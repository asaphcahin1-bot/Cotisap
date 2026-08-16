# Décisions techniques — CotisApp

Chaque entrée : la décision, pourquoi, ce qui a été écarté.

## Annulation d'une clôture de cycle faite par erreur

**Décision** : `annulerClotureCycle` autorisée **uniquement si le
nouveau cycle est strictement vide** (aucune cotisation, prêt, amende,
contribution au fonds de solidarité). Dans ce cas : le nouveau cycle est
supprimé, l'ancien redevient `en_cours`.

**Écarté, discuté explicitement avec le fondateur** : une version plus
souple autorisant l'annulation tant que "moins de deux paiements" ont
été enregistrés sur le nouveau cycle. Rejetée pour une raison technique
concrète, pas seulement par prudence : chaque cotisation/prêt/amende
porte un hash qui inclut son `cycleId` (voir `HashChain`). Réattribuer
une ligne déjà écrite à un autre cycle casserait cette chaîne
d'intégrité — la même raison pour laquelle aucune table financière de
ce projet n'autorise de UPDATE/DELETE direct. Un critère basé sur "le
cycle n'est pas encore arrivé à son terme naturel" a aussi été écarté :
il ne garantit rien sur la sécurité technique de l'annulation, seulement
sur le caractère "précoce" de la clôture — une clôture anticipée peut
être parfaitement volontaire.

**Si le nouveau cycle a déjà des données** : pas d'annulation
automatique proposée. Cas à traiter manuellement, au cas par cas.

## Horloge de test (`AppClock`)

**Décision** : une horloge interne à l'app, substituée à
`DateTime.now()` dans tout le code métier sensible au temps
(échéances, amendes automatiques, solde de prêt, valeurs par défaut
d'horodatage en base). Renvoie toujours la vraie date, sauf si
explicitement simulée — possible **uniquement en mode debug**
(`kDebugMode`), avec une vraie garde à l'exécution (`if (!kDebugMode)
return;`) plutôt qu'un simple `assert` (retiré des builds release, donc
insuffisant comme garantie).

**Pourquoi** : le fondateur a tenté de changer la date système de son
téléphone pour tester l'app sur plusieurs mois — ça a rendu le
téléphone inutilisable ("après avoir rempli cette date, je ne peux plus
rien faire"). Changer l'horloge d'un appareil entier affecte aussi
d'autres apps/services (certificats, etc.) — jamais une bonne idée.
Une horloge simulée interne à l'app évite complètement ce risque.

**Portée** : tous les `DateTime.now()` pertinents pour la logique
métier ont été remplacés (une quinzaine d'endroits, dont
`database.dart`). Les usages purement UI sans impact métier (ex.
bornes de `showDatePicker`) ont aussi été alignés sur `AppClock.now()`
par cohérence, pour qu'un sélecteur de date ne permette jamais de
choisir "après" la date simulée en cours.

**Contrôle** : icône 🧪 dans la barre de l'écran "Mes groupes",
visible seulement en mode debug — fixe une date simulée ou revient à la
date réelle. Aucune trace de ce contrôle dans un build release.

## Amendes de retard automatiques (remplace le bouton manuel par membre)

**Décision, précisée par le fondateur avec un scénario concret (3
membres, cotisations hebdomadaires)** : l'ancien mécanisme — un bouton
"Amende" par membre en retard, à taper par l'agent — est remplacé par
une détection et application **automatiques**, mais **jamais
instantanées et jamais irréversibles** :

1. Aucune amende n'est jamais possible pour l'échéance qui vient de
   s'ouvrir (y compris le tout premier jour d'un cycle) — seules les
   échéances déjà closes comptent.
2. `AmendeAutoService.detecterEtAppliquer` tourne à chaque ouverture de
   l'écran Cotisations : pour chaque membre actif, compare le nombre
   d'échéances closes à sa couverture réelle (`totalPayé ÷ montant par
   échéance`, arrondi à l'entier inférieur) et crée une amende
   auto-générée pour chaque écart non encore sanctionné. Idempotent par
   construction (compare toujours à ce qui existe déjà), donc sans
   risque à rejouer à chaque ouverture d'écran.
3. Chaque amende auto-générée reste visible à la séance suivante avec
   deux choix pour l'agent — jamais un simple statu quo silencieux :
   **Confirmer** (rien ne change) ou **Erreur — il avait payé** (annule
   l'amende et enregistre la cotisation manquante, à la vraie date
   choisie par l'agent, pas forcément aujourd'hui).

**Écarté en cours de route** : ancrer la disponibilité d'une échéance un
jour avant sa date officielle ("permettre de cotiser pour le 8 dès le
7"), et permettre un paiement en avance explicite pour la prochaine
échéance dans la foulée d'un paiement normal. Les deux ont été discutés
en détail puis explicitement abandonnés par le fondateur au profit de
rester sur le système déjà en place — non implémentés, à ne pas
reprendre sans nouvelle demande explicite.

**Traçabilité** : comme pour les prêts, aucune suppression ni
modification directe. `AmendeAnnulations` (miroir de `PretAnnulations`)
référence l'amende d'origine ; celle-ci reste lisible dans l'historique
mais exclue des totaux dès qu'une annulation existe. `Amendes` gagne
`estAutoGeneree` (distingue une amende automatique d'une saisie libre
par l'agent) et `confirmedAt` (évite qu'une amende confirmée réapparaisse
indéfiniment dans la liste à revoir).

**Écarté** : faire du champ `motif` la seule façon de distinguer
auto/manuel (fragile, dépend d'un texte libre) — préféré un booléen
dédié.

## Remboursement de prêt — deux garde-fous UI

**Décision** : (1) le bouton "Remboursement" disparaît dès que
`LoanBalanceCalculator` indique un solde nul — rien à faire une fois
soldé. (2) Le formulaire refuse toute saisie supérieure au montant dû
affiché.

**Limite assumée** : ce plafond n'est validé que côté écran, pas dans
`enregistrerRemboursement` en base — contrairement à d'autres
garde-fous de ce projet (ex. `confirmerPretParSignature`). Raison :
calculer le montant dû exige `LoanBalanceCalculator` (intérêt composé),
qui vit délibérément dans la couche domaine/écran, jamais importé dans
`database.dart` (séparation déjà en place dans tout le projet). Ajouter
cette dépendance à la couche base uniquement pour ce garde-fou aurait
cassé cette séparation pour un gain de sécurité marginal (l'agent est
déjà la seule personne à saisir un remboursement, contrairement aux
policies RLS Supabase qui, elles, doivent se défendre contre un client
non fiable).

## Épisode annulé : échéances ancrées sur la date de début (finalement pas retenu)

**Bug remonté par le fondateur après test réel** : un groupe fraîchement
créé, un membre fraîchement ajouté avec ses carnets définis → l'écran
Cotisations affichait "membre à jour", aucun montant à payer. Cause :
`EcheanceCalculator` calait la première échéance sur le prochain jour
calendaire correspondant au jour de paiement choisi (ex. "le prochain
jeudi") — si le groupe n'était pas créé précisément ce jour-là, la
première échéance tombait dans le futur et 0 échéance était comptée
comme "passée".

**Correction** : la première échéance est désormais **toujours la date
de début du cycle elle-même** (premier paiement dû immédiatement, dès
l'ajout du membre), puis les échéances suivantes s'enchaînent à
intervalle fixe depuis cette date (7/15/30 jours selon la fréquence —
mêmes valeurs que `_joursParPeriode` déjà utilisé par `membresEnRetard`,
ce qui unifie au passage les deux mécanismes évoqués comme limite
connue dans l'entrée précédente).

**Annulé le jour même** : après explication, le fondateur a confirmé que
le système calendaire (jour de paiement fixe) était le comportement
voulu — le "bug" observé était en fait normal : le groupe de test
n'avait pas été créé le jour choisi comme jour de paiement, donc aucune
échéance n'était encore passée. `EcheanceCalculator` et l'écran de
création de groupe (avec ses champs jour de semaine/jour du mois) sont
restaurés tels quels. Voir l'entrée suivante pour la vraie demande qui
en a résulté.

## Modification du groupe/cycle avant la première cotisation

**Décision** : puisqu'un groupe peut être créé un autre jour que le
jour de paiement choisi (configuration administrative avant la
première vraie réunion), il faut pouvoir corriger nom, durée,
fréquence, jour de paiement, valeur du carnet, taux, amende, durée de
prêt — **tant qu'aucune cotisation n'a encore été enregistrée** sur le
cycle. `modifierGroupeEtCycle` applique ce verrou côté base (refuse
explicitement, `StateError`, pas seulement un bouton caché côté écran)
: une fois qu'un premier paiement existe, ces paramètres sont
considérés comme définitifs, cohérent avec `interestRatePercent` déjà
figé sur chaque prêt à sa création plutôt que relu depuis le cycle.

**Écran** : `EditGroupScreen`, accessible par une icône crayon dans la
barre du groupe, visible uniquement si le verrou est encore ouvert.
Volontairement un écran séparé de `CreateGroupScreen` plutôt qu'un
composant partagé — même style de duplication légère que le reste du
projet (dialogues de confirmation, écrans de prêt), pour rester simple
à lire plutôt que d'introduire une couche d'abstraction pour deux
écrans.

## Carnets figés, échéances fixes, prêts à intérêt composé

Règles précisées par le fondateur (2026-08-05), plus strictes que ce qui
était codé jusqu'ici. Trois points tranchés explicitement avec lui avant
d'implémenter (financier sensible, pas de place à la supposition) :

**Intérêt de prêt en retard** : confirmé — le taux se réapplique au
solde restant à chaque période de `loanDurationDays` expirée sans
remboursement complet, indéfiniment jusqu'au solde nul
(`LoanBalanceCalculator`). Écarté : un taux qui augmente à chaque
renouvellement (pénalité progressive) — pas ce qui a été demandé.

**Jour de paiement mensuel/bimensuel** : jour(s) du mois configurable(s)
plutôt que de garder l'ancien calcul par intervalle glissant partout.
Résultat : `groups.paymentDayOfWeek` (hebdomadaire) XOR
`paymentDayOfMonth1`(+`paymentDayOfMonth2` si bimensuelle). Aucune
valeur par défaut devinée — `EcheanceCalculator` lève une erreur claire
si la configuration attendue pour la fréquence du groupe manque, plutôt
que de deviner un jour.

**Portée de la vérification groupée avant enregistrement** : cotisations
cash uniquement. Prêts, remboursements et amendes restent enregistrés
immédiatement comme avant — pas de "brouillon" pour ces derniers, pour
ne pas complexifier des flux déjà dotés de leur propre confirmation
(code SMS/signature pour les prêts, dialogue de confirmation pour les
amendes).

**Limite connue, assumée pour cette étape** : `membresEnRetard` (skill
avec-business-rules) utilise encore l'ancien calcul de période glissante
depuis `cycle.startedAt`, pas le nouveau calendrier d'échéances fixes de
`EcheanceCalculator`. Les deux mécanismes servent des rôles différents
(l'un déclenche le signal "en retard" pour l'amende, l'autre calcule le
montant exact à payer) et ne se contredisent pas sur le montant dû, mais
ne sont pas unifiés. Refaire `membresEnRetard` sur le même calendrier
d'échéances est un futur nettoyage, pas un correctif urgent — les 5
tests existants sur `membresEnRetard` continuent de documenter son
comportement actuel tel quel.

**Carnets engagés** : nouvelle table `CarnetsEngages` (une ligne par
membre et par cycle) plutôt qu'un champ sur `Members` — un même membre
peut avoir un engagement différent d'un cycle à l'autre, cohérent avec
le fait que la valeur du carnet et le taux sont eux aussi propres à
chaque cycle. Verrouillage automatique (`lockedAt`) au premier paiement
`direct` uniquement — un import historique (`provenance = 'importe'`)
ne verrouille jamais, un historique papier n'a pas à contraindre les
choix du cycle en cours.

## Membres sans téléphone — confirmation de prêt par signature

**Décision** : `members.phoneNumber` devient nullable (migration drift
schemaVersion 2→3, `TableMigration` car SQLite ne permet pas
d'assouplir une contrainte NOT NULL par un simple ALTER). Un membre
sans aucun téléphone personnel (pas seulement sans smartphone) peut
être ajouté à un groupe.

**Choix du mécanisme de confirmation, tranché avec le fondateur** :
signature capturée à l'écran, plutôt qu'un code PIN — le skill
`member-consent-rules` autorisait les deux ("cas des membres sans
smartphone"). Raison retenue : geste familier (équivalent d'une
signature papier), et un PIN saisi sur l'appareil partagé de l'agent
offre une confidentialité fragile en petit village, contrairement à
l'intention du skill.

**Implémentation** : `PretConfirmations` gagne un champ `methode`
(`code` | `signature`, jamais mélangés sur une même ligne),
`signatureData` (traits capturés, encodés en texte compact — pas
d'image PNG, pour rester sans dépendance externe après l'expérience
`file_picker`/KGP) et `witnessPhone` (le numéro de l'**agent** témoin,
jamais celui d'un tiers agissant pour le membre). `codeSaisi` et
`confirmedByPhone` restent réservés à la méthode `code`.
`confirmerPretParSignature` **refuse explicitement** si le membre
emprunteur a un téléphone enregistré — la signature ne doit jamais
devenir un raccourci pour éviter la confirmation SMS individuelle
quand elle est possible (skill `member-consent-rules`, règle centrale).

**Conséquence acceptée** : un membre sans téléphone ne peut jamais
utiliser l'accès "membre" en lecture seule (`membresParTelephone`
s'identifie par numéro) — documenté comme limite connue, pas un bug.
Le skill `two-tier-access-model` garantit la gratuité de cet accès
*quand il est possible*, pas qu'il soit possible pour tout le monde.

**Écarté** : générer une image (PNG) de la signature — ajoute une
dépendance d'encodage sans bénéfice pour cette étape ; le tracé en
texte compact suffit comme preuve capturée, et reste lisible/rejouable
plus tard si besoin (ex. régénérer un aperçu visuel).

## Clôture de cycle — pas de mécanisme de report de dette automatique

**Décision** : `cloturerCycleEtOuvrirSuivant` avertit l'agent si des
prêts confirmés du cycle ne sont pas totalement remboursés
(`pretsNonSoldesDuCycle`), mais **n'empêche jamais** la clôture et
**n'invente aucune règle** pour transférer ce solde au cycle suivant
(pas de nouvelle ligne `prets` créée automatiquement dans le nouveau
cycle, pas de déduction sur la répartition de fin de cycle). Le dossier
source ne précise pas cette règle — plutôt que de la deviner pour un
sujet financier sensible, l'app se contente d'informer le comité, qui
tranche en dehors de l'app (le prêt reste visible et son solde calculable
via l'écran "Cycles" → cycle historique concerné).

**Écarté** : bloquer la clôture tant qu'un prêt n'est pas soldé — rejeté
car un cycle AVEC se clôture à date fixe dans la réalité (fin de la
période convenue), pas quand toutes les dettes sont réglées ; bloquer
l'app irait à l'encontre de l'usage réel et forcerait une résolution
artificielle en urgence.

**Priorité des paramètres du nouveau cycle** : valeur du carnet, taux
d'intérêt et amende de retard sont redemandés explicitement à la
clôture (pré-remplis avec les valeurs du cycle qui se termine, mais
modifiables) plutôt que copiés silencieusement — cohérent avec le choix
déjà fait à la création du groupe (skill `avec-business-rules`).

## Schéma PostgreSQL + RLS Supabase — miroir strict du schéma drift

**Décision** : `supabase/migrations/0001_init.sql` reproduit exactement
les tables `drift` locales (mêmes noms de colonnes en snake_case, mêmes
contraintes `check`), sans ajouter de colonnes de synchronisation
(`updated_at`, `deleted_at`...) à cette étape — celles-ci arriveront
avec la conception de la couche de synchronisation elle-même (skill
`offline-first-flutter`), pas avant, pour éviter la surconstruction.

**RLS = seule frontière de sécurité fiable** (skill
`two-tier-access-model`, "règle non négociable") : chaque table a RLS
activé, et le filtrage agent/membre est appliqué par des politiques
SQL, jamais seulement côté client. Fonctions d'aide créées :
`app_current_phone()` (lit `auth.users.phone` de l'utilisateur
connecté), `app_is_agent(group_id)` (vrai si une ligne
`agent_assignments` active avec `role = 'agent'` existe pour ce
numéro), `app_is_self_member(member_id)`. Hypothèse à vérifier au
branchement de l'auth réelle (ROADMAP étape 3) : le numéro stocké par
Supabase Auth après confirmation SMS doit être normalisé exactement
comme `members.phone_number`/`agent_assignments.phone_number`, sinon
les politiques ne matcheront jamais.

**Tables financières en ajout seul → pas de politique UPDATE/DELETE** :
Postgres refuse une action sans politique correspondante, donc
l'absence volontaire de politique `update`/`delete` sur `cotisations`,
`amendes`, `prets`, `pret_confirmations`, `pret_remboursements`,
`pret_annulations`, `fonds_solidarite_contributions` suffit à empêcher
toute modification après coup au niveau serveur — cohérent avec la
chaîne de hash déjà en place côté `drift`.

**Confirmation de prêt réservée au membre concerné** (skill
`member-consent-rules`) : la politique d'insertion sur
`pret_confirmations` exige `confirmed_by_phone = app_current_phone()`
ET que ce numéro soit bien celui du membre emprunteur — ni l'agent ni
un tiers ne peut insérer cette ligne à la place du membre, y compris
en modifiant la requête.

**Écarté** : générer le schéma automatiquement depuis les définitions
`drift` (pas d'outil mûr pour drift → Postgres+RLS ; écrire le SQL à la
main reste plus sûr pour un schéma financier, et permet de revoir
chaque politique une par une).

## Détection des retards de cotisation — période calculée, pas stockée

**Décision** : pas de table "réunions" séparée pour cette étape. La
période en cours (semaine/quinzaine/mois) se calcule à la volée à
partir de `cycle.startedAt` et `group.meetingFrequency`
(`_debutPeriodeEnCours` dans `database.dart`) plutôt que d'être
enregistrée à chaque réunion. "Mensuelle" est approximée à 30 jours
(pas un vrai calcul de mois calendaire) — suffisant pour repérer un
retard, pas pour une facturation au jour près.

**Amende automatique vs décision de l'agent** : la détection ne crée
jamais d'amende toute seule. `membresEnRetard` se contente de lister
qui n'a pas cotisé sur la période — l'agent voit un montant suggéré
(`cycle.lateFeeFcfa`, configuré à la création du cycle comme la valeur
du carnet et le taux d'intérêt) et confirme d'un tap. Raison : le
dossier source prévoit explicitement qu'un groupe peut accorder une
suspension temporaire à un membre en difficulté — une amende 100 %
automatique romprait cette règle.

**Éviter le double comptage** : un membre déjà mis à l'amende sur la
période en cours (une ligne dans `amendes` avec `recordedAt` dans la
période) n'est plus listé comme en retard, même s'il n'a toujours pas
cotisé — sinon l'agent le reverrait indéfiniment tant qu'il ne paie
pas.

**Migration de schéma** : `lateFeeFcfa` ajouté à `Cycles` via
`schemaVersion` 1 → 2 avec `MigrationStrategy.onUpgrade` (ajout de
colonne, pas de perte de données).

## Vocabulaire "carnet" pour l'unité de cotisation

**Décision** : l'interface affiche "carnet" (pas "part") pour l'unité de
cotisation qu'un membre achète à chaque réunion (1 à 5). C'est le terme
réellement utilisé sur le terrain par les groupes AVEC — demande directe
du fondateur.

**Ce qui change / ce qui ne change pas** : seuls les libellés visibles
à l'écran changent. En interne, le code garde `part`/`parts` comme nom
technique (`partsCount`, `partValueFcfa`, `MemberParts`, la formule du
skill `avec-business-rules`) — renommer ces identifiants demanderait une
migration de schéma `drift` (colonnes déjà nommées `parts_count`,
`part_value_fcfa`) sans aucun bénéfice utilisateur, puisque personne ne
voit ces noms. Documenté dans les skills `localisation-fr-afrique-ouest`
et `avec-business-rules` pour que ce pont technique↔affichage reste
explicite pour toute future session de développement.

**Effet de bord utile** : "part" avait aussi un second sens dans le
code — "part individuelle" désignait la portion du bénéfice qu'un
membre reçoit en fin de cycle (intérêts + amendes répartis). Ce champ
est renommé `beneficeIndividuel` ("bénéfice individuel" à l'écran) pour
lever toute ambiguïté avec "carnet", qui est un concept totalement
différent.

## Accès membre — choix de rôle explicite plutôt que déduit

**Décision** : à l'écran d'identification, la personne choisit
elle-même "agent" ou "membre" (deux boutons), plutôt que l'app essaie
de deviner le rôle à partir du numéro de téléphone saisi.

**Pourquoi** : un même numéro peut légitimement être à la fois agent
d'un groupe et simple membre d'un autre — une déduction automatique
serait ambiguë dans ce cas très plausible (le dossier source décrit
justement la Trésorière comme membre du comité ET potentiellement
utilisatrice de l'app à titre personnel). Laisser la personne choisir
est plus simple à raisonner et sans ambiguïté.

**Limite assumée** : ce choix n'est pas une session au sens strict
(juste un état en mémoire, `appModeProvider`), il se perd au
redémarrage de l'app comme le numéro de téléphone lui-même. Une vraie
session persistante arrive avec Supabase Auth (voir ROADMAP.md).

## Filtrage des données membre : au niveau de la requête, pas après coup

**Décision** : `cotisationsDuMembre` et `pretsDuMembre` filtrent par
`memberId` directement dans la clause `WHERE` de la requête drift,
plutôt que de récupérer toutes les lignes du cycle et de filtrer la
liste résultante en Dart.

**Pourquoi** : c'est la même discipline que le skill
`two-tier-access-model` demande pour Supabase ("le filtrage doit se
faire au niveau de la base de données... une simple restriction
d'affichage côté client n'est pas suffisante"). Le faire déjà ainsi en
local, même si SQLite n'a pas de row-level security à proprement
parler, rend la future migration vers des politiques RLS Postgres plus
directe (même forme de requête, juste un moteur différent) et évite de
prendre une habitude de code qu'il faudrait corriger plus tard.

**Ce qui reste une simplification assumée** : le calcul de fin de
cycle affiché au membre (`MemberHomeScreen`) doit, par nature,
recalculer avec les parts de TOUT le groupe (la formule du skill
`avec-business-rules` en dépend). L'écran interroge donc bien
`cotisationsDuCycle` (toutes les lignes) pour ce calcul précis, mais ne
garde et n'affiche que la ligne de résultat correspondant au membre
connecté — jamais la liste complète. Un test dédié
(`member_home_screen_test.dart`) vérifie que le nom et les montants
d'un autre membre du même cycle n'apparaissent jamais dans le rendu.
En production avec Supabase, ce calcul agrégé devra passer par une
fonction serveur (ex. `SECURITY DEFINER`) qui ne renvoie que la ligne
de l'appelant, plutôt que de faire confiance au client pour ne pas
afficher ce qu'il a techniquement reçu.

## Import d'historique — provenance, conversion et limites connues

**Provenance plutôt qu'un champ `source` réutilisé** : `cash`/`distance`
(sur `cotisations`) décrit le canal de paiement ; `direct`/`importe`
(nouveau champ `provenance`, toutes les tables financières) décrit la
temporalité/vérification de l'écriture. Ce sont deux axes différents et
volontairement séparés — un import CSV peut très bien déclarer une
cotisation `cash` historique.

**Un prêt importé est confirmé par construction** : contrairement à un
prêt créé en direct (qui exige une ligne dans `pret_confirmations`, donc
le consentement SMS individuel du membre), un prêt `importe` est
considéré confirmé dès son insertion. Justification : il n'a pu être
écrit qu'après la validation collective du comité de gestion exigée par
l'écran d'import (skill historical-data-import) — redemander en plus un
consentement SMS individuel rétroactif n'aurait pas de sens pour un
historique déclaré, et bloquerait de fait tout import de prêts anciens
déjà remboursés.

**Conversion montant → parts pour les cotisations importées** : le
format CSV du skill (`nom,date,montant,type`) donne un montant brut en
FCFA, alors que le modèle de cotisation de l'app est fondé sur un
nombre de parts (skill avec-business-rules). La conversion retenue :
`parts = round(montant / valeur_de_la_part_du_cycle_cible)`, marquée
`estApproximatif` si la division n'est pas exacte. C'est une
approximation assumée, pas une garantie — un groupe dont les montants
historiques ne correspondaient pas à un multiple propre de la valeur de
part actuelle verra un léger écart.

**Rattachement des remboursements importés à un prêt** : le format CSV
du skill ne référence pas explicitement quel prêt un remboursement
solde. Heuristique retenue : les lignes
sont triées par date, et un remboursement est rattaché au plus ancien
prêt importé du même membre pas encore intégralement soldé. Une ligne
de remboursement qui ne trouve aucun prêt correspondant n'est jamais
ignorée silencieusement — elle est renvoyée comme avertissement après
l'import, à vérifier manuellement. Alternative écartée : bloquer tout
l'import dès qu'un remboursement est ambigu — jugé trop strict pour un
historique de carnet papier, forcément imparfait.

**Cycles historiques clos** : un cycle créé via `creerCycleHistorique`
a un statut `cloture` dès sa création et des dates de début/fin fixées
explicitement (plutôt que déduites de `DateTime.now()` comme
`ouvrirCycle`). Chaque cycle garde sa propre valeur de part et son
propre taux d'intérêt — le calcul de fin de cycle (`EndOfCycleCalculator`)
ne lit jamais de données au-delà du `cycleId` qu'on lui passe, donc les
cycles restent naturellement isolés sans logique de filtrage
supplémentaire à écrire ou à maintenir.

## Paiement à distance retiré du périmètre de cette étape

**Décision** : aucune intégration PayDunya/DEXCHANGE/Wave dans cette
étape. Le champ `source` existe sur `cotisations` (`cash` | `distance`)
parce que le skill `avec-business-rules` l'exige comme partie du
modèle de données central, mais aucun code n'écrit encore `distance`.

**Pourquoi** : le compte agrégateur nécessite un numéro de téléphone
UEMOA, indisponible avant le retour en Côte d'Ivoire (~septembre 2026).
Le statut réglementaire exact du flux (intermédiation de fonds) n'est
pas non plus vérifié. Retirer le paiement du périmètre élimine ces deux
blocages sans retarder la partie qui constitue la vraie valeur ajoutée
du produit : le calcul.

## Gestion d'état : Riverpod

Choisi pour sa testabilité et parce qu'il gère bien les flux
asynchrones dont la synchronisation offline aura besoin plus tard.
Alternative écartée : `Provider` seul (moins outillé pour les cas
asynchrones à venir), Bloc (plus verbeux pour un projet de cette
taille).

## Stockage local : drift plutôt que sqflite brut

Le skill `offline-first-flutter` autorise les deux. `drift` a été
retenu pour les requêtes vérifiées à la compilation et l'outillage de
migration — un vrai avantage pour un moteur de calcul financier où une
erreur de requête doit être détectée avant l'exécution, pas en
production dans un village sans réseau pour la corriger à distance.

## Authentification / OTP SMS : Supabase Auth + Twilio (différé), mode dev pour l'instant

**Décision** : en production, utiliser l'authentification téléphone de
Supabase Auth avec Twilio comme fournisseur SMS. Ne jamais utiliser
Firebase Phone Auth.

**Pourquoi Twilio plutôt que Firebase** : Firebase Phone Auth dépend
des services Google Play, ce qui viole directement la contrainte du
skill `offline-first-flutter` ("ne pas coder de dépendance dure aux
services Google Play... pour les fonctions critiques") — l'app doit
rester installable par APK partagé dans les zones à faible accès au
Play Store, y compris pour l'authentification, une fonction critique.

**Pourquoi Twilio plutôt qu'un flux OTP fait maison** : Supabase gère
déjà l'envoi, la vérification et l'expiration des codes ; ne pas
réinventer cette mécanique réduit la surface de bug sur un point
sensible (identité).

**Ce qui n'est PAS fait maintenant** : aucun compte Twilio ni Supabase
n'a été créé — je ne peux pas créer de compte externe en votre nom.
`DevAuthGateway` (code de test fixe, voir `lib/data/auth/`) permet de
développer et tester tout le flux de consentement de prêt sans ce
compte. Le remplacement par `SupabaseAuthGateway` est une implémentation
supplémentaire de la même interface `AuthGateway`, pas une
réécriture — voir ROADMAP.md.

## Immuabilité de l'historique financier : ajout seul + chaîne de hash

**Problème identifié à l'audit** : "historique immuable" était écrit
dans les skills sans mécanisme technique pour l'imposer — un accès
direct au fichier SQLite aurait permis de modifier une ligne déjà
confirmée sans laisser de trace.

**Décision** : les tables financières (`cotisations`, `prets` et ses
tables satellites, `amendes`, `fonds_solidarite_contributions`,
`agent_assignments`) n'ont aucune méthode d'UPDATE ni de DELETE dans
`AppDatabase`. Chaque ligne stocke `previousHash` (hash de la dernière
ligne insérée dans la même table) et `hash` (calculé sur ses propres
champs + `previousHash`) via `HashChain.compute()`. Une modification
directe du fichier `.sqlite` casse la chaîne de façon détectable.

**Ce que ça ne couvre pas** : ce n'est pas une signature cryptographique
vérifiable par un tiers, seulement une détection d'altération locale.
Une vraie garantie d'audit multi-parties nécessiterait de faire
remonter ces hashes vers Supabase au moment de la synchronisation
(non fait dans cette étape).

## Continuité du rôle "agent" : table d'affectation, pas un champ figé

**Problème identifié à l'audit** : rien ne prévoyait le changement
d'agent/trésorière entre deux cycles, alors que le dossier métier
prévoit explicitement que le comité de gestion peut changer après
chaque cycle.

**Décision** : `agent_assignments` (en ajout seul) plutôt qu'un champ
`agentPhone` sur `groups`. Une affectation reste active tant qu'aucune
ligne de `agent_assignment_revocations` ne la référence. Changer
d'agent = une révocation + une nouvelle affectation, sans jamais
modifier l'historique.

## Intérêts "perçus" = prêts confirmés et remboursés intégralement avant la clôture

Le skill `avec-business-rules` parle d'"intérêts perçus", pas
"intérêts dus". Le dossier source ne précise pas le traitement d'un
prêt en défaut ou partiellement remboursé à la clôture du cycle — sujet
ouvert, pas tranché ici. Hypothèse retenue pour V0 :
`totalInteretsPercusDuCycle` ne compte que les prêts confirmés dont le
remboursement total (capital + intérêt) atteint ou dépasse le montant
dû. Un prêt non intégralement remboursé ne contribue aucun intérêt au
calcul de répartition. À confirmer avec vous avant la V1.

## Fusion cotisation + amende à l'encaissement

**Décision, précisée par le fondateur (2026-08-07)** : à l'écran
Cotisations, sélectionner un membre affiche désormais **un seul montant
total à régler** = arriéré de cotisation (inchangé, voir
`EcheanceCalculator.soldeDuFcfa`) + toutes ses amendes non encore
soldées — avec la composition toujours détaillée à l'écran ("1000 F
cotisation + 500 F amende = 1500 F"), jamais un chiffre opaque.
`AppDatabase.enregistrerEncaissementSeance` écrit les deux dans la même
opération atomique : la cotisation (comme avant), et chaque amende en
attente passe à "réglée" (`confirmerAmende`) — l'agent n'a plus qu'un
seul geste d'encaissement par membre.

**Ce qui reste inchangé** : `confirmerAmende` et `corrigerAmendeErreur`
existent toujours tels quels (l'agent peut confirmer une amende sans
paiement immédiat, ou corriger une amende posée par erreur) — la fusion
s'ajoute au-dessus sans remplacer ce mécanisme déjà testé.

## Une amende ne se règle plus jamais automatiquement (2026-08-09, contredit la décision du 7 août)

**Contradiction avec une décision antérieure, tranchée explicitement
par le fondateur** : la décision du 7 août ("Fusion cotisation +
amende à l'encaissement", ci-dessus) faisait régler automatiquement
toutes les amendes non soldées d'un membre dès qu'un agent enregistrait
n'importe quelle cotisation pour lui — même si l'agent n'avait en
réalité collecté que l'argent de la cotisation ce jour-là. Après
réflexion, le fondateur juge ce comportement anormal : **une amende ne
doit se régler que par un geste explicite et séparé de l'agent**, jamais
comme effet de bord d'une autre action.

**Décision** : `enregistrerEncaissementMembre` ne touche plus jamais
aux amendes du membre — le bloc qui appelait automatiquement
`confirmerAmende` sur chaque amende non soldée est retiré. Le seul
chemin pour régler une amende reste le bouton "Confirmer telle quelle"
de la section "Amendes en attente" de l'écran Cotisations (mécanisme
déjà existant, voir `_confirmerAmende` /
`corrigerAmendeErreur` — inchangés). Côté écran, le brouillon
d'encaissement ne peut plus contenir de ligne "amende seule" : une
amende en attente s'affiche désormais comme un simple rappel
informatif à côté du formulaire de cotisation ("Rappel : ce membre a
aussi X FCFA d'amende en attente — à régler séparément"), jamais
ajoutée au total ni au brouillon.

**Conséquence pratique** : si un membre paie sa cotisation ET son
amende le même jour, l'agent doit désormais faire deux gestes
distincts (enregistrer la cotisation, puis confirmer l'amende) même si
l'argent est remis en une seule fois dans la vraie vie — accepté
explicitement par le fondateur en échange d'une trace plus fiable (rien
n'est marqué "réglé" sans une action délibérée dessus).

## Registre d'échéances : historique groupé par date

**Problème** : l'ancien modèle ne traçait que les paiements réels — une
échéance manquée n'existait que comme un delta recalculé à la volée
(`soldeDuFcfa`), jamais comme une ligne consultable. Impossible d'afficher
un historique "Payé / Non payé" par date sans un vrai registre.

**Décision** : nouvelle table `Echeances` (ajout seul, une ligne par
membre et par échéance). `AmendeAutoService.detecterEtAppliquer` trace
désormais **toujours** une ligne `non_paye` pour chaque échéance close
non couverte, **même dans un groupe sans amende automatique**
(`lateFeeFcfa = 0`) — avant cette étape, la méthode s'arrêtait
immédiatement dans ce cas et ne traçait rien du tout. Un règlement
ultérieur écrit une **nouvelle** ligne `paye` (jamais une correction sur
place, même principe que le reste des tables financières en ajout seul)
— la lecture (`echeancesGroupeesParDate`) retient toujours la plus
récente pour un couple (membre, date). `montantDuFcfa`/`montantPayeFcfa`/
`amendeFcfa` ne concernent que l'échéance elle-même ; `arrieresFcfa` est
le seul champ cumulatif (solde total dû à cet instant, 0 sur une ligne
`paye`).

**Nombre de carnets jamais affecté** : `enregistrerEncaissementSeance`
ne touche jamais `CarnetsEngages.partsCount` — un rattrapage de 2 ou 4
cotisations (voir exemples AD/AB du fondateur) reste un multiple des
carnets déjà engagés, jamais une modification de ce nombre. Vérifié
explicitement par test (`echeances_ledger_test.dart`).

**Écran Historique** (`CotisationsHistoryScreen`, icône dans la barre de
l'écran Cotisations) : regroupe `echeancesGroupeesParDate` par date
(la plus récente en premier), chaque date dépliable (`ExpansionTile`)
listant chaque membre avec son statut — format demandé par le fondateur.

## Déduction des dettes au partage (inclut le solde de prêt)

**Décision, précisée par le fondateur (2026-08-07)** : au moment du
partage de fin de cycle, la dette totale d'un membre (arriéré de
cotisation non rattrapé + amendes non soldées + **solde de prêt confirmé
non remboursé**) est déduite de ce qu'il aurait dû percevoir
(`AppDatabase.detteMembreFcfa` + `DebtDeductionCalculator`, pur et
testé séparément) :
- dette < montant à percevoir → dette déduite intégralement, le membre
  reçoit le solde ;
- dette = montant à percevoir → le membre reçoit 0 ;
- dette > montant à percevoir → le membre reçoit 0, la différence non
  récupérée est enregistrée comme **perte pour l'AVEC**
  (`PartageDeductions.pertAvecFcfa`).

**Ne contredit pas** la décision "pas de report de dette automatique
pour les prêts" (voir plus haut, "Clôture de cycle") — elle la
complète : cette dernière porte sur le solde qui *reste* après le
partage (l'app ne le transfère jamais automatiquement au cycle
suivant) ; celle-ci porte sur le règlement *pendant* le partage, par
prélèvement sur le montant à percevoir. Ferme de fait le sujet ouvert
"report de dette d'un cycle à l'autre" listé dans ROADMAP.md : soit la
dette est récupérée par déduction, soit elle devient une perte
enregistrée — jamais un solde oublié.

**Figé une fois pour toutes à la clôture** : `PartageDeductions` (ajout
seul) écrit une ligne par membre au moment précis où
`cloturerCycleEtOuvrirSuivant` clôture effectivement le cycle — jamais à
la simple prévisualisation de l'écran (`CycleSummaryScreen`), qui peut
être ouvert plusieurs fois avant la clôture réelle. Pour un cycle déjà
clos, l'écran relit ces valeurs figées plutôt que de les recalculer :
un prêt reste remboursable après la clôture du cycle (voir
`pretsNonSoldesDuCycle`), donc son solde recalculé "en direct"
changerait avec le temps — la dette et la déduction retenues pour le
partage, elles, ne doivent jamais bouger après coup.

**Une amende incluse dans la dette est marquée réglée à la clôture**
(`confirmerAmende` appelé pour chacune) — récupérée par déduction ou
perdue pour l'AVEC, elle ne doit jamais être recomptée. **Le solde de
prêt n'est volontairement jamais marqué comme réglé** : contrairement à
une amende, un prêt reste une vraie créance remboursable après coup,
indépendamment du traitement comptable appliqué au partage.

## Carnets : 1 ou 2 par membre, jamais un multiplicateur libre

**Contexte** : plusieurs itérations sur ce sujet en une seule journée
(2026-08-08). D'abord un responsable de terrain avait indiqué "une
personne a droit à un seul carnet, plusieurs carnets = plusieurs
fiches sous des noms différents". Un document de règles écrit avec
l'agent, discuté ensuite avec le fondateur, a tranché différemment :
**un membre peut détenir 1 ou 2 carnets directement sur sa fiche**,
jamais davantage. C'est cette dernière version qui est retenue et
codée — la piste "toujours 1, plusieurs fiches" n'a jamais été
implémentée.

**Ce que ça remplace** : l'ancien modèle (juillet-août) traitait
"carnets engagés" comme un simple multiplicateur 1 à 5 sur une seule
fiche membre, appliqué uniformément à chaque échéance. Le nouveau
modèle sépare strictement deux notions : `CarnetsEngages.nombreCarnets`
(1 ou 2, combien de carnets un membre détient, toujours figé au premier
paiement comme avant) et le nombre de **parts** déposées à chaque
cotisation dans **un carnet donné** (voir l'entrée suivante). Chaque
carnet d'un membre suit ensuite ses propres échéances et son propre
arriéré **indépendamment** de l'autre — un membre à 2 carnets peut être
à jour sur l'un et en retard sur l'autre.

## Parts libres par cotisation, minimum 1

**Règles données par un responsable de terrain (2026-08-08)**, résumées
dans un document de règles métier partagé par le fondateur :

- Un carnet reçoit **entre 1 et 5 parts par cotisation**, jamais plus
  en une seule transaction ("aucun montant intermédiaire n'est
  autorisé" — le montant doit être un multiple exact de la valeur de la
  part).
- **Le rythme normal est 1 part minimum par carnet et par échéance** —
  en dessous, c'est un retard ou une absence (confirmé explicitement
  par le fondateur). La fourchette 1-5 sert donc à rattraper plusieurs
  échéances manquées en une seule fois (ou à payer un peu en avance),
  jamais à définir un engagement variable au choix du membre à chaque
  passage.

**Remplace la décision du 5 août 2026** ("Carnets figés, échéances
fixes... montant de cotisation calculé automatiquement, plus de saisie
libre") : ce montant n'est plus figé pour tout le cycle. Il reste
**suggéré automatiquement** à l'écran (arriéré + échéance du jour,
plafonné à 5 parts) mais l'agent peut l'ajuster à la baisse ou à la
hausse dans cette même limite — nécessaire puisque le rattrapage n'est
plus mécaniquement "tout ou rien".

**Implémentation** : `EcheanceCalculator.soldeDuFcfa` ne prend plus de
paramètre `carnetsEngages` (retiré) — un carnet doit toujours
exactement `échéances passées × valeur de la part`, jamais un multiple
fixe. `EcheanceCalculator.maxPartsParTransaction` (= 5) et
`estUnMontantValide` portent la nouvelle contrainte. `Cotisations` et
`Echeances` gagnent `carnetNumero` (1 ou 2) — chaque écriture concerne
un seul carnet précis.
`AppDatabase.enregistrerEncaissementMembre({carnetNumero: parts, ...})`
remplace `enregistrerEncaissementSeance` : traite chaque carnet du
membre indépendamment (une cotisation par carnet non nul), puis règle
les amendes non soldées du membre en une fois (fusion inchangée, voir
plus haut).

**Amende : une par membre par date, jamais une par carnet.** "Absence à
une réunion" est un événement par personne, pas par carnet — même si
un membre à 2 carnets manque les deux à la même échéance, une seule
amende est appliquée (décision technique prise pour cette étape, pas
explicitement demandée mais cohérente avec le vocabulaire "absence"
plutôt que "cotisation manquée" utilisé pour les amendes).

## Clôture de la journée de cotisation

**Problème identifié avec le fondateur (2026-08-08)** : la détection
automatique des échéances manquées tournait en silence à chaque
ouverture de l'écran Cotisations, en comparant l'horloge du téléphone
aux dates calculées. Risque concret : un agent qui saisit ses données
plusieurs jours après une réunion (réseau faible) pouvait voir l'app
trancher "en retard" ou "absent" avant même d'avoir fini sa saisie du
jour — et rien n'empêchait techniquement d'ajouter un nouveau membre ou
un rattrapage n'importe quel jour entre deux échéances, ce qui n'a pas
de sens dans un système où l'argent ne change de main qu'en réunion.

**Décision** : l'agent clôture **explicitement** chaque journée de
cotisation (`AppDatabase.cloturerJourneeCotisation`), à la fin de la
réunion — jamais une clôture automatique et silencieuse. Ce geste :
1. Trace `non_paye` (registre `Echeances`) chaque carnet sans paiement
   enregistré pour cette date, pour chaque membre déjà inscrit à cette
   date — et applique l'amende de retard si le groupe en a une.
2. Si c'est la **toute première** journée clôturée du cycle, ferme les
   inscriptions (`Cycles.inscriptionsFermeesAt`) : plus aucun nouveau
   membre ne peut être ajouté à ce cycle après ce point
   (`AppDatabase.ajouterMembre` refuse explicitement).

**Rappel visible, jamais de clôture automatique** :
`journeeCotisationEnAttente` signale la plus ancienne échéance passée
et non encore clôturée — affiché comme bandeau sur l'écran Cotisations,
avec un bouton pour clôturer. Rien ne se passe tant que l'agent n'a pas
tapé ce bouton, cohérent avec le principe déjà en place dans ce projet
("jamais un simple statu quo silencieux").

**Annulation possible, mais seulement si rien n'en dépend déjà** :
`annulerClotureJournee` supprime directement la séance et les lignes
`Echeances`/amendes qu'elle a créées (même logique que
`annulerClotureCycle` — sûr uniquement tant que rien d'autre n'en
dépend). Refuse dès qu'une cotisation a été enregistrée pour une
échéance postérieure à la date annulée. **Limite acceptée** : annuler
la toute première séance clôturée ne rouvre pas automatiquement les
inscriptions du cycle (`inscriptionsFermeesAt` reste renseigné) — cas
jugé assez rare pour être traité manuellement plutôt que d'ajouter une
logique de réouverture symétrique pour cette étape.

## Clôture de journée : précisions apportées après un premier test réel (2026-08-09)

Après avoir vu comment "annuler la clôture" fonctionnait concrètement
(voir l'entrée précédente), le fondateur a confirmé la garder telle
quelle, puis précisé plusieurs comportements attendus autour de la
journée de cotisation :

**La saisie de cotisation est bloquée entre deux dates de paiement.**
Avant, l'écran Cotisations acceptait un encaissement n'importe quand
(le calcul se basait juste sur `AppClock.now()`). Désormais, la section
"Ajouter un encaissement" n'apparaît que s'il existe une journée
ouverte — `journeeCotisationEnAttente` sert de porte d'entrée unique :
tant qu'il ne renvoie rien (dernière échéance déjà clôturée, prochaine
pas encore arrivée), rien n'est proposé, avec un message explicite.

**Plafond de 5 parts par carnet et par jour : cumulatif, pas juste par
transaction.** Un agent qui enregistre 3 parts pour un carnet puis,
plus tard le même jour, encore 3, ne doit pas dépasser 5 au total.
`AppDatabase.partsDejaAjouteesAujourdhui` compte ce qui a déjà été
enregistré ce jour calendaire pour ce (membre, carnet) ; le plafond
appliqué à une nouvelle transaction est réduit d'autant. Tant que la
journée n'est pas clôturée, plusieurs transactions successives restent
possibles pour le même carnet, dans cette limite cumulée.

**Message de confirmation avec liste nominative avant clôture
définitive.** `AppDatabase.membresAbsentsPourDate` prévisualise, sans
rien écrire, qui manque à l'appel pour une date donnée. L'écran
Cotisations l'utilise pour afficher, avant que la clôture ne s'exécute
réellement, un message par membre absent ("X ne figure pas sur la
liste. Il écopera d'une amende de Y FCFA au prochain paiement.") — même
formulation pour tous. L'agent valide cet écran, et c'est seulement
ensuite que `cloturerJourneeCotisation` s'exécute.

**Amendes traitées en premier à la séance suivante.** La section
"Amendes en attente de règlement" est remontée en haut de l'écran
Cotisations (avant la saisie de nouvelles cotisations), pour que
l'agent régularise d'abord les amendes en attente.

**Encaissements de la journée visibles en direct, pas seulement après
coup.** Avant, la liste "Encaissements du jour" désignait uniquement le
brouillon en attente de confirmation — elle se vidait après validation,
sans rien montrer de ce qui venait d'être enregistré. Une nouvelle
section, alimentée par `echeancesResoluesPourDate` (même registre que
l'écran Historique, filtré sur la date ouverte), reste affichée en
permanence pendant la journée en cours et montre chaque paiement déjà
enregistré (membre, carnet, montant, heure, agent) — pas seulement au
moment de la confirmation.

**Statut d'une amende visible dans l'Historique.** `statutsAmendes`
renvoie, pour chaque amende d'un cycle, `en_attente` / `reglee` /
`annulee` (miroir de `confirmedAt` et des lignes `AmendeAnnulations`
déjà en place — aucune nouvelle colonne). L'écran Historique affiche ce
statut à côté de chaque échéance concernée, plutôt que de créer un
écran séparé.

**Libellés de fréquence clarifiés.** "Hebdomadaire (une fois par
semaine)", "Bimensuelle (deux fois par mois)", "Mensuelle (une fois par
mois)" — texte seul, aucun changement de comportement
(`formatMeetingFrequency`).

## Amende seule, jamais de rattrapage (2026-08-09)

**Contradiction avec une décision antérieure, tranchée explicitement
par le fondateur** : la décision du 8 août ("Parts libres par
cotisation, minimum 1") prévoyait qu'une échéance manquée pouvait être
rattrapée plus tard (jusqu'à 5 parts en une fois). Après un test réel,
le fondateur a tranché différemment : **une échéance manquée reste
définitivement à 0 part** — seule l'amende prédéfinie s'applique,
aucun mécanisme ne permet plus de la rattraper. La fourchette "1 à 5
parts par jour" reste vraie, mais elle ne sert plus qu'à un choix
volontaire du membre de déposer plusieurs parts le même jour dans un
même carnet (pas à rattraper une autre date).

**Conséquences en cascade** :
- `EcheanceCalculator.soldeDuFcfa` retiré — plus aucun "arriéré" à
  calculer.
- `Echeances.arrieresFcfa` devient un champ vestige, toujours 0 (gardé
  pour ne pas casser les lignes déjà écrites, plutôt qu'une migration
  de suppression de colonne).
- `Echeances` gagne `partsPayees` (int explicite) — une ligne `paye`
  porte désormais le vrai nombre de parts déposées ce jour-là dans ce
  carnet, cumulé si plusieurs transactions se succèdent avant la
  clôture (remplace l'ancien montant toujours égal à 1 part).
- `detteMembreFcfa` (déduction au partage) ne compte plus l'arriéré de
  cotisation — seulement les amendes non soldées et le solde de prêt
  (voir "Déduction des dettes au partage" ci-dessus, dont la portée se
  réduit d'autant).
- `_enregistrerCotisationCarnet` n'a plus besoin de connaître les
  échéances passées d'un membre : une transaction écrit toujours
  exactement une ligne `paye`, à la date de la journée ouverte, avec le
  total cumulé du jour — corrige au passage un risque de paiement
  invisible (voir l'entrée suivante).

## Un paiement ne doit jamais être invisible

**Bug identifié par le fondateur après test réel** : l'ancienne
écriture (`enregistrerCotisationCash` avec le plein nombre de parts
demandées, puis une boucle sur les échéances "rattrapables" pour créer
les lignes `Echeances`) pouvait écrire plus de parts en cotisation
qu'il n'existait d'échéances à leur associer — l'argent était compté
dans les totaux financiers, mais **aucune ligne `Echeances`
n'existait** pour le représenter, le rendant invisible dans la vue du
jour et dans l'Historique (qui lisent toutes les deux ce registre, pas
`Cotisations` directement).

**Décision** : `_enregistrerCotisationCarnet` écrit désormais
**toujours exactement une** ligne `Echeances` `paye` par transaction,
à la date explicitement fournie (la journée ouverte), avec le nombre
de parts réellement traité. Plus aucun scénario ne peut laisser de
l'argent enregistré sans trace visible par date — garanti par
construction, pas par une vérification a posteriori.

## Le plafond journalier se base sur l'échéance, pas sur l'heure de saisie

**Bug trouvé par les tests automatisés** (pas par le fondateur cette
fois) en écrivant le test "plusieurs transactions le même jour pour le
même carnet s'additionnent" : `partsDejaAjouteesAujourdhui` (le calcul
du plafond de 5 parts/carnet/jour, voir "Plafond de 5 parts par carnet
et par jour") filtrait `Cotisations` par `recordedAt` — l'horodatage
réel/simulé de la saisie — comparé au jour calendaire de la date
d'échéance visée. Ces deux dates ne coïncident pas forcément : un agent
peut saisir une journée en retard, ou simplement enregistrer deux
transactions pour la même échéance à des instants réels différents (ce
qui est exactement le scénario que le fondateur a décrit avec Seal —
plusieurs passages dans la même journée). Résultat : la deuxième
transaction ne "voyait" jamais la première, le plafond ne s'appliquait
jamais correctement, et `partsPayees` (voir décision précédente)
pouvait afficher un total inférieur à la réalité au lieu du cumul
attendu.

**Décision** : `Cotisations` gagne une colonne `echeanceDate` (la
journée de cotisation visée par la transaction, distincte de
`recordedAt`). `partsDejaAjouteesAujourdhui` filtre désormais sur cette
colonne — un cumul par échéance, jamais par heure réelle de saisie.
Migration drift schemaVersion 8 → 9 ; mirée côté Postgres dans
`supabase/migrations/0005_parts_payees_et_echeance_date.sql` (comblant
au passage le trou laissé par `partsPayees`, jamais miré côté Supabase
à schemaVersion 8 — toujours sans impact réel puisque la synchronisation
reste inactive, voir ROADMAP.md).

## Amendes en attente masquées tant qu'aucune journée n'est ouverte

**Bug d'écran identifié par le fondateur** (capture d'écran à l'appui) :
la section "Amendes en attente de règlement" s'affichait juste après
la clôture d'une journée, alors même que la section "Ajouter un
encaissement" indiquait "Aucune journée de cotisation ouverte" —
écran contradictoire, rien à faire avec cette liste avant la prochaine
échéance. Décision : la section amendes suit désormais exactement la
même condition d'affichage que la saisie de cotisation
(`journeeCotisationEnAttente` non nul) — elle n'apparaît qu'au moment
où l'agent peut réellement agir dessus.

## Étiquette "carnet" corrigée en "part" sur l'écran de répartition

**Confusion de vocabulaire identifiée par le fondateur** : l'écran de
répartition de fin de cycle affichait "3 carnet(s)" pour un membre —
impossible littéralement (maximum 2 carnets par membre). Il s'agissait
en réalité du cumul des parts achetées sur tout le cycle
(`Cotisations.partsCount` sommé), pas du nombre de carnets détenus.
Correction du texte uniquement ("part(s)" au lieu de "carnet(s)",
"Total parts du groupe" au lieu de "Total carnets du groupe") — aucun
changement de calcul, `EndOfCycleCalculator` reste inchangé.

## Un membre ajouté en cours de cycle ne doit rien avant son entrée

**Bug identifié par le fondateur (2026-08-07)**, vérifié dans le code
avant correction : `Members.joinedAt` existait en base depuis le début
du projet mais n'était utilisé par **aucun** calcul métier. Toutes les
échéances d'un membre étaient calculées depuis `cycle.startedAt` (date
de début du cycle), jamais depuis sa propre date d'entrée. Conséquence
concrète : un membre ajouté après le début du cycle se voyait réclamer
un rattrapage pour des échéances antérieures à son inscription — une
dette qu'il n'a jamais pu éviter puisqu'il n'était pas encore membre.

**Décision** : chaque calcul d'échéances (`AppDatabase
._echeancesPasseesMembre`, utilisé par `enregistrerEncaissementMembre`,
`detteMembreFcfa`, `cloturerJourneeCotisation`, l'écran Cotisations)
s'ancre désormais sur `max(cycle.startedAt, membre.joinedAt)` plutôt
que sur `cycle.startedAt` seul. `AppDatabase.ajouterMembre` accepte
aussi un `joinedAt` optionnel, résolu via `AppClock.now()` par défaut
plutôt que l'horodatage SQL brut (`currentDateAndTime`) — nécessaire
pour que cette date reste simulable en mode debug, comme le reste de la
logique sensible au temps (voir la décision `AppClock`).

## Fonds de solidarité : table séparée, jamais lue par le calculateur

Décision directe du skill `avec-business-rules`, appliquée littéralement :
`EndOfCycleInput` n'a aucun champ qui référence
`fonds_solidarite_contributions`. C'est la garantie de correction la
plus simple possible — le calculateur ne peut pas mélanger les deux
parce que la donnée n'est structurellement pas accessible depuis son
entrée.

## Historique des cotisations regroupé par mois

**Demande du fondateur** : sur un cycle qui court plusieurs mois
(9 mois par défaut), la liste plate de séances de l'écran Historique
devient longue à faire défiler pour retrouver une date précise.

**Décision** : ajout d'un niveau de regroupement par mois au-dessus des
groupes par date déjà existants (`echeancesGroupeesParDate`, inchangé
côté base — regroupement fait uniquement à l'affichage). Chaque mois
("août 2026", via le nouveau `formatMoisAnneeFr`) devient une section
dépliable contenant ses séances ; seul le mois le plus récent est
déplié par défaut, les précédents restent accessibles en un clic sans
encombrer l'écran. Aucun changement de schéma — c'est une
réorganisation d'affichage pure.

## Petites retouches d'écran après test réel de l'APK (2026-08-09, suite)

Quatre retouches mineures, demandées par le fondateur après avoir testé
l'APK précédent — aucune ne change une règle métier, uniquement du
texte ou de la mise en page :

- **"Confirmer telle quelle" → "Payer l'amende"** : le libellé du seul
  bouton qui règle une amende (voir "Une amende ne se règle plus jamais
  automatiquement") était resté un vestige de l'ancien mécanisme
  d'auto-règlement ; renommé pour décrire l'action réelle.
- **Dialogue de clôture de journée** : le titre précise désormais "La
  réunion est terminée — clôturer le [date] ?" plutôt que juste
  "Clôturer le [date] ?", pour que l'agent confirme explicitement que
  la séance est bien finie avant de verrouiller la journée.
- **Section "Amendes en attente" compactée** : chaque amende tenait sur
  trois lignes (nom, puis deux boutons pleine largeur) — resserré en
  une seule ligne par amende (nom + deux petits boutons "Payer" /
  "Erreur", infobulle pour le libellé complet). Un agent avec plusieurs
  amendes en attente ne perd plus tout l'écran de saisie de cotisation
  en dessous.
- **Étoile rouge dans l'Historique** : une date (et le mois qui la
  contient) affiche désormais une étoile rouge si au moins une de ses
  amendes reste `en_attente` (voir `statutsAmendes`) — repérable sans
  déplier chaque séance, dans l'esprit du regroupement par mois
  ("Historique des cotisations regroupé par mois", ci-dessus).

## Résolution automatique du taux de prêt : plafond 3x, dans/hors carnet, fenêtre des 3 derniers mois

**Décision, confirmée avec le fondateur le 2026-08-09** (Phase 2 des
"Règles métier restant à coder", voir ROADMAP.md) : `Prets.interestRatePercent`
n'est plus une copie brute de `cycle.interestRatePercent` — il est
résolu automatiquement à la création du prêt par `LoanRateResolver`,
puis figé sur la ligne comme avant (même principe que `dureeJours`).
Trois points précisés explicitement, chacun avec un choix par défaut
proposé et confirmé :

- **Base du plafond** : le plafond de 3x l'épargne cotisée se compare
  au **total emprunté sur le cycle** (prêts confirmés non soldés du
  membre + ce nouveau prêt), pas au nouveau prêt isolément — empêche de
  contourner le plafond en cumulant plusieurs petits prêts. Base sur le
  **principal** emprunté, pas le solde restant dû avec intérêt (qui
  varie avec le temps sans rapport avec la capacité d'emprunt).
- **Bascule totale, jamais un taux mixte** : dès que le total dépasse
  le plafond, le prêt entier passe à 15 % "hors carnet" — jamais une
  part à 10 % et une part à 15 % sur le même prêt.
- **Fenêtre des 3 derniers mois du cycle** : reclassement automatique à
  15 %, jamais de blocage — cohérent avec le principe déjà appliqué
  partout ailleurs dans l'app (rien n'empêche techniquement une action,
  au pire elle coûte plus cher ou déclenche une amende).

**Implémentation** : `LoanRateResolver` (pure Dart, aucune dépendance à
la base) prend `cotiseTotalFcfa`, `empruntesEnCoursFcfa`,
`principalDemandeFcfa`, `maintenant`, `finDeCycle` et renvoie le taux +
une raison à afficher. `AppDatabase.totalEmprunteEnCoursFcfa` (nouvelle
méthode) somme les principaux des prêts confirmés non soldés d'un
membre, réutilisant `pretsNonSoldesDuCycle`. `LoanBalanceCalculator`
(calcul du solde dû avec intérêt composé) reste entièrement inchangé —
il ne se soucie que du taux déjà figé, jamais de comment il a été
choisi. **Aucune migration de schéma** : `interestRatePercent` existait
déjà sur `Prets`.

**Écran Prêts** : le taux applicable s'affiche en direct pendant la
saisie du montant, avec la raison ("dans le carnet" / "hors carnet :
dépasse 3x l'épargne cotisée" / "hors carnet : dans les 3 derniers mois
du cycle") — l'agent voit pourquoi avant de valider, jamais un chiffre
opaque. La liste des prêts affiche aussi ce libellé pour tout prêt créé
sous ce système (un prêt importé garde l'ancien taux plat du cycle,
sans ce libellé — il précède cette règle).

**Valeurs codées en dur** (multiplicateur 3x, taux 10/15 %, fenêtre 3
mois) — configurables par groupe dans un second temps, décision déjà
actée (voir ROADMAP.md).

## Nouvelle formule de partage : caisse disponible (2026-08-09, remplace la formule intérêts+amendes/parts)

**Décision, récap validé point par point avec le fondateur avant
implémentation** — remplace entièrement l'ancienne formule (skill
avec-business-rules : "cotisation + intérêts/amendes proratisés").

**Formule** :
```
caisse_disponible = cotisations + amendes réglées + intérêts perçus
                     − dettes en cours
valeur_par_part    = caisse_disponible ÷ total_parts_du_groupe
```
- **"Dettes en cours"** = uniquement le capital des prêts confirmés pas
  encore intégralement remboursés, tout le groupe. Jamais l'intérêt
  hypothétique dessus (jamais perçu, donc jamais entré dans la caisse).
- **"Intérêts perçus" et implicitement "prêts remboursés"** suivent le
  principe **"tout ou rien"** déjà appliqué par
  `totalInteretsPercusDuCycle` avant cette série : un prêt ne compte
  comme remboursé que si la **totalité** (capital + intérêt) est
  rentrée dans la caisse — un remboursement partiel, même à 90 %,
  compte comme "pas encore remboursé" (donc dans "dettes en cours").
  Pas de terme séparé "prêts remboursés" : le capital revient
  simplement dans la caisse sans traitement spécial (il n'en avait
  jamais été retiré comptablement quand le prêt a été décaissé).
- **"Amendes"** = uniquement les amendes **réglées** (confirmées, non
  annulées) — jamais celles encore en attente ni annulées. Corrige au
  passage `totalAmendesDuCycle` (utilisé ailleurs), qui comptait
  toutes les amendes émises sans distinguer leur statut.
- **La caisse ne descend jamais sous zéro** — un groupe dont les prêts
  non remboursés dépassent le reste de la caisse ne "doit" rien à
  personne au-delà de ce qu'il a réellement (même principe que
  `LoanBalanceCalculator`, "le solde dû ne descend jamais sous zéro").

**Un membre endetté au moment du partage ne touche aucun bénéfice
collectif, quel que soit le montant de sa dette** : son montant brut
est plafonné à **sa cotisation exactement** (`valeur_par_part × ses
parts` ne s'applique qu'aux membres sans dette). Exemple donné par le
fondateur : cotisé 500 000 F, dette 100 000 F au partage → reçoit
exactement 400 000 F (jamais un centime de plus, jamais un centime de
moins que cotisation − dette).

**"Dette" pour ce plafonnement individuel = exactement
`AppDatabase.detteMembreFcfa` inchangé** (amendes non soldées + solde
de prêt confirmé non remboursé) — confirmé explicitement avec le
fondateur. Ce choix résout élégamment la question du double comptage
soulevée pendant la discussion : un membre endetté ne touchant de toute
façon aucun bénéfice collectif (brut plafonné à sa cotisation), lui
déduire ensuite sa dette (comme avant, `DebtDeductionCalculator`
inchangé) n'est pas un double comptage — c'est le même mécanisme déjà
testé, appliqué sur un brut différent selon qu'il y a dette ou non.
**Aucun changement nécessaire dans `detteMembreFcfa` ni
`DebtDeductionCalculator`.**

**Conséquence assumée** : contrairement à l'ancienne formule, un
membre n'a plus la garantie de récupérer au moins sa propre cotisation
— si la caisse est diluée par des prêts non remboursés, **tout le
monde** encaisse une part de cette perte proportionnellement à ses
parts, y compris les membres qui n'ont jamais emprunté (voir le test
"une dilution partielle réduit la part de TOUS les membres").

**Implémentation** : `EndOfCycleCalculator` entièrement réécrit
(`MemberCycleInput`/`MemberCycleResult`/`EndOfCycleInput`/
`EndOfCycleResult` — noms de champs changés, casse le code appelant
existant, corrigé partout). Nouvelles méthodes DB :
`totalCotisationsDuCycle`, `totalAmendesRegleesDuCycle`,
`totalPrincipalNonRembourseDuCycle`. `cycle_summary_screen.dart` et
`member_home_screen.dart` mis à jour ; un cycle déjà clos relit
désormais uniquement le résultat déjà réparti par membre (figé à la
clôture), sans reconstituer la caisse/valeur par part de l'époque (non
conservées telles quelles). Aucune migration de schéma nécessaire.

## Catalogue de motifs d'amende (2026-08-09)

**Décision** : nouvelle table `MotifsAmende` (par groupe) — libellé +
montant, activable/désactivable. Remplace la saisie entièrement libre
(motif texte + montant retapés à chaque amende) par un choix rapide
dans une liste, sans supprimer la flexibilité pour les cas hors
catalogue.

**Volontairement pas une table financière en ajout seul** comme
`Amendes` : c'est de la configuration (même statut que `Groups`/
`Cycles`), pas une transaction — CRUD normal (créer, renommer, changer
le montant, désactiver). **Aucune référence vivante entre un motif et
les amendes déjà enregistrées avec lui** : `Amendes.motif`/
`montantFcfa` restent de simples valeurs texte/entier copiées au
moment de la saisie. Modifier ou désactiver un motif du catalogue ne
change donc jamais rétroactivement une amende déjà enregistrée (testé
explicitement).

**Désactiver, jamais supprimer** : un motif retiré du choix proposé
pour une nouvelle amende reste visible dans l'écran de gestion (pour
pouvoir le réactiver), jamais une suppression — cohérent avec le
principe déjà appliqué ailleurs dans l'app (rien ne disparaît
silencieusement).

**Écran "Ajouter une amende"** : liste déroulante des motifs actifs du
groupe (choisir un motif pré-remplit libellé et montant, les deux
restant modifiables) + option "Autre" qui garde la saisie entièrement
libre d'avant. Un groupe sans aucun motif configuré retrouve
exactement l'ancien formulaire — rien ne change pour lui.

**Nouvel écran "Motifs d'amende"** accessible depuis la fiche groupe
(au même niveau que "Membres").

## Délai de recouvrement des prêts aligné sur les réunions (2026-08-09)

**Décision, validée avec le fondateur** : la borne de fin de période
d'un prêt (`dureeJours`, ex. 90 jours) n'est plus le calcul calendaire
brut (`début + dureeJours` exactement) — c'est **la dernière vraie
réunion du groupe au plus tard à cette date**, jamais une réunion
après, même si elle est numériquement plus proche du délai configuré.
Exemple : réunions hebdomadaires le jeudi, début un jeudi + 90 jours =
un mercredi (pas une réunion) → le jeudi précédent est la vraie
échéance, jamais le jeudi suivant (qui dépasserait les 90 jours).

**S'applique à chaque renouvellement de période**, pas seulement le
premier — recalculé à chaque palier franchi par `LoanBalanceCalculator`.

**Ne s'applique jamais à un prêt importé sans durée connue**
(`dureeJours == null`) : ce type de prêt garde son traitement
pré-existant (intérêt appliqué une seule fois à l'import, jamais
recomposé) — il n'a pas de notion de "période" à aligner sur quoi que
ce soit.

**Implémentation** : `LoanBalanceCalculator.calculer` accepte
désormais des paramètres optionnels (`meetingFrequency`,
`paymentDayOfWeek`, `paymentDayOfMonth1`, `paymentDayOfMonth2`) — sans
eux, comportement calendaire brut inchangé (rétrocompatible avec les
prêts déjà en cours dans des groupes sans fréquence de réunion
définie). Réutilise `EcheanceCalculator.echeancesPassees()` en interne
pour trouver "la dernière réunion ≤ la date brute". `loans_screen.dart`
transmet désormais ces paramètres depuis le groupe.

## Les amendes ne sont plus une dette (2026-08-09)

**Décision, récap validé point par point avec le fondateur avant
implémentation** — corrige "Déduction des dettes au partage" (ci-dessus) :
une amende, quelle que soit sa nature (manuelle ou auto-générée pour
absence), **n'est plus jamais comptée comme une dette**.
`AppDatabase.detteMembreFcfa` ne représente désormais **que le solde de
prêt confirmé non remboursé** — le terme "amendes non soldées" en a été
retiré.

**Deux façons de régler une amende** :
- **Cash**, à tout moment avant la clôture du cycle : inchangé, rejoint
  simplement la caisse comme avant.
- **Par déduction automatique de la cotisation**, si toujours impayée à
  la clôture du cycle — mécanisme donné par le fondateur avec plusieurs
  exemples chiffrés (10 000 F cotisés/10 parts, amende de 100 F → 9
  parts ; amende de 1800 F → 8 parts ; amende de 200 F → 9 parts + 800 F
  de résidu) :
  ```
  reste           = rawCotisationFcfa − min(amendesNonSoldeesFcfa, rawCotisationFcfa)  (jamais négatif)
  partsReconnues  = reste ÷ valeurPartFcfa (division entière)
  résidu          = reste − partsReconnues × valeurPartFcfa
  ```
  Les `partsReconnues` génèrent une part du bénéfice collectif comme
  d'habitude ; le `résidu` revient au membre tel quel, **sans aucun
  bénéfice dessus** ; le montant effectivement déduit (= le montant de
  l'amende, plafonné à la cotisation brute — **jamais une dette
  résiduelle si l'amende dépasse la cotisation**, l'excédent n'est
  simplement pas recouvré) rejoint le terme "amendes réglées" de la
  caisse exactement comme s'il avait été payé cash.

**Composition avec une dette de prêt** : si un membre a À LA FOIS une
amende non soldée ET une dette de prêt, la réduction pour amende
s'applique **d'abord** (sur sa cotisation brute), puis le plafond
"dette de prêt" habituel (`DebtDeductionCalculator`, inchangé)
s'applique sur le montant déjà réduit — jamais l'inverse.

**Le pot commun exclut toujours le résidu** — point de correction
technique découvert en implémentant (pas explicitement demandé par le
fondateur, mais nécessaire à la cohérence comptable) : si le résidu
d'un membre était inclus dans le total mis en commun pour calculer
`valeur_par_part`, ET reversé une seconde fois intégralement à ce même
membre en plus de son bénéfice sur ses parts reconnues, de l'argent
serait inventé à chaque cycle où un résidu existe. Le pot ne contient
donc que `sum(partsReconnues × valeur_de_la_part)`, jamais les résidus
— voir la doc de `EndOfCycleInput.cotisationsTotalesGroupeFcfa` et le
test "conservation" ajouté dans `end_of_cycle_calculator_test.dart`.

**À la clôture du cycle, toute amende encore non soldée est
automatiquement marquée réglée** (par déduction) — jamais laissée
"en attente" après une clôture, y compris les amendes auto-générées
pour absence.

**Implémentation** :
- `AmendeReductionCalculator` (nouveau, pur) : la formule ci-dessus.
- `EndOfCycleCalculator`/`MemberCycleInput` : nouveau champ
  `residuSansBonusFcfa`, ajouté au montant brut d'un membre sans dette
  de prêt (en plus de son bénéfice sur les parts reconnues) ; déjà
  inclus dans `cotisationTotaleFcfa` pour un membre avec dette de prêt
  (jamais ajouté deux fois).
- `AppDatabase.preparerPartageCycle` (nouveau) : point d'entrée partagé
  qui applique la réduction membre par membre — réutilisé par
  `cloturerCycleEtOuvrirSuivant` (clôture réelle, marque aussi les
  amendes réglées), `cycle_summary_screen.dart` (prévisualisation d'un
  cycle en cours) et `member_home_screen.dart` (vue membre), pour que
  les trois ne divergent jamais.
- `detteMembreFcfa` : le terme "amendes non soldées" retiré, ne
  retourne plus que le solde de prêt.

## Écran Cotisations moins chargé (2026-08-09)

**Décision, récap validé avec le fondateur avant implémentation** :
l'écran Cotisations devenait trop chargé (motif du fondateur : "l'écran
saisie des encaissements commence à avoir beaucoup d'informations").

**"Ajouter une amende" et "Contribution fonds" accessibles directement
pendant la saisie des encaissements** — pas seulement depuis l'écran
Répartition : deux icônes compactes dans l'AppBar de l'écran
Cotisations, mêmes dialogues que sur l'écran Répartition (code
factorisé dans `amende_fonds_dialogs.dart`, plus jamais dupliqué entre
les deux écrans).

**La section "Amendes en attente" (auto-générées pour absence) devient
bloquante** : la saisie de cotisation (section "2. Ajouter un
encaissement") reste masquée tant qu'il en reste. Corollaire découvert
en implémentant, nécessaire pour distinguer deux actions désormais
séparées :
- **"Confirmer telle quelle"** — valide seulement que l'absence est
  réelle, **ne règle rien**, débloque la saisie. L'amende reste "non
  soldée" (comptera pour la réduction de parts au partage — voir "Les
  amendes ne sont plus une dette").
- **"Payer"** (cash) — règle immédiatement, débloque aussi, rejoint la
  caisse tout de suite.

**Nouvelle colonne `Amendes.reviewedAt`** (schemaVersion 11), distincte
de `confirmedAt` (règlement) : nécessaire car l'ancien champ unique
`confirmedAt` ne pouvait pas représenter "revue mais pas payée" — la
liste bloquante (`amendesEnAttenteRevue`) filtre désormais sur
`reviewedAt`, jamais `confirmedAt`. Régler une amende (`confirmerAmende`)
renseigne aussi `reviewedAt` s'il ne l'était pas déjà (payer directement
équivaut à l'avoir revue, sans étape intermédiaire obligatoire).

**Le règlement cash reste possible à tout moment avant la clôture du
cycle**, y compris après avoir quitté la liste bloquante : un rappel
actionnable ("Payer") apparaît dès qu'un membre sélectionné pour une
cotisation a des amendes non soldées, quelle qu'en soit l'origine
(manuelle ou auto-générée, déjà revue ou non).

## Clôture de cycle conditionnée au paiement de tous les membres (2026-08-09)

**Décision, récap validé avec le fondateur avant implémentation** : un
cycle ne peut plus être clôturé tant que tous les membres ayant des
parts sur ce cycle n'ont pas été explicitement confirmés comme ayant
reçu leur versement de fin de cycle — y compris un membre endetté dont
le montant net est 0 (l'agent confirme quand même que la situation a
été traitée/communiquée).

**Case à cocher "payé" par membre**, sur l'écran Répartition, visible
uniquement pour un cycle `en_cours` (jamais pour un cycle déjà clos —
figée par construction : l'écran ne rend plus ces cases modifiables une
fois le cycle clos). Librement décochable avant la clôture (erreur de
saisie) — voir `AppDatabase.annulerConfirmationPaiementMembre`.

**Bouton "Clôturer ce cycle" désactivé tant qu'il reste au moins un
membre non confirmé** — avec le décompte affiché ("X membre(s) pas
encore confirmé(s)"). **Vérifié aussi côté base de données**
(`cloturerCycleEtOuvrirSuivant` lève une erreur si un membre du calcul
de partage n'est pas confirmé), pas seulement le bouton désactivé côté
écran — même principe que les autres invariants de cette méthode. Un
cycle sans aucun membre à répartir (jamais aucune cotisation) n'a rien
à confirmer, se clôture normalement.

**Nouvelle table `PartagePaiementConfirmations`** (schemaVersion 11 →
12) : table de configuration/workflow (comme `CarnetsEngages`), pas
financière/hash-chaînée — une ligne par (cycle, membre) confirmé,
librement supprimable tant que le cycle est en cours.

## Mode de paiement de l'amende demandé immédiatement (2026-08-09)

**Décision, récap validé avec le fondateur avant implémentation** —
affine "Écran Cotisations moins chargé" (ci-dessus) : le mode de
paiement d'une amende (cash aujourd'hui, ou plus tard) n'est plus une
action optionnelle et séparée — il est **demandé immédiatement et
obligatoirement**, à deux moments :
- au moment où une amende est **ajoutée manuellement** (dialogue
  "Ajouter une amende", écrans Cotisations et Répartition) — juste
  après avoir validé membre/motif/montant ;
- au moment où l'agent **confirme une amende auto-générée pour
  absence** (bouton unique "Confirmer", remplace les anciens
  "Confirmer telle quelle" + "Payer" séparés).

**Ce choix est définitif** : une fois "plus tard" choisi, l'amende ne
peut plus jamais être réglée cash — elle sera automatiquement déduite
de la cotisation du membre à la clôture du cycle (mécanisme déjà en
place, voir "Les amendes ne sont plus une dette" ci-dessus, inchangé).
**Conséquence directe** : le bouton "Payer" du rappel par membre sur
l'écran Cotisations (ajouté dans "Écran Cotisations moins chargé") est
**retiré** — il permettait un règlement cash différé, désormais
impossible par construction. Le rappel reste affiché mais devient
purement informatif.

**"Erreur" (amende auto-générée saisie par erreur) reste totalement
inchangé** — ce n'est pas un mode de paiement mais une correction de
données (`corrigerAmendeErreur`, annule l'amende et enregistre la
cotisation manquante), disponible indépendamment du choix cash/plus
tard.

**Aucun nouveau mécanisme de calcul** : `AppDatabase.confirmerAmende`
(cash) et `AppDatabase.validerAmendeTelleQuelle` (plus tard) existaient
déjà et faisaient exactement ce qu'il fallait — cette décision ne
change que l'interface (choix systématique et immédiat, jamais laissé
en suspens) et retire une possibilité de règlement cash tardif devenue
incohérente avec "définitif".

**Implémentation** : `askAmendePaymentMode` (nouveau, dans
`amende_fonds_dialogs.dart`, partagé) — dialogue à deux boutons, sans
option d'annulation (l'amende existe déjà, un choix est obligatoire).
`showAddAmendeDialog` l'appelle après l'enregistrement de l'amende.
`record_cotisation_screen.dart` : bouton "Confirmer" unique dans la
section bloquante, appelle `validerAmendeTelleQuelle` puis
`askAmendePaymentMode`, et `confirmerAmende` seulement si "cash".

## Numéro de série physique par carnet (2026-08-10)

**Décision** : un carnet devient une vraie entité identifiable, avec
son propre numéro de série **unique par groupe** (jamais réutilisé),
format `C-001`, `C-002`... — volontairement différent de `carnetNumero`
(1 ou 2, la position du carnet chez son membre) pour ne jamais confondre
les deux dans l'interface.

**Génération** : l'app propose automatiquement le prochain numéro
disponible dans la séquence du groupe, à chaque carnet engagé
(`AppDatabase.definirCarnetsEngages`) ; l'agent peut le remplacer
manuellement (`genererOuRecupererCarnet(numeroSerieManuel: ...)`) si le
membre a déjà un vrai carnet physique numéroté, ou le corriger après
coup (`redefinirNumeroSerieCarnet`).

**Persistant, pas recréé à chaque cycle** : une ligne par (membre,
carnetNumero) — créée une seule fois, réutilisée telle quelle à chaque
cycle suivant où ce créneau est réengagé.

**Implémentation** : nouvelle table `Carnets` (schemaVersion 12 → 13),
volontairement **pas** une table financière en ajout seul (comme
`CarnetsEngages`) — le numéro peut être corrigé. Ne remplace pas
`CarnetsEngages` (qui reste le choix, par cycle, du nombre de carnets)
ni `carnetNumero` sur `Cotisations`/`Echeances`/`Amendes` (clé technique
interne inchangée) — purement un registre auxiliaire de numéros
affichés, jamais une migration de clé étrangère.

## Motifs d'amende prédéfinis (2026-08-10)

**Décision** : 3 motifs système créés automatiquement à la création de
chaque groupe (jamais rétroactivement pour un groupe existant, pas de
valeur à deviner pour ses montants) — "Absence" ("Le membre n'est pas
présent à la réunion."), "Part impayée" ("Le membre n'a pas acheté de
parts aujourd'hui."), "Payé par un tiers" ("Le membre est absent, mais
quelqu'un d'autre a apporté son paiement à sa place."). Chacun a un
libellé explicatif en français simple, affiché à l'agent en plus du nom
court.

**Montants fixés à la création du groupe** (comme la valeur du carnet,
le taux d'intérêt...), 0 par défaut si non précisés — modifiables
ensuite comme n'importe quel motif (`modifierMotifAmende`).

**Implémentation** : `MotifsAmende` gagne `description` et
`codeSysteme` (schemaVersion 13 → 14) — `codeSysteme` est une copie
figée (`absence`/`part_impayee`/`paye_par_tiers`), jamais une référence
vivante, qui permet de reconnaître ces 3 motifs même renommés. Un motif
personnalisé du groupe garde `codeSysteme == null`.

## Validation de cohérence des motifs par carnet (2026-08-10)

**Décision** : les 3 motifs système ne peuvent jamais se contredire
pour un même carnet à une même échéance —
- si une cotisation existe déjà pour ce carnet à cette échéance :
  "Part impayée" devient impossible (il a réellement payé) ;
- si "Payé par un tiers" a déjà été appliqué pour ce carnet à cette
  échéance : "Absence" et "Part impayée" deviennent impossibles aussi
  (sa cotisation est considérée reçue) ;
- si rien n'est enregistré du tout pour ce carnet à cette échéance :
  les 3 motifs système restent possibles, à l'agent de choisir celui
  qui correspond à la réalité.

**Toujours par carnet, jamais par membre entier** — un membre à 2
carnets peut avoir réglé le carnet 1 et rien pour le carnet 2 : les
motifs système restent applicables au carnet 2 seulement.

**Implémentation** : `AppDatabase.motifsSystemeApplicables` — fonction
pure de lecture (pas de règle imposée côté écriture, l'écran l'utilisera
pour n'afficher que les choix pertinents). Amendes gagne `carnetNumero`,
`echeanceDate` et `motifCodeSysteme` (schemaVersion 14 → 15) — permet
cette validation et prépare "Amende par carnet, pas par membre"
(prochaine décision).

**Pas encore pris en compte** : une éventuelle contribution de
solidarité (Groupe B, pas encore construit) pourrait devenir un signal
supplémentaire de présence — à revoir une fois ce chantier en place.

## Amende par carnet, pas par membre (2026-08-10)

**Décision** : un membre à 2 carnets absent reçoit **2 amendes
distinctes**, une par carnet — **annule la décision inverse du 9 août**
("absence à une réunion est un événement par personne, pas par
carnet").

**Implémentation** : `cloturerJourneeCotisation` applique désormais
l'amende de retard (si `Cycles.lateFeeFcfa > 0`) à l'intérieur de la
boucle par carnet, plutôt qu'une seule fois par membre avant la boucle
— chaque amende porte son propre `carnetNumero`, son `echeanceDate` et
`motifCodeSysteme: 'absence'` (voir "Motifs d'amende prédéfinis").
`echeances_ledger_test.dart` réécrit en conséquence (le test qui
vérifiait l'ancien comportement vérifie maintenant l'inverse).

**Reste volontairement séparé** de `MotifsAmende` "Absence" (montant
fixé une fois à la création du groupe) : l'amende automatique continue
d'utiliser `Cycles.lateFeeFcfa` (configurable à chaque cycle, mécanisme
préexistant, déjà testé) — les deux champs représentent aujourd'hui la
même idée sans être unifiés. Signalé dans RETOURS_TERRAIN.md comme
question ouverte, pas tranché unilatéralement.

## Paiement partiel d'une amende (2026-08-10)

**Décision** : un membre peut s'acquitter d'une amende **en plusieurs
fois**, à tout moment (voir DECISIONS.md, "Règlement d'une amende à
tout moment", 2026-08-10) — plus un simple booléen soldée/non soldée.

**Implémentation** : nouvelle table `AmendePaiements` (schemaVersion 15
→ 16), même principe que `PretRemboursements` pour les prêts —
plusieurs paiements peuvent s'accumuler contre la même amende.
`AppDatabase.enregistrerPaiementAmende` règle tout ou partie du solde
restant, et marque l'amende `confirmedAt`/`reviewedAt` dès que ce
solde atteint 0 (peu importe le nombre de paiements qui y ont mené) —
même règlement final que [confirmerAmende], qui reste inchangé (règle
toujours la totalité en un seul geste, toujours utilisable directement).
`montantAmendesNonSoldeesFcfa` compte désormais le **solde restant**
de chaque amende non confirmée, pas son montant brut d'origine.

## Écran membre consolidé (2026-08-11)

**Décision** : quand l'agent clique sur le nom d'un membre depuis
l'écran Membres, il arrive sur une fiche unique qui regroupe la
cotisation, les amendes non soldées et les prêts en cours de ce membre
— au lieu de naviguer entre l'écran Cotisations et l'écran Prêts (voir
RETOURS_TERRAIN.md, points 1 et 7).

**Implémentation** : nouvel écran
`lib/features/cotisations/member_session_screen.dart`
(`MemberSessionScreen`), accessible via un `onTap` sur chaque
`ListTile` de `members_screen.dart` (uniquement quand un cycle est en
cours — sinon message invitant à ouvrir un cycle d'abord). Trois
sections, additives, aucune ne dépend des deux autres :

1. **Cotisation** — même logique de saisie par carnet (plafond
   quotidien de 5 parts, voir `EcheanceCalculator`) que l'écran
   Cotisations, mais enregistrement immédiat pour ce seul membre
   (`enregistrerEncaissementMembre`) plutôt qu'un brouillon groupé.
   Respecte le même verrou qu'avant (aucune saisie tant qu'une amende
   du groupe attend d'être revue, voir "Écran Cotisations moins
   chargé") pour ne jamais contredire l'écran Cotisations.
2. **Amendes** — liste des amendes non soldées du membre avec leur
   solde restant (voir "Paiement partiel d'une amende"), bouton
   "Payer" (partiel ou total) et "Ajouter une amende" (réutilise
   `showAddAmendeDialog`, déjà partagé avec l'écran Cotisations et
   l'écran Répartition).
3. **Prêts** — prêt(s) confirmé(s) du membre sur ce cycle avec solde
   dû (`LoanBalanceCalculator`, même calcul qu'`écran Prêts`) et bouton
   "Rembourser". La création d'un nouveau prêt et la confirmation
   SMS/signature restent sur l'écran Prêts (hors scope ici — flux déjà
   complexes, pas dupliqués).

Le dialogue de remboursement, auparavant privé à `loans_screen.dart`,
a été extrait dans `lib/features/loans/loan_repayment_dialog.dart`
(`showLoanRepaymentDialog`) pour être partagé entre les deux écrans —
même principe que `amende_fonds_dialogs.dart` : un seul code, jamais
dupliqué.

**Volontairement hors scope pour l'instant** : cotisation
exceptionnelle et contribution au fonds de solidarité obligatoire
(Groupe B, pas encore construit) — viendront s'ajouter comme sections
supplémentaires une fois ce chantier livré.

## Clôture de journée interactive (2026-08-11)

**Décision** : le mécanisme "amende auto-générée → revue différée à la
séance suivante" (`amendesEnAttenteRevue`, bloc "Amendes à valider"
sur l'écran Cotisations) est **entièrement remplacé** par une
résolution **au moment même de la clôture** : pour chaque carnet sans
rien d'enregistré (ni cotisation, ni amende) à la date qu'on clôture,
l'agent choisit interactivement un motif parmi les 3 prédéfinis
(Absence / Part impayée / Payé par un tiers), pré-rempli sur "Absence"
mais modifiable ligne par ligne, avant de valider "Clôturer
définitivement". Plus rien n'est laissé en attente d'une décision
future (voir RETOURS_TERRAIN.md, point 1 : "ces informations ont été
entrées manuellement par l'agent, plus besoin de vérifications").

**Implémentation** :
- `AppDatabase.carnetsATraiterPourDate` (remplace
  `membresAbsentsPourDate` pour l'écran, granularité carnet et non
  membre) — s'appuie sur `motifsSystemeApplicables` (déjà construit,
  voir "Validation de cohérence des motifs par carnet") pour ne
  proposer que les carnets réellement vides, jamais un carnet déjà
  réglé manuellement pendant la journée (ex. "Payé par un tiers"
  ajouté via "Ajouter une amende").
- `cloturerJourneeCotisation` gagne un paramètre `resolutions`
  (`Map<clefResolutionCarnet, codeSysteme>`, optionnel, défaut vide) :
  pour chaque carnet à traiter, applique le motif choisi ; un carnet
  absent de la map retombe sur "Absence" (préserve le comportement
  historique pour les appels qui n'utilisent pas encore l'écran
  interactif — imports, tests). Un carnet déjà réglé manuellement
  pendant la journée relie l'échéance à l'amende existante plutôt que
  d'en créer une nouvelle en double.
- L'amende créée est marquée `reviewedAt` immédiatement (choisie
  interactivement par l'agent, jamais "en attente de revue").
- Écran Cotisations : bloc "Amendes à valider" et gate sur la saisie de
  cotisation supprimés — plus rien ne bloque la saisie. Le dialogue de
  clôture propose désormais un choix de motif par carnet à traiter.
- Écran membre consolidé : `corrigerAmendeErreur` ("le membre avait en
  fait payé") accessible directement sur chaque amende auto-générée,
  reprend le rôle de l'ancien bouton "Erreur".

**Résout la question ouverte** ("Amende par carnet, pas par membre",
2026-08-10) entre `Cycles.lateFeeFcfa` et le montant du motif "Absence"
du catalogue : `lateFeeFcfa` reste **prioritaire quand configuré**
(> 0) — réglage historique, encore modifiable cycle par cycle (voir
`edit_group_screen.dart`) — sinon le montant du catalogue du groupe
s'applique. Pour "Part impayée" et "Payé par un tiers" (aucun
équivalent historique) : toujours le catalogue. Pour un groupe migré
sans catalogue (avant schemaVersion 14) : `lateFeeFcfa` en dernier
recours. Choix fait pour préserver tout le comportement existant
(aucun test cassé) tout en donnant un sens réel au nouveau champ pour
les groupes qui l'utilisent.

## Section "Amendes" dédiée (2026-08-11)

**Décision** : un écran "Amendes" centralise toutes les amendes du
cycle en cours (voir RETOURS_TERRAIN.md, point 5) — plutôt que
dispersées entre l'écran Cotisations et l'écran Répartition. Pas de
nouvelle règle métier : une vue + les actions déjà existantes
ailleurs (payer, corriger une erreur, ajouter une amende).

**Implémentation** :
- `AppDatabase.amendesDuCycle` (nouveau) : toutes les amendes d'un
  cycle, tous membres confondus.
- `AmendesScreen` (`lib/features/amendes/amendes_screen.dart`) : liste
  filtrable (En attente / Réglées / Annulées / Toutes, "En attente"
  par défaut), un bouton "Payer" par amende en attente, "Erreur"
  seulement pour une amende auto-générée (voir `estAutoGeneree`),
  bouton flottant "Ajouter une amende". Accessible depuis l'écran
  Groupe, à côté de Cotisations/Prêts/Répartition.
- `showPayerAmendeDialog`/`showCorrigerAmendeErreurDialog` extraits
  dans `lib/features/cotisations/amende_resolution_dialogs.dart` —
  partagés entre l'écran membre consolidé et ce nouvel écran (même
  principe que `amende_fonds_dialogs.dart`/`loan_repayment_dialog.dart`
  : un seul et même code, jamais dupliqué).

**Avec cet écran, le Groupe A (refonte amendes + écran membre
consolidé) est terminé** : A0 à A7 tous livrés et testés.

## Fonds de solidarité obligatoire (2026-08-11)

**Décision** : le fonds de solidarité peut devenir **obligatoire**
pour un groupe — voir RETOURS_TERRAIN.md, points 6 et 18. Montant fixe
**par carnet**, dû à **chaque réunion**, fixé une seule fois à la
création du groupe (jamais modifiable ensuite — même principe que les
motifs d'amende prédéfinis). Un membre à 2 carnets doit le double.
Souple dans le rythme (un membre peut payer plusieurs mois d'avance ou
accumuler du retard), mais **tout doit être soldé avant le partage de
fin de cycle** — nouvelle condition de clôture, en plus de "tous les
membres confirmés payés" (déjà codé).

**Reste totalement exclu de la caisse principale et jamais redistribué
automatiquement** (point 18, déjà le comportement historique —
`totalFondsSolidarite`/`EndOfCycleCalculator` inchangés) : un solde
restant à la clôture continue simplement d'exister pour le cycle
suivant, sans aucun code supplémentaire nécessaire.

**Implémentation** :
- `Groups.montantSolidariteObligatoireFcfa` (schemaVersion 16 → 17),
  0 par défaut = fonds facultatif (comportement historique préservé
  pour tout groupe existant ou qui laisse le champ à 0).
- `AppDatabase.soldeSolidariteObligatoireFcfa` : montant dû cumulé
  (montant × nombre de carnets × nombre de réunions déjà passées
  depuis l'entrée du membre dans le groupe, même calendrier que la
  cotisation — voir `EcheanceCalculator.echeancesPassees`) moins ce
  qu'il a déjà versé (`FondsSolidariteContributions`, réutilisée telle
  quelle, aucune nouvelle table). Jamais négatif.
- `AppDatabase.soldesSolidariteObligatoireNonSoldesDuCycle` +
  nouvelle vérification dans `cloturerCycleEtOuvrirSuivant` (avant
  même la condition "confirmé payé", pour un membre sans aucune part
  sur ce cycle aussi) : refuse la clôture tant qu'un membre est en
  retard.
- Écran création de groupe : nouveau champ "Fonds de solidarité
  obligatoire — montant par carnet, dû à chaque réunion".
- Écran membre consolidé : nouvelle section "4. Fonds de solidarité"
  (visible seulement si le groupe l'a rendu obligatoire) — solde dû +
  bouton "Contribution" (montant pré-rempli au solde dû, mais **libre**
  contrairement au paiement d'une amende, pour permettre de payer
  d'avance).
- Écran Répartition : le bouton "Clôturer ce cycle" se désactive aussi
  si des membres n'ont pas soldé le fonds obligatoire, avec le nombre
  concerné affiché.

**Reste à faire (Groupe B)** : cotisations exceptionnelles
(mariage/décès/accouchement — voir RETOURS_TERRAIN.md, point 7),
partagent le même solde/suivi que ce chantier.

## Cotisations exceptionnelles (2026-08-11)

**Décision** : une cotisation exceptionnelle (mariage, décès,
accouchement) se déclare **une seule fois** par l'agent — motif,
montant par membre, date limite — et s'applique **automatiquement à
tous les membres déjà présents dans le groupe à cet instant** (jamais
à ceux qui rejoignent après, même principe que [Members.joinedAt] pour
les échéances de cotisation). Réglable à tout moment, en une ou
plusieurs fois, depuis la fiche membre. **Si la date limite passe sans
paiement**, le solde restant est **automatiquement déduit des parts**
du membre à la clôture du cycle — jamais avant, jamais une dette qui
s'accumule (voir RETOURS_TERRAIN.md, point 7).

**Mécanisme de déduction** : réutilise `AmendeReductionCalculator` tel
quel (aucun nouveau calculateur), **chaîné une seconde fois** après la
réduction pour amende non soldée — le "reste" après amende devient le
`rawCotisationFcfa` d'une seconde réduction, une fois par événement
échu et encore dû, dans l'ordre des dates limites. La différence avec
une amende : le montant récupéré n'entre **jamais dans la caisse
principale** (voir "Fonds de solidarité obligatoire" — même principe)
— il est simplement exclu du pot commun et enregistré comme une
contribution automatique au fonds de solidarité, imputée à l'événement
précis. Comme pour une amende, quand la cotisation du membre ne suffit
pas à couvrir tout ce qui est dû, seul ce qui peut l'être est récupéré
— jamais une perte enregistrée nulle part pour ce mécanisme précis
(contrairement à une dette de prêt).

**Implémentation** :
- `CotisationsExceptionnelles` (schemaVersion 17 → 18) : événement,
  table financière en ajout seul (comme `Amendes`), jamais modifiable.
- `FondsSolidariteContributions.cotisationExceptionnelleId` (nullable)
  : relie un versement (volontaire ou déduction automatique) à
  l'événement précis qu'il règle — un bucket séparé du fonds
  obligatoire récurrent (`totalVerseFondsSolidariteMembre` exclut
  désormais explicitement ces versements ciblés, pour ne jamais les
  confondre).
- `soldeCotisationExceptionnelleFcfa`/`cotisationsExceptionnellesNonSoldeesDuMembre`
  : solde dû par membre et par événement, 0 pour un membre non
  éligible.
- `preparerPartageCycle` étendu : pour chaque membre, après la
  réduction "amende", boucle sur les événements échus et encore dus,
  réduit le reste une seconde fois par événement (voir mécanisme
  ci-dessus), renvoie `cotisationsExceptionnellesADeduire` (détail par
  membre et par événement — jamais ajouté à la caisse). Purement
  additif : sans événement échu impayé, le résultat est strictement
  identique à avant (aucun test existant modifié).
- `cloturerCycleEtOuvrirSuivant` : à la clôture réelle seulement,
  enregistre chaque déduction comme une contribution automatique
  (`enregistrerContributionFondsSolidarite`, motif "non payée à temps
  — déduite automatiquement").
- Écran "Cotisations exceptionnelles"
  (`lib/features/cotisations_exceptionnelles/`) : déclarer un
  événement, vue d'ensemble de la collecte (membres concernés, total
  collecté / attendu). Accessible depuis l'écran Groupe.
- Écran membre consolidé : nouvelle section "5. Cotisations
  exceptionnelles" — solde dû par événement, bouton "Payer" (montant
  libre jusqu'au solde, jamais plus), rappel visuel si la date limite
  est dépassée.

**Avec ce chantier, le Groupe B est terminé** : fonds de solidarité
obligatoire (récurrent) + cotisations exceptionnelles (ponctuelles),
même solde/suivi, tous deux testés.

## Fenêtres de crédit selon la fréquence de réunion (2026-08-11)

**Décision** : un nouveau prêt ne peut être initié que pendant une
fenêtre de crédit — voir RETOURS_TERRAIN.md, point 10 :
- `hebdomadaire` : le premier prêt seulement à partir de la **4e
  réunion**, puis de nouveau toutes les 4 réunions (8e, 12e...) ;
- `bimensuelle`/`mensuelle` : à chaque **2e réunion** (2e, 4e, 6e...).

Une fenêtre reste ouverte depuis la réunion concernée jusqu'à la
réunion suivante (pas seulement le jour même) — l'agent peut initier
le prêt n'importe quel jour de cette période.

**Implémentation** : `LoanWindowCalculator` (nouveau, pur, comme
`EcheanceCalculator`) — `fenetreOuverte`/`reunionsAvantProchaineFenetre`.
Vérifié dans `AppDatabase.enregistrerPret` pour une écriture `direct`
uniquement (jamais `importe`, qui décrit des prêts déjà accordés dans
le passé). Écran Prêts : bandeau visible tant que la fenêtre est
fermée (nombre de réunions restantes), bouton "Nouveau prêt" désactivé.

## Rationnement des crédits selon la caisse disponible (2026-08-11)

**Décision** : le montant d'un nouveau prêt ne peut jamais dépasser
l'argent réellement disponible dans la caisse — voir RETOURS_TERRAIN.md,
point 13 : "exactement ce qui a été enregistré par l'agent".

**Implémentation** : `AppDatabase.caisseDisponibleActuelleFcfa` =
cotisations + intérêts perçus + amendes réglées − principal des prêts
confirmés pas encore remboursé (réutilise les agrégats déjà construits
pour la formule de fin de cycle). Jamais le fonds de solidarité (voir
DECISIONS.md, toujours exclu). Vérifié dans `enregistrerPret` (écriture
`direct` uniquement, même principe que la fenêtre de crédit ci-dessus).
Écran Prêts : caisse disponible affichée dans le formulaire, montant
demandé validé contre elle avant l'enregistrement.

**Reste ouvert** (voir RETOURS_TERRAIN.md, point 13) : le mécanisme
"demande totale > caisse disponible → réduction proportionnelle
proposée à tous les demandeurs simultanés, chacun accepte ou se
désiste" n'est pas construit — chaque demande de prêt est traitée une
à la fois (premier arrivé, le plafond se réduit pour le suivant), pas
de négociation collective entre plusieurs demandeurs en attente.

**Tests existants adaptés** : ces deux règles ont une portée large (18
appels à `enregistrerPret` dans 9 fichiers de tests) — chaque appel a
été revu individuellement : `provenance: 'importe'` pour les tests qui
ne portent pas sur le moment/montant du prêt (représente un prêt déjà
accordé, hors du champ de ces nouvelles règles), sinon fenêtre et
caisse satisfaites explicitement (date simulée + cotisation
préalable). Aucun test n'a été affaibli ou contourné silencieusement.

**Reste à faire (Groupe C)** : dette de prêt "au rouge" universelle
(10 %/mois après expiration, sortie du rouge, RETOURS_TERRAIN.md point
8) et reconduction d'un prêt non soldé au cycle suivant (point 19).

## Dette de prêt "au rouge" (2026-08-11)

**Décision** : voir RETOURS_TERRAIN.md, point 8. Chaque prêt a **une
seule période normale**, au taux fixé à sa création (10 % ou 15 %,
voir `LoanRateResolver`), sur sa durée habituelle (`dureeJours`,
réunion-alignée comme avant). Si cette période expire sans être
soldée, le prêt passe **"au rouge"** : à partir de là, l'intérêt se
recompose à un taux **universel de 10 %, chaque mois calendaire** —
le même pour tous les groupes, quel que soit le taux d'origine du
prêt. Ça **remplace** entièrement l'ancienne recomposition au taux
d'origine (confirmé par le fondateur : "ça remplace, au même taux,
cadence différente" — comprendre : au même taux *universel* de 10 %,
mais à une cadence mensuelle calendaire, jamais réunion-alignée une
fois au rouge).

**Sortir du rouge : paiement libre** (précisé le 2026-08-11, après
l'implémentation initiale) : le membre apporte, ce jour-là, le montant
de son choix (`montantPayeFcfa`, peut être 0). Le prêt reconduit vaut
alors :

> `montantDuFcfa (dette du jour, principal + intérêts du rouge) +
> amende du groupe − montantPayeFcfa`

- payer exactement les intérêts accumulés + l'amende reconduit le
  principal d'origine tel quel (le cas "standard") ;
- payer plus réduit d'autant le montant reconduit (un vrai
  remboursement, jamais ignoré) ;
- payer moins, ou rien, ajoute la différence au montant reconduit —
  **l'amende n'a jamais de trace séparée** dans ce cas : si elle n'est
  pas payée cash, elle est absorbée dans le nouveau prêt plutôt que de
  rester une amende impayée en parallèle (double comptage sinon).
  Décision explicite du fondateur : "pas de trace séparée".

Le solde reconduit repart pour une période normale fraîche — jamais
déjà au rouge (contrairement à une reconduction au cycle suivant, voir
plus bas) — **au taux résolu comme un prêt neuf** (dans/hors carnet,
plafond 3x, fenêtre des 3 derniers mois — voir `LoanRateResolver`,
"Résolution automatique du taux de prêt") : jamais le taux plat du
cycle, même pour une reconduction. Ce nouveau prêt exige sa propre
confirmation par le membre, exactement comme tout nouveau prêt (code
SMS ou signature) — la sortie du rouge n'est jamais un raccourci qui
contourne le consentement individuel (skill member-consent-rules).

**Passage au rouge vs reconduction** : le passage au rouge lui-même
est **automatique** (calculé par `LoanBalanceCalculator` selon le
temps écoulé, sans aucune action requise). La reconduction (sortir du
rouge, ou reconduire au cycle suivant), elle, est **toujours une
action explicite du gérant** — jamais silencieuse — car l'AVEC peut la
refuser.

**Implémentation** :
- `LoanBalanceCalculator` réécrit : phase 1 (période normale, au taux
  d'origine, réunion-alignée) puis, si elle expire non soldée, phase 2
  (`_calculerAuRouge`, 10 %/mois, calendaire pur via
  `_ajouterUnMoisCalendaire`, jamais réunion-alignée). `LoanBalanceResult`
  gagne `estAuRouge` (bool) et `soldeAuDebutDuRougeFcfa` (int?, base du
  montant à payer pour sortir). Vérifié contre l'exemple chiffré du
  fondateur : 100 000 → 110 000 (1 mois) → 121 000 (2 mois).
- Nouvelles colonnes : `Groups.montantAmendeSortieRougeFcfa` (0 par
  défaut), `Prets.renouvelePretId` (FK auto-référencée, nullable — relie
  un prêt à son successeur), `Prets.estAuRougeDesLeDepart` (bool, faux
  par défaut — vrai seulement pour une reconduction au cycle suivant,
  qui saute la période de grâce). Migration schéma v18 → v19.
- **Prêt "successeur"** : le prêt d'origine n'est **jamais modifié ni
  supprimé** — un nouveau `Pret` est créé, relié via `renouvelePretId`,
  `provenance: 'renouvellement'` (nouvelle valeur — comme `'direct'`,
  exige une vraie confirmation du membre, contrairement à `'importe'`
  qui confirme automatiquement ; mais **exempté** des vérifications
  fenêtre de crédit / caisse disponible d'`enregistrerPret`, puisque
  ce n'est pas de l'argent neuf qui sort de la caisse — juste la même
  dette qui continue sous un nouveau numéro). Mécanisme partagé avec
  la reconduction au cycle suivant (Groupe C4, voir plus bas).
- `AppDatabase.sortirDuRouge({pretId, agentPhone, montantPayeFcfa,
  confirmationCode, maintenant})` : refuse si le prêt n'est pas au
  rouge, ou si `montantPayeFcfa` couvre déjà tout (`StateError` —
  utiliser un remboursement normal dans ce cas, pas une sortie du
  rouge). Enregistre `montantPayeFcfa` comme un vrai remboursement (si
  > 0), résout le taux du nouveau prêt via `LoanRateResolver` (le prêt
  en cours de sortie est exclu du total emprunté, il est sur le point
  d'être remplacé), puis crée le prêt successeur. `AppDatabase.soldePret` :
  petit assembleur réutilisé partout (`detteMembreFcfa`, écrans Prêts
  et membre consolidé) pour ne calculer le solde qu'à un seul endroit.
- Écran Prêts : le dialogue "Sortir du rouge" affiche les intérêts
  accumulés et l'amende, propose un champ "Montant payé aujourd'hui"
  pré-rempli au minimum requis (modifiable), et prévisualise en direct
  le montant reconduit et son taux résolu (dans/hors carnet) — même
  principe que le dialogue "Nouveau prêt".
- **Double comptage évité** : un prêt qui a un successeur connu
  (`renouvelePretId` non nul quelque part) est **exclu** de
  `pretsNonSoldesDuCycle` et de `detteMembreFcfa` — sa dette restante
  vit désormais uniquement sur le prêt successeur, jamais les deux à
  la fois. Bug découvert et corrigé pendant la construction (pas
  signalé par le fondateur), via un nouveau helper interne
  `_idsDesPretsRenouveles()`.
- Écran Prêts : indicateur "AU ROUGE" visible sur chaque prêt concerné
  (montant de départ du rouge affiché), bouton "Sortir du rouge"
  (affiche les intérêts et l'amende à payer avant de confirmer),
  réutilise le même flux de confirmation (code SMS / signature) qu'un
  nouveau prêt. Écran membre consolidé : indicateur "AU ROUGE" affiché
  en lecture seule, renvoie vers l'écran Prêts pour l'action (comme un
  prêt non confirmé).
- `showLoanConfirmationDialog` (nouveau, `loan_confirmation_dialogs.dart`) :
  extraction du flux de confirmation code SMS/signature, jusqu'ici
  dupliqué dans l'écran Prêts — même principe que
  `loan_repayment_dialog.dart`. Réutilisé par l'écran de clôture de
  cycle pour la reconduction (voir plus bas).

## Reconduction d'un prêt non soldé au cycle suivant (2026-08-11)

**Décision** : voir RETOURS_TERRAIN.md, point 19. À la clôture d'un
cycle, chaque prêt confirmé non soldé (`pretsNonSoldesDuCycle`) peut
être reconduit dans le **nouveau** cycle qui vient d'être ouvert —
**jamais automatique dans son déclenchement** : l'agent doit obtenir
l'accord explicite du membre, un prêt à la fois ; refuser n'empêche
jamais la clôture, déjà effective à ce stade. Le prêt reconduit entre
**directement "au rouge"** dès sa création (pas de nouvelle période de
grâce) — c'est le même mécanisme "au rouge" que C2 (voir "Dette de
prêt au rouge" ci-dessus), avec le passage de cycle comme second
déclencheur possible (en plus de l'expiration normale d'une période),
jamais un système séparé. Comme tout prêt, il exige sa propre
confirmation par le membre.

**Automatique dans son calcul, manuel dans son déclenchement**
(précisé le 2026-08-11) : contrairement à la sortie du rouge (C2), la
reconduction au cycle suivant **ne propose pas** de paiement partiel
ce jour-là — le montant reconduit est simplement le solde exact de
l'ancien prêt (via `soldePret`), sans négociation. Seule l'action de
*proposer puis obtenir l'accord* reste manuelle.

**Taux résolu comme un prêt neuf** (précisé le 2026-08-11) : jamais le
taux plat du cycle — mêmes règles que C2 (`LoanRateResolver`), évaluées
sur le **nouveau** cycle. Confirmé volontaire par le fondateur même si
la cotisation y démarre à 0 (pousse quasi systématiquement vers "hors
carnet" en tout début de cycle pour un prêt reconduit).

**Implémentation** :
- `AppDatabase.reconduireCyclePret({pretId, nouveauCycleId, agentPhone,
  confirmationCode, maintenant})` : recalcule le solde précis de
  l'ancien prêt via `soldePret` (jamais la version simplifiée de
  `pretsNonSoldesDuCycle`, qui ne sert qu'à signaler un solde, pas à le
  chiffrer), refuse si déjà soldé (`StateError`), résout le taux via
  `LoanRateResolver` (cotisation/emprunts du **nouveau** cycle), puis
  crée le prêt successeur dans le nouveau cycle — même mécanisme
  `renouvelePretId` / `provenance: 'renouvellement'` que la sortie du
  rouge (C2), avec `estAuRougeDesLeDepart: true` cette fois
  (contrairement à une sortie du rouge dans le même cycle, qui repart
  avec une période normale fraîche).
- Écran de clôture de cycle (`cycle_summary_screen.dart`) :
  `_showCloturerCycleDialog` récupère désormais l'identifiant du
  nouveau cycle renvoyé par `cloturerCycleEtOuvrirSuivant`, puis — si
  des prêts étaient non soldés — propose leur reconduction un par un
  via `_proposerReconductions` : une boîte de dialogue par prêt
  ("Prêt non soldé", solde affiché), puis le flux de confirmation
  habituel (code SMS envoyé via `AuthGateway.envoyerCode` avant la
  création du prêt, comme tout nouveau prêt — pas de raccourci).
- Exclusion du double comptage déjà en place pour C2
  (`_idsDesPretsRenouveles`, `pretsNonSoldesDuCycle`/`detteMembreFcfa`)
  s'applique automatiquement ici aussi — l'ancien prêt disparaît de la
  dette de son cycle (déjà clos) une fois reconduit.

**Reste ouvert** : la reconduction n'est proposée qu'**au moment de la
clôture** — si l'agent la refuse ou que le membre est absent ce
jour-là, il n'existe aujourd'hui aucun écran dédié pour la reconduire
plus tard (le prêt reste visible et remboursable comme avant, juste
sans mécanisme de reconduction différée). Non demandé par le dossier
source ; à construire si le besoin se confirme sur le terrain.

**Corrigé (2026-08-11)** : le fondateur a précisé que si un prêt non
soldé **n'est pas reconduit** à la clôture, sa dette doit être
**considérée comme perdue** — la composition "au rouge" ne continue
donc plus après la clôture du cycle pour un prêt resté sans
successeur.

**Implémentation** : `AppDatabase.soldePret` (le seul point d'entrée
du calcul de solde, jamais dupliqué inline ailleurs — `detteMembreFcfa`,
l'écran Prêts et l'écran membre consolidé s'y sont tous les trois
recentrés dans le même passage, précisément pour que ce plafond
s'applique de façon uniforme) plafonne désormais la date utilisée pour
le calcul à `Cycles.endedAt` dès que le cycle du prêt est `cloture` et
que la date demandée (ou `AppClock.now()` par défaut) tombe après
cette clôture — jamais repoussé en avant si la date demandée est
antérieure à la clôture. Un prêt reconduit continue de fonctionner
normalement : son successeur vit sur un cycle différent, non clos,
donc jamais plafonné par cette règle.

**Reste ouvert** : cette perte n'est pas encore **affichée**
explicitement quelque part (proche de la "perte AVEC" déjà utilisée au
partage de fin de cycle) — le prêt reste juste gelé à son solde de
clôture, visible normalement sur l'écran Prêts du cycle fermé, sans
étiquette "perdue" dédiée. Pas demandé pour l'instant ; à construire
si le besoin se confirme sur le terrain.

**Conséquence sur l'annulation de clôture** : `annulerClotureCycle`
exige que le nouveau cycle soit strictement vide (voir DECISIONS.md,
"Clôture explicite de la journée de cotisation") — un prêt reconduit y
étant désormais une donnée réelle, accepter une reconduction rend
cette clôture non annulable automatiquement, au même titre que toute
autre donnée du nouveau cycle. Comportement volontaire, pas un oubli.

Avec ce point, le **Groupe C est terminé**.

## Inscription de nouveaux membres : sans limite, sauf fin de cycle (2026-08-11)

**Décision** : voir RETOURS_TERRAIN.md, point 16. **Remplace**
l'ancienne règle ("inscriptions closes dès la clôture de la première
journée de cotisation") — annulée par le fondateur le 2026-08-10, mais
jamais implémentée jusqu'ici (écart trouvé en inspectant le projet, pas
signalé par le fondateur). Un membre peut désormais rejoindre un
groupe **à n'importe quel moment du cycle**, sauf dans les **2
dernières réunions avant la fin prévue du cycle** — fermeture
automatique à partir de ce seuil, jamais rouverte ensuite.

**Implémentation** :
- `MembershipClosureCalculator` (nouveau, pur, comme
  `LoanWindowCalculator`) — `inscriptionsFermees` / `reunionsRestantesAvantFinDeCycle`,
  basé sur `EcheanceCalculator.echeancesPassees` : compte les réunions
  totales prévues sur tout le cycle (jusqu'à `finDeCycle`) contre
  celles déjà passées à l'instant demandé.
- `AppDatabase.ajouterMembre` : remplace l'ancien contrôle booléen
  (`Cycles.inscriptionsFermeesAt != null`) par cet appel. `Cycles.inscriptionsFermeesAt`
  continue d'être tracé à la clôture de la première journée (aucune
  migration nécessaire) mais devient **purement informatif** — il ne
  ferme plus rien.
- Sensible au temps (comme les fenêtres de crédit) : `[joinedAt]`
  détermine le calcul, `AppClock.now()` par défaut — plusieurs tests
  existants ouvraient un cycle sur une date fixe passée (ex. janvier
  2024) sans fournir `joinedAt` explicite à `ajouterMembre` ; sous
  l'horloge réelle (bien après cette date), le cycle semblait déjà
  terminé. Corrigé en passant `joinedAt` explicitement dans ces tests
  plutôt qu'en affaiblissant la règle.
- 6 nouveaux tests (`membership_closure_calculator_test.dart`), 2 tests
  réécrits dans `seances_cotisation_test.dart` (l'ancien "refuse dès la
  1re clôture" n'a plus de sens, remplacé par "refuse dans les 2
  dernières réunions").

## Rationnement collectif des crédits (2026-08-11)

**Décision** : voir RETOURS_TERRAIN.md, point 13. Le plafond dur "un
prêt ne dépasse jamais la caisse disponible" (déjà livré) ne suffit
pas seul : si **plusieurs membres demandent en même temps** et que le
total dépasse la caisse, chacun doit recevoir une offre
**proportionnelle** à sa demande plutôt qu'un simple "premier arrivé,
premier servi" (qui réduirait le plafond du suivant sans négociation).

**Deux chemins, jamais un seul imposé** (décision explicite du
fondateur) :
- **"Nouveau prêt"** — inchangé, le geste simple et immédiat pour le
  cas courant (un seul demandeur) : caisse et taux vérifiés tout de
  suite, prêt créé en un seul geste.
- **"Demander un prêt" + "Traiter les demandes en attente"** — chemin
  séparé, à utiliser quand plusieurs membres pourraient demander à la
  même réunion : une demande dépose seulement l'intention (montant
  souhaité), **sans** vérifier la caisse tout de suite — c'est
  justement ce qui sera négocié collectivement au moment de traiter la
  file.

**Redistribution immédiate** (décision explicite du fondateur, pas
l'option recommandée initialement — une répartition figée à l'avance
pour tout le lot) : à chaque décision (un demandeur accepte ou se
désiste), la part proposée aux suivants est **recalculée** avec la
caisse et le total encore demandé à cet instant — jamais une
répartition calculée une seule fois puis appliquée telle quelle.

**Formule** (`CollectiveLoanRationingCalculator.allocationProposeeFcfa`) :
pour la première demande encore en attente (ordre FIFO — dépôt le plus
ancien traité en premier), si le total de toutes les demandes en
attente tient dans la caisse, elle est proposée intégralement ; sinon,
`montant × caisse ÷ total`, arrondi à l'entier inférieur (jamais
au-dessus de la caisse réelle par arrondi).

**Implémentation** :
- Nouvelles tables `PretDemandes` (une demande — montant, membre,
  date de dépôt, immuable comme un `Pret`) et `PretDemandeRefus`
  (refus/désistement — toujours une nouvelle ligne, jamais une colonne
  de statut mutable sur `PretDemandes`, même principe que
  `PretAnnulations`). `Prets.demandeId` (nullable) relie un prêt
  accordé (intégral ou réduit) à la demande dont il découle — null
  pour un prêt créé via "Nouveau prêt". Migration schéma v19 → v20.
  Une demande "en attente" est celle qui n'a ni prêt lié ni ligne de
  refus.
- `AppDatabase.demanderPret` : dépose une demande, soumise à la
  fenêtre de crédit (même contrôle que "Nouveau prêt") mais **jamais**
  à la caisse disponible — c'est le sens même de la file d'attente.
- `AppDatabase.prochaineDemandeAvecAllocation` : recalcule, à chaque
  appel, le montant à proposer à la première demande en attente à
  partir de l'état courant (jamais mis en cache) — c'est ce qui rend
  la redistribution immédiate possible.
- `AppDatabase.accepterDemandePret` : crée le prêt réel via
  `enregistrerPret` (mêmes contrôles fenêtre/caisse en filet de
  sécurité), **au taux résolu comme un prêt neuf** (`LoanRateResolver`
  — jamais un taux plat), relié à la demande. Comme tout prêt, il
  exige sa propre confirmation par le membre — **essentiel** : tant
  qu'il n'est pas confirmé, il ne compte pas dans la caisse disponible
  (même principe que "Nouveau prêt"), donc le calcul du demandeur
  suivant serait faux si la confirmation n'était pas menée
  immédiatement après l'acceptation, avant de passer au suivant.
- `AppDatabase.refuserDemandePret` : refus/désistement, nouvelle ligne
  dans `PretDemandeRefus`.
- Écran Prêts : section "Demandes en attente" (nombre affiché, bouton
  "Demander" gated par la fenêtre de crédit comme "Nouveau prêt") et,
  si au moins une demande existe, bouton "Traiter les demandes en
  attente" — boucle un demandeur à la fois (offre affichée, "Accepte" /
  "Se désiste" / "Arrêter (reprendre plus tard)"), avec le même flux de
  confirmation (code SMS/signature) que tout nouveau prêt entre chaque
  décision.
- **Passage au rouge automatique, reconduction manuelle — même
  principe ici** : le calcul de l'offre est automatique, mais chaque
  décision (accepter/se désister) reste un geste explicite de l'agent
  avec le membre, jamais silencieux.

## Amende de retard retirée, catalogue de motifs devient la seule source (2026-08-11)

**Décision, confirmée par le fondateur après le premier test terrain** :
`Cycles.lateFeeFcfa` ("Amende de retard de cotisation") est retiré des
écrans Création/Édition groupe. "Amende Absence" du catalogue de
motifs (voir "Motifs d'amende prédéfinis") devient la seule source du
montant appliqué à la clôture pour une absence — **annule la règle de
priorité** posée dans RETOURS_TERRAIN.md ("Question technique
résolue", 2026-08-11) qui donnait la main à `lateFeeFcfa` quand il
était configuré : sur le terrain, deux champs pour la même idée restait
confus pour l'agent malgré cette règle.

**La colonne `Cycles.lateFeeFcfa` n'est pas supprimée** (migration,
groupes existants) — sert uniquement de dernier recours dans
`_resolutionMotifSysteme` pour un groupe migré sans catalogue (avant
schemaVersion 14, cas déjà prévu avant cette décision).

**Implémentation** : champ retiré de `create_group_screen.dart`,
`edit_group_screen.dart` (et son appel à `modifierGroupeEtCycle`, qui
perd le paramètre `lateFeeFcfa`), de l'affichage `group_detail_screen.dart`
et du pré-remplissage `cycle_summary_screen.dart` (clôture de cycle).
`historical_import_screen.dart` garde son propre champ "Amende de
retard" — import de cycles historiques papier où l'ancienne règle
s'appliquait réellement, pas concerné par cette décision.

## Écran "Séance du jour" — présence anticipée, jamais définitive avant la clôture (2026-08-11)

**Décision, confirmée par le fondateur après le premier test terrain**
(voir RETOURS_TERRAIN.md, point 20.6) : un nouvel écran, dédié à la
réunion et accessible directement depuis Cotisations, regroupe les 4
gestes par membre — cotisation, présence, demande de crédit, amende —
en un seul endroit. Complète `MemberSessionScreen` (écran membre
consolidé, accessible depuis l'onglet Membres, sans présence ni
demande de crédit), ne le remplace pas.

**La présence marquée depuis cet écran reste une intention, jamais
définitive avant la vraie clôture de journée** — choix délibéré pour
ne pas toucher au mécanisme de "Clôture de journée interactive" (déjà
en place, transactionnel, hash-chaîné) : `PresenceAnticipee` (nouvelle
table de config, non hash-chaînée, comme `CarnetsEngages`) enregistre
le motif choisi par carnet, relu par `cloturerJourneeCotisation` comme
valeur par défaut de `resolutions` au lieu de toujours proposer
"Absence". L'agent garde la main pour corriger à la clôture — rien
n'est écrit définitivement (ni échéance, ni amende) avant ce moment-là.
Un "Absent" marqué ici applique le même motif à tous les carnets non
encore traités du membre pour cette date (la présence reste un
événement par personne, pas par carnet — un "Autre motif" reste
disponible pour les cas "part impayée"/"payé par un tiers").

**Implémentation** : `AppDatabase.marquerPresenceAnticipee` /
`effacerPresenceAnticipee` / `presenceAnticipeeDuJour` (schemaVersion
20 → 21). `cloturerJourneeCotisation` nettoie la table pour la date
concernée une fois la journée close — la présence anticipée n'a plus
de sens ensuite. Nouvel écran `SeanceJourScreen`.

**Revu (2026-08-11), même jour** — voir "Écran Cotisation : un seul
écran actionnable par membre" ci-dessous : `SeanceJourScreen` perd ses
4 gestes, redevient un écran de lecture seule. Les mécanismes de cette
décision (présence anticipée, table `PresenceAnticipee`) restent
inchangés — seul l'endroit où l'agent les déclenche change.

## Écran Cotisation : un seul écran actionnable par membre (2026-08-11)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
points 21.1 et 21.2) : `SeanceJourScreen` ("Séance du jour") devient un
écran de **lecture seule** — liste des membres avec statut, tap → récap
de ce qui a déjà été enregistré aujourd'hui, sans aucune action
possible. Toutes les actions (cotisation, présence, amende, cotisation
exceptionnelle, fonds de solidarité, prêt) se concentrent sur un nouvel
écran unique, `CotisationMembreScreen` ("Cotisation"), selon un croquis
fourni par le fondateur : carnets + total en tête, présence
(Présent/Absent), puis une rangée de boutons pour toutes les autres
actions, et un bouton "Enregistrer et passer au membre suivant" pour
enchaîner sans ressortir de l'écran.

**Remplace l'ancien flux "Ajouter un encaissement" + brouillon
multi-membres** de `record_cotisation_screen.dart` (sélection d'un
membre dans un menu déroulant, saisie des parts, ajout à une liste,
confirmation groupée en fin de séance) : ce flux datait d'avant l'idée
d'un écran consolidé par membre et devenait redondant avec elle.
Sélectionner un membre dans ce menu déroulant ouvre désormais
directement `CotisationMembreScreen`.

**Implémentation** : `CotisationMembreScreen` reprend les données déjà
utilisées par `MemberSessionScreen` (amendes non soldées, cotisations
exceptionnelles, fonds de solidarité, prêts) en plus de la cotisation
et de la présence — reste volontairement une fiche de lecture/action
par membre, pas un nouveau modèle de données. `MemberSessionScreen`
n'est pas retiré, reste accessible depuis l'onglet Membres pour un
usage hors réunion.

## Clôture automatique après 23h (2026-08-11)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 21.5) : filet de sécurité contre une journée de cotisation qui
resterait bloquée sans que l'agent parvienne à identifier pourquoi le
bouton "Clôturer" ne s'active pas. Si la journée ouverte a dépassé 23h
de sa propre date, elle se clôture automatiquement.

**Contrainte technique acceptée telle quelle** : un téléphone ne peut
pas exécuter de code à une heure précise pendant que l'app est fermée,
sans service natif Android (jugé disproportionné ici) — la clôture
automatique se déclenche donc à la prochaine ouverture de l'app, dès
que l'heure locale a dépassé le seuil. Rattrape plusieurs journées
d'affilée si l'app est restée fermée plusieurs jours (boucle jusqu'à
la première journée dont le seuil n'est pas encore dépassé).

**Implémentation** :
`AppDatabase.journeeCotisationEnAttenteEtAutoClotureSiDepassee` —
wrapper autour de `journeeCotisationEnAttente` (qui reste, elle, un
pur constat sans effet de bord) : clôture avec les motifs anticipés
depuis l'écran Cotisation s'il y en a (voir "Écran 'Séance du jour' —
présence anticipée" ci-dessus), sinon "Absence" par défaut, exactement
comme une clôture manuelle sans résolutions explicites. Appelée par
`record_cotisation_screen.dart` et `seance_jour_screen.dart` à chaque
chargement.

## Cotisation exceptionnelle modifiable après création (2026-08-11)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 21.6) : assouplit "Cotisations exceptionnelles" ci-dessus
("jamais modifiable ensuite") — motif, montant et date limite d'une
cotisation exceptionnelle déjà déclarée restent modifiables à tout
moment (report de date limite, montant révisé après coup).

**Ce qui ne change pas** : les paiements déjà enregistrés contre elle
(`FondsSolidariteContributions`, hash-chaînée) restent, eux,
définitivement intouchables — seule la définition de l'événement est
modifiable, jamais un mouvement d'argent déjà tracé. Réduire le
montant sous ce qu'un membre a déjà versé ne le met jamais en
trop-perçu négatif (`soldeCotisationExceptionnelleFcfa` reste plafonné
à 0).

**Implémentation** : `AppDatabase.modifierCotisationExceptionnelle` —
simple mise à jour des champs définitionnels de
`CotisationsExceptionnelles`, sans recalcul de hash-chaîne (contrairement
à `enregistrerCotisationExceptionnelle`, qui crée l'événement financier
lui-même, cette mise à jour ne crée ni ne modifie aucun mouvement
d'argent). Bouton crayon par événement sur
`cotisations_exceptionnelles_screen.dart`.

## Résolution immédiate par carnet depuis "Ajouter amende" (2026-08-11)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 22.2) : les boutons Présent/Absent de l'écran Cotisation
disparaissent. L'agent règle une absence, une part impayée ou un
paiement par un tiers en cliquant directement "Ajouter amende" — le
carnet concerné se résout **tout de suite**, plus jamais différé à la
clôture (contrairement à la "présence anticipée" ci-dessus, qui
n'était qu'une intention).

**Précision obtenue avant implémentation** : l'écran de clôture reste
un filet de rattrapage pour un carnet vraiment oublié par l'agent
(déjà son comportement — il ne redemande rien pour un carnet déjà
résolu, voir `carnetsATraiterPourDate`), mais n'a plus vocation à être
le lieu normal de résolution. Le filet de sécurité 23h (ci-dessus)
reste utile pour ce même cas de figure.

**Amendes cumulatives, confirmé** : rien n'empêche d'ajouter une
amende libre (motif personnalisé, hors carnet) en plus d'une
résolution de carnet pour le même membre le même jour — c'était déjà
vrai (`Amendes` en ajout seul, pas de contrainte d'unicité), reconfirmé
explicitement.

**Implémentation** : `AppDatabase.resoudreCarnetImmediat({groupId,
cycleId, memberId, carnetNumero, date, codeSysteme, agentPhone})` —
écrit exactement ce que `cloturerJourneeCotisation` aurait écrit pour
CE carnet (amende si le motif a un montant configuré, puis l'échéance
`non_paye` qui la référence), mais tout de suite. Refuse
(`StateError`) si le carnet est déjà résolu (voir
`motifsSystemeApplicables`). `estAutoGeneree: true` sur l'amende créée
— pas "sans intervention humaine", mais "issue de la résolution par
motif système", même sens que pour une amende posée à la clôture
(cohérent avec `amendesAutoDuMembre` et le bouton "Erreur" de
correction). Sur `cotisation_membre_screen.dart`, "Ajouter amende"
propose d'abord la liste des (carnet, motif) encore possibles puis
"Autre amende (hors carnet)", qui retombe sur le dialogue générique
existant pour un motif personnalisé.

## Numéro de série du carnet saisissable par l'agent (2026-08-11)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 22.1) : le mécanisme de correction du numéro de série existait
déjà en base (`redefinirNumeroSerieCarnet`, voir "Numéro de série
physique par carnet") mais n'était exposé nulle part à l'écran — un
carnet physique déjà numéroté par le groupe doit pouvoir garder son
vrai numéro dès sa création, pas seulement être corrigé après coup.

**Implémentation** : champ optionnel "Numéro du carnet physique N" sur
`members_screen.dart`, à l'ajout d'un membre et à la modification de
ses carnets — laissé vide, le numéro continue de se générer
automatiquement (`genererOuRecupererCarnet`) ; rempli, appelle
`redefinirNumeroSerieCarnet` juste après. Le numéro de série (au lieu
de "Carnet N") s'affiche aussi sur l'écran Cotisation — voir
RETOURS_TERRAIN.md, point 22.3 : sur le terrain, un membre est appelé
par le numéro de son carnet, pas par son nom.

## Un membre = un seul carnet, toujours (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 23.1) après plusieurs allers-retours de clarification : **annule
et remplace** la règle "1 ou 2 carnets par membre" (voir "Table
Carnets avec numéro de série" et le choix historique `nombreCarnets`).
Un vrai carnet physique = un membre = un carnet, systématiquement. Une
personne qui détient deux carnets physiques doit désormais être
inscrite comme **deux membres distincts** dans le groupe, chacun avec
son propre nom et — potentiellement — le même numéro de téléphone
(seule l'unicité ci-dessous s'applique, jamais une contrainte
d'identité réelle).

**Implémentation** : `AppDatabase.definirCarnetsEngages` refuse
désormais tout `nombreCarnets` différent de 1 (`ArgumentError`) ; le
paramètre est conservé uniquement pour compatibilité d'appel. Un
second appel après verrouillage (`lockedAt`) est désormais **idempotent**
plutôt que de lever une `StateError` — il n'y a plus rien à changer
puisque le nombre est fixé. Comme la quasi-totalité du code boucle
`for (carnetNumero = 1; carnetNumero <= nombreCarnets; ...)`, fixer
`nombreCarnets` à 1 à ce point d'entrée unique fait dégénérer
naturellement toutes ces boucles à une seule itération, sans devoir
toucher chaque site d'appel individuellement. `members_screen.dart`
simplifié en cohérence : un seul champ de numéro de série, plus de
choix "1 ou 2 carnets".

**Tests devenus obsolètes, supprimés plutôt que réécrits** : plusieurs
tests démontraient spécifiquement le comportement à deux carnets pour
un même membre (`echeances_ledger_test.dart` : "amende par carnet,
pas par membre" et "peut déposer plus d'une part par carnet le même
jour" ; `presence_anticipee_test.dart` et
`resoudre_carnet_immediat_test.dart` : résolution indépendante de
carnet 1 et 2 ; `fonds_solidarite_obligatoire_test.dart` : "doit le
double") — leur prémisse même (un membre avec deux carnets) n'existe
plus, donc supprimés plutôt que convertis artificiellement en
scénario à deux membres qui n'aurait rien démontré de nouveau.

## Unicité nom + téléphone par groupe (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 23.2), en conséquence directe de la décision ci-dessus : puisqu'un
membre ne peut plus avoir qu'un seul carnet, le même nom complet
(prénom + nom) ou le même numéro de téléphone ne peut plus servir à
créer un second membre **dans le même groupe** — ce serait rouvrir la
porte à un second carnet pour la même personne par un autre chemin.

**Portée strictement limitée au groupe, jamais globale** — précision
explicitement demandée et confirmée par le fondateur : la même
personne, avec le même nom et le même numéro de téléphone, peut
appartenir à autant de groupes/tontines qu'elle veut. Aucune table de
membres partagée entre groupes n'existe ni n'est prévue.

**Implémentation** : `AppDatabase.nomOuTelephoneDejaUtiliseDansLeGroupe`
compare le nom normalisé (`trim` + minuscule) et le numéro de
téléphone exact parmi les membres **actifs** du groupe ; appelée en
tout début d'`ajouterMembre`, qui lève une `StateError` explicite si
l'un des deux est déjà pris. `members_screen.dart` affiche l'erreur
dans un `SnackBar` plutôt que de laisser l'exception remonter
silencieusement (gap pré-existant, comblé au passage).

## Renommage "Cotisation" → "Épargne" dans les textes visibles (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 23.3) : partout où l'agent ou le membre voit le mot
"Cotisation"/"cotisation" à l'écran, le texte devient
"Épargne"/"épargne" — libellés d'écran, titres, boutons, messages
d'aide, textes de dialogue. **Explicitement limité au texte affiché** :
noms de classes, de fichiers, de méthodes, de colonnes de base de
données et documentation (`DECISIONS.md`, `CHANGELOG.md`,
`ROADMAP.md`, `RETOURS_TERRAIN.md`) restent inchangés — seul ce que
l'utilisateur final lit change.

Cas tranchés en cours de route : "Cotisation exceptionnelle" devient
"Épargne exceptionnelle" (le mot apparaît explicitement dans
l'instruction du fondateur, "partout où on a écrit cotisation") ;
inversement, les formes verbales dérivées ("parts cotisées") et le mot
clé de format `type` reconnu par l'import historique
(`historical_import_parser.dart`, valeur littérale `'cotisation'` dans
le CSV/texte collé) sont laissés tels quels — ce ne sont pas des
occurrences du mot "Cotisation" en tant que libellé, et changer le
mot-clé du parseur casserait la compatibilité avec d'anciens exports
sans qu'aucune UI ne l'exige.

**Repéré en chemin, hors périmètre de cette tâche** : `members_screen.dart`
ouvre toujours `MemberSessionScreen` (l'ancienne "fiche membre
consolidée") au tap sur un membre dans la liste, alors que
`RecordCotisationScreen` route vers le nouvel écran
`CotisationMembreScreen` (refonte du point 20.6) pour la même action.
Les deux écrans font désormais des choses très proches en parallèle —
mérite un nettoyage (fusionner ou retirer l'un des deux chemins) une
fois validé avec le fondateur, pas traité ici pour rester dans le
périmètre demandé.

## Fusion des écrans membre — CotisationMembreScreen conservé (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 24.1), en réponse directe au repérage ci-dessus : fusionner les
deux écrans membre, en gardant `CotisationMembreScreen`.

**Implémentation** : `members_screen.dart` ouvre désormais
`CotisationMembreScreen` (même liste de membres que l'écran Membres,
index sur le membre tapé — identique au chemin déjà utilisé depuis
`record_cotisation_screen.dart`) au lieu de `MemberSessionScreen`.
`member_session_screen.dart` et son test supprimés. Les quelques
commentaires de doc qui pointaient vers l'ancien fichier
(`amende_resolution_dialogs.dart`, `cotisations_exceptionnelles_screen.dart`,
`loan_repayment_dialog.dart`) mis à jour vers `cotisation_membre_screen.dart`.

## Correction de motifsSystemeApplicables — carnet déjà résolu (2026-08-13)

**Bug de terrain, diagnostiqué avant tout code puis confirmé par un
test qui reproduisait le symptôme avant correction** (voir
RETOURS_TERRAIN.md, point 24.2, et
`test/data/local/resolution_carnet_deja_resolu_test.dart`) : le
fondateur signalait que "Clôturer cette journée" échouait souvent
après une amende, restait bloqué même en avançant la date simulée, et
qu'une clôture automatique par le filet de sécurité 23h laissait la
réunion suivante vide elle aussi.

**Cause** : `motifsSystemeApplicables` ne reconnaissait un carnet
comme déjà résolu que dans deux cas — une cotisation payée
(`Cotisations`), ou une amende au motif système précis "Payé par un
tiers" (`Amendes.motifCodeSysteme`). Les deux motifs les plus
fréquents depuis "Ajouter amende" — "Absence" et "Part impayée" —
n'étaient jamais reconnus comme une résolution par cette fonction,
alors même que [resoudreCarnetImmediat] écrit systématiquement une
ligne `Echeances` pour ces trois motifs. Rien n'empêchait donc l'agent
de résoudre deux fois le même carnet, ce qui écrivait une **deuxième**
ligne `Echeances` pour le même (membre, carnet, date) — et cassait
ensuite toute requête `getSingleOrNull` qui suppose ce triplet unique :
`cloturerJourneeCotisation`, `carnetsATraiterPourDate`, et le filet de
sécurité 23h (`journeeCotisationEnAttenteEtAutoClotureSiDepassee`, qui
appelle `cloturerJourneeCotisation` en interne — d'où le même symptôme
qu'une clôture manuelle ratée). Le lien avec les prêts mentionné par
le fondateur n'a révélé aucun bug distinct : les prêts n'écrivent
jamais dans `Echeances`, entièrement indépendants du registre de
cotisation.

**Correction** : `motifsSystemeApplicables` vérifie désormais
directement l'existence d'une ligne `Echeances` pour ce (membre,
carnet, date) — quel que soit son statut ou le motif système qui l'a
produite — et retourne `{}` si elle existe, en plus des vérifications
existantes (cotisation payée, "payé par un tiers"), conservées pour ne
rien changer aux cas déjà couverts (notamment l'import historique, qui
peut poser une amende sans ligne `Echeances`). Aucune migration de
données nécessaire — le correctif empêche une nouvelle corruption sans
tenter de réparer d'éventuelles doubles lignes déjà écrites sur le
terrain (aucune connue à ce jour).

## Clôture bloquée par un doublon déjà écrit avant le correctif (2026-08-14)

**Retour terrain** : le correctif ci-dessus n'a pas suffi — la clôture
restait bloquée sur un APK déjà censé le contenir. Cause : le correctif
du 2026-08-13 protège uniquement l'**écriture** (`motifsSystemeApplicables`
empêche une nouvelle ligne en double), mais trois fonctions de
**lecture** utilisaient encore `getSingleOrNull` seul sur `Echeances`
filtré par (membre, carnet, date) — `membresAbsentsPourDate`,
`carnetsATraiterPourDate`, `cloturerJourneeCotisation` elle-même.
`getSingleOrNull` lève une exception dès qu'un **deuxième** résultat
existe. Une seule ligne en double écrite sur un appareil de terrain
avant le 2026-08-13 restait donc piégée en base **définitivement** :
aucune mise à jour de code ne l'efface, et les trois fonctions
continuaient de planter sur ce même triplet à chaque nouvelle
ouverture de l'app, y compris via le filet de sécurité 23h (qui appelle
`cloturerJourneeCotisation` en interne).

**Correction** : nouveau helper `_derniereEcheancePourCarnet`
(`orderBy(desc) + limit(1)` avant `getSingleOrNull`, garantit au plus
un résultat quel que soit le nombre de lignes réellement présentes),
qui remplace les 3 requêtes fragiles. Cohérent avec la doc de classe
d'`Echeances` elle-même ("la lecture retient toujours la ligne la plus
récente pour un triplet") et avec `_echeancesResoluesDuCycle`, qui
appliquait déjà cette règle correctement ailleurs. Aucune migration,
aucune suppression de donnée — un doublon déjà écrit reste en base
mais ne fait plus jamais planter la lecture.

**Test de régression** : `test/data/local/echeance_dupliquee_deja_existante_test.dart`
— écrit directement deux lignes `Echeances` pour le même triplet (en
contournant les garde-fous actuels, pour reproduire une base non
corrigée) et vérifie que les trois fonctions ne plantent plus. Vérifié
contre l'ancien code (`git stash` sur `database.dart` seul) avant
correction : échoue bien avec `Bad state: Too many elements` sur
`getSingleOrNull`, confirmant le mécanisme exact du bug.

## Amendes : plus aucun motif pré-sélectionné à la clôture (2026-08-14)

**Décision, précisée par le fondateur** : "Clôture de journée
interactive" (2026-08-11, ci-dessus) pré-remplissait chaque carnet non
traité sur "Absence" — modifiable, mais un agent qui validait sans
toucher au dropdown appliquait quand même une amende par défaut. Le
fondateur a explicitement demandé qu'aucune amende ne puisse jamais
s'appliquer sans un choix actif de l'agent, carnet par carnet — "il
n'y a plus d'amende automatique, quelle que soit la raison".

**Correction** : `resolutions` passe de `Map<String, String>` à
`Map<String, String?>` — `null` tant que l'agent n'a rien choisi,
jamais de repli implicite sur "Absence". Le dropdown affiche un indice
("Choisir…") plutôt qu'une valeur pré-sélectionnée. "Clôturer
définitivement" reste désactivé tant qu'il manque un choix pour au
moins un carnet, avec un message explicite. Seule exception, qui reste
un vrai choix explicite et non un défaut caché : un carnet déjà
anticipé plus tôt dans la journée (écran "Séance du jour") reste
pré-rempli avec ce choix-là, puisque l'agent l'a déjà décidé lui-même.

**Portée limitée à l'écran interactif** : `cloturerJourneeCotisation`
retombe toujours sur "Absence" côté base pour un appel qui ne fournit
pas de `resolutions` (import historique, tests, autres appelants
programmatiques) — comportement historique préservé, sans lien avec un
agent humain face à un écran.

## Écran Cotisation : membre suivant plus visible (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 25.1/25.2) : l'agent pouvait changer de membre après
"Enregistrer et passer au membre suivant" sans s'en rendre compte —
seul le nom en haut de page, en petit, changeait. Le nom, le numéro de
carnet et le nombre de parts déjà achetées aujourd'hui sont les 3
informations les plus importantes de cet écran pour l'agent sur le
terrain.

**Implémentation** : `cotisation_membre_screen.dart` — ces 3 infos
regroupées dans une carte à fort contraste (`colorScheme.primaryContainer`,
texte large et gras) en tête d'écran, plus un `SnackBar` explicite
("✓ [ancien membre] enregistré — passage à [nouveau membre]") au
moment du passage au membre suivant, en plus de la carte qui change.

## Renommage partiel annulé : "Épargne exceptionnelle" → "Cotisation exceptionnelle" (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 25.3) : annule, uniquement pour ce terme précis, le renommage
"Cotisation" → "Épargne" du 2026-08-13 (voir plus haut) — "Cotisation
exceptionnelle" redevient le texte affiché partout où il apparaît.
Le reste du renommage ("Épargne", "Épargnes (cash)", "Total épargne",
etc.) reste inchangé. Toujours uniquement le texte affiché, jamais le
code (`CotisationsExceptionnelles`, `cotisations_exceptionnelles_screen.dart`,
etc. restent tels quels).

## Suppression d'"Annuler la clôture" (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 25.5) : plus aucune possibilité de revenir sur une journée de
cotisation déjà clôturée, même si rien n'a été enregistré depuis.
Annule la fonctionnalité introduite avec la clôture explicite (voir
"Clôture de la journée de cotisation").

**Implémentation** : `AppDatabase.annulerClotureJournee` retiré
entièrement (plus seulement caché côté écran) ; bouton et message
correspondants retirés de `record_cotisation_screen.dart`. Le message
de confirmation avant clôture insiste désormais explicitement sur le
caractère définitif ("il ne sera plus possible de revenir en
arrière").

## Dates de début/fin de cycle affichées (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 25.6) : la date de début du cycle et sa date de fin prévue
(calculée depuis la durée choisie à la création du groupe) doivent
être visibles à l'écran, pour vérifier que les choix faits à la
création sont respectés.

**Implémentation** : `AppDatabase._finDeCycle` rendu public
(`finDeCyclePrevue`) — calcul déjà existant (utilisé par
`LoanRateResolver`/`LoanWindowCalculator`), maintenant réutilisé plutôt
que dupliqué. Affiché en tête de `cycle_summary_screen.dart` (écran
Répartition), avec le numéro et le statut du cycle.

## Déduction automatique immédiate d'une cotisation exceptionnelle échue (2026-08-13)

**Décision, confirmée par le fondateur** (voir RETOURS_TERRAIN.md,
point 25.4, question posée explicitement) : quand la date limite d'une
cotisation exceptionnelle passe sans paiement complet, le solde
restant de chaque membre éligible doit être déduit de son épargne
**immédiatement** — pas seulement à la clôture du cycle, comme c'était
déjà le cas depuis l'origine de cette fonctionnalité (voir
`AppDatabase.preparerPartageCycle`, doc de
[CotisationsExceptionnelles]). Le fondateur a explicitement choisi
cette option plutôt que de garder le comportement à la clôture
seulement (l'alternative que j'avais recommandée par défaut).

**Piège identifié et corrigé avant de livrer** : une première version
écrivait la déduction immédiate comme un simple versement dans
`FondsSolidariteContributions` (même table que les vrais paiements
cash). Un test de bout en bout a immédiatement révélé le problème :
`preparerPartageCycle` calcule la réduction des parts reconnues à
partir de `soldeCotisationExceptionnelleFcfa` (solde encore dû) — une
fois la déduction immédiate écrite, ce solde retombe à 0, et
`preparerPartageCycle` **sautait alors la réduction**, comme si le
membre avait payé cash alors qu'aucun argent réel n'avait été reçu :
son épargne recommençait à générer une part du bénéfice collectif sur
la totalité de ses parts, sans jamais avoir réglé son dû.

**Correction retenue** : nouvelle colonne
`FondsSolidariteContributions.estDeductionAutomatique` (schemaVersion
22) qui distingue une ligne écrite automatiquement d'un vrai versement
cash :
- `soldeCotisationExceptionnelleFcfa` / `cotisationsExceptionnellesNonSoldeesDuMembre`
  comptent les deux de la même façon (le membre ne doit plus rien une
  fois déduit, automatiquement ou en cash) ;
- `resumeCotisationExceptionnelle` ("Collecté : X/Y FCFA") et
  `totalFondsSolidarite` ("Fonds de solidarité : X FCFA") **excluent**
  les lignes automatiques — ces totaux ne reflètent jamais que de
  l'argent réellement en caisse ;
- `preparerPartageCycle` calcule désormais la réduction des parts
  reconnues à partir du **cash reçu uniquement**
  (`_totalVerseCashCotisationExceptionnelle`), jamais du solde restant
  — la réduction reste donc identique, que la déduction immédiate ait
  déjà eu lieu ou non, éliminant le risque de double compte ou de
  saut ;
- `cloturerCycleEtOuvrirSuivant` (clôture réelle) vérifie
  `_totalDejaDeduitAutomatiquement` avant d'écrire sa propre ligne
  automatique, pour ne jamais réécrire ce qu'une déduction immédiate a
  déjà réglé.

**Implémentation** : `AppDatabase.appliquerDeductionsCotisationsExceptionnellesEchues({groupId,
cycleId, agentPhone})` — pour chaque cotisation exceptionnelle du
cycle dont la date limite est dépassée, pour chaque membre éligible
avec un solde restant, écrit une ligne automatique. Idempotent (le
solde retombe à 0 après écriture). Appelée à chaque ouverture de
`cotisations_exceptionnelles_screen.dart` et `cotisation_membre_screen.dart`
— même principe que le filet de sécurité 23h des journées de
cotisation. Sans effet sur un cycle déjà clos.

## Échéances décalées par le changement d'heure (DST) (2026-08-15)

**Retour terrain** : sur un groupe hebdomadaire du vendredi démarré le
14 août 2026, le fondateur a vu apparaître dans l'historique deux
séances datées "jeudi 5 novembre" et "jeudi 12 novembre" — jamais
saisies manuellement, et pourtant décalées d'un jour par rapport au
vendredi attendu.

**Cause, confirmée par reproduction directe** : `_echeancesHebdomadaires`
avançait de vendredi en vendredi avec `courante.add(Duration(days: 7))`
— une addition de **temps écoulé réel** (7×24h), pas de jours
calendaires. Le passage à l'heure d'hiver aux États-Unis (et dans tout
fuseau qui observe le même changement) a lieu le **dimanche 1er
novembre 2026** ; l'appareil de terrain n'était pas réglé sur un
fuseau ouest-africain (qui n'a pas d'heure d'été). La semaine qui
traverse cette transition atterrit une heure avant minuit du bon jour
— donc la veille. Vérifié directement avec un script isolé sur une
machine réglée sur un fuseau américain : `DateTime(2026, 10,
30).add(Duration(days: 7))` renvoie `2026-11-05 23:00:00`, pas
`2026-11-06 00:00:00`.

**Portée** : la même construction fragile touchait aussi
`LoanBalanceCalculator._finDePeriode` (date de fin de période de prêt)
et deux calculs de `joursRestantsPeriodeCourante`
(`DateTime.difference(...).inDays`, sensible au même problème dans
l'autre sens — une différence entre deux dates calendaires correctes
peut valoir 89 ou 91 jours au lieu de 90 si une transition tombe entre
les deux, `.inDays` tronquant vers le bas). Deux autres occurrences
mineures identifiées mais non corrigées ici (hors périmètre de ce
correctif) : `AppDatabase.totalRembourseParMembreAuJour` (borne d'un
jour, très faible risque) et `AppDatabase._debutPeriodeEnCours`
(utilisée uniquement par `membresEnRetard`, déjà du code mort, aucun
écran ne l'appelle).

**Correction** : deux fonctions utilitaires DST-immunes dans
`echeance_calculator.dart` (fichier pur Dart, sans dépendance à la
base, réutilisable partout) :
- `ajouterJoursCalendaires(date, jours)` — construit directement
  `DateTime(year, month, day + jours)` plutôt que d'ajouter une
  `Duration`. `DateTime` normalise un `day` hors bornes selon le
  calendrier, jamais selon un décompte d'heures écoulées — immunisé
  par construction.
- `joursCalendairesEntre(plusRecente, plusAncienne)` — convertit les
  deux dates en `DateTime.utc` avec les mêmes composants calendaires
  avant de soustraire. UTC n'a jamais d'heure d'été, donc la
  différence obtenue est toujours l'exact décompte de jours de
  calendrier.

`_echeancesHebdomadaires`, `LoanBalanceCalculator._finDePeriode` et les
deux `joursRestantsPeriodeCourante` utilisent désormais ces helpers.
`_echeancesMensuelles` n'a jamais été concernée : elle construit déjà
chaque date directement depuis ses composants calendaires
(`DateTime(annee, mois, jour)`), jamais par addition.

**Nuance importante pour le fondateur** : la Côte d'Ivoire et l'UEMOA
n'observent pas l'heure d'été — un agent réel là-bas ne rencontrerait
jamais ce bug avec un téléphone correctement réglé sur son fuseau.
Reste un vrai correctif de robustesse (téléphone mal configuré, agent
en déplacement), pas une urgence spécifique au terrain visé.

**Données de test déjà écrites (5 et 12 novembre) non réparées** :
irrécupérables telles quelles (voir "Suppression d'`Annuler la
clôture`" plus haut) — sans conséquence, il s'agit de données de test.

**Vérifié par test de régression** avant/après correction (`git stash`
sur les seuls fichiers du correctif) : le test échoue sur l'ancien
code avec exactement le symptôme du terrain (5/12 novembre au lieu de
6/13), passe après correction. Voir
`test/domain/calculators/echeance_calculator_test.dart` et
`loan_balance_calculator_test.dart`, groupes "changement d'heure
(DST)".

## Date de la prochaine réunion après clôture (2026-08-15)

**Décision, demandée par le fondateur** : le message de confirmation
affiché juste après la clôture d'une journée de cotisation indique
désormais aussi la date de la prochaine réunion — plus pratique que de
laisser l'agent la déduire lui-même.

**Implémentation** : `EcheanceCalculator.prochaineEcheance({apres,
meetingFrequency, ...})` — première échéance strictement après
[apres], même cadence que `echeancesPassees` (fenêtre de recherche de
40 jours, couvre le plus grand écart possible entre deux échéances
quelle que soit la fréquence). `record_cotisation_screen.dart` l'appelle
juste après `cloturerJourneeCotisation` et affiche un `SnackBar` :
"Journée du [date] clôturée — prochaine réunion : [date]."

## Détail par membre d'une cotisation exceptionnelle (2026-08-15)

**Décision, demandée par le fondateur** : l'écran "Cotisations
exceptionnelles" affichait déjà un total collecté et un statut
"(dépassée)" une fois la date limite passée, mais aucun détail par
membre — impossible de savoir en un coup d'œil qui a payé et qui a été
prélevé automatiquement.

**Implémentation** : `AppDatabase.detailCotisationExceptionnelleParMembre(evt)`
— pour chaque membre éligible, le montant versé en cash et le montant
déduit automatiquement (déjà suivis séparément, voir
`estDeductionAutomatique`), d'où un statut dérivé
(`StatutCotisationExceptionnelleMembre.paye` / `.deduitAutomatiquement`
/ `.enAttente`, un versement partiel avant échéance restant
`.enAttente`). Chaque événement de `cotisations_exceptionnelles_screen.dart`
devient un `ExpansionTile` : un bandeau explicite "Cette cotisation
exceptionnelle a expiré..." si la date limite est dépassée, puis la
liste des membres avec leur statut et montant.

## Historique de prêt enrichi pour l'agent et le membre (2026-08-16)

**Retour terrain** : un membre a demandé à voir son historique de
prêt. Vérification faite avant tout code : l'écran membre affichait
déjà une section "Mes prêts", mais très pauvre comparée à ce que
l'agent voit pour le même prêt — montant emprunté, statut et total
remboursé seulement, jamais le taux d'intérêt, le montant dû
actuellement, le statut "au rouge", l'échéance, ni le détail des
remboursements un par un (cette dernière liste manquait aussi côté
agent).

**Décision** : aligner l'écran membre sur l'écran agent (lecture
seule, aucune action nouvelle — cohérent avec `two-tier-access-model`),
et ajouter le détail des remboursements aux deux écrans.

**Implémentation** :
- Les deux écrans utilisent désormais `AppDatabase.soldePret` (déjà la
  source unique pour ce calcul, voir sa doc) — jamais de calcul
  dupliqué, le membre voit exactement le même solde que l'agent.
- `AppDatabase.remboursementsDuPret` (déjà existant, utilisé en
  interne par `soldePret`) est maintenant aussi lu directement par les
  deux écrans pour afficher la liste des remboursements.
- Chaque prêt devient un `ExpansionTile` (au lieu d'un `ListTile`
  simple) sur les deux écrans : résumé toujours visible (montant, taux,
  dû actuellement, "au rouge" le cas échéant, échéance), historique des
  remboursements (date, montant) affiché au dépliage.

## Rattrapage du miroir Postgres (2026-08-16)

**Constat** : `ROADMAP.md` signalait depuis le 2026-08-08 que le
schéma Postgres avait décroché du schéma drift local (schemaVersion
4-5), sans jamais avoir été comblé malgré la mention dans 0004. En
vérifiant colonne par colonne, l'écart s'était en fait élargi jusqu'à
schemaVersion 22 (tout Phases 2 à 5) : `groups.payment_day_of_week` et
consorts, `cycles.loan_duration_days`, `prets.duree_jours`,
`amendes.est_auto_generee`/`confirmed_at`/`reviewed_at`/`carnet_numero`/
`echeance_date`/`motif_code_systeme`, `amende_annulations`,
`motifs_amende`, `partage_paiement_confirmations`, `carnets`,
`amende_paiements`, `groups.montant_solidarite_obligatoire_fcfa`,
`cotisations_exceptionnelles`,
`fonds_solidarite_contributions.cotisation_exceptionnelle_id`/
`est_deduction_automatique`, `groups.montant_amende_sortie_rouge_fcfa`,
`prets.renouvele_pret_id`/`est_au_rouge_des_le_depart`,
`pret_demandes`, `pret_demande_refus`, `prets.demande_id`,
`presence_anticipee` — manquaient tous. Un vestige inverse a aussi été
trouvé : `echeances.carnets_engages` (0003) n'existe plus du tout côté
drift depuis la refonte carnet/part de schemaVersion 7 (table
supprimée puis recréée) — colonne morte côté Postgres, retirée.

**Correction** : `supabase/migrations/0006_rattrapage_dette_technique_phases_2_a_5.sql`
— un seul fichier consolidé plutôt que 12 migrations séparées, même
principe que 0004 pour les tables introduites en cours d'historique
(créées directement avec leur structure actuelle). Colonnes/tables
ajoutées en respectant l'ordre de dépendance (ex. `cotisations_exceptionnelles`
avant la colonne qui la référence). RLS ajoutée pour chaque nouvelle
table selon les patterns déjà établis (agent = accès complet sur son
groupe, membre = lecture de ses propres lignes uniquement) — 4
nouvelles fonctions d'aide (`app_group_of_amende`,
`app_member_of_amende`, `app_group_of_demande`,
`app_member_of_demande`), même principe que `app_group_of_pret`.

**Vérifié le 2026-08-16 par exécution réelle** — écrit sans accès à
`psql`/Docker/identifiants d'administration Supabase depuis
l'environnement de développement (voir ENVIRONMENT.md sur la clé
secrète, jamais utilisée), donc relu méthodiquement mais pas exécuté
sur le moment. Le fondateur a ensuite collé 0002 à 0006 dans le SQL
Editor du projet Supabase existant, un fichier à la fois, dans l'ordre
— seul 0001 avait déjà été appliqué auparavant (confirmé via Table
Editor avant de commencer : uniquement les 12 tables de 0001
présentes). Chaque fichier est passé sans erreur (le message "Potential
issue detected" de Supabase est apparu comme attendu sur les requêtes
contenant `ALTER COLUMN`/`DROP` — confirmé à chaque fois, aucune perte
de donnée possible, le projet n'ayant encore aucune vraie donnée).
Table Editor recompte ensuite exactement les 25 tables attendues (12
de 0001 + 13 nouvelles). RLS non re-testée à ce stade (le script
`supabase/tests/rls_smoke_test.sql` existe pour ça, pas encore
rejoué).

**Écarté** : resynchroniser la contrainte `carnets_engages.nombre_carnets
in (1, 2)` (0004) avec la nouvelle règle "un membre = un seul carnet"
(drift, commentaire de classe) — laissé tel quel pour garder ce
correctif purement additif ; à traiter séparément si besoin.

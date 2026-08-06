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

## Fonds de solidarité : table séparée, jamais lue par le calculateur

Décision directe du skill `avec-business-rules`, appliquée littéralement :
`EndOfCycleInput` n'a aucun champ qui référence
`fonds_solidarite_contributions`. C'est la garantie de correction la
plus simple possible — le calculateur ne peut pas mélanger les deux
parce que la donnée n'est structurellement pas accessible depuis son
entrée.

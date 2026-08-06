# Changelog — CotisApp

## 2026-07-31 — V0 : moteur hors ligne (sans paiement)

Premier code du projet. Précédemment : dossier de planification
uniquement (`CotisApp_Resume.pdf` + 6 skills), aucun code.

**Ajouté**
- Scaffold Flutter (`com.cotisapp.app`), skills copiés dans
  `.claude/skills/`
- Schéma local `drift` : groupes, membres, cycles, cotisations, prêts
  (+ confirmations, remboursements, annulations), amendes, fonds de
  solidarité, affectations de rôle agent — tables financières en ajout
  seul avec chaîne de hash
- Moteur de calcul de fin de cycle (`EndOfCycleCalculator`), testé
  contre un scénario Kondoukro construit à partir des paramètres réels
  du dossier source
- Écrans : identification par téléphone, groupes, membres, cotisations
  cash, prêts (avec flux de consentement en mode dev), répartition de
  fin de cycle
- `AuthGateway` / `DevAuthGateway` — abstraction prête pour Supabase
  Auth + Twilio, sans dépendance à un compte externe pour développer
- Documentation : README, ARCHITECTURE, DECISIONS, ROADMAP, TESTING

**Périmètre explicitement exclu de cette étape**
- Paiement à distance / intégration PayDunya-DEXCHANGE
- Synchronisation Supabase (tout est local pour l'instant)
- Membres sans aucun téléphone

## 2026-07-31 — Import d'historique (skill historical-data-import)

**Ajouté**
- Champ `provenance` (`direct`/`importe`) + `estApproximatif` sur toutes
  les tables financières en ajout seul (cotisations, prêts,
  remboursements, amendes, fonds de solidarité)
- Parseur CSV pur et testé (`HistoricalImportParser`) : tolérant aux
  dates et montants approximatifs, ne bloque jamais tout l'import pour
  une ligne isolée en erreur
- `HistoricalImportService` : résolution des membres du CSV contre le
  groupe (jamais de création automatique — un membre exige un numéro de
  téléphone), rattachement des remboursements au prêt importé le plus
  ancien non soldé, conversion montant → parts pour les cotisations
- Écran d'import avec résumé (nombre de membres, montant total),
  détection des membres introuvables, confirmation explicite avant
  écriture (skill : validation collective du comité de gestion)
- Un prêt importé compte comme confirmé sans consentement SMS
  individuel rétroactif — voir DECISIONS.md
- Badges "importé"/"approximatif" dans les écrans cotisations et prêts
- Tests d'intégration en base mémoire : conversion montant → parts,
  rattachement remboursement → prêt, comptage correct dans le calcul de
  fin de cycle, avertissement (pas perte silencieuse) pour un
  remboursement sans prêt correspondant

**Limite connue** : l'import rattache tout au cycle actuellement
ouvert du groupe — importer un cycle antérieur déjà clos séparément
n'est pas encore possible (voir ROADMAP.md). Le CSV se colle en texte
brut pour l'instant, pas encore de sélecteur de fichier.

## 2026-07-31 — Import multi-cycle

Résout la limite connue de l'étape précédente.

**Ajouté**
- `creerCycleHistorique` : crée un cycle déjà clos avec numéro, dates de
  début/fin, valeur de part et taux propres (distinct du cycle en
  cours)
- `cyclesDuGroupe` / `prochainNumeroCycle` : lister tous les cycles d'un
  groupe, suggérer le prochain numéro disponible
- Écran d'import : première étape de choix du cycle cible (cycle en
  cours, ou création d'un nouveau cycle historique clos via un petit
  formulaire) avant de coller le CSV
- Écran "Cycles" : liste tous les cycles (ouvert et clos) d'un groupe,
  ouvre la répartition de fin de cycle de n'importe lequel
- Tests confirmant l'isolation entre cycles : un import vers un cycle
  historique clos n'apparaît jamais dans le calcul du cycle en cours

**Limite connue restante** : le CSV se colle toujours en texte brut,
pas de sélecteur de fichier natif (voir ROADMAP.md).

## 2026-08-01 — Accès en lecture pour les membres

**Ajouté**
- Écran d'identification : choix explicite "continuer comme agent" ou
  "voir mes informations (membre)" (`appModeProvider`)
- `membresParTelephone`, `cotisationsDuMembre`, `pretsDuMembre` :
  requêtes filtrées au niveau base de données, jamais un filtrage
  après-coup en mémoire (skill `two-tier-access-model`)
- `MemberLookupScreen` : retrouve tous les groupes où un numéro est
  enregistré comme membre
- `MemberHomeScreen` : parts, cotisations, prêts et estimation de fin
  de cycle du membre connecté uniquement — jamais les données des
  autres membres du même cycle, aucune action d'écriture, navigation
  vers les cycles précédents en lecture seule
- Correction : le créateur d'un groupe est maintenant automatiquement
  affecté au rôle `agent` (`affecterRole` existait dans le schéma mais
  n'était jamais appelée)
- Test de non-fuite : un widget test vérifie que le nom et les montants
  d'un autre membre du même cycle n'apparaissent jamais sur l'écran
  d'un membre

**Limite connue** : le choix agent/membre est une bascule manuelle en
mémoire (pas de session persistante), et le filtrage reste appliqué
côté client (SQLite local) — la vraie garantie de sécurité (row-level
security côté serveur) arrive avec Supabase, voir ROADMAP.md.

## 2026-08-01 — Sélecteur de fichier pour l'import

Résout la dernière limite connue de l'import d'historique.

**Ajouté**
- Dépendance `file_picker` — bouton "Choisir un fichier CSV" sur
  l'écran d'import, en plus du collage manuel déjà existant
- Lecture des octets du fichier choisi, décodage UTF-8 avec repli
  automatique en latin1 si l'encodage échoue (exports Excel/Windows
  fréquemment en Windows-1252)

## 2026-08-01 — Retiré : sélecteur de fichier

Après plusieurs échecs de build confirmés sur émulateur réel (`Gradle
task assembleDebug failed`, `cannot find symbol
com.mr.flutter.plugin.filepicker.FilePickerPlugin`), `file_picker`
est incompatible avec cette version de Flutter (son "Built-in Kotlin"
ne compile plus les plugins qui appliquent leur propre Kotlin Gradle
Plugin). Retiré pour débloquer l'app — le collage manuel de CSV reste
la seule méthode d'import. Voir ROADMAP.md.

## 2026-08-01 — Vocabulaire "carnet" + amende de retard

**Ajouté**
- Toute l'interface affiche "carnet" au lieu de "part" (terme réel
  utilisé par les groupes AVEC), et "bénéfice individuel" au lieu de
  "part individuelle" pour lever l'ambiguïté avec ce nouveau terme —
  seuls les libellés changent, le code technique interne garde
  `part`/`parts`
- Nouveau champ `lateFeeFcfa` sur les cycles (migration de schéma 1→2) :
  amende de retard configurable à la création du groupe/cycle, comme
  la valeur du carnet et le taux d'intérêt
- Détection automatique des membres n'ayant pas cotisé sur la période
  en cours (calculée depuis la fréquence de réunion du groupe et la
  date de début du cycle), affichée sur l'écran Cotisations avec le
  montant d'amende suggéré — jamais appliquée automatiquement, un tap
  de l'agent est toujours nécessaire
- Un membre déjà mis à l'amende sur la période en cours n'est plus
  signalé comme en retard (pas de double comptage)
- 5 nouveaux tests couvrant les scénarios de retard (cotisé à temps,
  aucune cotisation, déjà mis à l'amende, cycle clos, valeur par défaut)

## 2026-08-04 — Projet Supabase + schéma PostgreSQL/RLS

**Ajouté**
- Projet Supabase `cotisapp` créé (région West EU/Ireland, plan gratuit)
- `supabase/migrations/0001_init.sql` : miroir exact du schéma `drift`
  local (12 tables), exécuté avec succès dans le SQL Editor du dashboard
- Row-Level Security activée sur toutes les tables — filtrage
  agent/membre appliqué côté base de données (skill
  `two-tier-access-model`, "règle non négociable"), pas seulement côté
  client comme jusqu'ici. Fonctions d'aide : `app_current_phone()`,
  `app_is_agent(group_id)`, `app_is_self_member(member_id)`
- Confirmation de prêt réservée au membre concerné au niveau des
  politiques RLS elles-mêmes (skill `member-consent-rules`)
- Dépendance `supabase_flutter` ^2.16.0, client initialisé dans
  `main.dart` — de façon non bloquante : sans identifiants fournis à la
  compilation, l'app démarre normalement en local uniquement (skill
  `offline-first-flutter`)
- Identifiants lus via `--dart-define-from-file=env/env.json` (non
  commité, modèle dans `env/env.example.json`), voir ENVIRONMENT.md
- `flutter analyze` et `flutter test` (34 tests) toujours au vert après
  l'ajout de la dépendance

- Policies RLS vérifiées par un test de fumée SQL
  (`supabase/tests/rls_smoke_test.sql`, exécuté dans une transaction
  annulée) : un membre ne voit que sa propre cotisation, l'agent voit
  tout le groupe, un numéro inconnu ne voit rien — confirmé directement
  dans le dashboard, résultats conformes sur les 4 cas testés

**Non fait à cette étape (volontairement)**
- Authentification réelle (Twilio) — `DevAuthGateway` toujours utilisé.
  Nécessaire avant toute synchronisation réelle : sans session Supabase
  Auth authentique, l'app ne peut obtenir aucun `auth.uid()` valide et
  reste bloquée au rôle `anon` (aucun accès, par sécurité) côté serveur.
  **Reporté à la fin du projet, à la demande du fondateur** : l'app doit
  d'abord être pleinement fonctionnelle hors ligne.
- Synchronisation offline ↔ Supabase — le client est initialisé mais
  rien ne l'utilise encore

## 2026-08-04 — Clôture de cycle et ouverture du suivant

Trou fonctionnel identifié en relisant le code après la mise en place de
Supabase : `ouvrirCycle` n'était appelé qu'une seule fois, à la création
du groupe. Aucun moyen n'existait de clôturer le cycle en cours pour en
ouvrir un nouveau — un groupe réel se serait retrouvé bloqué au premier
cycle après 9 à 12 mois d'usage.

**Ajouté**
- `cloturerCycleEtOuvrirSuivant` : marque le cycle actuel `cloture` avec
  sa date de fin, crée immédiatement le cycle suivant `en_cours` — avec
  sa propre valeur de carnet, son propre taux d'intérêt et sa propre
  amende de retard, jamais recopiés du cycle précédent (skill
  `avec-business-rules` : ces paramètres sont définis par le groupe en
  début de cycle)
- `pretsNonSoldesDuCycle` : liste les prêts confirmés dont le
  remboursement (principal + intérêt) n'est pas complet — avertissement
  affiché avant la clôture, jamais bloquant (le dossier source ne
  prévoit aucune règle de report de dette d'un cycle à l'autre ; l'app
  se contente de signaler la situation au comité, voir DECISIONS.md)
- Bouton "Clôturer ce cycle" sur l'écran de répartition de fin de cycle
  (visible uniquement si le cycle est encore `en_cours`), avec
  confirmation explicite et formulaire des paramètres du cycle suivant,
  pré-rempli avec les valeurs actuelles
- 5 nouveaux tests : clôture + ouverture correctes, refus de clôturer un
  cycle déjà clos, isolation des cotisations entre l'ancien et le
  nouveau cycle, fonds de solidarité jamais réinitialisé, détection
  correcte des prêts non soldés (ignore les prêts non confirmés et ceux
  déjà totalement remboursés)

## 2026-08-05 — Membres sans téléphone personnel

Traite le premier sujet ouvert de ROADMAP.md. Décision produit tranchée
avec le fondateur : confirmation de prêt par signature capturée à
l'écran (plutôt que par code PIN) pour les membres sans téléphone.

**Ajouté**
- `members.phoneNumber` devient nullable (migration schémaVersion 2→3)
  — un membre sans aucun téléphone (pas seulement sans smartphone) peut
  être ajouté à un groupe
- `PretConfirmations` gagne `methode` (`code`/`signature`),
  `signatureData`, `witnessPhone` — deux façons de confirmer un prêt
  sans jamais les mélanger sur une même ligne. `confirmerPretParSignature`
  refuse explicitement si le membre a un téléphone enregistré
- Nouveau widget `SignaturePad` (`CustomPainter`/`GestureDetector`, sans
  dépendance externe) — capture le tracé, encodé en texte compact
- Écran Membres : case "pas de téléphone personnel" au lieu du champ
  numéro obligatoire, affichage adapté dans la liste
- Écran Prêts : bascule automatiquement vers la confirmation par
  signature quand l'emprunteur n'a pas de téléphone, aussi bien à la
  création du prêt qu'à la confirmation d'un prêt déjà en attente
- Migration Postgres `0002_membres_sans_telephone.sql` : mêmes
  changements de schéma + policy RLS `pret_confirmations_insert` mise à
  jour (signature autorisée seulement pour l'agent témoin d'un membre
  effectivement sans téléphone)
- 5 nouveaux tests, 44 au total dans le projet

**Limite acceptée** : un membre sans téléphone ne peut jamais utiliser
l'accès "membre" en lecture seule (identification par numéro) — voir
DECISIONS.md et skill `two-tier-access-model`.

## 2026-08-05 — Sélecteur de fichier CSV : deuxième tentative, même échec

Deuxième essai de `file_picker`, cette fois en version 11.0.3 (la plus
récente, réécrite en architecture fédérée entre-temps pour supporter
AGP 9). Testé proprement via `flutter build apk --debug` (sans passer
par l'émulateur, pour isoler le problème de compilation de tout souci
d'environnement).

**Résultat** : échec identique au premier essai (2026-08-01) —
`cannot find symbol com.mr.flutter.plugin.filepicker.FilePickerPlugin`.
Le message d'erreur de Flutter est cette fois explicite : `file_picker`
applique son propre Kotlin Gradle Plugin (KGP), incompatible avec le
"Built-in Kotlin" de cette version de Flutter, et Flutter prévient que
ce sera un blocage total dans une future version (pas juste un
avertissement). Retiré à nouveau, collage manuel de CSV inchangé.
Détails et piste de contournement (sélecteur natif via `MethodChannel`
plutôt qu'un plugin tiers) dans ROADMAP.md.

## 2026-08-05 — Carnets figés, échéances fixes, prêts à intérêt composé

Règles précisées par le fondateur, plus strictes que le comportement
jusqu'ici (saisie libre du nombre de carnets à chaque cotisation,
période glissante, intérêt de prêt appliqué une seule fois). Trois
points sensibles confirmés explicitement avant codage (voir
DECISIONS.md).

**Ajouté**
- Carnets engagés par membre et par cycle (`CarnetsEngages`, 1 à 5),
  choisis à l'entrée dans le cycle, **verrouillés automatiquement dès le
  premier paiement direct** — jamais modifiables après (import
  historique exempté)
- Jour de paiement fixe configuré à la création du groupe
  (`paymentDayOfWeek` hebdomadaire, `paymentDayOfMonth1`(+`2`) mensuelle/
  bimensuelle) — `EcheanceCalculator` calcule les dates d'échéance
  réelles, plus une simple période glissante
- Montant de cotisation **calculé automatiquement**, plus de saisie
  libre : `carnets engagés × valeur du carnet`, avec **cumul
  automatique des échéances manquées** (`EcheanceCalculator.soldeDuFcfa`)
  — un paiement raté ne se remet jamais à zéro silencieusement
- Écran Cotisations réécrit : sélection d'un membre → montant calculé
  affiché → ajout à une liste "encaissements du jour" → vérification
  groupée avec avertissement "définitif" → un seul bouton qui
  enregistre tout
- Durée de prêt (`cycles.loanDurationDays`) et intérêt qui se recompose
  au solde restant à chaque période expirée sans remboursement complet
  (`LoanBalanceCalculator`) — jusqu'au remboursement intégral
- Écran Prêts enrichi : montant emprunté, montant dû actuellement,
  temps restant avant la prochaine échéance de renouvellement
- 27 nouveaux tests (calculateurs purs + intégration DB, dont un
  scénario reproduisant exactement l'exemple "Mr AB" du fondateur),
  66 au total dans le projet

**Limite connue** : la détection `membresEnRetard` (déclenchement de
l'amende) n'utilise pas encore le même calendrier d'échéances que le
nouveau calcul du montant dû — voir DECISIONS.md.

## 2026-08-06 — Aller-retour : échéances calendaires confirmées, ajout de la modification de groupe

Un premier test réel a semblé montrer un bug ("membre à jour" alors
qu'aucune cotisation n'était encore payée) — corrigé une première fois
en ancrant les échéances sur la date de création du cycle plutôt que
sur un jour calendaire fixe. Après clarification avec le fondateur : ce
n'était pas un bug, c'était le comportement voulu (le groupe de test
n'avait simplement pas été créé le jour choisi comme jour de paiement).
`EcheanceCalculator` et l'écran de création de groupe sont restaurés
tels qu'avant.

**Ajouté** (la vraie demande derrière ce test)
- `modifierGroupeEtCycle` : nom, durée, fréquence, jour de paiement,
  valeur du carnet, taux, amende, durée de prêt redevenus modifiables
  — mais **uniquement tant qu'aucune cotisation n'a été enregistrée**
  sur le cycle en cours. Refus explicite côté base (`StateError`) si ce
  n'est plus le cas, pas seulement un bouton caché à l'écran
- Nouvel écran `EditGroupScreen`, accessible par une icône crayon sur
  l'écran du groupe (visible uniquement si le verrou est encore ouvert)
- 2 nouveaux tests (modification autorisée avant, refusée après la
  première cotisation), 68 tests au total dans le projet

## 2026-08-06 — Amendes de retard automatiques + garde-fous remboursement

Remplace le bouton "Amende" manuel par membre par une détection et
application automatiques, précisées avec le fondateur via un scénario
concret (3 membres, cotisations hebdomadaires) — voir DECISIONS.md pour
le détail complet, y compris ce qui a été envisagé puis abandonné
(disponibilité anticipée d'une échéance, paiement en avance).

**Ajouté**
- `AmendeAutoService.detecterEtAppliquer` : à chaque ouverture de
  l'écran Cotisations, applique automatiquement l'amende configurée
  pour chaque échéance close non couverte — jamais pour l'échéance en
  cours, jamais deux fois pour la même échéance (idempotent)
- `Amendes.estAutoGeneree` / `confirmedAt`, nouvelle table
  `AmendeAnnulations` (miroir de `PretAnnulations`) — aucune
  suppression ni modification directe, toujours une ligne d'annulation
  qui référence l'originale
- Écran Cotisations : section "Amendes à revoir" remplace l'ancien
  bloc "Pas encore cotisé" — chaque amende auto-générée propose
  Confirmer ou Erreur (annule + enregistre la cotisation manquante à la
  vraie date, choisie via un sélecteur de date)
- Écran Prêts : bouton Remboursement masqué une fois le prêt soldé,
  montant saisi plafonné au montant réellement dû
- 12 nouveaux tests (service d'amendes automatiques, écran prêts),
  78 tests au total dans le projet

## 2026-08-06 — Annulation de clôture par erreur + horloge de test

**Ajouté**
- `annulerClotureCycle` : rouvre un cycle clos par erreur, uniquement si
  le nouveau cycle créé à sa suite est encore strictement vide (aucune
  cotisation/prêt/amende/fonds de solidarité) — sinon refusé,
  correction manuelle nécessaire. Bouton "Annuler la clôture" sur
  l'écran Cycles, visible seulement quand la condition est remplie
- `AppClock` : horloge de test interne à l'app, simulable uniquement en
  mode debug — remplace `DateTime.now()` dans toute la logique sensible
  au temps (échéances, amendes automatiques, solde de prêt). Contrôle
  🧪 sur l'écran "Mes groupes" (visible seulement en debug) pour fixer
  une date simulée ou revenir à la date réelle. Permet de tester
  plusieurs semaines/mois de paiements sans attendre ni toucher à
  l'horloge du téléphone (qui avait rendu un test précédent inutilisable)
- 4 nouveaux tests (annulation de clôture), 82 tests au total dans le
  projet

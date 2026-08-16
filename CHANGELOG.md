# Changelog — CotisApp

## 2026-08-16 — Historique de prêt enrichi (agent + membre)

Retour terrain : un membre a demandé à voir son historique de prêt.
Vérification faite avant tout code (voir DECISIONS.md) : l'écran
membre existait déjà mais était nettement plus pauvre que l'écran
agent pour le même prêt.

**Ajouté**
- Écran membre ("Mes prêts") : taux d'intérêt, montant dû actuellement,
  statut "au rouge", prochaine échéance — même source que l'écran
  agent (`AppDatabase.soldePret`), jamais un calcul dupliqué
- Écrans agent et membre : chaque prêt devient dépliable, avec le
  détail des remboursements un par un (date, montant) — absent des
  deux écrans jusqu'ici, malgré la donnée déjà en base

**Ajouté (tests)**
- 2 nouveaux tests (historique dépliable côté agent et côté membre)
- 311 tests au total dans le projet — `flutter analyze` : aucun
  problème

## 2026-08-15 — Échéances décalées par l'heure d'été, date de la prochaine réunion, détail cotisation exceptionnelle

Nouveau retour terrain après plusieurs semaines de simulation : des
séances de cotisation apparaissaient à la mauvaise date (un jour plus
tôt) à partir de début novembre 2026. Deux autres demandes du fondateur
dans la même conversation.

**Corrigé**
- Échéances hebdomadaires décalées d'un jour lors d'un changement
  d'heure (heure d'été/hiver) traversé par le calcul — `_echeancesHebdomadaires`
  utilisait une addition de temps écoulé (`Duration`) plutôt qu'une
  addition calendaire. Même défaut dans `LoanBalanceCalculator`
  (date de fin de période de prêt, jours restants). Deux nouveaux
  helpers DST-immuns dans `echeance_calculator.dart` :
  `ajouterJoursCalendaires`, `joursCalendairesEntre`. Reproduit et
  vérifié directement sur une machine réglée sur un fuseau à heure
  d'été (voir DECISIONS.md pour le détail complet, y compris la
  nuance : la Côte d'Ivoire/UEMOA n'observe pas l'heure d'été).

**Ajouté**
- Message de confirmation de clôture d'une journée : affiche
  désormais la date de la prochaine réunion
  (`EcheanceCalculator.prochaineEcheance`)
- Écran Cotisations exceptionnelles : chaque événement devient
  dépliable, avec bandeau explicite si la date limite est dépassée et
  détail par membre (payé en cash / déduit automatiquement / en
  attente) — `AppDatabase.detailCotisationExceptionnelleParMembre`

**Ajouté (tests)**
- 4 nouveaux tests (2 échéances DST, 1 prêt DST, 1 détail cotisation
  exceptionnelle), 2 tests existants complétés (SnackBar de clôture)
- 309 tests au total dans le projet — `flutter analyze` : aucun
  problème

## 2026-08-14 — Clôture bloquée par un doublon préexistant, amendes sans défaut

Nouveau retour terrain : la clôture restait bloquée sur un APK déjà
censé contenir le correctif du 2026-08-13 (voir DECISIONS.md,
"Correction de motifsSystemeApplicables — carnet déjà résolu"). Ce
correctif protégeait l'écriture mais pas la lecture — voir DECISIONS.md
pour le détail complet des deux entrées ci-dessous.

**Corrigé**
- `_derniereEcheancePourCarnet` (nouveau helper, `orderBy(desc) +
  limit(1)`) remplace 3 requêtes `getSingleOrNull` fragiles
  (`membresAbsentsPourDate`, `carnetsATraiterPourDate`,
  `cloturerJourneeCotisation`) — ne plante plus, même si une ligne
  `Echeances` en double existe déjà pour un triplet (membre, carnet,
  date), écrite avant le correctif du 13 août. Aucune migration, aucune
  suppression de donnée.

**Changé**
- Écran Cotisation, dialogue de clôture : plus aucun motif
  pré-sélectionné par défaut sur "Absence" — l'agent doit choisir
  activement un motif pour chaque carnet non traité, "Clôturer
  définitivement" reste désactivé tant qu'il en manque un. Un carnet
  déjà anticipé (écran "Séance du jour") reste pré-rempli, puisque déjà
  un choix explicite de l'agent.

**Ajouté (tests)**
- `test/data/local/echeance_dupliquee_deja_existante_test.dart` (4
  tests) — simule directement une ligne en double pour reproduire une
  base de terrain non corrigée, vérifié contre l'ancien code avant
  correction (échoue bien avec `Bad state: Too many elements`)
- 2 tests existants adaptés au nouveau dialogue de clôture (plus de
  motif "Absence" trouvable par défaut, bouton désactivé tant que rien
  n'est choisi)
- 305 tests au total dans le projet après cette série

## 2026-08-13 (suite 2) — Visibilité écran Cotisation, déduction immédiate, nettoyage clôture

Sixième vague de retours, même jour (voir RETOURS_TERRAIN.md, point
25).

**Ajouté**
- Carte nom / carnet / parts déjà achetées aujourd'hui, en fort
  contraste, en tête de l'écran Cotisation — plus un SnackBar explicite
  au passage au membre suivant (ex. "✓ Aya Kone enregistré — passage à
  Seydou Traore")
- Dates de début et de fin prévue du cycle affichées sur l'écran
  Répartition (`AppDatabase.finDeCyclePrevue`, calcul déjà existant
  rendu public plutôt que dupliqué)
- `AppDatabase.appliquerDeductionsCotisationsExceptionnellesEchues` :
  le solde restant d'une cotisation exceptionnelle est désormais déduit
  automatiquement de l'épargne du membre **dès que la date limite
  passe**, plutôt qu'attendre la clôture du cycle — nouvelle colonne
  `FondsSolidariteContributions.estDeductionAutomatique` (schemaVersion
  22) pour distinguer une ligne automatique d'un vrai versement cash,
  condition nécessaire pour éviter un double compte à la clôture (voir
  DECISIONS.md pour le détail)
- `test/data/local/pret_independant_cotisation_test.dart` : confirme
  qu'aucune opération de prêt n'affecte la détection de la journée de
  cotisation (investigation du point 25.7, non reproduit)

**Changé**
- "Épargne exceptionnelle" redevient "Cotisation exceptionnelle" à
  l'écran — seul ce terme du renommage Cotisation→Épargne est annulé
- Message de confirmation avant clôture de journée renforcé
  ("il ne sera plus possible de revenir en arrière")

**Supprimé**
- "Annuler la clôture" retiré entièrement (bouton, méthode
  `annulerClotureJournee`, tests dédiés) — une journée clôturée est
  désormais définitive, sans exception

**Ajouté (tests)**
- 301 tests au total dans le projet après cette série

## 2026-08-13 (suite) — Fusion des écrans membre + correctif clôture bloquée

Cinquième vague de retours, même jour (voir RETOURS_TERRAIN.md, point
24) — un bug de terrain récurrent et gênant, diagnostiqué avant tout
code puis confirmé par un test de reproduction avant correction.

**Corrigé**
- **Bug majeur** : "Clôturer cette journée" échouait souvent après
  avoir résolu un carnet en "Absence" ou "Part impayée" (le cas le
  plus fréquent depuis "Ajouter amende") puis avoir retenté de le
  résoudre — `motifsSystemeApplicables` ne reconnaissait ces deux
  motifs comme une résolution, contrairement à "Payé par un tiers".
  Une deuxième ligne `Echeances` s'écrivait alors pour le même
  (membre, carnet, date), cassant ensuite `cloturerJourneeCotisation`,
  `carnetsATraiterPourDate`, et le filet de sécurité 23h (qui appelle
  `cloturerJourneeCotisation` en interne — d'où le même symptôme sur
  la réunion suivante après une clôture automatique). Corrigé en
  vérifiant directement l'existence d'une ligne `Echeances` plutôt que
  de déduire la résolution depuis les tables `Cotisations`/`Amendes`

**Changé**
- Fusion des deux écrans membre redondants : `members_screen.dart`
  ouvre désormais `CotisationMembreScreen` (au lieu de l'ancienne
  fiche consolidée `MemberSessionScreen`, supprimée avec son test)

**Ajouté**
- `test/data/local/resolution_carnet_deja_resolu_test.dart` : 5 tests,
  dont 2 qui échouaient avant le correctif — preuve du bug puis de sa
  résolution
- 300 tests au total dans le projet après cette série

## 2026-08-13 — Un membre = un seul carnet + renommage Épargne

Quatrième vague de retours (voir RETOURS_TERRAIN.md, point 23) —
correction d'un malentendu de fond sur la notion de carnet, clarifiée
en plusieurs échanges avant tout code.

**Changé**
- **Un membre ne peut plus avoir qu'un seul carnet, jamais deux** —
  annule la règle historique "1 ou 2 carnets par membre".
  `definirCarnetsEngages` refuse désormais tout `nombreCarnets`
  différent de 1 ; un second appel après verrouillage est devenu
  idempotent plutôt que de lever une erreur. `members_screen.dart`
  simplifié : un seul champ de numéro de série, plus de choix "1 ou 2
  carnets". Une personne avec deux carnets physiques doit être
  inscrite comme deux membres distincts
- Nom ou numéro de téléphone désormais **uniques par groupe** à la
  création d'un membre (`nomOuTelephoneDejaUtiliseDansLeGroupe`,
  appelée dans `ajouterMembre`) — jamais une contrainte globale, la
  même personne peut appartenir à plusieurs groupes avec la même
  identité
- Renommage **"Cotisation" → "Épargne"** dans tous les textes vus par
  l'agent ou le membre (écrans, boutons, dialogues, messages d'aide)
  — noms de code, de fichiers et documentation inchangés,
  volontairement

**Ajouté**
- `test/data/local/unicite_membre_test.dart` : 5 nouveaux tests
  dédiés à l'unicité nom/téléphone par groupe
- 295 tests au total dans le projet après cette série (quelques tests
  devenus obsolètes par la suppression du multi-carnet ont été retirés
  plutôt que réécrits — voir DECISIONS.md pour le détail)

## 2026-08-11 — Résolution immédiate par carnet + numéro de série saisissable

Troisième vague de retours, même jour (voir RETOURS_TERRAIN.md, point
22).

**Ajouté**
- `AppDatabase.resoudreCarnetImmediat` : remplace le bouton
  Présent/Absent de l'écran Cotisation. L'agent clique "Ajouter
  amende", choisit directement "Carnet N — Absence" / "Part impayée" /
  "Payé par un tiers" dans la liste proposée — résolu **tout de suite**
  (écrit l'échéance `non_paye` et l'amende, exactement comme
  `cloturerJourneeCotisation` l'aurait fait à la clôture, mais sans
  attendre) — plus d'amende auto-générée à la clôture pour un carnet
  déjà traité ainsi. "Autre amende (hors carnet)" retombe sur le
  dialogue générique existant. Les amendes restent cumulatives : une
  amende libre reste toujours possible en plus d'une résolution de
  carnet
- Numéro de série du carnet physique saisissable par l'agent — le
  mécanisme existait déjà en base (`redefinirNumeroSerieCarnet`) mais
  n'était jamais exposé à l'écran. Deux champs optionnels "Numéro du
  carnet physique" à l'ajout d'un membre et à la modification de ses
  carnets (`members_screen.dart`) — laissés vides, le numéro continue
  de se générer automatiquement
- Numéro de série affiché à la place de "Carnet N" sur l'écran
  Cotisation (nom + puces de carnets en tête, ligne de saisie par
  carnet) — sur le terrain, un membre est appelé par le numéro de son
  carnet, pas par son nom
- 290 tests au total dans le projet après cette série.

**Retiré**
- Boutons "Présent"/"Absent" de l'écran Cotisation (voir "Ajouté"
  ci-dessus, remplacés par "Ajouter amende").

## 2026-08-11 — Retours du fondateur après la reprise du test terrain

Deuxième vague de retours après le tout premier APK de test (voir
RETOURS_TERRAIN.md, point 21, pour le détail).

**Corrigé**
- Dialogue "Mode de paiement de l'amende" : le texte disait encore "ce
  choix est définitif — plus tard = déduite à la clôture", contredisant
  la règle déjà en place depuis le 2026-08-10 (une amende reste payable
  cash à tout moment). Texte et bouton corrigés ("Pas maintenant" au
  lieu de "Plus tard (déduite à la clôture)")
- "Durée du cycle" à la création/édition du groupe : 6 mois ajouté aux
  options (9/10/11/12 seulement jusque-là)

**Ajouté**
- `AppDatabase.modifierCotisationExceptionnelle` : motif/montant/date
  limite d'une cotisation exceptionnelle restent modifiables après sa
  déclaration (assouplit "jamais modifiable ensuite") — les paiements
  déjà enregistrés contre elle restent, eux, intouchables. Bouton
  crayon sur chaque événement de `cotisations_exceptionnelles_screen.dart`
- Totaux "amendes réglées" et "intérêts perçus" affichés sur l'écran
  Répartition de fin de cycle (déjà calculés en base, juste pas
  affichés jusque-là)
- `AppDatabase.journeeCotisationEnAttenteEtAutoClotureSiDepassee` :
  filet de sécurité — une journée ouverte dont la date a dépassé 23h se
  clôture automatiquement à la prochaine vérification (utilise la
  présence anticipée si disponible, sinon "Absence"), pour ne jamais
  rester bloqué si le bouton "Clôturer" ne s'active pas pour une raison
  peu claire sur le moment
- `AppDatabase.totalRembourseParMembreAuJour` : total remboursé par un
  membre un jour donné, base du récap "Séance du jour"

**Restructuré — séparation lecture/action**
- "Séance du jour" (`seance_jour_screen.dart`) devient un écran de
  **lecture seule** : liste des membres avec statut, tap → récap de ce
  qui a été enregistré aujourd'hui (parts par carnet, amende,
  remboursement de prêt, présence anticipée) — plus aucune action
  possible ici
- Nouvel écran `cotisation_membre_screen.dart` ("Cotisation") — devient
  LE seul écran actionnable par membre, reçoit toutes les actions
  auparavant réparties sur "Séance du jour" et l'écran membre : carnets
  + total en tête, présence (Présent/Absent), puis une rangée de
  boutons (Ajouter amende, Payer amende, Cotisation exceptionnelle,
  Fonds de solidarité, Rembourser un prêt, Demander un prêt), et
  "Enregistrer et passer au membre suivant" pour enchaîner sans
  ressortir de l'écran. Remplace l'ancien flux "Ajouter un
  encaissement" + brouillon multi-membres de `record_cotisation_screen.dart`
  (sélectionner un membre dans le menu déroulant ouvre directement ce
  nouvel écran)
- 284 tests au total dans le projet après cette série.

## 2026-08-11 — Premier test terrain (APK) : 6 corrections

Retours du fondateur après le premier essai de l'APK release sur un
vrai téléphone (voir RETOURS_TERRAIN.md, point 20, pour le détail de
chaque point et son statut). 271 tests au total dans le projet après
cette série (30 nouveaux : 6 pour la présence anticipée en base, 3
pour l'écran "Séance du jour", le reste des ajustements de fixtures).

**Corrigé**
- `create_group_screen.dart` / `edit_group_screen.dart` : à l'échec de
  `Form.validate()`, `_scrollToFirstError()` fait défiler jusqu'au
  premier champ invalide et affiche un message — jusque-là le champ
  était bien souligné en rouge mais pouvait rester hors écran sans
  retour visible sur un long formulaire
- Champ "Amende de retard de cotisation" (`Cycles.lateFeeFcfa`)
  retiré des écrans Création/Édition groupe, de l'affichage du groupe
  et du dialogue de clôture de cycle — doublonnait "Amende Absence" du
  catalogue de motifs avec une règle de priorité confuse pour l'agent.
  `AppDatabase._resolutionMotifSysteme` simplifié : toujours le
  catalogue du groupe, `lateFeeFcfa` gardé en base (migration, jamais
  supprimée) seulement comme dernier recours pour un groupe migré sans
  catalogue (avant schemaVersion 14)
- `AppClock.simulationAutorisee` (= `kDebugMode ||
  bool.fromEnvironment('FIELD_TEST_BUILD')`) : la simulation de date
  était verrouillée sur `kDebugMode` uniquement, donc invisible dans
  n'importe quel APK release, y compris celui du test terrain. Un APK
  de test se compile désormais avec `flutter build apk --release
  --dart-define=FIELD_TEST_BUILD=true` ; un APK public normal garde
  `flutter build apk --release` sans ce define et reste verrouillé

**Ajouté**
- Écran `SeanceJourScreen` ("Séance du jour") : accessible depuis
  l'écran Cotisations pendant une journée ouverte — liste des membres,
  tap → cotisation, présence (Présent/Absent, motif personnalisable),
  demande de crédit, amende, les 4 gestes au même endroit. Complète
  `MemberSessionScreen` (déjà livré le 2026-08-11 pour un autre
  contexte), ne le remplace pas
- Nouvelle table `PresenceAnticipee` (config, non hash-chaînée,
  schemaVersion 20 → 21) et `AppDatabase.marquerPresenceAnticipee` /
  `effacerPresenceAnticipee` / `presenceAnticipeeDuJour` : la présence
  marquée depuis "Séance du jour" est une **intention**, jamais
  définitive avant la vraie clôture — `cloturerJourneeCotisation` la
  relit comme valeur par défaut de `resolutions` (au lieu de toujours
  proposer "Absence"), et nettoie la table pour cette date une fois la
  journée close

## 2026-08-11 — Point 13 : rationnement collectif des crédits

**Ajouté**
- `AppDatabase.demanderPret` : dépose une demande de prêt (montant
  souhaité) sans l'accorder tout de suite — soumise à la fenêtre de
  crédit, jamais à la caisse disponible (c'est justement ce qui est
  négocié). Nouvelles tables `PretDemandes` (immuable) et
  `PretDemandeRefus` (refus/désistement, nouvelle ligne comme
  `PretAnnulations`). `Prets.demandeId` relie un prêt accordé à sa
  demande d'origine. Migration schéma v19 → v20
- `CollectiveLoanRationingCalculator` (nouveau, pur) : montant à
  proposer à la première demande en attente (FIFO) — intégral si la
  caisse suffit pour tout le monde, sinon proportionnel au prorata du
  total demandé, arrondi à l'entier inférieur
- `AppDatabase.prochaineDemandeAvecAllocation` : recalcule à chaque
  appel à partir de l'état courant — **redistribution immédiate**
  (décision explicite du fondateur) : la part des demandeurs suivants
  augmente à chaque désistement, diminue à chaque acceptation
  confirmée
- `AppDatabase.accepterDemandePret` : crée le prêt au taux résolu
  comme un prêt neuf (`LoanRateResolver`, jamais un taux plat), relié à
  la demande ; `AppDatabase.refuserDemandePret` : désistement
- Écran Prêts : section "Demandes en attente", bouton "Demander"
  (complémentaire de "Nouveau prêt", qui reste inchangé pour le cas
  simple à un seul demandeur) et "Traiter les demandes en attente" —
  boucle un demandeur à la fois (accepter/se désister/arrêter), avec
  le flux de confirmation habituel entre chaque décision
- 7 nouveaux tests DB (`rationnement_collectif_test.dart`), 7 tests
  calculateur (`collective_loan_rationing_calculator_test.dart`), 1
  test widget bout-en-bout (désistement puis acceptations,
  redistribution vérifiée à chaque étape)

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` : data/local (135 tests), domain (100 tests), features
  (suite complète) — tout passe

**Bug auto-corrigé pendant la construction** : le prêt accordé via ce
nouveau chemin n'était pas immédiatement confirmé (code de
confirmation jamais généré) — la redistribution suivante calculait
alors sur une caisse pas encore réduite, faussant l'offre du
demandeur suivant. Trouvé par le test widget bout-en-bout, corrigé
avant tout usage réel.

## 2026-08-11 — Correction : inscriptions closes seulement en fin de cycle

En passant en revue le reste du Groupe C avec le fondateur, écart
trouvé en inspectant le projet (pas signalé par le fondateur) : une
décision prise le 2026-08-10 (RETOURS_TERRAIN.md, point 16) n'avait
jamais été implémentée — le code appliquait encore l'ancienne règle.

**Corrigé**
- `ajouterMembre` fermait les inscriptions dès la clôture de la
  **première journée de cotisation** du cycle. Remplacé par la vraie
  règle décidée : un membre peut rejoindre à n'importe quel moment du
  cycle, sauf dans les **2 dernières réunions avant sa fin prévue**
- `MembershipClosureCalculator` (nouveau, pur) : calcule les réunions
  restantes avant la fin prévue du cycle, même principe que
  `LoanWindowCalculator`
- `Cycles.inscriptionsFermeesAt` reste tracé à la clôture de la 1re
  journée, mais devient purement informatif — ne ferme plus rien
- 6 nouveaux tests (`membership_closure_calculator_test.dart`), 2 tests
  réécrits dans `seances_cotisation_test.dart`, corrections dans
  `loans_screen_test.dart` (tests existants qui ouvraient un cycle sur
  une date fixe passée sans `joinedAt` explicite — l'horloge réelle
  faisait paraître le cycle déjà terminé)

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` : data/local (128 tests), domain (93 tests), features
  (suite complète) — tout passe

## 2026-08-11 — Correction : dette perdue à la clôture, plus de composition indéfinie

**Corrigé**
- Un prêt "au rouge" jamais reconduit continuait, dans les calculs, à
  composer indéfiniment même des mois après la clôture de son cycle —
  contraire à la règle du fondateur ("on considère la dette comme
  perdue" si le prêt n'est pas reconduit). `AppDatabase.soldePret`
  plafonne désormais le calcul à `Cycles.endedAt` dès que le cycle est
  clos et que la date demandée tombe après — jamais repoussé en avant
  si la date demandée est antérieure à la clôture ; un prêt reconduit
  n'est pas affecté (son successeur vit sur un cycle différent, non
  clos)
- `detteMembreFcfa`, l'écran Prêts et l'écran membre consolidé
  dupliquaient chacun l'appel à `LoanBalanceCalculator` au lieu de
  passer par `soldePret` — recentrés sur ce point d'entrée unique,
  précisément pour que ce plafond (et tout futur ajustement du calcul)
  s'applique partout de façon uniforme, sans risque de dérive entre
  les 4 endroits
- 4 nouveaux tests (`solde_pret_cloture_test.dart`) : composition gelée
  au montant de clôture même interrogée des années plus tard, une date
  demandée avant la clôture n'est jamais repoussée en avant, un cycle
  toujours en cours continue de composer normalement,
  `detteMembreFcfa` hérite du même plafond

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` : data/local (128 tests), features (suite complète)
  — tout passe

**Reste ouvert** : cette perte n'est pas encore affichée explicitement
quelque part (proche de la "perte AVEC" du partage de fin de cycle) —
le prêt reste juste gelé à son solde de clôture. Pas demandé pour
l'instant.

## 2026-08-11 — Correction : sortie du rouge à paiement libre, taux résolu comme un prêt neuf

Suite à une revue du comportement "au rouge" avec le fondateur, deux
règles avaient été mal comprises lors de la construction initiale de
C2/C4 (voir entrées précédentes) — corrigées ici avant tout usage réel.

**Corrigé**
- `sortirDuRouge` reconduisait toujours le principal d'origine en
  entier, sans jamais tenir compte de ce que le membre paie réellement
  ce jour-là. Corrigé : gagne un paramètre `montantPayeFcfa` (libre —
  0, le minimum requis, ou plus) ; le prêt reconduit vaut désormais
  `dette du jour + amende − montantPayeFcfa`. Payer le minimum
  reconduit le principal d'origine tel quel ; payer plus le réduit ;
  payer moins (ou rien) ajoute la différence au montant reconduit
- L'amende de sortie du rouge était enregistrée comme une `Amende`
  séparée, même si elle finissait absorbée dans le prêt reconduit —
  double comptage potentiel. Corrigé : plus aucune trace séparée,
  jamais (décision explicite du fondateur)
- `sortirDuRouge` et `reconduireCyclePret` utilisaient le taux plat du
  cycle (`cycle.interestRatePercent`) pour le prêt reconduit. Corrigé :
  les deux résolvent maintenant le taux comme un prêt neuf via
  `LoanRateResolver` (dans/hors carnet, plafond 3x, fenêtre des 3
  derniers mois) — y compris pour C4, où la cotisation quasi nulle en
  tout début de nouveau cycle pousse souvent vers "hors carnet"
  (confirmé volontaire)
- Écran Prêts : le dialogue "Sortir du rouge" gagne un champ "Montant
  payé aujourd'hui" (pré-rempli au minimum, modifiable) et une
  prévisualisation en direct du montant reconduit + son taux résolu,
  même principe que le dialogue "Nouveau prêt"

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` : data/local (124 tests), features (suite complète)
  — tout passe, y compris les tests réécrits pour le nouveau
  comportement (`sortir_du_rouge_test.dart`,
  `reconduire_cycle_pret_test.dart`, `loans_screen_test.dart`)

**Reste à faire, identifié pendant cette revue (pas encore construit)** :
si un prêt non soldé n'est pas reconduit à la clôture d'un cycle, sa
dette doit être considérée comme perdue — la composition "au rouge" ne
devrait donc plus continuer indéfiniment après la clôture pour un prêt
resté sans successeur. Voir DECISIONS.md, "Reconduction d'un prêt non
soldé au cycle suivant", section "Reste à construire".

## 2026-08-11 — Groupe C terminé : C4, reconduction d'un prêt au cycle suivant

**Ajouté**
- `AppDatabase.reconduireCyclePret` : reconduit un prêt non soldé dans
  le nouveau cycle qui vient d'être ouvert, jamais automatique — solde
  précis recalculé via `soldePret`, prêt successeur créé au taux du
  nouveau cycle, `estAuRougeDesLeDepart: true` (entre directement au
  rouge, pas de nouvelle période de grâce), exige sa propre
  confirmation par le membre. Réutilise le mécanisme
  `renouvelePretId`/`provenance: 'renouvellement'` déjà construit pour
  C2 — même exclusion du double comptage (`pretsNonSoldesDuCycle`,
  `detteMembreFcfa`)
- Écran de clôture de cycle : propose la reconduction, un prêt à la
  fois, une fois le nouveau cycle ouvert — accepter ou refuser
  n'affecte jamais la clôture déjà effective ; accepter déclenche le
  même flux de confirmation (code SMS/signature) qu'un nouveau prêt
- `showLoanConfirmationDialog` (nouveau, `loan_confirmation_dialogs.dart`) :
  extraction du flux de confirmation code SMS/signature — jusqu'ici
  dupliqué 3 fois dans l'écran Prêts — en une fonction partagée,
  réutilisée aussi par l'écran de clôture de cycle
- 6 nouveaux tests (4 `reconduire_cycle_pret_test.dart` + 2
  `cycle_summary_screen_test.dart`)

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` : data/local (119 tests), domain (87 tests), features
  (suite complète) — tout passe, y compris après le refactor du flux
  de confirmation dans `loans_screen.dart`

**Reste ouvert** : la reconduction n'est proposée qu'au moment de la
clôture — pas d'écran dédié pour la reconduire plus tard si l'agent la
refuse ou que le membre est absent ce jour-là (voir DECISIONS.md).

**Avec ce point, le Groupe C (fenêtres de crédit, rationnement, dette
au rouge, reconduction) est terminé.**

## 2026-08-11 — Groupe C : C2, dette de prêt "au rouge"

**Ajouté**
- `LoanBalanceCalculator` réécrit : une seule période normale au taux
  d'origine du prêt, puis — si elle expire non soldée — passage "au
  rouge" à un taux **universel de 10 %/mois**, composé chaque mois
  calendaire (jamais réunion-aligné), quel que soit le taux d'origine.
  Remplace entièrement l'ancienne recomposition au taux d'origine.
  Vérifié contre l'exemple chiffré du fondateur (100 000 → 110 000 →
  121 000, un mois puis deux)
- `LoanBalanceResult.estAuRouge` / `.soldeAuDebutDuRougeFcfa` (nouveau)
- `Groups.montantAmendeSortieRougeFcfa`, `Prets.renouvelePretId`,
  `Prets.estAuRougeDesLeDepart` (nouvelles colonnes, migration v18→v19)
- `AppDatabase.soldePret` (assembleur réutilisable) et
  `AppDatabase.sortirDuRouge` : paie les intérêts accumulés + l'amende
  fixe du groupe (si configurée), puis reconduit le solde restant dans
  un **nouveau prêt successeur** (`provenance: 'renouvellement'`,
  `renouvelePretId` vers l'ancien) — exige sa propre confirmation par
  le membre, comme tout nouveau prêt, mais exempté des vérifications
  fenêtre/caisse (pas d'argent neuf)
- `pretsNonSoldesDuCycle` et `detteMembreFcfa` excluent désormais tout
  prêt qui a un successeur connu — évite un double comptage de la même
  dette (bug découvert et corrigé pendant la construction, via
  `_idsDesPretsRenouveles()`)
- Écran Prêts : indicateur "AU ROUGE" par prêt concerné, bouton
  "Sortir du rouge" (affiche intérêts + amende à payer avant de
  confirmer, réutilise le flux de confirmation code SMS/signature).
  Écran membre consolidé : indicateur "AU ROUGE" en lecture seule
- 20 nouveaux tests (14 `loan_balance_calculator_test.dart` réécrits +
  5 `sortir_du_rouge_test.dart` + 1 `loans_screen_test.dart`)

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` (data/local — 115 tests, domain/calculators, widgets
  loans_screen + member_session_screen) : tout passe

**Reste à faire (Groupe C)** : reconduction d'un prêt non soldé au
cycle suivant (C4) — réutilisera le même mécanisme de prêt successeur.

## 2026-08-11 — Groupe C (en cours) : C1+C3, fenêtres de crédit + rationnement

**Ajouté**
- `LoanWindowCalculator` (nouveau, pur) : fenêtre de crédit ouverte
  selon la fréquence de réunion — hebdomadaire (4e réunion puis chaque
  4), bimensuelle/mensuelle (chaque 2e réunion). Reste ouverte jusqu'à
  la réunion suivante
- `AppDatabase.caisseDisponibleActuelleFcfa` : argent réellement
  disponible (cotisations + intérêts perçus + amendes réglées − prêts
  en cours), jamais le fonds de solidarité
- `AppDatabase.enregistrerPret` refuse désormais (écriture `direct`
  uniquement) si aucune fenêtre de crédit n'est ouverte, ou si le
  montant dépasse la caisse disponible
- Écran Prêts : bandeau "aucune fenêtre de crédit" avec compte à
  rebours en réunions, bouton "Nouveau prêt" désactivé hors fenêtre,
  caisse disponible affichée dans le formulaire et montant validé
  contre elle
- 10 nouveaux tests (8 `loan_window_calculator_test.dart` + 2
  `loans_screen_test.dart`)

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` (suite complète — plus de 330 tests, data, domain,
  features, import) : tout passe. 18 appels à `enregistrerPret` dans 9
  fichiers de tests existants revus individuellement (satisfaits
  explicitement ou `provenance: 'importe'` selon ce qu'ils testent
  réellement) — aucun test affaibli

**Reste ouvert** (voir RETOURS_TERRAIN.md, point 13) : la négociation
collective entre plusieurs demandeurs simultanés quand la demande
totale dépasse la caisse — pas construite, chaque demande traitée une
à la fois pour l'instant.

**Reste à faire (Groupe C)** : dette de prêt "au rouge" universelle
(C2) et reconduction d'un prêt non soldé au cycle suivant (C4).

## 2026-08-11 — Groupe B terminé : B2, cotisations exceptionnelles

**Ajouté**
- `CotisationsExceptionnelles` (schemaVersion 17 → 18) : événement
  (mariage/décès/accouchement) déclaré une fois — motif, montant par
  membre, date limite — appliqué automatiquement à tous les membres
  déjà présents dans le groupe (jamais à ceux qui rejoignent après)
- `FondsSolidariteContributions.cotisationExceptionnelleId` (nullable)
  : relie un versement à l'événement qu'il règle, bucket séparé du
  fonds obligatoire récurrent
- `preparerPartageCycle` étendu : réduction chaînée (amende, puis
  chaque cotisation exceptionnelle échue et impayée, un événement à la
  fois) — réutilise `AmendeReductionCalculator` tel quel, exclut la
  portion déduite de la caisse principale. Purement additif : aucun
  test existant modifié
- `cloturerCycleEtOuvrirSuivant` : enregistre chaque déduction
  automatique comme une contribution au fonds de solidarité, à la
  clôture réelle seulement
- Écran "Cotisations exceptionnelles"
  (`lib/features/cotisations_exceptionnelles/`) : déclarer un
  événement, suivre la collecte (membres concernés, collecté/attendu).
  Accessible depuis l'écran Groupe
- Écran membre consolidé : section "5. Cotisations exceptionnelles" —
  solde dû par événement, paiement libre, alerte si date limite
  dépassée
- 9 nouveaux tests (7 `cotisations_exceptionnelles_test.dart` — dont
  la math du chaînage amende + exceptionnelle vérifiée sur un exemple
  chiffré — + 1 `cotisations_exceptionnelles_screen_test.dart` + 1
  `member_session_screen_test.dart`)

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` (suite complète par lots — plus de 300 tests, data,
  domain, features, import) : tout passe, aucune régression malgré la
  réécriture de `preparerPartageCycle`

**Groupe B terminé** : fonds de solidarité obligatoire (B1, récurrent)
+ cotisations exceptionnelles (B2, ponctuelles), même solde/suivi.

## 2026-08-11 — Groupe B (en cours) : B1, fonds de solidarité obligatoire

**Ajouté**
- `Groups.montantSolidariteObligatoireFcfa` (schemaVersion 16 → 17) :
  montant par carnet, dû à chaque réunion, fixé une fois à la création
  du groupe. 0 par défaut = fonds facultatif (comportement historique
  préservé)
- `AppDatabase.soldeSolidariteObligatoireFcfa` : solde dû cumulé par
  membre (montant × carnets × réunions passées depuis son entrée,
  moins ce qu'il a versé) — jamais négatif, souple dans le rythme
  (peut payer d'avance ou accumuler du retard)
- Nouvelle condition de clôture de cycle : `cloturerCycleEtOuvrirSuivant`
  refuse tant qu'un membre n'a pas soldé le fonds obligatoire (voir
  `soldesSolidariteObligatoireNonSoldesDuCycle`), en plus de la
  condition "confirmé payé" déjà existante
- Écran création de groupe : champ "Fonds de solidarité obligatoire"
- Écran membre consolidé : section "4. Fonds de solidarité" (solde dû
  + bouton "Contribution", montant libre pour permettre de payer
  d'avance)
- Écran Répartition : "Clôturer ce cycle" se désactive aussi si des
  membres sont en retard sur le fonds obligatoire
- 10 nouveaux tests (`fonds_solidarite_obligatoire_test.dart`) + 1
  nouveau test `member_session_screen_test.dart`

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` (data/local complet + tous les écrans concernés, par
  lots) : tout passe, aucune régression

**Reste à faire (Groupe B)** : cotisations exceptionnelles
(mariage/décès/accouchement — voir RETOURS_TERRAIN.md, point 7).

## 2026-08-11 — Groupe A terminé : clôture interactive + section Amendes

**Ajouté**
- Clôture de journée interactive (voir DECISIONS.md) : à la clôture,
  l'agent choisit un motif (Absence / Part impayée / Payé par un
  tiers) pour chaque carnet sans rien d'enregistré, pré-rempli sur
  "Absence", modifiable ligne par ligne — remplace entièrement
  l'ancien mécanisme "amende auto-générée → revue à la séance
  suivante" (`amendesEnAttenteRevue`, bloc "Amendes à valider" retiré
  de l'écran Cotisations)
  - `AppDatabase.carnetsATraiterPourDate` (remplace
    `membresAbsentsPourDate` pour l'écran), `cloturerJourneeCotisation`
    gagne un paramètre `resolutions`
  - Résout la question ouverte `lateFeeFcfa` vs motif "Absence" du
    catalogue : `lateFeeFcfa` prioritaire quand configuré (> 0), sinon
    le catalogue du groupe — aucun test existant cassé
- `AmendesScreen` (`lib/features/amendes/amendes_screen.dart`) : toutes
  les amendes du cycle en un seul écran, filtrable (en attente /
  réglées / annulées / toutes), accessible depuis l'écran Groupe. Voir
  DECISIONS.md, "Section Amendes dédiée"
- `amende_resolution_dialogs.dart` : "Payer"/"Corriger une erreur"
  extraits en composants partagés entre l'écran membre consolidé et le
  nouvel écran Amendes
- 5 nouveaux tests (2 `record_cotisation_screen_test.dart` réécrits
  pour la clôture interactive, 2 `amendes_screen_test.dart`)

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test` (suite complète par lots — data/local, domain,
  features, import) : tout passe, aucune régression

**Groupe A terminé** : A0 à A7 tous livrés et testés (fondations
carnets/motifs, amende par carnet, paiement partiel, écran membre
consolidé, clôture interactive, section Amendes dédiée).

## 2026-08-11 — Groupe A (en cours) : écran membre consolidé

**Ajouté**
- `MemberSessionScreen` (`lib/features/cotisations/member_session_screen.dart`)
  : fiche membre unique — cotisation, amendes non soldées (paiement
  partiel/total, ajout d'amende), prêts en cours (solde, remboursement)
  — accessible en cliquant sur un membre depuis l'écran Membres. Voir
  DECISIONS.md, "Écran membre consolidé"
- `showLoanRepaymentDialog` (`lib/features/loans/loan_repayment_dialog.dart`)
  : dialogue de remboursement extrait de `loans_screen.dart`, partagé
  avec le nouvel écran membre — même principe que
  `amende_fonds_dialogs.dart`
- 3 nouveaux tests (`member_session_screen_test.dart`) : cotisation,
  paiement partiel d'amende, remboursement de prêt, tous depuis la
  fiche membre

**Vérifié**
- `flutter analyze` : aucun problème (nouveau ou pré-existant)
- `flutter test test/features/` (15 tests, y compris les 3 nouveaux et
  tous les écrans Cotisations/Prêts/Membres existants) : tout passe

**Reste à faire (Groupe A)** : clôture de journée interactive, section
"Amendes" dédiée.

## 2026-08-10 — Groupe A (en cours) : fondations — Carnets, motifs prédéfinis, validation par carnet

Premier lot de retours terrain consolidés (voir RETOURS_TERRAIN.md).
Couche données uniquement — écrans (membre consolidé, section Amendes,
clôture interactive) pas encore construits.

**Ajouté**
- Table `Carnets` (schemaVersion 12 → 13) : numéro de série physique
  persistant par carnet (`C-001`, `C-002`...), unique par groupe,
  généré automatiquement ou saisi manuellement, jamais réinitialisé
  d'un cycle à l'autre. Voir DECISIONS.md, "Numéro de série physique
  par carnet"
- `MotifsAmende` gagne `description`/`codeSysteme` (schemaVersion 13 →
  14) : 3 motifs système (absence, part impayée, payé par un tiers)
  créés automatiquement à la création du groupe, montants configurés
  au même moment (formulaire `create_group_screen.dart` mis à jour)
- `Amendes` gagne `carnetNumero`/`echeanceDate`/`motifCodeSysteme`
  (schemaVersion 14 → 15) — prépare l'amende par carnet
- `AppDatabase.motifsSystemeApplicables` : les 3 motifs système ne
  peuvent jamais se contredire pour un même carnet à une même échéance
  (voir DECISIONS.md, "Validation de cohérence des motifs par carnet")

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots, ~178 tests) : tout passe —
  nouveaux tests dédiés (`carnets_test.dart`, `motifs_systeme_test.dart`)
  + tests existants (`motifs_amende_test.dart`,
  `amende_motifs_screen_test.dart`) adaptés aux 3 motifs désormais
  toujours présents

**Ajouté depuis (même jour)** : `cloturerJourneeCotisation` applique
désormais l'amende de retard par carnet (une amende par carnet absent,
plus une seule par membre) — annule la décision inverse du 9 août.
`echeances_ledger_test.dart` réécrit en conséquence. Voir
DECISIONS.md, "Amende par carnet, pas par membre".

**Ajouté depuis (même jour)** :
- `cloturerJourneeCotisation` applique désormais l'amende de retard
  par carnet (une amende par carnet absent, plus une seule par membre)
  — annule la décision inverse du 9 août. `echeances_ledger_test.dart`
  réécrit en conséquence. Voir DECISIONS.md, "Amende par carnet, pas
  par membre"
- Table `AmendePaiements` (schemaVersion 15 → 16) : paiement partiel
  d'une amende, même principe que `PretRemboursements`.
  `enregistrerPaiementAmende` règle tout ou partie du solde restant ;
  `montantAmendesNonSoldeesFcfa` compte désormais le solde restant, pas
  le montant brut. Voir DECISIONS.md, "Paiement partiel d'une amende"

**Vérifié (ajout)** : `flutter test` (~185 tests, par lots) toujours au
vert après ces deux ajouts — nouveaux tests dédiés
(`amende_paiements_test.dart`) + `echeances_ledger_test.dart` adapté.

**Reste à faire (Groupe A)** : écran membre consolidé, clôture de
journée interactive, section "Amendes" dédiée.

## 2026-08-09 (suite 11) — Mode de paiement de l'amende demandé immédiatement

Retour d'un premier test réel de l'APK avec les fonctionnalités A/B/C/D.
Voir DECISIONS.md, "Mode de paiement de l'amende demandé immédiatement".

**Ajouté**
- `askAmendePaymentMode` (`amende_fonds_dialogs.dart`, partagé) :
  dialogue obligatoire cash/plus tard, sans option d'annulation

**Changé**
- "Ajouter une amende" (Cotisations + Répartition) : demande
  immédiatement le mode de paiement après l'enregistrement
- Écran Cotisations, amendes auto-générées en attente : bouton unique
  "Confirmer" (remplace "Confirmer telle quelle" + "Payer" séparés),
  ouvre le même choix cash/plus tard
- **Choix définitif** : une amende "plus tard" n'est plus jamais
  réglable cash ensuite — le bouton "Payer" du rappel par membre est
  retiré, ce rappel devient purement informatif
- "Erreur" (correction d'une amende auto-générée saisie par erreur)
  inchangé

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots, 164 tests) : tout passe —
  tests existants adaptés au nouveau dialogue obligatoire, deux
  nouveaux tests dédiés (choix "plus tard" : débloque sans régler,
  aucune action de paiement ensuite ; choix "cash" : réglée
  immédiatement)

## 2026-08-09 (suite 10) — Phase 5, partie C : clôture conditionnée au paiement de tous les membres

Dernier point de la série "Phase 5 — 4 changements validés (A/B/C/D)".
Voir DECISIONS.md, "Clôture de cycle conditionnée au paiement de tous
les membres".

**Ajouté**
- Table `PartagePaiementConfirmations` (schemaVersion 11 → 12) —
  workflow, pas financière
- `AppDatabase.confirmerPaiementMembre` / `annulerConfirmationPaiementMembre`
  / `membresConfirmesPayesDuCycle`
- Écran Répartition : case à cocher "payé" par membre (cycle en cours
  uniquement)

**Changé**
- `cloturerCycleEtOuvrirSuivant` refuse désormais de clôturer tant
  qu'un membre du calcul de partage n'est pas confirmé payé (vérifié
  aussi côté base, pas seulement le bouton désactivé côté écran)
- Bouton "Clôturer ce cycle" désactivé + décompte affiché tant que
  tous les membres ne sont pas cochés

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots) : tout passe — nouveaux
  tests dédiés (`partage_paiement_confirmations_test.dart`,
  4 tests) + un test d'interface bout en bout (bouton désactivé → coche
  un membre → toujours désactivé → coche le second → activé)
- Tests préexistants exerçant `cloturerCycleEtOuvrirSuivant` avec des
  membres mis à jour pour confirmer le paiement avant de clôturer

## 2026-08-09 (suite 9) — Phase 5, partie A : écran Cotisations moins chargé

Voir DECISIONS.md, "Écran Cotisations moins chargé".

**Ajouté**
- `amende_fonds_dialogs.dart` : dialogues "Ajouter une amende" et
  "Contribution fonds" factorisés, partagés entre l'écran Répartition
  et l'écran Cotisations (icônes compactes dans l'AppBar)
- `Amendes.reviewedAt` (schemaVersion 10 → 11) : distingue "revue"
  (validation de l'absence) de "réglée" (`confirmedAt`, cash ou
  déduction)
- `AppDatabase.validerAmendeTelleQuelle` : nouvelle action "Confirmer
  telle quelle" — valide sans régler

**Changé**
- `amendesEnAttenteRevue` filtre désormais sur `reviewedAt` (plus
  `confirmedAt`) — la section "Amendes en attente" de l'écran
  Cotisations bloque la saisie tant qu'elle n'est pas vide
- `confirmerAmende` renseigne aussi `reviewedAt` si absent (payer
  équivaut à avoir revu)
- Écran Cotisations : rappel d'amende(s) non soldée(s) du membre
  sélectionné devient actionnable ("Payer"), disponible à tout moment
  avant la clôture

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots) : tout passe, y compris un
  nouveau test d'interface bout en bout (amende auto-générée → écran
  bloqué → "Confirmer telle quelle" débloque sans régler → "Payer"
  règle séparément)

## 2026-08-09 (suite 8) — Phase 5, partie B : les amendes ne sont plus une dette

Récap validé point par point avec le fondateur avant implémentation.
Voir DECISIONS.md, "Les amendes ne sont plus une dette".

**Ajouté**
- `AmendeReductionCalculator` (nouveau, pur) : réduit les parts
  reconnues d'un membre pour amende non soldée (`reste = cotisation −
  amende`, `partsReconnues = reste ÷ valeur_part`, `résidu = reste −
  partsReconnues × valeur_part`) — jamais une dette résiduelle
- `AppDatabase.preparerPartageCycle` : point d'entrée partagé
  appliquant cette réduction membre par membre, réutilisé par la
  clôture réelle, la prévisualisation (écran Répartition) et la vue
  membre, pour que les trois ne divergent jamais
- `EndOfCycleCalculator`/`MemberCycleInput` : nouveau champ
  `residuSansBonusFcfa`

**Changé**
- `detteMembreFcfa` ne compte plus les amendes non soldées — seulement
  le solde de prêt confirmé non remboursé
- À la clôture d'un cycle, toute amende encore non soldée est
  automatiquement marquée réglée (par déduction), y compris les
  amendes auto-générées pour absence — jamais laissée "en attente"
  après une clôture
- Correction de cohérence comptable découverte en implémentant : le
  pot commun (base de `valeur_par_part`) exclut désormais les résidus,
  pour ne jamais reverser deux fois le même montant à un membre (voir
  DECISIONS.md pour le détail, section "Le pot commun exclut toujours
  le résidu")

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots) : tout passe — tests
  `AmendeReductionCalculator` (10), `EndOfCycleCalculator` (résidu
  seul/avec dette + invariant de conservation), scénario DB bout en
  bout (`partage_deductions_test.dart`), écran Répartition (membre
  avec amende non soldée profite quand même du bénéfice collectif sur
  ses parts reconnues, distinct d'un membre endetté par un prêt)

## 2026-08-09 (suite 7) — Phase 5, partie D : délai de recouvrement des prêts aligné sur les réunions

Voir DECISIONS.md, "Délai de recouvrement des prêts aligné sur les
réunions".

**Changé**
- `LoanBalanceCalculator.calculer` : nouveaux paramètres optionnels
  (`meetingFrequency`, `paymentDayOfWeek`, `paymentDayOfMonth1`,
  `paymentDayOfMonth2`) — la borne de fin de période devient la
  dernière vraie réunion au plus tard à la date brute (`début +
  dureeJours`), jamais une réunion après. Sans ces paramètres,
  comportement calendaire brut inchangé (rétrocompatible). Ne
  s'applique jamais à un prêt importé sans durée connue
- `loans_screen.dart` transmet la fréquence de réunion du groupe

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test test/domain/calculators/loan_balance_calculator_test.dart` :
  11/11, y compris 5 nouveaux tests dédiés à l'alignement sur les
  réunions

## 2026-08-09 (suite 6) — Phase 4 : catalogue de motifs d'amende par groupe

Dernier point des "Règles métier restant à coder" (voir ROADMAP.md) —
les trois phases de cette série de règles métier sont maintenant
terminées. Voir DECISIONS.md, "Catalogue de motifs d'amende".

**Ajouté**
- Table `MotifsAmende` (config, pas financière) : libellé + montant par
  groupe, activable/désactivable, CRUD
- Nouvel écran "Motifs d'amende" (fiche groupe, au même niveau que
  "Membres")
- `AppDatabase.creerMotifAmende`, `modifierMotifAmende`,
  `definirActifMotifAmende`, `motifsAmendeDuGroupe`,
  `motifsAmendeActifsDuGroupe`

**Changé**
- Écran Répartition, dialogue "Ajouter une amende" : liste déroulante
  des motifs actifs (pré-remplit libellé + montant, modifiables) +
  "Autre" pour la saisie libre d'avant. Un groupe sans motif configuré
  retrouve exactement l'ancien formulaire

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots) : tout passe, y compris de
  nouveaux tests CRUD et un test d'interface bout en bout (choix d'un
  motif du catalogue → montant pré-rempli → amende enregistrée)

## 2026-08-09 (suite 5) — Phase 3 : nouvelle formule de partage (caisse disponible)

Deuxième point des "Règles métier restant à coder" (voir ROADMAP.md),
récap validé en plusieurs allers-retours avec le fondateur avant
implémentation. Voir DECISIONS.md, "Nouvelle formule de partage :
caisse disponible", pour le détail complet.

**Changé**
- `EndOfCycleCalculator` entièrement réécrit : `caisse_disponible =
  cotisations + amendes réglées + intérêts perçus − dettes en cours`,
  puis `valeur_par_part = caisse_disponible ÷ total_parts` — remplace
  l'ancienne formule (intérêts+amendes proratisés, ajoutés à la
  cotisation de chacun)
- **Un membre endetté au moment du partage ne touche plus aucun
  bénéfice collectif** : son brut est plafonné à sa cotisation exacte
  (pas `valeur_par_part × ses parts`), quel que soit le montant de sa
  dette — puis sa dette est déduite comme avant (mécanisme inchangé)
- Écran Répartition de fin de cycle et écran Membre mis à jour pour la
  nouvelle formule et le nouveau plafonnement

**Ajouté**
- `AppDatabase.totalCotisationsDuCycle`,
  `totalAmendesRegleesDuCycle` (amendes réglées seulement, corrige
  `totalAmendesDuCycle` qui comptait toutes les amendes émises),
  `totalPrincipalNonRembourseDuCycle`

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots) : tout passe, y compris de
  nouveaux tests dédiés à la dilution collective et au plafonnement
  individuel, et un nouveau test d'interface pour l'écran de
  répartition (jusque-là non testé)

## 2026-08-09 (suite 4) — Phase 2 : résolution automatique du taux de prêt

Premier point des "Règles métier restant à coder" (voir ROADMAP.md),
recap validé avec le fondateur avant implémentation. Voir DECISIONS.md,
"Résolution automatique du taux de prêt".

**Ajouté**
- `LoanRateResolver` (nouveau calculateur pur) : résout automatiquement
  le taux d'un nouveau prêt — 10 % "dans le carnet" si le total
  emprunté sur le cycle (prêts en cours + nouveau prêt) reste sous 3x
  l'épargne cotisée, sinon 15 % "hors carnet" sur la totalité du prêt.
  Reclassement automatique à 15 % dans les 3 derniers mois du cycle,
  jamais de blocage.
- `AppDatabase.totalEmprunteEnCoursFcfa` : somme des principaux des
  prêts confirmés non soldés d'un membre sur un cycle.
- `formatPercent` (lib/core/formatting.dart) : "10 %" plutôt que "10.0
  %" pour l'affichage d'un taux.

**Changé**
- Écran Prêts : le taux applicable s'affiche en direct pendant la
  saisie du montant, avec la raison. La liste des prêts affiche
  "dans le carnet" / "hors carnet" pour tout prêt créé sous ce système.

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots) : tout passe, y compris 12
  nouveaux cas pour `LoanRateResolver`, 5 pour
  `totalEmprunteEnCoursFcfa`, et un test d'interface bout en bout
  (sélection du membre, saisie du montant, bascule du taux affiché,
  enregistrement)

## 2026-08-09 (suite 3) — Retouches d'écran après test réel de l'APK

Quatre petites retouches demandées après test — aucun changement de
règle métier, ni de schéma. Voir DECISIONS.md.

**Changé**
- Bouton "Confirmer telle quelle" → "Payer l'amende"
- Dialogue de clôture de journée : "La réunion est terminée — clôturer
  le [date] ?"
- Section "Amendes en attente" : une ligne compacte par amende au lieu
  de trois (moins d'espace pris pendant la saisie de cotisation)
- Historique : étoile rouge devant une date (et son mois) qui a encore
  une amende `en_attente`

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test test/features/cotisations/record_cotisation_screen_test.dart` : vert

## 2026-08-09 (suite 2) — Amendes plus jamais réglées automatiquement, historique par mois

Retours du fondateur après le rebuild précédent. Voir DECISIONS.md pour
le détail de chaque décision.

**Changé**
- **Une amende ne se règle plus jamais automatiquement** : contredit la
  décision du 7 août ("Fusion cotisation + amende"). Enregistrer une
  cotisation ne solde plus les amendes en attente du membre — seul le
  bouton "Confirmer telle quelle" (section "Amendes en attente") règle
  une amende, toujours par un geste explicite et séparé
- Écran Cotisations : le brouillon d'encaissement ne concerne plus que
  les cotisations ; une amende en attente s'affiche comme un simple
  rappel informatif, jamais ajoutée au total ni au brouillon
- Historique des cotisations regroupé par mois (section dépliable par
  mois, contenant les séances de ce mois) — évite une liste de dates
  sans fin sur un cycle de plusieurs mois. Le mois en cours est déplié
  par défaut

**Ajouté**
- `formatMoisAnneeFr` (lib/core/formatting.dart) — libellé "août 2026"

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` : tout passe, y compris les scénarios AD et Mr AB
  réécrits pour vérifier explicitement qu'une amende reste en attente
  après un encaissement, et ne se règle que via `confirmerAmende`

## 2026-08-09 (suite) — Correction du plafond journalier (cumul par échéance)

Bug trouvé en écrivant les tests de la série précédente (pas par un
test réel du fondateur cette fois) : `flutter test` a révélé qu'un
scénario "deux transactions pour la même échéance le même jour"
n'additionnait pas correctement. Voir DECISIONS.md, "Le plafond
journalier se base sur l'échéance, pas sur l'heure de saisie".

**Corrigé**
- `partsDejaAjouteesAujourdhui` comparait `Cotisations.recordedAt`
  (horodatage réel/simulé de la saisie) au jour de l'échéance visée —
  les deux ne coïncident pas forcément (saisie tardive, ou plusieurs
  passages le même jour). La deuxième transaction ne voyait jamais la
  première : le plafond de 5 parts/carnet/jour ne s'appliquait pas
  correctement, et l'affichage du cumul du jour pouvait être faux
- `Cotisations` gagne `echeanceDate` (colonne dédiée, distincte de
  `recordedAt`) ; le calcul du cumul journalier filtre désormais
  dessus. Migration drift schemaVersion 8 → 9

**Ajouté**
- `supabase/migrations/0005_parts_payees_et_echeance_date.sql` :
  comble aussi le trou laissé par `Echeances.partsPayees`
  (schemaVersion 8), jamais miré côté Postgres jusqu'ici

**Vérifié**
- `flutter analyze lib test` : aucun problème
- `flutter test` (toute la suite, par lots pour éviter l'OOM Dart
  constaté sur cette machine lors d'un run complet) : tout passe, y
  compris le nouveau cas qui avait révélé le bug

## 2026-08-09 — Amende seule (jamais de rattrapage), corrections d'affichage

Nouveaux retours après un deuxième test réel de l'APK (captures d'écran
à l'appui). Voir DECISIONS.md pour le détail complet de chaque
décision.

**Changé**
- **Suppression du rattrapage** : une échéance manquée reste
  définitivement à 0 part — seule l'amende prédéfinie s'applique, plus
  aucun mécanisme ne la rattrape. Contredit explicitement la décision
  du 8 août sur ce point précis, tranchée à nouveau par le fondateur
  après test réel
- `Echeances` gagne `partsPayees` (nombre de parts explicite, cumulé si
  plusieurs transactions le même jour pour le même carnet) — corrige un
  bug d'affichage où l'écran montrait toujours "1 part" quel que soit
  le nombre réellement acheté
- `detteMembreFcfa` simplifié : n'inclut plus l'arriéré de cotisation
  (qui n'existe plus), seulement amendes non soldées + solde de prêt
- Étiquettes "carnet" → "part" corrigées sur l'écran de répartition de
  fin de cycle (confusion de vocabulaire, pas un bug de calcul)
- Section "Amendes en attente" masquée tant qu'aucune journée de
  cotisation n'est ouverte (évitait un écran contradictoire)

**Corrigé**
- Risque de paiement invisible : l'ancienne écriture pouvait enregistrer
  plus de parts en cotisation qu'il n'existait d'échéances pour les
  recevoir, laissant de l'argent compté financièrement mais invisible
  dans les vues par date. Une transaction écrit désormais toujours
  exactement une ligne visible, garanti par construction

**Retiré**
- `EcheanceCalculator.soldeDuFcfa` (n'a plus de sens sans rattrapage)
- Écran Cotisations : calcul de "montant dû" remplacé par "déjà ajouté
  aujourd'hui" + choix libre de parts supplémentaires (0 à 5, plafond
  cumulé sur la journée, inchangé)

## 2026-08-08 (suite) — Clôture de journée : précisions après premier test réel

Après un premier test réel de l'APK par le fondateur, plusieurs
précisions sur le fonctionnement de la journée de cotisation. Voir
DECISIONS.md, "Clôture de journée : précisions apportées après un
premier test réel".

**Ajouté / changé**
- Saisie de cotisation bloquée tant qu'aucune journée n'est ouverte
  (entre deux dates de paiement, ou après clôture de la journée en
  cours) — `journeeCotisationEnAttente` sert de porte d'entrée unique
  sur l'écran Cotisations
- Plafond de 5 parts par carnet et par jour rendu **cumulatif**
  (`partsDejaAjouteesAujourdhui`) plutôt que limité à une seule
  transaction
- `membresAbsentsPourDate` (lecture seule) + nouveau message de
  confirmation nominatif avant l'exécution réelle d'une clôture de
  journée ("X ne figure pas sur la liste. Il écopera d'une amende de Y
  FCFA au prochain paiement.")
- Section "Amendes en attente de règlement" remontée en haut de l'écran
  Cotisations
- Nouvelle section "Encaissements déjà enregistrés" sur l'écran
  Cotisations : reste visible en permanence pendant la journée en
  cours (membre, carnet, montant, heure, agent), ne se vide plus après
  confirmation (`echeancesResoluesPourDate`)
- `statutsAmendes` (`en_attente`/`reglee`/`annulee`) affiché dans
  l'écran Historique à côté de chaque échéance concernée
- Libellés de fréquence clarifiés à la création/édition d'un groupe
  ("Hebdomadaire (une fois par semaine)"...)
- L'annulation de clôture de journée est **conservée telle quelle**
  (question soulevée puis confirmée par le fondateur après explication
  de son fonctionnement exact)
- 6 nouveaux tests, 108 au total dans le projet

## 2026-08-08 — Refonte carnet/part, clôture de journée, correctif joinedAt

Un responsable de terrain a corrigé une hypothèse de la veille ("1
carnet par fiche membre") : un membre peut en réalité détenir 1 ou 2
carnets directement sur sa fiche. Un document de règles écrit avec un
agent a précisé, en plus, que le nombre de parts déposées à chaque
cotisation est libre (1 à 5) plutôt que figé pour tout le cycle — avec
un minimum d'1 part par échéance, sinon retard/absence. Le fondateur a
aussi fait remonter et fait corriger un bug réel : un membre ajouté en
cours de cycle était facturé pour des échéances antérieures à son
entrée. Voir DECISIONS.md pour le détail complet de chaque décision.

**Ajouté / changé**
- `CarnetsEngages.nombreCarnets` (1 ou 2, remplace l'ancien
  `partsCount` 1-5) : un membre détient des carnets, plus un
  multiplicateur. `Cotisations` et `Echeances` gagnent `carnetNumero` —
  chaque carnet suit désormais ses propres échéances et son propre
  arriéré indépendamment de l'autre
- `EcheanceCalculator.soldeDuFcfa` simplifié (retrait du paramètre
  `carnetsEngages` — toujours 1 part minimum par échéance) ;
  `maxPartsParTransaction` (5) et `estUnMontantValide` portent la
  nouvelle contrainte ("aucun montant intermédiaire, jamais plus de 5
  parts en une fois")
- `AppDatabase.enregistrerEncaissementMembre` (remplace
  `enregistrerEncaissementSeance`) : traite chaque carnet du membre
  indépendamment, règle les amendes non soldées en une fois (fusion
  cotisation + amende inchangée)
- **Clôture explicite de la journée de cotisation**
  (`cloturerJourneeCotisation`) : remplace la détection automatique par
  l'horloge (`AmendeAutoService`, retiré). L'agent clôture chaque date à
  la fin de sa réunion — un bandeau rappelle une clôture en attente
  sans jamais la déclencher seul. Ferme les inscriptions du cycle
  (`Cycles.inscriptionsFermeesAt`) dès la première séance clôturée —
  `ajouterMembre` refuse explicitement au-delà. `annulerClotureJournee`
  permet de revenir en arrière si rien ne s'est passé depuis
- Correctif `joinedAt` : toutes les échéances d'un membre s'ancrent
  désormais sur `max(début du cycle, date d'entrée du membre)` —
  `ajouterMembre` accepte un `joinedAt` explicite, résolu via
  `AppClock.now()` plutôt que l'horodatage SQL brut, pour rester
  simulable en mode debug comme le reste de la logique temporelle
- Écran Cotisations réécrit : saisie du nombre de parts (0 à 5) par
  carnet, montant suggéré ajustable ; nouveau bandeau de clôture de
  journée et bouton d'annulation de la dernière clôture
- Écran Membres : choix 1 ou 2 carnets (au lieu de 1 à 5)
- Migration Postgres `0004_carnets_et_seances.sql` — au passage, dette
  technique constatée : `carnets_engages` et plusieurs colonnes de
  schemaVersion 4-5 n'avaient jamais été miroitées côté Postgres (sans
  conséquence tant que la synchronisation reste inactive, voir
  ROADMAP.md)
- ~20 tests réécrits ou ajoutés (registre d'échéances par carnet,
  clôture de journée, annulation), 102 au total dans le projet

**Restant à coder** (même document de règles, voir ROADMAP.md) : plafond
et taux de prêt (3×, 10 %/15 %), nouvelle formule de partage ("caisse
disponible"), catalogue de motifs d'amende par groupe — valeurs codées
en dur pour l'instant, configurables par groupe dans un second temps.

## 2026-08-07 — Registre d'échéances, fusion cotisation+amende, déduction des dettes au partage

Règles précisées par le fondateur avec des exemples concrets (AD 1
carnet, AB 2 carnets, scénarios de partage 120000/20000,
50000/50000, 80000/100000). Voir DECISIONS.md pour le détail complet.

**Ajouté**
- `Echeances` (migration schémaVersion 5→6, ajout seul) : une ligne par
  membre et par échéance, statut `paye`/`non_paye`. `AmendeAutoService`
  trace désormais toujours une échéance manquée, même dans un groupe
  sans amende automatique (avant : la méthode s'arrêtait immédiatement
  si `lateFeeFcfa = 0`, rien n'était tracé)
- `AppDatabase.enregistrerEncaissementSeance` : un seul encaissement par
  membre règle l'arriéré de cotisation **et** toutes ses amendes non
  soldées, composition détaillée à l'écran Cotisations ("1000 F
  cotisation + 500 F amende = 1500 F"). Le nombre de carnets engagés
  n'est jamais modifié par un rattrapage — vérifié par test
- `CotisationsHistoryScreen` (icône dans la barre de l'écran
  Cotisations) : historique regroupé par date d'échéance, dépliable,
  statut Payé/Non payé par membre — remplace la liste plate précédente
- `PartageDeductions` (ajout seul) + `DebtDeductionCalculator` (pur,
  testé séparément) : au partage de fin de cycle, la dette totale d'un
  membre (arriéré de cotisation + amendes non soldées + solde de prêt
  confirmé non remboursé) est déduite du montant qu'il aurait dû
  percevoir ; l'excédent non récupéré est enregistré comme perte pour
  l'AVEC. Figé une fois pour toutes à la clôture réelle du cycle
  (`cloturerCycleEtOuvrirSuivant`) — un cycle déjà clos affiche ces
  valeurs telles quelles, jamais recalculées après coup
- Écran de répartition (`CycleSummaryScreen`) : affiche pour chaque
  membre endetté le montant brut, la dette, le montant déduit, le
  montant net versé et, s'il y en a une, la perte AVEC
- Migration Postgres `0003_echeances_et_partage.sql` (tables + RLS,
  même schéma que le miroir `drift`)
- 14 nouveaux tests (registre d'échéances, fusion cotisation+amende,
  déduction de dette pure et intégrée), 96 au total dans le projet

**Sujet ouvert résolu différemment** : "report de dette d'un cycle à
l'autre" (ROADMAP.md) — un prêt non soldé n'est toujours pas reporté
automatiquement au cycle suivant, mais son solde est maintenant déduit
du partage plutôt que de rester un avertissement sans suite.

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

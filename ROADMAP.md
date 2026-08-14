# Roadmap — CotisApp

> **Retours terrain en cours de collecte** : voir RETOURS_TERRAIN.md —
> plusieurs présidents/agents ont testé l'app et fait remonter des
> observations, dont certaines contredisent des décisions déjà prises
> (voir ce document). Rien n'y est codé ni tranché tant que le
> fondateur n'a pas confirmé, potentiellement après d'autres retours.

## Fait (cette étape — V0, hors ligne, sans paiement)

- Groupes, membres, cycles
- Cotisations cash + prêts avec consentement (mode dev) + remboursements
- Amendes, fonds de solidarité (jamais mélangé au calcul)
- Calcul de répartition de fin de cycle fidèle à la formule du skill
  `avec-business-rules`, testé contre un scénario Kondoukro
- Historique en ajout seul avec chaîne de hash sur les tables
  financières
- Table d'affectation du rôle agent (changement possible entre cycles)
- Import d'historique (CSV collé) — skill `historical-data-import` :
  parseur tolérant aux dates/montants approximatifs, résolution des
  membres, résumé + confirmation explicite avant écriture, champ
  `provenance` (`direct`/`importe`) sur toutes les tables financières,
  prêts importés comptés dans le calcul de fin de cycle au même titre
  que les prêts directs confirmés
- Import multi-cycle : création de cycles historiques déjà clos
  (numéro, dates, valeur de part et taux propres), écran de sélection
  du cycle cible avant import, écran "Cycles" pour retrouver et
  consulter la répartition de n'importe quel cycle passé — les cycles
  restent isolés les uns des autres dans le calcul
- Accès en lecture pour les membres (skill `two-tier-access-model`) :
  choix de rôle agent/membre à l'identification, recherche par numéro
  de téléphone (tous groupes confondus), écran membre affichant
  uniquement ses propres parts, cotisations, prêts et son estimation de
  fin de cycle — jamais les données des autres membres, jamais
  d'action d'écriture. Affectation automatique du créateur d'un groupe
  comme agent (corrige un trou où `affecterRole` n'était jamais
  appelée)
- Vocabulaire "carnet" (plutôt que "part") dans toute l'interface — le
  terme réellement utilisé par les groupes AVEC. Champ technique
  interne inchangé (`partsCount`...), documenté dans les skills
  `localisation-fr-afrique-ouest` et `avec-business-rules`.
- Amende de retard de cotisation : montant configurable par cycle.
  **Remplacé le 2026-08-06** par une application automatique différée
  (voir plus bas) — l'agent confirme ou corrige a posteriori plutôt que
  de taper un bouton par membre.
- Projet Supabase créé, schéma PostgreSQL + RLS migré et vérifié par un
  test de fumée réel (`supabase/tests/rls_smoke_test.sql`) : un membre
  ne voit que sa propre donnée, l'agent voit tout son groupe.
  `supabase_flutter` câblé dans l'app sans dépendance bloquante hors
  ligne.
- Clôture de cycle et ouverture du suivant : bouton sur l'écran de
  répartition, avertissement (non bloquant) sur les prêts non soldés,
  paramètres du cycle suivant configurables (carnet, taux, amende) —
  jusqu'ici un groupe réel se serait retrouvé bloqué au premier cycle.
- Membres sans téléphone personnel : `phoneNumber` nullable, confirmation
  de prêt par signature capturée à l'écran (au lieu du code SMS) pour ces
  membres — décision produit tranchée avec le fondateur. Limite acceptée :
  ces membres n'ont pas accès à l'espace membre en lecture seule.
- Carnets figés par membre et par cycle (choisis une fois, verrouillés
  au premier paiement), jour de paiement fixe configuré à la création
  du groupe, montant de cotisation calculé automatiquement avec cumul
  des échéances manquées (`EcheanceCalculator`), écran Cotisations
  réécrit en deux temps (liste du jour → vérification → enregistrement
  définitif), prêts à intérêt composé sur solde restant
  (`LoanBalanceCalculator`) avec montant dû et temps restant affichés.
  Règles précisées par le fondateur, tranchées explicitement avant
  codage — voir DECISIONS.md.
- Modification du groupe/cycle (nom, durée, fréquence, jour de
  paiement, valeur du carnet, taux, amende, durée de prêt) tant
  qu'aucune cotisation n'a encore été enregistrée — icône crayon sur
  l'écran du groupe, refus explicite côté base une fois la première
  cotisation posée (`modifierGroupeEtCycle`).
- Amendes de retard automatiques (`AmendeAutoService`) : détectées et
  appliquées sans tap manuel à chaque ouverture de l'écran Cotisations,
  jamais pour l'échéance en cours, jamais deux fois pour la même
  échéance manquée — l'agent confirme ou corrige (annule + enregistre
  la cotisation manquante à la vraie date) à la séance suivante.
  Remboursement de prêt : bouton masqué une fois soldé, montant plafonné
  au dû réel.
- Annulation d'une clôture de cycle faite par erreur — uniquement si le
  nouveau cycle n'a encore aucune donnée (voir DECISIONS.md).
- Horloge de test (`AppClock`, mode debug uniquement) : simuler une
  date pour dérouler plusieurs semaines/mois de test sans attendre ni
  toucher à l'horloge du téléphone.
- Registre d'échéances (`Echeances`, ajout seul) : chaque échéance close
  est désormais tracée payée ou non — y compris dans un groupe sans
  amende automatique, ce que l'ancien mécanisme ne faisait pas. Écran
  Historique des cotisations (icône dans la barre de l'écran
  Cotisations) : groupé par date, dépliable, statut Payé/Non payé par
  membre.
- Fusion cotisation + amende : l'écran Cotisations affiche et encaisse
  en une seule fois l'arriéré de cotisation et les amendes non soldées
  d'un membre, composition toujours détaillée à l'écran.
- Déduction des dettes au partage de fin de cycle — **amendes non
  soldées + solde de prêt non remboursé** (l'arriéré de cotisation n'en
  fait plus partie depuis le 9 août, voir plus bas), avec perte pour
  l'AVEC enregistrée (`PartageDeductions`) si la dette dépasse le
  montant à percevoir — voir DECISIONS.md.
- Refonte carnet/part (2026-08-08, règles confirmées par un responsable
  de terrain) : un membre détient 1 ou 2 carnets (jamais un
  multiplicateur libre 1-5), chaque carnet suit ses échéances
  indépendamment. Écran Cotisations réécrit (saisie par carnet). Voir
  DECISIONS.md.
- Clôture explicite de la journée de cotisation par l'agent — remplace
  la détection automatique basée sur l'horloge. Ferme les inscriptions
  du cycle dès la première séance clôturée, annulable si rien ne s'est
  passé depuis. Voir DECISIONS.md.
- Correction du bug `joinedAt` : un membre ajouté en cours de cycle
  n'est plus jamais facturé pour des échéances antérieures à son
  entrée dans le groupe.
- **Amende seule, jamais de rattrapage** (2026-08-09, tranché après
  test réel) : une échéance manquée reste définitivement à 0 part,
  seule l'amende prédéfinie s'applique — remplace le mécanisme de
  rattrapage (jusqu'à 5 parts pour rattraper) prévu la veille. Un
  carnet peut toujours recevoir 1 à 5 parts par jour, mais seulement
  par choix volontaire du membre, jamais pour compenser une autre date.
  Voir DECISIONS.md.
- Correction du plafond journalier (2026-08-09, trouvée par les tests) :
  le cumul de parts/jour se basait sur l'horodatage réel/simulé de la
  saisie au lieu de la date d'échéance visée — deux transactions pour
  la même échéance à des instants réels différents ne s'additionnaient
  pas. `Cotisations` gagne `echeanceDate` (schemaVersion 8 → 9). Voir
  DECISIONS.md.
- **Une amende ne se règle plus jamais automatiquement** (2026-08-09,
  contredit la décision du 7 août) : enregistrer une cotisation ne
  solde plus les amendes en attente du membre — seul un geste explicite
  ("Confirmer telle quelle") règle une amende. Voir DECISIONS.md.
- Historique des cotisations regroupé par mois (2026-08-09) — évite une
  liste de dates sans fin sur un cycle de plusieurs mois.
- Retouches d'écran après test réel (2026-08-09) : bouton "Payer
  l'amende" (libellé plus clair), clôture de journée précisant "la
  réunion est terminée", section "Amendes en attente" compactée,
  étoile rouge dans l'Historique pour repérer une date/mois avec
  amende non réglée. Voir DECISIONS.md.

## Décision du fondateur — authentification réelle reportée à la fin

L'app doit d'abord être pleinement fonctionnelle et testée en local
avant d'ajouter Twilio (service payant, coût par SMS). Tant que
`DevAuthGateway` reste en place : pas de session persistante réelle, et
la synchronisation Supabase ne peut pas démarrer (RLS a besoin d'un
`auth.uid()` réel — voir DECISIONS.md). C'est un choix assumé, pas un
oubli : les étapes ci-dessous sont donc réordonnées pour avancer sur ce
qui ne dépend pas d'un compte externe.

## Règles métier restant à coder (document de règles partagé par le fondateur, 2026-08-08)

Un document de règles écrit avec un responsable/agent de terrain a
précisé plusieurs sujets non encore codés. Le socle (carnets, parts,
clôture de journée, bug `joinedAt`) est fait — voir "Fait" ci-dessus et
DECISIONS.md. Ordre convenu avec le fondateur :

1. ~~**Prêts**~~ — **fait le 2026-08-09** : plafond souple 3× l'épargne
   cotisée (comparé au total emprunté sur le cycle, pas au nouveau prêt
   seul ; seuil de bascule vers le taux "hors carnet", pas un mur dur),
   deux taux automatiques (10 % dans le carnet / 15 % hors carnet,
   bascule totale sur tout le prêt), reclassement automatique
   (jamais de blocage) dans les 3 derniers mois du cycle. Voir
   DECISIONS.md, "Résolution automatique du taux de prêt".
2. ~~**Partage de fin de cycle**~~ — **fait le 2026-08-09** : nouvelle
   formule = caisse disponible (cotisations + amendes réglées +
   intérêts perçus − dettes en cours) ÷ total des parts — remplace la
   formule précédente (intérêts + amendes proratisés, ajoutés à la
   cotisation de chacun). Un membre endetté au moment du partage ne
   touche plus aucun bénéfice collectif, quel que soit le montant —
   plafonné à sa cotisation exacte. Voir DECISIONS.md, "Nouvelle
   formule de partage : caisse disponible".
3. ~~**Catalogue d'amendes par groupe**~~ — **fait le 2026-08-09** :
   motifs configurables (libellé + montant) par groupe, CRUD, avec
   option "Autre" gardant la saisie libre pour les cas hors catalogue —
   voir DECISIONS.md, "Catalogue de motifs d'amende". **Les trois
   points de cette liste sont maintenant terminés.**

Valeurs codées en dur pour le plafond de prêt et sa fenêtre (3×, taux
10/15 %, fenêtre 3 mois) — rendues configurables par groupe **dans un
second temps, une fois les règles stabilisées** (décision explicite du
fondateur, pour ne pas construire un écran de paramétrage avant d'être
sûr des valeurs).

## Phase 5 — 4 changements validés après premier test réel de l'APK (2026-08-09)

Récap consolidé validé par le fondateur ("vas-y") :

- **A. ~~Écran Cotisations moins chargé~~** — **fait le 2026-08-09** :
  voir DECISIONS.md, "Écran Cotisations moins chargé".
- **B. ~~Les amendes ne sont plus une dette~~** — **fait le 2026-08-09** :
  voir DECISIONS.md, "Les amendes ne sont plus une dette". Une amende
  (manuelle ou auto-générée) réduit désormais les parts reconnues d'un
  membre au partage plutôt que de plafonner son montant net comme une
  dette de prêt.
- **C. ~~Clôture de cycle conditionnée au paiement de tous les
  membres~~** — **fait le 2026-08-09** : voir DECISIONS.md, "Clôture de
  cycle conditionnée au paiement de tous les membres". **Les quatre
  points de cette série sont maintenant terminés.**
- **D. ~~Délai de recouvrement des prêts aligné sur les réunions~~** —
  **fait le 2026-08-09** : voir DECISIONS.md, "Délai de recouvrement des
  prêts aligné sur les réunions".

## Phase 6 — 6 retours du premier test terrain APK (2026-08-11)

Voir RETOURS_TERRAIN.md, point 20, pour le détail de chaque point et
CHANGELOG.md pour l'implémentation. Tous **faits le 2026-08-11** :

- **20.1. ~~Nom du groupe obligatoire~~** — déjà le cas, rien à corriger.
- **20.2. ~~Tous les champs de création de groupe obligatoires~~** —
  déjà le cas (validateurs existants, 0 reste valide si tapé), rien à
  corriger.
- **20.3. ~~Champ oublié pas assez visible~~** — `_scrollToFirstError()`
  sur `create_group_screen.dart`/`edit_group_screen.dart`.
- **20.4. ~~"Amende de retard" doublonne "Amende Absence"~~** — champ
  retiré, catalogue de motifs devient la seule source.
- **20.5. ~~Date simulée indisponible dans l'APK de test terrain~~** —
  `AppClock.simulationAutorisee`, build avec
  `--dart-define=FIELD_TEST_BUILD=true`.
- **20.6. ~~Écran Cotisations sans fiche consolidée par membre~~** —
  nouvel écran `SeanceJourScreen` ("Séance du jour"), accessible depuis
  Cotisations : cotisation + présence + crédit + amende par membre.

## Phase 7 — reprise du test terrain, retours du même jour (2026-08-11)

Voir RETOURS_TERRAIN.md, point 21. Tous **faits le 2026-08-11** :

- **21.1. ~~Séance du jour en lecture seule~~** — plus aucune action
  possible sur cet écran.
- **21.2. ~~Refonte de l'écran Cotisation~~** — nouvel écran
  `CotisationMembreScreen` selon le croquis du fondateur, devient
  l'unique écran actionnable par membre.
- **21.3. ~~Totaux amendes/intérêts sur Répartition~~** — affichés.
- **21.4. ~~Texte du dialogue "Mode de paiement de l'amende" obsolète~~**
  — corrigé.
- **21.5. ~~Clôture automatique après 23h~~** — filet de sécurité livré.
- **21.6. ~~Cotisation exceptionnelle modifiable~~** — motif/montant/date
  limite modifiables après coup.
- **21.7. ~~6 mois manquant comme durée de cycle~~** — ajouté.

## Phase 8 — reprise du test terrain, retours plus tard le même jour (2026-08-11)

Voir RETOURS_TERRAIN.md, point 22. Tous **faits le 2026-08-11** :

- **22.1. ~~Numéro de série du carnet saisissable~~** — champ optionnel
  ajouté à l'ajout d'un membre et à la modification de ses carnets.
- **22.2. ~~Plus de bouton Présent/Absent~~** — remplacé par "Ajouter
  amende", qui résout le carnet tout de suite
  (`resoudreCarnetImmediat`).
- **22.3. ~~Numéro de carnet affiché à la place du nom~~** — sur
  l'écran Cotisation.
- **22.4. ~~Rappels hors carnet~~** — vérifiés, déjà corrects, rien à
  changer.

## Dette technique — miroir Postgres en retard sur le schéma drift

Constaté le 2026-08-08 en écrivant la migration `0004` :
`carnets_engages` n'avait jamais été créée côté Postgres (ajoutée en
drift à schemaVersion 4, jamais miroitée), et plusieurs colonnes de
schemaVersion 4-5 manquent aussi (`groups.payment_day_of_week`/
`payment_day_of_month1`/`2`, `cycles.loan_duration_days`,
`amendes.est_auto_generee`/`confirmed_at`, table `amende_annulations`).
Sans conséquence tant que la synchronisation Supabase reste inactive
(bloquée par l'authentification Twilio, voir ci-dessous) — mais **à
combler avant de brancher la synchronisation réelle**, pas avant.

## Prochaines étapes, dans l'ordre recommandé

1. **Sélecteur de fichier pour l'import** — deux tentatives, deux
   échecs identiques (2026-08-01 puis 2026-08-05, `file_picker` ^8.1.6
   puis ^11.0.3 — dernière version disponible, réécrite entre-temps en
   architecture fédérée pour le support AGP 9). Même erreur exacte à
   chaque fois : `cannot find symbol
   com.mr.flutter.plugin.filepicker.FilePickerPlugin`. Flutter est
   maintenant explicite sur la cause : `file_picker` applique son propre
   Kotlin Gradle Plugin (KGP), ce que le "Built-in Kotlin" de cette
   version de Flutter ne supporte pas — et prévient que les futures
   versions de Flutter refuseront carrément de builder avec ce genre de
   plugin. Le collage manuel de CSV reste la seule méthode d'import.
   **Ne pas retenter avec `file_picker` sans changement en amont** — soit
   une version future du paquet migrée vers le Built-in Kotlin (à
   vérifier sur son changelog avant de réessayer), soit un remplacement
   par un sélecteur écrit à la main via `MethodChannel` (code Android
   propre au projet, pas un plugin tiers — contourne le conflit
   puisqu'aucun autre plugin actuel n'applique son propre KGP). Priorité
   basse : non bloquant pour l'usage réel de l'app.

2. **Authentification réelle (Twilio)** — reportée à la fin par
   décision du fondateur (voir ci-dessus). Configurer Twilio dans
   Supabase Auth, remplacer `DevAuthGateway`. Coût par SMS à confirmer
   avant activation, ~15-30 FCFA/SMS en zone UEMOA selon le pays et
   l'opérateur.

3. **Synchronisation offline ↔ Supabase** — bloquée par l'étape 2.

4. **Paiement à distance (V1)** — seulement une fois : (a) le statut
   réglementaire du flux vérifié auprès de l'agrégateur/d'un juriste
   local, (b) une entité légale CotisApp constituée, (c) un compte
   PayDunya ou DEXCHANGE ouvrable (numéro UEMOA disponible). Le skill
   `cotisapp-payment-flow` documente déjà le flux technique cible.

## Sujets ouverts, non traités par le code actuel

- Dashboard web pour ONG/institutions (skill `avec-business-rules`
  positionnement) — après demande B2B confirmée, pas avant.
- Dépôt de marque CotisApp / recherche d'antériorité OAPI.
- ~~Report de dette d'un cycle à l'autre pour un prêt non soldé~~ —
  résolu différemment le 2026-08-07 : plutôt qu'un report automatique au
  cycle suivant (toujours pas modélisé, et volontairement), le solde de
  prêt non remboursé est désormais déduit du montant que le membre
  perçoit au partage ; ce qui n'est pas récupéré devient une perte
  enregistrée pour l'AVEC (voir DECISIONS.md, "Déduction des dettes au
  partage").
- `membresEnRetard` (ancienne détection à période glissante) n'est plus
  utilisé par aucun écran depuis le passage aux amendes automatiques
  (`AmendeAutoService`) — méthode et ses tests dédiés conservés tels
  quels mais orphelins. Un nettoyage (suppression ou réutilisation)
  pourra être fait plus tard, pas urgent.
- Un groupe créé un autre jour que le jour de paiement choisi verra sa
  première échéance tomber quelques jours après sa création — normal,
  pas un bug (voir DECISIONS.md, épisode du 2026-08-06). C'est
  justement pour ce cas que les paramètres du groupe restent
  modifiables tant qu'aucune cotisation n'est encore enregistrée.
- ~~Deux écrans membre faisaient des choses très proches en
  parallèle~~ — résolu le 2026-08-13 : `MemberSessionScreen` (l'ancienne
  "fiche membre consolidée") supprimé, `members_screen.dart` ouvre
  désormais `CotisationMembreScreen` comme le reste de l'app (voir
  DECISIONS.md, "Fusion des écrans membre").

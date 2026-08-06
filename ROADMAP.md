# Roadmap — CotisApp

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

## Décision du fondateur — authentification réelle reportée à la fin

L'app doit d'abord être pleinement fonctionnelle et testée en local
avant d'ajouter Twilio (service payant, coût par SMS). Tant que
`DevAuthGateway` reste en place : pas de session persistante réelle, et
la synchronisation Supabase ne peut pas démarrer (RLS a besoin d'un
`auth.uid()` réel — voir DECISIONS.md). C'est un choix assumé, pas un
oubli : les étapes ci-dessous sont donc réordonnées pour avancer sur ce
qui ne dépend pas d'un compte externe.

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
- Report de dette d'un cycle à l'autre pour un prêt non soldé à la
  clôture — l'app avertit seulement, ne modélise aucun mécanisme
  automatique (voir DECISIONS.md).
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

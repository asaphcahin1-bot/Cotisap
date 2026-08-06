# Architecture — CotisApp

## Vue d'ensemble (V0)

```
UI (features/*)  --Riverpod-->  AppDatabase (drift/SQLite local)
        |
        +-- domain/calculators/EndOfCycleCalculator  (pur, sans dépendance DB)
        |
        +-- domain/import/HistoricalImportParser     (pur, sans dépendance DB)
        +-- data/import/HistoricalImportService       (pont parseur <-> AppDatabase)
        |
        +-- data/auth/AuthGateway  (DevAuthGateway pour l'instant)
```

Il n'y a pas encore de backend distant. Tout tourne en local, hors
ligne, sur l'appareil de l'agent — conforme au skill
`offline-first-flutter`. La synchronisation Supabase est prévue mais
pas branchée (voir ROADMAP.md).

## Couche données locale (`lib/data/local/`)

- **Tables mutables** : `groups`, `members`, `cycles`. Ce sont des faits
  administratifs (nom, numéro de téléphone, statut d'un cycle) — les
  corriger n'est pas un enregistrement financier et ne présente pas de
  risque de litige.
- **Tables en ajout seul** (avec `HashChainColumns`) : `cotisations`,
  `prets`, `pret_confirmations`, `pret_remboursements`,
  `pret_annulations`, `amendes`, `fonds_solidarite_contributions`,
  `agent_assignments`, `agent_assignment_revocations`. Aucune méthode
  de `AppDatabase` ne fait d'UPDATE ou de DELETE sur ces tables —
  seulement des insertions. Une correction ou un changement d'état crée
  une nouvelle ligne qui référence l'ancienne (ex. un prêt se confirme
  via une ligne dans `pret_confirmations`, jamais en modifiant la ligne
  du prêt lui-même). Voir DECISIONS.md pour le raisonnement complet.
- Les tables financières susceptibles de recevoir de l'historique
  importé (`cotisations`, `prets`, `pret_remboursements`, `amendes`,
  `fonds_solidarite_contributions`) portent en plus `ProvenanceColumns`
  (`provenance`, `estApproximatif`).

`AppDatabase` (dans `database.dart`) expose directement des méthodes
métier (`enregistrerCotisationCash`, `confirmerPret`, etc.) plutôt que
des DAO génériques par table — plus direct à appeler depuis les
écrans, et chaque méthode peut appliquer la règle de hash chain sans
dupliquer cette logique dans la couche UI.

## Moteur de calcul (`lib/domain/calculators/`)

`EndOfCycleCalculator` ne connaît ni drift, ni Riverpod, ni Flutter —
il prend des données déjà agrégées (`EndOfCycleInput`) et applique la
formule du skill `avec-business-rules`. C'est volontaire : c'est la
seule pièce du projet qui a vraiment besoin d'être testée à la manière
d'une bibliothèque pure, indépendamment du stockage ou de
l'interface — voir `test/domain/calculators/`.

## Authentification (`lib/data/auth/`)

`AuthGateway` est une interface avec une seule méthode
(`envoyerCode`). `DevAuthGateway` renvoie un code de test fixe sans
réseau. En production, une implémentation `SupabaseAuthGateway`
s'appuierait sur l'authentification téléphone de Supabase Auth
(fournisseur SMS Twilio) — voir DECISIONS.md.

Cette étape n'implémente pas encore de session applicative complète
(pas de "connexion" persistée entre lancements de l'app) : l'écran
d'accueil demande simplement le numéro de téléphone de l'agent une
fois par lancement (`currentPhoneNumberProvider`), utilisé pour
tracer qui a enregistré quoi. La vraie authentification par code
OTP est utilisée précisément là où le skill `member-consent-rules`
l'exige : la confirmation d'un prêt par le membre concerné.

## Interface (`lib/features/`)

Un dossier par domaine fonctionnel (`groups`, `members`,
`cotisations`, `loans`, `cycle_summary`). Chaque écran recharge ses
données via `FutureBuilder` après une action plutôt que d'utiliser des
flux réactifs (`Stream`) — plus simple à suivre pour cette étape, à
revoir si la synchronisation multi-appareil (V1+) demande une UI
réactive en temps réel.

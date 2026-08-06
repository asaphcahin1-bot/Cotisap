# CotisApp

Application mobile pour la gestion des AVEC (Associations Villageoises
d'Épargne et de Crédit) en Côte d'Ivoire et dans les autres pays de la
zone UEMOA.

## État actuel

V0 — moteur hors-ligne uniquement (groupes, membres, cotisations cash,
prêts avec consentement, calcul de répartition de fin de cycle). Aucune
intégration de paiement à distance ni synchronisation Supabase pour le
moment — voir [ROADMAP.md](ROADMAP.md).

## Démarrer

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Après toute modification du schéma de base de données
(`lib/data/local/tables/`), relancer `build_runner build` pour
régénérer `lib/data/local/database.g.dart`.

## Structure

```
lib/
  core/                   formatage FCFA (skill localisation-fr-afrique-ouest)
  domain/calculators/     moteur de calcul pur (aucune dépendance DB), voir DECISIONS.md
  data/local/             base SQLite locale (drift) — source de vérité principale
  data/auth/              abstraction téléphone + code de confirmation (mode dev pour l'instant)
  state/                  providers Riverpod
  features/               écrans, un dossier par domaine fonctionnel
test/
  domain/calculators/     tests du moteur de calcul (scénario Kondoukro)
.claude/skills/           règles métier pour Claude Code — chargées automatiquement
```

## Documents à lire dans l'ordre

1. [ARCHITECTURE.md](ARCHITECTURE.md) — comment le projet est construit
2. [DECISIONS.md](DECISIONS.md) — pourquoi, avec les alternatives écartées
3. [ROADMAP.md](ROADMAP.md) — ce qui vient après cette étape
4. [TESTING.md](TESTING.md) — comment vérifier que ça marche
5. `.claude/skills/` — les règles métier AVEC que tout code doit respecter

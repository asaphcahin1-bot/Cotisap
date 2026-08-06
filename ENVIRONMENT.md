# Environnement — CotisApp

## Identifiants Supabase

L'app lit deux valeurs à la **compilation** (jamais codées en dur, jamais
commitées — voir CLAUDE.md) :

- `SUPABASE_URL` — l'URL du projet, ex. `https://xxxxxxxxxxxx.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY` — la clé publique du projet (Project Settings
  → API Keys → "Publishable key", commence par `sb_publishable_...`).
  Cette clé est conçue par Supabase pour être exposée côté client ; la
  vraie protection vient des règles RLS (`supabase/migrations/0001_init.sql`),
  pas du secret de cette clé.

**Ne jamais utiliser la "Secret key"** (`sb_secret_...`, équivalent de
l'ancienne `service_role`) dans l'app — elle contourne toutes les règles
RLS et ne doit exister que côté dashboard Supabase.

## Fichiers

- `env/env.example.json` — modèle committé, avec des valeurs factices
- `env/env.json` — vos vraies valeurs, **ignoré par git** (voir
  `.gitignore`). À créer une seule fois en copiant `env.example.json` et
  en remplaçant les deux valeurs par celles de votre projet Supabase
  (Project Settings → API Keys).

## Lancer l'app avec ces identifiants

```bash
flutter run --dart-define-from-file=env/env.json
```

Sans ce flag, l'app démarre quand même — `SupabaseConfig.isConfigured`
est faux, et rien n'appelle Supabase (skill `offline-first-flutter` : le
distant ne doit jamais être une dépendance bloquante). Utile pour tester
rapidement sans toucher au réseau.

## Nouveau projet Supabase (dev / prod séparés, si besoin plus tard)

1. Créer le nouveau projet dans le dashboard Supabase
2. Coller `supabase/migrations/0001_init.sql` dans son SQL Editor
3. Copier son URL + sa Publishable key dans un fichier séparé, ex.
   `env/env.prod.json`
4. `flutter run --dart-define-from-file=env/env.prod.json`

Pas fait pour l'instant — un seul projet (`cotisapp`) suffit tant que
l'app n'est pas en usage réel (voir ROADMAP.md).

---
name: offline-first-flutter
description: Architecture offline-first en Flutter avec SQLite local et synchronisation Supabase/PostgreSQL. À utiliser dès qu'un écran ou une fonctionnalité lit ou écrit des données, pour garantir qu'elle fonctionne sans connexion.
---

## Principe non négociable

Toute fonctionnalité de saisie ou de consultation doit fonctionner sans connexion internet. L'agent doit pouvoir saisir des cotisations pendant une réunion au village sans réseau. Si une fonctionnalité proposée nécessite une connexion active pour fonctionner, la reconcevoir avant de l'implémenter.

## Architecture à deux niveaux

- **Local** : SQLite via `sqflite` ou `drift` — source de vérité principale sur l'appareil, lecture et écriture toujours possibles hors-ligne
- **Distant** : PostgreSQL via Supabase — utilisé uniquement pour la synchronisation et le partage entre appareils (ex. plusieurs agents, ou agent + dashboard web), jamais comme dépendance bloquante pour une action locale

## Synchronisation

- Toute écriture locale doit être marquée comme "en attente de synchronisation" jusqu'à confirmation du serveur
- En cas de reconnexion, synchroniser dans l'ordre chronologique des écritures locales
- En cas de conflit (rare pour un usage mono-agent par groupe, mais possible), ne jamais écraser silencieusement — signaler le conflit et privilégier la donnée la plus récente par timestamp, avec trace de l'ancienne valeur conservée

## Contraintes de performance

- Garder l'app légère (viser quelques dizaines de Mo maximum) — le public cible a des forfaits data limités et chers
- Ne pas charger d'images ou de médias lourds par défaut
- Tester systématiquement chaque nouvelle fonctionnalité en mode avion avant de la considérer terminée

## Distribution

Prévoir que l'app soit installable aussi via un fichier APK partagé directement (hors Play Store), pour les zones à très faible accès au Play Store — ne pas coder de dépendance dure aux services Google Play si évitable pour les fonctions critiques (paiement, saisie, calcul).

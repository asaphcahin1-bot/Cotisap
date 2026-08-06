---
name: two-tier-access-model
description: Modèle de permissions à deux niveaux — agent avec accès complet, membre avec lecture seule limitée à ses propres données. À utiliser dès que le code touche à l'authentification, aux permissions, aux rôles utilisateur, ou à l'accès aux données d'un groupe ou d'un membre.
---

## Les deux rôles

- **Agent/gestionnaire** : accès complet à son ou ses groupes — saisie des cotisations cash, gestion des prêts, consultation et déclenchement des calculs de répartition
- **Membre** : accès en lecture seule, uniquement à ses propres données (ses parts, son solde, sa part estimée de fin de cycle, son historique de prêts) — jamais aux données des autres membres du groupe

## Règle de sécurité non négociable

Le filtrage des données d'un membre doit se faire au niveau de la base de données (règles de sécurité au niveau ligne / row-level security dans Supabase), jamais uniquement dans l'interface. Une simple restriction d'affichage côté client n'est pas suffisante — un membre ne doit techniquement pas pouvoir récupérer les données d'un autre membre même en modifiant une requête.

## Identification

- Chaque membre est identifié par son numéro de téléphone personnel + un code de confirmation envoyé par SMS
- Pas de mot de passe à retenir
- Un agent ne peut pas se connecter avec le compte d'un membre, et inversement
- Un membre sans aucun téléphone personnel (voir skill `member-consent-rules`) ne peut techniquement pas utiliser cet accès en lecture seule, faute d'identification possible — limite connue, pas un mur payant déguisé : la gratuité s'applique dès que l'identification par téléphone est possible.

## Ce qui reste gratuit vs payant

- L'accès en lecture seule pour les membres individuels doit toujours rester gratuit — ne jamais implémenter de mur payant sur cette fonctionnalité, c'est un pilier de confiance du produit
- Les fonctionnalités payantes (abonnement, frais de 5 % sur cotisation à distance) concernent l'agent/le groupe, jamais l'accès en lecture du membre individuel

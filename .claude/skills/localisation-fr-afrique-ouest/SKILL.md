---
name: localisation-fr-afrique-ouest
description: Conventions de langue, vocabulaire et format monétaire pour toute l'interface de CotisApp. À utiliser dès que le code touche à un texte affiché à l'utilisateur, un libellé, un message, ou un format de montant.
---

## Langue

Français uniquement pour l'interface, ton simple et direct. Le public cible n'est pas familier du jargon technique — éviter tout anglicisme évitable et tout terme "fintech" abstrait.

## Vocabulaire à privilégier

- "cotisation" (pas "dépôt")
- "carnet" (pas "part", ni "action" ni "share") pour l'unité de cotisation achetée par un membre (1 à 5 par réunion). C'est le terme que les groupes AVEC utilisent réellement sur le terrain. Le code garde `part`/`parts` comme identifiant technique interne (voir skill `avec-business-rules` et DECISIONS.md) — seul l'affichage change.
- "bénéfice individuel" (pas "part individuelle") pour la portion des intérêts/amendes revenant à un membre en fin de cycle — évite toute confusion avec "carnet" ci-dessus, qui désigne un tout autre concept.
- "groupe" ou "AVEC" pour désigner l'association (jamais présenter CotisApp comme affilié officiellement à la structure AVEC — voir la note de propriété intellectuelle ci-dessous)
- "agent" pour le gestionnaire du groupe
- "membre" pour les participants

## Format des montants

- Toujours en FCFA, jamais en symbole $ ou €
- Pas de décimales inutiles (le FCFA ne s'utilise pas avec des centimes en usage courant)
- Séparateur de milliers pour la lisibilité (ex. 25 000 FCFA, pas 25000)

## Note de propriété intellectuelle

Ne jamais faire apparaître de texte suggérant que CotisApp est une structure AVEC officielle ou un programme gouvernemental/ONG affilié. "AVEC" est un terme générique décrivant le type de groupe géré par l'app, jamais une marque ou un partenariat à revendiquer.

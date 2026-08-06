---
name: historical-data-import
description: Import et reprise d'historique pour les groupes AVEC déjà existants qui basculent vers CotisApp. À utiliser dès que le code touche à la création d'un nouveau groupe, à l'import de données, ou à la migration d'un historique papier/Excel.
---

## Contexte

La majorité des AVEC ciblées existent déjà depuis des années, avec un historique géré à la main (carnet, parfois Excel). Un groupe ne doit pas avoir l'impression de "repartir à zéro" en adoptant CotisApp.

## Formats d'import à supporter

- Saisie manuelle rétroactive par l'agent (cycles précédents : dates, membres, parts, prêts, remboursements)
- Import CSV/Excel avec un format simple : nom du membre, date, montant, type d'opération

## Distinction obligatoire dans le modèle de données

Chaque enregistrement doit porter un champ indiquant sa provenance : `importé` (saisi rétroactivement, non vérifié en temps réel au moment des faits) ou `direct` (créé et vérifié en temps réel via l'app). Ne jamais fusionner ces deux statuts dans un même champ — l'app doit toujours pouvoir distinguer les deux si besoin de litige ou d'audit.

## Validation à la bascule

Au moment de basculer un groupe existant vers l'app, générer un résumé de ce qui a été importé (nombre de membres, montant total cumulé) et exiger une confirmation explicite du comité de gestion avant de considérer l'historique comme le point de départ officiel dans l'app.

## Tolérance aux données incomplètes

Ne pas bloquer un import parce qu'une date est incertaine ou un montant approximatif. Prévoir des champs qui acceptent une valeur marquée comme approximative plutôt que de forcer une précision que le carnet papier d'origine n'avait pas.

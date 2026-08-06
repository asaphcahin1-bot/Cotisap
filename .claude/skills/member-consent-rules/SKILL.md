---
name: member-consent-rules
description: Règles de consentement et de traçabilité pour tout prêt ou engagement financier enregistré au nom d'un membre. À utiliser dès que le code crée, modifie, ou confirme un prêt, un engagement financier, ou toute action affectant le solde d'un membre autre que l'utilisateur connecté.
---

## Le problème à empêcher

Un membre absent ne doit jamais pouvoir se retrouver avec un prêt enregistré à son nom sans l'avoir lui-même confirmé. C'est un vrai litige courant dans les AVEC gérées à la main — CotisApp doit le rendre structurellement impossible, pas juste décourager la pratique.

## Règle centrale

Aucune action affectant le solde ou l'engagement financier d'un membre ne peut être enregistrée comme définitive sans une confirmation venant du numéro de téléphone personnel de ce membre exact. Personne d'autre — ni l'agent, ni un autre membre, ni un proche — ne peut confirmer à sa place par défaut.

## Flux de confirmation

1. Une demande de prêt (ou tout engagement) "au nom de" un membre est créée avec un statut `en_attente_confirmation`
2. Un SMS est envoyé immédiatement au numéro personnel du membre concerné, avec un code de confirmation
3. Le prêt ne passe au statut `confirmé` que si ce code est saisi par le membre lui-même
4. Tant que non confirmé, le prêt n'apparaît PAS dans les calculs de répartition ni dans le solde exigible du membre

## Cas des membres sans smartphone

Si un membre n'a pas de moyen de recevoir un SMS ou de confirmer numériquement, la confirmation doit passer par une validation en personne documentée (signature numérique capturée par l'agent, ou code PIN connu uniquement du membre concerné, jamais transmis à un tiers). Ne jamais permettre à l'agent de cocher "confirmé" sans une de ces preuves attachées à l'enregistrement.

**Implémenté** (voir DECISIONS.md) : mécanisme retenu = signature capturée à l'écran (pas de PIN — confidentialité fragile sur l'appareil partagé de l'agent). `PretConfirmations.methode` distingue `code` (SMS, le membre confirme lui-même) de `signature` (membre sans téléphone du tout, capturée en présence de l'agent témoin). La confirmation par signature est **refusée par la base** si le membre a un téléphone enregistré — jamais un raccourci pour éviter la confirmation SMS individuelle quand elle est possible.

## Notification et historique

- Le membre concerné reçoit une notification dès la création de la demande, pas seulement à la confirmation
- Chaque prêt garde un historique immuable : qui l'a initié, quand, comment il a été confirmé — jamais de modification rétroactive silencieuse d'un enregistrement déjà confirmé
- Ce historique doit être consultable par le membre lui-même à tout moment (voir le skill `two-tier-access-model`)

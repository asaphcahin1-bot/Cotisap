---
name: cotisapp-payment-flow
description: Flux de paiement à distance pour les membres absents/en déplacement, intégration agrégateur mobile money (PayDunya/DEXCHANGE), webhooks de confirmation. À utiliser dès que le code touche à un paiement, un webhook, une session de paiement, un décaissement, ou l'intégration Wave/PayDunya/DEXCHANGE.
---

## Périmètre confirmé (V1)

CotisApp ne collecte de l'argent réel via l'app QUE pour les cotisations des membres absents ou en déplacement, qui ne peuvent pas payer physiquement à la réunion. Ne jamais implémenter un flux qui ferait transiter la totalité de l'épargne d'un groupe par l'app — ce n'est pas le périmètre validé.

Les cotisations en cash, saisies manuellement par l'agent pendant la réunion, restent hors de ce flux (voir le skill `avec-business-rules` pour la distinction `source`).

## Frais

- Le membre absent paie 5 % de frais en plus de sa cotisation
- Le montant net (hors frais) est reversé à l'AVEC concernée
- Ne jamais faire absorber ce frais par le groupe — c'est le payeur individuel qui le supporte

## Choix technique : agrégateur multi-opérateurs

Ne pas intégrer l'API Wave directement seule. Utiliser un agrégateur (PayDunya ou DEXCHANGE) qui donne accès à Wave + Orange Money + MTN + Moov via une seule intégration — nécessaire car CotisApp vise plusieurs pays (CI, Bénin, Sénégal, Mali, Burkina) et une clé API Wave n'est pas portable d'un pays à l'autre.

## Flux technique

1. Le membre absent choisit son groupe et le nombre de parts à cotiser
2. Créer une session de paiement (invoice) via l'API de l'agrégateur, montant = cotisation + 5 %
3. Attacher en données personnalisées : `member_id`, `group_id`, `cycle_id`, `meeting_date`
4. Rediriger le membre vers l'URL de paiement retournée
5. Recevoir la confirmation via webhook — vérifier la signature avant tout traitement, ne jamais faire confiance à un callback non vérifié
6. À la confirmation : créer une ligne de cotisation avec `source = distance`, mettre à jour les parts du membre, déclencher le décaissement du montant net vers le compte de l'AVEC

## Contrainte de devise

L'agrégateur ne traite que le XOF. Toute logique de compte utilisateur doit assumer un numéro de téléphone identifié par un opérateur de la zone UEMOA — ne pas construire de logique qui suppose un numéro international générique.

## Décaissement vers l'AVEC

- Le compte de l'agrégateur est un portefeuille unique partagé entre tous les groupes gérés par CotisApp — l'agrégateur ne connaît pas la répartition entre groupes
- Le grand livre interne de CotisApp (base de données) est la seule source de vérité sur "quel argent appartient à quel groupe" — ne jamais s'appuyer sur le solde de l'agrégateur pour cette information
- Chaque décaissement vers une AVEC doit être lié dans la base à la ligne exacte de cotisation qu'il solde, pour rester traçable

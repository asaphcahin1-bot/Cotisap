---
name: avec-business-rules
description: Règles de calcul des cotisations, parts, prêts et répartition de fin de cycle pour les groupes AVEC (Associations Villageoises d'Épargne et de Crédit). À utiliser dès que le code touche au calcul financier d'un groupe, à la structure des parts, aux prêts, aux intérêts, au fonds de solidarité, ou au calcul de répartition de fin de cycle.
---

## Contexte

CotisApp gère des groupes AVEC — un modèle d'épargne communautaire répandu en Afrique de l'Ouest (Côte d'Ivoire, Bénin, Sénégal, Mali, Burkina Faso). Chaque calcul financier doit respecter exactement la mécanique traditionnelle du modèle, décrite ci-dessous — ne pas improviser une variante.

**Vocabulaire** : ce skill décrit la formule avec "part" comme terme technique (et le code garde ce nom en interne : `partsCount`, `partValueFcfa`, `MemberParts`...). Sur l'interface visible par l'agent et les membres, ce même concept s'affiche "carnet" — voir le skill `localisation-fr-afrique-ouest`. Ne jamais renommer la formule ci-dessous en "carnet" dans le code, seul l'affichage change.

## Structure d'un groupe

- 15 à 30 membres par groupe
- Comité de gestion à 5 rôles : Présidente, Secrétaire, Trésorière, 2 Compteuses
- Cycle de 9 à 12 mois, configurable par groupe
- Réunions hebdomadaires, bimensuelles ou mensuelles, configurable par groupe

## Système de parts

- Chaque membre **choisit son nombre de parts (1 à 5) une seule fois par
  cycle**, à son entrée dans le cycle — jamais un choix libre à chaque
  réunion. Ce choix devient **définitif dès son premier paiement
  enregistré sur ce cycle** (implémenté par `CarnetsEngages.lockedAt`).
- La valeur d'une part est fixée par le groupe en début de cycle (champ configurable, pas une constante)
- Le total de parts d'un membre = somme de toutes ses parts achetées sur le cycle en cours
- **Le montant de chaque paiement est imposé, jamais saisi librement** :
  `nombre de parts engagées × valeur de la part`. L'agent ne choisit pas
  un montant, l'app le calcule.
- **Les cotisations tombent à date calendaire fixe**, pas sur une
  période glissante : le groupe configure un jour de paiement précis à
  la création (`groups.paymentDayOfWeek` pour l'hebdomadaire ;
  `paymentDayOfMonth1` seul pour la mensuelle ; `paymentDayOfMonth1` +
  `paymentDayOfMonth2` pour la bimensuelle). Voir
  `EcheanceCalculator.echeancesPassees`. Si le groupe n'est pas créé
  précisément ce jour-là, la première échéance peut tomber quelques
  jours après la création — normal, pas un bug (voir DECISIONS.md,
  épisode du 2026-08-06). C'est justement pour ce cas (créer le groupe
  en avance d'une vraie première réunion) que les paramètres restent
  modifiables tant qu'aucune cotisation n'est encore enregistrée —
  voir `modifierGroupeEtCycle` / `EditGroupScreen`.
- **Un paiement manqué s'accumule sur le suivant**, il ne se remet
  jamais à zéro silencieusement. Le montant dû à un instant donné =
  `(nombre d'échéances passées × parts engagées × valeur de la part) −
  ce que le membre a déjà payé sur ce cycle` (voir
  `EcheanceCalculator.soldeDuFcfa`). Exemple : carnet à 500F, une
  semaine manquée -> le paiement suivant est de 1000F (500 dû + 500 de
  rattrapage), avant même l'amende de retard éventuelle (voir "Retard
  de cotisation" plus bas — les deux mécanismes sont indépendants et se
  cumulent).

## Prêts

- Un prêt est toujours facultatif pour le membre
- Taux d'intérêt fixé par le groupe (champ configurable par groupe, pas une constante globale)
- Un prêt ne peut être enregistré au nom d'un membre sans sa confirmation directe (voir le skill `member-consent-rules`)
- **Le prêt a une durée fixe** (`cycles.loanDurationDays`, configurée
  comme la valeur de la part et le taux). Le taux s'applique une
  première fois à l'emprunt ; **si la durée expire sans remboursement
  complet, le même taux se réapplique au solde restant pour une
  nouvelle période de même durée, et ainsi de suite** jusqu'au
  remboursement intégral — voir `LoanBalanceCalculator`. Un prêt importé
  sans durée connue n'est jamais recomposé (intérêt appliqué une seule
  fois), plutôt que de deviner une durée.
- L'écran des prêts affiche toujours : montant emprunté, montant dû
  actuellement (avec intérêt recomposé le cas échéant), et le temps
  restant avant la prochaine échéance de renouvellement.
- **Remboursement** : jamais possible de saisir plus que le montant
  réellement dû (validé côté formulaire contre `LoanBalanceCalculator`).
  Une fois le prêt intégralement soldé, l'action de remboursement
  disparaît de l'écran — plus rien à faire dessus.

## Fonds de solidarité

- Caisse séparée du calcul de répartition — jamais incluse dans le calcul de fin de cycle
- Alimentée par des contributions distinctes des parts de cotisation
- Ne jamais faire transiter ce fonds par la même colonne de données que les parts de cotisation

## Calcul de répartition de fin de cycle

Formule exacte à respecter :

1. `total_interets_amendes = somme(intérêts perçus sur tous les prêts du cycle) + somme(amendes collectées sur le cycle)`
2. `valeur_par_part = total_interets_amendes / total_parts_du_groupe`
3. `part_individuelle_membre = valeur_par_part * nombre_de_parts_du_membre`
4. Le montant total reçu par chaque membre en fin de cycle = sa cotisation totale (parts × valeur de la part) + sa `part_individuelle_membre`

Ne jamais diviser à parts égales entre membres — toujours au prorata des parts individuelles.

## Distinction cash vs à distance

Chaque ligne de cotisation doit porter un champ `source` avec deux valeurs possibles uniquement : `cash` (saisie manuelle par l'agent en réunion) ou `distance` (payée via l'app, voir le skill `cotisapp-payment-flow`). Le calcul de répartition doit inclure les deux sources sans distinction de traitement — seule l'origine est tracée, pas le poids dans le calcul.

## Retard de cotisation

- Les cotisations se font à date fixe (selon la fréquence des réunions du
  groupe : hebdomadaire, bimensuelle, mensuelle). Un membre qui ne
  cotise pas à cette date est en retard pour la période en cours.
- Le montant de l'amende de retard est fixé par le groupe à la création
  du cycle (champ configurable par cycle, comme la valeur du carnet et
  le taux d'intérêt) — 0 si le groupe ne veut pas d'amende automatique.
- **Jamais d'amende pour l'échéance en cours** : une échéance qui vient
  de s'ouvrir (y compris le tout premier jour du cycle) ne peut jamais
  déclencher d'amende — seules les échéances déjà closes comptent.
- **Application automatique, mais différée d'une échéance** : à
  l'ouverture de l'écran Cotisations, l'app détecte automatiquement
  (`AmendeAutoService`) toute échéance close non couverte par un membre
  actif et lui applique l'amende configurée — sans tap manuel par
  membre. Concrètement : un membre absent à l'échéance N ne voit rien se
  passer à l'échéance N (skill non violée : l'agent n'a encore rien à
  décider) ; c'est à l'échéance N+1 que l'amende de l'échéance N
  apparaît, déjà posée.
- **L'agent reste décisionnaire malgré l'automatisation** : chaque
  amende auto-générée est présentée à la séance suivante avec deux
  choix explicites — "Confirmer l'absence" (rien ne change) ou "Erreur
  — il avait payé" (annule l'amende et enregistre sa cotisation
  manquante, à la vraie date). Jamais de suppression ni modification
  directe de la ligne d'origine — toujours une nouvelle ligne
  d'annulation qui la référence (voir `AmendeAnnulations`).
- Idempotent par construction : une échéance manquée ne peut jamais être
  sanctionnée deux fois, même si la détection tourne plusieurs fois.
- Si un membre rate plusieurs échéances d'affilée, une amende par
  échéance manquée non encore comptée — s'additionne comme le rattrapage
  de carnet.

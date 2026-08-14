# Retours terrain — en attente de confirmation

Ce document rassemble les retours d'agents/présidents AVEC ayant testé
l'app, au fur et à mesure qu'ils arrivent. **Rien ici n'est validé ni
codé** — c'est une zone de brouillon, pas une décision. Une fois qu'un
point est confirmé par le fondateur (éventuellement après plusieurs
retours qui se recoupent), il est retiré d'ici et déplacé dans
DECISIONS.md (règle tranchée) et/ou ROADMAP.md (à coder). Ce document
est amené à changer souvent — dernière mise à jour : 2026-08-11.

**Un point est marqué "Décidé" quand le fondateur a tranché le
principe** — même si des détails de conception restent encore ouverts
avant de pouvoir coder (indiqués sous chaque point concerné). Rien
n'est codé tant qu'un point porte encore une question ouverte.

## Question technique résolue (2026-08-11), découverte en construisant le Groupe A

**Deux champs représentaient la même idée sans être unifiés** :
`Cycles.lateFeeFcfa` (l'amende de retard automatique, configurable à
chaque cycle — mécanisme préexistant) et le motif système "Absence" de
`MotifsAmende` (montant fixé une fois à la création du groupe, voir
"Motifs d'amende prédéfinis"). **Résolu** dans le cadre de la clôture
de journée interactive (voir DECISIONS.md, "Clôture de journée
interactive") : `lateFeeFcfa` reste prioritaire quand configuré
(> 0, réglage historique modifiable cycle par cycle), sinon le montant
du catalogue de motifs s'applique. Choix technique, pas une nouvelle
question à trancher par le fondateur — préserve tout le comportement
existant.

**Renversé (2026-08-11), après le premier test terrain** — voir point
20 ci-dessous : le fondateur signale sur le terrain que ces deux champs
restent confus pour l'agent malgré la règle de priorité ci-dessus (deux
champs visibles à l'écran pour une seule idée). `lateFeeFcfa` retiré
des écrans Création/Édition groupe et de la résolution du motif à la
clôture — "Amende Absence" du catalogue est désormais la seule source.
La colonne reste en base (migration, jamais supprimée), ne sert plus
que de dernier recours pour un groupe migré sans catalogue (avant
schemaVersion 14).

## 1. Écran membre consolidé pendant la réunion (retour terrain #2)

**Constat** : en réunion, l'agent traite un membre à la fois —
cotisation, amende, solidarité — jamais une catégorie à la fois sur des
écrans séparés. Aujourd'hui, sélectionner un membre pour sa cotisation
n'affiche pas ses amendes en attente ni une action de solidarité au
même endroit.

**Demande** : qu'un seul écran/flux par membre regroupe les trois
actions (cotisation cash, règlement d'amende, contribution solidarité)
quand on clique sur son nom.

**Statut** : le plus mûr et le plus concret des retours reçus — pas de
nouvelle règle métier, une réorganisation d'écran. Recommandé comme
premier chantier une fois les retours stabilisés.

**Livré (2026-08-11)** : `MemberSessionScreen` — cotisation, amendes
non soldées et prêts en cours du membre, en un seul écran (voir
DECISIONS.md, "Écran membre consolidé"). La contribution solidarité
manque encore : elle rejoindra cet écran avec le Groupe B (fonds de
solidarité obligatoire, pas encore construit).

**Retour du premier test terrain (2026-08-11)** : le fondateur ne
retrouvait pas cette idée en testant l'écran Cotisations — parce que
`MemberSessionScreen` n'est accessible que depuis l'onglet Membres, pas
depuis Cotisations, et ne couvre ni la présence ni la demande de
crédit. Voir point 20 : nouvel écran "Séance du jour", dédié à la
réunion, accessible directement depuis Cotisations, avec les 4 gestes
(cotisation, présence, crédit, amende) — complète `MemberSessionScreen`
sans le remplacer.

## 2. Amende d'absence : par carnet ou par membre ?

**Décidé (2026-08-10)** : par carnet. Un membre à 2 carnets absent
reçoit 2 amendes distinctes (ex. amende à 200 F → 400 F au total).
**Annule la décision du 9 août** ("absence = événement par personne,
pas par carnet", `echeances_ledger_test.dart`) — ce test devra être
réécrit avec la nouvelle règle.

## 3. Un deuxième motif d'amende : absent mais payé par un tiers

**Retour terrain #1** : si un membre absent fait porter son paiement
par quelqu'un d'autre, il reçoit une amende différente (a priori plus
légère) de l'amende d'absence complète.

**Statut** : probablement déjà réalisable sans nouveau code — le
catalogue de motifs d'amende (Phase 4) permet de créer un motif dédié
que l'agent applique manuellement dans ce cas précis, au lieu de
laisser l'amende automatique d'absence se déclencher.

## 4. Règlement d'une amende "à tout moment"

**Décidé (2026-08-10)** : on abandonne le "choix définitif" codé plus
tôt dans la même session — un paiement cash doit rester possible à tout
moment, quel qu'ait été le choix initial ("cash" ou "plus tard").

**Précisé (2026-08-10)** : on garde la question immédiate "cash
aujourd'hui ou plus tard ?", mais "plus tard" n'a plus rien
d'irréversible — ça enregistre l'amende dans un "compte amende" du
membre, réglable en partie ou en totalité à tout moment.

**Implication technique nouvelle** : le **paiement partiel** d'une
amende n'existe pas aujourd'hui (aujourd'hui : soldée ou non soldée,
tout ou rien). Probablement à modéliser sur le même principe que les
remboursements de prêt (`PretRemboursements` — plusieurs paiements
partiels contre une même dette), plutôt qu'un simple booléen
`confirmedAt`.

## 5. Section "Amendes" dédiée

**Retour terrain #1** : idée d'un écran centralisant toutes les
amendes, plutôt que dispersées entre Cotisations et Répartition.
Suggestion d'interface, pas une règle métier — faisable, à designer
plus tard si retenue.

**Livré (2026-08-11)** : `AmendesScreen` — voir DECISIONS.md, "Section
Amendes dédiée".

## 6. Fonds de solidarité : obligatoire, avec logique d'arriéré propre

**Décidé sur le principe (2026-08-10)** : montant dû à chaque réunion,
souple dans le rythme (payer plusieurs mois d'avance, ou accumuler du
retard), mais tout doit être soldé avant le partage de fin de cycle.

**Aujourd'hui** : le fonds de solidarité est une caisse totalement
libre (montant libre, à tout moment, jamais suivi comme une
obligation) — `enregistrerContributionFondsSolidarite`, aucun solde dû
calculé.

**Précisé (2026-08-10)** : montant fixe **par carnet** (pas par part),
défini une fois à la création du groupe — un membre à 2 carnets paie le
double. Le "fonds de solidarité" regroupe désormais deux composantes
suivies ensemble : la cotisation obligatoire par réunion (ce point) et
les cotisations exceptionnelles ponctuelles (point 7) — même solde,
même suivi d'arriéré.

Implique de toute façon : suivre un solde dû cumulé par membre
(mécanisme d'arriéré qu'on a justement supprimé pour les cotisations le
9 août) et une nouvelle condition de clôture (en plus de "tous les
membres confirmés payés" déjà codé). Chantier réel, pas un ajustement
mineur.

**Livré (2026-08-11)** : la partie "cotisation obligatoire récurrente"
— voir DECISIONS.md, "Fonds de solidarité obligatoire". Les
cotisations exceptionnelles (point 7), qui partageront le même
solde/suivi, restent à construire.

## 7. Cotisations exceptionnelles pour événements de vie

**Décidé sur le principe (2026-08-10)** : mariage, décès, accouchement
→ cotisation ponctuelle obligatoire liée au fonds de solidarité.

**Précisé (2026-08-10), déroulé complet donné par le fondateur** :
- Un événement (mariage, décès, accouchement) déclenche l'enregistrement
  d'une cotisation exceptionnelle par l'agent, une seule fois — montant
  + date limite de paiement (comptée à partir du jour d'enregistrement).
- Elle s'applique **automatiquement à tous les membres du groupe** (une
  solidarité collective envers la personne concernée par l'événement,
  pas un paiement de sa part à elle).
- À chaque réunion, en cliquant sur un membre (rejoint le point 1) :
  l'agent peut traiter en même temps sa cotisation hebdomadaire, ses
  amendes (partielles ou totales), son prêt (partiel ou total), et
  cette cotisation exceptionnelle (payer maintenant ou patienter).
- **Si la date limite arrive sans paiement**, elle est automatiquement
  déduite des parts du membre concerné.

**Ça résout l'inquiétude technique précédente** : la déduction ne se
fait pas "à n'importe quel moment imprévisible", mais à une **date
limite précise, connue à l'avance, propre à chaque cotisation
exceptionnelle** — un mécanisme proche de la clôture de cycle (même
principe de déduction de parts) mais avec son propre déclencheur.
Beaucoup plus faisable que ce qu'on craignait au départ.

**Livré (2026-08-11)** : voir DECISIONS.md, "Cotisations
exceptionnelles". Avec ce point, le Groupe B est terminé.

## 8. Dette de prêt "au rouge" après 3 mois

**Décidé sur le principe (2026-08-10)** : s'applique à **tous les
groupes**, pas une option par groupe. Un prêt impayé après sa période
(3 mois) passe "au rouge" et perd 10 % du solde restant **à chaque fin
de mois** — rythme mensuel, différent de la recomposition actuelle qui
se fait à chaque échéance de ~90 jours. Possibilité de "sortir du
rouge" en payant les intérêts + une amende, ce qui reconduit le crédit
pour 3 nouveaux mois.

**Précisé (2026-08-10), avec exemple chiffré** : 100 000 F dû → 110 000
F à la fin du mois suivant (100 000 + 10 %) → toujours impayé → 121 000
F le mois d'après (110 000 + 10 %), et ainsi de suite. **Composition
mensuelle continue une fois "au rouge"** — le même principe que la
recomposition existante tous les 90 jours, simplement à un rythme
mensuel après le premier délai dépassé (résout la question "s'ajoute ou
remplace" : ça remplace, au même taux, cadence différente).

**Précisé (2026-08-10)** : le montant de "l'amende" de reconduction sera
défini à la création du groupe (comme la valeur du carnet, le taux
d'intérêt, l'amende de retard) — plus de question ouverte sur ce point.

**Livré (2026-08-11)** : voir DECISIONS.md, "Dette de prêt au rouge".
Une précision par rapport à la formulation initiale ("après 3 mois") :
le déclencheur est en réalité la fin de la **période normale du prêt**
(sa propre durée, `dureeJours` — 3 mois est la valeur par défaut, mais
un cycle peut en configurer une autre), pas une durée fixe universelle
de 3 mois. Une fois au rouge, le taux (10 %/mois) et la cadence
(calendaire) sont, eux, bien universels. La sortie du rouge (intérêts +
amende fixe du groupe) et la reconduction sont livrées côté prêt du
même cycle ; la reconduction **au cycle suivant** (point 19) réutilisera
le même mécanisme mais n'est pas encore construite.

**Précisé (2026-08-11), après une revue du comportement** : la sortie
du rouge n'exige pas de payer exactement les intérêts + l'amende — le
membre paie **le montant de son choix** ce jour-là. Exemple donné par
le fondateur : prêt de 100 000 F, à la 4ᵉ réunion le membre peut payer
10 000 F (intérêts) + l'amende et reconduire les 100 000 F ; ou payer
60 000 F, dont 10 000 F + l'amende couvrent la sortie et le reste
réduit directement le principal reconduit (40 000 F environ) ; ou ne
rien payer pour les 10 000 F + l'amende, auquel cas ils s'ajoutent au
principal reconduit. **L'amende n'a jamais de trace séparée** dans
l'app — si elle n'est pas payée, elle est absorbée dans le nouveau
prêt. Le prêt reconduit est aussi désormais résolu **au taux d'un prêt
neuf** (dans/hors carnet, plafond 3x, fenêtre des 3 derniers mois),
jamais le taux plat du cycle — confirmé, même exemple chiffré : un
solde reconduit dans les 3 derniers mois du cycle bascule "hors
carnet" (15 %), comme n'importe quel nouveau prêt.

**Confirmé (2026-08-11)** : le passage au rouge est automatique
(calculé, aucune action requise) ; la reconduction (sortie du rouge ou
report au cycle suivant), elle, reste toujours une action manuelle du
gérant — jamais silencieuse — car l'AVEC peut la refuser.

**Précisé et livré (2026-08-11)** : si un prêt non soldé n'est jamais
reconduit (ni sorti du rouge dans le cycle, ni reporté au cycle
suivant à la clôture), sa dette doit être considérée comme **perdue**
à la clôture du cycle — la composition au rouge ne continue donc plus
indéfiniment après coup, elle se gèle au solde exact de l'instant de
la clôture. Voir DECISIONS.md pour le détail (`AppDatabase.soldePret`).
Reste ouvert : cette perte n'est pas encore affichée explicitement
quelque part — le prêt reste juste gelé, visible normalement.

## 9. Cycles de 6 mois

**Retour terrain #1** : certains AVEC ont des cycles de 6 mois.

**Statut** : déjà supporté — `cycleDurationMonths` est configurable par
groupe depuis le début. Rien à faire.

## 10. Crédits une fois par mois (4e semaine), remboursements à tout moment

**Livré (2026-08-11)** : `LoanWindowCalculator` — voir DECISIONS.md,
"Fenêtres de crédit selon la fréquence de réunion".


**Précisé (2026-08-10), par fréquence de réunion** :
- **Hebdomadaire** : prêts disponibles à partir de la 4e semaine, puis
  **toutes les 4 semaines** (récurrent, pas une seule fois).
- **Bimensuelle** : prêts disponibles à partir de la 2e réunion, puis
  **chaque 2e réunion** (récurrent).
- **Mensuelle** : reste à clarifier — voir ci-dessous.

Remboursements toujours libres à tout moment, quelle que soit la
fréquence.

**Résolu (2026-08-10)** : **Mensuelle** suit le même principe que
bimensuelle — prêts à partir de la 2e réunion, puis chaque 2e réunion.
Plus de question ouverte sur ce point.

## 11. Ordre réel d'une réunion

**Retour terrain #2** : informations/annonces d'abord (événements,
mariage, décès, questions), puis les épargnes (cotisations), puis les
crédits si 4e semaine du mois. Surtout un fait de terrain utile pour le
contexte — pas forcément quelque chose que l'app doit imposer ou
structurer numériquement.

## 12. Gestion de la monnaie / de l'appoint

**Retour terrain #2** : un membre qui donne un billet plus gros que son
dû ne reçoit pas sa monnaie immédiatement — l'agent finit toute la
collecte, calcule les totaux (épargne, solidarité, amendes), puis rend
la monnaie restante à la fin, par numéro de carnet.

**Recommandation proposée (2026-08-10), en attente de confirmation** :
ne rien construire dans l'app. L'app n'a jamais eu besoin de savoir
combien de cash physique un membre a réellement tendu — elle calcule
uniquement le montant dû (parts × valeur), jamais un montant "reçu".
Le rendu de monnaie reste une opération physique entre l'agent et le
membre, hors app, sans perte d'exactitude côté enregistrement.

## 13. Rationnement des crédits selon l'argent disponible en caisse

**Décidé sur le principe (2026-08-10)** : le plafond de 3× l'épargne
(déjà codé) n'est qu'une première limite — la vraie limite du jour,
c'est l'argent physiquement présent dans la caisse. Si la demande
totale dépasse ce qui est disponible, le groupe propose une réduction
proportionnelle à tous les demandeurs ; chacun accepte (prend moins) ou
se désiste.

**Confirmé (2026-08-10)** : "l'argent en caisse" = uniquement ce que
l'agent a effectivement enregistré dans l'app (cotisations, amendes
réglées, etc.) — jamais une estimation ou une saisie séparée. Calculé
automatiquement à partir des données déjà enregistrées, pas une
nouvelle saisie manuelle. Le changement le plus substantiel de tous les
retours reçus jusqu'ici — reste à concevoir la formule exacte (quels
encaissements/décaissements entrent dans le calcul) et le mécanisme de
proposition/désistement.

**Livré (partiel, 2026-08-11)** : la formule (`AppDatabase.caisseDisponibleActuelleFcfa`,
voir DECISIONS.md, "Rationnement des crédits selon la caisse
disponible") et le plafond dur — un prêt ne peut jamais dépasser la
caisse au moment de la demande, vérifié dans `enregistrerPret`.
**Reste ouvert** : le mécanisme "demande totale > caisse disponible →
réduction proportionnelle proposée à tous les demandeurs simultanés,
chacun accepte ou se désiste" — pas construit, l'app traite
aujourd'hui chaque demande de prêt une à la fois (premier arrivé,
plafond déjà réduit pour le suivant), pas de négociation collective.

**Livré (2026-08-11)** : voir DECISIONS.md, "Rationnement collectif
des crédits" — le mécanisme manquant ci-dessus est maintenant
construit. Deux chemins distincts, jamais un seul imposé : "Nouveau
prêt" reste inchangé pour le cas simple (un seul demandeur) ; "Demander
un prêt" + "Traiter les demandes en attente" pour le cas collectif —
dépose une demande sans vérifier la caisse tout de suite, puis
propose, un demandeur à la fois (ordre FIFO), un montant proportionnel
au prorata du total encore demandé si la caisse ne suffit pas pour
tous. **Redistribution immédiate**, précisée par le fondateur : après
chaque décision (accepter ou se désister), la part proposée aux
suivants est recalculée avec la caisse et le total restants — jamais
figée une fois pour tout le lot.

## 14. Gouvernance à plusieurs personnes (caisse à trois clés)

**Contexte** : certains AVEC gèrent la caisse physique avec plusieurs
clés (ex. trois) détenues par des personnes différentes — aucune ne
peut agir seule sur l'argent réel.

**Décidé (2026-08-10)**, différent de la proposition initiale : un
modèle à droits asymétriques et modifiables, pas plusieurs agents à
égalité —
- le président (ou la présidente) a toujours l'accès en écriture complet ;
- les deux autres démarrent en lecture seule ;
- le président peut, à tout moment, faire basculer l'un des deux en
  écriture, puis le repasser en lecture seule, autant de fois que
  nécessaire.

**Précisé (2026-08-10)** : en mode écriture, le trésorier/secrétaire
voient et font **exactement** comme le président, sauf gérer les droits
d'accès (accorder/retirer lecture ou écriture) — ça reste exclusif au
président, y compris qu'ils ne peuvent jamais retirer ce droit au
président lui-même.

**Précisé (2026-08-10)** : en mode lecture seule (leur état par défaut)
aussi, ils voient tout le groupe comme le président — jamais limités
aux données d'un membre classique. Plus de question ouverte sur ce
point.

**Dépendance importante, à signaler clairement** : une bascule de
droits entre personnes précises n'a de sens en sécurité que si l'app
sait avec certitude qui se connecte. Aujourd'hui, n'importe quel numéro
tapé obtient l'accès complet, sans vérification — cette fonctionnalité
ne peut pas être construite de façon fiable avant l'authentification
réelle (Twilio, voir ROADMAP.md).

## 15. Numéro de série physique par carnet

**Décidé (2026-08-10)** : un carnet devient une vraie entité
identifiable, avec son propre numéro de série unique **par groupe**
(jamais réutilisé), format **C-001, C-002, C-003...** — volontairement
différent de `carnetNumero` (1 ou 2, position du carnet chez son
membre) pour ne jamais confondre les deux dans l'interface.

**Génération** : l'app propose automatiquement le prochain numéro
disponible dans la séquence du groupe à la création de chaque carnet
d'un membre ; l'agent peut le remplacer manuellement si le membre a
déjà un vrai carnet physique numéroté.

**Implication technique** : un carnet doit devenir une vraie table
(`Carnets`, avec son propre id), pas seulement la paire (memberId,
carnetNumero) comme aujourd'hui — changement de fondation, à faire
avant le reste du Groupe A (cotisations, échéances, amendes devront
s'y rattacher).

## 16. Inscription de nouveaux membres : sans limite, sauf fin de cycle

**Décidé (2026-08-10)** : annule la règle actuelle ("inscriptions
fermées dès la première journée clôturée", confirmée le 9 août puis à
nouveau plus tôt dans cette même session). Un membre peut désormais
rejoindre **à n'importe quel moment du cycle**, sauf dans les **2
dernières réunions avant la fin prévue du cycle** — fermeture
automatique à partir de ce seuil.

**Pas de nouveau calcul nécessaire** : la règle "un membre ajouté en
cours de cycle ne doit rien avant son entrée" gère déjà correctement
la proportionnalité de sa part au partage. Implique de calculer combien
de réunions il reste avant la fin prévue du cycle (durée du cycle +
fréquence des réunions du groupe) pour savoir quand fermer
`ajouterMembre`.

**Livré (2026-08-11)** : voir DECISIONS.md, "Inscription de nouveaux
membres : sans limite, sauf fin de cycle" — écart trouvé en inspectant
le reste du Groupe C : cette décision du 2026-08-10 n'avait jamais été
implémentée, le code appliquait encore l'ancienne règle. Corrigé.

## 17. Valeur de la part : confirmée fixe pour tout le cycle

**Clarifié (2026-08-10)** après une fausse alerte : un nouveau membre
paie **exactement le même montant par part que tout le monde**, celui
fixé pour le cycle en cours — aucun changement au calculateur de fin de
cycle. Le fondateur note lui-même une iniquité de fond (un membre
arrivé tard profite du même bénéfice par part qu'un membre présent
depuis le début) mais choisit délibérément de ne pas la corriger,
puisque les AVEC réels ne le font pas non plus (retour terrain) —
aucune action à prévoir.

## 18. Fonds de solidarité : jamais dans la caisse, jamais redistribué automatiquement

**Confirmé (2026-08-10)** : même une fois obligatoire (point 6), le
fonds de solidarité reste **totalement exclu** du calcul de la caisse
disponible et **n'est jamais redistribué** aux membres au partage —
déjà le comportement actuel (`totalFondsSolidarite` jamais lu par
`EndOfCycleCalculator`), à préserver explicitement en construisant le
point 6.

**S'il reste un solde à la clôture d'un cycle** : par défaut, il
continue simplement d'exister pour le cycle suivant (déjà le
comportement actuel — rien ne le remet à zéro, aucun code
supplémentaire nécessaire). Si le comité décide de le répartir
autrement, formule retenue : **également entre tous les carnets du
groupe**, sans pondération par les parts, sans tenir compte des dettes
de prêt (contrairement à la formule de la caisse principale).

## 19. Reconduction d'un prêt non soldé au cycle suivant

**Décidé (2026-08-10)** : un prêt confirmé non soldé à la clôture peut
être reconduit dans le nouveau cycle — **jamais automatique**, exige
que le membre soit toujours présent dans le groupe et donne son accord
explicite (cohérent avec le principe déjà appliqué à tout prêt —
confirmation du membre obligatoire).

**Précisé** : le prêt reconduit repart avec le **taux d'intérêt du
nouveau cycle**. Un prêt reconduit au nouveau cycle **est**, par
définition, un prêt "au rouge" dès son entrée dans le nouveau cycle
(pas de nouvelle période de grâce) — le principe des 10 %/mois (point
8) s'applique dessus automatiquement. C'est le **même mécanisme** "au
rouge" que le point 8, avec le passage de cycle comme un des
déclencheurs possibles (en plus de l'expiration normale d'une période
de 3 mois), pas un système séparé.

**Livré (2026-08-11)** : voir DECISIONS.md, "Reconduction d'un prêt
non soldé au cycle suivant". Proposée un prêt à la fois, à l'écran de
clôture, juste après l'ouverture du nouveau cycle — jamais automatique,
toujours avec l'accord explicite du membre, et le nouveau prêt exige sa
propre confirmation (code SMS ou signature). Reste ouvert : pas de
mécanisme pour reconduire plus tard un prêt si l'occasion est manquée
à la clôture elle-même (voir DECISIONS.md pour le détail). **Avec ce
point, le Groupe C est terminé.**

**Corrigé (2026-08-11), après une revue du comportement** : "le taux
d'intérêt du nouveau cycle" ci-dessus était trop littéral — le prêt
reconduit est en réalité résolu **comme un prêt neuf** (dans/hors
carnet, plafond 3x, fenêtre des 3 derniers mois, voir
`LoanRateResolver`), jamais directement le taux plat configuré sur le
cycle. Confirmé volontaire même si ça pousse presque toujours vers
"hors carnet" en tout début de nouveau cycle (cotisation encore à 0).
Contrairement à la sortie du rouge dans le même cycle (point 8), la
reconduction au cycle suivant reste **automatique dans son calcul** —
pas de paiement partiel négociable ce jour-là, seul le montant exact
dû est reconduit.

## 20. Premier test terrain (APK release) — retours du fondateur

**Six points remontés (2026-08-11)** après le premier essai de l'APK
release sur un vrai téléphone — voir CHANGELOG.md pour le détail
technique de chaque correction.

**20.1 — Nom du groupe obligatoire.** Déjà le cas (`create_group_screen.dart`
avait déjà un validateur) — rien à corriger, juste vérifié.

**20.2 — Tous les champs de création de groupe obligatoires.** Clarifié
avec le fondateur : les validateurs existaient déjà pour tous les
champs (aucun ne peut rester vide ou non-numérique) et **0 reste une
valeur valide si tapée volontairement** — cohérent avec les décisions
déjà prises sur les montants optionnels (amende "part impayée", "payé
par un tiers", solidarité). Rien à changer côté règles.

**20.3 — Champ oublié pas assez visible.** Le vrai problème : sur un
long formulaire, `Form.validate()` souligne bien le champ en rouge mais
il peut rester hors écran, donnant l'impression que rien ne s'est
passé. **Livré** : `_scrollToFirstError()` dans
`create_group_screen.dart` et `edit_group_screen.dart` — fait défiler
jusqu'au premier champ invalide et affiche un message, à l'échec de la
validation.

**20.4 — "Amende de retard de cotisation" doublonne "Amende Absence".**
Confirmé par le fondateur : supprimer le champ, "Amende Absence" du
catalogue devient la seule source. **Livré** — voir la mise à jour de
"Question technique résolue" plus haut dans ce document.

**20.5 — Impossible de simuler une date dans l'APK de test terrain.**
`AppClock.definir` et le bouton 🧪 étaient verrouillés sur `kDebugMode`
uniquement, donc invisibles dans n'importe quel APK release, y compris
celui destiné au test terrain du fondateur. **Livré** :
`AppClock.simulationAutorisee` (= `kDebugMode ||
bool.fromEnvironment('FIELD_TEST_BUILD')`) — un APK de test terrain se
compile désormais avec `flutter build apk --release
--dart-define=FIELD_TEST_BUILD=true`, un APK public normal garde
`flutter build apk --release` sans ce define et reste verrouillé.

**20.6 — Écran Cotisations sans fiche consolidée par membre.** Le
fondateur attendait, en cliquant sur un membre depuis Cotisations, de
pouvoir enregistrer en un seul geste paiement/présence/crédit/amende —
`MemberSessionScreen` (point 1) existait déjà mais seulement depuis
l'onglet Membres, sans présence ni demande de crédit. **Livré** :
nouvel écran `SeanceJourScreen` ("Séance du jour"), accessible
directement depuis Cotisations pendant une journée ouverte — liste des
membres, tap → cotisation, présence (bouton Présent/Absent, motif
personnalisable), demande de crédit, amende, tous les quatre au même
endroit. La présence marquée ici est une **intention** (nouvelle table
`PresenceAnticipee`, config non hash-chaînée), relue par
`cloturerJourneeCotisation` comme valeur par défaut à la vraie clôture
— jamais définitive avant ce moment-là, l'agent garde la main pour
corriger. `MemberSessionScreen` n'est pas remplacé, reste utile hors
réunion (ex. un membre qui passe régler une amende ou un prêt en
dehors d'une journée de cotisation).

**Revu (2026-08-11), même jour** — voir points 21.1/21.2 puis 22.2 :
"Séance du jour" redevient un écran de lecture seule, les gestes
déménagent sur le nouvel écran "Cotisation"
(`cotisation_membre_screen.dart`), et le bouton Présent/Absent
disparaît à son tour au profit d'"Ajouter amende".

## 21. Reprise du test terrain — retours du même jour (2026-08-11)

Le fondateur a testé l'APK du point 20, puis est revenu avec des
retours plus précis avant de reprendre le test — recap validé
("vas y") avant implémentation.

**21.1 — "Séance du jour" doit être en lecture seule.** Toutes les
autres actions se retrouvent déjà ailleurs — pas besoin qu'elles soient
dupliquées ici aussi. **Livré** : voir "Écran membre consolidé"
ci-dessus, la révision du 2026-08-11.

**21.2 — Refonte de l'écran "Cotisation" par membre selon un croquis
du fondateur.** Sélection du membre, ses carnets et le total en tête,
puis une rangée de boutons pour toutes les autres actions (amende,
cotisation exceptionnelle, fonds de solidarité, prêt), et un bouton
pour enchaîner directement sur le membre suivant sans ressortir de
l'écran. **Livré** : nouvel écran `CotisationMembreScreen`, remplace
l'ancien flux "Ajouter un encaissement" + brouillon multi-membres de
l'écran Cotisations.

**21.3 — Totaux amendes/intérêts sur l'écran Répartition.** Le
fondateur voulait voir, en plus de la caisse disponible, le total
généré par les amendes et par les intérêts de prêt sur le cycle.
**Livré** — les deux totaux existaient déjà en base
(`totalAmendesRegleesDuCycle`, `totalInteretsPercusDuCycle`), juste pas
affichés.

**21.4 — Le dialogue "Mode de paiement de l'amende" contredisait une
décision déjà prise.** Le texte affichait encore "ce choix est
définitif — plus tard = déduite à la clôture", reste de la règle
d'origine (voir "Mode de paiement de l'amende demandé immédiatement",
2026-08-09) que le point 4 de ce document a explicitement abandonnée le
2026-08-10 ("Une amende ne se règle plus jamais automatiquement" —
paiement possible à tout moment). Le comportement réel était déjà
correct, seul le texte du dialogue était resté figé sur l'ancienne
règle. **Livré** : texte corrigé.

**21.5 — Clôture automatique après 23h.** Le fondateur a été bloqué
plus de deux fois par une journée qui ne voulait pas se clôturer, sans
pouvoir identifier facilement quelle action précise l'en empêchait.
Demande : qu'une journée se clôture automatiquement à 23h de sa propre
date si l'agent ne l'a pas fait manuellement. **Précision technique
apportée avant implémentation** : impossible d'exécuter du code
Flutter à une heure précise pendant que l'app est fermée, sans ajouter
un service natif Android (jugé disproportionné) — la clôture
automatique se déclenche donc à la prochaine ouverture de l'app, dès
que l'heure locale a dépassé 23h de la date de la journée concernée
(rattrape plusieurs journées d'affilée si l'app est restée fermée
plusieurs jours). Accepté tel quel. **Livré**.

**21.6 — Cotisation exceptionnelle modifiable.** Le fondateur veut
pouvoir corriger le montant ou repousser la date limite d'une
cotisation exceptionnelle déjà déclarée. Contredisait la doc d'origine
("jamais modifiable ensuite", voir "Cotisations exceptionnelles" dans
DECISIONS.md) — assoupli avec son accord : seule la **définition**
(motif/montant/date limite) devient modifiable, les paiements déjà
enregistrés contre elle restent définitifs. **Livré**.

**21.7 — Durée de cycle : 6 mois manquant.** Seules 9/10/11/12 mois
étaient proposés à la création du groupe. **Livré** : 6 mois ajouté.

## 22. Reprise du test terrain — retours plus tard le même jour (2026-08-11)

Le fondateur a de nouveau testé, avec des retours supplémentaires plus
précis sur l'écran Cotisation, les carnets et un rappel sur les prêts.

**22.1 — Numéro de série du carnet saisissable par l'agent.** Le
mécanisme existait déjà en base (`redefinirNumeroSerieCarnet`) mais
jamais exposé à l'écran — un carnet physique déjà numéroté doit
pouvoir garder son vrai numéro plutôt qu'un numéro généré au hasard.
**Livré** : champ optionnel à l'ajout d'un membre et à la modification
de ses carnets.

**22.2 — Plus de bouton Présent/Absent — remplacé par "Ajouter
amende".** Le fondateur ne veut plus de présence générée
automatiquement : l'agent traite chaque absence/paiement par un tiers
en cliquant directement "Ajouter amende", qui doit résoudre le carnet
concerné **tout de suite**, pas seulement anticiper pour la clôture.
"Il n'est plus nécessaire de revenir si une journée est déjà clôturée
car l'agent saisit presque tout lui-même." Les amendes restent
cumulatives (une amende libre en plus d'une résolution de carnet reste
toujours possible). **Précision demandée et confirmée avec le
fondateur avant implémentation** : l'écran de clôture reste un filet
de rattrapage pour un carnet vraiment oublié, mais ne redemande plus
rien pour un membre déjà traité (déjà son comportement actuel).
**Livré** : `AppDatabase.resoudreCarnetImmediat`, voir DECISIONS.md
"Résolution immédiate par carnet depuis 'Ajouter amende'".

**22.3 — Numéro de carnet affiché à la place du nom.** Sur le terrain,
un membre est appelé par le numéro de son carnet, pas par son nom.
**Livré** sur l'écran Cotisation (le plus concerné) : puces de carnets
sous le nom, et le numéro de série remplace "Carnet N" dans la ligne de
saisie par carnet.

**22.4 — Rappels sur le hors carnet (déjà en place, vérifiés).** Un
membre avec un crédit déjà en cours qui en redemande un autre bascule
automatiquement hors carnet dès que le cumul dépasse le plafond
(`LoanRateResolver`, via `totalEmprunteEnCoursFcfa` qui additionne tous
les prêts confirmés non soldés du membre). Plusieurs demandes de crédit
le même jour s'additionnent bien (chaque nouvelle résolution de taux
relit le cumul à jour). Rien à corriger — déjà le comportement actuel,
vérifié avec le fondateur plutôt que reconstruit.

## 23. Un membre = un seul carnet, et renommage Épargne (2026-08-13)

Le fondateur a signalé un malentendu de fond sur la notion même de
carnet, clarifié en plusieurs échanges courts avant tout code — il a
volontairement retenu son "vas-y" jusqu'à ce que chaque détail soit
fixé.

**23.1 — Un membre ne peut avoir qu'un seul carnet, jamais deux.**
Contredit la règle historique "1 ou 2 carnets par membre" (voir
DECISIONS.md, "Table Carnets avec numéro de série"). Un carnet
physique = un membre = un carnet. Une personne qui a réellement deux
carnets doit être inscrite comme deux membres séparés. **Livré** :
voir DECISIONS.md, "Un membre = un seul carnet, toujours".

**23.2 — Unicité du nom ou du téléphone, par groupe.** Conséquence
directe du point précédent : le même nom complet ou le même numéro de
téléphone ne peut plus être réutilisé pour créer un second
membre/carnet **dans le même groupe** — sinon la règle du point 23.1
serait contournable. Précision explicitement demandée et confirmée
avec le fondateur : cette unicité est **par groupe, jamais globale**
— la même personne peut appartenir à plusieurs groupes avec la même
identité. **Livré** : voir DECISIONS.md, "Unicité nom + téléphone par
groupe".

**23.3 — Renommer "Cotisation" en "Épargne" à l'écran.** Partout où
l'agent ou le membre voit le mot "Cotisation", à l'écran uniquement
(pas les noms de code, pas la documentation). **Livré** : voir
DECISIONS.md, "Renommage 'Cotisation' → 'Épargne' dans les textes
visibles" — inclut un repérage hors périmètre (deux écrans membre
redondants, `MemberSessionScreen` et `CotisationMembreScreen`) à
soumettre séparément au fondateur.

## 24. Fusion des écrans membre + bug de clôture bloquée (2026-08-13)

Le fondateur a validé la fusion des deux écrans membre repérée au
point 23.3, et a signalé le même jour un bug de terrain récurrent et
gênant : le bouton "Clôturer cette journée" échoue souvent — en lien
avec la saisie d'une amende et/ou d'un prêt — et la journée reste
bloquée même en avançant la date simulée ; quand la clôture se fait
automatiquement via le filet de sécurité 23h plutôt que par le
bouton, la réunion suivante n'affiche rien non plus.

**24.1 — Fusion des écrans membre, `CotisationMembreScreen` conservé.**
`members_screen.dart` ouvrait encore l'ancienne fiche membre
consolidée (`MemberSessionScreen`) au tap sur un membre, en parallèle
du nouvel écran Cotisation ouvert depuis "Épargnes (cash)". **Livré** :
`members_screen.dart` ouvre désormais `CotisationMembreScreen` (même
liste de membres, index sur le membre tapé), `MemberSessionScreen`
et son test supprimés.

**24.2 — Bug de clôture bloquée après une amende, cause trouvée et
corrigée.** Diagnostiqué avant tout code, confirmé par un test qui
reproduisait exactement le symptôme avant correction (voir
`test/data/local/resolution_carnet_deja_resolu_test.dart`) :
`motifsSystemeApplicables` ne reconnaissait un carnet comme déjà
résolu que via une cotisation payée ou une amende au motif précis
"Payé par un tiers" — jamais pour "Absence" ou "Part impayée", les
deux motifs les plus fréquents depuis "Ajouter amende". Rien
n'empêchait donc de résoudre deux fois le même carnet, ce qui écrivait
une deuxième ligne `Echeances` pour le même (membre, carnet, date) —
et cassait ensuite toute requête `getSingleOrNull` qui suppose ce
triplet unique (`cloturerJourneeCotisation`, `carnetsATraiterPourDate`,
et le filet de sécurité 23h qui appelle `cloturerJourneeCotisation` en
interne, expliquant pourquoi une clôture automatique cassait la
réunion suivante exactement comme une clôture manuelle ratée). **Livré**
: voir DECISIONS.md, "Correction de motifsSystemeApplicables — carnet
déjà résolu". Le lien avec les prêts mentionné par le fondateur n'a
pas révélé de bug distinct — les prêts restent entièrement séparés du
registre des échéances de cotisation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/end_of_cycle_calculator.dart';
import '../../state/providers.dart';
import '../cotisations/amende_fonds_dialogs.dart';
import '../loans/loan_confirmation_dialogs.dart';

class CycleSummaryScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const CycleSummaryScreen({
    super.key,
    required this.groupId,
    required this.cycleId,
  });

  @override
  ConsumerState<CycleSummaryScreen> createState() => _CycleSummaryScreenState();
}

class _CycleSummaryScreenState extends ConsumerState<CycleSummaryScreen> {
  late Future<_SummaryData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final db = ref.read(databaseProvider);
    setState(() {
      _dataFuture = _fetch(db);
    });
  }

  Future<_SummaryData> _fetch(AppDatabase db) async {
    final cycle = await (db.select(
      db.cycles,
    )..where((c) => c.id.equals(widget.cycleId))).getSingle();
    final membres = await db.membresDuGroupe(widget.groupId);
    final cotisations = await db.cotisationsDuCycle(widget.cycleId);
    final totalFonds = await db.totalFondsSolidarite(widget.groupId);
    final pretsNonSoldes = await db.pretsNonSoldesDuCycle(widget.cycleId);
    final motifsActifs = await db.motifsAmendeActifsDuGroupe(widget.groupId);
    // Totaux affichés à l'agent (voir RETOURS_TERRAIN.md) — valables
    // pour un cycle en cours (prévisualisation, ne compte que les
    // amendes déjà réglées cash) comme pour un cycle clos (toutes les
    // amendes sont réglées à la clôture, voir "Les amendes ne sont
    // plus une dette" : le total devient alors exact).
    final totalAmendesFcfa = await db.totalAmendesRegleesDuCycle(
      widget.cycleId,
    );
    final totalInteretsFcfa = await db.totalInteretsPercusDuCycle(
      widget.cycleId,
    );
    // Condition de clôture (voir DECISIONS.md, "Clôture de cycle
    // conditionnée au paiement de tous les membres") — sans objet pour
    // un cycle déjà clos (figée, plus jamais modifiable).
    final confirmesPayes = cycle.status == 'en_cours'
        ? await db.membresConfirmesPayesDuCycle(widget.cycleId)
        : <String>{};
    // Condition de clôture (voir DECISIONS.md, "Fonds de solidarité
    // obligatoire") — vide si le groupe n'a pas rendu le fonds
    // obligatoire, ou pour un cycle déjà clos (figé).
    final soldesSolidariteNonSoldes = cycle.status == 'en_cours'
        ? await db.soldesSolidariteObligatoireNonSoldesDuCycle(
            groupId: widget.groupId,
            cycleId: widget.cycleId,
          )
        : <String, int>{};

    final partsParMembre = <String, int>{};
    for (final c in cotisations) {
      partsParMembre.update(
        c.memberId,
        (v) => v + c.partsCount,
        ifAbsent: () => c.partsCount,
      );
    }

    // Formule "caisse disponible" (voir DECISIONS.md, "Nouvelle formule
    // de partage") : un cycle déjà clos relit les montants par membre
    // figés à la clôture (jamais recalculés — un prêt reste
    // remboursable après coup, voir pretsNonSoldesDuCycle, donc le
    // recalcul changerait avec le temps ; la "caisse disponible" et la
    // "valeur par part" de l'instant de la clôture, elles, ne sont pas
    // conservées telles quelles — seul le résultat déjà réparti par
    // membre l'est). Un cycle encore en cours affiche une
    // prévisualisation complète, recalculée à chaque ouverture de
    // l'écran.
    EndOfCycleResult? resultatEnCours;
    List<MemberCycleResult>? resultatsClotures;
    String? erreur;
    if (partsParMembre.isNotEmpty) {
      if (cycle.status == 'cloture') {
        final deductions = await db.partageDeductionsDuCycle(widget.cycleId);
        resultatsClotures = deductions
            .map(
              (d) => MemberCycleResult(
                memberId: d.memberId,
                totalParts: partsParMembre[d.memberId] ?? 0,
                cotisationTotaleFcfa:
                    (partsParMembre[d.memberId] ?? 0) * cycle.partValueFcfa,
                aBeneficieDuBonus: d.detteFcfa <= 0,
                montantBrutFcfa: d.montantBrutFcfa,
                detteFcfa: d.detteFcfa,
                montantDeduitFcfa: d.montantDeduitFcfa,
                montantNetFcfa: d.montantNetFcfa,
                pertAvecFcfa: d.pertAvecFcfa,
              ),
            )
            .toList();
      } else {
        try {
          // Même logique que [AppDatabase.cloturerCycleEtOuvrirSuivant] —
          // voir [AppDatabase.preparerPartageCycle] : la prévisualisation
          // doit refléter exactement ce que la clôture produirait,
          // amendes non soldées déjà déduites de la cotisation de chaque
          // membre (voir DECISIONS.md, "Les amendes ne sont plus une
          // dette").
          final prepared = await db.preparerPartageCycle(
            groupId: widget.groupId,
            cycleId: widget.cycleId,
          );
          final totalInterets = await db.totalInteretsPercusDuCycle(
            widget.cycleId,
          );
          final totalAmendesRegleesCash = await db.totalAmendesRegleesDuCycle(
            widget.cycleId,
          );
          final totalAmendesDeduites = prepared.amendesADeduireParMembre.values
              .fold<int>(0, (a, b) => a + b);
          final totalDettesEnCours = await db.totalPrincipalNonRembourseDuCycle(
            widget.cycleId,
          );
          resultatEnCours = const EndOfCycleCalculator().calculer(
            EndOfCycleInput(
              membres: prepared.membres,
              cotisationsTotalesGroupeFcfa:
                  prepared.cotisationsEffectivesTotalesFcfa,
              amendesRegleesFcfa:
                  totalAmendesRegleesCash + totalAmendesDeduites,
              interetsPercusFcfa: totalInterets,
              dettesEnCoursGroupeFcfa: totalDettesEnCours,
            ),
          );
        } on ArgumentError catch (e) {
          erreur = e.message?.toString();
        }
      }
    }

    return _SummaryData(
      cycle: cycle,
      membres: membres,
      resultatEnCours: resultatEnCours,
      resultatsClotures: resultatsClotures,
      erreur: erreur,
      totalFondsSolidarite: totalFonds,
      pretsNonSoldes: pretsNonSoldes,
      motifsActifs: motifsActifs,
      confirmesPayes: confirmesPayes,
      soldesSolidariteNonSoldes: soldesSolidariteNonSoldes,
      totalAmendesFcfa: totalAmendesFcfa,
      totalInteretsFcfa: totalInteretsFcfa,
    );
  }

  /// Coche/décoche "payé" pour un membre — voir DECISIONS.md, "Clôture
  /// de cycle conditionnée au paiement de tous les membres".
  Future<void> _toggleConfirmationPaiement(
    String memberId,
    bool confirme,
  ) async {
    final db = ref.read(databaseProvider);
    if (confirme) {
      final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
      await db.confirmerPaiementMembre(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        memberId: memberId,
        confirmedByPhone: agentPhone,
      );
    } else {
      await db.annulerConfirmationPaiementMembre(
        cycleId: widget.cycleId,
        memberId: memberId,
      );
    }
    _reload();
  }

  /// Dialogues "Ajouter une amende"/"Contribution fonds" : voir
  /// `amende_fonds_dialogs.dart`, partagés avec l'écran Cotisations
  /// (voir DECISIONS.md, "Écran Cotisations moins chargé").
  Future<void> _showAddAmendeDialog(
    List<Member> membres,
    List<MotifsAmendeData> motifsCatalogue,
  ) {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    return showAddAmendeDialog(
      context: context,
      db: db,
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      agentPhone: agentPhone,
      membres: membres,
      motifsCatalogue: motifsCatalogue,
      onSaved: _reload,
    );
  }

  Future<void> _showAddFondsDialog(List<Member> membres) {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    return showAddFondsDialog(
      context: context,
      db: db,
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      agentPhone: agentPhone,
      membres: membres,
      onSaved: _reload,
    );
  }

  Future<void> _showCloturerCycleDialog(
    Cycle cycle,
    List<PretNonSolde> pretsNonSoldes,
    List<Member> membres,
  ) async {
    final carnetController = TextEditingController(
      text: cycle.partValueFcfa.toString(),
    );
    final tauxController = TextEditingController(
      text: cycle.interestRatePercent.toString(),
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clôturer le cycle n°${cycle.cycleNumber} ?'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cette action fige définitivement le cycle actuel (plus aucune "
                  "épargne, prêt ou amende ne pourra y être ajouté) et ouvre "
                  "immédiatement le cycle suivant.",
                ),
                if (pretsNonSoldes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pretsNonSoldes.length} prêt(s) pas encore totalement remboursé(s) :',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        ...pretsNonSoldes.map(
                          (p) => Text(
                            '• solde restant ${p.soldeRestantFcfa} FCFA',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "La clôture reste possible — au comité de décider comment "
                          "traiter ce solde en dehors de l'app.",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Paramètres du cycle n°${cycle.cycleNumber + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: carnetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valeur du carnet (FCFA)',
                  ),
                  validator: (v) => (int.tryParse(v ?? '') == null)
                      ? 'Montant invalide'
                      : null,
                ),
                TextFormField(
                  controller: tauxController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Taux d'intérêt (%)",
                  ),
                  validator: (v) => (double.tryParse(v ?? '') == null)
                      ? 'Taux invalide'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate())
                Navigator.of(context).pop(true);
            },
            child: const Text('Clôturer et ouvrir le cycle suivant'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    final nouveauCycleId = await db.cloturerCycleEtOuvrirSuivant(
      groupId: widget.groupId,
      cycleIdACloturer: cycle.id,
      nouveauPartValueFcfa: int.parse(carnetController.text.trim()),
      nouveauInterestRatePercent: double.parse(tauxController.text.trim()),
      recordedByPhone: agentPhone,
    );
    if (!mounted) return;
    // Reconduction d'un prêt non soldé au cycle suivant (voir
    // DECISIONS.md, "Dette de prêt au rouge") — proposée maintenant,
    // une fois le nouveau cycle ouvert (le prêt successeur doit lui
    // être rattaché), jamais automatique : chaque prêt est traité un à
    // un, avec l'accord explicite du membre à chaque fois.
    if (pretsNonSoldes.isNotEmpty) {
      await _proposerReconductions(pretsNonSoldes, nouveauCycleId, membres);
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cycle n°${cycle.cycleNumber} clôturé — cycle n°${cycle.cycleNumber + 1} ouvert.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  /// Propose, un prêt à la fois, de reconduire dans le nouveau cycle
  /// chaque prêt non soldé de l'ancien — voir DECISIONS.md, "Dette de
  /// prêt au rouge", et RETOURS_TERRAIN.md, point 19. **Jamais
  /// automatique** : l'agent doit obtenir l'accord explicite du membre
  /// avant de reconduire quoi que ce soit ; refuser n'empêche jamais la
  /// clôture, déjà effective à ce stade. Un prêt reconduit exige sa
  /// propre confirmation par le membre, comme tout nouveau prêt.
  Future<void> _proposerReconductions(
    List<PretNonSolde> pretsNonSoldes,
    String nouveauCycleId,
    List<Member> membres,
  ) async {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    final membresParId = {for (final m in membres) m.id: m};

    for (final pretNonSolde in pretsNonSoldes) {
      final pret = pretNonSolde.pret;
      final membre = membresParId[pret.memberId];
      final nomMembre = membre?.fullName ?? pret.memberId;

      if (!mounted) return;
      final veutReconduire = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Prêt non soldé'),
          content: Text(
            '$nomMembre a un prêt non soldé (solde restant '
            '${formatFcfa(pretNonSolde.soldeRestantFcfa)} au moment de la '
            'clôture). Le membre est-il d\'accord pour le reconduire dans '
            'le nouveau cycle ? Il repart au taux du nouveau cycle et '
            'entre directement "au rouge" (10 %/mois, voir DECISIONS.md).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Non — laisser tel quel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Oui, le membre est d\'accord'),
            ),
          ],
        ),
      );

      if (veutReconduire != true) continue;
      if (!mounted) return;

      // Génère le code de confirmation AVANT de créer le prêt
      // successeur, comme tout nouveau prêt — voir [enregistrerPret] /
      // [_showNewLoanDialog] dans loans_screen.dart.
      final authGateway = ref.read(authGatewayProvider);
      final phoneMembre = membre?.phoneNumber;
      final code = phoneMembre == null
          ? null
          : await authGateway.envoyerCode(phoneMembre);

      final ({String pretId, String? confirmationCode}) resultat;
      try {
        resultat = await db.reconduireCyclePret(
          pretId: pret.id,
          nouveauCycleId: nouveauCycleId,
          agentPhone: agentPhone,
          confirmationCode: code,
        );
      } on StateError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
        continue;
      }

      if (!mounted) return;
      await showLoanConfirmationDialog(
        context: context,
        db: db,
        pretId: resultat.pretId,
        memberName: nomMembre,
        memberPhone: phoneMembre,
        agentPhone: agentPhone,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Répartition de fin de cycle')),
      body: FutureBuilder<_SummaryData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final membresParId = {for (final m in data.membres) m.id: m};
          final resultats =
              data.resultatEnCours?.resultatsParMembre ??
              data.resultatsClotures;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (resultats == null)
                Text(
                  data.erreur ??
                      'Aucune épargne enregistrée sur ce cycle pour le moment.',
                )
              else ...[
                // La caisse disponible / valeur par part ne s'affichent que
                // pour un cycle en cours (prévisualisation recalculée à
                // chaque ouverture) — un cycle déjà clos ne conserve que le
                // résultat déjà réparti par membre, pas ces totaux
                // intermédiaires (voir DECISIONS.md, "Nouvelle formule de
                // partage").
                if (data.resultatEnCours != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Caisse disponible : ${formatFcfa(data.resultatEnCours!.caisseDisponibleFcfa)}',
                          ),
                          Text(
                            'Total parts du groupe : ${data.resultatEnCours!.totalPartsGroupe}',
                          ),
                          Text(
                            'Valeur par part : ${formatFcfa(data.resultatEnCours!.valeurParPart)}',
                          ),
                          const Divider(height: 20),
                          Text(
                            'Total généré par les amendes : '
                            '${formatFcfa(data.totalAmendesFcfa)}',
                          ),
                          Text(
                            'Total généré par les intérêts de prêt : '
                            '${formatFcfa(data.totalInteretsFcfa.round())}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // Cycle déjà clos : caisse disponible/valeur par part
                  // n'ont plus de sens (voir plus haut), mais les totaux
                  // amendes/intérêts restent lisibles depuis les données
                  // définitives du cycle.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total généré par les amendes : '
                            '${formatFcfa(data.totalAmendesFcfa)}',
                          ),
                          Text(
                            'Total généré par les intérêts de prêt : '
                            '${formatFcfa(data.totalInteretsFcfa.round())}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ...resultats.map((r) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              membresParId[r.memberId]?.fullName ?? r.memberId,
                            ),
                            subtitle: Text(
                              r.aBeneficieDuBonus
                                  ? '${r.totalParts} part(s) · épargne ${formatFcfa(r.cotisationTotaleFcfa)} '
                                        '+ part du bénéfice collectif'
                                  : '${r.totalParts} part(s) · épargne ${formatFcfa(r.cotisationTotaleFcfa)} '
                                        '· aucun bénéfice (dette en cours)',
                            ),
                            trailing: data.resultatEnCours == null
                                ? Text(
                                    formatFcfa(r.montantNetFcfa),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  )
                                // Condition de clôture (voir DECISIONS.md,
                                // "Clôture de cycle conditionnée au paiement
                                // de tous les membres") — case à cocher par
                                // membre, uniquement pour un cycle en cours.
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(formatFcfa(r.montantNetFcfa)),
                                      Tooltip(
                                        message:
                                            'Confirmer que ce membre a '
                                            'reçu son paiement',
                                        child: Checkbox(
                                          value: data.confirmesPayes.contains(
                                            r.memberId,
                                          ),
                                          onChanged: (v) =>
                                              _toggleConfirmationPaiement(
                                                r.memberId,
                                                v ?? false,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          // Déduction de dette (skill avec-business-rules — voir
                          // DECISIONS.md "Déduction des dettes au partage") :
                          // affichée seulement si le membre a une dette, pour ne
                          // pas alourdir l'écran pour les membres à jour.
                          if (r.detteFcfa > 0)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Montant brut à percevoir (sans bénéfice) : ${formatFcfa(r.montantBrutFcfa)}',
                                    ),
                                    Text(
                                      'Dette totale : ${formatFcfa(r.detteFcfa)}',
                                    ),
                                    Text(
                                      'Déduit : ${formatFcfa(r.montantDeduitFcfa)}',
                                    ),
                                    Text(
                                      'Montant net versé : ${formatFcfa(r.montantNetFcfa)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (r.pertAvecFcfa > 0)
                                      Text(
                                        'Perte pour l\'AVEC : ${formatFcfa(r.pertAvecFcfa)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fonds de solidarité : ${formatFcfa(data.totalFondsSolidarite)}',
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Jamais inclus dans le calcul ci-dessus — reste dans le groupe pour l’avenir.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _showAddAmendeDialog(data.membres, data.motifsActifs),
                      child: const Text('Ajouter une amende'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showAddFondsDialog(data.membres),
                      child: const Text('Contribution fonds'),
                    ),
                  ),
                ],
              ),
              if (data.cycle.status == 'en_cours') ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    // Condition de clôture (voir DECISIONS.md, "Clôture de
                    // cycle conditionnée au paiement de tous les membres") :
                    // un cycle sans aucun membre à répartir (jamais aucune
                    // cotisation) n'a rien à confirmer.
                    final nonConfirmes = (resultats ?? const [])
                        .where((r) => !data.confirmesPayes.contains(r.memberId))
                        .length;
                    final tousConfirmes = nonConfirmes == 0;
                    // Condition de clôture (voir DECISIONS.md, "Fonds de
                    // solidarité obligatoire" : "tout doit être soldé
                    // avant le partage de fin de cycle") — indépendante
                    // de la confirmation "payé" ci-dessus.
                    final nonSoldesSolidarite =
                        data.soldesSolidariteNonSoldes.length;
                    final solidariteAJour = nonSoldesSolidarite == 0;
                    final peutCloturer = tousConfirmes && solidariteAJour;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!tousConfirmes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '$nonConfirmes membre(s) pas encore confirmé(s) '
                              'comme payé(s) — cochez "payé" pour chacun avant '
                              'de pouvoir clôturer.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (!solidariteAJour)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '$nonSoldesSolidarite membre(s) n\'ont pas soldé '
                              'leur fonds de solidarité obligatoire — à régler '
                              'depuis leur fiche membre avant de pouvoir '
                              'clôturer.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: peutCloturer
                              ? () => _showCloturerCycleDialog(
                                  data.cycle,
                                  data.pretsNonSoldes,
                                  data.membres,
                                )
                              : null,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Clôturer ce cycle'),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Cycle clôturé — lecture seule.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryData {
  final Cycle cycle;
  final List<Member> membres;

  /// Non nul seulement pour un cycle `en_cours` — inclut la caisse
  /// disponible et la valeur par part (prévisualisation recalculée).
  final EndOfCycleResult? resultatEnCours;

  /// Non nul seulement pour un cycle `cloture` — relit les montants par
  /// membre figés à la clôture, sans totaux intermédiaires (voir
  /// DECISIONS.md, "Nouvelle formule de partage").
  final List<MemberCycleResult>? resultatsClotures;

  final String? erreur;
  final int totalFondsSolidarite;
  final List<PretNonSolde> pretsNonSoldes;
  final List<MotifsAmendeData> motifsActifs;

  /// Membres déjà confirmés comme payés pour ce cycle — vide (et sans
  /// objet) pour un cycle déjà clos. Voir DECISIONS.md, "Clôture de
  /// cycle conditionnée au paiement de tous les membres".
  final Set<String> confirmesPayes;

  /// Membres n'ayant pas encore soldé le fonds de solidarité
  /// obligatoire — vide si le groupe ne l'a pas rendu obligatoire, ou
  /// pour un cycle déjà clos. Voir DECISIONS.md, "Fonds de solidarité
  /// obligatoire".
  final Map<String, int> soldesSolidariteNonSoldes;

  /// Total des amendes réglées sur ce cycle — voir RETOURS_TERRAIN.md.
  /// Exact pour un cycle clos (toutes réglées à la clôture), une
  /// prévisualisation (cash seulement) pour un cycle en cours.
  final int totalAmendesFcfa;

  /// Total des intérêts perçus sur les prêts remboursés de ce cycle.
  final double totalInteretsFcfa;

  const _SummaryData({
    required this.cycle,
    required this.membres,
    required this.resultatEnCours,
    required this.resultatsClotures,
    required this.erreur,
    required this.totalFondsSolidarite,
    required this.pretsNonSoldes,
    required this.motifsActifs,
    required this.confirmesPayes,
    required this.soldesSolidariteNonSoldes,
    required this.totalAmendesFcfa,
    required this.totalInteretsFcfa,
  });
}

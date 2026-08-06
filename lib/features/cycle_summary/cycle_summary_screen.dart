import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/end_of_cycle_calculator.dart';
import '../../state/providers.dart';

class CycleSummaryScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const CycleSummaryScreen({super.key, required this.groupId, required this.cycleId});

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
    final cycle =
        await (db.select(db.cycles)..where((c) => c.id.equals(widget.cycleId))).getSingle();
    final membres = await db.membresDuGroupe(widget.groupId);
    final cotisations = await db.cotisationsDuCycle(widget.cycleId);
    final totalInterets = await db.totalInteretsPercusDuCycle(widget.cycleId);
    final totalAmendes = await db.totalAmendesDuCycle(widget.cycleId);
    final totalFonds = await db.totalFondsSolidarite(widget.groupId);
    final pretsNonSoldes = await db.pretsNonSoldesDuCycle(widget.cycleId);

    final partsParMembre = <String, int>{};
    for (final c in cotisations) {
      partsParMembre.update(c.memberId, (v) => v + c.partsCount, ifAbsent: () => c.partsCount);
    }

    EndOfCycleResult? resultat;
    String? erreur;
    if (partsParMembre.isNotEmpty) {
      try {
        resultat = const EndOfCycleCalculator().calculer(EndOfCycleInput(
          partsByMember: partsParMembre.entries
              .map((e) => MemberParts(memberId: e.key, totalParts: e.value))
              .toList(),
          partValueFcfa: cycle.partValueFcfa,
          totalInterestCollectedFcfa: totalInterets,
          totalFinesCollectedFcfa: totalAmendes,
        ));
      } on ArgumentError catch (e) {
        erreur = e.message?.toString();
      }
    }

    return _SummaryData(
      cycle: cycle,
      membres: membres,
      resultat: resultat,
      erreur: erreur,
      totalFondsSolidarite: totalFonds,
      pretsNonSoldes: pretsNonSoldes,
    );
  }

  Future<void> _showAddAmendeDialog(List<Member> membres) async {
    String? memberId;
    final montantController = TextEditingController();
    final motifController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter une amende'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: memberId,
                  decoration: const InputDecoration(labelText: 'Membre'),
                  items: membres
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => memberId = v),
                  validator: (v) => v == null ? 'Choisir un membre' : null,
                ),
                TextFormField(
                  controller: montantController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
                ),
                TextFormField(
                  controller: motifController,
                  decoration: const InputDecoration(labelText: 'Motif'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Motif obligatoire' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || memberId == null) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.enregistrerAmende(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      memberId: memberId!,
      montantFcfa: int.parse(montantController.text.trim()),
      motif: motifController.text.trim(),
      recordedByPhone: agentPhone,
    );
    _reload();
  }

  Future<void> _showAddFondsDialog(List<Member> membres) async {
    String? memberId;
    final montantController = TextEditingController();
    final motifController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Contribution — fonds de solidarité'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: memberId,
                  decoration: const InputDecoration(labelText: 'Membre (optionnel)'),
                  items: membres
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => memberId = v),
                ),
                TextFormField(
                  controller: montantController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
                ),
                TextFormField(
                  controller: motifController,
                  decoration: const InputDecoration(labelText: 'Motif'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Motif obligatoire' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.enregistrerContributionFondsSolidarite(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      memberId: memberId,
      montantFcfa: int.parse(montantController.text.trim()),
      motif: motifController.text.trim(),
      recordedByPhone: agentPhone,
    );
    _reload();
  }

  Future<void> _showCloturerCycleDialog(Cycle cycle, List<PretNonSolde> pretsNonSoldes) async {
    final carnetController =
        TextEditingController(text: cycle.partValueFcfa.toString());
    final tauxController =
        TextEditingController(text: cycle.interestRatePercent.toString());
    final amendeController =
        TextEditingController(text: cycle.lateFeeFcfa.toString());
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
                  "cotisation, prêt ou amende ne pourra y être ajouté) et ouvre "
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
                          (p) => Text('• solde restant ${p.soldeRestantFcfa} FCFA'),
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
                Text('Paramètres du cycle n°${cycle.cycleNumber + 1}',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: carnetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valeur du carnet (FCFA)'),
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
                ),
                TextFormField(
                  controller: tauxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Taux d'intérêt (%)"),
                  validator: (v) => (double.tryParse(v ?? '') == null) ? 'Taux invalide' : null,
                ),
                TextFormField(
                  controller: amendeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amende de retard (FCFA)',
                    helperText: '0 si le groupe ne prévoit pas d\'amende automatique',
                  ),
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
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
              if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
            },
            child: const Text('Clôturer et ouvrir le cycle suivant'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    await db.cloturerCycleEtOuvrirSuivant(
      groupId: widget.groupId,
      cycleIdACloturer: cycle.id,
      nouveauPartValueFcfa: int.parse(carnetController.text.trim()),
      nouveauInterestRatePercent: double.parse(tauxController.text.trim()),
      nouveauLateFeeFcfa: int.parse(amendeController.text.trim()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cycle n°${cycle.cycleNumber} clôturé — cycle n°${cycle.cycleNumber + 1} ouvert.')),
    );
    Navigator.of(context).pop();
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.resultat == null)
                Text(data.erreur ?? 'Aucune cotisation enregistrée sur ce cycle pour le moment.')
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Intérêts + amendes collectés : ${formatFcfa(data.resultat!.totalInteretsAmendes)}'),
                        Text('Total carnets du groupe : ${data.resultat!.totalPartsGroupe}'),
                        Text('Valeur ajoutée par carnet : ${formatFcfa(data.resultat!.valeurParPart)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...data.resultat!.resultatsParMembre.map((r) => Card(
                      child: ListTile(
                        title: Text(membresParId[r.memberId]?.fullName ?? r.memberId),
                        subtitle: Text(
                          '${r.totalParts} carnet(s) · cotisation ${formatFcfa(r.cotisationTotale)} '
                          '+ bénéfice individuel ${formatFcfa(r.beneficeIndividuel)}',
                        ),
                        trailing: Text(
                          formatFcfa(r.montantTotalRecu),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fonds de solidarité : ${formatFcfa(data.totalFondsSolidarite)}'),
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
                      onPressed: () => _showAddAmendeDialog(data.membres),
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
                FilledButton.icon(
                  onPressed: () => _showCloturerCycleDialog(data.cycle, data.pretsNonSoldes),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Clôturer ce cycle'),
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
  final EndOfCycleResult? resultat;
  final String? erreur;
  final int totalFondsSolidarite;
  final List<PretNonSolde> pretsNonSoldes;

  const _SummaryData({
    required this.cycle,
    required this.membres,
    required this.resultat,
    required this.erreur,
    required this.totalFondsSolidarite,
    required this.pretsNonSoldes,
  });
}

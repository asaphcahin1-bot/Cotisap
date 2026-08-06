import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_clock.dart';
import '../../core/formatting.dart';
import '../../data/import/historical_import_service.dart';
import '../../data/local/database.dart';
import '../../domain/import/historical_import_parser.dart';
import '../../state/providers.dart';

/// Import d'historique pour un groupe déjà existant (skill
/// historical-data-import). L'agent choisit d'abord le cycle cible : le
/// cycle actuellement ouvert, ou un nouveau cycle historique déjà clos
/// (pour un historique qui représente un cycle antérieur, avec sa
/// propre valeur de part et son propre taux — voir DECISIONS.md).
class HistoricalImportScreen extends ConsumerStatefulWidget {
  final String groupId;

  const HistoricalImportScreen({super.key, required this.groupId});

  @override
  ConsumerState<HistoricalImportScreen> createState() => _HistoricalImportScreenState();
}

enum _CibleImport { cycleEnCours, nouveauCycleHistorique }

class _HistoricalImportScreenState extends ConsumerState<HistoricalImportScreen> {
  final _csvController = TextEditingController();
  final _numeroCycleController = TextEditingController();
  final _partValueController = TextEditingController();
  final _interestController = TextEditingController();
  final _lateFeeController = TextEditingController(text: '0');
  DateTime? _debutCycle;
  DateTime? _finCycle;

  _CibleImport? _cible;
  Cycle? _cycleEnCours;
  String? _cycleCibleId;

  ResultatAnalyseImport? _resultat;
  Map<String, Member>? _membresResolus;
  List<String> _nomsIntrouvables = [];
  bool _importEnCours = false;
  HistoricalImportOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _chargerCycleEnCours();
  }

  @override
  void dispose() {
    _csvController.dispose();
    _numeroCycleController.dispose();
    _partValueController.dispose();
    _interestController.dispose();
    _lateFeeController.dispose();
    super.dispose();
  }

  Future<void> _chargerCycleEnCours() async {
    final db = ref.read(databaseProvider);
    final cycle = await db.cycleEnCours(widget.groupId);
    final prochainNumero = await db.prochainNumeroCycle(widget.groupId);
    if (!mounted) return;
    setState(() {
      _cycleEnCours = cycle;
      _numeroCycleController.text = '$prochainNumero';
    });
  }

  Future<void> _creerCycleHistorique() async {
    final numero = int.tryParse(_numeroCycleController.text.trim());
    final partValue = int.tryParse(_partValueController.text.trim());
    final taux = double.tryParse(_interestController.text.trim());
    final amendeRetard = int.tryParse(_lateFeeController.text.trim()) ?? 0;
    if (numero == null || partValue == null || taux == null || _debutCycle == null || _finCycle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs du cycle historique.')),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    final cycleId = await db.creerCycleHistorique(
      groupId: widget.groupId,
      cycleNumber: numero,
      partValueFcfa: partValue,
      interestRatePercent: taux,
      lateFeeFcfa: amendeRetard,
      debut: _debutCycle!,
      fin: _finCycle!,
    );
    setState(() => _cycleCibleId = cycleId);
  }

  Future<void> _choisirDate({required bool debut}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: AppClock.now(),
      firstDate: DateTime(2000),
      lastDate: AppClock.now(),
    );
    if (date == null) return;
    setState(() {
      if (debut) {
        _debutCycle = date;
      } else {
        _finCycle = date;
      }
    });
  }

  Future<void> _analyser() async {
    final db = ref.read(databaseProvider);
    final resultat = const HistoricalImportParser().analyser(_csvController.text);
    final membresDuGroupe = await db.membresDuGroupe(widget.groupId);
    final service = HistoricalImportService(db);
    final resolus = service.resoudreMembres(resultat.nomsMembresDistincts, membresDuGroupe);
    final introuvables = service.nomsIntrouvables(resultat.nomsMembresDistincts, resolus);

    setState(() {
      _resultat = resultat;
      _membresResolus = resolus;
      _nomsIntrouvables = introuvables;
      _outcome = null;
    });
  }

  bool get _peutConfirmer =>
      _resultat != null &&
      !_resultat!.aDesErreurs &&
      _resultat!.lignesValides.isNotEmpty &&
      _nomsIntrouvables.isEmpty;

  Future<void> _confirmer() async {
    final resultat = _resultat!;
    final cycleCibleId = _cycleCibleId!;
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'import'),
        content: Text(
          '${resultat.lignesValides.length} opération(s), '
          '${resultat.nomsMembresDistincts.length} membre(s), '
          '${formatFcfa(resultat.montantTotalFcfa)} au total.\n\n'
          'Cette confirmation représente la validation collective du comité '
          'de gestion prévue par le processus d\'import — elle sera tracée '
          'au nom de $agentPhone. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer l\'import'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _importEnCours = true);
    final db = ref.read(databaseProvider);
    final cycle = await (db.select(db.cycles)..where((c) => c.id.equals(cycleCibleId))).getSingle();
    final service = HistoricalImportService(db);
    final outcome = await service.executer(
      groupId: widget.groupId,
      cycleId: cycleCibleId,
      lignes: resultat.lignesValides,
      membresResolus: _membresResolus!,
      partValueFcfa: cycle.partValueFcfa,
      interestRatePercent: cycle.interestRatePercent,
      confirmedByPhone: agentPhone,
    );

    setState(() {
      _importEnCours = false;
      _outcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importer un historique')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('1. Cycle cible', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<_CibleImport>(
            groupValue: _cible,
            onChanged: (v) => setState(() {
              _cible = v;
              _cycleCibleId = v == _CibleImport.cycleEnCours ? _cycleEnCours?.id : null;
            }),
            child: Column(
              children: [
                RadioListTile<_CibleImport>(
                  value: _CibleImport.cycleEnCours,
                  enabled: _cycleEnCours != null,
                  title: Text(_cycleEnCours != null
                      ? 'Cycle en cours (n°${_cycleEnCours!.cycleNumber})'
                      : 'Aucun cycle en cours'),
                ),
                RadioListTile<_CibleImport>(
                  value: _CibleImport.nouveauCycleHistorique,
                  title: const Text('Nouveau cycle historique (déjà clos)'),
                ),
              ],
            ),
          ),
          if (_cible == _CibleImport.nouveauCycleHistorique && _cycleCibleId == null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _numeroCycleController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Numéro du cycle', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _partValueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Valeur du carnet (FCFA) de ce cycle', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _interestController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: "Taux d'intérêt (%) de ce cycle", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lateFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amende de retard (FCFA) de ce cycle', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _choisirDate(debut: true),
                    child: Text(_debutCycle == null
                        ? 'Date de début'
                        : 'Début : ${_debutCycle!.day}/${_debutCycle!.month}/${_debutCycle!.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _choisirDate(debut: false),
                    child: Text(_finCycle == null
                        ? 'Date de fin'
                        : 'Fin : ${_finCycle!.day}/${_finCycle!.month}/${_finCycle!.year}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _creerCycleHistorique,
              child: const Text('Créer ce cycle historique'),
            ),
          ],
          if (_cycleCibleId != null) ...[
            const Divider(height: 32),
            Text('2. Historique à importer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Collez ici le contenu d\'un carnet ou d\'un export CSV/Excel, '
              'une opération par ligne : nom du membre, date, montant, type '
              '(cotisation, pret, remboursement, amende, fonds_solidarite).',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _csvController,
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Aya Kone,2024-03-15,5000,cotisation\n'
                    'Fatou Traore,15/03/2024,50000,pret\n'
                    'Fatou Traore,20/04/2024,55000,remboursement',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _analyser, child: const Text('Analyser')),
            if (_resultat != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_resultat!.lignesValides.length} ligne(s) valide(s)'),
                      Text('${_resultat!.nomsMembresDistincts.length} membre(s) concerné(s)'),
                      Text('Montant total : ${formatFcfa(_resultat!.montantTotalFcfa)}'),
                    ],
                  ),
                ),
              ),
              if (_resultat!.erreurs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Erreurs (${_resultat!.erreurs.length})',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
                ..._resultat!.erreurs.map((e) => Text('Ligne ${e.numeroLigne} — ${e.message}')),
              ],
              if (_nomsIntrouvables.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Membres introuvables dans ce groupe (${_nomsIntrouvables.length})',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                Text(_nomsIntrouvables.join(', ')),
                const Text(
                  'Ajoutez-les d\'abord dans "Membres" (avec leur numéro de téléphone), '
                  'puis relancez l\'analyse.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: (_peutConfirmer && !_importEnCours) ? _confirmer : null,
                child: _importEnCours
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirmer l\'import'),
              ),
            ],
            if (_outcome != null) ...[
              const SizedBox(height: 20),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_outcome!.nbEcritures} écriture(s) importée(s).'),
                      ..._outcome!.avertissements.map((a) => Text(a)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

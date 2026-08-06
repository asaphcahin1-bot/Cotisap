import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../state/providers.dart';
import '../cycle_summary/cycle_summary_screen.dart';

/// Liste tous les cycles d'un groupe, ouvert comme clos — permet de
/// revenir consulter la répartition finale d'un cycle historique importé
/// (voir ROADMAP.md, "import multi-cycle").
class CyclesListScreen extends ConsumerStatefulWidget {
  final String groupId;

  const CyclesListScreen({super.key, required this.groupId});

  @override
  ConsumerState<CyclesListScreen> createState() => _CyclesListScreenState();
}

class _CyclesData {
  final List<Cycle> cycles;

  /// Le cycle clos immédiatement suivi d'un cycle en cours encore vide —
  /// seul cas où l'annulation de clôture est proposée (voir
  /// DECISIONS.md).
  final String? cycleClotureAnnulableId;
  final String? cycleSuivantVideId;

  const _CyclesData({
    required this.cycles,
    required this.cycleClotureAnnulableId,
    required this.cycleSuivantVideId,
  });
}

class _CyclesListScreenState extends ConsumerState<CyclesListScreen> {
  late Future<_CyclesData> _dataFuture;

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

  Future<_CyclesData> _fetch(AppDatabase db) async {
    final cycles = await db.cyclesDuGroupe(widget.groupId);
    final enCours = cycles.where((c) => c.status == 'en_cours').toList();

    String? cycleClotureAnnulableId;
    String? cycleSuivantVideId;
    if (enCours.length == 1) {
      final courant = enCours.single;
      if (await db.cycleEstVide(courant.id)) {
        final precedents = cycles.where(
          (c) => c.status == 'cloture' && c.cycleNumber == courant.cycleNumber - 1,
        );
        if (precedents.isNotEmpty) {
          cycleClotureAnnulableId = precedents.first.id;
          cycleSuivantVideId = courant.id;
        }
      }
    }

    return _CyclesData(
      cycles: cycles,
      cycleClotureAnnulableId: cycleClotureAnnulableId,
      cycleSuivantVideId: cycleSuivantVideId,
    );
  }

  Future<void> _annulerCloture(String cycleClotureId, String cycleSuivantId, int numero) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler la clôture du cycle n°$numero ?'),
        content: const Text(
          "Le cycle suivant (encore vide) sera supprimé et ce cycle redeviendra "
          "en cours, comme avant la clôture. Possible uniquement parce qu'aucune "
          "donnée n'a encore été enregistrée sur le nouveau cycle.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Annuler la clôture'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    final db = ref.read(databaseProvider);
    try {
      await db.annulerClotureCycle(
        cycleClotureId: cycleClotureId,
        cycleSuivantId: cycleSuivantId,
      );
      _reload();
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycles')),
      body: FutureBuilder<_CyclesData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final cycles = data.cycles;
          if (cycles.isEmpty) {
            return const Center(child: Text('Aucun cycle pour ce groupe.'));
          }
          return ListView.separated(
            itemCount: cycles.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cycle = cycles[index];
              final enCours = cycle.status == 'en_cours';
              final annulable = cycle.id == data.cycleClotureAnnulableId;
              return ListTile(
                leading: Icon(
                  enCours ? Icons.play_circle_outline : Icons.lock_outline,
                  color: enCours ? Colors.green : null,
                ),
                title: Text('Cycle n°${cycle.cycleNumber}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${enCours ? "En cours" : "Clos"} · '
                      'carnet ${cycle.partValueFcfa} FCFA · intérêt ${cycle.interestRatePercent} %',
                    ),
                    if (annulable)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: OutlinedButton(
                          onPressed: () => _annulerCloture(
                            cycle.id,
                            data.cycleSuivantVideId!,
                            cycle.cycleNumber,
                          ),
                          child: const Text('Annuler la clôture (fermé par erreur ?)'),
                        ),
                      ),
                  ],
                ),
                isThreeLine: annulable,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CycleSummaryScreen(
                      groupId: widget.groupId,
                      cycleId: cycle.id,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

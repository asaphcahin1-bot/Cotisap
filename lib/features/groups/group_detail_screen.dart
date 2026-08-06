import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../state/providers.dart';
import '../members/members_screen.dart';
import '../cotisations/record_cotisation_screen.dart';
import '../loans/loans_screen.dart';
import '../cycle_summary/cycle_summary_screen.dart';
import '../historical_import/historical_import_screen.dart';
import '../cycles/cycles_list_screen.dart';
import 'edit_group_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  late Future<(Group, Cycle?, bool)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final db = ref.read(databaseProvider);
    setState(() {
      _dataFuture = _fetch(db);
    });
  }

  Future<(Group, Cycle?, bool)> _fetch(AppDatabase db) async {
    final groupe = await (db.select(db.groups)
          ..where((g) => g.id.equals(widget.groupId)))
        .getSingle();
    final cycle = await db.cycleEnCours(widget.groupId);
    final peutModifier = cycle == null ? false : !(await db.cycleADesCotisations(cycle.id));
    return (groupe, cycle, peutModifier);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Group, Cycle?, bool)>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final (groupe, cycle, peutModifier) = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(groupe.name),
            actions: [
              if (peutModifier && cycle != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Modifier le groupe',
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EditGroupScreen(groupe: groupe, cycle: cycle),
                    ));
                    _load();
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: cycle == null
                      ? const Text('Aucun cycle en cours.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cycle n°${cycle.cycleNumber} — en cours',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('Valeur du carnet : ${cycle.partValueFcfa} FCFA'),
                            Text("Taux d'intérêt : ${cycle.interestRatePercent} %"),
                            if (cycle.lateFeeFcfa > 0)
                              Text('Amende de retard : ${cycle.lateFeeFcfa} FCFA'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _NavCard(
                icon: Icons.people_outline,
                title: 'Membres',
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MembersScreen(groupId: widget.groupId),
                  ));
                  _load();
                },
              ),
              if (cycle != null) ...[
                _NavCard(
                  icon: Icons.savings_outlined,
                  title: 'Cotisations (cash)',
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RecordCotisationScreen(
                        groupId: widget.groupId,
                        cycleId: cycle.id,
                      ),
                    ));
                    _load();
                  },
                ),
                _NavCard(
                  icon: Icons.handshake_outlined,
                  title: 'Prêts',
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LoansScreen(
                        groupId: widget.groupId,
                        cycleId: cycle.id,
                      ),
                    ));
                    _load();
                  },
                ),
                _NavCard(
                  icon: Icons.calculate_outlined,
                  title: 'Répartition de fin de cycle',
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CycleSummaryScreen(
                        groupId: widget.groupId,
                        cycleId: cycle.id,
                      ),
                    ));
                    _load();
                  },
                ),
              ],
              _NavCard(
                icon: Icons.upload_file_outlined,
                title: 'Importer un historique',
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HistoricalImportScreen(groupId: widget.groupId),
                  ));
                  _load();
                },
              ),
              _NavCard(
                icon: Icons.history,
                title: 'Cycles',
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CyclesListScreen(groupId: widget.groupId),
                  ));
                  _load();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _NavCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

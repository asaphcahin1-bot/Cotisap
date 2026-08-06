import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_clock.dart';
import '../../data/local/database.dart';
import '../../state/providers.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  late Future<List<Group>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final db = ref.read(databaseProvider);
    setState(() {
      _groupsFuture = db.select(db.groups).get();
    });
  }

  /// Mode test uniquement (jamais en version publiée, voir
  /// `AppClock.definir` qui ignore silencieusement hors debug) : permet
  /// de simuler une date pour dérouler plusieurs semaines/mois d'usage
  /// sans attendre ni toucher à l'horloge réelle du téléphone — voir
  /// DECISIONS.md.
  Future<void> _gererDateSimulee() async {
    final choix = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 Mode test — date simulée'),
        content: Text(
          AppClock.estSimulee
              ? 'Date actuellement simulée : ${_formatDate(AppClock.now())}\n\n'
                  "Toute l'app (montants dus, amendes, prêts) se comporte comme si "
                  "on était à cette date."
              : "Date réelle utilisée actuellement (${_formatDate(AppClock.now())}).",
        ),
        actions: [
          if (AppClock.estSimulee)
            TextButton(
              onPressed: () => Navigator.of(context).pop('reset'),
              child: const Text('Revenir à aujourd\'hui'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('choisir'),
            child: const Text('Choisir une date'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (choix == 'reset') {
      setState(() => AppClock.definir(null));
    } else if (choix == 'choisir') {
      final choisie = await showDatePicker(
        context: context,
        initialDate: AppClock.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );
      if (choisie != null) {
        setState(() => AppClock.definir(choisie));
      }
    }
  }

  static String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes groupes AVEC'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: Text(
                '🧪',
                style: TextStyle(
                  fontSize: 20,
                  color: AppClock.estSimulee ? null : Theme.of(context).disabledColor,
                ),
              ),
              tooltip: AppClock.estSimulee
                  ? 'Date simulée : ${_formatDate(AppClock.now())}'
                  : 'Mode test — simuler une date',
              onPressed: _gererDateSimulee,
            ),
        ],
      ),
      body: FutureBuilder<List<Group>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groupes = snapshot.data!;
          if (groupes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucun groupe pour l'instant. Créez-en un avec le bouton +.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: groupes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final groupe = groupes[index];
              return ListTile(
                title: Text(groupe.name),
                subtitle: Text(
                  'Cycle de ${groupe.cycleDurationMonths} mois · réunions ${groupe.meetingFrequency}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(groupId: groupe.id),
                    ),
                  );
                  _reload();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
          if (created == true) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Créer un groupe'),
      ),
    );
  }
}

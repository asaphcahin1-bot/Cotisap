import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../state/providers.dart';
import 'member_home_screen.dart';

/// Point d'entrée du mode "membre" (skill two-tier-access-model).
/// Recherche tous les enregistrements membre correspondant au numéro
/// saisi à l'écran d'identification — une même personne peut être
/// membre de plusieurs groupes.
class MemberLookupScreen extends ConsumerStatefulWidget {
  const MemberLookupScreen({super.key});

  @override
  ConsumerState<MemberLookupScreen> createState() => _MemberLookupScreenState();
}

class _MemberLookupScreenState extends ConsumerState<MemberLookupScreen> {
  late Future<List<({Member membre, Group groupe})>> _resultatsFuture;

  @override
  void initState() {
    super.initState();
    _resultatsFuture = _rechercher();
  }

  Future<List<({Member membre, Group groupe})>> _rechercher() async {
    final phone = ref.read(currentPhoneNumberProvider);
    if (phone == null) return [];
    final db = ref.read(databaseProvider);
    final membres = await db.membresParTelephone(phone);
    final resultats = <({Member membre, Group groupe})>[];
    for (final membre in membres) {
      final groupe =
          await (db.select(db.groups)..where((g) => g.id.equals(membre.groupId))).getSingle();
      resultats.add((membre: membre, groupe: groupe));
    }
    return resultats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes informations')),
      body: FutureBuilder<List<({Member membre, Group groupe})>>(
        future: _resultatsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final resultats = snapshot.data!;
          if (resultats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ce numéro n\'est enregistré comme membre d\'aucun groupe.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(currentPhoneNumberProvider.notifier).state = null;
                        ref.read(appModeProvider.notifier).state = null;
                      },
                      child: const Text('Recommencer'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: resultats.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = resultats[index];
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(r.membre.fullName),
                subtitle: Text(r.groupe.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MemberHomeScreen(
                      memberId: r.membre.id,
                      groupId: r.groupe.id,
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

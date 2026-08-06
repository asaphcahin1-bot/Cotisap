import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../state/providers.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  late Future<_MembersData> _dataFuture;

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

  Future<_MembersData> _fetch(AppDatabase db) async {
    final membres = await db.membresDuGroupe(widget.groupId);
    final cycle = await db.cycleEnCours(widget.groupId);
    final carnetsParMembre = <String, CarnetsEngage>{};
    if (cycle != null) {
      final tous = await db.carnetsEngagesDuCycle(cycle.id);
      for (final c in tous) {
        carnetsParMembre[c.memberId] = c;
      }
    }
    return _MembersData(membres: membres, cycle: cycle, carnetsParMembre: carnetsParMembre);
  }

  Future<void> _showAddMemberDialog(Cycle? cycle) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final carnetsController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    bool sansTelephone = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un membre'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                ),
                if (!sansTelephone)
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Numéro de téléphone'),
                    validator: (v) => (!sansTelephone && (v == null || v.trim().isEmpty))
                        ? 'Numéro obligatoire'
                        : null,
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Ce membre n\'a aucun téléphone personnel'),
                  subtitle: const Text(
                    "Ses prêts seront confirmés par signature en personne plutôt que "
                    "par SMS, et il n'aura pas accès à l'espace membre en lecture seule.",
                  ),
                  value: sansTelephone,
                  onChanged: (v) => setDialogState(() {
                    sansTelephone = v ?? false;
                    if (sansTelephone) phoneController.clear();
                  }),
                ),
                if (cycle != null) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: carnetsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de carnets pour ce cycle (1 à 5)',
                      helperText: 'Définitif dès le premier paiement de ce membre.',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 1 || n > 5) ? 'Entre 1 et 5' : null;
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Aucun cycle en cours — les carnets se choisiront à l\'ouverture du cycle.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
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
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final db = ref.read(databaseProvider);
      final memberId = await db.ajouterMembre(
        groupId: widget.groupId,
        fullName: nameController.text.trim(),
        phoneNumber: sansTelephone ? null : phoneController.text.trim(),
      );
      if (cycle != null) {
        await db.definirCarnetsEngages(
          groupId: widget.groupId,
          cycleId: cycle.id,
          memberId: memberId,
          partsCount: int.parse(carnetsController.text.trim()),
        );
      }
      _reload();
    }
  }

  Future<void> _showEditCarnetsDialog(Cycle cycle, Member membre, CarnetsEngage? actuel) async {
    if (actuel?.lockedAt != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Carnets verrouillés pour ${membre.fullName} — un premier paiement a déjà '
          'été enregistré sur ce cycle.',
        ),
      ));
      return;
    }
    final controller = TextEditingController(text: '${actuel?.partsCount ?? 1}');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Carnets — ${membre.fullName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nombre de carnets (1 à 5)'),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return (n == null || n < 1 || n > 5) ? 'Entre 1 et 5' : null;
            },
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
    );

    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    await db.definirCarnetsEngages(
      groupId: widget.groupId,
      cycleId: cycle.id,
      memberId: membre.id,
      partsCount: int.parse(controller.text.trim()),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Membres')),
      body: FutureBuilder<_MembersData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.membres.isEmpty) {
            return const Center(child: Text('Aucun membre pour l’instant.'));
          }
          return ListView.separated(
            itemCount: data.membres.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final membre = data.membres[index];
              final phone = membre.phoneNumber;
              final carnets = data.carnetsParMembre[membre.id];
              final sousTitre = StringBuffer(
                phone ?? 'Aucun téléphone — confirmation de prêt par signature',
              );
              if (data.cycle != null) {
                if (carnets == null) {
                  sousTitre.write(' · carnets non définis');
                } else {
                  sousTitre.write(
                    ' · ${carnets.partsCount} carnet(s)'
                    '${carnets.lockedAt != null ? ' (verrouillé)' : ''}',
                  );
                }
              }
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(membre.fullName),
                subtitle: Text(
                  sousTitre.toString(),
                  style: phone == null ? const TextStyle(fontStyle: FontStyle.italic) : null,
                ),
                trailing: data.cycle == null
                    ? null
                    : IconButton(
                        icon: Icon(
                          carnets?.lockedAt != null ? Icons.lock_outline : Icons.edit_outlined,
                        ),
                        tooltip: 'Carnets pour ce cycle',
                        onPressed: () =>
                            _showEditCarnetsDialog(data.cycle!, membre, carnets),
                      ),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<_MembersData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          return FloatingActionButton(
            onPressed: () => _showAddMemberDialog(snapshot.data?.cycle),
            child: const Icon(Icons.person_add_alt_1),
          );
        },
      ),
    );
  }
}

class _MembersData {
  final List<Member> membres;
  final Cycle? cycle;
  final Map<String, CarnetsEngage> carnetsParMembre;

  const _MembersData({required this.membres, required this.cycle, required this.carnetsParMembre});
}

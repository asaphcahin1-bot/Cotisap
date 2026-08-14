import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../state/providers.dart';
import '../cotisations/cotisation_membre_screen.dart';

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
    final serieController = TextEditingController();
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
                    controller: serieController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro du carnet physique (optionnel)',
                      helperText:
                          'Laisser vide pour générer un numéro automatiquement '
                          '— corrigeable plus tard.',
                    ),
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

    if (saved != true) return;
    final db = ref.read(databaseProvider);
    try {
      final memberId = await db.ajouterMembre(
        groupId: widget.groupId,
        fullName: nameController.text.trim(),
        phoneNumber: sansTelephone ? null : phoneController.text.trim(),
      );
      if (cycle != null) {
        // Un membre = un seul carnet, toujours (voir DECISIONS.md).
        await db.definirCarnetsEngages(
          groupId: widget.groupId,
          cycleId: cycle.id,
          memberId: memberId,
        );
        // Numéro de série manuel — voir RETOURS_TERRAIN.md : le carnet
        // physique du membre a déjà son propre numéro, l'agent doit
        // pouvoir le saisir tel quel plutôt que garder celui généré
        // automatiquement.
        await _appliquerNumerosSerieSaisis(memberId, {
          1: serieController.text.trim(),
        });
      }
      _reload();
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  /// Applique les numéros de série saisis manuellement par l'agent —
  /// ignore silencieusement une entrée vide (le numéro auto-généré par
  /// `definirCarnetsEngages`/`genererOuRecupererCarnet` reste alors en
  /// place). Affiche un message si un numéro est déjà pris par un autre
  /// carnet du groupe, sans bloquer le reste de l'opération.
  Future<void> _appliquerNumerosSerieSaisis(
    String memberId,
    Map<int, String> numerosSaisis,
  ) async {
    final db = ref.read(databaseProvider);
    for (final entry in numerosSaisis.entries) {
      if (entry.value.isEmpty) continue;
      try {
        await db.redefinirNumeroSerieCarnet(
          memberId: memberId,
          carnetNumero: entry.key,
          nouveauNumeroSerie: entry.value,
        );
      } on StateError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
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
    final db = ref.read(databaseProvider);
    final carnetExistant = await db.carnetDuMembre(
      memberId: membre.id,
      carnetNumero: 1,
    );
    final serieController = TextEditingController(
      text: carnetExistant?.numeroSerie ?? '',
    );
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Carnet — ${membre.fullName}'),
        content: TextFormField(
          controller: serieController,
          decoration: const InputDecoration(
            labelText: 'Numéro du carnet physique (optionnel)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    // Un membre = un seul carnet, toujours (voir DECISIONS.md).
    await db.definirCarnetsEngages(
      groupId: widget.groupId,
      cycleId: cycle.id,
      memberId: membre.id,
    );
    await _appliquerNumerosSerieSaisis(membre.id, {
      1: serieController.text.trim(),
    });
    _reload();
  }

  /// Ouvre l'écran Cotisation sur ce membre — voir DECISIONS.md,
  /// "Renommage 'Cotisation' → 'Épargne'" : fusionné avec l'ancienne
  /// fiche membre consolidée (`MemberSessionScreen`, retirée), les deux
  /// écrans faisant désormais la même chose en parallèle. N'a de sens
  /// que sur un cycle en cours (cotisations, amendes et prêts sont tous
  /// rattachés à un cycle) ; sans cycle, un simple message oriente vers
  /// l'écran Membres pour créer le cycle d'abord.
  void _openFicheMembre(Cycle? cycle, List<Member> membres, Member membre) {
    if (cycle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun cycle en cours — ouvrez un cycle avant de consulter la '
            'fiche d\'un membre.',
          ),
        ),
      );
      return;
    }
    final index = membres.indexWhere((m) => m.id == membre.id);
    if (index == -1) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CotisationMembreScreen(
              groupId: widget.groupId,
              cycleId: cycle.id,
              membres: membres,
              initialIndex: index,
            ),
          ),
        )
        .then((_) => _reload());
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
                  sousTitre.write(' · carnet non engagé pour ce cycle');
                } else {
                  sousTitre.write(
                    ' · carnet engagé'
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
                onTap: () => _openFicheMembre(data.cycle, data.membres, membre),
                trailing: data.cycle == null
                    ? null
                    : IconButton(
                        icon: Icon(
                          carnets?.lockedAt != null ? Icons.lock_outline : Icons.edit_outlined,
                        ),
                        tooltip: 'Carnet pour ce cycle',
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

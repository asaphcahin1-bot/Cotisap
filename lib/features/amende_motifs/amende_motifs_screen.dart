import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../state/providers.dart';

/// Gestion du catalogue de motifs d'amende du groupe (voir DECISIONS.md,
/// "Catalogue de motifs d'amende") — libellé + montant, activable ou
/// désactivable. Purement de la configuration : modifier ou désactiver
/// un motif ici ne change jamais une amende déjà enregistrée.
class AmendeMotifsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AmendeMotifsScreen({super.key, required this.groupId});

  @override
  ConsumerState<AmendeMotifsScreen> createState() => _AmendeMotifsScreenState();
}

class _AmendeMotifsScreenState extends ConsumerState<AmendeMotifsScreen> {
  late Future<List<MotifsAmendeData>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final db = ref.read(databaseProvider);
    setState(() {
      _dataFuture = db.motifsAmendeDuGroupe(widget.groupId);
    });
  }

  Future<void> _showEditDialog({MotifsAmendeData? existant}) async {
    final libelleController = TextEditingController(
      text: existant?.libelle ?? '',
    );
    final montantController = TextEditingController(
      text: existant == null ? '' : existant.montantFcfa.toString(),
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existant == null ? 'Nouveau motif' : 'Modifier — ${existant.libelle}',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: libelleController,
                decoration: const InputDecoration(
                  labelText: 'Libellé (ex : Bavardage)',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Libellé obligatoire'
                    : null,
              ),
              TextFormField(
                controller: montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Montant invalide' : null;
                },
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
              if (formKey.currentState!.validate())
                Navigator.of(context).pop(true);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    final libelle = libelleController.text.trim();
    final montant = int.parse(montantController.text.trim());
    if (existant == null) {
      await db.creerMotifAmende(
        groupId: widget.groupId,
        libelle: libelle,
        montantFcfa: montant,
      );
    } else {
      await db.modifierMotifAmende(
        motifId: existant.id,
        libelle: libelle,
        montantFcfa: montant,
      );
    }
    _reload();
  }

  Future<void> _toggleActif(MotifsAmendeData motif) async {
    final db = ref.read(databaseProvider);
    await db.definirActifMotifAmende(motifId: motif.id, actif: !motif.actif);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Motifs d\'amende')),
      body: FutureBuilder<List<MotifsAmendeData>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final motifs = snapshot.data!;
          if (motifs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun motif configuré pour le moment — la saisie d\'une amende '
                  'reste possible avec un motif et un montant libres.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: motifs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final motif = motifs[index];
              return ListTile(
                leading: Icon(
                  motif.actif
                      ? Icons.rule_outlined
                      : Icons.rule_folder_outlined,
                ),
                title: Text(
                  motif.libelle,
                  style: motif.actif
                      ? null
                      : const TextStyle(color: Colors.grey),
                ),
                subtitle: Text(
                  '${formatFcfa(motif.montantFcfa)}${motif.actif ? '' : ' · désactivé'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Modifier',
                      onPressed: () => _showEditDialog(existant: motif),
                    ),
                    Switch(
                      value: motif.actif,
                      onChanged: (_) => _toggleActif(motif),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        tooltip: 'Nouveau motif',
        child: const Icon(Icons.add),
      ),
    );
  }
}

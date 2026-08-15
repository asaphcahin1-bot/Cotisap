import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_clock.dart';
import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../state/providers.dart';

/// Écran "Cotisations exceptionnelles" — déclarer un événement
/// (mariage, décès, accouchement) et suivre la collecte, voir
/// DECISIONS.md, "Cotisations exceptionnelles" et RETOURS_TERRAIN.md,
/// point 7. Le règlement individuel se fait depuis l'écran Cotisation
/// (`cotisation_membre_screen.dart`) — cet écran ne fait que déclarer
/// et donner une vue d'ensemble.
class CotisationsExceptionnellesScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const CotisationsExceptionnellesScreen({
    super.key,
    required this.groupId,
    required this.cycleId,
  });

  @override
  ConsumerState<CotisationsExceptionnellesScreen> createState() =>
      _CotisationsExceptionnellesScreenState();
}

class _CotisationsExceptionnellesScreenState
    extends ConsumerState<CotisationsExceptionnellesScreen> {
  late Future<List<_EvtAvecResume>> _dataFuture;

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

  Future<List<_EvtAvecResume>> _fetch(AppDatabase db) async {
    // Déduction automatique du solde restant à la date limite — voir
    // RETOURS_TERRAIN.md, point 25.4. Idempotent (voir la doc de la
    // méthode), donc sûr de rappeler à chaque ouverture de l'écran.
    await db.appliquerDeductionsCotisationsExceptionnellesEchues(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      agentPhone: ref.read(currentPhoneNumberProvider) ?? 'inconnu',
    );
    final evts = await db.cotisationsExceptionnellesDuCycle(widget.cycleId);
    final resultat = <_EvtAvecResume>[];
    for (final evt in evts) {
      final resume = await db.resumeCotisationExceptionnelle(evt);
      resultat.add(_EvtAvecResume(evt: evt, resume: resume));
    }
    return resultat;
  }

  /// Formulaire partagé déclaration/modification — voir
  /// [_declarerEvenement] et [_modifierEvenement]. [existing] non nul
  /// pré-remplit les champs pour une modification (voir DECISIONS.md,
  /// "Cotisations exceptionnelles" mis à jour — motif/montant/date
  /// limite restent modifiables ensuite, contrairement aux paiements
  /// déjà enregistrés contre l'événement, eux définitifs).
  Future<({String motif, int montantFcfa, DateTime dateLimite})?>
  _showEventForm({CotisationsExceptionnelle? existing}) async {
    final motifController = TextEditingController(text: existing?.motif);
    final montantController = TextEditingController(
      text: existing?.montantFcfa.toString(),
    );
    DateTime dateLimite =
        existing?.dateLimite ?? AppClock.now().add(const Duration(days: 30));
    final formKey = GlobalKey<FormState>();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? 'Déclarer une cotisation exceptionnelle'
                : 'Modifier — ${existing.motif}',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null
                      ? "S'applique automatiquement à tous les membres déjà "
                            "présents dans le groupe — le montant et la date "
                            "limite restent modifiables ensuite."
                      : "Les paiements déjà enregistrés contre cet événement "
                            "ne sont pas affectés par cette modification.",
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: motifController,
                  decoration: const InputDecoration(
                    labelText: 'Événement (ex. "Mariage de Awa Koné")',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Motif obligatoire'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: montantController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant par membre (FCFA)',
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n <= 0) ? 'Montant invalide' : null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final choisie = await showDatePicker(
                      context: context,
                      initialDate: dateLimite,
                      firstDate: DateTime(2020),
                      lastDate: AppClock.now().add(const Duration(days: 730)),
                    );
                    if (choisie != null) {
                      setDialogState(() => dateLimite = choisie);
                    }
                  },
                  child: Text(
                    'Date limite : ${dateLimite.day}/${dateLimite.month}/${dateLimite.year}',
                  ),
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
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Text(existing == null ? 'Déclarer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (confirme != true) return null;
    return (
      motif: motifController.text.trim(),
      montantFcfa: int.parse(montantController.text.trim()),
      dateLimite: dateLimite,
    );
  }

  Future<void> _declarerEvenement() async {
    final saisie = await _showEventForm();
    if (saisie == null) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.enregistrerCotisationExceptionnelle(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      motif: saisie.motif,
      montantFcfa: saisie.montantFcfa,
      dateLimite: saisie.dateLimite,
      createdByPhone: agentPhone,
    );
    _reload();
  }

  Future<void> _modifierEvenement(CotisationsExceptionnelle evt) async {
    final saisie = await _showEventForm(existing: evt);
    if (saisie == null) return;
    final db = ref.read(databaseProvider);
    await db.modifierCotisationExceptionnelle(
      id: evt.id,
      motif: saisie.motif,
      montantFcfa: saisie.montantFcfa,
      dateLimite: saisie.dateLimite,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotisations exceptionnelles')),
      body: FutureBuilder<List<_EvtAvecResume>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(
              child: Text('Aucune cotisation exceptionnelle déclarée.'),
            );
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = data[index];
              final evt = item.evt;
              final resume = item.resume;
              final totalAttendu = resume.membresEligibles * evt.montantFcfa;
              final echue = evt.dateLimite.isBefore(AppClock.now());
              return ListTile(
                title: Text(evt.motif),
                subtitle: Text(
                  '${formatFcfa(evt.montantFcfa)} par membre — '
                  '${resume.membresEligibles} membre(s) concerné(s)\n'
                  'Collecté : ${formatFcfa(resume.totalCollecteFcfa)} '
                  '/ ${formatFcfa(totalAttendu)} — date limite '
                  '${evt.dateLimite.day}/${evt.dateLimite.month}/${evt.dateLimite.year}'
                  '${echue ? ' (dépassée)' : ''}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      resume.totalCollecteFcfa >= totalAttendu
                          ? Icons.check_circle
                          : (echue
                                ? Icons.error_outline
                                : Icons.hourglass_top),
                      color: resume.totalCollecteFcfa >= totalAttendu
                          ? Colors.green
                          : (echue
                                ? Theme.of(context).colorScheme.error
                                : Colors.orange),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Modifier le montant ou la date limite',
                      onPressed: () => _modifierEvenement(evt),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _declarerEvenement,
        icon: const Icon(Icons.add),
        label: const Text('Déclarer un événement'),
      ),
    );
  }
}

class _EvtAvecResume {
  final CotisationsExceptionnelle evt;
  final ({int membresEligibles, int totalCollecteFcfa}) resume;

  const _EvtAvecResume({required this.evt, required this.resume});
}

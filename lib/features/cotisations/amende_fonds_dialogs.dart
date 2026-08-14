import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../../data/local/database.dart';

/// Dialogues "Ajouter une amende" et "Contribution — fonds de
/// solidarité", partagés entre l'écran Répartition
/// (`cycle_summary_screen.dart`) et l'écran Cotisations
/// (`record_cotisation_screen.dart` — voir DECISIONS.md, "Écran
/// Cotisations moins chargé" : ces deux actions doivent aussi être
/// accessibles directement pendant la saisie des encaissements, pas
/// seulement depuis l'écran Répartition). Un seul et même code, jamais
/// dupliqué entre les deux écrans.
const autreMotifSentinel = '__autre__';

/// Demande le mode de paiement d'une amende **au moment où elle est
/// posée** — juste une question de rythme, plus un choix définitif
/// (voir RETOURS_TERRAIN.md, point 4, "Règlement d'une amende à tout
/// moment" : annule et remplace l'ancienne règle "plus tard = déduite
/// automatiquement, plus jamais réglable cash") : `true` = cash,
/// réglée sur-le-champ ; `false` = pas encore réglée pour l'instant —
/// reste payable en cash à tout moment ensuite (bouton "Payer" sur la
/// fiche membre ou l'écran Amendes), et si jamais rien n'est payé
/// avant la clôture du cycle, le solde restant est alors déduit
/// automatiquement (mécanisme inchangé, voir `AmendeReductionCalculator`).
/// Pas de bouton "annuler" : l'amende existe déjà à ce stade, un choix
/// est obligatoire.
Future<bool> askAmendePaymentMode(BuildContext context) async {
  final cash = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Mode de paiement de l\'amende'),
      content: const Text(
        'Le membre paie-t-il cette amende maintenant ? Si non, elle reste '
        'payable en cash à tout moment plus tard (fiche membre ou écran '
        'Amendes) — et sera automatiquement déduite de son épargne si '
        'rien n\'est payé avant la clôture du cycle.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Pas maintenant'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cash aujourd\'hui'),
        ),
      ],
    ),
  );
  return cash ?? false;
}

/// [motifsCatalogue] : voir DECISIONS.md, "Catalogue de motifs
/// d'amende" — choisir un motif du catalogue pré-remplit libellé et
/// montant (les deux restent modifiables) ; "Autre" garde la saisie
/// entièrement libre d'avant, pour les cas hors catalogue. Un groupe
/// sans aucun motif configuré retrouve exactement l'ancien formulaire
/// (motif + montant libres).
///
/// Une fois le formulaire validé, demande immédiatement le mode de
/// paiement (voir [askAmendePaymentMode], DECISIONS.md "Mode de
/// paiement de l'amende demandé immédiatement") — jamais laissée en
/// attente d'un choix ultérieur.
Future<void> showAddAmendeDialog({
  required BuildContext context,
  required AppDatabase db,
  required String groupId,
  required String cycleId,
  required String agentPhone,
  required List<Member> membres,
  required List<MotifsAmendeData> motifsCatalogue,
  required VoidCallback onSaved,
  String? memberIdInitial,
}) async {
  String? memberId = memberIdInitial;
  String? motifChoisi;
  final montantController = TextEditingController();
  final motifController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Ajouter une amende'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: memberId,
                  decoration: const InputDecoration(labelText: 'Membre'),
                  items: membres
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => memberId = v),
                  validator: (v) => v == null ? 'Choisir un membre' : null,
                ),
                if (motifsCatalogue.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: motifChoisi,
                    decoration: const InputDecoration(labelText: 'Motif'),
                    items: [
                      ...motifsCatalogue.map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(
                            '${m.libelle} — ${formatFcfa(m.montantFcfa)}',
                          ),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: autreMotifSentinel,
                        child: Text('Autre (préciser)'),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() {
                      motifChoisi = v;
                      if (v == null || v == autreMotifSentinel) {
                        motifController.clear();
                        montantController.clear();
                      } else {
                        final motif = motifsCatalogue.firstWhere(
                          (m) => m.id == v,
                        );
                        motifController.text = motif.libelle;
                        montantController.text = motif.montantFcfa.toString();
                      }
                    }),
                    validator: (v) => v == null ? 'Choisir un motif' : null,
                  ),
                ],
                if (motifsCatalogue.isEmpty ||
                    motifChoisi == autreMotifSentinel) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: motifController,
                    decoration: const InputDecoration(labelText: 'Motif'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Motif obligatoire'
                        : null,
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: montantController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (FCFA)',
                  ),
                  validator: (v) => (int.tryParse(v ?? '') == null)
                      ? 'Montant invalide'
                      : null,
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
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || memberId == null) return;
  final amendeId = await db.enregistrerAmende(
    groupId: groupId,
    cycleId: cycleId,
    memberId: memberId!,
    montantFcfa: int.parse(montantController.text.trim()),
    motif: motifController.text.trim(),
    recordedByPhone: agentPhone,
  );
  if (!context.mounted) {
    onSaved();
    return;
  }
  final cash = await askAmendePaymentMode(context);
  if (cash) {
    await db.confirmerAmende(amendeId);
  }
  onSaved();
}

Future<void> showAddFondsDialog({
  required BuildContext context,
  required AppDatabase db,
  required String groupId,
  required String cycleId,
  required String agentPhone,
  required List<Member> membres,
  required VoidCallback onSaved,
}) async {
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
                decoration: const InputDecoration(
                  labelText: 'Membre (optionnel)',
                ),
                items: membres
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => memberId = v),
              ),
              TextFormField(
                controller: montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                validator: (v) =>
                    (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
              ),
              TextFormField(
                controller: motifController,
                decoration: const InputDecoration(labelText: 'Motif'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Motif obligatoire'
                    : null,
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return;
  await db.enregistrerContributionFondsSolidarite(
    groupId: groupId,
    cycleId: cycleId,
    memberId: memberId,
    montantFcfa: int.parse(montantController.text.trim()),
    motif: motifController.text.trim(),
    recordedByPhone: agentPhone,
  );
  onSaved();
}

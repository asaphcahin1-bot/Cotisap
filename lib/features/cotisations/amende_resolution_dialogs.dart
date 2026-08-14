import 'package:flutter/material.dart';

import '../../core/app_clock.dart';
import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/echeance_calculator.dart';

/// Dialogues "Payer" et "Corriger" une amende — partagés entre l'écran
/// Cotisation (`cotisation_membre_screen.dart`) et l'écran Amendes
/// dédié (`amendes_screen.dart`) — voir DECISIONS.md, "Section Amendes
/// dédiée" : un seul et même code, jamais dupliqué entre les deux
/// écrans (même principe que `amende_fonds_dialogs.dart` et
/// `loan_repayment_dialog.dart`).

/// Solde restant proposé par défaut — un tap suffit pour un paiement
/// intégral, modifiable pour un paiement partiel (voir DECISIONS.md,
/// "Paiement partiel d'une amende").
Future<void> showPayerAmendeDialog({
  required BuildContext context,
  required AppDatabase db,
  required Amende amende,
  required int solde,
  required String agentPhone,
  required VoidCallback onSaved,
}) async {
  final montantController = TextEditingController(text: solde.toString());
  final formKey = GlobalKey<FormState>();

  final confirme = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Payer — ${amende.motif}'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: montantController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Montant payé (FCFA)',
            helperText: 'Solde restant : ${formatFcfa(solde)}',
          ),
          validator: (v) {
            final montant = int.tryParse(v ?? '');
            if (montant == null || montant <= 0) return 'Montant invalide';
            if (montant > solde) {
              return 'Ne peut pas dépasser le solde (${formatFcfa(solde)})';
            }
            return null;
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
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
  if (confirme != true) return;

  await db.enregistrerPaiementAmende(
    amendeId: amende.id,
    montantFcfa: int.parse(montantController.text.trim()),
    recordedByPhone: agentPhone,
  );
  onSaved();
}

/// Le membre avait en réalité payé cette échéance : annule l'amende
/// posée par erreur (typiquement par le système, à la clôture — voir
/// DECISIONS.md, "Clôture de journée interactive") et enregistre sa
/// cotisation manquante, à la vraie date du paiement.
Future<void> showCorrigerAmendeErreurDialog({
  required BuildContext context,
  required AppDatabase db,
  required String groupId,
  required String cycleId,
  required String memberId,
  required String membreNom,
  required Amende amende,
  required String agentPhone,
  required VoidCallback onSaved,
}) async {
  final partsController = TextEditingController(text: '1');
  DateTime dateReelle = amende.echeanceDate ?? amende.recordedAt;
  final formKey = GlobalKey<FormState>();

  final confirme = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Corriger — $membreNom'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "L'amende sera annulée et son épargne manquante enregistrée "
                "à la vraie date du paiement.",
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final choisie = await showDatePicker(
                    context: context,
                    initialDate: dateReelle,
                    firstDate: DateTime(2000),
                    lastDate: AppClock.now(),
                  );
                  if (choisie != null) {
                    setDialogState(() => dateReelle = choisie);
                  }
                },
                child: Text(
                  'Date réelle du paiement : '
                  '${dateReelle.day}/${dateReelle.month}/${dateReelle.year}',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: partsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre de parts (1 à 5)',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null ||
                          n < 1 ||
                          n > EcheanceCalculator.maxPartsParTransaction)
                      ? 'Entre 1 et ${EcheanceCalculator.maxPartsParTransaction}'
                      : null;
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
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Corriger'),
          ),
        ],
      ),
    ),
  );

  if (confirme != true) return;
  await db.corrigerAmendeErreur(
    amendeId: amende.id,
    raison:
        'Le membre avait en fait payé — épargne non enregistrée à temps',
    annuleParPhone: agentPhone,
    groupId: groupId,
    cycleId: cycleId,
    memberId: memberId,
    carnetNumero: amende.carnetNumero,
    partsCount: int.parse(partsController.text.trim()),
    dateReelle: dateReelle,
  );
  onSaved();
}

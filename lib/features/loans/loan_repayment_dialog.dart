import 'package:flutter/material.dart';

import '../../data/local/database.dart';

/// Dialogue "Enregistrer un remboursement" — partagé entre l'écran Prêts
/// (`loans_screen.dart`) et l'écran Cotisation
/// (`cotisation_membre_screen.dart` — voir DECISIONS.md, "Écran
/// Cotisation : un seul écran actionnable par membre"). Un seul et même
/// code, jamais dupliqué entre les deux écrans (même principe que
/// `amende_fonds_dialogs.dart`).
///
/// [montantMaxFcfa] : le montant réellement dû (voir
/// [LoanBalanceCalculator]) — jamais possible de rembourser plus que ça.
/// Null seulement si le solde n'a pas pu être calculé (prêt importé sans
/// durée), auquel cas on ne plafonne pas plutôt que de deviner une
/// limite.
///
/// Renvoie `true` si un remboursement a bien été enregistré (pour que
/// l'appelant recharge ses données), `false`/`null` sinon.
Future<bool> showLoanRepaymentDialog({
  required BuildContext context,
  required AppDatabase db,
  required String pretId,
  required int? montantMaxFcfa,
  required String agentPhone,
}) async {
  final montantController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enregistrer un remboursement'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: montantController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Montant remboursé (FCFA)',
            helperText: montantMaxFcfa != null
                ? 'Montant dû : $montantMaxFcfa FCFA maximum'
                : null,
          ),
          validator: (v) {
            final montant = int.tryParse(v ?? '');
            if (montant == null || montant <= 0) return 'Montant invalide';
            if (montantMaxFcfa != null && montant > montantMaxFcfa) {
              return 'Ne peut pas dépasser le montant dû ($montantMaxFcfa FCFA)';
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

  if (confirmed != true) return false;

  await db.enregistrerRemboursement(
    pretId: pretId,
    montantFcfa: int.parse(montantController.text.trim()),
    recordedByPhone: agentPhone,
  );
  return true;
}

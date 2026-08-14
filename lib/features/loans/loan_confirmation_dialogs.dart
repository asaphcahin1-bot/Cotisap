import 'package:flutter/material.dart';

import '../../data/auth/auth_gateway.dart';
import '../../data/local/database.dart';
import 'signature_pad.dart';

/// Confirmation d'un prêt qui vient d'être créé — nouveau prêt, sortie
/// du rouge ou reconduction au cycle suivant (voir DECISIONS.md, "Dette
/// de prêt au rouge") : un seul flux, partagé entre l'écran Prêts
/// (`loans_screen.dart`) et l'écran de clôture de cycle
/// (`cycle_summary_screen.dart`) — même principe que
/// `loan_repayment_dialog.dart`. Code SMS si le membre a un téléphone,
/// signature en personne sinon (skill member-consent-rules, "cas des
/// membres sans smartphone").
///
/// [pretId] doit déjà porter le bon `confirmationCode` (généré par
/// l'appelant via [AuthGateway.envoyerCode] avant la création du prêt,
/// voir [AppDatabase.enregistrerPret]) — cette fonction ne fait que
/// recueillir et vérifier ce que le membre a reçu/signé.
Future<void> showLoanConfirmationDialog({
  required BuildContext context,
  required AppDatabase db,
  required String pretId,
  required String memberName,
  required String? memberPhone,
  required String agentPhone,
}) {
  if (memberPhone == null) {
    return _showSignatureConfirmDialog(
      context: context,
      db: db,
      pretId: pretId,
      memberName: memberName,
      agentPhone: agentPhone,
    );
  }
  return _showCodeConfirmDialog(
    context: context,
    db: db,
    pretId: pretId,
    memberName: memberName,
    memberPhone: memberPhone,
  );
}

Future<void> _showCodeConfirmDialog({
  required BuildContext context,
  required AppDatabase db,
  required String pretId,
  required String memberName,
  required String memberPhone,
}) async {
  final codeController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmation du prêt'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Un code de confirmation a été envoyé à $memberName au numéro $memberPhone.\n'
              '(mode dev — code de test : ${DevAuthGateway.codeDeTest})',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Code reçu par le membre',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Code obligatoire' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Confirmer'),
        ),
      ],
    ),
  );

  if (result != true) return;

  final ok = await db.confirmerPret(
    pretId: pretId,
    codeSaisi: codeController.text.trim(),
    confirmedByPhone: memberPhone,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? 'Prêt confirmé.' : 'Code incorrect — prêt toujours en attente.',
      ),
    ),
  );
}

/// Confirmation par signature pour un membre sans téléphone (skill
/// member-consent-rules, "cas des membres sans smartphone") — l'agent
/// tend l'appareil au membre, qui signe lui-même à l'écran en sa
/// présence.
Future<void> _showSignatureConfirmDialog({
  required BuildContext context,
  required AppDatabase db,
  required String pretId,
  required String memberName,
  required String agentPhone,
}) async {
  final padKey = GlobalKey<SignaturePadState>();
  String? erreur;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Signature de $memberName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$memberName n'a pas de téléphone personnel — faites-lui signer "
              "ci-dessous, en votre présence, pour confirmer ce prêt.",
            ),
            const SizedBox(height: 12),
            SignaturePad(key: padKey),
            if (erreur != null) ...[
              const SizedBox(height: 8),
              Text(
                erreur!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setDialogState(() => padKey.currentState?.effacer()),
                child: const Text('Effacer'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              if (padKey.currentState?.estVide ?? true) {
                setDialogState(() => erreur = 'Signature obligatoire');
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return;

  await db.confirmerPretParSignature(
    pretId: pretId,
    signatureData: padKey.currentState!.exporter(),
    witnessPhone: agentPhone,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Prêt confirmé par signature.')),
  );
}

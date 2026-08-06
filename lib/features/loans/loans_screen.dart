import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_clock.dart';
import '../../core/formatting.dart';
import '../../data/auth/auth_gateway.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/loan_balance_calculator.dart';
import '../../state/providers.dart';
import 'signature_pad.dart';

class LoansScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const LoansScreen({super.key, required this.groupId, required this.cycleId});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  late Future<_LoansData> _dataFuture;

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

  Future<_LoansData> _fetch(AppDatabase db) async {
    final cycle =
        await (db.select(db.cycles)..where((c) => c.id.equals(widget.cycleId)))
            .getSingle();
    final membres = await db.membresDuGroupe(widget.groupId);
    final prets = await db.pretsDuCycle(widget.cycleId);
    final statuts = <String, bool>{};
    final soldes = <String, LoanBalanceResult>{};
    for (final pret in prets) {
      final confirme = await db.pretEstConfirme(pret.id);
      statuts[pret.id] = confirme;
      if (confirme) {
        final remboursements = await db.remboursementsDuPret(pret.id);
        soldes[pret.id] = const LoanBalanceCalculator().calculer(
          principalFcfa: pret.principalFcfa,
          interestRatePercent: pret.interestRatePercent,
          dureeJours: pret.dureeJours,
          debut: pret.createdAt,
          remboursements: remboursements
              .map((r) => RemboursementSimple(montantFcfa: r.montantFcfa, date: r.recordedAt))
              .toList(),
          maintenant: AppClock.now(),
        );
      }
    }
    return _LoansData(
      cycle: cycle,
      membres: membres,
      prets: prets,
      confirmes: statuts,
      soldes: soldes,
    );
  }

  Future<void> _showNewLoanDialog(_LoansData data) async {
    String? memberId;
    final montantController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau prêt'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: memberId,
                  decoration: const InputDecoration(labelText: 'Emprunteur'),
                  items: data.membres
                      .map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => memberId = v),
                  validator: (v) => v == null ? 'Choisir un membre' : null,
                ),
                TextFormField(
                  controller: montantController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Montant du prêt (FCFA)',
                    helperText: "Taux d'intérêt du cycle : ${data.cycle.interestRatePercent} %",
                  ),
                  validator: (v) =>
                      (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
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

    if (confirmed != true || memberId == null) return;

    final db = ref.read(databaseProvider);
    final authGateway = ref.read(authGatewayProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    final membre = data.membres.firstWhere((m) => m.id == memberId);
    final phoneMembre = membre.phoneNumber;

    final code = phoneMembre == null ? null : await authGateway.envoyerCode(phoneMembre);
    final resultat = await db.enregistrerPret(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      memberId: memberId!,
      principalFcfa: int.parse(montantController.text.trim()),
      interestRatePercent: data.cycle.interestRatePercent,
      initiatedByPhone: agentPhone,
      confirmationCode: code,
      dureeJours: data.cycle.loanDurationDays,
    );

    _reload();
    if (!mounted) return;
    if (phoneMembre == null) {
      await _showSignatureConfirmDialog(resultat.pretId, membre.fullName);
    } else {
      await _showConfirmDialog(resultat.pretId, membre.fullName, phoneMembre);
    }
  }

  Future<void> _showConfirmDialog(String pretId, String memberName, String memberPhone) async {
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
                decoration: const InputDecoration(labelText: 'Code reçu par le membre'),
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

    final db = ref.read(databaseProvider);
    final ok = await db.confirmerPret(
      pretId: pretId,
      codeSaisi: codeController.text.trim(),
      confirmedByPhone: memberPhone,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Prêt confirmé.' : 'Code incorrect — prêt toujours en attente.')),
    );
    _reload();
  }

  /// Confirmation par signature pour un membre sans téléphone (skill
  /// member-consent-rules, "cas des membres sans smartphone") — l'agent
  /// tend l'appareil au membre, qui signe lui-même à l'écran en sa
  /// présence.
  Future<void> _showSignatureConfirmDialog(String pretId, String memberName) async {
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
                Text(erreur!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setDialogState(() => padKey.currentState?.effacer()),
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

    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.confirmerPretParSignature(
      pretId: pretId,
      signatureData: padKey.currentState!.exporter(),
      witnessPhone: agentPhone,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prêt confirmé par signature.')),
    );
    _reload();
  }

  /// [montantMaxFcfa] : le montant réellement dû (voir
  /// [LoanBalanceCalculator]) — jamais possible de rembourser plus que
  /// ça. Null seulement si le solde n'a pas pu être calculé (prêt
  /// importé sans durée), auquel cas on ne plafonne pas plutôt que de
  /// deviner une limite.
  Future<void> _showRepaymentDialog(String pretId, int? montantMaxFcfa) async {
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
              helperText: montantMaxFcfa != null ? 'Montant dû : $montantMaxFcfa FCFA maximum' : null,
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

    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.enregistrerRemboursement(
      pretId: pretId,
      montantFcfa: int.parse(montantController.text.trim()),
      recordedByPhone: agentPhone,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prêts')),
      body: FutureBuilder<_LoansData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.prets.isEmpty) {
            return const Center(child: Text('Aucun prêt sur ce cycle.'));
          }
          final membresParId = {for (final m in data.membres) m.id: m};
          return ListView.separated(
            itemCount: data.prets.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final pret = data.prets[index];
              final confirme = data.confirmes[pret.id] ?? false;
              final membre = membresParId[pret.memberId];
              final solde = data.soldes[pret.id];
              final ligneStatut = [
                if (pret.provenance == 'importe') 'Importé' else if (confirme) 'Confirmé' else 'En attente de confirmation',
                'intérêt ${pret.interestRatePercent} %',
                if (pret.estApproximatif) 'approximatif',
              ].join(' · ');
              return ListTile(
                leading: Icon(
                  confirme ? Icons.check_circle : Icons.hourglass_top,
                  color: confirme ? Colors.green : Colors.orange,
                ),
                title: Text('${membre?.fullName ?? pret.memberId} — emprunté ${formatFcfa(pret.principalFcfa)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ligneStatut),
                    if (solde != null) ...[
                      Text(
                        solde.montantDuFcfa > 0
                            ? 'Dû actuellement : ${formatFcfa(solde.montantDuFcfa)}'
                            : 'Soldé',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: solde.montantDuFcfa > 0
                              ? Theme.of(context).colorScheme.error
                              : Colors.green,
                        ),
                      ),
                      if (solde.montantDuFcfa > 0 && solde.joursRestantsPeriodeCourante != null)
                        Text(
                          solde.joursRestantsPeriodeCourante! >= 0
                              ? 'Prochaine échéance dans ${solde.joursRestantsPeriodeCourante} jour(s)'
                              : 'Échéance dépassée de ${-solde.joursRestantsPeriodeCourante!} jour(s)',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ],
                ),
                isThreeLine: solde != null,
                trailing: confirme
                    ? (solde != null && solde.montantDuFcfa == 0
                        ? null // soldé — plus rien à rembourser
                        : TextButton(
                            onPressed: () =>
                                _showRepaymentDialog(pret.id, solde?.montantDuFcfa),
                            child: const Text('Remboursement'),
                          ))
                    : TextButton(
                        onPressed: () {
                          final phoneMembre = membre?.phoneNumber;
                          if (phoneMembre == null) {
                            _showSignatureConfirmDialog(pret.id, membre?.fullName ?? '');
                          } else {
                            _showConfirmDialog(pret.id, membre?.fullName ?? '', phoneMembre);
                          }
                        },
                        child: const Text('Confirmer'),
                      ),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<_LoansData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showNewLoanDialog(snapshot.data!),
            icon: const Icon(Icons.add),
            label: const Text('Nouveau prêt'),
          );
        },
      ),
    );
  }
}

class _LoansData {
  final Cycle cycle;
  final List<Member> membres;
  final List<Pret> prets;
  final Map<String, bool> confirmes;
  final Map<String, LoanBalanceResult> soldes;

  const _LoansData({
    required this.cycle,
    required this.membres,
    required this.prets,
    required this.confirmes,
    required this.soldes,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

const _frequences = ['hebdomadaire', 'bimensuelle', 'mensuelle'];

const _joursSemaine = [
  (1, 'Lundi'),
  (2, 'Mardi'),
  (3, 'Mercredi'),
  (4, 'Jeudi'),
  (5, 'Vendredi'),
  (6, 'Samedi'),
  (7, 'Dimanche'),
];

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _partValueController = TextEditingController(text: '1000');
  final _interestController = TextEditingController(text: '10');
  final _lateFeeController = TextEditingController(text: '0');
  final _loanDurationController = TextEditingController(text: '90');
  final _dayOfMonth1Controller = TextEditingController();
  final _dayOfMonth2Controller = TextEditingController();
  int _cycleDurationMonths = 9;
  String _meetingFrequency = 'mensuelle';
  int? _paymentDayOfWeek;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _partValueController.dispose();
    _interestController.dispose();
    _lateFeeController.dispose();
    _loanDurationController.dispose();
    _dayOfMonth1Controller.dispose();
    _dayOfMonth2Controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final groupId = await db.creerGroupe(
      name: _nameController.text.trim(),
      cycleDurationMonths: _cycleDurationMonths,
      meetingFrequency: _meetingFrequency,
      paymentDayOfWeek: _meetingFrequency == 'hebdomadaire' ? _paymentDayOfWeek : null,
      paymentDayOfMonth1: _meetingFrequency == 'mensuelle' || _meetingFrequency == 'bimensuelle'
          ? int.tryParse(_dayOfMonth1Controller.text.trim())
          : null,
      paymentDayOfMonth2: _meetingFrequency == 'bimensuelle'
          ? int.tryParse(_dayOfMonth2Controller.text.trim())
          : null,
    );
    await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: int.parse(_partValueController.text.trim()),
      interestRatePercent: double.parse(_interestController.text.trim()),
      lateFeeFcfa: int.parse(_lateFeeController.text.trim()),
      loanDurationDays: int.parse(_loanDurationController.text.trim()),
    );
    final creatorPhone = ref.read(currentPhoneNumberProvider);
    if (creatorPhone != null) {
      await db.affecterRole(groupId: groupId, phoneNumber: creatorPhone, role: 'agent');
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau groupe AVEC')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du groupe',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _cycleDurationMonths,
              decoration: const InputDecoration(
                labelText: 'Durée du cycle',
                border: OutlineInputBorder(),
              ),
              items: [9, 10, 11, 12]
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m mois')))
                  .toList(),
              onChanged: (v) => setState(() => _cycleDurationMonths = v ?? 9),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _meetingFrequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence des réunions',
                border: OutlineInputBorder(),
              ),
              items: _frequences
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _meetingFrequency = v ?? 'mensuelle'),
            ),
            const SizedBox(height: 16),
            // Jour de paiement fixe (skill avec-business-rules) : la
            // cotisation tombe toujours ce jour précis, pas une simple
            // période glissante.
            if (_meetingFrequency == 'hebdomadaire')
              DropdownButtonFormField<int>(
                initialValue: _paymentDayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Jour de paiement',
                  border: OutlineInputBorder(),
                ),
                items: _joursSemaine
                    .map((j) => DropdownMenuItem(value: j.$1, child: Text(j.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentDayOfWeek = v),
                validator: (v) => v == null ? 'Choisir un jour' : null,
              ),
            if (_meetingFrequency == 'mensuelle')
              TextFormField(
                controller: _dayOfMonth1Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jour du mois pour la cotisation (1 à 31)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final jour = int.tryParse(v ?? '');
                  return (jour == null || jour < 1 || jour > 31) ? 'Jour invalide' : null;
                },
              ),
            if (_meetingFrequency == 'bimensuelle') ...[
              TextFormField(
                controller: _dayOfMonth1Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '1er jour du mois pour la cotisation (1 à 31)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final jour = int.tryParse(v ?? '');
                  return (jour == null || jour < 1 || jour > 31) ? 'Jour invalide' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dayOfMonth2Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '2e jour du mois pour la cotisation (1 à 31)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final jour = int.tryParse(v ?? '');
                  return (jour == null || jour < 1 || jour > 31) ? 'Jour invalide' : null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _partValueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Valeur d'un carnet (FCFA) — cycle 1",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Taux d'intérêt des prêts (%) — cycle 1",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (double.tryParse(v ?? '') == null) ? 'Taux invalide' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loanDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Durée d'une période de prêt (jours) — cycle 1",
                helperText:
                    "Si un prêt n'est pas totalement remboursé à l'échéance, le taux "
                    "se réapplique au solde restant pour une nouvelle période de même durée.",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final jours = int.tryParse(v ?? '');
                return (jours == null || jours < 1) ? 'Durée invalide' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lateFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amende de retard de cotisation (FCFA) — cycle 1',
                helperText: '0 si le groupe ne prévoit pas d\'amende automatique',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer le groupe'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting.dart';
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
  final _loanDurationController = TextEditingController(text: '90');
  final _amendeAbsenceController = TextEditingController(text: '0');
  final _amendePartImpayeeController = TextEditingController(text: '0');
  final _amendePayeParTiersController = TextEditingController(text: '0');
  final _solidariteObligatoireController = TextEditingController(text: '0');
  final _dayOfMonth1Controller = TextEditingController();
  final _dayOfMonth2Controller = TextEditingController();
  int _cycleDurationMonths = 9;
  String _meetingFrequency = 'mensuelle';
  int? _paymentDayOfWeek;
  bool _saving = false;

  // Un GlobalKey par champ validé, dans l'ordre d'affichage — voir
  // RETOURS_TERRAIN.md, point 3 : un champ oublié est déjà souligné en
  // rouge par Flutter (Form.validate()), mais sur un long formulaire il
  // peut rester hors écran sans que l'agent le remarque. En cas
  // d'échec, on fait défiler jusqu'au premier champ invalide plutôt que
  // de se contenter du soulignement (voir _submit / _scrollToFirstError).
  final _nameKey = GlobalKey();
  final _paymentDayOfWeekKey = GlobalKey();
  final _dayOfMonth1Key = GlobalKey();
  final _dayOfMonth2Key = GlobalKey();
  final _partValueKey = GlobalKey();
  final _interestKey = GlobalKey();
  final _loanDurationKey = GlobalKey();
  final _amendeAbsenceKey = GlobalKey();
  final _amendePartImpayeeKey = GlobalKey();
  final _amendePayeParTiersKey = GlobalKey();
  final _solidariteObligatoireKey = GlobalKey();

  @override
  void dispose() {
    _nameController.dispose();
    _partValueController.dispose();
    _interestController.dispose();
    _loanDurationController.dispose();
    _amendeAbsenceController.dispose();
    _amendePartImpayeeController.dispose();
    _amendePayeParTiersController.dispose();
    _solidariteObligatoireController.dispose();
    _dayOfMonth1Controller.dispose();
    _dayOfMonth2Controller.dispose();
    super.dispose();
  }

  /// Fait défiler jusqu'au premier champ dont le `GlobalKey` est monté à
  /// l'écran — appelé uniquement après un `validate()` en échec, dans
  /// l'ordre d'affichage du formulaire, donc trouve bien le premier
  /// champ invalide (les champs non pertinents pour la fréquence
  /// choisie ne sont pas montés, ex. `_dayOfMonth2Key` hors
  /// "bimensuelle" — sans risque puisque leur validateur ne s'exécute
  /// pas non plus dans ce cas).
  void _scrollToFirstError() {
    for (final key in [
      _nameKey,
      _paymentDayOfWeekKey,
      _dayOfMonth1Key,
      _dayOfMonth2Key,
      _partValueKey,
      _interestKey,
      _loanDurationKey,
      _amendeAbsenceKey,
      _amendePartImpayeeKey,
      _amendePayeParTiersKey,
      _solidariteObligatoireKey,
    ]) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final field = ctx.findAncestorStateOfType<FormFieldState>();
      if (field != null && !field.isValid) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.2,
        );
        return;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Des champs sont invalides ou incomplets — corrigez les champs '
            'surlignés en rouge.',
          ),
        ),
      );
      return;
    }
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
      montantAmendeAbsenceFcfa: int.parse(_amendeAbsenceController.text.trim()),
      montantAmendePartImpayeeFcfa:
          int.parse(_amendePartImpayeeController.text.trim()),
      montantAmendePayeParTiersFcfa:
          int.parse(_amendePayeParTiersController.text.trim()),
      montantSolidariteObligatoireFcfa:
          int.parse(_solidariteObligatoireController.text.trim()),
    );
    await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: int.parse(_partValueController.text.trim()),
      interestRatePercent: double.parse(_interestController.text.trim()),
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
              key: _nameKey,
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
              items: [6, 9, 10, 11, 12]
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
                  .map((f) => DropdownMenuItem(value: f, child: Text(formatMeetingFrequency(f))))
                  .toList(),
              onChanged: (v) => setState(() => _meetingFrequency = v ?? 'mensuelle'),
            ),
            const SizedBox(height: 16),
            // Jour de paiement fixe (skill avec-business-rules) : la
            // cotisation tombe toujours ce jour précis, pas une simple
            // période glissante.
            if (_meetingFrequency == 'hebdomadaire')
              DropdownButtonFormField<int>(
                key: _paymentDayOfWeekKey,
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
                key: _dayOfMonth1Key,
                controller: _dayOfMonth1Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jour du mois pour l\'épargne (1 à 31)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final jour = int.tryParse(v ?? '');
                  return (jour == null || jour < 1 || jour > 31) ? 'Jour invalide' : null;
                },
              ),
            if (_meetingFrequency == 'bimensuelle') ...[
              TextFormField(
                key: _dayOfMonth1Key,
                controller: _dayOfMonth1Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '1er jour du mois pour l\'épargne (1 à 31)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final jour = int.tryParse(v ?? '');
                  return (jour == null || jour < 1 || jour > 31) ? 'Jour invalide' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: _dayOfMonth2Key,
                controller: _dayOfMonth2Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '2e jour du mois pour l\'épargne (1 à 31)',
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
              key: _partValueKey,
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
              key: _interestKey,
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
              key: _loanDurationKey,
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
            const SizedBox(height: 24),
            Text(
              'Motifs d\'amende prédéfinis',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Toujours proposés à l\'agent, en plus de ceux qu\'il ajoute '
              'lui-même — modifiables plus tard.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: _amendeAbsenceKey,
              controller: _amendeAbsenceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amende "Absence" (FCFA)',
                helperText:
                    'Le membre n\'est pas présent à la réunion — couvre aussi le '
                    'retard d\'épargne, il n\'y a plus qu\'une seule amende pour ce cas.',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: _amendePartImpayeeKey,
              controller: _amendePartImpayeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amende "Part impayée" (FCFA)',
                helperText: 'Le membre n\'a pas acheté de parts aujourd\'hui.',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: _amendePayeParTiersKey,
              controller: _amendePayeParTiersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amende "Payé par un tiers" (FCFA)',
                helperText:
                    'Le membre est absent, mais quelqu\'un d\'autre a apporté '
                    'son paiement à sa place.',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (int.tryParse(v ?? '') == null) ? 'Montant invalide' : null,
            ),
            const SizedBox(height: 24),
            Text(
              'Fonds de solidarité obligatoire',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Fixé une fois pour toutes — ne pourra plus être modifié ensuite.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: _solidariteObligatoireKey,
              controller: _solidariteObligatoireController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant par carnet, dû à chaque réunion (FCFA)',
                helperText:
                    '0 si le fonds de solidarité reste facultatif pour ce groupe. '
                    'Un membre à 2 carnets doit le double.',
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

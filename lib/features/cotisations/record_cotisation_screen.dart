import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_clock.dart';
import '../../core/formatting.dart';
import '../../data/cotisations/amende_auto_service.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/echeance_calculator.dart';
import '../../state/providers.dart';

/// Une ligne du "brouillon" du jour : un membre + le montant qu'il doit
/// régler, en attente de confirmation groupée (skill member-consent-rules
/// dans l'esprit : rien n'est écrit définitivement avant validation
/// explicite — voir _confirmerEtEnregistrer).
class _LigneBrouillon {
  final Member membre;
  final int montantFcfa;
  final int carnetsCouverts;

  const _LigneBrouillon({
    required this.membre,
    required this.montantFcfa,
    required this.carnetsCouverts,
  });
}

class RecordCotisationScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;

  const RecordCotisationScreen({
    super.key,
    required this.groupId,
    required this.cycleId,
  });

  @override
  ConsumerState<RecordCotisationScreen> createState() =>
      _RecordCotisationScreenState();
}

class _RecordCotisationScreenState extends ConsumerState<RecordCotisationScreen> {
  late Future<List<Member>> _membersFuture;
  late Future<List<Cotisation>> _cotisationsFuture;
  late Future<Cycle> _cycleFuture;
  late Future<Group> _groupFuture;
  late Future<List<({Amende amende, Member membre})>> _amendesRevueFuture;

  String? _selectedMemberId;
  bool _calculEnCours = false;
  String? _erreurCalcul;
  int? _montantCalcule;
  int? _carnetsCouvertsCalcules;
  bool _carnetsNonDefinis = false;

  final List<_LigneBrouillon> _brouillon = [];
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    setState(() {
      _membersFuture = db.membresDuGroupe(widget.groupId);
      _cotisationsFuture = db.cotisationsDuCycle(widget.cycleId);
      _cycleFuture =
          (db.select(db.cycles)..where((c) => c.id.equals(widget.cycleId))).getSingle();
      _groupFuture =
          (db.select(db.groups)..where((g) => g.id.equals(widget.groupId))).getSingle();
      // Détecte et applique les amendes automatiques (échéances closes
      // non couvertes, jamais l'échéance en cours) avant de charger la
      // liste à revoir — voir DECISIONS.md.
      _amendesRevueFuture = AmendeAutoService(db)
          .detecterEtAppliquer(
            groupId: widget.groupId,
            cycleId: widget.cycleId,
            recordedByPhone: agentPhone,
          )
          .then((_) => db.amendesEnAttenteRevue(groupId: widget.groupId, cycleId: widget.cycleId));
      _brouillon.clear();
      _selectedMemberId = null;
      _montantCalcule = null;
    });
  }

  Future<void> _onMemberSelected(String? memberId) async {
    setState(() {
      _selectedMemberId = memberId;
      _montantCalcule = null;
      _carnetsCouvertsCalcules = null;
      _carnetsNonDefinis = false;
      _erreurCalcul = null;
    });
    if (memberId == null) return;

    setState(() => _calculEnCours = true);
    final db = ref.read(databaseProvider);
    try {
      final cycle = await _cycleFuture;
      final groupe = await _groupFuture;
      final carnets =
          await db.carnetsEngagesDuMembre(memberId: memberId, cycleId: widget.cycleId);
      if (carnets == null) {
        setState(() {
          _carnetsNonDefinis = true;
          _calculEnCours = false;
        });
        return;
      }
      final echeances = const EcheanceCalculator().echeancesPassees(
        debutCycle: cycle.startedAt,
        meetingFrequency: groupe.meetingFrequency,
        paymentDayOfWeek: groupe.paymentDayOfWeek,
        paymentDayOfMonth1: groupe.paymentDayOfMonth1,
        paymentDayOfMonth2: groupe.paymentDayOfMonth2,
        maintenant: AppClock.now(),
      );
      final dejaPaye = await db.totalCotiseFcfa(memberId: memberId, cycleId: widget.cycleId);
      final montant = const EcheanceCalculator().soldeDuFcfa(
        echeancesPassees: echeances,
        carnetsEngages: carnets.partsCount,
        valeurCarnetFcfa: cycle.partValueFcfa,
        montantDejaPayeFcfa: dejaPaye,
      );
      if (!mounted) return;
      setState(() {
        _montantCalcule = montant;
        _carnetsCouvertsCalcules = cycle.partValueFcfa == 0 ? 0 : montant ~/ cycle.partValueFcfa;
        _calculEnCours = false;
      });
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() {
        _erreurCalcul = e.message?.toString() ??
            'Jour de paiement non configuré pour ce groupe.';
        _calculEnCours = false;
      });
    }
  }

  void _ajouterAuBrouillon(List<Member> membres) {
    final memberId = _selectedMemberId;
    final montant = _montantCalcule;
    final carnets = _carnetsCouvertsCalcules;
    if (memberId == null || montant == null || carnets == null) return;
    final membre = membres.firstWhere((m) => m.id == memberId);
    setState(() {
      _brouillon.add(_LigneBrouillon(membre: membre, montantFcfa: montant, carnetsCouverts: carnets));
      _selectedMemberId = null;
      _montantCalcule = null;
      _carnetsCouvertsCalcules = null;
    });
  }

  Future<void> _confirmerEtEnregistrer() async {
    if (_brouillon.isEmpty) return;
    final total = _brouillon.fold<int>(0, (s, l) => s + l.montantFcfa);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer les encaissements du jour'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._brouillon.map((l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${l.membre.fullName} — ${formatFcfa(l.montantFcfa)} '
                      '(${l.carnetsCouverts} carnet(s))',
                    ),
                  )),
              const Divider(height: 24),
              Text('Total : ${formatFcfa(total)}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const Text(
                'Vérifiez la liste ci-dessus avant de continuer — une fois '
                'enregistré, cet encaissement sera définitif.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Revoir'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer définitivement'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _enregistrementEnCours = true);
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    for (final ligne in _brouillon) {
      await db.enregistrerCotisationCash(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        memberId: ligne.membre.id,
        partsCount: ligne.carnetsCouverts,
        recordedByPhone: agentPhone,
      );
    }
    setState(() => _enregistrementEnCours = false);
    _reload();
  }

  Future<void> _confirmerAmende(Amende amende) async {
    final db = ref.read(databaseProvider);
    await db.confirmerAmende(amende.id);
    _reload();
  }

  /// Le membre avait en réalité payé cette échéance : annule l'amende
  /// posée par erreur et enregistre sa cotisation manquante, à la vraie
  /// date du paiement (voir DECISIONS.md).
  Future<void> _corrigerAmendeErreur(Amende amende, Member membre) async {
    final db = ref.read(databaseProvider);
    final carnets = await db.carnetsEngagesDuMembre(
        memberId: membre.id, cycleId: widget.cycleId);
    if (!mounted) return;
    final carnetsParDefaut = carnets?.partsCount ?? 1;
    final carnetsController = TextEditingController(text: '$carnetsParDefaut');
    DateTime dateReelle = amende.recordedAt;
    final formKey = GlobalKey<FormState>();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Corriger — ${membre.fullName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "L'amende sera annulée et sa cotisation manquante enregistrée "
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
                  controller: carnetsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nombre de carnets'),
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Invalide' : null,
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
                if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
              },
              child: const Text('Corriger'),
            ),
          ],
        ),
      ),
    );

    if (confirme != true) return;
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.corrigerAmendeErreur(
      amendeId: amende.id,
      raison: 'Le membre avait en fait payé — cotisation non enregistrée à temps',
      annuleParPhone: agentPhone,
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      memberId: membre.id,
      partsCount: int.parse(carnetsController.text.trim()),
      dateReelle: dateReelle,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotisations (cash)')),
      body: FutureBuilder<List<Member>>(
        future: _membersFuture,
        builder: (context, memberSnapshot) {
          if (!memberSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final membres = memberSnapshot.data!;
          final membresDisponibles =
              membres.where((m) => !_brouillon.any((l) => l.membre.id == m.id)).toList();

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('1. Ajouter un encaissement', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMemberId,
                      decoration: const InputDecoration(
                        labelText: 'Membre',
                        border: OutlineInputBorder(),
                      ),
                      items: membresDisponibles
                          .map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName)))
                          .toList(),
                      onChanged: _onMemberSelected,
                    ),
                    const SizedBox(height: 12),
                    if (_calculEnCours) const Center(child: CircularProgressIndicator()),
                    if (_erreurCalcul != null)
                      Text(_erreurCalcul!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    if (_carnetsNonDefinis)
                      const Text(
                        'Carnets non définis pour ce membre sur ce cycle — allez sur '
                        '"Membres" pour les choisir avant de pouvoir enregistrer un paiement.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    if (_montantCalcule != null) ...[
                      if (_montantCalcule == 0)
                        const Text('Ce membre est à jour — rien à régler pour le moment.')
                      else ...[
                        Text(
                          'Montant à régler : ${formatFcfa(_montantCalcule!)} '
                          '($_carnetsCouvertsCalcules carnet(s))',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => _ajouterAuBrouillon(membres),
                          child: const Text('Ajouter à la liste du jour'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_brouillon.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('2. Encaissements du jour (${_brouillon.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._brouillon.map((l) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.pending_outlined),
                            title: Text(l.membre.fullName),
                            subtitle: Text('${l.carnetsCouverts} carnet(s)'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatFcfa(l.montantFcfa)),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Retirer',
                                  onPressed: () => setState(() => _brouillon.remove(l)),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _enregistrementEnCours ? null : _confirmerEtEnregistrer,
                        icon: _enregistrementEnCours
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: const Text('Vérifier et enregistrer'),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              FutureBuilder<List<({Amende amende, Member membre})>>(
                future: _amendesRevueFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final enAttente = snapshot.data!;
                  return Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.errorContainer,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amendes de retard à revoir (${enAttente.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Appliquées automatiquement pour une échéance passée non '
                          'couverte — à confirmer, ou à corriger si le membre avait '
                          'en fait payé.',
                          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        ...enAttente.map((r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r.membre.fullName} — ${formatFcfa(r.amende.montantFcfa)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _confirmerAmende(r.amende),
                                          child: const Text('Confirmer'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _corrigerAmendeErreur(r.amende, r.membre),
                                          child: const Text('Erreur — il avait payé'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              FutureBuilder<List<Cotisation>>(
                future: _cotisationsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cotisations = snapshot.data!;
                  if (cotisations.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Aucune cotisation enregistrée sur ce cycle.'),
                      ),
                    );
                  }
                  final membresParId = {for (final m in membres) m.id: m};
                  return Column(
                    children: cotisations.map((c) {
                      final nom = membresParId[c.memberId]?.fullName ?? c.memberId;
                      final provenanceTag = c.provenance == 'importe'
                          ? ' · importé${c.estApproximatif ? ' (approximatif)' : ''}'
                          : '';
                      return ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text('$nom — ${c.partsCount} carnet(s)'),
                        subtitle: Text('Source : ${c.source}$provenanceTag'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_clock.dart';
import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/echeance_calculator.dart';
import '../../domain/calculators/loan_balance_calculator.dart';
import '../../state/providers.dart';
import '../loans/loan_repayment_dialog.dart';
import 'amende_fonds_dialogs.dart';
import 'amende_resolution_dialogs.dart';

/// Écran "Cotisation" — voir RETOURS_TERRAIN.md, point 20.6 et ses
/// refontes suivantes : LE seul écran actionnable pour un membre
/// pendant la réunion. Cotisation en tête (le geste le plus fréquent),
/// puis toutes les autres actions (amende, cotisation exceptionnelle,
/// fonds de solidarité, prêt) rassemblées dans une rangée de boutons.
/// "Enregistrer et passer au membre suivant" évite de ressortir de
/// l'écran entre deux membres.
///
/// Pas de bouton Présent/Absent séparé : une absence ou un paiement par
/// un tiers se règle directement via "Ajouter amende", qui résout le
/// carnet concerné **tout de suite** (voir
/// `AppDatabase.resoudreCarnetImmediat`) — plus d'amende auto-générée
/// à la clôture pour un carnet déjà traité ainsi (voir DECISIONS.md,
/// "Résolution immédiate par carnet depuis 'Ajouter amende'").
///
/// "Séance du jour" (`seance_jour_screen.dart`) reste l'écran
/// d'ensemble, désormais en lecture seule — cet écran-ci est celui où
/// tout s'enregistre.
class CotisationMembreScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cycleId;
  final List<Member> membres;
  final int initialIndex;

  const CotisationMembreScreen({
    super.key,
    required this.groupId,
    required this.cycleId,
    required this.membres,
    required this.initialIndex,
  });

  @override
  ConsumerState<CotisationMembreScreen> createState() =>
      _CotisationMembreScreenState();
}

class _CotisationMembreScreenState
    extends ConsumerState<CotisationMembreScreen> {
  late int _index;
  late Future<_MembreData> _dataFuture;
  final Map<int, int> _partsChoisiesParCarnet = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _reload();
  }

  Member get _membre => widget.membres[_index];

  void _reload() {
    final db = ref.read(databaseProvider);
    setState(() {
      _dataFuture = _fetch(db);
      _partsChoisiesParCarnet.clear();
    });
  }

  Future<_MembreData> _fetch(AppDatabase db) async {
    final cycle = await (db.select(
      db.cycles,
    )..where((c) => c.id.equals(widget.cycleId))).getSingle();
    final group = await (db.select(
      db.groups,
    )..where((g) => g.id.equals(widget.groupId))).getSingle();
    final journeeOuverte = await db.journeeCotisationEnAttente(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
    );

    final carnets = await db.carnetsEngagesDuMembre(
      memberId: _membre.id,
      cycleId: widget.cycleId,
    );
    final dejaAjoutees = <int, int>{};
    final maxParCarnet = <int, int>{};
    final motifsRestants = <int, Set<String>>{};
    final numerosSerie = <int, String>{};
    if (carnets != null) {
      for (
        var carnetNumero = 1;
        carnetNumero <= carnets.nombreCarnets;
        carnetNumero++
      ) {
        final carnet = await db.carnetDuMembre(
          memberId: _membre.id,
          carnetNumero: carnetNumero,
        );
        if (carnet != null) numerosSerie[carnetNumero] = carnet.numeroSerie;
        if (journeeOuverte == null) continue;
        final ajoutees = await db.partsDejaAjouteesAujourdhui(
          memberId: _membre.id,
          cycleId: widget.cycleId,
          carnetNumero: carnetNumero,
          jour: journeeOuverte,
        );
        dejaAjoutees[carnetNumero] = ajoutees;
        maxParCarnet[carnetNumero] =
            (EcheanceCalculator.maxPartsParTransaction - ajoutees).clamp(
              0,
              EcheanceCalculator.maxPartsParTransaction,
            );
        motifsRestants[carnetNumero] = await db.motifsSystemeApplicables(
          memberId: _membre.id,
          cycleId: widget.cycleId,
          carnetNumero: carnetNumero,
          echeanceDate: journeeOuverte,
        );
      }
    }

    final motifsCatalogue = await db.motifsAmendeActifsDuGroupe(
      widget.groupId,
    );
    final amendesNonSoldees = await db.amendesNonSoldeesDuMembre(
      memberId: _membre.id,
      cycleId: widget.cycleId,
    );
    final soldesAmendes = <String, int>{};
    for (final a in amendesNonSoldees) {
      soldesAmendes[a.id] = await db.soldeRestantAmendeFcfa(a.id);
    }

    final exceptionnellesNonSoldees =
        await db.cotisationsExceptionnellesNonSoldeesDuMembre(
          cycleId: widget.cycleId,
          memberId: _membre.id,
        );

    final soldeSolidarite = group.montantSolidariteObligatoireFcfa > 0
        ? await db.soldeSolidariteObligatoireFcfa(
            groupId: widget.groupId,
            cycleId: widget.cycleId,
            memberId: _membre.id,
          )
        : 0;

    final tousLesPrets = await db.pretsDuCycle(widget.cycleId);
    final prets = tousLesPrets.where((p) => p.memberId == _membre.id).toList();
    final soldesPrets = <String, LoanBalanceResult>{};
    for (final pret in prets) {
      if (await db.pretEstConfirme(pret.id)) {
        soldesPrets[pret.id] = await db.soldePret(
          pret,
          maintenant: AppClock.now(),
        );
      }
    }

    return _MembreData(
      cycle: cycle,
      group: group,
      journeeOuverte: journeeOuverte,
      carnets: carnets,
      dejaAjoutees: dejaAjoutees,
      maxParCarnet: maxParCarnet,
      motifsRestants: motifsRestants,
      numerosSerie: numerosSerie,
      motifsCatalogue: motifsCatalogue,
      amendesNonSoldees: amendesNonSoldees,
      soldesAmendes: soldesAmendes,
      exceptionnellesNonSoldees: exceptionnellesNonSoldees,
      soldeSolidariteFcfa: soldeSolidarite,
      prets: prets,
      soldesPrets: soldesPrets,
    );
  }

  Future<bool> _enregistrerCotisationSiSaisie() async {
    final partsRetenues = {
      for (final e in _partsChoisiesParCarnet.entries)
        if (e.value > 0) e.key: e.value,
    };
    if (partsRetenues.isEmpty) return true;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    try {
      await db.enregistrerEncaissementMembre(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        memberId: _membre.id,
        partsParCarnet: partsRetenues,
        recordedByPhone: agentPhone,
      );
      return true;
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message?.toString() ?? 'Montant invalide.')),
        );
      }
      return false;
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    }
  }

  Future<void> _enregistrerCotisation() async {
    setState(() => _busy = true);
    await _enregistrerCotisationSiSaisie();
    if (mounted) setState(() => _busy = false);
    _reload();
  }

  Future<void> _enregistrerEtPasserAuSuivant() async {
    setState(() => _busy = true);
    final ok = await _enregistrerCotisationSiSaisie();
    if (mounted) setState(() => _busy = false);
    if (!ok || !mounted) return;
    if (_index + 1 < widget.membres.length) {
      setState(() => _index++);
      _reload();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _demanderCredit() async {
    final montantController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demande de crédit'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: montantController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Montant demandé (FCFA)'),
            validator: (v) => (int.tryParse(v ?? '') == null || int.parse(v!) <= 0)
                ? 'Montant invalide'
                : null,
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
            child: const Text('Enregistrer la demande'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    try {
      await db.demanderPret(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        memberId: _membre.id,
        montantDemandeFcfa: int.parse(montantController.text.trim()),
        recordedByPhone: agentPhone,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande enregistrée — à traiter sur l\'écran Prêts.'),
          ),
        );
      }
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message?.toString() ?? 'Montant invalide.')),
        );
      }
    }
  }

  static const _libellesMotifSysteme = {
    AppDatabase.codeSystemeAbsence: 'Absence',
    AppDatabase.codeSystemePartImpayee: 'Part impayée',
    AppDatabase.codeSystemePayeParTiers: 'Payé par un tiers',
  };
  static const _autreAmendeSentinel = '__autre__';

  /// "Ajouter amende" — voir RETOURS_TERRAIN.md : remplace le bouton
  /// Présent/Absent. S'il reste des carnets non traités aujourd'hui,
  /// propose d'abord (carnet, motif système) — un choix résout
  /// **tout de suite** ce carnet précis (voir
  /// `AppDatabase.resoudreCarnetImmediat`), jamais différé à la
  /// clôture. "Autre amende" (ou aucun carnet à traiter) retombe sur le
  /// dialogue générique existant, pour une amende hors carnet
  /// (disciplinaire, etc.) — les amendes restent cumulatives, un carnet
  /// déjà résolu peut toujours recevoir une amende libre en plus.
  Future<void> _ajouterAmende(_MembreData data) async {
    final choixCarnetMotif = <(int, String)>[
      for (final entry in data.motifsRestants.entries)
        for (final motif in entry.value) (entry.key, motif),
    ];

    String? choix;
    if (data.journeeOuverte != null && choixCarnetMotif.isNotEmpty) {
      choix = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Ajouter une amende'),
          children: [
            for (final (carnetNumero, motif) in choixCarnetMotif)
              SimpleDialogOption(
                onPressed: () => Navigator.of(
                  context,
                ).pop('$carnetNumero::$motif'),
                child: Text(
                  'Carnet $carnetNumero — '
                  '${_libellesMotifSysteme[motif] ?? motif}',
                ),
              ),
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(context).pop(_autreAmendeSentinel),
              child: const Text('Autre amende (hors carnet)'),
            ),
          ],
        ),
      );
      if (choix == null) return;
    }

    if (choix == null || choix == _autreAmendeSentinel) {
      if (!mounted) return;
      final db = ref.read(databaseProvider);
      final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
      await showAddAmendeDialog(
        context: context,
        db: db,
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        agentPhone: agentPhone,
        membres: [_membre],
        motifsCatalogue: data.motifsCatalogue,
        memberIdInitial: _membre.id,
        onSaved: _reload,
      );
      return;
    }

    final parts = choix.split('::');
    final carnetNumero = int.parse(parts[0]);
    final codeSysteme = parts[1];
    setState(() => _busy = true);
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    try {
      await db.resoudreCarnetImmediat(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        memberId: _membre.id,
        carnetNumero: carnetNumero,
        date: data.journeeOuverte!,
        codeSysteme: codeSysteme,
        agentPhone: agentPhone,
      );
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    if (mounted) setState(() => _busy = false);
    _reload();
  }

  Future<void> _payerUneAmende(_MembreData data) async {
    if (data.amendesNonSoldees.isEmpty) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    // Une seule amende en attente -> réglée directement ; plusieurs ->
    // l'agent choisit laquelle.
    Amende amende;
    if (data.amendesNonSoldees.length == 1) {
      amende = data.amendesNonSoldees.single;
    } else {
      final choix = await showDialog<Amende>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Quelle amende régler ?'),
          children: [
            for (final a in data.amendesNonSoldees)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(a),
                child: Text(
                  '${a.motif} — ${formatFcfa(data.soldesAmendes[a.id] ?? 0)}',
                ),
              ),
          ],
        ),
      );
      if (choix == null) return;
      amende = choix;
    }
    if (!mounted) return;
    await showPayerAmendeDialog(
      context: context,
      db: db,
      amende: amende,
      solde: data.soldesAmendes[amende.id] ?? 0,
      agentPhone: agentPhone,
      onSaved: _reload,
    );
  }

  Future<void> _payerCotisationExceptionnelle(_MembreData data) async {
    if (data.exceptionnellesNonSoldees.isEmpty) return;
    final evt = data.exceptionnellesNonSoldees.length == 1
        ? data.exceptionnellesNonSoldees.single
        : await showDialog<({CotisationsExceptionnelle evt, int solde})>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Quelle épargne exceptionnelle régler ?'),
              children: [
                for (final r in data.exceptionnellesNonSoldees)
                  SimpleDialogOption(
                    onPressed: () => Navigator.of(context).pop(r),
                    child: Text(
                      '${r.evt.motif} — ${formatFcfa(r.solde)}',
                    ),
                  ),
              ],
            ),
          );
    if (evt == null || !mounted) return;
    final montantController = TextEditingController(
      text: evt.solde.toString(),
    );
    final formKey = GlobalKey<FormState>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payer — ${evt.evt.motif}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: montantController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Montant payé (FCFA)',
              helperText: 'Solde dû : ${formatFcfa(evt.solde)}',
            ),
            validator: (v) {
              final montant = int.tryParse(v ?? '');
              if (montant == null || montant <= 0) return 'Montant invalide';
              if (montant > evt.solde) {
                return 'Ne peut pas dépasser le solde (${formatFcfa(evt.solde)})';
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
    if (confirme != true || !mounted) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.enregistrerContributionFondsSolidarite(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      memberId: _membre.id,
      montantFcfa: int.parse(montantController.text.trim()),
      motif: evt.evt.motif,
      recordedByPhone: agentPhone,
      cotisationExceptionnelleId: evt.evt.id,
    );
    _reload();
  }

  Future<void> _payerSolidarite(_MembreData data) async {
    final montantController = TextEditingController(
      text: data.soldeSolidariteFcfa > 0
          ? data.soldeSolidariteFcfa.toString()
          : '',
    );
    final formKey = GlobalKey<FormState>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contribution — fonds de solidarité'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: montantController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Montant versé (FCFA)',
              helperText: data.soldeSolidariteFcfa > 0
                  ? 'Solde dû : ${formatFcfa(data.soldeSolidariteFcfa)}'
                  : 'À jour — ce versement prend de l\'avance.',
            ),
            validator: (v) => (int.tryParse(v ?? '') == null || int.parse(v!) <= 0)
                ? 'Montant invalide'
                : null,
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
    if (confirme != true || !mounted) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    await db.enregistrerContributionFondsSolidarite(
      groupId: widget.groupId,
      cycleId: widget.cycleId,
      memberId: _membre.id,
      montantFcfa: int.parse(montantController.text.trim()),
      motif: 'Fonds de solidarité obligatoire',
      recordedByPhone: agentPhone,
    );
    _reload();
  }

  Future<void> _rembourserPret(_MembreData data) async {
    final pretsConfirmesAvecDette = data.prets.where(
      (p) => (data.soldesPrets[p.id]?.montantDuFcfa ?? 0) > 0,
    );
    if (pretsConfirmesAvecDette.isEmpty) return;
    final pret = pretsConfirmesAvecDette.length == 1
        ? pretsConfirmesAvecDette.single
        : await showDialog<Pret>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Quel prêt rembourser ?'),
              children: [
                for (final p in pretsConfirmesAvecDette)
                  SimpleDialogOption(
                    onPressed: () => Navigator.of(context).pop(p),
                    child: Text(
                      'Emprunté ${formatFcfa(p.principalFcfa)} — dû '
                      '${formatFcfa(data.soldesPrets[p.id]!.montantDuFcfa)}',
                    ),
                  ),
              ],
            ),
          );
    if (pret == null || !mounted) return;
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    final enregistre = await showLoanRepaymentDialog(
      context: context,
      db: db,
      pretId: pret.id,
      montantMaxFcfa: data.soldesPrets[pret.id]!.montantDuFcfa,
      agentPhone: agentPhone,
    );
    if (enregistre) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Épargne — ${_index + 1}/${widget.membres.length}',
        ),
      ),
      body: FutureBuilder<_MembreData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final nombreCarnets = data.carnets?.nombreCarnets ?? 0;
          final cotisationTotal =
              _partsChoisiesParCarnet.entries.fold<int>(
                0,
                (s, e) => s + e.value,
              ) *
              data.cycle.partValueFcfa;
          final pretsAvecDette = data.prets
              .where((p) => (data.soldesPrets[p.id]?.montantDuFcfa ?? 0) > 0)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _membre.fullName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (nombreCarnets > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (var n = 1; n <= nombreCarnets; n++)
                        Chip(
                          label: Text(
                            data.numerosSerie[n] ?? 'Carnet $n',
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              Text('1. Épargne', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (data.journeeOuverte == null)
                const Text(
                  'Aucune journée d\'épargne ouverte pour le moment.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else if (nombreCarnets == 0)
                const Text(
                  'Carnets non définis pour ce cycle — allez sur "Membres" '
                  'pour les choisir.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else ...[
                for (var n = 1; n <= nombreCarnets; n++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${data.numerosSerie[n] ?? 'Carnet $n'} — déjà '
                            'aujourd\'hui : ${data.dejaAjoutees[n] ?? 0} part(s)',
                          ),
                        ),
                        DropdownButton<int>(
                          value: _partsChoisiesParCarnet[n] ?? 0,
                          items: [
                            for (
                              var p = 0;
                              p <=
                                  (data.maxParCarnet[n] ??
                                      EcheanceCalculator.maxPartsParTransaction);
                              p++
                            )
                              DropdownMenuItem(value: p, child: Text('+ $p part(s)')),
                          ],
                          onChanged: (v) => setState(() {
                            _partsChoisiesParCarnet[n] = v ?? 0;
                          }),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Total épargne : ${formatFcfa(cotisationTotal)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: cotisationTotal > 0 && !_busy
                      ? _enregistrerCotisation
                      : null,
                  child: const Text('Enregistrer l\'épargne'),
                ),
              ],
              const Divider(height: 32),

              Text(
                'Autres actions pour ce membre',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _ajouterAmende(data),
                    icon: const Icon(Icons.report_gmailerrorred_outlined, size: 18),
                    label: const Text('Ajouter amende', style: TextStyle(fontSize: 12)),
                  ),
                  OutlinedButton.icon(
                    onPressed: data.amendesNonSoldees.isEmpty
                        ? null
                        : () => _payerUneAmende(data),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Payer amende', style: TextStyle(fontSize: 12)),
                  ),
                  OutlinedButton.icon(
                    onPressed: data.exceptionnellesNonSoldees.isEmpty
                        ? null
                        : () => _payerCotisationExceptionnelle(data),
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: const Text(
                      'Épargne except.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: data.group.montantSolidariteObligatoireFcfa <= 0
                        ? null
                        : () => _payerSolidarite(data),
                    icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
                    label: const Text(
                      'Fonds solidarité',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: pretsAvecDette.isEmpty
                        ? null
                        : () => _rembourserPret(data),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text(
                      'Rembourser prêt',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _demanderCredit,
                    icon: const Icon(Icons.request_page_outlined, size: 18),
                    label: const Text('Demander prêt', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _busy ? null : _enregistrerEtPasserAuSuivant,
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  _index + 1 < widget.membres.length
                      ? 'Enregistrer et passer au membre suivant'
                      : 'Enregistrer et terminer',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MembreData {
  final Cycle cycle;
  final Group group;
  final DateTime? journeeOuverte;
  final CarnetsEngage? carnets;
  final Map<int, int> dejaAjoutees;
  final Map<int, int> maxParCarnet;
  final Map<int, Set<String>> motifsRestants;
  final Map<int, String> numerosSerie;
  final List<MotifsAmendeData> motifsCatalogue;
  final List<Amende> amendesNonSoldees;
  final Map<String, int> soldesAmendes;
  final List<({CotisationsExceptionnelle evt, int solde})> exceptionnellesNonSoldees;
  final int soldeSolidariteFcfa;
  final List<Pret> prets;
  final Map<String, LoanBalanceResult> soldesPrets;

  const _MembreData({
    required this.cycle,
    required this.group,
    required this.journeeOuverte,
    required this.carnets,
    required this.dejaAjoutees,
    required this.maxParCarnet,
    required this.motifsRestants,
    required this.numerosSerie,
    required this.motifsCatalogue,
    required this.amendesNonSoldees,
    required this.soldesAmendes,
    required this.exceptionnellesNonSoldees,
    required this.soldeSolidariteFcfa,
    required this.prets,
    required this.soldesPrets,
  });
}

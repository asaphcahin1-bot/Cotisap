import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_clock.dart';
import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/loan_balance_calculator.dart';
import '../../domain/calculators/loan_rate_resolver.dart';
import '../../domain/calculators/loan_window_calculator.dart';
import '../../state/providers.dart';
import 'loan_confirmation_dialogs.dart';
import 'loan_repayment_dialog.dart';

/// Date de fin prévue du cycle — base de la fenêtre des 3 derniers mois
/// (voir [LoanRateResolver], DECISIONS.md "Résolution automatique du
/// taux de prêt").
DateTime _finDeCycle(Cycle cycle, Group group) {
  return DateTime(
    cycle.startedAt.year,
    cycle.startedAt.month + group.cycleDurationMonths,
    cycle.startedAt.day,
  );
}

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
    final cycle = await (db.select(
      db.cycles,
    )..where((c) => c.id.equals(widget.cycleId))).getSingle();
    final group = await (db.select(
      db.groups,
    )..where((g) => g.id.equals(widget.groupId))).getSingle();
    final membres = await db.membresDuGroupe(widget.groupId);
    final prets = await db.pretsDuCycle(widget.cycleId);
    final statuts = <String, bool>{};
    final soldes = <String, LoanBalanceResult>{};
    final remboursements = <String, List<PretRemboursement>>{};
    for (final pret in prets) {
      final confirme = await db.pretEstConfirme(pret.id);
      statuts[pret.id] = confirme;
      if (confirme) {
        // Toujours via db.soldePret (jamais un calcul dupliqué inline)
        // — c'est ce qui applique le plafond de dette perdue à la
        // clôture (voir DECISIONS.md, "Dette de prêt au rouge") de
        // façon uniforme, pour un cycle déjà clos comme pour un cycle
        // en cours.
        soldes[pret.id] = await db.soldePret(pret, maintenant: AppClock.now());
      }
      remboursements[pret.id] = await db.remboursementsDuPret(pret.id);
    }
    // Fenêtre de crédit + caisse disponible (voir DECISIONS.md,
    // "Fenêtres de crédit selon la fréquence de réunion" et
    // "Rationnement des crédits selon la caisse disponible") —
    // vérifiées aussi côté base (voir [AppDatabase.enregistrerPret]),
    // ceci ne fait que refléter l'état à l'écran.
    final maintenant = AppClock.now();
    final fenetreOuverte = const LoanWindowCalculator().fenetreOuverte(
      debutCycle: cycle.startedAt,
      meetingFrequency: group.meetingFrequency,
      paymentDayOfWeek: group.paymentDayOfWeek,
      paymentDayOfMonth1: group.paymentDayOfMonth1,
      paymentDayOfMonth2: group.paymentDayOfMonth2,
      maintenant: maintenant,
    );
    final reunionsAvant = const LoanWindowCalculator()
        .reunionsAvantProchaineFenetre(
          debutCycle: cycle.startedAt,
          meetingFrequency: group.meetingFrequency,
          paymentDayOfWeek: group.paymentDayOfWeek,
          paymentDayOfMonth1: group.paymentDayOfMonth1,
          paymentDayOfMonth2: group.paymentDayOfMonth2,
          maintenant: maintenant,
        );
    final caisseDisponible = await db.caisseDisponibleActuelleFcfa(
      widget.cycleId,
    );
    // Rationnement collectif des crédits (voir DECISIONS.md) — file
    // d'attente des demandes pas encore accordées ni refusées.
    final demandesEnAttente = await db.demandesEnAttenteDuCycle(
      widget.cycleId,
    );

    return _LoansData(
      cycle: cycle,
      group: group,
      membres: membres,
      prets: prets,
      confirmes: statuts,
      soldes: soldes,
      remboursements: remboursements,
      fenetreOuverte: fenetreOuverte,
      reunionsAvantProchaineFenetre: reunionsAvant,
      caisseDisponibleFcfa: caisseDisponible,
      demandesEnAttente: demandesEnAttente,
    );
  }

  /// Taux résolu au moment d'enregistrer un nouveau prêt — jamais
  /// `cycle.interestRatePercent` directement (voir [LoanRateResolver],
  /// DECISIONS.md "Résolution automatique du taux de prêt : plafond 3x,
  /// dans/hors carnet, fenêtre des 3 derniers mois").
  Future<void> _showNewLoanDialog(_LoansData data) async {
    String? memberId;
    final montantController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int? cotiseTotalFcfa;
    int? empruntesEnCoursFcfa;
    bool chargementTaux = false;

    LoanRateResolution? resolutionActuelle() {
      final montant = int.tryParse(montantController.text.trim());
      if (montant == null || montant <= 0) return null;
      if (cotiseTotalFcfa == null || empruntesEnCoursFcfa == null) return null;
      return const LoanRateResolver().resoudre(
        cotiseTotalFcfa: cotiseTotalFcfa!,
        empruntesEnCoursFcfa: empruntesEnCoursFcfa!,
        principalDemandeFcfa: montant,
        maintenant: AppClock.now(),
        finDeCycle: _finDeCycle(data.cycle, data.group),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> chargerDonneesMembre(String id) async {
            setDialogState(() => chargementTaux = true);
            final db = ref.read(databaseProvider);
            final cotise = await db.totalCotiseFcfa(
              memberId: id,
              cycleId: widget.cycleId,
            );
            final enCours = await db.totalEmprunteEnCoursFcfa(
              memberId: id,
              cycleId: widget.cycleId,
            );
            setDialogState(() {
              cotiseTotalFcfa = cotise;
              empruntesEnCoursFcfa = enCours;
              chargementTaux = false;
            });
          }

          final resolution = resolutionActuelle();
          return AlertDialog(
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
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        memberId = v;
                        cotiseTotalFcfa = null;
                        empruntesEnCoursFcfa = null;
                      });
                      if (v != null) chargerDonneesMembre(v);
                    },
                    validator: (v) => v == null ? 'Choisir un membre' : null,
                  ),
                  TextFormField(
                    controller: montantController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant du prêt (FCFA)',
                      // Rationnement des crédits selon la caisse
                      // disponible (voir DECISIONS.md) — jamais plus
                      // que ce qui a réellement été enregistré.
                      helperText:
                          'Caisse disponible : ${formatFcfa(data.caisseDisponibleFcfa)}',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                    validator: (v) {
                      final montant = int.tryParse(v ?? '');
                      if (montant == null || montant <= 0) {
                        return 'Montant invalide';
                      }
                      if (montant > data.caisseDisponibleFcfa) {
                        return 'Dépasse la caisse disponible '
                            '(${formatFcfa(data.caisseDisponibleFcfa)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: chargementTaux
                        ? const Text(
                            'Calcul du taux en cours…',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          )
                        : resolution == null
                        ? const Text(
                            'Choisissez un membre et un montant pour voir le '
                            'taux applicable.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          )
                        : Text(
                            resolution.horsCarnet
                                ? 'Taux : ${formatPercent(resolution.tauxPercent)} — ${resolution.raison}'
                                : 'Taux : ${formatPercent(resolution.tauxPercent)} — dans le carnet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: resolution.horsCarnet
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.green,
                            ),
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
                onPressed: resolution == null
                    ? null
                    : () {
                        if (formKey.currentState!.validate()) {
                          Navigator.of(context).pop(true);
                        }
                      },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || memberId == null) return;
    final resolutionFinale = resolutionActuelle();
    if (resolutionFinale == null) return;

    final db = ref.read(databaseProvider);
    final authGateway = ref.read(authGatewayProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    final membre = data.membres.firstWhere((m) => m.id == memberId);
    final phoneMembre = membre.phoneNumber;

    final code = phoneMembre == null
        ? null
        : await authGateway.envoyerCode(phoneMembre);
    final ({String pretId, String? confirmationCode}) resultat;
    try {
      resultat = await db.enregistrerPret(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        memberId: memberId!,
        principalFcfa: int.parse(montantController.text.trim()),
        interestRatePercent: resolutionFinale.tauxPercent,
        initiatedByPhone: agentPhone,
        confirmationCode: code,
        dureeJours: data.cycle.loanDurationDays,
      );
    } on StateError catch (e) {
      // Fenêtre de crédit refermée ou caisse insuffisante entre
      // l'ouverture du dialogue et la validation (voir DECISIONS.md) —
      // rare, mais vérifié aussi côté base, pas seulement l'écran.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    _reload();
    if (!mounted) return;
    await showLoanConfirmationDialog(
      context: context,
      db: db,
      pretId: resultat.pretId,
      memberName: membre.fullName,
      memberPhone: phoneMembre,
      agentPhone: agentPhone,
    );
    _reload();
  }

  /// Dépose une demande de prêt sans l'accorder tout de suite — voir
  /// DECISIONS.md, "Rationnement collectif des crédits". Complémentaire
  /// de [_showNewLoanDialog] (qui reste inchangé pour le cas simple,
  /// un seul demandeur) : à utiliser quand plusieurs membres pourraient
  /// demander un prêt à la même réunion, pour permettre une négociation
  /// collective si leur total dépasse la caisse disponible (voir
  /// [_traiterDemandesEnAttente]).
  Future<void> _showDemanderPretDialog(_LoansData data) async {
    String? memberId;
    final montantController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Demander un prêt'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dépose une demande sans l\'accorder tout de suite — à '
                    'traiter avec les autres demandes en attente, ensemble, '
                    'si plusieurs membres demandent en même temps.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: memberId,
                    decoration: const InputDecoration(labelText: 'Demandeur'),
                    items: data.membres
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
                  TextFormField(
                    controller: montantController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant souhaité (FCFA)',
                    ),
                    validator: (v) {
                      final montant = int.tryParse(v ?? '');
                      if (montant == null || montant <= 0) {
                        return 'Montant invalide';
                      }
                      return null;
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
                child: const Text('Déposer la demande'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || memberId == null) return;

    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    try {
      await db.demanderPret(
        groupId: widget.groupId,
        cycleId: widget.cycleId,
        memberId: memberId!,
        montantDemandeFcfa: int.parse(montantController.text.trim()),
        recordedByPhone: agentPhone,
      );
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    _reload();
  }

  /// Traite les demandes en attente une à une, dans l'ordre où elles
  /// ont été déposées — voir DECISIONS.md, "Rationnement collectif des
  /// crédits". **Redistribution immédiate** : le montant proposé au
  /// suivant est recalculé après chaque décision (accepter ou se
  /// désister), jamais figé à l'avance pour tout le lot — d'où l'appel
  /// à [AppDatabase.prochaineDemandeAvecAllocation] à chaque itération
  /// plutôt qu'une liste préparée une seule fois.
  Future<void> _traiterDemandesEnAttente() async {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';

    while (true) {
      final prochaine = await db.prochaineDemandeAvecAllocation(
        widget.cycleId,
      );
      if (prochaine == null) {
        _reload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toutes les demandes ont été traitées.'),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final membres = await db.membresDuGroupe(widget.groupId);
      final membre = membres.firstWhere(
        (m) => m.id == prochaine.demande.memberId,
      );
      final reduit =
          prochaine.montantProposeFcfa < prochaine.demande.montantDemandeFcfa;

      if (!mounted) return;
      final decision = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Demande de prêt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${membre.fullName} a demandé '
                  '${formatFcfa(prochaine.demande.montantDemandeFcfa)}.'),
              const SizedBox(height: 8),
              Text(
                reduit
                    ? 'Caisse insuffisante pour tout accorder — offre proposée : '
                          '${formatFcfa(prochaine.montantProposeFcfa)}.'
                    : 'Caisse suffisante — offre proposée : '
                          '${formatFcfa(prochaine.montantProposeFcfa)} (intégral).',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: reduit
                      ? Theme.of(context).colorScheme.error
                      : Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('arreter'),
              child: const Text('Arrêter (reprendre plus tard)'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop('desister'),
              child: const Text('Se désiste'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('accepter'),
              child: const Text('Accepte'),
            ),
          ],
        ),
      );

      if (decision == null || decision == 'arreter') {
        _reload();
        return;
      }

      if (decision == 'desister') {
        await db.refuserDemandePret(
          demandeId: prochaine.demande.id,
          agentPhone: agentPhone,
        );
        continue;
      }

      // Accepté — crée le prêt puis mène immédiatement sa confirmation
      // (code SMS/signature), avant de passer au suivant : c'est ce qui
      // permet à la redistribution de tenir compte de ce prêt tout
      // juste accordé pour le calcul suivant (voir la doc de
      // [AppDatabase.accepterDemandePret]) — un prêt non confirmé ne
      // compte jamais dans la caisse disponible.
      final authGateway = ref.read(authGatewayProvider);
      final phoneMembre = membre.phoneNumber;
      final code = phoneMembre == null
          ? null
          : await authGateway.envoyerCode(phoneMembre);
      final ({String pretId, String? confirmationCode}) resultat;
      try {
        resultat = await db.accepterDemandePret(
          demandeId: prochaine.demande.id,
          montantAccepteFcfa: prochaine.montantProposeFcfa,
          agentPhone: agentPhone,
          confirmationCode: code,
        );
      } on StateError catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.message)));
        }
        continue;
      }

      if (!mounted) return;
      await showLoanConfirmationDialog(
        context: context,
        db: db,
        pretId: resultat.pretId,
        memberName: membre.fullName,
        memberPhone: membre.phoneNumber,
        agentPhone: agentPhone,
      );
    }
  }

  /// [montantMaxFcfa] : le montant réellement dû (voir
  /// [LoanBalanceCalculator]) — jamais possible de rembourser plus que
  /// ça. Null seulement si le solde n'a pas pu être calculé (prêt
  /// importé sans durée), auquel cas on ne plafonne pas plutôt que de
  /// deviner une limite. Dialogue partagé avec l'écran membre consolidé
  /// (voir [showLoanRepaymentDialog]).
  Future<void> _showRepaymentDialog(String pretId, int? montantMaxFcfa) async {
    final db = ref.read(databaseProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    final enregistre = await showLoanRepaymentDialog(
      context: context,
      db: db,
      pretId: pretId,
      montantMaxFcfa: montantMaxFcfa,
      agentPhone: agentPhone,
    );
    if (enregistre) _reload();
  }

  /// Sortie du rouge (voir DECISIONS.md, "Sortir du rouge : paiement
  /// libre") : le membre apporte le montant de son choix — payer le
  /// minimum (intérêts + amende) reconduit le principal d'origine tel
  /// quel, payer plus le réduit, payer moins (voire rien) ajoute la
  /// différence au montant reconduit. Le nouveau prêt est résolu au
  /// taux d'un prêt neuf (dans/hors carnet, voir [LoanRateResolver]) et
  /// exige sa propre confirmation, comme tout nouveau prêt (voir
  /// [db.sortirDuRouge]).
  Future<void> _showSortirDuRougeDialog(
    _LoansData data,
    Pret pret,
    LoanBalanceResult solde,
  ) async {
    final membre = data.membres.firstWhere((m) => m.id == pret.memberId);
    final montantAmende = data.group.montantAmendeSortieRougeFcfa;
    // Intérêts accumulés depuis l'entrée au rouge — base du minimum à
    // payer pour reconduire le principal d'origine tel quel.
    final montantInterets =
        solde.montantDuFcfa - (solde.soldeAuDebutDuRougeFcfa ?? 0);
    final minimumSuggere = montantInterets + montantAmende;

    final db = ref.read(databaseProvider);
    // Chargé une seule fois avant l'ouverture du dialogue (le membre
    // est déjà connu, contrairement au dialogue "Nouveau prêt") — le
    // prêt en cours de sortie est exclu du total emprunté, il est sur
    // le point d'être remplacé (voir la doc de [db.sortirDuRouge]).
    final cotiseTotalFcfa = await db.totalCotiseFcfa(
      memberId: pret.memberId,
      cycleId: pret.cycleId,
    );
    final empruntesAvant = await db.totalEmprunteEnCoursFcfa(
      memberId: pret.memberId,
      cycleId: pret.cycleId,
    );
    final diffEmpruntes = empruntesAvant - pret.principalFcfa;
    final empruntesEnCoursFcfa = diffEmpruntes < 0 ? 0 : diffEmpruntes;

    if (!mounted) return;

    final montantPayeController = TextEditingController(
      text: minimumSuggere.toString(),
    );
    final formKey = GlobalKey<FormState>();

    int? montantReconduit() {
      final montantPaye = int.tryParse(montantPayeController.text.trim());
      if (montantPaye == null || montantPaye < 0) return null;
      return solde.montantDuFcfa + montantAmende - montantPaye;
    }

    LoanRateResolution? resolutionActuelle() {
      final reconduit = montantReconduit();
      if (reconduit == null || reconduit <= 0) return null;
      return const LoanRateResolver().resoudre(
        cotiseTotalFcfa: cotiseTotalFcfa,
        empruntesEnCoursFcfa: empruntesEnCoursFcfa,
        principalDemandeFcfa: reconduit,
        maintenant: AppClock.now(),
        finDeCycle: _finDeCycle(data.cycle, data.group),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final reconduit = montantReconduit();
          final resolution = resolutionActuelle();
          return AlertDialog(
            title: const Text('Sortir du rouge'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${membre.fullName} — prêt actuellement au rouge.'),
                  const SizedBox(height: 8),
                  Text('Intérêts accumulés : ${formatFcfa(montantInterets)}'),
                  if (montantAmende > 0)
                    Text(
                      'Amende de sortie du rouge : ${formatFcfa(montantAmende)}',
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: montantPayeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant payé aujourd\'hui (FCFA)',
                      helperText:
                          'Payer moins ajoute la différence au nouveau prêt ; '
                          'payer plus le réduit.',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                    validator: (v) {
                      final montant = int.tryParse(v ?? '');
                      if (montant == null || montant < 0) {
                        return 'Montant invalide';
                      }
                      final reconduitCalc =
                          solde.montantDuFcfa + montantAmende - montant;
                      if (reconduitCalc <= 0) {
                        return 'Couvre déjà tout le prêt — utilisez un '
                            'remboursement normal';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  if (reconduit != null && reconduit > 0) ...[
                    Text(
                      'Prêt reconduit : ${formatFcfa(reconduit)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (resolution != null)
                      Text(
                        resolution.horsCarnet
                            ? 'Taux : ${formatPercent(resolution.tauxPercent)} — ${resolution.raison}'
                            : 'Taux : ${formatPercent(resolution.tauxPercent)} — dans le carnet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: resolution.horsCarnet
                              ? Theme.of(context).colorScheme.error
                              : Colors.green,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: resolution == null
                    ? null
                    : () {
                        if (formKey.currentState!.validate()) {
                          Navigator.of(context).pop(true);
                        }
                      },
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;
    final montantPayeFinal = int.parse(montantPayeController.text.trim());

    final authGateway = ref.read(authGatewayProvider);
    final agentPhone = ref.read(currentPhoneNumberProvider) ?? 'inconnu';
    final phoneMembre = membre.phoneNumber;

    final code = phoneMembre == null
        ? null
        : await authGateway.envoyerCode(phoneMembre);
    final ({String pretId, String? confirmationCode}) resultat;
    try {
      resultat = await db.sortirDuRouge(
        pretId: pret.id,
        agentPhone: agentPhone,
        montantPayeFcfa: montantPayeFinal,
        confirmationCode: code,
      );
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    _reload();
    if (!mounted) return;
    await showLoanConfirmationDialog(
      context: context,
      db: db,
      pretId: resultat.pretId,
      memberName: membre.fullName,
      memberPhone: phoneMembre,
      agentPhone: agentPhone,
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
          final membresParId = {for (final m in data.membres) m.id: m};
          return Column(
            children: [
              // Fenêtre de crédit (voir DECISIONS.md, "Fenêtres de
              // crédit selon la fréquence de réunion") — rappel visible
              // en permanence tant qu'elle est fermée, jamais un
              // blocage silencieux.
              if (!data.fenetreOuverte)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    data.reunionsAvantProchaineFenetre == 1
                        ? 'Aucune fenêtre de crédit pour le moment — encore '
                              '1 réunion avant la prochaine.'
                        : 'Aucune fenêtre de crédit pour le moment — encore '
                              '${data.reunionsAvantProchaineFenetre} réunions '
                              'avant la prochaine.',
                    textAlign: TextAlign.center,
                  ),
                ),
              // Rationnement collectif des crédits (voir DECISIONS.md,
              // "Rationnement collectif des crédits") — file d'attente
              // des demandes, complémentaire du bouton "Nouveau prêt"
              // (qui reste le chemin simple, un seul demandeur).
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.demandesEnAttente.isEmpty
                                ? 'Aucune demande en attente'
                                : '${data.demandesEnAttente.length} demande(s) en attente',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: data.fenetreOuverte
                              ? () => _showDemanderPretDialog(data)
                              : null,
                          icon: const Icon(Icons.add),
                          label: const Text('Demander'),
                        ),
                      ],
                    ),
                    if (data.demandesEnAttente.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...data.demandesEnAttente.map((d) {
                        final membre = membresParId[d.memberId];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${membre?.fullName ?? d.memberId} — '
                            '${formatFcfa(d.montantDemandeFcfa)}',
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _traiterDemandesEnAttente,
                        icon: const Icon(Icons.balance),
                        label: const Text('Traiter les demandes en attente'),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: data.prets.isEmpty
                    ? const Center(child: Text('Aucun prêt sur ce cycle.'))
                    : ListView.separated(
                        itemCount: data.prets.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
              final pret = data.prets[index];
              final confirme = data.confirmes[pret.id] ?? false;
              final membre = membresParId[pret.memberId];
              final solde = data.soldes[pret.id];
              // "Dans/hors carnet" seulement pour les prêts créés sous le
              // nouveau système à deux taux (voir [LoanRateResolver]) —
              // un prêt importé garde l'ancien taux plat du cycle, sans
              // ce libellé (voir DECISIONS.md).
              final String libelleCarnet;
              if (pret.interestRatePercent ==
                  LoanRateResolver.tauxDansLeCarnet) {
                libelleCarnet = 'dans le carnet';
              } else if (pret.interestRatePercent ==
                  LoanRateResolver.tauxHorsCarnet) {
                libelleCarnet = 'hors carnet';
              } else {
                libelleCarnet = '';
              }
              final ligneStatut = [
                if (pret.provenance == 'importe')
                  'Importé'
                else if (confirme)
                  'Confirmé'
                else
                  'En attente de confirmation',
                'intérêt ${formatPercent(pret.interestRatePercent)}'
                    '${libelleCarnet.isEmpty ? '' : ' ($libelleCarnet)'}',
                if (pret.estApproximatif) 'approximatif',
              ].join(' · ');
              final rembs = data.remboursements[pret.id] ?? const [];
              return ExpansionTile(
                leading: Icon(
                  confirme ? Icons.check_circle : Icons.hourglass_top,
                  color: confirme ? Colors.green : Colors.orange,
                ),
                title: Text(
                  '${membre?.fullName ?? pret.memberId} — emprunté ${formatFcfa(pret.principalFcfa)}',
                ),
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
                      // Prêt "au rouge" (voir DECISIONS.md, "Dette de
                      // prêt au rouge") — période normale expirée,
                      // intérêt désormais à 10 %/mois, universel.
                      if (solde.estAuRouge) ...[
                        Text(
                          'AU ROUGE — intérêt à 10 %/mois depuis le '
                          '${formatFcfa(solde.soldeAuDebutDuRougeFcfa ?? 0)} de départ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        if (confirme)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showSortirDuRougeDialog(data, pret, solde),
                              child: const Text('Sortir du rouge'),
                            ),
                          ),
                      ],
                      if (solde.montantDuFcfa > 0 &&
                          solde.joursRestantsPeriodeCourante != null)
                        Text(
                          solde.joursRestantsPeriodeCourante! >= 0
                              ? 'Prochaine échéance dans ${solde.joursRestantsPeriodeCourante} jour(s)'
                              : 'Échéance dépassée de ${-solde.joursRestantsPeriodeCourante!} jour(s)',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ],
                ),
                trailing: confirme
                    ? (solde != null && solde.montantDuFcfa == 0
                          ? null // soldé — plus rien à rembourser
                          : TextButton(
                              onPressed: () => _showRepaymentDialog(
                                pret.id,
                                solde?.montantDuFcfa,
                              ),
                              child: const Text('Remboursement'),
                            ))
                    : TextButton(
                        onPressed: () async {
                          final db = ref.read(databaseProvider);
                          final agentPhone =
                              ref.read(currentPhoneNumberProvider) ??
                              'inconnu';
                          await showLoanConfirmationDialog(
                            context: context,
                            db: db,
                            pretId: pret.id,
                            memberName: membre?.fullName ?? '',
                            memberPhone: membre?.phoneNumber,
                            agentPhone: agentPhone,
                          );
                          _reload();
                        },
                        child: const Text('Confirmer'),
                      ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remboursements',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        if (rembs.isEmpty)
                          const Text(
                            'Aucun remboursement enregistré pour ce prêt.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          )
                        else
                          ...rembs.map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(formatDateFr(r.recordedAt)),
                                  ),
                                  Text(formatFcfa(r.montantFcfa)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
                            },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<_LoansData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final data = snapshot.data!;
          return FloatingActionButton.extended(
            onPressed: data.fenetreOuverte
                ? () => _showNewLoanDialog(data)
                : null,
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
  final Group group;
  final List<Member> membres;
  final List<Pret> prets;
  final Map<String, bool> confirmes;
  final Map<String, LoanBalanceResult> soldes;
  final Map<String, List<PretRemboursement>> remboursements;
  final bool fenetreOuverte;
  final int reunionsAvantProchaineFenetre;
  final int caisseDisponibleFcfa;
  final List<PretDemande> demandesEnAttente;

  const _LoansData({
    required this.cycle,
    required this.group,
    required this.membres,
    required this.prets,
    required this.confirmes,
    required this.soldes,
    required this.remboursements,
    required this.fenetreOuverte,
    required this.reunionsAvantProchaineFenetre,
    required this.caisseDisponibleFcfa,
    required this.demandesEnAttente,
  });
}

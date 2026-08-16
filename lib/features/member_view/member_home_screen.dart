import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_clock.dart';
import '../../core/formatting.dart';
import '../../data/local/database.dart';
import '../../domain/calculators/end_of_cycle_calculator.dart';
import '../../domain/calculators/loan_balance_calculator.dart';
import '../../state/providers.dart';

/// Écran "membre" en lecture seule (skill two-tier-access-model).
///
/// Point de vigilance central : même si le calcul de fin de cycle a
/// besoin des parts de TOUS les membres pour être correct (valeur
/// ajoutée par part = intérêts+amendes / total des parts du groupe),
/// cet écran n'affiche jamais que la ligne de résultat correspondant à
/// [memberId] — jamais la liste complète ni les montants des autres
/// membres. Gratuit, aucune action d'écriture possible depuis ici.
class MemberHomeScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String groupId;
  final String? cycleId;

  const MemberHomeScreen({
    super.key,
    required this.memberId,
    required this.groupId,
    this.cycleId,
  });

  @override
  ConsumerState<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends ConsumerState<MemberHomeScreen> {
  late Future<_MemberViewData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _charger();
  }

  Future<_MemberViewData> _charger() async {
    final db = ref.read(databaseProvider);
    final membre = await (db.select(
      db.members,
    )..where((m) => m.id.equals(widget.memberId))).getSingle();
    final groupe = await (db.select(
      db.groups,
    )..where((g) => g.id.equals(widget.groupId))).getSingle();

    final cycleIdDemande = widget.cycleId;
    final cycle = cycleIdDemande != null
        ? await (db.select(
            db.cycles,
          )..where((c) => c.id.equals(cycleIdDemande))).getSingleOrNull()
        : await db.cycleEnCours(widget.groupId);

    final tousLesCycles = await db.cyclesDuGroupe(widget.groupId);

    if (cycle == null) {
      return _MemberViewData(
        membre: membre,
        groupe: groupe,
        cycle: null,
        cotisationsMembre: const [],
        pretsMembre: const [],
        pretsConfirmes: const {},
        pretsRembourses: const {},
        pretsSoldes: const {},
        pretsHistorique: const {},
        resultatMembre: null,
        autresCycles: tousLesCycles,
      );
    }

    final cotisationsMembre = await db.cotisationsDuMembre(
      widget.memberId,
      cycle.id,
    );
    final pretsMembre = await db.pretsDuMembre(widget.memberId, cycle.id);
    final pretsConfirmes = <String, bool>{};
    final pretsRembourses = <String, int>{};
    final pretsSoldes = <String, LoanBalanceResult>{};
    final pretsHistorique = <String, List<PretRemboursement>>{};
    for (final pret in pretsMembre) {
      final confirme = await db.pretEstConfirme(pret.id);
      pretsConfirmes[pret.id] = confirme;
      pretsRembourses[pret.id] = await db.totalRembourse(pret.id);
      pretsHistorique[pret.id] = await db.remboursementsDuPret(pret.id);
      if (confirme) {
        // Même source que l'écran agent (voir DECISIONS.md, "Dette de
        // prêt au rouge") — jamais un calcul dupliqué inline, pour que
        // le membre voie exactement le même solde que l'agent.
        pretsSoldes[pret.id] = await db.soldePret(
          pret,
          maintenant: AppClock.now(),
        );
      }
    }

    // Le calcul de fin de cycle a besoin des parts de tout le groupe —
    // voir la note de la classe ci-dessus sur ce qui est affiché ensuite.
    final toutesLesCotisations = await db.cotisationsDuCycle(cycle.id);
    final partsParMembre = <String, int>{};
    for (final c in toutesLesCotisations) {
      partsParMembre.update(
        c.memberId,
        (v) => v + c.partsCount,
        ifAbsent: () => c.partsCount,
      );
    }

    MemberCycleResult? resultatMembre;
    if (partsParMembre.isNotEmpty) {
      // Même logique que [AppDatabase.cloturerCycleEtOuvrirSuivant] et
      // l'écran Répartition (voir [AppDatabase.preparerPartageCycle]) :
      // amendes non soldées déjà déduites de la cotisation de chaque
      // membre (voir DECISIONS.md, "Les amendes ne sont plus une dette").
      final prepared = await db.preparerPartageCycle(
        groupId: widget.groupId,
        cycleId: cycle.id,
      );
      final totalInterets = await db.totalInteretsPercusDuCycle(cycle.id);
      final totalAmendesRegleesCash = await db.totalAmendesRegleesDuCycle(
        cycle.id,
      );
      final totalAmendesDeduites = prepared.amendesADeduireParMembre.values
          .fold<int>(0, (a, b) => a + b);
      final totalDettesEnCours = await db.totalPrincipalNonRembourseDuCycle(
        cycle.id,
      );
      final resultatComplet = const EndOfCycleCalculator().calculer(
        EndOfCycleInput(
          membres: prepared.membres,
          cotisationsTotalesGroupeFcfa:
              prepared.cotisationsEffectivesTotalesFcfa,
          amendesRegleesFcfa: totalAmendesRegleesCash + totalAmendesDeduites,
          interetsPercusFcfa: totalInterets,
          dettesEnCoursGroupeFcfa: totalDettesEnCours,
        ),
      );
      // Ne garder QUE la ligne du membre concerné.
      for (final r in resultatComplet.resultatsParMembre) {
        if (r.memberId == widget.memberId) {
          resultatMembre = r;
          break;
        }
      }
    }

    return _MemberViewData(
      membre: membre,
      groupe: groupe,
      cycle: cycle,
      cotisationsMembre: cotisationsMembre,
      pretsMembre: pretsMembre,
      pretsConfirmes: pretsConfirmes,
      pretsRembourses: pretsRembourses,
      pretsSoldes: pretsSoldes,
      pretsHistorique: pretsHistorique,
      resultatMembre: resultatMembre,
      autresCycles: tousLesCycles.where((c) => c.id != cycle.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MemberViewData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final totalParts = data.cotisationsMembre.fold<int>(
          0,
          (sum, c) => sum + c.partsCount,
        );

        return Scaffold(
          appBar: AppBar(title: Text(data.membre.fullName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data.groupe.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (data.cycle == null)
                const Text(
                  'Aucun cycle en cours pour ce groupe pour le moment.',
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cycle n°${data.cycle!.cycleNumber}'
                          '${data.cycle!.status == 'en_cours' ? ' (en cours)' : ' (clos)'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Mes parts cotisées sur ce cycle : $totalParts'),
                        if (data.resultatMembre != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Mon épargne totale : ${formatFcfa(data.resultatMembre!.cotisationTotaleFcfa)}',
                          ),
                          Text(
                            data.resultatMembre!.aBeneficieDuBonus
                                ? (data.cycle!.status == 'en_cours'
                                      ? 'J\'ai droit à une part du bénéfice collectif si le '
                                            'cycle se terminait aujourd\'hui.'
                                      : 'J\'ai reçu une part du bénéfice collectif de ce cycle.')
                                : 'Aucun bénéfice collectif : j\'ai encore une dette envers '
                                      'le groupe (${formatFcfa(data.resultatMembre!.detteFcfa)}).',
                          ),
                          Text(
                            data.cycle!.status == 'en_cours'
                                ? 'Montant estimé : ${formatFcfa(data.resultatMembre!.montantNetFcfa)}'
                                : 'Montant total : ${formatFcfa(data.resultatMembre!.montantNetFcfa)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mes prêts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (data.pretsMembre.isEmpty)
                  const Text('Aucun prêt sur ce cycle.')
                else
                  ...data.pretsMembre.map((pret) {
                    final confirme = data.pretsConfirmes[pret.id] ?? false;
                    final rembourse = data.pretsRembourses[pret.id] ?? 0;
                    final solde = data.pretsSoldes[pret.id];
                    final historique = data.pretsHistorique[pret.id] ?? const [];
                    return Card(
                      child: ExpansionTile(
                        title: Text(formatFcfa(pret.principalFcfa)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pret.provenance == 'importe'
                                  ? 'Importé'
                                  : (confirme ? 'Confirmé' : 'En attente de confirmation')} · '
                              'intérêt ${formatPercent(pret.interestRatePercent)} · '
                              'remboursé : ${formatFcfa(rembourse)}',
                            ),
                            if (solde != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                solde.montantDuFcfa > 0
                                    ? 'Je dois encore : ${formatFcfa(solde.montantDuFcfa)}'
                                    : 'Soldé',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: solde.montantDuFcfa > 0
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.green,
                                ),
                              ),
                              if (solde.estAuRouge)
                                Text(
                                  'AU ROUGE — intérêt à 10 %/mois depuis le '
                                  '${formatFcfa(solde.soldeAuDebutDuRougeFcfa ?? 0)} de départ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
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
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mes remboursements',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                if (historique.isEmpty)
                                  const Text(
                                    'Aucun remboursement enregistré pour ce prêt.',
                                    style: TextStyle(fontStyle: FontStyle.italic),
                                  )
                                else
                                  ...historique.map(
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
                      ),
                    );
                  }),
              ],
              if (data.autresCycles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Cycles précédents',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...data.autresCycles.map(
                  (c) => ListTile(
                    title: Text('Cycle n°${c.cycleNumber}'),
                    subtitle: Text(
                      c.status == 'en_cours' ? 'En cours' : 'Clos',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MemberHomeScreen(
                            memberId: widget.memberId,
                            groupId: widget.groupId,
                            cycleId: c.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MemberViewData {
  final Member membre;
  final Group groupe;
  final Cycle? cycle;
  final List<Cotisation> cotisationsMembre;
  final List<Pret> pretsMembre;
  final Map<String, bool> pretsConfirmes;
  final Map<String, int> pretsRembourses;
  final Map<String, LoanBalanceResult> pretsSoldes;
  final Map<String, List<PretRemboursement>> pretsHistorique;
  final MemberCycleResult? resultatMembre;
  final List<Cycle> autresCycles;

  const _MemberViewData({
    required this.membre,
    required this.groupe,
    required this.cycle,
    required this.cotisationsMembre,
    required this.pretsMembre,
    required this.pretsConfirmes,
    required this.pretsRembourses,
    required this.pretsSoldes,
    required this.pretsHistorique,
    required this.resultatMembre,
    required this.autresCycles,
  });
}

import 'echeance_calculator.dart';

/// Un remboursement, réduit au strict nécessaire pour ce calculateur
/// (pas de dépendance à la couche base de données — voir
/// [LoanBalanceCalculator]).
class RemboursementSimple {
  final int montantFcfa;
  final DateTime date;

  const RemboursementSimple({required this.montantFcfa, required this.date});
}

class LoanBalanceResult {
  /// Montant dû actuellement (jamais négatif — 0 si le prêt est soldé ou
  /// remboursé au-delà de ce qui était dû).
  final int montantDuFcfa;

  /// Nombre de fois où l'intérêt a été appliqué, en comptant la charge
  /// initiale (1 dès l'emprunt, incrémenté à chaque échéance de
  /// [LoanBalanceCalculator.calculer] expirée sans solde nul).
  final int nombrePeriodesEcoulees;

  /// Jours restants avant la prochaine échéance de renouvellement de
  /// l'intérêt. Null si la durée du prêt n'est pas connue (ex. prêt
  /// importé sans durée déclarée — voir DECISIONS.md).
  final int? joursRestantsPeriodeCourante;

  /// Vrai si le prêt est "au rouge" — voir DECISIONS.md, "Dette de
  /// prêt au rouge" : sa période normale a expiré sans remboursement
  /// complet (ou il a été créé directement au rouge, voir
  /// [LoanBalanceCalculator.calculer] `dejaAuRouge`), et il reste dû.
  final bool estAuRouge;

  /// Solde au moment précis où ce prêt est passé au rouge — null s'il
  /// n'est pas au rouge. Base du montant à payer pour en sortir : la
  /// différence avec [montantDuFcfa] représente les intérêts (à 10 %
  /// par mois) accumulés depuis l'entrée au rouge (voir
  /// DECISIONS.md, "Sortir du rouge").
  final int? soldeAuDebutDuRougeFcfa;

  const LoanBalanceResult({
    required this.montantDuFcfa,
    required this.nombrePeriodesEcoulees,
    required this.joursRestantsPeriodeCourante,
    required this.estAuRouge,
    required this.soldeAuDebutDuRougeFcfa,
  });
}

/// Calcule le solde dû d'un prêt — voir DECISIONS.md, "Dette de prêt au
/// rouge" (RETOURS_TERRAIN.md, point 8) :
/// - le taux fixé à la création du prêt s'applique une première fois à
///   l'emprunt, pour **une seule période normale** de [dureeJours] ;
/// - si cette période expire sans remboursement complet, le prêt passe
///   "au rouge" : à partir de là, l'intérêt se recompose à un taux
///   **universel de 10 %, chaque mois calendaire** — remplace
///   entièrement l'ancienne recomposition au taux d'origine (résout la
///   question "s'ajoute ou remplace" : ça remplace, cadence
///   différente), jusqu'au remboursement intégral ou à une sortie du
///   rouge (voir [LoanBalanceResult.soldeAuDebutDuRougeFcfa]).
///
/// [dejaAuRouge] : vrai seulement pour un prêt créé directement au
/// rouge (reconduction au cycle suivant, voir DECISIONS.md) — saute la
/// période normale, [principalFcfa] est alors déjà le solde de départ
/// du rouge (pas de charge d'intérêt initiale supplémentaire).
///
/// **Délai de recouvrement aligné sur les réunions** (voir DECISIONS.md,
/// "Délai de recouvrement des prêts aligné sur les réunions", 2026-08-09) :
/// s'applique uniquement à la période normale (avant le rouge) — si
/// [meetingFrequency] est fourni, sa borne de fin (calculée normalement
/// comme `début + dureeJours`) est ramenée à la dernière vraie date de
/// réunion **avant ou égale** à cette date brute. La cadence mensuelle
/// une fois au rouge, elle, est toujours calendaire — jamais alignée
/// sur les réunions (voir l'exemple chiffré du fondateur).
///
/// Pure Dart, aucune dépendance à la base — testable directement, comme
/// [EndOfCycleCalculator].
class LoanBalanceCalculator {
  const LoanBalanceCalculator();

  /// Taux universel une fois "au rouge" — jamais celui du prêt
  /// d'origine (voir DECISIONS.md), le même pour tous les groupes.
  static const tauxRougePercent = 10.0;

  LoanBalanceResult calculer({
    required int principalFcfa,
    required double interestRatePercent,
    int? dureeJours,
    required DateTime debut,
    required List<RemboursementSimple> remboursements,
    required DateTime maintenant,
    String? meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
    bool dejaAuRouge = false,
  }) {
    final rembTries = [...remboursements]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Prêt sans durée connue (ex. importé) : pas de recomposition,
    // simple application des remboursements — plutôt que de deviner une
    // durée qui n'a jamais été déclarée. Jamais "au rouge" non plus
    // (rien à comparer à une période).
    if (dureeJours == null || dureeJours <= 0) {
      double solde = principalFcfa + principalFcfa * interestRatePercent / 100;
      for (final r in rembTries) {
        solde -= r.montantFcfa;
      }
      return LoanBalanceResult(
        montantDuFcfa: solde > 0 ? solde.round() : 0,
        nombrePeriodesEcoulees: 1,
        joursRestantsPeriodeCourante: null,
        estAuRouge: false,
        soldeAuDebutDuRougeFcfa: null,
      );
    }

    if (dejaAuRouge) {
      // Reconduction au cycle suivant (voir DECISIONS.md) : au rouge
      // dès le départ, [principalFcfa] est déjà le solde de départ.
      return _calculerAuRouge(
        soldeDepart: principalFcfa.toDouble(),
        depuis: debut,
        remboursements: rembTries,
        maintenant: maintenant,
        periodesDejaEcoulees: 1,
      );
    }

    // Période normale unique, au taux du prêt.
    double solde = principalFcfa + principalFcfa * interestRatePercent / 100;
    var indexRemb = 0;
    final finPeriode = _finDePeriode(
      debutPeriode: debut,
      dureeJours: dureeJours,
      meetingFrequency: meetingFrequency,
      paymentDayOfWeek: paymentDayOfWeek,
      paymentDayOfMonth1: paymentDayOfMonth1,
      paymentDayOfMonth2: paymentDayOfMonth2,
    );

    if (finPeriode.isAfter(maintenant)) {
      // Encore dans la période normale — jamais au rouge.
      while (indexRemb < rembTries.length &&
          !rembTries[indexRemb].date.isAfter(maintenant)) {
        solde -= rembTries[indexRemb].montantFcfa;
        indexRemb++;
      }
      return LoanBalanceResult(
        montantDuFcfa: solde > 0 ? solde.round() : 0,
        nombrePeriodesEcoulees: 1,
        joursRestantsPeriodeCourante: finPeriode.difference(maintenant).inDays,
        estAuRouge: false,
        soldeAuDebutDuRougeFcfa: null,
      );
    }

    // Période normale expirée : applique les remboursements faits
    // pendant cette période.
    while (indexRemb < rembTries.length &&
        !rembTries[indexRemb].date.isAfter(finPeriode)) {
      solde -= rembTries[indexRemb].montantFcfa;
      indexRemb++;
    }
    if (solde <= 0) {
      // Soldé pendant (ou à) la période normale -> jamais passé au rouge.
      return const LoanBalanceResult(
        montantDuFcfa: 0,
        nombrePeriodesEcoulees: 1,
        joursRestantsPeriodeCourante: 0,
        estAuRouge: false,
        soldeAuDebutDuRougeFcfa: null,
      );
    }

    // Toujours dû après la période normale -> passe au rouge à partir
    // de cette date, au taux universel (voir DECISIONS.md).
    return _calculerAuRouge(
      soldeDepart: solde,
      depuis: finPeriode,
      remboursements: rembTries.sublist(indexRemb),
      maintenant: maintenant,
      periodesDejaEcoulees: 1,
    );
  }

  /// Composition mensuelle calendaire à [tauxRougePercent] — voir la
  /// doc de la classe. [remboursements] : uniquement ceux pas encore
  /// appliqués à l'entrée du rouge.
  LoanBalanceResult _calculerAuRouge({
    required double soldeDepart,
    required DateTime depuis,
    required List<RemboursementSimple> remboursements,
    required DateTime maintenant,
    required int periodesDejaEcoulees,
  }) {
    double solde = soldeDepart;
    var indexRemb = 0;
    var periodes = periodesDejaEcoulees;
    var finMois = _ajouterUnMoisCalendaire(depuis);

    while (!finMois.isAfter(maintenant)) {
      while (indexRemb < remboursements.length &&
          !remboursements[indexRemb].date.isAfter(finMois)) {
        solde -= remboursements[indexRemb].montantFcfa;
        indexRemb++;
      }
      if (solde > 0) {
        solde += solde * tauxRougePercent / 100;
        periodes++;
      }
      finMois = _ajouterUnMoisCalendaire(finMois);
    }

    while (indexRemb < remboursements.length &&
        !remboursements[indexRemb].date.isAfter(maintenant)) {
      solde -= remboursements[indexRemb].montantFcfa;
      indexRemb++;
    }

    final soldeFinal = solde > 0 ? solde.round() : 0;
    return LoanBalanceResult(
      montantDuFcfa: soldeFinal,
      nombrePeriodesEcoulees: periodes,
      joursRestantsPeriodeCourante: finMois.difference(maintenant).inDays,
      estAuRouge: soldeFinal > 0,
      soldeAuDebutDuRougeFcfa: soldeFinal > 0 ? soldeDepart.round() : null,
    );
  }

  /// Borne de fin de la période normale : `debutPeriode + dureeJours`
  /// en brut, ou la dernière vraie date de réunion avant ou égale à
  /// cette date brute si [meetingFrequency] est fourni — voir la doc de
  /// la classe.
  DateTime _finDePeriode({
    required DateTime debutPeriode,
    required int dureeJours,
    String? meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
  }) {
    final brut = debutPeriode.add(Duration(days: dureeJours));
    if (meetingFrequency == null) return brut;

    // echeancesPassees ramène toujours la première date au bon jour de
    // réunion à partir de debutPeriode (peu importe son propre jour de
    // semaine/mois), puis avance au rythme configuré — voir
    // EcheanceCalculator. On prend la dernière réunion <= brut.
    final reunions = const EcheanceCalculator().echeancesPassees(
      debutCycle: debutPeriode,
      meetingFrequency: meetingFrequency,
      paymentDayOfWeek: paymentDayOfWeek,
      paymentDayOfMonth1: paymentDayOfMonth1,
      paymentDayOfMonth2: paymentDayOfMonth2,
      maintenant: brut,
    );
    if (reunions.isEmpty) return brut;
    return reunions.last;
  }

  /// Un mois calendaire plus tard, même jour (clampé au dernier jour du
  /// mois si besoin, ex. 31 janvier -> 28/29 février) — toujours
  /// calendaire, jamais aligné sur les réunions (voir la doc de la
  /// classe).
  DateTime _ajouterUnMoisCalendaire(DateTime d) {
    var annee = d.year;
    var mois = d.month + 1;
    if (mois > 12) {
      mois = 1;
      annee++;
    }
    final dernierJourDuMois = DateTime(annee, mois + 1, 0).day;
    final jour = d.day > dernierJourDuMois ? dernierJourDuMois : d.day;
    return DateTime(annee, mois, jour);
  }
}

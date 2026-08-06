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

  const LoanBalanceResult({
    required this.montantDuFcfa,
    required this.nombrePeriodesEcoulees,
    required this.joursRestantsPeriodeCourante,
  });
}

/// Calcule le solde dû d'un prêt dont l'intérêt se recompose s'il n'est
/// pas remboursé dans les temps (skill avec-business-rules, section
/// "Prêts") : le taux fixé à la création du cycle s'applique une
/// première fois à l'emprunt, puis, si la durée du prêt expire sans
/// remboursement complet, le même taux s'applique de nouveau au solde
/// restant pour une nouvelle période de même durée — et ainsi de suite
/// jusqu'au remboursement intégral.
///
/// Pure Dart, aucune dépendance à la base — testable directement, comme
/// [EndOfCycleCalculator].
class LoanBalanceCalculator {
  const LoanBalanceCalculator();

  LoanBalanceResult calculer({
    required int principalFcfa,
    required double interestRatePercent,
    int? dureeJours,
    required DateTime debut,
    required List<RemboursementSimple> remboursements,
    required DateTime maintenant,
  }) {
    final rembTries = [...remboursements]..sort((a, b) => a.date.compareTo(b.date));
    double solde = principalFcfa + principalFcfa * interestRatePercent / 100;

    // Prêt sans durée connue (ex. importé) : pas de recomposition,
    // simple application des remboursements — plutôt que de deviner une
    // durée qui n'a jamais été déclarée.
    if (dureeJours == null || dureeJours <= 0) {
      for (final r in rembTries) {
        solde -= r.montantFcfa;
      }
      return LoanBalanceResult(
        montantDuFcfa: solde > 0 ? solde.round() : 0,
        nombrePeriodesEcoulees: 1,
        joursRestantsPeriodeCourante: null,
      );
    }

    var periodesEcoulees = 1;
    var indexRemb = 0;
    var finPeriode = debut.add(Duration(days: dureeJours));

    while (!finPeriode.isAfter(maintenant)) {
      while (indexRemb < rembTries.length && !rembTries[indexRemb].date.isAfter(finPeriode)) {
        solde -= rembTries[indexRemb].montantFcfa;
        indexRemb++;
      }
      if (solde > 0) {
        solde += solde * interestRatePercent / 100;
        periodesEcoulees++;
      }
      finPeriode = finPeriode.add(Duration(days: dureeJours));
    }

    // Remboursements faits après le dernier palier franchi, mais avant maintenant.
    while (indexRemb < rembTries.length && !rembTries[indexRemb].date.isAfter(maintenant)) {
      solde -= rembTries[indexRemb].montantFcfa;
      indexRemb++;
    }

    return LoanBalanceResult(
      montantDuFcfa: solde > 0 ? solde.round() : 0,
      nombrePeriodesEcoulees: periodesEcoulees,
      joursRestantsPeriodeCourante: finPeriode.difference(maintenant).inDays,
    );
  }
}

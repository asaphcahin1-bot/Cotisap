/// Déduction des dettes au moment du partage de fin de cycle — règle
/// précisée par le fondateur (voir DECISIONS.md, "Déduction des dettes
/// au partage") : un membre encore endetté envers l'AVEC (cotisations
/// impayées, amendes, solde de prêt non remboursé) au moment du partage
/// voit sa dette prélevée sur ce qu'il aurait dû percevoir, jamais versée
/// en plus.
///
/// Volontairement séparé d'[EndOfCycleCalculator] plutôt que d'ajouter ce
/// calcul dedans : ce dernier calcule le montant BRUT (skill
/// avec-business-rules, formule déjà testée), la déduction de dette est
/// une étape suivante et distincte, appliquée après coup. Pure Dart,
/// aucune dépendance à la base — testable directement.
library;

class DebtDeductionResult {
  /// min(montantBrutFcfa, detteFcfa).
  final int montantDeduitFcfa;

  /// montantBrutFcfa - montantDeduitFcfa (jamais négatif).
  final int montantNetFcfa;

  /// detteFcfa - montantDeduitFcfa : partie de la dette que le montant à
  /// percevoir ne suffisait pas à couvrir — perte pour l'AVEC (0 si la
  /// dette est intégralement couverte).
  final int pertAvecFcfa;

  const DebtDeductionResult({
    required this.montantDeduitFcfa,
    required this.montantNetFcfa,
    required this.pertAvecFcfa,
  });
}

class DebtDeductionCalculator {
  const DebtDeductionCalculator();

  /// [montantBrutFcfa] et [detteFcfa] doivent être positifs ou nuls —
  /// jamais négatifs (un montant à percevoir négatif ou une dette
  /// négative n'a pas de sens métier).
  DebtDeductionResult calculer({
    required int montantBrutFcfa,
    required int detteFcfa,
  }) {
    if (montantBrutFcfa < 0) {
      throw ArgumentError('montantBrutFcfa ne peut pas être négatif.');
    }
    if (detteFcfa < 0) {
      throw ArgumentError('detteFcfa ne peut pas être négatif.');
    }
    final deduit = detteFcfa < montantBrutFcfa ? detteFcfa : montantBrutFcfa;
    return DebtDeductionResult(
      montantDeduitFcfa: deduit,
      montantNetFcfa: montantBrutFcfa - deduit,
      pertAvecFcfa: detteFcfa - deduit,
    );
  }
}

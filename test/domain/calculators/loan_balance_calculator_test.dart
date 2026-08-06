import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/loan_balance_calculator.dart';

void main() {
  const calc = LoanBalanceCalculator();

  test('avant toute échéance : montant dû = principal + intérêt initial, temps restant = durée complète', () {
    final r = calc.calculer(
      principalFcfa: 10000,
      interestRatePercent: 10,
      dureeJours: 90,
      debut: DateTime(2024, 1, 1),
      remboursements: [],
      maintenant: DateTime(2024, 1, 1),
    );
    expect(r.montantDuFcfa, 11000);
    expect(r.nombrePeriodesEcoulees, 1);
    expect(r.joursRestantsPeriodeCourante, 90);
  });

  test('un remboursement intégral avant l\'échéance annule tout intérêt supplémentaire', () {
    final r = calc.calculer(
      principalFcfa: 10000,
      interestRatePercent: 10,
      dureeJours: 90,
      debut: DateTime(2024, 1, 1),
      remboursements: [
        RemboursementSimple(montantFcfa: 11000, date: DateTime(2024, 1, 30)),
      ],
      maintenant: DateTime(2024, 4, 1),
    );
    expect(r.montantDuFcfa, 0);
    expect(r.nombrePeriodesEcoulees, 1);
  });

  test('durée expirée sans remboursement complet : le taux se réapplique au solde restant', () {
    // 10000 à 10% -> 11000 dû. Remboursement partiel de 5000 avant
    // l'échéance des 90 jours -> reste 6000, qui devient 6600 après
    // recomposition de l'intérêt.
    final r = calc.calculer(
      principalFcfa: 10000,
      interestRatePercent: 10,
      dureeJours: 90,
      debut: DateTime(2024, 1, 1),
      remboursements: [
        RemboursementSimple(montantFcfa: 5000, date: DateTime(2024, 1, 10)),
      ],
      maintenant: DateTime(2024, 4, 1), // 91 jours après le début
    );
    expect(r.montantDuFcfa, 6600);
    expect(r.nombrePeriodesEcoulees, 2);
  });

  test('plusieurs périodes expirées d\'affilée sans remboursement : composition à chaque palier', () {
    // 1000 à 10%, périodes de 30 jours, aucun remboursement, 95 jours
    // écoulés -> 3 paliers franchis (30, 60, 90).
    final r = calc.calculer(
      principalFcfa: 1000,
      interestRatePercent: 10,
      dureeJours: 30,
      debut: DateTime(2024, 1, 1),
      remboursements: [],
      maintenant: DateTime(2024, 1, 1).add(const Duration(days: 95)),
    );
    // 1100 -> 1210 -> 1331 -> 1464.1 (arrondi à 1464)
    expect(r.montantDuFcfa, 1464);
    expect(r.nombrePeriodesEcoulees, 4);
    expect(r.joursRestantsPeriodeCourante, 25); // prochain palier à 120 jours
  });

  test('sans durée connue (prêt importé) : intérêt appliqué une seule fois, jamais recomposé', () {
    final r = calc.calculer(
      principalFcfa: 5000,
      interestRatePercent: 10,
      dureeJours: null,
      debut: DateTime(2024, 1, 1),
      remboursements: [
        RemboursementSimple(montantFcfa: 2000, date: DateTime(2024, 6, 1)),
      ],
      maintenant: DateTime(2025, 1, 1), // bien après ce qui serait une échéance
    );
    expect(r.montantDuFcfa, 3500); // 5500 - 2000, sans recomposition
    expect(r.joursRestantsPeriodeCourante, isNull);
  });

  test('le solde dû ne descend jamais sous zéro même en cas de trop-perçu', () {
    final r = calc.calculer(
      principalFcfa: 1000,
      interestRatePercent: 10,
      dureeJours: 90,
      debut: DateTime(2024, 1, 1),
      remboursements: [
        RemboursementSimple(montantFcfa: 5000, date: DateTime(2024, 1, 5)),
      ],
      maintenant: DateTime(2024, 1, 10),
    );
    expect(r.montantDuFcfa, 0);
  });
}

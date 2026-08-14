import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/debt_deduction_calculator.dart';

/// Scénarios donnés par le fondateur (voir DECISIONS.md, "Déduction des
/// dettes au partage").
void main() {
  const calc = DebtDeductionCalculator();

  test('montant à percevoir supérieur à la dette : dette entièrement déduite, solde versé', () {
    final r = calc.calculer(montantBrutFcfa: 120000, detteFcfa: 20000);
    expect(r.montantDeduitFcfa, 20000);
    expect(r.montantNetFcfa, 100000);
    expect(r.pertAvecFcfa, 0);
  });

  test('montant à percevoir exactement égal à la dette : membre reçoit 0', () {
    final r = calc.calculer(montantBrutFcfa: 50000, detteFcfa: 50000);
    expect(r.montantDeduitFcfa, 50000);
    expect(r.montantNetFcfa, 0);
    expect(r.pertAvecFcfa, 0);
  });

  test('dette supérieure au montant à percevoir : membre reçoit 0, le reste est une perte AVEC', () {
    final r = calc.calculer(montantBrutFcfa: 80000, detteFcfa: 100000);
    expect(r.montantDeduitFcfa, 80000);
    expect(r.montantNetFcfa, 0);
    expect(r.pertAvecFcfa, 20000);
  });

  test('aucune dette : montant net = montant brut, aucune perte', () {
    final r = calc.calculer(montantBrutFcfa: 30000, detteFcfa: 0);
    expect(r.montantDeduitFcfa, 0);
    expect(r.montantNetFcfa, 30000);
    expect(r.pertAvecFcfa, 0);
  });

  test('rejette un montant brut négatif', () {
    expect(() => calc.calculer(montantBrutFcfa: -1, detteFcfa: 0), throwsArgumentError);
  });

  test('rejette une dette négative', () {
    expect(() => calc.calculer(montantBrutFcfa: 0, detteFcfa: -1), throwsArgumentError);
  });
}

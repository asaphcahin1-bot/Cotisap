import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/collective_loan_rationing_calculator.dart';

/// Rationnement collectif des crédits — voir DECISIONS.md
/// (RETOURS_TERRAIN.md, point 13). Redistribution immédiate : chaque
/// appel simule l'état "à cet instant", jamais une répartition figée.
void main() {
  const calc = CollectiveLoanRationingCalculator();

  test('caisse suffisante pour tout le monde -> chacun reçoit l\'intégralité de sa demande', () {
    expect(
      calc.allocationProposeeFcfa(
        montantsDemandesEnAttenteFcfa: [10000, 20000, 5000],
        caisseDisponibleFcfa: 100000,
      ),
      10000,
    );
  });

  test('caisse insuffisante -> proportionnel à la part du total demandé', () {
    // Total demandé = 100000, caisse = 50000 -> chacun reçoit la moitié.
    expect(
      calc.allocationProposeeFcfa(
        montantsDemandesEnAttenteFcfa: [60000, 40000],
        caisseDisponibleFcfa: 50000,
      ),
      30000, // 60000 * 50000 / 100000
    );
  });

  test('arrondi toujours à l\'entier inférieur, jamais au-dessus de la caisse', () {
    // Total = 30000, caisse = 10000 -> 1/3 chacun, arrondi vers le bas.
    expect(
      calc.allocationProposeeFcfa(
        montantsDemandesEnAttenteFcfa: [10000, 10000, 10000],
        caisseDisponibleFcfa: 10000,
      ),
      3333, // 10000 * 10000 / 30000 = 3333.33... -> 3333
    );
  });

  test('liste vide -> rien à proposer', () {
    expect(
      calc.allocationProposeeFcfa(
        montantsDemandesEnAttenteFcfa: [],
        caisseDisponibleFcfa: 50000,
      ),
      0,
    );
  });

  test('caisse à zéro -> rien à proposer, jamais une erreur', () {
    expect(
      calc.allocationProposeeFcfa(
        montantsDemandesEnAttenteFcfa: [10000],
        caisseDisponibleFcfa: 0,
      ),
      0,
    );
  });

  test('rejette un montant demandé nul ou négatif', () {
    expect(
      () => calc.allocationProposeeFcfa(
        montantsDemandesEnAttenteFcfa: [0],
        caisseDisponibleFcfa: 10000,
      ),
      throwsArgumentError,
    );
  });

  test(
      'redistribution immédiate : un désistement augmente la part des suivants',
      () {
    // 3 demandeurs à 30000 chacun (total 90000), caisse 30000 ->
    // 10000 chacun au premier tour.
    var enAttente = [30000, 30000, 30000];
    const caisse = 30000;
    final premiereOffre = calc.allocationProposeeFcfa(
      montantsDemandesEnAttenteFcfa: enAttente,
      caisseDisponibleFcfa: caisse,
    );
    expect(premiereOffre, 10000);

    // Le premier se désiste (rien accordé, caisse inchangée) -> les 2
    // restants se partagent maintenant toute la caisse entre eux.
    enAttente = enAttente.sublist(1);
    final offreApresDesistement = calc.allocationProposeeFcfa(
      montantsDemandesEnAttenteFcfa: enAttente,
      caisseDisponibleFcfa: caisse,
    );
    expect(offreApresDesistement, 15000); // 30000 * 30000 / 60000

    // Le deuxième accepte son offre réduite (15000) -> la caisse
    // restante diminue d'autant pour le dernier.
    enAttente = enAttente.sublist(1);
    final caisseApresAcceptation = caisse - offreApresDesistement;
    final offreFinale = calc.allocationProposeeFcfa(
      montantsDemandesEnAttenteFcfa: enAttente,
      caisseDisponibleFcfa: caisseApresAcceptation,
    );
    // Seul demandeur restant, caisse suffisante pour sa demande
    // restante (15000 <= 15000) -> intégralité.
    expect(offreFinale, 15000);
  });
}

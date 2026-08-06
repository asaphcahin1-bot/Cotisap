import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/echeance_calculator.dart';

void main() {
  const calc = EcheanceCalculator();

  group('échéances hebdomadaires', () {
    test('le jour de début tombant sur le jour de paiement compte comme la première échéance',
        () {
      // 4 janvier 2024 est un jeudi.
      final echeances = calc.echeancesPassees(
        debutCycle: DateTime(2024, 1, 4),
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: DateTime(2024, 1, 18),
      );
      expect(echeances, [
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 11),
        DateTime(2024, 1, 18),
      ]);
    });

    test('un début de cycle qui ne tombe pas sur le jour de paiement décale à la première occurrence',
        () {
      // 1er janvier 2024 est un lundi ; premier jeudi = 4 janvier.
      final echeances = calc.echeancesPassees(
        debutCycle: DateTime(2024, 1, 1),
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: DateTime(2024, 1, 4),
      );
      expect(echeances, [DateTime(2024, 1, 4)]);
    });

    test('aucune échéance si "maintenant" est avant le début du cycle', () {
      final echeances = calc.echeancesPassees(
        debutCycle: DateTime(2024, 2, 1),
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: DateTime(2024, 1, 1),
      );
      expect(echeances, isEmpty);
    });

    test('paymentDayOfWeek obligatoire pour une fréquence hebdomadaire', () {
      expect(
        () => calc.echeancesPassees(
          debutCycle: DateTime(2024, 1, 1),
          meetingFrequency: 'hebdomadaire',
          maintenant: DateTime(2024, 1, 10),
        ),
        throwsArgumentError,
      );
    });
  });

  group('échéances mensuelles', () {
    test('une échéance par mois au jour configuré', () {
      final echeances = calc.echeancesPassees(
        debutCycle: DateTime(2024, 1, 1),
        meetingFrequency: 'mensuelle',
        paymentDayOfMonth1: 5,
        maintenant: DateTime(2024, 3, 10),
      );
      expect(echeances, [
        DateTime(2024, 1, 5),
        DateTime(2024, 2, 5),
        DateTime(2024, 3, 5),
      ]);
    });

    test('un jour du mois trop grand est clampé au dernier jour existant (février)', () {
      final echeances = calc.echeancesPassees(
        debutCycle: DateTime(2024, 1, 1),
        meetingFrequency: 'mensuelle',
        paymentDayOfMonth1: 31,
        maintenant: DateTime(2024, 2, 29),
      );
      // 2024 est bissextile : février a 29 jours.
      expect(echeances, [DateTime(2024, 1, 31), DateTime(2024, 2, 29)]);
    });

    test('paymentDayOfMonth1 obligatoire pour une fréquence mensuelle', () {
      expect(
        () => calc.echeancesPassees(
          debutCycle: DateTime(2024, 1, 1),
          meetingFrequency: 'mensuelle',
          maintenant: DateTime(2024, 3, 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('échéances bimensuelles', () {
    test('deux échéances par mois, triées', () {
      final echeances = calc.echeancesPassees(
        debutCycle: DateTime(2024, 1, 1),
        meetingFrequency: 'bimensuelle',
        paymentDayOfMonth1: 20,
        paymentDayOfMonth2: 5,
        maintenant: DateTime(2024, 2, 5),
      );
      expect(echeances, [
        DateTime(2024, 1, 5),
        DateTime(2024, 1, 20),
        DateTime(2024, 2, 5),
      ]);
    });
  });

  group('soldeDuFcfa', () {
    test('cumule le montant dû sur plusieurs échéances non couvertes (scénario Mr AB)', () {
      // Carnet à 500F, 3 échéances passées, une seule payée (500F).
      final solde = calc.soldeDuFcfa(
        echeancesPassees: [DateTime(2024, 1, 4), DateTime(2024, 1, 11), DateTime(2024, 1, 18)],
        carnetsEngages: 1,
        valeurCarnetFcfa: 500,
        montantDejaPayeFcfa: 500,
      );
      expect(solde, 1000); // 2 échéances manquées x 500F
    });

    test('un membre à jour ou en avance doit 0, jamais un solde négatif', () {
      final solde = calc.soldeDuFcfa(
        echeancesPassees: [DateTime(2024, 1, 4)],
        carnetsEngages: 1,
        valeurCarnetFcfa: 500,
        montantDejaPayeFcfa: 2000,
      );
      expect(solde, 0);
    });
  });
}

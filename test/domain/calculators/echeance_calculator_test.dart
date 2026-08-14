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

  group('montantMaxTransactionFcfa / estUnMontantValide', () {
    test('une transaction ne peut jamais dépasser 5 parts', () {
      expect(calc.montantMaxTransactionFcfa(500), 2500);
    });

    test('un montant multiple exact entre 1x et 5x la valeur de la part est valide', () {
      expect(calc.estUnMontantValide(montantFcfa: 500, valeurPartFcfa: 500), isTrue);
      expect(calc.estUnMontantValide(montantFcfa: 2500, valeurPartFcfa: 500), isTrue);
    });

    test('un montant intermédiaire (pas un multiple exact) est invalide', () {
      expect(calc.estUnMontantValide(montantFcfa: 700, valeurPartFcfa: 500), isFalse);
    });

    test('un montant au-delà de 5 parts est invalide', () {
      expect(calc.estUnMontantValide(montantFcfa: 3000, valeurPartFcfa: 500), isFalse);
    });

    test('zéro ou négatif est invalide', () {
      expect(calc.estUnMontantValide(montantFcfa: 0, valeurPartFcfa: 500), isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/loan_window_calculator.dart';

/// Fenêtres de crédit selon la fréquence de réunion — voir
/// DECISIONS.md, "Fenêtres de crédit selon la fréquence de réunion"
/// (RETOURS_TERRAIN.md, point 10).
void main() {
  const calc = LoanWindowCalculator();
  final debutCycle = DateTime(2024, 1, 4); // jeudi

  group('hebdomadaire : 4e réunion, puis chaque 4', () {
    test('fermée avant la 4e réunion', () {
      // Réunions : 4, 11, 18 janvier (3 réunions).
      expect(
        calc.fenetreOuverte(
          debutCycle: debutCycle,
          meetingFrequency: 'hebdomadaire',
          paymentDayOfWeek: DateTime.thursday,
          maintenant: debutCycle.add(const Duration(days: 14)), // 3e réunion
        ),
        isFalse,
      );
    });

    test('ouverte à la 4e réunion', () {
      expect(
        calc.fenetreOuverte(
          debutCycle: debutCycle,
          meetingFrequency: 'hebdomadaire',
          paymentDayOfWeek: DateTime.thursday,
          maintenant: debutCycle.add(const Duration(days: 21)), // 4e réunion
        ),
        isTrue,
      );
    });

    test('reste ouverte jusqu\'à la réunion suivante (pas seulement le jour même)', () {
      expect(
        calc.fenetreOuverte(
          debutCycle: debutCycle,
          meetingFrequency: 'hebdomadaire',
          paymentDayOfWeek: DateTime.thursday,
          maintenant: debutCycle.add(const Duration(days: 25)), // entre la 4e et la 5e
        ),
        isTrue,
      );
    });

    test('refermée à la 5e réunion, rouvre à la 8e', () {
      expect(
        calc.fenetreOuverte(
          debutCycle: debutCycle,
          meetingFrequency: 'hebdomadaire',
          paymentDayOfWeek: DateTime.thursday,
          maintenant: debutCycle.add(const Duration(days: 28)), // 5e réunion
        ),
        isFalse,
      );
      expect(
        calc.fenetreOuverte(
          debutCycle: debutCycle,
          meetingFrequency: 'hebdomadaire',
          paymentDayOfWeek: DateTime.thursday,
          maintenant: debutCycle.add(const Duration(days: 49)), // 8e réunion
        ),
        isTrue,
      );
    });
  });

  group('mensuelle/bimensuelle : chaque 2e réunion', () {
    test('fermée à la 1re réunion, ouverte à la 2e', () {
      expect(
        calc.fenetreOuverte(
          debutCycle: DateTime(2024, 1, 5),
          meetingFrequency: 'mensuelle',
          paymentDayOfMonth1: 5,
          maintenant: DateTime(2024, 1, 5), // 1re réunion
        ),
        isFalse,
      );
      expect(
        calc.fenetreOuverte(
          debutCycle: DateTime(2024, 1, 5),
          meetingFrequency: 'mensuelle',
          paymentDayOfMonth1: 5,
          maintenant: DateTime(2024, 2, 5), // 2e réunion
        ),
        isTrue,
      );
    });

    test('bimensuelle : même règle, deux réunions par mois comptent double', () {
      expect(
        calc.fenetreOuverte(
          debutCycle: DateTime(2024, 1, 5),
          meetingFrequency: 'bimensuelle',
          paymentDayOfMonth1: 5,
          paymentDayOfMonth2: 20,
          maintenant: DateTime(2024, 1, 20), // 2e réunion (5 puis 20 janvier)
        ),
        isTrue,
      );
    });
  });

  test('aucune réunion encore passée : fenêtre fermée', () {
    expect(
      calc.fenetreOuverte(
        debutCycle: debutCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: debutCycle.subtract(const Duration(days: 1)),
      ),
      isFalse,
    );
  });

  test('reunionsAvantProchaineFenetre compte juste', () {
    expect(
      calc.reunionsAvantProchaineFenetre(
        debutCycle: debutCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: debutCycle, // 1re réunion
      ),
      3, // encore 3 réunions avant la 4e
    );
    expect(
      calc.reunionsAvantProchaineFenetre(
        debutCycle: debutCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: debutCycle.add(const Duration(days: 21)), // 4e réunion
      ),
      0,
    );
  });
}

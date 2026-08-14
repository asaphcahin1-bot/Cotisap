import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/membership_closure_calculator.dart';

/// Inscription de nouveaux membres : sans limite, sauf fin de cycle —
/// voir DECISIONS.md (RETOURS_TERRAIN.md, point 16).
void main() {
  const calc = MembershipClosureCalculator();
  final debutCycle = DateTime(2024, 1, 4); // jeudi
  // Réunions hebdomadaires du 4 janvier au 1er février inclus : 4, 11,
  // 18, 25 janvier, 1er février -> 5 réunions au total sur le cycle.
  final finDeCycle = DateTime(2024, 2, 1);

  test('encore ouvertes juste après la 1re réunion (4 réunions restantes)', () {
    expect(
      calc.inscriptionsFermees(
        debutCycle: debutCycle,
        finDeCycle: finDeCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: debutCycle, // 1re réunion
      ),
      isFalse,
    );
  });

  test('encore ouvertes après la 2e réunion (3 réunions restantes)', () {
    expect(
      calc.inscriptionsFermees(
        debutCycle: debutCycle,
        finDeCycle: finDeCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: debutCycle.add(const Duration(days: 7)), // 2e réunion
      ),
      isFalse,
    );
  });

  test('fermées dès qu\'il ne reste plus que 2 réunions', () {
    expect(
      calc.inscriptionsFermees(
        debutCycle: debutCycle,
        finDeCycle: finDeCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: debutCycle.add(const Duration(days: 14)), // 3e réunion
      ),
      isTrue,
    );
  });

  test('restent fermées après la fin prévue du cycle (jamais rouvertes)', () {
    expect(
      calc.inscriptionsFermees(
        debutCycle: debutCycle,
        finDeCycle: finDeCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: DateTime(2024, 3, 1), // bien après la fin prévue
      ),
      isTrue,
    );
  });

  test('reunionsRestantesAvantFinDeCycle compte juste', () {
    expect(
      calc.reunionsRestantesAvantFinDeCycle(
        debutCycle: debutCycle,
        finDeCycle: finDeCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: debutCycle, // 1re réunion sur 5
      ),
      4,
    );
    expect(
      calc.reunionsRestantesAvantFinDeCycle(
        debutCycle: debutCycle,
        finDeCycle: finDeCycle,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
        maintenant: finDeCycle, // dernière réunion
      ),
      0,
    );
  });

  test(
      'une fréquence mal configurée ne bloque jamais silencieusement — reste ouvert',
      () {
    expect(
      calc.inscriptionsFermees(
        debutCycle: debutCycle,
        finDeCycle: finDeCycle,
        meetingFrequency: 'hebdomadaire',
        // paymentDayOfWeek manquant -> ArgumentError interne, capturée.
        maintenant: debutCycle,
      ),
      isFalse,
    );
  });
}

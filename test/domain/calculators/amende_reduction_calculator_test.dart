import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/amende_reduction_calculator.dart';

/// Reprend les deux exemples donnés par le fondateur (voir DECISIONS.md,
/// "Les amendes ne sont plus une dette").
void main() {
  const calc = AmendeReductionCalculator();

  test(
    'cotisé 10 000 F (10 parts), amende de 100 F : neuf parts reconnues',
    () {
      final r = calc.calculer(
        rawCotisationFcfa: 10000,
        amendesNonSoldeesFcfa: 100,
        valeurPartFcfa: 1000,
      );
      expect(r.partsReconnues, 9);
      expect(r.residuFcfa, 900);
      expect(r.montantEffectivementDeduitFcfa, 100);
      // Vérifie l'invariant comptable : rien ne se perd ni ne se crée.
      expect(
        r.partsReconnues * 1000 +
            r.residuFcfa +
            r.montantEffectivementDeduitFcfa,
        10000,
      );
    },
  );

  test(
    'cotisé 10 000 F (10 parts), amende de 1800 F : huit parts reconnues',
    () {
      final r = calc.calculer(
        rawCotisationFcfa: 10000,
        amendesNonSoldeesFcfa: 1800,
        valeurPartFcfa: 1000,
      );
      expect(r.partsReconnues, 8);
      expect(r.residuFcfa, 200);
      expect(r.montantEffectivementDeduitFcfa, 1800);
    },
  );

  test(
    'cotisé 10 000 F, amende de 200 F : neuf parts + 800 F de résidu (exemple exact du fondateur)',
    () {
      final r = calc.calculer(
        rawCotisationFcfa: 10000,
        amendesNonSoldeesFcfa: 200,
        valeurPartFcfa: 1000,
      );
      expect(r.partsReconnues, 9);
      expect(r.residuFcfa, 800);
      expect(r.montantEffectivementDeduitFcfa, 200);
    },
  );

  test(
    'amende exactement un multiple de la valeur de la part : aucun résidu',
    () {
      final r = calc.calculer(
        rawCotisationFcfa: 10000,
        amendesNonSoldeesFcfa: 2000,
        valeurPartFcfa: 1000,
      );
      expect(r.partsReconnues, 8);
      expect(r.residuFcfa, 0);
    },
  );

  test('aucune amende : toutes les parts restent reconnues, aucun résidu', () {
    final r = calc.calculer(
      rawCotisationFcfa: 10000,
      amendesNonSoldeesFcfa: 0,
      valeurPartFcfa: 1000,
    );
    expect(r.partsReconnues, 10);
    expect(r.residuFcfa, 0);
    expect(r.montantEffectivementDeduitFcfa, 0);
  });

  test(
    'amende supérieure à la cotisation totale : 0 part, jamais négatif, jamais une dette',
    () {
      final r = calc.calculer(
        rawCotisationFcfa: 1000,
        amendesNonSoldeesFcfa: 5000,
        valeurPartFcfa: 1000,
      );
      expect(r.partsReconnues, 0);
      expect(r.residuFcfa, 0);
      // Jamais déduit plus que ce qu'il a réellement cotisé.
      expect(r.montantEffectivementDeduitFcfa, 1000);
    },
  );

  test(
    'amende égale exactement à la cotisation totale : 0 part, résidu nul',
    () {
      final r = calc.calculer(
        rawCotisationFcfa: 1000,
        amendesNonSoldeesFcfa: 1000,
        valeurPartFcfa: 1000,
      );
      expect(r.partsReconnues, 0);
      expect(r.residuFcfa, 0);
      expect(r.montantEffectivementDeduitFcfa, 1000);
    },
  );

  group('validation des entrées', () {
    test('rejette une cotisation brute négative', () {
      expect(
        () => calc.calculer(
          rawCotisationFcfa: -1,
          amendesNonSoldeesFcfa: 0,
          valeurPartFcfa: 1000,
        ),
        throwsArgumentError,
      );
    });

    test('rejette des amendes négatives', () {
      expect(
        () => calc.calculer(
          rawCotisationFcfa: 0,
          amendesNonSoldeesFcfa: -1,
          valeurPartFcfa: 1000,
        ),
        throwsArgumentError,
      );
    });

    test('rejette une valeur de part nulle ou négative', () {
      expect(
        () => calc.calculer(
          rawCotisationFcfa: 1000,
          amendesNonSoldeesFcfa: 0,
          valeurPartFcfa: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}

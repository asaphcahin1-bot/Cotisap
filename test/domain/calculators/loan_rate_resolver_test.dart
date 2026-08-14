import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/loan_rate_resolver.dart';

/// Règles confirmées avec le fondateur le 2026-08-09 (voir DECISIONS.md,
/// "Résolution automatique du taux de prêt") : plafond souple de 3x
/// l'épargne cotisée (comparé au total emprunté, pas au nouveau prêt
/// seul ; bascule totale à 15 %, jamais un taux mixte), et fenêtre des
/// 3 derniers mois du cycle (reclassement automatique, jamais de
/// blocage).
void main() {
  const resolver = LoanRateResolver();

  // Fin de cycle fixée au 1er octobre 2024 -> fenêtre des 3 derniers
  // mois commence le 1er juillet 2024.
  final finDeCycle = DateTime(2024, 10, 1);

  group('plafond de 3x l\'épargne cotisée (hors fenêtre des 3 derniers mois)', () {
    test('sous le plafond : reste dans le carnet (10 %)', () {
      final r = resolver.resoudre(
        cotiseTotalFcfa: 10000,
        empruntesEnCoursFcfa: 0,
        principalDemandeFcfa: 20000, // <= 3 x 10000
        maintenant: DateTime(2024, 5, 1),
        finDeCycle: finDeCycle,
      );
      expect(r.tauxPercent, 10);
      expect(r.horsCarnet, isFalse);
      expect(r.raison, isNull);
    });

    test('exactement au plafond (3x pile) : encore dans le carnet', () {
      final r = resolver.resoudre(
        cotiseTotalFcfa: 10000,
        empruntesEnCoursFcfa: 0,
        principalDemandeFcfa: 30000, // == 3 x 10000
        maintenant: DateTime(2024, 5, 1),
        finDeCycle: finDeCycle,
      );
      expect(r.tauxPercent, 10);
      expect(r.horsCarnet, isFalse);
    });

    test('juste au-dessus du plafond : bascule entièrement hors carnet (15 %)', () {
      final r = resolver.resoudre(
        cotiseTotalFcfa: 10000,
        empruntesEnCoursFcfa: 0,
        principalDemandeFcfa: 30001, // > 3 x 10000
        maintenant: DateTime(2024, 5, 1),
        finDeCycle: finDeCycle,
      );
      expect(r.tauxPercent, 15);
      expect(r.horsCarnet, isTrue);
      expect(r.raison, contains('dépasse'));
    });

    test('un prêt déjà en cours compte dans le total emprunté, pas seulement le nouveau', () {
      // Cotisé 10000 -> plafond 30000. Déjà 25000 empruntés (dans le
      // carnet à l'époque) ; ce nouveau prêt de 10000 ferait 35000,
      // au-dessus du plafond -> bascule entièrement à 15 %, même si
      // 10000 seul serait resté sous le plafond isolément.
      final r = resolver.resoudre(
        cotiseTotalFcfa: 10000,
        empruntesEnCoursFcfa: 25000,
        principalDemandeFcfa: 10000,
        maintenant: DateTime(2024, 5, 1),
        finDeCycle: finDeCycle,
      );
      expect(r.tauxPercent, 15);
      expect(r.horsCarnet, isTrue);
    });

    test('aucune cotisation encore : tout prêt est hors carnet', () {
      final r = resolver.resoudre(
        cotiseTotalFcfa: 0,
        empruntesEnCoursFcfa: 0,
        principalDemandeFcfa: 1,
        maintenant: DateTime(2024, 5, 1),
        finDeCycle: finDeCycle,
      );
      expect(r.tauxPercent, 15);
      expect(r.horsCarnet, isTrue);
    });
  });

  group('fenêtre des 3 derniers mois du cycle', () {
    test('juste avant la fenêtre : le plafond seul décide', () {
      final r = resolver.resoudre(
        cotiseTotalFcfa: 100000,
        empruntesEnCoursFcfa: 0,
        principalDemandeFcfa: 1000, // largement sous le plafond
        maintenant: DateTime(2024, 6, 30),
        finDeCycle: finDeCycle,
      );
      expect(r.tauxPercent, 10);
      expect(r.horsCarnet, isFalse);
    });

    test('au premier jour de la fenêtre : hors carnet même très sous le plafond', () {
      final r = resolver.resoudre(
        cotiseTotalFcfa: 100000,
        empruntesEnCoursFcfa: 0,
        principalDemandeFcfa: 1000,
        maintenant: DateTime(2024, 7, 1),
        finDeCycle: finDeCycle,
      );
      expect(r.tauxPercent, 15);
      expect(r.horsCarnet, isTrue);
      expect(r.raison, contains('derniers'));
    });

    test('après la fin de cycle : toujours hors carnet (jamais de blocage)', () {
      final r = resolver.resoudre(
        cotiseTotalFcfa: 100000,
        empruntesEnCoursFcfa: 0,
        principalDemandeFcfa: 1000,
        maintenant: DateTime(2024, 11, 1),
        finDeCycle: finDeCycle,
      );
      expect(r.tauxPercent, 15);
      expect(r.horsCarnet, isTrue);
    });

    test('la fenêtre prime sur le plafond même si le plafond aurait aussi été dépassé', () {
      final r = resolver.resoudre(
        cotiseTotalFcfa: 0,
        empruntesEnCoursFcfa: 0,
        principalDemandeFcfa: 1,
        maintenant: DateTime(2024, 7, 15),
        finDeCycle: finDeCycle,
      );
      expect(r.horsCarnet, isTrue);
      expect(r.raison, contains('derniers'));
    });
  });

  group('validation des entrées', () {
    test('rejette une épargne cotisée négative', () {
      expect(
        () => resolver.resoudre(
          cotiseTotalFcfa: -1,
          empruntesEnCoursFcfa: 0,
          principalDemandeFcfa: 1000,
          maintenant: DateTime(2024, 5, 1),
          finDeCycle: finDeCycle,
        ),
        throwsArgumentError,
      );
    });

    test('rejette un total emprunté en cours négatif', () {
      expect(
        () => resolver.resoudre(
          cotiseTotalFcfa: 0,
          empruntesEnCoursFcfa: -1,
          principalDemandeFcfa: 1000,
          maintenant: DateTime(2024, 5, 1),
          finDeCycle: finDeCycle,
        ),
        throwsArgumentError,
      );
    });

    test('rejette un montant demandé nul ou négatif', () {
      expect(
        () => resolver.resoudre(
          cotiseTotalFcfa: 0,
          empruntesEnCoursFcfa: 0,
          principalDemandeFcfa: 0,
          maintenant: DateTime(2024, 5, 1),
          finDeCycle: finDeCycle,
        ),
        throwsArgumentError,
      );
    });
  });
}

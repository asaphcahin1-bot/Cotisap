import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/loan_balance_calculator.dart';

void main() {
  const calc = LoanBalanceCalculator();

  test(
    'avant toute échéance : montant dû = principal + intérêt initial, temps restant = durée complète',
    () {
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
    },
  );

  test(
    'un remboursement intégral avant l\'échéance annule tout intérêt supplémentaire',
    () {
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
    },
  );

  test(
    'durée expirée sans remboursement complet : passe au rouge, pas de recomposition avant un mois plein',
    () {
      // 10000 à 10% -> 11000 dû. Remboursement partiel de 5000 avant
      // l'échéance des 90 jours -> reste 6000. La période normale
      // expire sans être soldé -> le prêt passe au rouge (voir
      // DECISIONS.md, "Dette de prêt au rouge") mais un seul jour plus
      // tard : aucun mois calendaire plein ne s'est encore écoulé,
      // donc pas encore de recomposition à 10 %.
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
      expect(r.montantDuFcfa, 6000);
      expect(r.estAuRouge, isTrue);
      expect(r.soldeAuDebutDuRougeFcfa, 6000);
      expect(r.nombrePeriodesEcoulees, 1);
    },
  );

  group('au rouge (voir DECISIONS.md, "Dette de prêt au rouge")', () {
    test(
      'exemple chiffré du fondateur : 100 000 -> 110 000 -> 121 000, un mois puis deux',
      () {
        // Période normale de 90 jours déjà expirée sans remboursement —
        // debut choisi pour que la période normale se termine pile au
        // 1er janvier (100 000 F dû, sans intérêt initial pour cet
        // exemple : taux à 0 % sur la période normale, seul le rouge
        // nous intéresse ici).
        final debutRouge = DateTime(2024, 1, 1);

        // 1 mois après le début du rouge -> +10 %.
        final unMois = calc.calculer(
          principalFcfa: 100000,
          interestRatePercent: 0,
          dureeJours: 1,
          debut: debutRouge.subtract(const Duration(days: 1)),
          remboursements: [],
          maintenant: DateTime(2024, 2, 1),
        );
        expect(unMois.montantDuFcfa, 110000);
        expect(unMois.estAuRouge, isTrue);

        // 2 mois après le début du rouge -> +10 % une seconde fois sur
        // le nouveau solde (composition continue, voir DECISIONS.md).
        final deuxMois = calc.calculer(
          principalFcfa: 100000,
          interestRatePercent: 0,
          dureeJours: 1,
          debut: debutRouge.subtract(const Duration(days: 1)),
          remboursements: [],
          maintenant: DateTime(2024, 3, 1),
        );
        expect(deuxMois.montantDuFcfa, 121000);
      },
    );

    test('reste faux (jamais au rouge) tant que la période normale n\'a pas expiré', () {
      final r = calc.calculer(
        principalFcfa: 10000,
        interestRatePercent: 10,
        dureeJours: 90,
        debut: DateTime(2024, 1, 1),
        remboursements: [],
        maintenant: DateTime(2024, 2, 1),
      );
      expect(r.estAuRouge, isFalse);
      expect(r.soldeAuDebutDuRougeFcfa, isNull);
    });

    test('redevient faux une fois le prêt soldé, même après être passé au rouge', () {
      final r = calc.calculer(
        principalFcfa: 10000,
        interestRatePercent: 10,
        dureeJours: 90,
        debut: DateTime(2024, 1, 1),
        remboursements: [
          RemboursementSimple(montantFcfa: 12100, date: DateTime(2024, 5, 1)),
        ],
        maintenant: DateTime(2024, 6, 1),
      );
      expect(r.montantDuFcfa, 0);
      expect(r.estAuRouge, isFalse);
    });

    test(
      'un prêt créé directement au rouge (reconduction, voir dejaAuRouge) compose dès le début, sans période de grâce',
      () {
        final r = calc.calculer(
          principalFcfa: 100000,
          interestRatePercent: 10, // ignoré : le rouge est toujours à 10 %
          dureeJours: 90,
          debut: DateTime(2024, 1, 1),
          remboursements: [],
          maintenant: DateTime(2024, 2, 1),
          dejaAuRouge: true,
        );
        expect(r.montantDuFcfa, 110000);
        expect(r.estAuRouge, isTrue);
        expect(r.soldeAuDebutDuRougeFcfa, 100000);
      },
    );
  });

  test(
    'sans durée connue (prêt importé) : intérêt appliqué une seule fois, jamais recomposé',
    () {
      final r = calc.calculer(
        principalFcfa: 5000,
        interestRatePercent: 10,
        dureeJours: null,
        debut: DateTime(2024, 1, 1),
        remboursements: [
          RemboursementSimple(montantFcfa: 2000, date: DateTime(2024, 6, 1)),
        ],
        maintenant: DateTime(
          2025,
          1,
          1,
        ), // bien après ce qui serait une échéance
      );
      expect(r.montantDuFcfa, 3500); // 5500 - 2000, sans recomposition
      expect(r.joursRestantsPeriodeCourante, isNull);
    },
  );

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

  group('délai de recouvrement aligné sur les réunions (voir DECISIONS.md)', () {
    // 4 janvier 2024 est un jeudi. Réunions hebdomadaires le jeudi.
    // Brut (4 janvier + 90 jours) = 3 avril 2024, un mercredi — pas une
    // réunion. Le jeudi suivant (4 avril) dépasserait les 90 jours ->
    // interdit. Le jeudi précédent (28 mars) est donc la vraie échéance,
    // même s'il est numériquement plus loin des 90 jours que le 4 avril.
    final debut = DateTime(2024, 1, 4);

    test(
      'la borne de période est ramenée à la dernière réunion, jamais après le délai',
      () {
        final r = calc.calculer(
          principalFcfa: 10000,
          interestRatePercent: 10,
          dureeJours: 90,
          debut: debut,
          remboursements: [],
          maintenant: DateTime(2024, 3, 27), // juste avant le 28 mars
          meetingFrequency: 'hebdomadaire',
          paymentDayOfWeek: DateTime.thursday,
        );
        // Encore dans la première période (le palier du 28 mars n'est pas
        // encore atteint) -> aucune recomposition, jours restants = 1.
        expect(r.nombrePeriodesEcoulees, 1);
        expect(r.joursRestantsPeriodeCourante, 1);
      },
    );

    test(
      'le palier tombe le 28 mars (jeudi), pas le 3 avril (mercredi, hors délai) -> passe au rouge',
      () {
        // Marge de sécurité après le 28 mars (plutôt que l'instant pile)
        // pour éviter tout artefact d'arithmétique de dates autour du
        // changement d'heure de mars, sans rapport avec la règle testée.
        final r = calc.calculer(
          principalFcfa: 10000,
          interestRatePercent: 10,
          dureeJours: 90,
          debut: debut,
          remboursements: [],
          maintenant: DateTime(2024, 3, 29),
          meetingFrequency: 'hebdomadaire',
          paymentDayOfWeek: DateTime.thursday,
        );
        // Le palier du 28 mars est atteint -> passe au rouge (voir
        // DECISIONS.md), mais un seul jour plus tard : aucun mois
        // calendaire plein écoulé, pas encore de recomposition.
        expect(r.estAuRouge, isTrue);
        expect(r.nombrePeriodesEcoulees, 1);
        expect(r.montantDuFcfa, 11000);
      },
    );

    test(
      'sans meetingFrequency fourni, le calcul brut en jours calendaires est inchangé',
      () {
        final r = calc.calculer(
          principalFcfa: 10000,
          interestRatePercent: 10,
          dureeJours: 90,
          debut: debut,
          remboursements: [],
          maintenant: DateTime(2024, 4, 4), // au-delà des 90 jours calendaires
        );
        expect(r.estAuRouge, isTrue);
        expect(r.nombrePeriodesEcoulees, 1);
        expect(r.montantDuFcfa, 11000);
      },
    );

    test(
      'une fois au rouge, la composition mensuelle continue indéfiniment, jamais réalignée sur les réunions',
      () {
      // Loin après le palier du 28 mars (voir test ci-dessus) : plusieurs
      // mois calendaires pleins se sont écoulés depuis, donc plusieurs
      // recompositions à 10 % (voir DECISIONS.md, "Dette de prêt au
      // rouge") — jamais un nouveau palier réaligné sur les réunions.
      final r = calc.calculer(
        principalFcfa: 10000,
        interestRatePercent: 10,
        dureeJours: 90,
        debut: debut,
        remboursements: [],
        maintenant: DateTime(2024, 7, 1),
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
      );
      expect(r.estAuRouge, isTrue);
      // 1 (normale) + au moins 3 mois pleins (28 mars -> fin juin) -> au
      // moins 4 périodes.
      expect(r.nombrePeriodesEcoulees, greaterThanOrEqualTo(4));
    });

    test(
      'prêt sans durée connue : l\'alignement sur les réunions ne s\'applique pas',
      () {
        final r = calc.calculer(
          principalFcfa: 10000,
          interestRatePercent: 10,
          dureeJours: null,
          debut: debut,
          remboursements: [],
          maintenant: DateTime(2024, 4, 3),
          meetingFrequency: 'hebdomadaire',
          paymentDayOfWeek: DateTime.thursday,
        );
        expect(r.joursRestantsPeriodeCourante, isNull);
        expect(r.nombrePeriodesEcoulees, 1);
      },
    );
  });

  group('changement d\'heure (DST) — retour terrain du 2026-08-15', () {
    test(
        'joursRestantsPeriodeCourante reste exactement 90 même en '
        'traversant le passage à l\'heure d\'été', () {
      // 1er janvier 2024 -> 31 mars 2024 (90 jours calendaires plus
      // tard) traverse le passage à l'heure d'été du 10 mars 2024 aux
      // États-Unis. Avant correction, finPeriode.difference(maintenant)
      // renvoyait 89 sur cette machine (une heure "perdue" par le
      // changement d'heure, tronquée par .inDays).
      final r = calc.calculer(
        principalFcfa: 10000,
        interestRatePercent: 10,
        dureeJours: 90,
        debut: DateTime(2024, 1, 1),
        remboursements: [],
        maintenant: DateTime(2024, 1, 1),
      );
      expect(r.joursRestantsPeriodeCourante, 90);
    });
  });
}

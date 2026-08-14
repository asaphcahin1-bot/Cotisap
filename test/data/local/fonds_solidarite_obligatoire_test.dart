import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

/// Fonds de solidarité obligatoire — voir DECISIONS.md, "Fonds de
/// solidarité obligatoire" : montant fixe par carnet, dû à chaque
/// réunion, souple dans le rythme, mais tout doit être soldé avant le
/// partage de fin de cycle.
void main() {
  late AppDatabase db;
  final debutCycle = DateTime(2024, 1, 4); // jeudi

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    AppClock.definir(debutCycle);
  });

  tearDown(() async {
    AppClock.definir(null);
    await db.close();
  });

  // Un membre = un seul carnet, toujours (voir DECISIONS.md, "Un membre
  // = un seul carnet").
  Future<({String groupId, String cycleId, String membreId})> preparer({
    int montantSolidariteObligatoireFcfa = 500,
    DateTime? joinedAt,
  }) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantSolidariteObligatoireFcfa: montantSolidariteObligatoireFcfa,
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
      joinedAt: joinedAt ?? debutCycle,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
    );
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  test('rien versé, le jour même de la première réunion : solde = 1 réunion',
      () async {
    final ctx = await preparer();
    expect(
      await db.soldeSolidariteObligatoireFcfa(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
      ),
      500,
    );
  });

  test('le solde s\'accumule réunion après réunion tant que rien n\'est versé',
      () async {
    final ctx = await preparer();
    AppClock.definir(debutCycle.add(const Duration(days: 7))); // 2e réunion
    expect(
      await db.soldeSolidariteObligatoireFcfa(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
      ),
      1000,
    );
  });

  test('un versement réduit le solde, jamais sous zéro', () async {
    final ctx = await preparer();
    await db.enregistrerContributionFondsSolidarite(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      montantFcfa: 500,
      motif: 'Fonds de solidarité obligatoire',
      recordedByPhone: '+2250000099',
    );
    expect(
      await db.soldeSolidariteObligatoireFcfa(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
      ),
      0,
    );
  });

  test('un membre peut payer d\'avance : solde reste à 0 tant que le crédit n\'est pas épuisé',
      () async {
    final ctx = await preparer();
    // Paie 3 réunions d'avance en une fois.
    await db.enregistrerContributionFondsSolidarite(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      montantFcfa: 1500,
      motif: 'Fonds de solidarité obligatoire',
      recordedByPhone: '+2250000099',
    );
    AppClock.definir(debutCycle.add(const Duration(days: 14))); // 3e réunion
    expect(
      await db.soldeSolidariteObligatoireFcfa(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
      ),
      0,
    );
    AppClock.definir(debutCycle.add(const Duration(days: 21))); // 4e réunion
    expect(
      await db.soldeSolidariteObligatoireFcfa(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
      ),
      500,
    );
  });

  test('montant à 0 : le fonds n\'est pas obligatoire, solde toujours nul',
      () async {
    final ctx = await preparer(montantSolidariteObligatoireFcfa: 0);
    expect(
      await db.soldeSolidariteObligatoireFcfa(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
      ),
      0,
    );
  });

  test('un membre entré en cours de cycle ne doit rien pour les réunions avant son entrée',
      () async {
    final entreeMembre = debutCycle.add(const Duration(days: 14));
    final ctx = await preparer(joinedAt: entreeMembre);
    AppClock.definir(entreeMembre);
    expect(
      await db.soldeSolidariteObligatoireFcfa(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
      ),
      500,
      reason: 'seule sa première réunion compte, pas celles d\'avant son entrée',
    );
  });

  test(
    'soldesSolidariteObligatoireNonSoldesDuCycle ne liste que les membres en retard',
    () async {
      final ctx = await preparer();
      final nonSoldes = await db.soldesSolidariteObligatoireNonSoldesDuCycle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
      );
      expect(nonSoldes, {ctx.membreId: 500});

      await db.enregistrerContributionFondsSolidarite(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        montantFcfa: 500,
        motif: 'Fonds de solidarité obligatoire',
        recordedByPhone: '+2250000099',
      );
      expect(
        await db.soldesSolidariteObligatoireNonSoldesDuCycle(
          groupId: ctx.groupId,
          cycleId: ctx.cycleId,
        ),
        isEmpty,
      );
    },
  );

  test(
    'cloturerCycleEtOuvrirSuivant refuse tant qu\'un membre n\'a pas soldé le fonds obligatoire',
    () async {
      final ctx = await preparer();
      expect(
        () => db.cloturerCycleEtOuvrirSuivant(
          groupId: ctx.groupId,
          cycleIdACloturer: ctx.cycleId,
          nouveauPartValueFcfa: 500,
          nouveauInterestRatePercent: 10,
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'cloturerCycleEtOuvrirSuivant réussit une fois le fonds obligatoire soldé',
    () async {
      final ctx = await preparer();
      await db.enregistrerContributionFondsSolidarite(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        montantFcfa: 500,
        motif: 'Fonds de solidarité obligatoire',
        recordedByPhone: '+2250000099',
      );
      final nouveauCycleId = await db.cloturerCycleEtOuvrirSuivant(
        groupId: ctx.groupId,
        cycleIdACloturer: ctx.cycleId,
        nouveauPartValueFcfa: 500,
        nouveauInterestRatePercent: 10,
      );
      expect(nouveauCycleId, isNotEmpty);
    },
  );
}

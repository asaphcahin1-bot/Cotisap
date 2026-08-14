import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('cloturerCycleEtOuvrirSuivant clôture le cycle actuel et ouvre le suivant avec ses propres paramètres',
      () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycle1Id = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);

    final cycle2Id = await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle1Id,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 10,
      nouveauLateFeeFcfa: 500,
    );

    final cycle1 = await (db.select(db.cycles)..where((c) => c.id.equals(cycle1Id))).getSingle();
    final cycle2 = await (db.select(db.cycles)..where((c) => c.id.equals(cycle2Id))).getSingle();

    expect(cycle1.status, 'cloture');
    expect(cycle1.endedAt, isNotNull);
    expect(cycle2.status, 'en_cours');
    expect(cycle2.cycleNumber, 2);
    expect(cycle2.partValueFcfa, 1000);
    expect(cycle2.interestRatePercent, 10);
    expect(cycle2.lateFeeFcfa, 500);

    expect(await db.cycleEnCours(groupId), isNotNull);
    expect((await db.cycleEnCours(groupId))!.id, cycle2Id);
  });

  test('un cycle déjà clos ne peut pas être clôturé une seconde fois', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycle1Id = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);
    await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle1Id,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 10,
    );

    expect(
      () => db.cloturerCycleEtOuvrirSuivant(
        groupId: groupId,
        cycleIdACloturer: cycle1Id,
        nouveauPartValueFcfa: 1000,
        nouveauInterestRatePercent: 10,
      ),
      throwsStateError,
    );
  });

  test('les cotisations du cycle clos restent isolées du nouveau cycle', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final memberId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycle1Id = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycle1Id,
      memberId: memberId,
      partsCount: 3,
      recordedByPhone: '+2250000099',
    );
    // Condition de clôture (voir DECISIONS.md, "Clôture de cycle
    // conditionnée au paiement de tous les membres").
    await db.confirmerPaiementMembre(
      groupId: groupId,
      cycleId: cycle1Id,
      memberId: memberId,
      confirmedByPhone: '+2250000099',
    );

    final cycle2Id = await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle1Id,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 10,
    );

    expect(await db.cotisationsDuCycle(cycle1Id), hasLength(1));
    expect(await db.cotisationsDuCycle(cycle2Id), isEmpty);
  });

  test('le fonds de solidarité n\'est jamais réinitialisé par une clôture de cycle', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycle1Id = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);
    await db.enregistrerContributionFondsSolidarite(
      groupId: groupId,
      cycleId: cycle1Id,
      memberId: null,
      montantFcfa: 2000,
      motif: 'Cotisation annuelle',
      recordedByPhone: '+2250000099',
    );

    await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle1Id,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 10,
    );

    expect(await db.totalFondsSolidarite(groupId), 2000);
  });

  test('pretsNonSoldesDuCycle signale un prêt confirmé partiellement remboursé, ignore les autres',
      () async {
    final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
        paymentDayOfMonth1: 5);
    final membre1 = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000001');
    final membre2 = await db.ajouterMembre(
        groupId: groupId, fullName: 'Kofi Yao', phoneNumber: '+2250000002');
    final membre3 = await db.ajouterMembre(
        groupId: groupId, fullName: 'Awa Traore', phoneNumber: '+2250000003');
    final debutCycle = DateTime(2024, 1, 5);
    final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 10,
        startedAt: debutCycle);
    // Fenêtre de crédit + caisse disponible (voir DECISIONS.md).
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membre1,
      partsCount: 60, // 30 000 F, largement au-dessus des 3 prêts
      recordedByPhone: '+2250000099',
    );
    AppClock.definir(DateTime(2024, 2, 5)); // 2e réunion -> fenêtre ouverte
    addTearDown(() => AppClock.definir(null));

    // Prêt confirmé, partiellement remboursé -> doit être signalé.
    final pretNonSolde = await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membre1,
      principalFcfa: 10000,
      interestRatePercent: 10,
      initiatedByPhone: '+2250000099',
      confirmationCode: '1234',
    );
    await db.confirmerPret(
        pretId: pretNonSolde.pretId, codeSaisi: '1234', confirmedByPhone: '+2250000001');
    await db.enregistrerRemboursement(
      pretId: pretNonSolde.pretId,
      montantFcfa: 5000,
      recordedByPhone: '+2250000099',
    );

    // Prêt confirmé, totalement remboursé -> ne doit pas être signalé.
    final pretSolde = await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membre2,
      principalFcfa: 5000,
      interestRatePercent: 10,
      initiatedByPhone: '+2250000099',
      confirmationCode: '5678',
    );
    await db.confirmerPret(
        pretId: pretSolde.pretId, codeSaisi: '5678', confirmedByPhone: '+2250000002');
    await db.enregistrerRemboursement(
      pretId: pretSolde.pretId,
      montantFcfa: 5500,
      recordedByPhone: '+2250000099',
    );

    // Prêt jamais confirmé -> ne doit pas être signalé (hors calcul, skill member-consent-rules).
    await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membre3,
      principalFcfa: 3000,
      interestRatePercent: 10,
      initiatedByPhone: '+2250000099',
      confirmationCode: '9999',
    );

    final nonSoldes = await db.pretsNonSoldesDuCycle(cycleId);
    expect(nonSoldes, hasLength(1));
    expect(nonSoldes.single.pret.memberId, membre1);
    expect(nonSoldes.single.soldeRestantFcfa, 6000); // 10000 + 1000 intérêt - 5000
  });
}

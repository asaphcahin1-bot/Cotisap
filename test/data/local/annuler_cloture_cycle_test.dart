import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('annule la clôture et rouvre l\'ancien cycle si le nouveau est vide', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycle1Id = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);
    final cycle2Id = await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle1Id,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 10,
    );

    await db.annulerClotureCycle(cycleClotureId: cycle1Id, cycleSuivantId: cycle2Id);

    final cycle1 = await (db.select(db.cycles)..where((c) => c.id.equals(cycle1Id))).getSingle();
    expect(cycle1.status, 'en_cours');
    expect(cycle1.endedAt, isNull);

    final cycle2Existe =
        await (db.select(db.cycles)..where((c) => c.id.equals(cycle2Id))).getSingleOrNull();
    expect(cycle2Existe, isNull);

    expect(await db.cycleEnCours(groupId), isNotNull);
    expect((await db.cycleEnCours(groupId))!.id, cycle1Id);
  });

  test('refuse l\'annulation dès qu\'une cotisation existe sur le nouveau cycle', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycle1Id = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);
    final cycle2Id = await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle1Id,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 10,
    );
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycle2Id,
      memberId: membreId,
      partsCount: 1,
      recordedByPhone: '+2250000099',
    );

    expect(await db.cycleEstVide(cycle2Id), isFalse);
    expect(
      () => db.annulerClotureCycle(cycleClotureId: cycle1Id, cycleSuivantId: cycle2Id),
      throwsStateError,
    );

    // Rien n'a changé.
    final cycle1 = await (db.select(db.cycles)..where((c) => c.id.equals(cycle1Id))).getSingle();
    expect(cycle1.status, 'cloture');
  });

  test('refuse l\'annulation dès qu\'une amende existe sur le nouveau cycle', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycle1Id = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);
    final cycle2Id = await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle1Id,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 10,
    );
    await db.enregistrerAmende(
      groupId: groupId,
      cycleId: cycle2Id,
      memberId: membreId,
      montantFcfa: 200,
      motif: 'test',
      recordedByPhone: '+2250000099',
    );

    expect(
      () => db.annulerClotureCycle(cycleClotureId: cycle1Id, cycleSuivantId: cycle2Id),
      throwsStateError,
    );
  });

  test('refuse si les deux cycles ne se suivent pas directement', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycle1Id = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);
    final cycle2Id = await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle1Id,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 10,
    );
    final cycle3Id = await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycle2Id,
      nouveauPartValueFcfa: 1500,
      nouveauInterestRatePercent: 12,
    );

    // cycle1 est clos mais n'est pas immédiatement suivi de cycle3.
    expect(
      () => db.annulerClotureCycle(cycleClotureId: cycle1Id, cycleSuivantId: cycle3Id),
      throwsStateError,
    );
  });
}

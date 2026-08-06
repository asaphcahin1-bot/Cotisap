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

  test('definirCarnetsEngages crée une ligne non verrouillée', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);

    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 3);

    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(carnets, isNotNull);
    expect(carnets!.partsCount, 3);
    expect(carnets.lockedAt, isNull);
  });

  test('rejette un nombre de carnets hors 1-5', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);

    expect(
      () => db.definirCarnetsEngages(
          groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 6),
      throwsArgumentError,
    );
    expect(
      () => db.definirCarnetsEngages(
          groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 0),
      throwsArgumentError,
    );
  });

  test('modifiable tant qu\'aucun paiement n\'a été enregistré', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);

    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 2);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 4);

    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(carnets!.partsCount, 4);
  });

  test('le premier paiement direct verrouille automatiquement les carnets', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 2);

    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsCount: 2,
      recordedByPhone: '+2250000099',
    );

    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(carnets!.lockedAt, isNotNull);

    expect(
      () => db.definirCarnetsEngages(
          groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 3),
      throwsStateError,
    );
  });

  test('un import historique ne verrouille pas les carnets', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 2);

    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsCount: 2,
      recordedByPhone: '+2250000099',
      provenance: 'importe',
    );

    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(carnets!.lockedAt, isNull);
  });
}

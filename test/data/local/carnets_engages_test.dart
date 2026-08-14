import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Un membre a droit à un seul carnet, toujours — voir DECISIONS.md,
/// "Un membre = un seul carnet" (annule et remplace l'ancienne règle
/// "1 ou 2 carnets").
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('definirCarnetsEngages crée une ligne non verrouillée, un seul carnet', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);

    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId);

    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(carnets, isNotNull);
    expect(carnets!.nombreCarnets, 1);
    expect(carnets.lockedAt, isNull);
  });

  test('rejette tout nombre de carnets différent de 1', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);

    expect(
      () => db.definirCarnetsEngages(
          groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 2),
      throwsArgumentError,
    );
    expect(
      () => db.definirCarnetsEngages(
          groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 0),
      throwsArgumentError,
    );
  });

  test('idempotent : rappeler definirCarnetsEngages ne change rien', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);

    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId);

    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(carnets!.nombreCarnets, 1);
  });

  test('le premier paiement direct verrouille automatiquement le carnet', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId);

    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      carnetNumero: 1,
      partsCount: 2,
      recordedByPhone: '+2250000099',
    );

    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(carnets!.lockedAt, isNotNull);

    // Une fois verrouillé, un second appel est idempotent (ne relève
    // plus d'erreur puisqu'il n'y a plus rien à changer).
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId);
  });

  test('un import historique ne verrouille pas le carnet', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId);

    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      carnetNumero: 1,
      partsCount: 2,
      recordedByPhone: '+2250000099',
      provenance: 'importe',
    );

    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(carnets!.lockedAt, isNull);
  });
}

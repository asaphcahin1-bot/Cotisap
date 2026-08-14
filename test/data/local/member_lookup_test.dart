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

  test('membresParTelephone retrouve un membre par son numéro, tous groupes confondus', () async {
    final groupe1 = await db.creerGroupe(
      name: 'Kondoukro', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final groupe2 = await db.creerGroupe(
      name: 'Yopougon', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');

    await db.ajouterMembre(groupId: groupe1, fullName: 'Aya Kone', phoneNumber: '+2250700000001');
    await db.ajouterMembre(groupId: groupe2, fullName: 'Aya Kone', phoneNumber: '+2250700000001');
    await db.ajouterMembre(groupId: groupe1, fullName: 'Fatou Traore', phoneNumber: '+2250700000002');

    final resultats = await db.membresParTelephone('+2250700000001');
    expect(resultats, hasLength(2));
    expect(resultats.map((m) => m.groupId).toSet(), {groupe1, groupe2});
  });

  test('membresParTelephone ne renvoie rien pour un numéro inconnu', () async {
    await db.creerGroupe(name: 'Kondoukro', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final resultats = await db.membresParTelephone('+2250700000099');
    expect(resultats, isEmpty);
  });

  test('cotisationsDuMembre et pretsDuMembre ne renvoient que les données du membre demandé',
      () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycleId = await db.ouvrirCycle(
      groupId: groupId, cycleNumber: 1, partValueFcfa: 1000, interestRatePercent: 10);
    final ayaId = await db.ajouterMembre(groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+225001');
    final fatouId = await db.ajouterMembre(groupId: groupId, fullName: 'Fatou Traore', phoneNumber: '+225002');

    await db.enregistrerCotisationCash(
      groupId: groupId, cycleId: cycleId, memberId: ayaId, partsCount: 3, recordedByPhone: '+225099');
    await db.enregistrerCotisationCash(
      groupId: groupId, cycleId: cycleId, memberId: fatouId, partsCount: 5, recordedByPhone: '+225099');
    await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: fatouId,
      principalFcfa: 20000,
      interestRatePercent: 10,
      initiatedByPhone: '+225099',
      confirmationCode: '123456',
      provenance: 'importe',
    );

    final cotisationsAya = await db.cotisationsDuMembre(ayaId, cycleId);
    expect(cotisationsAya, hasLength(1));
    expect(cotisationsAya.single.partsCount, 3);

    final pretsAya = await db.pretsDuMembre(ayaId, cycleId);
    expect(pretsAya, isEmpty);

    final pretsFatou = await db.pretsDuMembre(fatouId, cycleId);
    expect(pretsFatou, hasLength(1));
  });

  test('affecterRole via creerGroupe : le créateur devient agent du groupe', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    await db.affecterRole(groupId: groupId, phoneNumber: '+225000000', role: 'agent');

    final affectations = await (db.select(db.agentAssignments)
          ..where((a) => a.groupId.equals(groupId)))
        .get();
    expect(affectations, hasLength(1));
    expect(affectations.single.role, 'agent');
    expect(affectations.single.phoneNumber, '+225000000');
  });
}

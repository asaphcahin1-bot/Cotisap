import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

void main() {
  late AppDatabase db;
  final debutCycle = DateTime(2024, 1, 5);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    AppClock.definir(null);
    await db.close();
  });

  // Fenêtre de crédit + caisse disponible (voir DECISIONS.md) : ces
  // tests portent sur la confirmation d'un prêt, pas sur ces deux
  // règles — les satisfait explicitement plutôt que de les contourner.
  Future<void> ouvrirFenetreEtCaisse(
    String groupId,
    String cycleId,
    String membreId,
  ) async {
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsCount: 20, // 10 000 F, au-dessus des prêts testés ici
      recordedByPhone: '+2250700000099',
    );
    AppClock.definir(DateTime(2024, 2, 5)); // 2e réunion -> fenêtre ouverte
  }

  test('ajouterMembre accepte un membre sans numéro de téléphone', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final membreId =
        await db.ajouterMembre(groupId: groupId, fullName: 'Sans Téléphone');

    final membres = await db.membresDuGroupe(groupId);
    expect(membres, hasLength(1));
    expect(membres.single.id, membreId);
    expect(membres.single.phoneNumber, isNull);
  });

  test('un membre sans téléphone n\'apparaît jamais dans membresParTelephone', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    await db.ajouterMembre(groupId: groupId, fullName: 'Sans Téléphone');
    await db.ajouterMembre(
        groupId: groupId, fullName: 'Avec Téléphone', phoneNumber: '+2250700000001');

    expect(await db.membresParTelephone('+2250700000001'), hasLength(1));
    expect(await db.membresParTelephone(''), isEmpty);
  });

  test('confirmerPretParSignature confirme le prêt d\'un membre sans téléphone', () async {
    final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
        paymentDayOfMonth1: 5);
    final membreId =
        await db.ajouterMembre(groupId: groupId, fullName: 'Sans Téléphone');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 10,
        startedAt: debutCycle);
    await ouvrirFenetreEtCaisse(groupId, cycleId, membreId);

    final resultat = await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      principalFcfa: 5000,
      interestRatePercent: 10,
      initiatedByPhone: '+2250700000099',
    );
    expect(resultat.confirmationCode, isNull);
    expect(await db.pretEstConfirme(resultat.pretId), isFalse);

    await db.confirmerPretParSignature(
      pretId: resultat.pretId,
      signatureData: '10.0,20.0;15.0,25.0',
      witnessPhone: '+2250700000099',
    );

    expect(await db.pretEstConfirme(resultat.pretId), isTrue);
  });

  test('confirmerPretParSignature refuse un membre qui a un téléphone', () async {
    final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
        paymentDayOfMonth1: 5);
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Avec Téléphone', phoneNumber: '+2250700000001');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 10,
        startedAt: debutCycle);
    await ouvrirFenetreEtCaisse(groupId, cycleId, membreId);

    final resultat = await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      principalFcfa: 5000,
      interestRatePercent: 10,
      initiatedByPhone: '+2250700000099',
      confirmationCode: '1234',
    );

    expect(
      () => db.confirmerPretParSignature(
        pretId: resultat.pretId,
        signatureData: '10.0,20.0',
        witnessPhone: '+2250700000099',
      ),
      throwsStateError,
    );
    expect(await db.pretEstConfirme(resultat.pretId), isFalse);
  });

  test('confirmerPret (code) fonctionne toujours normalement pour un membre avec téléphone',
      () async {
    final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
        paymentDayOfMonth1: 5);
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Avec Téléphone', phoneNumber: '+2250700000001');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 10,
        startedAt: debutCycle);
    await ouvrirFenetreEtCaisse(groupId, cycleId, membreId);

    final resultat = await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      principalFcfa: 5000,
      interestRatePercent: 10,
      initiatedByPhone: '+2250700000099',
      confirmationCode: '1234',
    );

    final ok = await db.confirmerPret(
      pretId: resultat.pretId,
      codeSaisi: '1234',
      confirmedByPhone: '+2250700000001',
    );

    expect(ok, isTrue);
    expect(await db.pretEstConfirme(resultat.pretId), isTrue);
  });
}

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

  test('un membre ayant cotisé pendant la période en cours n\'est pas en retard', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'hebdomadaire');
    final memberId =
        await db.ajouterMembre(groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+225001');
    // Cycle commencé il y a 10 jours -> période hebdomadaire en cours
    // commencée il y a 3 jours (10 // 7 = 1 période écoulée, 1*7=7j après le début).
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 1000,
      interestRatePercent: 10,
    );
    // ouvrirCycle utilise DateTime.now() comme startedAt par défaut ; on
    // ne peut pas le décaler directement via l'API publique, donc ce test
    // couvre plutôt le cas "cotisation aujourd'hui, cycle qui vient de
    // commencer" — période en cours = date de début du cycle (aujourd'hui).
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: memberId,
      partsCount: 1,
      recordedByPhone: '+225099',
    );

    final enRetard = await db.membresEnRetard(groupId, cycleId);
    expect(enRetard, isEmpty);
  });

  test('un membre sans aucune cotisation est en retard', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'hebdomadaire');
    await db.ajouterMembre(groupId: groupId, fullName: 'Fatou Traore', phoneNumber: '+225002');
    final cycleId = await db.ouvrirCycle(
      groupId: groupId, cycleNumber: 1, partValueFcfa: 1000, interestRatePercent: 10, lateFeeFcfa: 500);

    final enRetard = await db.membresEnRetard(groupId, cycleId);
    expect(enRetard, hasLength(1));
    expect(enRetard.single.membre.fullName, 'Fatou Traore');
  });

  test('un membre déjà mis à l\'amende cette période n\'est plus signalé', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'hebdomadaire');
    final memberId =
        await db.ajouterMembre(groupId: groupId, fullName: 'Awa Diallo', phoneNumber: '+225003');
    final cycleId = await db.ouvrirCycle(
      groupId: groupId, cycleNumber: 1, partValueFcfa: 1000, interestRatePercent: 10, lateFeeFcfa: 500);

    var enRetard = await db.membresEnRetard(groupId, cycleId);
    expect(enRetard, hasLength(1));

    await db.enregistrerAmende(
      groupId: groupId,
      cycleId: cycleId,
      memberId: memberId,
      montantFcfa: 500,
      motif: 'Retard de cotisation',
      recordedByPhone: '+225099',
    );

    enRetard = await db.membresEnRetard(groupId, cycleId);
    expect(enRetard, isEmpty);
  });

  test('un cycle clos ne signale jamais de membre en retard', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'hebdomadaire');
    await db.ajouterMembre(groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+225001');
    final cycleId = await db.creerCycleHistorique(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 1000,
      interestRatePercent: 10,
      lateFeeFcfa: 500,
      debut: DateTime.now().subtract(const Duration(days: 200)),
      fin: DateTime.now().subtract(const Duration(days: 1)),
    );

    final enRetard = await db.membresEnRetard(groupId, cycleId);
    expect(enRetard, isEmpty);
  });

  test('la valeur par défaut de l\'amende de retard est 0 (pas d\'amende automatique)', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycleId = await db.ouvrirCycle(
      groupId: groupId, cycleNumber: 1, partValueFcfa: 1000, interestRatePercent: 10);

    final cycle = await (db.select(db.cycles)..where((c) => c.id.equals(cycleId))).getSingle();
    expect(cycle.lateFeeFcfa, 0);
  });
}

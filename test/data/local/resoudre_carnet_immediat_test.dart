import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

/// `resoudreCarnetImmediat` — voir RETOURS_TERRAIN.md : remplace le
/// bouton Présent/Absent. L'agent clique "Ajouter amende" pendant la
/// réunion et choisit directement le carnet + le motif (Absence / Part
/// impayée / Payé par un tiers) — résolu tout de suite, jamais différé
/// à la clôture.
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
  Future<({String groupId, String cycleId, String membreId})> preparer() async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 200,
      montantAmendePayeParTiersFcfa: 100,
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Membre test',
      phoneNumber: '+2250000001',
      joinedAt: debutCycle,
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

  test('crée l\'amende et l\'échéance non_paye tout de suite', () async {
    final ctx = await preparer();

    final amendeId = await db.resoudreCarnetImmediat(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      carnetNumero: 1,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );

    expect(amendeId, isNotNull);
    final amendes = await db.amendesAutoDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(amendes, hasLength(1));
    expect(amendes.single.montantFcfa, 200);
    expect(amendes.single.reviewedAt, isNotNull,
        reason: 'choisi interactivement, jamais en attente de revue');

    final echeances = await db.echeancesResoluesPourDate(
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(echeances, hasLength(1));
    expect(echeances.single.statut, 'non_paye');
    expect(echeances.single.amendeId, amendeId);
  });

  test('le carnet résolu n\'apparaît plus dans carnetsATraiterPourDate', () async {
    final ctx = await preparer();
    await db.resoudreCarnetImmediat(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      carnetNumero: 1,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );

    final aTraiter = await db.carnetsATraiterPourDate(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(aTraiter, isEmpty);
  });

  test('refuse un carnet déjà résolu (déjà payé)', () async {
    final ctx = await preparer();
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 1},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    expect(
      () => db.resoudreCarnetImmediat(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        carnetNumero: 1,
        date: debutCycle,
        codeSysteme: AppDatabase.codeSystemeAbsence,
        agentPhone: '+2250000099',
      ),
      throwsStateError,
    );
  });

  test('les amendes sont cumulatives : une amende libre reste possible en plus',
      () async {
    final ctx = await preparer();
    await db.resoudreCarnetImmediat(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      carnetNumero: 1,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );
    // Une amende libre (disciplinaire, hors carnet) reste toujours possible
    // en plus — jamais bloquée par la résolution du carnet.
    await db.enregistrerAmende(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      montantFcfa: 300,
      motif: 'Bavardage pendant la réunion',
      recordedByPhone: '+2250000099',
    );

    final toutesLesAmendes = await db.amendesDuMembre(
      ctx.membreId,
      ctx.cycleId,
    );
    expect(toutesLesAmendes, hasLength(2));
    expect(
      toutesLesAmendes.fold<int>(0, (s, a) => s + a.montantFcfa),
      500,
    );
  });

  test(
      'cloturerJourneeCotisation n\'a plus rien à demander pour un membre déjà résolu',
      () async {
    final ctx = await preparer();
    await db.resoudreCarnetImmediat(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      carnetNumero: 1,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );

    // La clôture ne crée pas de deuxième amende pour ce carnet déjà résolu.
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );

    final amendes = await db.amendesAutoDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(amendes, hasLength(1));
  });
}

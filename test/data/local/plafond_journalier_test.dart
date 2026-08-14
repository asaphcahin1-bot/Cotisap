import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Plafond de 5 parts par carnet et par jour — cumulatif sur la
/// journée, pas seulement par transaction (voir DECISIONS.md,
/// "Plafond de 5 parts par carnet et par jour"). Reprend aussi
/// [AppDatabase.membresAbsentsPourDate] et [AppDatabase.statutsAmendes],
/// ajoutés dans la même série.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  final debutCycle = DateTime(2024, 1, 4); // jeudi

  Future<({String groupId, String cycleId, String membreId})> preparerGroupe({
    int montantAmendeAbsenceFcfa = 0,
  }) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: montantAmendeAbsenceFcfa,
    );
    final membreId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Membre test',
        phoneNumber: '+2250000001',
        joinedAt: debutCycle);
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 1);
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  test('le plafond de 5 parts est cumulé sur la journée, pas juste par transaction', () async {
    final ctx = await preparerGroupe();

    // 3 parts d'abord.
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 3},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    // 2 de plus le même jour : autorisé (total = 5).
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 2},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    // 1 de plus le même jour : refusé (dépasserait 5).
    expect(
      () => db.enregistrerEncaissementMembre(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        partsParCarnet: {1: 1},
        recordedByPhone: '+2250000099',
        date: debutCycle,
      ),
      throwsArgumentError,
    );
  });

  test('le plafond redevient disponible le lendemain', () async {
    final ctx = await preparerGroupe();
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 5},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    // Le lendemain (nouvelle échéance non applicable ici, mais le
    // plafond journalier ne doit plus bloquer une nouvelle transaction).
    final dejaAjoutees = await db.partsDejaAjouteesAujourdhui(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
      carnetNumero: 1,
      jour: debutCycle.add(const Duration(days: 1)),
    );
    expect(dejaAjoutees, 0);
  });

  test('membresAbsentsPourDate liste un membre sans paiement, vide une fois payé', () async {
    final ctx = await preparerGroupe();

    var absents = await db.membresAbsentsPourDate(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(absents, hasLength(1));
    expect(absents.single.id, ctx.membreId);

    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 1},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    absents = await db.membresAbsentsPourDate(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(absents, isEmpty);
  });

  test('statutsAmendes distingue en_attente, reglee et annulee', () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa: 200);
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );
    final amendes = await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    final amendeId = amendes.single.id;

    var statuts = await db.statutsAmendes(ctx.cycleId);
    expect(statuts[amendeId], 'en_attente');

    await db.confirmerAmende(amendeId);
    statuts = await db.statutsAmendes(ctx.cycleId);
    expect(statuts[amendeId], 'reglee');
  });

  test('statutsAmendes marque annulee après corrigerAmendeErreur', () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa: 200);
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );
    final amendes = await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    final amendeId = amendes.single.id;

    await db.corrigerAmendeErreur(
      amendeId: amendeId,
      raison: 'Avait payé',
      annuleParPhone: '+2250000099',
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      carnetNumero: 1,
      partsCount: 1,
      dateReelle: debutCycle,
    );

    final statuts = await db.statutsAmendes(ctx.cycleId);
    expect(statuts[amendeId], 'annulee');
  });
}

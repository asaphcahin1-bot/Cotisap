import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Présence anticipée par carnet, saisie depuis l'écran "Séance du
/// jour" pendant la journée — voir RETOURS_TERRAIN.md, point 6, et la
/// doc de [PresenceAnticipee]/[AppDatabase.marquerPresenceAnticipee].
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // 4 janvier 2024 est un jeudi.
  final debutCycle = DateTime(2024, 1, 4);

  // Un membre = un seul carnet, toujours (voir DECISIONS.md, "Un membre
  // = un seul carnet").
  Future<({String groupId, String cycleId, String membreId})> preparerGroupe() async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 200,
      montantAmendePartImpayeeFcfa: 150,
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

  test('marquerPresenceAnticipee crée une ligne, relisible via presenceAnticipeeDuJour',
      () async {
    final ctx = await preparerGroupe();
    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );

    final anticipees = await db.presenceAnticipeeDuJour(
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(anticipees, hasLength(1));
    expect(
      anticipees[AppDatabase.clefResolutionCarnet(ctx.membreId, 1)],
      AppDatabase.codeSystemeAbsence,
    );
  });

  test('marquerPresenceAnticipee ignore un carnet déjà payé', () async {
    final ctx = await preparerGroupe();
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 1},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );

    final anticipees = await db.presenceAnticipeeDuJour(
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(anticipees, isEmpty); // carnet déjà payé, exclu
  });

  test('marquer un second motif remplace le premier (jamais de doublon)', () async {
    final ctx = await preparerGroupe();
    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );
    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemePayeParTiers,
      agentPhone: '+2250000099',
    );

    final anticipees = await db.presenceAnticipeeDuJour(
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(anticipees, hasLength(1));
    expect(
      anticipees[AppDatabase.clefResolutionCarnet(ctx.membreId, 1)],
      AppDatabase.codeSystemePayeParTiers,
    );
  });

  test('effacerPresenceAnticipee efface tout pour ce membre/date', () async {
    final ctx = await preparerGroupe();
    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );
    await db.effacerPresenceAnticipee(
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
    );

    final anticipees = await db.presenceAnticipeeDuJour(
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(anticipees, isEmpty);
  });

  test(
      'cloturerJourneeCotisation applique le motif anticipé quand resolutions ne le précise pas '
      '(pré-remplissage côté écran, voir record_cotisation_screen.dart)', () async {
    final ctx = await preparerGroupe();
    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemePartImpayee,
      agentPhone: '+2250000099',
    );

    // Simule ce que fait l'écran : relit la présence anticipée et
    // l'utilise comme valeur de `resolutions`.
    final anticipees = await db.presenceAnticipeeDuJour(
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
      resolutions: anticipees,
    );

    final amendes = await db.amendesAutoDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(amendes.single.motifCodeSysteme, AppDatabase.codeSystemePartImpayee);
  });

  test('cloturerJourneeCotisation nettoie la présence anticipée de cette date', () async {
    final ctx = await preparerGroupe();
    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
      resolutions: {
        AppDatabase.clefResolutionCarnet(ctx.membreId, 1):
            AppDatabase.codeSystemeAbsence,
      },
    );

    final anticipees = await db.presenceAnticipeeDuJour(
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(anticipees, isEmpty);
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

/// Bug de terrain (voir RETOURS_TERRAIN.md, point 24) : le fondateur a
/// signalé que "Clôturer cette journée" échoue souvent après avoir
/// saisi une amende, et que la journée reste bloquée même quand la
/// date simulée est avancée ou que le filet de sécurité 23h se
/// déclenche.
///
/// `motifsSystemeApplicables` ne reconnaissait un carnet comme déjà
/// résolu que dans deux cas : une cotisation payée, ou une amende au
/// motif système précis "Payé par un tiers" — jamais pour "Absence" ou
/// "Part impayée", les deux motifs les plus fréquents. Résultat :
/// rien n'empêchait de résoudre deux fois le même carnet via
/// "Ajouter amende", ce qui écrivait une deuxième ligne
/// `Echeances` pour le même (membre, carnet, date) — et cassait toute
/// requête `getSingleOrNull` qui repose sur l'unicité de ce triplet
/// (`cloturerJourneeCotisation`, `carnetsATraiterPourDate`, et le
/// filet de sécurité 23h qui appelle `cloturerJourneeCotisation` en
/// interne).
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

  Future<({String groupId, String cycleId, String membreId})> preparer() async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 200,
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

  test(
      'motifsSystemeApplicables ne propose plus rien après une résolution '
      '"Absence" (pas seulement "Payé par un tiers")', () async {
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

    final motifsRestants = await db.motifsSystemeApplicables(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
      carnetNumero: 1,
      echeanceDate: debutCycle,
    );
    expect(motifsRestants, isEmpty,
        reason: 'le carnet est déjà résolu en "Absence", plus rien à proposer');
  });

  test(
      'résoudre deux fois le même carnet (Absence puis Part impayée) est '
      'refusé, jamais une deuxième ligne Echeances', () async {
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

    expect(
      () => db.resoudreCarnetImmediat(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        carnetNumero: 1,
        date: debutCycle,
        codeSysteme: AppDatabase.codeSystemePartImpayee,
        agentPhone: '+2250000099',
      ),
      throwsStateError,
    );

    final lignes = await db.echeancesDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(lignes, hasLength(1),
        reason: 'une seule ligne Echeances pour ce (membre, carnet, date)');
  });

  test(
      'cloturerJourneeCotisation réussit pour une journée où un carnet a '
      'déjà été résolu en "Absence" pendant la journée', () async {
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

    // Ne doit lever aucune exception — c'était exactement le scénario
    // qui cassait la clôture sur le terrain.
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );

    final lignes = await db.echeancesDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(lignes, hasLength(1));
  });

  test(
      'carnetsATraiterPourDate n\'inclut pas un carnet déjà résolu en '
      '"Part impayée"', () async {
    final ctx = await preparer();
    await db.resoudreCarnetImmediat(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      carnetNumero: 1,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemePartImpayee,
      agentPhone: '+2250000099',
    );

    final aTraiter = await db.carnetsATraiterPourDate(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(aTraiter, isEmpty);
  });

  test(
      'le filet de sécurité 23h clôture sans casser une journée avec un '
      'carnet déjà résolu en "Absence"', () async {
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

    // Après 23h le jour de la réunion : le filet de sécurité doit
    // clôturer automatiquement sans lever d'exception.
    AppClock.definir(DateTime(2024, 1, 4, 23, 30));
    final journeeApres = await db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      agentPhone: '+2250000099',
    );
    expect(journeeApres, isNull,
        reason: 'plus rien en attente : la seule journée a été clôturée');
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

/// Retour terrain du 2026-08-14 : la clôture restait bloquée sur un
/// APK déjà censé contenir le correctif du 2026-08-13 (voir
/// `resolution_carnet_deja_resolu_test.dart`). Ce correctif empêche
/// d'écrire une **nouvelle** ligne `Echeances` en double, mais ne
/// répare rien sur un appareil où une ligne en double avait déjà été
/// écrite **avant** le correctif — ce test la simule directement (en
/// contournant `resoudreCarnetImmediat`, qui refuse désormais un
/// deuxième appel, pour reproduire l'état d'une base de terrain non
/// corrigée) et vérifie que la lecture ne plante plus, quel que soit
/// le nombre de lignes déjà présentes pour un même triplet (membre,
/// carnet, date) — voir DECISIONS.md,
/// "Correction de motifsSystemeApplicables — carnet déjà résolu"
/// (révision du 2026-08-14, `_derniereEcheancePourCarnet`).
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

  Future<({String groupId, String cycleId, String membreId})> preparerAvecDoublon() async {
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

    // Écrit directement DEUX lignes Echeances pour le même triplet
    // (membre, carnet 1, date) — reproduit une base de terrain
    // corrompue avant le correctif du 2026-08-13, sans passer par les
    // garde-fous actuels (impossibles à contourner désormais depuis
    // l'écran ou `resoudreCarnetImmediat`).
    for (var i = 0; i < 2; i++) {
      await db.enregistrerEcheanceNonPayee(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membreId,
        carnetNumero: 1,
        echeanceDate: debutCycle,
        montantDuFcfa: 500,
        recordedByPhone: '+2250000099',
      );
    }

    final lignes = await db.echeancesDuMembre(memberId: membreId, cycleId: cycleId);
    expect(lignes, hasLength(2), reason: 'le doublon simulé doit bien être en place avant le test');

    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  test(
      'carnetsATraiterPourDate ne plante plus avec une ligne Echeances déjà '
      'en double pour ce triplet', () async {
    final ctx = await preparerAvecDoublon();

    final aTraiter = await db.carnetsATraiterPourDate(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(aTraiter, isEmpty,
        reason: 'déjà tracé (en double) — rien à redemander à l\'agent');
  });

  test(
      'membresAbsentsPourDate ne plante plus avec une ligne Echeances déjà '
      'en double pour ce triplet', () async {
    final ctx = await preparerAvecDoublon();

    final absents = await db.membresAbsentsPourDate(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
    );
    expect(absents, isEmpty, reason: 'déjà tracé — plus "absent" au sens de cet aperçu');
  });

  test(
      'cloturerJourneeCotisation réussit malgré une ligne Echeances déjà en '
      'double pour ce triplet — c\'était exactement le blocage remonté du '
      'terrain sur un APK déjà corrigé', () async {
    final ctx = await preparerAvecDoublon();

    // Ne doit lever aucune exception, contrairement à avant ce
    // correctif (`getSingleOrNull` sans `limit(1)` levait `StateError`
    // dès qu'un deuxième résultat existait).
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );

    // Le doublon préexistant n'est pas nettoyé (pas l'objet de ce
    // correctif — voir DECISIONS.md) et la clôture n'en ajoute pas un
    // troisième puisque le triplet est déjà considéré comme traité.
    final lignes = await db.echeancesDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(lignes, hasLength(2));
  });

  test(
      'le filet de sécurité 23h clôture sans planter malgré une ligne '
      'Echeances déjà en double pour ce triplet', () async {
    final ctx = await preparerAvecDoublon();

    AppClock.definir(DateTime(2024, 1, 4, 23, 30));
    final journeeApres = await db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      agentPhone: '+2250000099',
    );
    expect(journeeApres, isNull,
        reason: 'plus rien en attente : la seule journée a été clôturée sans exception');
  });
}

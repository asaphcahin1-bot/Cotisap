import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

/// Filet de sécurité "clôture automatique après 23h" — voir
/// RETOURS_TERRAIN.md : si l'agent n'a pas clôturé une journée avant
/// 23h de sa propre date, elle se clôture automatiquement à la
/// prochaine vérification, pour ne jamais rester bloqué.
void main() {
  late AppDatabase db;
  // 4 janvier 2024 est un jeudi.
  final debutCycle = DateTime(2024, 1, 4);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
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
      nombreCarnets: 1,
    );
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  test('avant 23h, la journée reste ouverte — pas de clôture automatique', () async {
    final ctx = await preparer();
    AppClock.definir(DateTime(2024, 1, 4, 20)); // 20h, même jour

    final date = await db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      agentPhone: '+2250000099',
    );

    expect(date, debutCycle);
    expect(await db.derniereSeanceCloturee(ctx.cycleId), isNull);
  });

  test('après 23h de la date de la journée, elle est clôturée automatiquement', () async {
    final ctx = await preparer();
    AppClock.definir(DateTime(2024, 1, 4, 23, 30)); // 23h30, même jour

    final date = await db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      agentPhone: '+2250000099',
    );

    final seance = await db.derniereSeanceCloturee(ctx.cycleId);
    expect(seance, isNotNull);
    expect(seance!.date, debutCycle);
    expect(seance.clotureeParPhone, '+2250000099');
    // La semaine 1 était en retard -> amende automatique posée (Absence).
    final amendes = await db.amendesAutoDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(amendes, hasLength(1));
    // Toujours le 4 janvier (23h30) : la semaine 2 (11 janvier) n'est
    // pas encore une échéance "passée" -> plus rien à traiter pour le
    // moment, jusqu'au jeudi suivant.
    expect(date, isNull);
  });

  test('rattrape plusieurs journées en retard d\'un coup si l\'app est restée fermée', () async {
    final ctx = await preparer();
    // 3 semaines plus tard, largement après 23h de chacune des 3
    // premières échéances.
    AppClock.definir(DateTime(2024, 1, 25, 10));

    final date = await db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      agentPhone: '+2250000099',
    );

    final amendes = await db.amendesAutoDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(amendes, hasLength(3), reason: 'les 3 semaines manquées sont rattrapées');
    // La 4e semaine (25 janvier) n'a pas encore dépassé 23h -> reste ouverte.
    expect(date, DateTime(2024, 1, 25));
  });

  test('réutilise la présence anticipée saisie depuis Séance du jour', () async {
    final ctx = await preparer();
    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemePayeParTiers,
      agentPhone: '+2250000099',
    );
    AppClock.definir(DateTime(2024, 1, 4, 23, 30));

    await db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      agentPhone: '+2250000099',
    );

    final amendes = await db.amendesAutoDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(amendes.single.motifCodeSysteme, AppDatabase.codeSystemePayeParTiers);
  });

  test('aucune journée ouverte -> ne fait rien, renvoie null', () async {
    final ctx = await preparer();
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );
    AppClock.definir(debutCycle); // encore dans la semaine 1, avant la semaine 2

    final date = await db.journeeCotisationEnAttenteEtAutoClotureSiDepassee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      agentPhone: '+2250000099',
    );

    expect(date, isNull);
  });
}

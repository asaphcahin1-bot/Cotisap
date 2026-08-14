import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Clôture explicite de la journée de cotisation par l'agent — voir
/// DECISIONS.md, "Clôture de la journée de cotisation". Décision prise
/// avec le fondateur : ce n'est plus l'horloge qui décide en silence
/// qu'une échéance est close, c'est un geste explicite de l'agent.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  final debutCycle = DateTime(2024, 1, 4); // jeudi

  test('journeeCotisationEnAttente signale la plus ancienne échéance non clôturée', () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );

    final enAttente = await db.journeeCotisationEnAttente(
      groupId: groupId,
      cycleId: cycleId,
      maintenant: DateTime(2024, 1, 18), // 3 échéances passées, aucune clôturée
    );
    expect(enAttente, DateTime(2024, 1, 4));
  });

  test('journeeCotisationEnAttente redevient null une fois la seule échéance clôturée', () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );

    expect(
      await db.journeeCotisationEnAttente(
          groupId: groupId, cycleId: cycleId, maintenant: debutCycle),
      debutCycle,
    );

    await db.cloturerJourneeCotisation(
      groupId: groupId,
      cycleId: cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );

    // Toujours le même jour (aucune nouvelle échéance n'est encore
    // arrivée) : plus rien n'est ouvert — la saisie doit rester bloquée
    // jusqu'à la prochaine date de paiement programmée (voir
    // DECISIONS.md).
    expect(
      await db.journeeCotisationEnAttente(
          groupId: groupId, cycleId: cycleId, maintenant: debutCycle),
      isNull,
    );
  });

  test('clôturer la première journée ferme les inscriptions du cycle', () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );

    var cycle = await (db.select(db.cycles)..where((c) => c.id.equals(cycleId))).getSingle();
    expect(cycle.inscriptionsFermeesAt, isNull);

    await db.cloturerJourneeCotisation(
      groupId: groupId,
      cycleId: cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );

    cycle = await (db.select(db.cycles)..where((c) => c.id.equals(cycleId))).getSingle();
    expect(cycle.inscriptionsFermeesAt, isNotNull);
  });

  test(
      'ajouterMembre refuse dans les 2 dernières réunions avant la fin prévue du cycle',
      () async {
    // Voir DECISIONS.md, "Inscription de nouveaux membres : sans
    // limite, sauf fin de cycle" (RETOURS_TERRAIN.md, point 16) —
    // remplace l'ancienne règle "fermé dès la 1re journée clôturée".
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 1,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle, // jeudi 4 janvier 2024
    );
    // Fin prévue du cycle : 4 février 2024 -> 5 réunions au total
    // (4, 11, 18, 25 janvier, 1er février). À la 3e réunion (18
    // janvier), il n'en reste que 2 -> fermé.
    expect(
      () => db.ajouterMembre(
        groupId: groupId,
        fullName: 'Trop tard',
        phoneNumber: '+2250000002',
        joinedAt: DateTime(2024, 1, 18),
      ),
      throwsStateError,
    );
  });

  test(
      'ajouterMembre reste possible même après une clôture de journée, tant qu\'on est loin de la fin du cycle',
      () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    // La 1re journée est clôturée — sous l'ancienne règle, ça aurait
    // fermé les inscriptions. Plus le cas depuis DECISIONS.md,
    // "Inscription de nouveaux membres : sans limite, sauf fin de
    // cycle" : seule la proximité de la fin du cycle compte désormais
    // (cycle de 9 mois, on est encore tout au début).
    await db.cloturerJourneeCotisation(
      groupId: groupId,
      cycleId: cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );

    final id = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'À temps',
        phoneNumber: '+2250000002',
        // Date explicite plutôt que l'horloge réelle : le calcul
        // "réunions restantes avant la fin du cycle" est maintenant
        // sensible au temps (voir DECISIONS.md, "Inscription de
        // nouveaux membres : sans limite, sauf fin de cycle").
        joinedAt: debutCycle);
    expect(id, isNotEmpty);
  });

  test('refuse de clôturer deux fois la même journée', () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    await db.cloturerJourneeCotisation(
      groupId: groupId,
      cycleId: cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );

    expect(
      () => db.cloturerJourneeCotisation(
        groupId: groupId,
        cycleId: cycleId,
        date: debutCycle,
        agentPhone: '+2250000099',
      ),
      throwsStateError,
    );
  });

  test('annulerClotureJournee rouvre la journée si rien ne s\'est passé depuis', () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 200,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    final membreId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
        joinedAt: debutCycle);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 1);

    await db.cloturerJourneeCotisation(
      groupId: groupId,
      cycleId: cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );
    final seance = await db.derniereSeanceCloturee(cycleId);
    expect(seance, isNotNull);
    final amendesAvant = await db.amendesAutoDuMembre(memberId: membreId, cycleId: cycleId);
    expect(amendesAvant, hasLength(1));

    await db.annulerClotureJournee(seanceId: seance!.id, annuleParPhone: '+2250000099');

    expect(await db.derniereSeanceCloturee(cycleId), isNull);
    expect(await db.echeancesDuMembre(memberId: membreId, cycleId: cycleId), isEmpty);
    final amendesApres = await db.amendesAutoDuMembre(memberId: membreId, cycleId: cycleId);
    expect(amendesApres, isEmpty);

    // Champ purement informatif désormais (voir DECISIONS.md,
    // "Inscription de nouveaux membres : sans limite, sauf fin de
    // cycle") — annuler la clôture ne l'efface pas, mais ça n'a plus
    // d'incidence sur la possibilité d'ajouter un membre.
    final cycle = await (db.select(db.cycles)..where((c) => c.id.equals(cycleId))).getSingle();
    expect(cycle.inscriptionsFermeesAt, isNotNull);
  });

  test('annulerClotureJournee refuse si une cotisation a déjà été enregistrée depuis', () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    final membreId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
        joinedAt: debutCycle);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 1);

    await db.cloturerJourneeCotisation(
      groupId: groupId,
      cycleId: cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );
    final seance = await db.derniereSeanceCloturee(cycleId);

    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      carnetNumero: 1,
      partsCount: 1,
      recordedByPhone: '+2250000099',
      recordedAt: DateTime(2024, 1, 11),
    );

    expect(
      () => db.annulerClotureJournee(seanceId: seance!.id, annuleParPhone: '+2250000099'),
      throwsStateError,
    );
  });
}

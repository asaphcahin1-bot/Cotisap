import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Reprend le scénario "Mr AB" décrit par le fondateur, mis à jour après
/// le retrait du rattrapage (2026-08-09, voir DECISIONS.md "Amende
/// seule, jamais de rattrapage") puis du règlement automatique des
/// amendes (voir "Une amende ne se règle plus jamais automatiquement") :
/// carnet à 500F, cotisation hebdomadaire le jeudi. Semaine 1 payée
/// normalement, semaine 2 manquée -> semaine 2 reste définitivement non
/// payée (seule l'amende s'applique), semaine 3 se paie normalement (1
/// part, jamais de rattrapage de la semaine 2, et l'amende de la
/// semaine 2 reste en attente tant que l'agent ne la confirme pas
/// explicitement).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('scénario Mr AB : une semaine manquée n\'est jamais rattrapée, seule l\'amende s\'applique',
      () async {
    // 4 janvier 2024 est un jeudi.
    final debutCycle = DateTime(2024, 1, 4);
    final semaine2 = DateTime(2024, 1, 11);
    final semaine3 = DateTime(2024, 1, 18);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 100,
    );
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Mr AB', phoneNumber: '+2250000001', joinedAt: debutCycle);
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 1);

    // Semaine 1 (jeudi 4 janvier) : paiement normal, 1 part.
    await db.enregistrerEncaissementMembre(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsParCarnet: {1: 1},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    // Semaine 2 (11 janvier) : absent, rien payé — clôturée telle quelle.
    await db.cloturerJourneeCotisation(
      groupId: groupId,
      cycleId: cycleId,
      date: semaine2,
      agentPhone: '+2250000099',
    );
    final amendeEnAttente =
        await db.montantAmendesNonSoldeesFcfa(memberId: membreId, cycleId: cycleId);
    expect(amendeEnAttente, 100);

    // Semaine 3 (18 janvier) : paiement normal, 1 SEULE part — jamais de
    // rattrapage de la semaine 2 manquée.
    final cotisationIds = await db.enregistrerEncaissementMembre(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsParCarnet: {1: 1},
      recordedByPhone: '+2250000099',
      date: semaine3,
    );
    final cotisation = await (db.select(db.cotisations)
          ..where((c) => c.id.equals(cotisationIds.single)))
        .getSingle();
    expect(cotisation.partsCount, 1);

    // Total cotisé sur le cycle : 2 parts (semaines 1 et 3), jamais 3 —
    // la semaine 2 manquée n'est jamais récupérée.
    final totalCotise =
        await db.totalCotiseParCarnetFcfa(memberId: membreId, cycleId: cycleId, carnetNumero: 1);
    expect(totalCotise, 1000); // 2 x 500F

    // L'amende de la semaine 2 reste en attente : l'encaissement de la
    // semaine 3 ne l'a pas réglée automatiquement.
    final amendeApresCotisation =
        await db.montantAmendesNonSoldeesFcfa(memberId: membreId, cycleId: cycleId);
    expect(amendeApresCotisation, 100);

    // Seul un geste explicite de l'agent la solde.
    final enAttente = await db.amendesNonSoldeesDuMembre(memberId: membreId, cycleId: cycleId);
    await db.confirmerAmende(enAttente.single.id);
    final amendeApresConfirmation =
        await db.montantAmendesNonSoldeesFcfa(memberId: membreId, cycleId: cycleId);
    expect(amendeApresConfirmation, 0);

    // La semaine 2 reste définitivement `non_paye` dans l'historique.
    final groupeSemaine2 = (await db.echeancesGroupeesParDate(cycleId))
        .firstWhere((g) => g.date == semaine2);
    expect(groupeSemaine2.lignes.single.statut, 'non_paye');
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Registre d'échéances (payé/non payé par membre, par carnet et par
/// date) — voir DECISIONS.md, "Historique des cotisations", "Amende
/// seule, jamais de rattrapage" et "Une amende ne se règle plus jamais
/// automatiquement". Reprend les scénarios AD/AB donnés par le
/// fondateur : une échéance manquée n'est plus jamais rattrapable,
/// seule l'amende prédéfinie s'applique — et cette amende ne se règle
/// que par un geste explicite, jamais en même temps qu'une cotisation.
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
  final semaine2 = DateTime(2024, 1, 11);

  // Un membre = un seul carnet, toujours (voir DECISIONS.md, "Un membre
  // = un seul carnet") — annule et remplace l'ancienne règle "1 ou 2
  // carnets".
  Future<({String groupId, String cycleId, String membreId})> preparerGroupe({
    int montantAmendeAbsenceFcfa = 200,
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
        groupId: groupId, cycleId: cycleId, memberId: membreId);
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  test('une échéance manquée est tracée `non_paye` même sans amende automatique (montantAmendeAbsenceFcfa=0)',
      () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa:0);
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle, // semaine 1 : personne n'a payé, on clôture ce jour-là
      agentPhone: '+2250000099',
    );
    final lignes = await db.echeancesDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(lignes, hasLength(1));
    expect(lignes.single.statut, 'non_paye');
    expect(lignes.single.carnetNumero, 1);
    expect(lignes.single.amendeId, isNull);
    expect(lignes.single.amendeFcfa, 0);
  });

  test('une échéance manquée avec amende automatique lie la ligne Echeances à l\'amende', () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa:200);
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );
    final lignes = await db.echeancesDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(lignes, hasLength(1));
    expect(lignes.single.amendeId, isNotNull);
    expect(lignes.single.amendeFcfa, 200);

    final amendes = await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendes.single.id, lignes.single.amendeId);
  });

  test(
      'AD (1 carnet) : une échéance manquée n\'est jamais rattrapée, et son amende ne se règle '
      'pas toute seule au paiement suivant', () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa:200);
    // Semaine 1 (4 janvier) manquée, clôturée ce jour-là.
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );

    final montantAmendes =
        await db.montantAmendesNonSoldeesFcfa(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(montantAmendes, 200);

    // Semaine 2 (11 janvier) : le membre paie normalement 1 part — il ne
    // rattrape jamais la semaine 1 manquée.
    final cotisationIds = await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 1},
      recordedByPhone: '+2250000099',
      date: semaine2,
    );
    expect(cotisationIds, hasLength(1));

    final cotisation = await (db.select(db.cotisations)
          ..where((c) => c.id.equals(cotisationIds.single)))
        .getSingle();
    expect(cotisation.partsCount, 1, reason: 'jamais de rattrapage, seulement la semaine en cours');
    expect(cotisation.carnetNumero, 1);

    final carnetsApres =
        await db.carnetsEngagesDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(carnetsApres!.nombreCarnets, 1, reason: 'le nombre de carnets ne doit jamais changer');

    // L'amende reste en attente : l'encaissement d'une cotisation ne la
    // règle plus automatiquement (voir DECISIONS.md, "Une amende ne se
    // règle plus jamais automatiquement").
    final amendesApresCotisation =
        await db.montantAmendesNonSoldeesFcfa(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesApresCotisation, 200,
        reason: 'une cotisation ne doit jamais régler une amende toute seule');

    // Seul un geste explicite (confirmerAmende) la solde.
    final enAttente = await db.amendesNonSoldeesDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    await db.confirmerAmende(enAttente.single.id);
    final amendesApresConfirmation =
        await db.montantAmendesNonSoldeesFcfa(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesApresConfirmation, 0);

    // La semaine 1 reste définitivement non_paye — jamais rattrapable.
    final semaine1 = (await db.echeancesGroupeesParDate(ctx.cycleId))
        .firstWhere((g) => g.date == debutCycle);
    expect(semaine1.lignes.single.statut, 'non_paye');
  });

  test('une transaction ne peut jamais dépasser 5 parts dans un carnet', () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa:0);
    expect(
      () => db.enregistrerEncaissementMembre(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        partsParCarnet: {1: 6},
        recordedByPhone: '+2250000099',
        date: debutCycle,
      ),
      throwsArgumentError,
    );
  });

  test(
      'echeancesGroupeesParDate distingue une échéance payée et une définitivement manquée',
      () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa:200);
    // Semaine 1 manquée, clôturée sans paiement.
    await db.cloturerJourneeCotisation(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      date: debutCycle,
      agentPhone: '+2250000099',
    );
    // Semaine 2 : payée normalement (2 parts, déposées volontairement).
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 2},
      recordedByPhone: '+2250000099',
      date: semaine2,
    );

    final groupes = await db.echeancesGroupeesParDate(ctx.cycleId);
    expect(groupes, hasLength(2));

    final groupeSemaine1 = groupes.firstWhere((g) => g.date == debutCycle);
    expect(groupeSemaine1.lignes.single.statut, 'non_paye');

    final groupeSemaine2 = groupes.firstWhere((g) => g.date == semaine2);
    expect(groupeSemaine2.lignes.single.statut, 'paye');
    expect(groupeSemaine2.lignes.single.partsPayees, 2);
    expect(groupeSemaine2.lignes.single.montantPayeFcfa, 1000);

    // La plus récente d'abord.
    expect(groupes.first.date.isAfter(groupes.last.date), isTrue);
  });

  test('plusieurs transactions le même jour pour le même carnet s\'additionnent', () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa:0);
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 2},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 2},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    final groupes = await db.echeancesGroupeesParDate(ctx.cycleId);
    expect(groupes.single.lignes.single.partsPayees, 4);
    expect(groupes.single.lignes.single.montantPayeFcfa, 2000);

    // L'argent des deux transactions reste compté (rien d'invisible).
    final total =
        await db.totalCotiseParCarnetFcfa(memberId: ctx.membreId, cycleId: ctx.cycleId, carnetNumero: 1);
    expect(total, 2000);
  });

  test('un membre qui ne dépose rien (0 part) ne crée aucune cotisation', () async {
    final ctx = await preparerGroupe(montantAmendeAbsenceFcfa:0);
    final cotisationIds = await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 0},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );
    expect(cotisationIds, isEmpty);
  });
}

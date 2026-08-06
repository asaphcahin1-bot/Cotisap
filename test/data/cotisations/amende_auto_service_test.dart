import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/cotisations/amende_auto_service.dart';
import 'package:cotisapp/data/local/database.dart';

void main() {
  late AppDatabase db;
  late AmendeAutoService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = AmendeAutoService(db);
  });

  tearDown(() async {
    await db.close();
  });

  // 4 janvier 2024 est un jeudi.
  final debutCycle = DateTime(2024, 1, 4);

  /// Groupe hebdomadaire (jeudi), amende 100F, 1 membre avec 1 carnet à
  /// 500F.
  Future<({String groupId, String cycleId, String membreId})> preparerGroupe({
    int lateFeeFcfa = 100,
  }) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Mr AB', phoneNumber: '+2250000001');
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      lateFeeFcfa: lateFeeFcfa,
      startedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 1);
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  test('aucune amende le jour même de la première échéance', () async {
    final ctx = await preparerGroupe();
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: debutCycle, // jour 1, personne n'a encore eu la chance de payer
    );
    final amendesAuto =
        await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesAuto, isEmpty);
  });

  test('une échéance manquée déclenche une amende à la séance suivante, pas avant', () async {
    final ctx = await preparerGroupe();
    // Semaine 1 (4 janvier) : rien payé. Semaine 2 (11 janvier) : on
    // détecte — la semaine 1 est maintenant close et non couverte.
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 11),
    );
    final amendesAuto =
        await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesAuto, hasLength(1));
    expect(amendesAuto.single.montantFcfa, 100);
    expect(amendesAuto.single.estAutoGeneree, isTrue);
  });

  test('un membre qui a payé la semaine 1 n\'est pas signalé en semaine 2', () async {
    final ctx = await preparerGroupe();
    await db.enregistrerCotisationCash(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsCount: 1,
      recordedByPhone: '+2250000099',
      recordedAt: DateTime(2024, 1, 4),
    );
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 11),
    );
    final amendesAuto =
        await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesAuto, isEmpty);
  });

  test('deux échéances manquées d\'affilée -> deux amendes', () async {
    final ctx = await preparerGroupe();
    // Semaine 1 et 2 manquées. Semaine 3 (18 janvier) : les deux sont closes.
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 18),
    );
    final amendesAuto =
        await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesAuto, hasLength(2));
  });

  test('idempotent : rejouer la détection au même moment n\'applique jamais deux fois', () async {
    final ctx = await preparerGroupe();
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 11),
    );
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 11),
    );
    final amendesAuto =
        await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesAuto, hasLength(1));
  });

  test('lateFeeFcfa = 0 : aucune amende automatique jamais appliquée', () async {
    final ctx = await preparerGroupe(lateFeeFcfa: 0);
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 18),
    );
    final amendesAuto =
        await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesAuto, isEmpty);
  });

  test('confirmerAmende retire l\'amende de la liste à revoir', () async {
    final ctx = await preparerGroupe();
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 11),
    );
    final avant = await db.amendesEnAttenteRevue(groupId: ctx.groupId, cycleId: ctx.cycleId);
    expect(avant, hasLength(1));

    await db.confirmerAmende(avant.first.amende.id);

    final apres = await db.amendesEnAttenteRevue(groupId: ctx.groupId, cycleId: ctx.cycleId);
    expect(apres, isEmpty);
  });

  test('corrigerAmendeErreur annule l\'amende et enregistre la cotisation à la vraie date', () async {
    final ctx = await preparerGroupe();
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 11),
    );
    final enAttente =
        await db.amendesEnAttenteRevue(groupId: ctx.groupId, cycleId: ctx.cycleId);
    expect(enAttente, hasLength(1));
    final amendeACorrigier = enAttente.single.amende;

    await db.corrigerAmendeErreur(
      amendeId: amendeACorrigier.id,
      raison: 'Le membre avait en fait payé',
      annuleParPhone: '+2250000099',
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsCount: 1,
      dateReelle: DateTime(2024, 1, 4),
    );

    final apresRevue =
        await db.amendesEnAttenteRevue(groupId: ctx.groupId, cycleId: ctx.cycleId);
    expect(apresRevue, isEmpty);

    final cotisations = await db.cotisationsDuMembre(ctx.membreId, ctx.cycleId);
    expect(cotisations.any((c) => c.recordedAt == DateTime(2024, 1, 4)), isTrue);

    // Rejouer la détection ne doit pas re-fineur cette échéance
    // désormais couverte par la cotisation rétroactive.
    await service.detecterEtAppliquer(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      recordedByPhone: '+2250000099',
      maintenant: DateTime(2024, 1, 11),
    );
    final amendesAuto =
        await db.amendesAutoDuMembre(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(amendesAuto, isEmpty);
  });
}

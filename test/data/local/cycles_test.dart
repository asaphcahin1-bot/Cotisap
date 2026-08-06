import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/import/historical_import_service.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/domain/import/historical_import_parser.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('prochainNumeroCycle vaut 1 pour un groupe sans cycle', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    expect(await db.prochainNumeroCycle(groupId), 1);
  });

  test('creerCycleHistorique crée un cycle clos avec des dates explicites', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    await db.creerCycleHistorique(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 8,
      debut: DateTime(2023, 1, 1),
      fin: DateTime(2023, 10, 1),
    );

    final cycles = await db.cyclesDuGroupe(groupId);
    expect(cycles, hasLength(1));
    expect(cycles.single.status, 'cloture');
    expect(cycles.single.startedAt, DateTime(2023, 1, 1));
    expect(cycles.single.endedAt, DateTime(2023, 10, 1));
    expect(await db.prochainNumeroCycle(groupId), 2);
  });

  test('cyclesDuGroupe liste le cycle en cours et les cycles historiques, triés du plus récent au plus ancien',
      () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    await db.creerCycleHistorique(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 8,
      debut: DateTime(2022, 1, 1),
      fin: DateTime(2022, 10, 1),
    );
    await db.ouvrirCycle(
      groupId: groupId, cycleNumber: 2, partValueFcfa: 1000, interestRatePercent: 10);

    final cycles = await db.cyclesDuGroupe(groupId);
    expect(cycles.map((c) => c.cycleNumber), [2, 1]);
    expect(cycles.first.status, 'en_cours');
    expect(cycles.last.status, 'cloture');
  });

  test(
      'un import vers un cycle historique clos n\'affecte pas le calcul du cycle en cours '
      '(les cycles restent isolés)', () async {
    final groupId = await db.creerGroupe(
      name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    await db.ajouterMembre(groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');

    final cycleHistoriqueId = await db.creerCycleHistorique(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 8,
      debut: DateTime(2022, 1, 1),
      fin: DateTime(2022, 10, 1),
    );
    final cycleEnCoursId = await db.ouvrirCycle(
      groupId: groupId, cycleNumber: 2, partValueFcfa: 1000, interestRatePercent: 10);

    const csv = 'Aya Kone,2022-05-01,5000,cotisation';
    final parsed = const HistoricalImportParser().analyser(csv);
    final service = HistoricalImportService(db);
    final membres = await db.membresDuGroupe(groupId);
    final resolus = service.resoudreMembres(parsed.nomsMembresDistincts, membres);
    await service.executer(
      groupId: groupId,
      cycleId: cycleHistoriqueId,
      lignes: parsed.lignesValides,
      membresResolus: resolus,
      partValueFcfa: 500,
      interestRatePercent: 8,
      confirmedByPhone: '+2250000099',
    );

    final cotisationsHistorique = await db.cotisationsDuCycle(cycleHistoriqueId);
    final cotisationsEnCours = await db.cotisationsDuCycle(cycleEnCoursId);
    expect(cotisationsHistorique, hasLength(1));
    expect(cotisationsEnCours, isEmpty);
  });
}

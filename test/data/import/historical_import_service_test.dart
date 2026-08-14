import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/import/historical_import_service.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/domain/calculators/end_of_cycle_calculator.dart';
import 'package:cotisapp/domain/import/historical_import_parser.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'un prêt importé compte comme confirmé sans ligne de confirmation SMS',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 10,
      );
      final memberId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000000',
      );

      final resultat = await db.enregistrerPret(
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        principalFcfa: 10000,
        interestRatePercent: 10,
        initiatedByPhone: '+2250000001',
        confirmationCode: 'importe',
        provenance: 'importe',
      );

      expect(await db.pretEstConfirme(resultat.pretId), isTrue);
    },
  );

  test(
    'import de bout en bout : cotisation convertie en parts, prêt + remboursement '
    'rattaché, montants comptés dans le calcul de fin de cycle',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Kondoukro',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 10,
      );
      final ayaId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000000',
      );
      await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Fatou Traore',
        phoneNumber: '+2250000002',
      );

      const csv = '''
Aya Kone,2024-01-10,5000,cotisation
Fatou Traore,2024-01-15,50000,pret
Fatou Traore,2024-02-20,55000,remboursement
''';
      final parsed = const HistoricalImportParser().analyser(csv);
      expect(parsed.erreurs, isEmpty);

      final service = HistoricalImportService(db);
      final membres = await db.membresDuGroupe(groupId);
      final resolus = service.resoudreMembres(
        parsed.nomsMembresDistincts,
        membres,
      );
      expect(
        service.nomsIntrouvables(parsed.nomsMembresDistincts, resolus),
        isEmpty,
      );

      final outcome = await service.executer(
        groupId: groupId,
        cycleId: cycleId,
        lignes: parsed.lignesValides,
        membresResolus: resolus,
        partValueFcfa: 1000,
        interestRatePercent: 10,
        confirmedByPhone: '+2250000099',
      );

      expect(outcome.nbEcritures, 3);
      expect(outcome.avertissements, isEmpty);

      // La cotisation de 5000 FCFA / 1000 FCFA par part = 5 parts pour Aya.
      final cotisations = await db.cotisationsDuCycle(cycleId);
      expect(cotisations.single.partsCount, 5);
      expect(cotisations.single.memberId, ayaId);
      expect(cotisations.single.provenance, 'importe');

      // Le prêt importé de Fatou (50000 FCFA, 10%) est intégralement
      // remboursé (55000 FCFA) -> ses intérêts doivent compter dans le calcul.
      final totalInterets = await db.totalInteretsPercusDuCycle(cycleId);
      expect(totalInterets, 5000); // 10% de 50000

      // Vérifie que le calculateur pur reçoit bien ces montants et calcule
      // une répartition cohérente (formule "caisse disponible", voir
      // DECISIONS.md "Nouvelle formule de partage").
      final resultatCalcul = const EndOfCycleCalculator().calculer(
        EndOfCycleInput(
          membres: [
            const MemberCycleInput(
              memberId: 'aya',
              totalParts: 5,
              cotisationTotaleFcfa: 5000,
              detteFcfa: 0,
            ),
          ],
          cotisationsTotalesGroupeFcfa: 5000,
          amendesRegleesFcfa: 0,
          interetsPercusFcfa: totalInterets,
          dettesEnCoursGroupeFcfa: 0,
        ),
      );
      expect(
        resultatCalcul.caisseDisponibleFcfa,
        10000,
      ); // 5000 cotisé + 5000 intérêt
    },
  );

  test(
    'un remboursement sans prêt importé correspondant est signalé, pas silencieusement perdu',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 10,
      );
      await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000000',
      );

      const csv = 'Aya Kone,2024-01-10,20000,remboursement';
      final parsed = const HistoricalImportParser().analyser(csv);
      final service = HistoricalImportService(db);
      final membres = await db.membresDuGroupe(groupId);
      final resolus = service.resoudreMembres(
        parsed.nomsMembresDistincts,
        membres,
      );

      final outcome = await service.executer(
        groupId: groupId,
        cycleId: cycleId,
        lignes: parsed.lignesValides,
        membresResolus: resolus,
        partValueFcfa: 1000,
        interestRatePercent: 10,
        confirmedByPhone: '+2250000099',
      );

      expect(outcome.nbEcritures, 0);
      expect(outcome.avertissements, hasLength(1));
    },
  );
}

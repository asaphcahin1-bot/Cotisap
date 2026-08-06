import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/domain/calculators/echeance_calculator.dart';

/// Reproduit le scénario "Mr AB" décrit par le fondateur : carnet à 500F,
/// cotisation hebdomadaire le jeudi. Semaine 1 payée normalement, semaine
/// 2 manquée -> à la semaine 3, le montant dû doit inclure le
/// rattrapage de la semaine manquée en plus du paiement normal.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('scénario Mr AB : une semaine manquée cumule sur la semaine suivante', () async {
    // 4 janvier 2024 est un jeudi.
    final debutCycle = DateTime(2024, 1, 4);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final membreId =
        await db.ajouterMembre(groupId: groupId, fullName: 'Mr AB', phoneNumber: '+2250000001');
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, partsCount: 1);

    // Semaine 1 (jeudi 4 janvier) : paiement normal.
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsCount: 1,
      recordedByPhone: '+2250000099',
      recordedAt: DateTime(2024, 1, 4),
    );

    // Semaine 2 (11 janvier) : absent, rien payé.

    // Semaine 3 (18 janvier) : on vérifie le montant dû avant paiement.
    final cycle = await (db.select(db.cycles)..where((c) => c.id.equals(cycleId))).getSingle();
    final groupe = await (db.select(db.groups)..where((g) => g.id.equals(groupId))).getSingle();
    final carnets = await db.carnetsEngagesDuMembre(memberId: membreId, cycleId: cycleId);
    final echeances = const EcheanceCalculator().echeancesPassees(
      debutCycle: cycle.startedAt,
      meetingFrequency: groupe.meetingFrequency,
      paymentDayOfWeek: groupe.paymentDayOfWeek,
      maintenant: DateTime(2024, 1, 18),
    );
    expect(echeances, hasLength(3)); // 4, 11, 18 janvier

    final dejaPaye = await db.totalCotiseFcfa(memberId: membreId, cycleId: cycleId);
    expect(dejaPaye, 500); // seule la semaine 1 a été payée

    final du = const EcheanceCalculator().soldeDuFcfa(
      echeancesPassees: echeances,
      carnetsEngages: carnets!.partsCount,
      valeurCarnetFcfa: cycle.partValueFcfa,
      montantDejaPayeFcfa: dejaPaye,
    );
    expect(du, 1000); // 500 (semaine 2 manquée) + 500 (semaine 3)

    // Le membre régularise en une fois.
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsCount: du ~/ cycle.partValueFcfa, // 2 carnets
      recordedByPhone: '+2250000099',
      recordedAt: DateTime(2024, 1, 18),
    );

    final apresRegularisation = await db.totalCotiseFcfa(memberId: membreId, cycleId: cycleId);
    expect(apresRegularisation, 1500); // 500 + 1000

    final duApres = const EcheanceCalculator().soldeDuFcfa(
      echeancesPassees: echeances,
      carnetsEngages: carnets.partsCount,
      valeurCarnetFcfa: cycle.partValueFcfa,
      montantDejaPayeFcfa: apresRegularisation,
    );
    expect(duApres, 0); // à jour
  });
}

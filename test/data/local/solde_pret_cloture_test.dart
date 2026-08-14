import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

/// Vérifie [AppDatabase.soldePret] — "dette perdue à la clôture si non
/// reconduite" (voir DECISIONS.md, "Dette de prêt au rouge") : un prêt
/// dont le cycle est clos, jamais reconduit, ne doit plus composer
/// au-delà de l'instant de la clôture, même si l'écran est rouvert bien
/// plus tard. `detteMembreFcfa` (qui délègue à `soldePret`) hérite du
/// même plafond.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    AppClock.definir(null);
  });

  Future<
      ({
        String groupId,
        String cycleId,
        String membreId,
        String pretId,
      })> preparerPretAuRougeDansUnCycleQuiVaFermer() async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 12,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 15,
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Membre test',
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      loanDurationDays: 30,
      startedAt: DateTime(2024, 1, 1),
    );
    final resultat = await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      principalFcfa: 10000,
      interestRatePercent: 10,
      initiatedByPhone: '+2250700000099',
      dureeJours: 30,
      provenance: 'importe',
      createdAt: DateTime(2024, 1, 1),
    );
    return (
      groupId: groupId,
      cycleId: cycleId,
      membreId: membreId,
      pretId: resultat.pretId,
    );
  }

  test(
      'la composition s\'arrête à la date de clôture pour un prêt jamais reconduit',
      () async {
    final ctx = await preparerPretAuRougeDansUnCycleQuiVaFermer();

    // Clôture le 1er février : le prêt est entré au rouge le 15
    // janvier (finPeriode) mais aucun mois calendaire plein ne s'est
    // encore écoulé (le prochain palier est le 15 février) -> solde
    // gelé à 11000 F (10000 + 10% initial, pas encore de recomposition
    // au rouge) au moment de la clôture.
    AppClock.definir(DateTime(2024, 2, 1));
    await db.cloturerCycleEtOuvrirSuivant(
      groupId: ctx.groupId,
      cycleIdACloturer: ctx.cycleId,
      nouveauPartValueFcfa: 500,
      nouveauInterestRatePercent: 10,
      recordedByPhone: '+2250700000099',
    );

    final pret = await (db.select(db.prets)
          ..where((p) => p.id.equals(ctx.pretId)))
        .getSingle();

    // Bien après la clôture -> aurait dû composer plusieurs fois
    // (mars, avril, mai) si rien ne plafonnait le calcul.
    final soldeLoin = await db.soldePret(
      pret,
      maintenant: DateTime(2024, 6, 1),
    );
    expect(soldeLoin.montantDuFcfa, 11000);

    // Interroger encore plus tard ne change rien non plus (gelé, pas
    // juste "en retard d'une mise à jour").
    final soldeEncorePlusLoin = await db.soldePret(
      pret,
      maintenant: DateTime(2026, 1, 1),
    );
    expect(soldeEncorePlusLoin.montantDuFcfa, 11000);
  });

  test(
      'detteMembreFcfa hérite du même plafond (délègue à soldePret)',
      () async {
    final ctx = await preparerPretAuRougeDansUnCycleQuiVaFermer();

    AppClock.definir(DateTime(2024, 2, 1));
    await db.cloturerCycleEtOuvrirSuivant(
      groupId: ctx.groupId,
      cycleIdACloturer: ctx.cycleId,
      nouveauPartValueFcfa: 500,
      nouveauInterestRatePercent: 10,
      recordedByPhone: '+2250700000099',
    );

    final dette = await db.detteMembreFcfa(
      groupId: ctx.groupId,
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
      maintenant: DateTime(2024, 6, 1),
    );
    expect(dette, 11000);
  });

  test(
      'une date demandée avant la clôture n\'est jamais repoussée en avant',
      () async {
    final ctx = await preparerPretAuRougeDansUnCycleQuiVaFermer();

    AppClock.definir(DateTime(2024, 2, 1));
    await db.cloturerCycleEtOuvrirSuivant(
      groupId: ctx.groupId,
      cycleIdACloturer: ctx.cycleId,
      nouveauPartValueFcfa: 500,
      nouveauInterestRatePercent: 10,
      recordedByPhone: '+2250700000099',
    );

    final pret = await (db.select(db.prets)
          ..where((p) => p.id.equals(ctx.pretId)))
        .getSingle();

    // Avant même la fin de la période normale (15 janvier) -> jamais
    // au rouge, peu importe la clôture bien plus tard.
    final solde = await db.soldePret(pret, maintenant: DateTime(2024, 1, 5));
    expect(solde.estAuRouge, isFalse);
  });

  test(
      'un prêt d\'un cycle toujours en cours continue de composer sans plafond',
      () async {
    final ctx = await preparerPretAuRougeDansUnCycleQuiVaFermer();
    final pret = await (db.select(db.prets)
          ..where((p) => p.id.equals(ctx.pretId)))
        .getSingle();

    // Cycle jamais clos -> plusieurs mois de composition attendus.
    final solde = await db.soldePret(pret, maintenant: DateTime(2024, 6, 1));
    expect(solde.montantDuFcfa, greaterThan(11000));
  });
}

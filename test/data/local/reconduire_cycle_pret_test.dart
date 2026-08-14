import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/domain/calculators/loan_rate_resolver.dart';

/// Vérifie [AppDatabase.reconduireCyclePret] — voir DECISIONS.md,
/// "Dette de prêt au rouge" et RETOURS_TERRAIN.md, point 19 :
/// reconduction d'un prêt non soldé dans le nouveau cycle qui vient
/// d'être ouvert — automatique dans son calcul (montant exact, sans
/// paiement partiel), au taux résolu comme un prêt neuf (jamais le
/// taux plat du cycle), jamais double compté avec l'ancien.
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
        String ancienCycleId,
        String membreId,
      })> preparerGroupeAvecPretNonSolde() async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 15,
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Membre test',
    );
    final ancienCycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      loanDurationDays: 30,
      startedAt: DateTime(2024, 1, 1),
    );
    await db.enregistrerPret(
      groupId: groupId,
      cycleId: ancienCycleId,
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
      ancienCycleId: ancienCycleId,
      membreId: membreId,
    );
  }

  test(
      'crée un prêt successeur, déjà au rouge, dans le nouveau cycle',
      () async {
    final ctx = await preparerGroupeAvecPretNonSolde();
    final maintenant = DateTime(2024, 3, 1);

    final pretAvant = (await db.pretsDuCycle(ctx.ancienCycleId)).single;
    final soldeAvant = await db.soldePret(pretAvant, maintenant: maintenant);

    final nouveauCycleId = await db.ouvrirCycle(
      groupId: ctx.groupId,
      cycleNumber: 2,
      partValueFcfa: 500,
      // Taux volontairement absurde (99 %) pour prouver que
      // reconduireCyclePret ne le lit jamais directement — voir
      // l'assertion sur interestRatePercent plus bas.
      interestRatePercent: 99,
      loanDurationDays: 60,
      startedAt: maintenant,
    );

    final resultat = await db.reconduireCyclePret(
      pretId: pretAvant.id,
      nouveauCycleId: nouveauCycleId,
      agentPhone: '+2250700000099',
      maintenant: maintenant,
    );

    final nouveauPret = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultat.pretId)))
        .getSingle();
    expect(nouveauPret.cycleId, nouveauCycleId);
    expect(nouveauPret.renouvelePretId, pretAvant.id);
    expect(nouveauPret.provenance, 'renouvellement');
    expect(nouveauPret.estAuRougeDesLeDepart, isTrue);
    // Taux résolu comme un prêt neuf (voir DECISIONS.md) — aucune
    // cotisation encore enregistrée dans le nouveau cycle -> plafond
    // 3x nul -> hors carnet, jamais le taux plat du cycle (99 %,
    // volontairement absurde ci-dessus).
    expect(nouveauPret.interestRatePercent, LoanRateResolver.tauxHorsCarnet);
    expect(nouveauPret.dureeJours, 60);
    // Principal = solde précis de l'ancien prêt au moment de la
    // reconduction (via soldePret, pas la version simplifiée).
    expect(nouveauPret.principalFcfa, soldeAvant.montantDuFcfa);
  });

  test(
      'le taux du prêt reconduit passe "dans le carnet" si le membre a déjà cotisé dans le nouveau cycle',
      () async {
    final ctx = await preparerGroupeAvecPretNonSolde();
    final maintenant = DateTime(2024, 3, 1);
    final pretAvant = (await db.pretsDuCycle(ctx.ancienCycleId)).single;
    final nouveauCycleId = await db.ouvrirCycle(
      groupId: ctx.groupId,
      cycleNumber: 2,
      partValueFcfa: 500,
      interestRatePercent: 15,
      startedAt: maintenant,
    );
    // Cotisation suffisante, déjà dans le nouveau cycle, pour couvrir
    // 3x le solde reconduit -> jamais "hors carnet" par le plafond.
    await db.enregistrerCotisationCash(
      groupId: ctx.groupId,
      cycleId: nouveauCycleId,
      memberId: ctx.membreId,
      partsCount: 30, // 15000 F à 500 F/part
      recordedByPhone: '+2250700000099',
    );

    final resultat = await db.reconduireCyclePret(
      pretId: pretAvant.id,
      nouveauCycleId: nouveauCycleId,
      agentPhone: '+2250700000099',
      maintenant: maintenant,
    );

    final nouveauPret = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultat.pretId)))
        .getSingle();
    expect(nouveauPret.interestRatePercent, LoanRateResolver.tauxDansLeCarnet);
  });

  test('refuse de reconduire un prêt déjà soldé', () async {
    final ctx = await preparerGroupeAvecPretNonSolde();
    final pret = (await db.pretsDuCycle(ctx.ancienCycleId)).single;
    // Solde intégralement remboursé (10000 + 10% = 11000) pendant la
    // période normale — date explicite, jamais l'horloge réelle
    // (sinon le remboursement tomberait après `maintenant` plus bas et
    // ne serait pas encore appliqué par le calculateur).
    await db.enregistrerRemboursement(
      pretId: pret.id,
      montantFcfa: 11000,
      recordedByPhone: '+2250700000099',
      recordedAt: DateTime(2024, 1, 10),
    );
    final nouveauCycleId = await db.ouvrirCycle(
      groupId: ctx.groupId,
      cycleNumber: 2,
      partValueFcfa: 500,
      interestRatePercent: 15,
    );

    expect(
      () => db.reconduireCyclePret(
        pretId: pret.id,
        nouveauCycleId: nouveauCycleId,
        agentPhone: '+2250700000099',
        maintenant: DateTime(2024, 3, 1),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
      'après reconduction, l\'ancien prêt disparaît de pretsNonSoldesDuCycle et detteMembreFcfa de son cycle',
      () async {
    final ctx = await preparerGroupeAvecPretNonSolde();
    final maintenant = DateTime(2024, 3, 1);
    final pretAvant = (await db.pretsDuCycle(ctx.ancienCycleId)).single;

    final nouveauCycleId = await db.ouvrirCycle(
      groupId: ctx.groupId,
      cycleNumber: 2,
      partValueFcfa: 500,
      interestRatePercent: 15,
      startedAt: maintenant,
    );

    await db.reconduireCyclePret(
      pretId: pretAvant.id,
      nouveauCycleId: nouveauCycleId,
      agentPhone: '+2250700000099',
      maintenant: maintenant,
    );

    final nonSoldesAncien = await db.pretsNonSoldesDuCycle(ctx.ancienCycleId);
    expect(nonSoldesAncien.map((p) => p.pret.id), isNot(contains(pretAvant.id)));

    final dette = await db.detteMembreFcfa(
      groupId: ctx.groupId,
      memberId: ctx.membreId,
      cycleId: ctx.ancienCycleId,
      maintenant: maintenant,
    );
    expect(dette, 0);
  });

  test(
      'le nouveau prêt successeur exige sa propre confirmation, comme tout prêt',
      () async {
    final ctx = await preparerGroupeAvecPretNonSolde();
    final maintenant = DateTime(2024, 3, 1);
    final pretAvant = (await db.pretsDuCycle(ctx.ancienCycleId)).single;
    final nouveauCycleId = await db.ouvrirCycle(
      groupId: ctx.groupId,
      cycleNumber: 2,
      partValueFcfa: 500,
      interestRatePercent: 15,
      startedAt: maintenant,
    );

    final resultat = await db.reconduireCyclePret(
      pretId: pretAvant.id,
      nouveauCycleId: nouveauCycleId,
      agentPhone: '+2250700000099',
      maintenant: maintenant,
    );

    expect(await db.pretEstConfirme(resultat.pretId), isFalse);
  });
}

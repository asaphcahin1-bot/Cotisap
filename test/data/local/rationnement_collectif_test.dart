import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/domain/calculators/loan_rate_resolver.dart';

/// Vérifie le rationnement collectif des crédits — voir DECISIONS.md
/// (RETOURS_TERRAIN.md, point 13) : plusieurs demandes en attente,
/// négociées avec redistribution immédiate à chaque décision.
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
      })> preparerGroupe() async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 4,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: DateTime(2023, 12, 4),
    );
    // 2e réunion (4 janvier) -> fenêtre de crédit ouverte.
    AppClock.definir(DateTime(2024, 1, 4));
    return (groupId: groupId, cycleId: cycleId);
  }

  test('demanderPret refuse hors fenêtre de crédit', () async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 4,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: DateTime(2024, 1, 4),
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      joinedAt: DateTime(2024, 1, 4),
    );
    // 1re réunion seulement -> fenêtre fermée.
    expect(
      () => db.demanderPret(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membreId,
        montantDemandeFcfa: 10000,
        recordedByPhone: '+2250700000099',
        createdAt: DateTime(2024, 1, 4),
      ),
      throwsStateError,
    );
  });

  test(
      'caisse suffisante pour toutes les demandes -> chacune peut être acceptée intégralement',
      () async {
    final ctx = await preparerGroupe();
    final ayaId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Aya Kone',
      joinedAt: DateTime(2023, 12, 4),
    );
    final modiboId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Modibo Sanogo',
      joinedAt: DateTime(2023, 12, 4),
    );
    // Caisse disponible = 100000 (cotisation d'un tiers, peu importe).
    final autreId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Autre',
      joinedAt: DateTime(2023, 12, 4),
    );
    await db.enregistrerCotisationCash(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: autreId,
      partsCount: 200, // 100000 F
      recordedByPhone: '+2250700000099',
    );

    final demandeAya = await db.demanderPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ayaId,
      montantDemandeFcfa: 20000,
      recordedByPhone: '+2250700000099',
    );
    final demandeModibo = await db.demanderPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: modiboId,
      montantDemandeFcfa: 30000,
      recordedByPhone: '+2250700000099',
    );

    final prochaine = await db.prochaineDemandeAvecAllocation(ctx.cycleId);
    expect(prochaine!.demande.id, demandeAya); // FIFO
    expect(prochaine.montantProposeFcfa, 20000); // intégral

    final resultat = await db.accepterDemandePret(
      demandeId: demandeAya,
      montantAccepteFcfa: prochaine.montantProposeFcfa,
      agentPhone: '+2250700000099',
    );
    final pret = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultat.pretId)))
        .getSingle();
    expect(pret.principalFcfa, 20000);
    expect(pret.demandeId, demandeAya);

    final suivante = await db.prochaineDemandeAvecAllocation(ctx.cycleId);
    expect(suivante!.demande.id, demandeModibo);
    expect(suivante.montantProposeFcfa, 30000); // toujours intégral
  });

  test(
      'redistribution immédiate : un désistement augmente l\'offre du suivant',
      () async {
    final ctx = await preparerGroupe();
    final ayaId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Aya Kone',
      joinedAt: DateTime(2023, 12, 4),
    );
    final modiboId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Modibo Sanogo',
      joinedAt: DateTime(2023, 12, 4),
    );
    final seydouId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Seydou Traore',
      joinedAt: DateTime(2023, 12, 4),
    );
    // Caisse disponible = 30000 F. 3 demandes de 30000 F chacune.
    await db.enregistrerCotisationCash(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: seydouId,
      partsCount: 60, // 30000 F
      recordedByPhone: '+2250700000099',
    );

    final demandeAya = await db.demanderPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ayaId,
      montantDemandeFcfa: 30000,
      recordedByPhone: '+2250700000099',
    );
    final demandeModibo = await db.demanderPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: modiboId,
      montantDemandeFcfa: 30000,
      recordedByPhone: '+2250700000099',
    );
    final demandeSeydou = await db.demanderPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: seydouId,
      montantDemandeFcfa: 30000,
      recordedByPhone: '+2250700000099',
    );

    // Premier tour : caisse 30000 / total 90000 -> 10000 chacun.
    var prochaine = await db.prochaineDemandeAvecAllocation(ctx.cycleId);
    expect(prochaine!.demande.id, demandeAya);
    expect(prochaine.montantProposeFcfa, 10000);

    // Aya se désiste -> la caisse reste à 30000, mais le total demandé
    // restant tombe à 60000 -> 15000 chacun pour les 2 suivants.
    await db.refuserDemandePret(
      demandeId: demandeAya,
      agentPhone: '+2250700000099',
    );
    prochaine = await db.prochaineDemandeAvecAllocation(ctx.cycleId);
    expect(prochaine!.demande.id, demandeModibo);
    expect(prochaine.montantProposeFcfa, 15000);

    // Modibo accepte son offre réduite (15000). Comme tout prêt, il ne
    // compte dans la caisse disponible qu'une fois confirmé (même
    // principe que "Nouveau prêt" — voir DECISIONS.md,
    // member-consent-rules) : dans le vrai flux, la confirmation
    // (code SMS/signature) suit immédiatement l'acceptation, avant de
    // passer au demandeur suivant.
    final resultatModibo = await db.accepterDemandePret(
      demandeId: demandeModibo,
      montantAccepteFcfa: prochaine.montantProposeFcfa,
      agentPhone: '+2250700000099',
    );
    final pretModibo = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultatModibo.pretId)))
        .getSingle();
    expect(pretModibo.principalFcfa, 15000);
    await db.confirmerPretParSignature(
      pretId: resultatModibo.pretId,
      signatureData: '10.0,20.0;15.0,25.0',
      witnessPhone: '+2250700000099',
    );

    // La caisse restante diminue d'autant pour Seydou, seul demandeur
    // restant : il ne reste que 15000 pour sa demande de 30000 ->
    // toujours proportionnel, mais seul en lice -> reçoit tout ce qui
    // reste (total restant = sa propre demande = 30000 > 15000
    // restants -> proportionnel = 30000 * 15000 / 30000 = 15000).
    prochaine = await db.prochaineDemandeAvecAllocation(ctx.cycleId);
    expect(prochaine!.demande.id, demandeSeydou);
    expect(prochaine.montantProposeFcfa, 15000);
  });

  test('refuse d\'accepter plus que le montant demandé', () async {
    final ctx = await preparerGroupe();
    final ayaId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Aya Kone',
      joinedAt: DateTime(2023, 12, 4),
    );
    final demandeId = await db.demanderPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ayaId,
      montantDemandeFcfa: 10000,
      recordedByPhone: '+2250700000099',
    );

    expect(
      () => db.accepterDemandePret(
        demandeId: demandeId,
        montantAccepteFcfa: 20000,
        agentPhone: '+2250700000099',
      ),
      throwsArgumentError,
    );
  });

  test('refuse de traiter deux fois la même demande', () async {
    final ctx = await preparerGroupe();
    final ayaId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Aya Kone',
      joinedAt: DateTime(2023, 12, 4),
    );
    final demandeId = await db.demanderPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ayaId,
      montantDemandeFcfa: 10000,
      recordedByPhone: '+2250700000099',
    );
    await db.refuserDemandePret(
      demandeId: demandeId,
      agentPhone: '+2250700000099',
    );

    expect(
      () => db.accepterDemandePret(
        demandeId: demandeId,
        montantAccepteFcfa: 10000,
        agentPhone: '+2250700000099',
      ),
      throwsStateError,
    );
    expect(
      () => db.refuserDemandePret(
        demandeId: demandeId,
        agentPhone: '+2250700000099',
      ),
      throwsStateError,
    );
  });

  test(
      'le prêt accepté est résolu au taux d\'un prêt neuf, jamais un taux plat',
      () async {
    final ctx = await preparerGroupe();
    final ayaId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Aya Kone',
      joinedAt: DateTime(2023, 12, 4),
    );
    final autreId = await db.ajouterMembre(
      groupId: ctx.groupId,
      fullName: 'Autre',
      joinedAt: DateTime(2023, 12, 4),
    );
    await db.enregistrerCotisationCash(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: autreId,
      partsCount: 200, // 100000 F -> caisse largement suffisante
      recordedByPhone: '+2250700000099',
    );
    // Aya n'a rien cotisé -> plafond 3x nul -> hors carnet.
    final demandeId = await db.demanderPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ayaId,
      montantDemandeFcfa: 10000,
      recordedByPhone: '+2250700000099',
    );

    final resultat = await db.accepterDemandePret(
      demandeId: demandeId,
      montantAccepteFcfa: 10000,
      agentPhone: '+2250700000099',
    );
    final pret = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultat.pretId)))
        .getSingle();
    expect(pret.interestRatePercent, LoanRateResolver.tauxHorsCarnet);
  });

  test('aucune demande en attente -> prochaineDemandeAvecAllocation est null', () async {
    final ctx = await preparerGroupe();
    expect(await db.prochaineDemandeAvecAllocation(ctx.cycleId), isNull);
  });
}

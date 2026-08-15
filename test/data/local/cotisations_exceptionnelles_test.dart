import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

/// Cotisations exceptionnelles (mariage, décès, accouchement...) — voir
/// DECISIONS.md, "Cotisations exceptionnelles" et RETOURS_TERRAIN.md,
/// point 7 : déclarées une fois, s'appliquent à tous les membres déjà
/// présents, réglables à tout moment, déduites automatiquement des
/// parts si la date limite passe sans paiement.
void main() {
  late AppDatabase db;
  final debutCycle = DateTime(2024, 1, 4);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    AppClock.definir(debutCycle);
  });

  tearDown(() async {
    AppClock.definir(null);
    await db.close();
  });

  Future<({String groupId, String cycleId, String membreId})> preparer() async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 5,
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
      joinedAt: debutCycle,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 1000,
      interestRatePercent: 0,
      startedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      nombreCarnets: 1,
    );
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  test(
    'un membre déjà présent doit la cotisation exceptionnelle, un membre qui rejoint après non',
    () async {
      final ctx = await preparer();
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 1000,
        dateLimite: debutCycle.add(const Duration(days: 30)),
        createdByPhone: '+2250000099',
      );
      final evt = (await db.cotisationsExceptionnellesDuCycle(ctx.cycleId))
          .firstWhere((e) => e.id == evtId);

      expect(
        await db.soldeCotisationExceptionnelleFcfa(
          evt: evt,
          memberId: ctx.membreId,
        ),
        1000,
      );

      final nouveauMembreId = await db.ajouterMembre(
        groupId: ctx.groupId,
        fullName: 'Seydou Traore',
        phoneNumber: '+2250000002',
        joinedAt: debutCycle.add(const Duration(days: 1)),
      );
      expect(
        await db.soldeCotisationExceptionnelleFcfa(
          evt: evt,
          memberId: nouveauMembreId,
        ),
        0,
        reason: 'a rejoint après la déclaration de l\'événement',
      );
    },
  );

  test('un versement réduit le solde, jamais sous zéro', () async {
    final ctx = await preparer();
    final evtId = await db.enregistrerCotisationExceptionnelle(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      motif: 'Décès du père de Kouassi',
      montantFcfa: 500,
      dateLimite: debutCycle.add(const Duration(days: 30)),
      createdByPhone: '+2250000099',
    );
    final evt = (await db.cotisationsExceptionnellesDuCycle(ctx.cycleId))
        .firstWhere((e) => e.id == evtId);

    await db.enregistrerContributionFondsSolidarite(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      montantFcfa: 500,
      motif: 'Cotisation exceptionnelle',
      recordedByPhone: '+2250000099',
      cotisationExceptionnelleId: evtId,
    );

    expect(
      await db.soldeCotisationExceptionnelleFcfa(
        evt: evt,
        memberId: ctx.membreId,
      ),
      0,
    );
    expect(
      await db.cotisationsExceptionnellesNonSoldeesDuMembre(
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
      ),
      isEmpty,
    );
  });

  test(
    'un versement pour une cotisation exceptionnelle ne solde jamais le fonds obligatoire, et inversement',
    () async {
      final ctx = await preparer();
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Accouchement de Fatou',
        montantFcfa: 500,
        dateLimite: debutCycle.add(const Duration(days: 30)),
        createdByPhone: '+2250000099',
      );
      await db.enregistrerContributionFondsSolidarite(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        montantFcfa: 500,
        motif: 'Cotisation exceptionnelle',
        recordedByPhone: '+2250000099',
        cotisationExceptionnelleId: evtId,
      );
      expect(
        await db.totalVerseFondsSolidariteMembre(
          cycleId: ctx.cycleId,
          memberId: ctx.membreId,
        ),
        0,
        reason: 'un versement ciblé ne compte pas pour le fonds récurrent',
      );
    },
  );

  test(
    'preparerPartageCycle ignore une cotisation exceptionnelle dont la date limite n\'est pas encore passée',
    () async {
      final ctx = await preparer();
      await db.enregistrerCotisationCash(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        partsCount: 3,
        recordedByPhone: '+2250000099',
      );
      await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 30)), // pas encore passée
        createdByPhone: '+2250000099',
      );

      final prepared = await db.preparerPartageCycle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
      );
      expect(prepared.cotisationsExceptionnellesADeduire, isEmpty);
      expect(prepared.membres.single.totalParts, 3);
    },
  );

  test(
    'preparerPartageCycle déduit une cotisation exceptionnelle échue et impayée, exclue de la caisse',
    () async {
      final ctx = await preparer();
      await db.enregistrerCotisationCash(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        partsCount: 3, // 3000 F
        recordedByPhone: '+2250000099',
      );
      await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      // La date limite est maintenant dépassée.
      AppClock.definir(debutCycle.add(const Duration(days: 20)));

      final prepared = await db.preparerPartageCycle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
      );

      // 3000 F cotisés, 800 F dus -> reste 2200 F -> 2 parts reconnues
      // (2000 F) + 200 F de résidu, jamais mis en commun.
      expect(prepared.membres.single.totalParts, 2);
      expect(prepared.membres.single.residuSansBonusFcfa, 200);
      expect(prepared.cotisationsEffectivesTotalesFcfa, 2000);
      expect(prepared.cotisationsExceptionnellesADeduire, hasLength(1));
      expect(
        prepared.cotisationsExceptionnellesADeduire.single.montantFcfa,
        800,
      );
      expect(
        prepared.cotisationsExceptionnellesADeduire.single.memberId,
        ctx.membreId,
      );
    },
  );

  test(
    'les réductions amende puis cotisation exceptionnelle se chaînent, jamais l\'inverse',
    () async {
      final ctx = await preparer();
      await db.enregistrerCotisationCash(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        partsCount: 3, // 3000 F
        recordedByPhone: '+2250000099',
      );
      await db.enregistrerAmende(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        montantFcfa: 500,
        motif: 'Retard',
        recordedByPhone: '+2250000099',
      );
      await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      AppClock.definir(debutCycle.add(const Duration(days: 20)));

      final prepared = await db.preparerPartageCycle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
      );

      // 3000 F cotisés, 500 F d'amende -> reste 2500 F -> 2 parts (2000)
      // + 500 F résidu. Puis 800 F de cotisation exceptionnelle sur ce
      // reste de 2500 F -> reste 1700 F -> 1 part (1000) + 700 F résidu.
      final m = prepared.membres.single;
      expect(m.totalParts, 1);
      expect(m.residuSansBonusFcfa, 700);
      expect(prepared.amendesADeduireParMembre[ctx.membreId], 500);
      expect(
        prepared.cotisationsExceptionnellesADeduire.single.montantFcfa,
        800,
      );
      expect(prepared.cotisationsEffectivesTotalesFcfa, 1000);
    },
  );

  test(
    'cloturerCycleEtOuvrirSuivant enregistre la déduction automatique comme une contribution',
    () async {
      final ctx = await preparer();
      await db.enregistrerCotisationCash(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        partsCount: 3,
        recordedByPhone: '+2250000099',
      );
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      AppClock.definir(debutCycle.add(const Duration(days: 20)));

      await db.confirmerPaiementMembre(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        confirmedByPhone: '+2250000099',
      );
      await db.cloturerCycleEtOuvrirSuivant(
        groupId: ctx.groupId,
        cycleIdACloturer: ctx.cycleId,
        nouveauPartValueFcfa: 1000,
        nouveauInterestRatePercent: 0,
        recordedByPhone: '+2250000099',
      );

      final evt = (await db.cotisationsExceptionnellesDuCycle(ctx.cycleId))
          .firstWhere((e) => e.id == evtId);
      expect(
        await db.soldeCotisationExceptionnelleFcfa(
          evt: evt,
          memberId: ctx.membreId,
        ),
        0,
        reason: 'soldée automatiquement par la déduction à la clôture',
      );
      expect(
        await db.totalVerseCotisationExceptionnelle(
          cotisationExceptionnelleId: evtId,
          memberId: ctx.membreId,
        ),
        800,
      );
    },
  );

  test(
    'modifierCotisationExceptionnelle change motif/montant/date limite sans '
    'toucher aux paiements déjà enregistrés',
    () async {
      final ctx = await preparer();
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 1000,
        dateLimite: debutCycle.add(const Duration(days: 30)),
        createdByPhone: '+2250000099',
      );
      await db.enregistrerContributionFondsSolidarite(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        montantFcfa: 400,
        motif: 'Mariage de Awa',
        recordedByPhone: '+2250000099',
        cotisationExceptionnelleId: evtId,
      );

      final nouvelleDate = debutCycle.add(const Duration(days: 60));
      await db.modifierCotisationExceptionnelle(
        id: evtId,
        motif: 'Mariage de Awa Koné',
        montantFcfa: 1500,
        dateLimite: nouvelleDate,
      );

      final evt = (await db.cotisationsExceptionnellesDuCycle(ctx.cycleId))
          .firstWhere((e) => e.id == evtId);
      expect(evt.motif, 'Mariage de Awa Koné');
      expect(evt.montantFcfa, 1500);
      expect(evt.dateLimite, nouvelleDate);

      // Le paiement déjà enregistré reste inchangé.
      expect(
        await db.totalVerseCotisationExceptionnelle(
          cotisationExceptionnelleId: evtId,
          memberId: ctx.membreId,
        ),
        400,
      );
      expect(
        await db.soldeCotisationExceptionnelleFcfa(
          evt: evt,
          memberId: ctx.membreId,
        ),
        1100, // 1500 - 400, le nouveau montant s'applique
      );
    },
  );

  test(
    'modifierCotisationExceptionnelle : réduire le montant sous ce qui a '
    'déjà été versé ne rend jamais le solde négatif',
    () async {
      final ctx = await preparer();
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Décès',
        montantFcfa: 1000,
        dateLimite: debutCycle.add(const Duration(days: 30)),
        createdByPhone: '+2250000099',
      );
      await db.enregistrerContributionFondsSolidarite(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        montantFcfa: 1000,
        motif: 'Décès',
        recordedByPhone: '+2250000099',
        cotisationExceptionnelleId: evtId,
      );

      await db.modifierCotisationExceptionnelle(
        id: evtId,
        motif: 'Décès',
        montantFcfa: 500,
        dateLimite: debutCycle.add(const Duration(days: 30)),
      );

      final evt = (await db.cotisationsExceptionnellesDuCycle(ctx.cycleId))
          .firstWhere((e) => e.id == evtId);
      expect(
        await db.soldeCotisationExceptionnelleFcfa(
          evt: evt,
          memberId: ctx.membreId,
        ),
        0,
      );
    },
  );

  test(
    'appliquerDeductionsCotisationsExceptionnellesEchues déduit le solde '
    'restant dès que la date limite est dépassée — voir RETOURS_TERRAIN.md, '
    'point 25.4',
    () async {
      final ctx = await preparer();
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      // La date limite n'est pas encore passée -> rien ne se passe.
      await db.appliquerDeductionsCotisationsExceptionnellesEchues(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        agentPhone: '+2250000099',
      );
      expect(
        await db.totalVerseCotisationExceptionnelle(
          cotisationExceptionnelleId: evtId,
          memberId: ctx.membreId,
        ),
        0,
      );

      // La date limite est maintenant dépassée.
      AppClock.definir(debutCycle.add(const Duration(days: 20)));
      await db.appliquerDeductionsCotisationsExceptionnellesEchues(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        agentPhone: '+2250000099',
      );

      final evt = (await db.cotisationsExceptionnellesDuCycle(ctx.cycleId))
          .firstWhere((e) => e.id == evtId);
      expect(
        await db.soldeCotisationExceptionnelleFcfa(
          evt: evt,
          memberId: ctx.membreId,
        ),
        0,
        reason: 'déduit automatiquement — plus rien dû',
      );
      expect(
        await db.totalVerseCotisationExceptionnelle(
          cotisationExceptionnelleId: evtId,
          memberId: ctx.membreId,
        ),
        800,
      );
    },
  );

  test(
    'appliquerDeductionsCotisationsExceptionnellesEchues est idempotent — '
    'jamais deux déductions pour le même membre',
    () async {
      final ctx = await preparer();
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      AppClock.definir(debutCycle.add(const Duration(days: 20)));

      // Appelé plusieurs fois de suite — simule plusieurs ouvertures
      // d'écran successives.
      for (var i = 0; i < 3; i++) {
        await db.appliquerDeductionsCotisationsExceptionnellesEchues(
          groupId: ctx.groupId,
          cycleId: ctx.cycleId,
          agentPhone: '+2250000099',
        );
      }

      expect(
        await db.totalVerseCotisationExceptionnelle(
          cotisationExceptionnelleId: evtId,
          memberId: ctx.membreId,
        ),
        800,
        reason: 'jamais déduit plus d\'une fois',
      );
    },
  );

  test(
    'appliquerDeductionsCotisationsExceptionnellesEchues ne déduit que le '
    'solde restant après un versement partiel',
    () async {
      final ctx = await preparer();
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      await db.enregistrerContributionFondsSolidarite(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        montantFcfa: 300,
        motif: 'Mariage de Awa',
        recordedByPhone: '+2250000099',
        cotisationExceptionnelleId: evtId,
      );
      AppClock.definir(debutCycle.add(const Duration(days: 20)));

      await db.appliquerDeductionsCotisationsExceptionnellesEchues(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        agentPhone: '+2250000099',
      );

      expect(
        await db.totalVerseCotisationExceptionnelle(
          cotisationExceptionnelleId: evtId,
          memberId: ctx.membreId,
        ),
        800,
        reason: '300 déjà versés + 500 déduits automatiquement',
      );
    },
  );

  test(
    'appliquerDeductionsCotisationsExceptionnellesEchues n\'affecte jamais '
    'un membre qui a rejoint après la déclaration',
    () async {
      final ctx = await preparer();
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      final nouveauMembreId = await db.ajouterMembre(
        groupId: ctx.groupId,
        fullName: 'Seydou Traore',
        phoneNumber: '+2250000002',
        joinedAt: debutCycle.add(const Duration(days: 5)),
      );
      AppClock.definir(debutCycle.add(const Duration(days: 20)));

      await db.appliquerDeductionsCotisationsExceptionnellesEchues(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        agentPhone: '+2250000099',
      );

      expect(
        await db.totalVerseCotisationExceptionnelle(
          cotisationExceptionnelleId: evtId,
          memberId: nouveauMembreId,
        ),
        0,
      );
    },
  );

  test(
    'preparerPartageCycle continue de prévisualiser la même réduction, que '
    'la déduction immédiate ait déjà eu lieu ou non (basée sur le cash, '
    'jamais sur la ligne automatique elle-même)',
    () async {
      final ctx = await preparer();
      await db.enregistrerCotisationCash(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        partsCount: 3, // 3000 F
        recordedByPhone: '+2250000099',
      );
      await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      AppClock.definir(debutCycle.add(const Duration(days: 20)));

      // Déduite tout de suite, avant la clôture.
      await db.appliquerDeductionsCotisationsExceptionnellesEchues(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        agentPhone: '+2250000099',
      );

      final prepared = await db.preparerPartageCycle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
      );

      // Toujours prévisualisée (basée sur le cash, jamais sur la ligne
      // automatique déjà écrite) — c'est la clôture elle-même qui évite
      // la réécriture, pas cette prévisualisation (voir le test suivant).
      expect(prepared.cotisationsExceptionnellesADeduire, hasLength(1));
      expect(
        prepared.cotisationsExceptionnellesADeduire.single.montantFcfa,
        800,
      );
      // 3000 F cotisés - 800 F déjà déduits -> 2200 F -> 2 parts + 200 résidu.
      expect(prepared.membres.single.totalParts, 2);
      expect(prepared.membres.single.residuSansBonusFcfa, 200);
    },
  );

  test(
    'cloturerCycleEtOuvrirSuivant ne réécrit jamais une déduction déjà '
    'appliquée immédiatement avant la clôture',
    () async {
      final ctx = await preparer();
      await db.enregistrerCotisationCash(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        partsCount: 3,
        recordedByPhone: '+2250000099',
      );
      final evtId = await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      AppClock.definir(debutCycle.add(const Duration(days: 20)));

      // Déduite tout de suite, avant la clôture.
      await db.appliquerDeductionsCotisationsExceptionnellesEchues(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        agentPhone: '+2250000099',
      );

      await db.confirmerPaiementMembre(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        confirmedByPhone: '+2250000099',
      );
      await db.cloturerCycleEtOuvrirSuivant(
        groupId: ctx.groupId,
        cycleIdACloturer: ctx.cycleId,
        nouveauPartValueFcfa: 1000,
        nouveauInterestRatePercent: 0,
        recordedByPhone: '+2250000099',
      );

      expect(
        await db.totalVerseCotisationExceptionnelle(
          cotisationExceptionnelleId: evtId,
          memberId: ctx.membreId,
        ),
        800,
        reason: 'jamais 1600 — la clôture ne doit pas réécrire ce qui a '
            'déjà été déduit immédiatement',
      );
    },
  );

  test(
    'appliquerDeductionsCotisationsExceptionnellesEchues n\'a aucun effet '
    'sur un cycle déjà clos',
    () async {
      final ctx = await preparer();
      await db.enregistrerCotisationExceptionnelle(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        motif: 'Mariage de Awa',
        montantFcfa: 800,
        dateLimite: debutCycle.add(const Duration(days: 10)),
        createdByPhone: '+2250000099',
      );
      AppClock.definir(debutCycle.add(const Duration(days: 20)));
      await db.confirmerPaiementMembre(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        confirmedByPhone: '+2250000099',
      );
      await db.cloturerCycleEtOuvrirSuivant(
        groupId: ctx.groupId,
        cycleIdACloturer: ctx.cycleId,
        nouveauPartValueFcfa: 1000,
        nouveauInterestRatePercent: 0,
        recordedByPhone: '+2250000099',
      );

      // Ne doit lever aucune exception sur un cycle déjà clos.
      await db.appliquerDeductionsCotisationsExceptionnellesEchues(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        agentPhone: '+2250000099',
      );
    },
  );

  test('modifierCotisationExceptionnelle refuse un montant nul ou négatif', () async {
    final ctx = await preparer();
    final evtId = await db.enregistrerCotisationExceptionnelle(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      motif: 'Mariage',
      montantFcfa: 1000,
      dateLimite: debutCycle.add(const Duration(days: 30)),
      createdByPhone: '+2250000099',
    );

    expect(
      () => db.modifierCotisationExceptionnelle(
        id: evtId,
        motif: 'Mariage',
        montantFcfa: 0,
        dateLimite: debutCycle.add(const Duration(days: 30)),
      ),
      throwsArgumentError,
    );
  });
}

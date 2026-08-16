import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/core/formatting.dart';
import 'package:cotisapp/data/auth/auth_gateway.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/domain/calculators/loan_rate_resolver.dart';
import 'package:cotisapp/features/loans/loans_screen.dart';
import 'package:cotisapp/state/providers.dart';

void main() {
  Future<({String groupId, String cycleId, String membreId})> preparer(
    AppDatabase db,
  ) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
    );
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  testWidgets(
    'le bouton Remboursement disparaît une fois le prêt intégralement soldé',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ctx = await preparer(db);

      final resultat = await db.enregistrerPret(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        principalFcfa: 10000,
        interestRatePercent: 10,
        initiatedByPhone: '+2250000099',
        confirmationCode: '1234',
        provenance: 'importe',
      );
      await db.confirmerPret(
        pretId: resultat.pretId,
        codeSaisi: '1234',
        confirmedByPhone: '+2250000001',
      );
      // 10000 + 10% = 11000 dû -> remboursement intégral.
      await db.enregistrerRemboursement(
        pretId: resultat.pretId,
        montantFcfa: 11000,
        recordedByPhone: '+2250000099',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: LoansScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remboursement'), findsNothing);
      expect(find.textContaining('Soldé'), findsOneWidget);
    },
  );

  testWidgets(
    'le bouton Remboursement reste visible tant que le prêt n\'est pas soldé',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ctx = await preparer(db);

      final resultat = await db.enregistrerPret(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        principalFcfa: 10000,
        interestRatePercent: 10,
        initiatedByPhone: '+2250000099',
        confirmationCode: '1234',
        provenance: 'importe',
      );
      await db.confirmerPret(
        pretId: resultat.pretId,
        codeSaisi: '1234',
        confirmedByPhone: '+2250000001',
      );
      // Remboursement partiel seulement.
      await db.enregistrerRemboursement(
        pretId: resultat.pretId,
        montantFcfa: 5000,
        recordedByPhone: '+2250000099',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: LoansScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remboursement'), findsOneWidget);
    },
  );

  group('Résolution du taux en direct dans le dialogue "Nouveau prêt"', () {
    // Réunions le 4 de chaque mois, cycle commencé le 4 décembre -> le 4
    // janvier est la 2e réunion : fenêtre de crédit ouverte (voir
    // DECISIONS.md, "Fenêtres de crédit selon la fréquence de réunion").
    setUp(() => AppClock.definir(DateTime(2024, 1, 4)));
    tearDown(() => AppClock.definir(null));

    testWidgets(
      'affiche le taux dans le carnet sous le plafond, puis hors carnet au-dessus',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
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
        final membreId = await db.ajouterMembre(
          groupId: groupId,
          fullName: 'Aya Kone',
          phoneNumber: '+2250000001',
        );
        final ctx = (groupId: groupId, cycleId: cycleId, membreId: membreId);

        // Cotise 10000 -> plafond 30000 pour Aya (voir LoanRateResolver).
        await db.enregistrerCotisationCash(
          groupId: ctx.groupId,
          cycleId: ctx.cycleId,
          memberId: ctx.membreId,
          partsCount: 20,
          recordedByPhone: '+2250000099',
        );
        // Un second membre cotise largement, uniquement pour que la
        // caisse disponible du groupe couvre le prêt testé plus bas
        // (voir DECISIONS.md, "Rationnement des crédits selon la
        // caisse disponible") — sans toucher au plafond 3x d'Aya
        // elle-même, qui ne dépend que de sa propre cotisation.
        final autreMembreId = await db.ajouterMembre(
          groupId: ctx.groupId,
          fullName: 'Autre Membre',
          phoneNumber: '+2250000002',
        );
        await db.enregistrerCotisationCash(
          groupId: ctx.groupId,
          cycleId: ctx.cycleId,
          memberId: autreMembreId,
          partsCount: 100, // 50 000 F
          recordedByPhone: '+2250000099',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: LoansScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aya Kone').last);
        await tester.pumpAndSettle();

        // Sous le plafond (20000 <= 30000) -> dans le carnet.
        await tester.enterText(find.byType(TextFormField), '20000');
        await tester.pumpAndSettle();
        expect(find.textContaining('10 %'), findsOneWidget);
        expect(find.textContaining('dans le carnet'), findsOneWidget);

        // Au-dessus du plafond (40000 > 30000) -> hors carnet.
        await tester.enterText(find.byType(TextFormField), '40000');
        await tester.pumpAndSettle();
        expect(find.textContaining('15 %'), findsOneWidget);
        expect(find.textContaining('dépasse'), findsOneWidget);

        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();

        // Aya Kone a un téléphone -> une boîte de dialogue de code SMS
        // s'ouvre ; on la ferme sans confirmer, seul le taux enregistré
        // sur le prêt nous intéresse ici.
        await tester.tap(find.text('Plus tard'));
        await tester.pumpAndSettle();

        final prets = await db.pretsDuCycle(ctx.cycleId);
        expect(prets, hasLength(1));
        expect(
          prets.single.interestRatePercent,
          LoanRateResolver.tauxHorsCarnet,
        );
      },
    );

    testWidgets(
      'hors fenêtre de crédit : bannière visible, bouton "Nouveau prêt" désactivé',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
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
        await db.ajouterMembre(
          groupId: groupId,
          fullName: 'Aya Kone',
          phoneNumber: '+2250000001',
        );
        // AppClock (voir setUp du groupe) est au 4 janvier -> 1re
        // réunion seulement : fenêtre fermée (voir DECISIONS.md).

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: LoansScreen(groupId: groupId, cycleId: cycleId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Aucune fenêtre de crédit'),
          findsOneWidget,
        );
        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        expect(fab.onPressed, isNull);
      },
    );
  });

  testWidgets(
    'un montant supérieur à la caisse disponible est refusé',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
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
      final membreId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
        // Date explicite plutôt que l'horloge réelle — AppClock n'est
        // simulée que plus bas, après cet appel (voir DECISIONS.md,
        // "Inscription de nouveaux membres : sans limite, sauf fin de
        // cycle", sensible au temps).
        joinedAt: DateTime(2023, 12, 4),
      );
      // Cotise seulement 5000 F -> caisse disponible = 5000 F.
      await db.enregistrerCotisationCash(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membreId,
        partsCount: 10,
        recordedByPhone: '+2250000099',
      );
      AppClock.definir(DateTime(2024, 1, 4)); // 2e réunion -> fenêtre ouverte
      addTearDown(() => AppClock.definir(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: LoansScreen(groupId: groupId, cycleId: cycleId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aya Kone').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '10000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dépasse la caisse disponible'), findsOneWidget);
      expect(await db.pretsDuCycle(cycleId), isEmpty);
    },
  );

  group('Sortir du rouge (voir DECISIONS.md, "Sortir du rouge : paiement libre")', () {
    Future<
        ({
          AppDatabase db,
          String groupId,
          String cycleId,
          String membreId,
          String pretId,
        })> preparerPretAuRouge() async {
      final db = AppDatabase(NativeDatabase.memory());
      final groupId = await db.creerGroupe(
        name: 'Groupe test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
        // Différent du jour de création du prêt (1er) — voir le
        // commentaire équivalent dans sortir_du_rouge_test.dart.
        paymentDayOfMonth1: 15,
        montantAmendeSortieRougeFcfa: 1000,
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 10,
        loanDurationDays: 30,
        startedAt: DateTime(2024, 1, 1),
      );
      final membreId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
        // Date explicite plutôt que l'horloge réelle (voir
        // DECISIONS.md, "Inscription de nouveaux membres : sans
        // limite, sauf fin de cycle", sensible au temps).
        joinedAt: DateTime(2024, 1, 1),
      );
      final resultat = await db.enregistrerPret(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membreId,
        principalFcfa: 10000,
        interestRatePercent: 10,
        initiatedByPhone: '+2250000099',
        dureeJours: 30,
        provenance: 'importe',
        createdAt: DateTime(2024, 1, 1),
      );
      // Bien après la période normale + un mois calendaire plein ->
      // au rouge, une recomposition à 10 % déjà appliquée (voir
      // LoanBalanceCalculator) : soldeAuDebutDuRouge = 11000,
      // montantDuFcfa = 12100 au 1er mars.
      AppClock.definir(DateTime(2024, 3, 1));
      return (
        db: db,
        groupId: groupId,
        cycleId: cycleId,
        membreId: membreId,
        pretId: resultat.pretId,
      );
    }

    testWidgets(
      'payer le minimum pré-rempli reconduit le principal d\'origine, sans amende séparée',
      (tester) async {
        final ctx = await preparerPretAuRouge();
        addTearDown(ctx.db.close);
        addTearDown(() => AppClock.definir(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(ctx.db)],
            child: MaterialApp(
              home: LoansScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('AU ROUGE'), findsOneWidget);

        await tester.tap(find.text('Sortir du rouge'));
        await tester.pumpAndSettle();

        expect(
          find.text('Intérêts accumulés : ${formatFcfa(1100)}'),
          findsOneWidget,
        );
        expect(
          find.text('Amende de sortie du rouge : ${formatFcfa(1000)}'),
          findsOneWidget,
        );
        // Champ "Montant payé" pré-rempli au minimum (1100 + 1000).
        final champMontant = tester.widget<TextFormField>(
          find.byType(TextFormField),
        );
        expect(champMontant.controller!.text, '2100');
        expect(
          find.text('Prêt reconduit : ${formatFcfa(11000)}'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
        await tester.pumpAndSettle();

        // Aya Kone a un téléphone -> la confirmation du nouveau prêt
        // successeur passe par le code SMS de test.
        expect(find.text('Confirmation du prêt'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField),
          DevAuthGateway.codeDeTest,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
        await tester.pumpAndSettle();

        final prets = await ctx.db.pretsDuCycle(ctx.cycleId);
        expect(prets, hasLength(2));
        final nouveauPret = prets.firstWhere((p) => p.id != ctx.pretId);
        expect(nouveauPret.renouvelePretId, ctx.pretId);
        expect(nouveauPret.provenance, 'renouvellement');
        expect(nouveauPret.principalFcfa, 11000);
        expect(await ctx.db.pretEstConfirme(nouveauPret.id), isTrue);

        // L'amende n'a jamais de trace séparée (voir DECISIONS.md) —
        // payée cash ici, elle n'apparaît jamais comme une Amende.
        final amendesGroupe = await (ctx.db.select(ctx.db.amendes)
              ..where((a) => a.memberId.equals(ctx.membreId)))
            .get();
        expect(amendesGroupe, isEmpty);
      },
    );

    testWidgets(
      'ne rien payer ajoute la dette du jour au prêt reconduit',
      (tester) async {
        final ctx = await preparerPretAuRouge();
        addTearDown(ctx.db.close);
        addTearDown(() => AppClock.definir(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(ctx.db)],
            child: MaterialApp(
              home: LoansScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sortir du rouge'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), '0');
        await tester.pumpAndSettle();
        // 12100 (dette du jour) + 1000 (amende non payée) - 0 = 13100.
        expect(
          find.text('Prêt reconduit : ${formatFcfa(13100)}'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          DevAuthGateway.codeDeTest,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
        await tester.pumpAndSettle();

        final prets = await ctx.db.pretsDuCycle(ctx.cycleId);
        final nouveauPret = prets.firstWhere((p) => p.id != ctx.pretId);
        expect(nouveauPret.principalFcfa, 13100);
        expect(await ctx.db.remboursementsDuPret(ctx.pretId), isEmpty);
      },
    );
  });

  group(
    'Rationnement collectif des crédits (voir DECISIONS.md, "Rationnement collectif des crédits")',
    () {
      testWidgets(
        'demander, traiter avec désistement puis acceptations, redistribution immédiate',
        (tester) async {
          final db = AppDatabase(NativeDatabase.memory());
          addTearDown(db.close);
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
          // Date explicite plutôt que l'horloge réelle (voir
          // DECISIONS.md, "Inscription de nouveaux membres : sans
          // limite, sauf fin de cycle", sensible au temps).
          await db.ajouterMembre(
            groupId: groupId,
            fullName: 'Aya Kone',
            phoneNumber: '+2250000001',
            joinedAt: DateTime(2023, 12, 4),
          );
          await db.ajouterMembre(
            groupId: groupId,
            fullName: 'Modibo Sanogo',
            phoneNumber: '+2250000002',
            joinedAt: DateTime(2023, 12, 4),
          );
          final seydouId = await db.ajouterMembre(
            groupId: groupId,
            fullName: 'Seydou Traore',
            phoneNumber: '+2250000003',
            joinedAt: DateTime(2023, 12, 4),
          );
          // Caisse disponible = 30000 F.
          await db.enregistrerCotisationCash(
            groupId: groupId,
            cycleId: cycleId,
            memberId: seydouId,
            partsCount: 60,
            recordedByPhone: '+2250000099',
          );
          AppClock.definir(DateTime(2024, 1, 4)); // 2e réunion -> fenêtre ouverte
          addTearDown(() => AppClock.definir(null));

          await tester.pumpWidget(
            ProviderScope(
              overrides: [databaseProvider.overrideWithValue(db)],
              child: MaterialApp(
                home: LoansScreen(groupId: groupId, cycleId: cycleId),
              ),
            ),
          );
          await tester.pumpAndSettle();

          Future<void> deposerDemande(String nom, String montant) async {
            await tester.tap(find.text('Demander'));
            await tester.pumpAndSettle();
            await tester.tap(find.byType(DropdownButtonFormField<String>));
            await tester.pumpAndSettle();
            await tester.tap(find.text(nom).last);
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextFormField), montant);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Déposer la demande'));
            await tester.pumpAndSettle();
          }

          await deposerDemande('Aya Kone', '30000');
          await deposerDemande('Modibo Sanogo', '30000');
          await deposerDemande('Seydou Traore', '30000');

          expect(find.textContaining('3 demande(s) en attente'), findsOneWidget);

          await tester.tap(find.text('Traiter les demandes en attente'));
          await tester.pumpAndSettle();

          // Aya (1re, FIFO) : total 90000 / caisse 30000 -> 10000
          // proposé. Elle se désiste.
          expect(find.textContaining('Aya Kone a demandé'), findsOneWidget);
          expect(
            find.textContaining(formatFcfa(10000)),
            findsWidgets,
          );
          await tester.tap(find.text('Se désiste'));
          await tester.pumpAndSettle();

          // Modibo : total restant 60000 / caisse 30000 -> 15000
          // proposé (redistribution immédiate). Il accepte.
          expect(find.textContaining('Modibo Sanogo a demandé'), findsOneWidget);
          expect(find.textContaining(formatFcfa(15000)), findsWidgets);
          await tester.tap(find.text('Accepte'));
          await tester.pumpAndSettle();

          // Confirmation du prêt de Modibo (code SMS).
          expect(find.text('Confirmation du prêt'), findsOneWidget);
          await tester.enterText(
            find.byType(TextFormField),
            DevAuthGateway.codeDeTest,
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
          await tester.pumpAndSettle();

          // Seydou, seul restant : caisse encore disponible 15000
          // (30000 - 15000 accordés à Modibo, désormais confirmé) pour
          // sa demande de 30000 -> proposé 15000.
          expect(find.textContaining('Seydou Traore a demandé'), findsOneWidget);
          expect(find.textContaining(formatFcfa(15000)), findsWidgets);
          await tester.tap(find.text('Accepte'));
          await tester.pumpAndSettle();

          expect(find.text('Confirmation du prêt'), findsOneWidget);
          await tester.enterText(
            find.byType(TextFormField),
            DevAuthGateway.codeDeTest,
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
          await tester.pumpAndSettle();

          // Le message de fin ("Toutes les demandes ont été traitées")
          // est un SnackBar éphémère — pas vérifié ici (déjà disparu
          // après pumpAndSettle, qui attend sa durée complète). Le
          // signal durable, c'est l'en-tête de la file d'attente.
          expect(find.textContaining('Aucune demande en attente'), findsOneWidget);

          final prets = await db.pretsDuCycle(cycleId);
          expect(prets, hasLength(2)); // Modibo + Seydou, jamais Aya
          expect(
            prets.map((p) => p.principalFcfa).toList()..sort(),
            [15000, 15000],
          );
        },
      );
    },
  );

  testWidgets(
    'déplier un prêt affiche l\'historique des remboursements un par un',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ctx = await preparer(db);

      final resultat = await db.enregistrerPret(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        principalFcfa: 10000,
        interestRatePercent: 10,
        initiatedByPhone: '+2250000099',
        confirmationCode: '1234',
        provenance: 'importe',
      );
      await db.confirmerPret(
        pretId: resultat.pretId,
        codeSaisi: '1234',
        confirmedByPhone: '+2250000001',
      );
      await db.enregistrerRemboursement(
        pretId: resultat.pretId,
        montantFcfa: 3000,
        recordedByPhone: '+2250000099',
        recordedAt: DateTime(2024, 2, 1),
      );
      await db.enregistrerRemboursement(
        pretId: resultat.pretId,
        montantFcfa: 2000,
        recordedByPhone: '+2250000099',
        recordedAt: DateTime(2024, 2, 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
          ],
          child: MaterialApp(
            home: LoansScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fermé par défaut : l'historique n'est pas encore visible.
      expect(find.text('Remboursements'), findsNothing);

      await tester.tap(find.text('Aya Kone — emprunté ${formatFcfa(10000)}'));
      await tester.pumpAndSettle();

      expect(find.text('Remboursements'), findsOneWidget);
      expect(find.textContaining(formatFcfa(3000)), findsOneWidget);
      expect(find.textContaining(formatFcfa(2000)), findsOneWidget);
    },
  );
}

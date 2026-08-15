import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/cotisations/record_cotisation_screen.dart';
import 'package:cotisapp/state/providers.dart';

/// Test d'interface (pas seulement de base de données) pour le parcours
/// complet de la journée de cotisation : encaisser un membre, voir
/// l'encaissement apparaître en direct, clôturer, puis vérifier que la
/// saisie reste bloquée tant que la prochaine échéance n'est pas arrivée
/// — voir DECISIONS.md, "Clôture de journée : précisions apportées
/// après un premier test réel" et "Clôture de journée interactive".
void main() {
  final debutCycle = DateTime(2024, 1, 4); // jeudi

  Future<({String groupId, String cycleId, String membreId})> preparer(AppDatabase db) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
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
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 1);
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  setUp(() => AppClock.definir(debutCycle));
  tearDown(() => AppClock.definir(null));

  testWidgets(
      'encaisser un membre, le voir en direct, clôturer, puis la saisie reste bloquée',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparer(db);

    // Fenêtre agrandie : l'écran Cotisation par membre est plus haut
    // que le viewport de test par défaut (voir la note "ListView
    // lazy-building" dans les gotchas établis).
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
        ],
        child: MaterialApp(
          home: RecordCotisationScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // La journée du jour est ouverte : le choix du membre est visible.
    expect(find.textContaining('Journée du'), findsOneWidget);
    expect(find.text('1. Épargne'), findsOneWidget);

    // Sélectionner le membre -> ouvre l'écran Cotisation dédié.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aya Kone').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Épargne — 1/1'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ 1 part(s)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer et terminer'));
    await tester.pumpAndSettle();

    // Retour sur l'écran Cotisations : l'encaissement est visible en
    // direct, sans qu'il faille naviguer vers l'historique.
    expect(find.textContaining('Encaissements déjà enregistrés'), findsOneWidget);
    expect(find.textContaining('Aya Kone'), findsWidgets);

    // Clôturer la journée — le seul membre a payé, donc rien à traiter.
    await tester.tap(find.text('Clôturer cette journée'));
    await tester.pumpAndSettle();
    expect(find.textContaining('figurent sur la liste définitive'), findsOneWidget);
    await tester.tap(find.text('Clôturer définitivement'));
    await tester.pumpAndSettle();

    // Plus rien n'est proposé pour une nouvelle cotisation tant que la
    // prochaine échéance n'est pas arrivée.
    expect(find.text('1. Épargne'), findsNothing);
    expect(find.textContaining('Aucune journée d\'épargne ouverte'), findsOneWidget);
  });

  Future<
    ({String groupId, String cycleId, String ayaId, String seydouId})
  >
  preparerAvecCarnetNonTraite(AppDatabase db) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 100,
      montantAmendePayeParTiersFcfa: 50,
    );
    final ayaId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
      joinedAt: debutCycle,
    );
    final seydouId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Seydou Traore',
      phoneNumber: '+2250000002',
      joinedAt: debutCycle,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    for (final membreId in [ayaId, seydouId]) {
      await db.definirCarnetsEngages(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membreId,
        nombreCarnets: 1,
      );
    }
    // Seule Aya cotise le 4 janvier — le carnet de Seydou n'a encore
    // rien d'enregistré (ni cotisation, ni amende).
    await db.enregistrerEncaissementMembre(
      groupId: groupId,
      cycleId: cycleId,
      memberId: ayaId,
      partsParCarnet: {1: 1},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );
    return (groupId: groupId, cycleId: cycleId, ayaId: ayaId, seydouId: seydouId);
  }

  testWidgets(
      'clôturer avec un carnet non traité exige un motif choisi activement, aucun défaut',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparerAvecCarnetNonTraite(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
        ],
        child: MaterialApp(
          home: RecordCotisationScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pas de blocage préalable : la saisie de cotisation reste
    // immédiatement disponible (voir DECISIONS.md, "Clôture de journée
    // interactive" — remplace l'ancienne revue différée).
    expect(find.text('1. Épargne'), findsOneWidget);

    await tester.tap(find.text('Clôturer cette journée'));
    await tester.pumpAndSettle();

    expect(find.textContaining('carnet(s) sans rien d\'enregistré'), findsOneWidget);
    expect(find.textContaining('Seydou Traore'), findsOneWidget);
    // Aucun motif pré-sélectionné (révision du 2026-08-14 — voir
    // DECISIONS.md, "Clôture de journée interactive" : plus de repli
    // automatique sur "Absence", jamais d'amende sans choix actif de
    // l'agent) : le dropdown affiche l'indice, pas un motif déjà choisi.
    expect(find.text('Absence'), findsNothing);
    expect(find.text('Choisir…'), findsOneWidget);

    // Le bouton reste désactivé tant qu'aucun motif n'est choisi.
    var bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Clôturer définitivement'));
    expect(bouton.onPressed, isNull);
    expect(find.textContaining('Choisissez un motif'), findsOneWidget);

    // L'agent choisit explicitement "Absence" — un vrai geste, pas un
    // défaut qu'il aurait juste laissé passer.
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Absence').last);
    await tester.pumpAndSettle();

    bouton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Clôturer définitivement'));
    expect(bouton.onPressed, isNotNull);

    await tester.tap(find.text('Clôturer définitivement'));
    await tester.pumpAndSettle();

    final amendes = await db.amendesDuMembre(ctx.seydouId, ctx.cycleId);
    expect(amendes, hasLength(1));
    expect(amendes.single.motifCodeSysteme, AppDatabase.codeSystemeAbsence);
    expect(amendes.single.montantFcfa, 100);
    expect(amendes.single.reviewedAt, isNotNull,
        reason: 'choisi interactivement par l\'agent — jamais en attente de revue');
  });

  testWidgets(
      'clôturer permet de choisir "Payé par un tiers" pour un carnet non traité',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparerAvecCarnetNonTraite(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
        ],
        child: MaterialApp(
          home: RecordCotisationScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clôturer cette journée'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payé par un tiers').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clôturer définitivement'));
    await tester.pumpAndSettle();

    final amendes = await db.amendesDuMembre(ctx.seydouId, ctx.cycleId);
    expect(amendes, hasLength(1));
    expect(amendes.single.motifCodeSysteme, AppDatabase.codeSystemePayeParTiers);
    expect(amendes.single.montantFcfa, 50);
  });
}

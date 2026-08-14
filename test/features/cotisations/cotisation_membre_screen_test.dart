import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/cotisations/cotisation_membre_screen.dart';
import 'package:cotisapp/state/providers.dart';

/// Écran "Cotisation" — voir RETOURS_TERRAIN.md, point 20 et sa refonte
/// suivante : le seul écran actionnable par membre (cotisation,
/// présence, et toutes les autres actions dans une rangée de boutons),
/// avec possibilité d'enchaîner sur le membre suivant.
void main() {
  final debutCycle = DateTime(2024, 1, 4); // jeudi

  setUp(() => AppClock.definir(debutCycle));
  tearDown(() => AppClock.definir(null));

  Future<void> pump(
    WidgetTester tester,
    AppDatabase db, {
    required String groupId,
    required String cycleId,
    required List<Member> membres,
    int initialIndex = 0,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
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
          home: CotisationMembreScreen(
            groupId: groupId,
            cycleId: cycleId,
            membres: membres,
            initialIndex: initialIndex,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<({String groupId, String cycleId, Member membre})> preparer(
    AppDatabase db,
  ) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 200,
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
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      nombreCarnets: 1,
    );
    final membre = await (db.select(
      db.members,
    )..where((m) => m.id.equals(membreId))).getSingle();
    return (groupId: groupId, cycleId: cycleId, membre: membre);
  }

  testWidgets('enregistre une cotisation', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparer(db);

    await pump(
      tester,
      db,
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      membres: [ctx.membre],
    );

    expect(find.text('1. Épargne'), findsOneWidget);
    expect(find.text('Autres actions pour ce membre'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ 1 part(s)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer l\'épargne'));
    await tester.pumpAndSettle();

    final cotisations = await db.cotisationsDuCycle(ctx.cycleId);
    expect(cotisations, hasLength(1));
    expect(cotisations.single.partsCount, 1);
  });

  testWidgets(
      '"Ajouter amende" propose le carnet à traiter et résout l\'absence '
      'immédiatement', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 200,
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
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      nombreCarnets: 1,
    );
    final membre = await (db.select(
      db.members,
    )..where((m) => m.id.equals(membreId))).getSingle();

    await pump(
      tester,
      db,
      groupId: groupId,
      cycleId: cycleId,
      membres: [membre],
    );

    await tester.tap(find.text('Ajouter amende'));
    await tester.pumpAndSettle();
    expect(find.text('Carnet 1 — Absence'), findsOneWidget);
    expect(find.text('Autre amende (hors carnet)'), findsOneWidget);

    await tester.tap(find.text('Carnet 1 — Absence'));
    await tester.pumpAndSettle();

    final amendes = await db.amendesAutoDuMembre(
      memberId: membreId,
      cycleId: cycleId,
    );
    expect(amendes, hasLength(1));
    expect(amendes.single.motifCodeSysteme, AppDatabase.codeSystemeAbsence);
    expect(amendes.single.montantFcfa, 200);

    // Résolu tout de suite -> plus rien à traiter pour ce carnet.
    final aTraiter = await db.carnetsATraiterPourDate(
      groupId: groupId,
      cycleId: cycleId,
      date: debutCycle,
    );
    expect(aTraiter, isEmpty);
  });

  testWidgets('demander un crédit enregistre la demande', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparer(db);

    // Fenêtre de crédit hebdomadaire : ouverte à partir de la 4e
    // réunion (voir LoanWindowCalculator) — clôture les 3 premières.
    for (var semaine = 0; semaine <= 2; semaine++) {
      await db.cloturerJourneeCotisation(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        date: debutCycle.add(Duration(days: 7 * semaine)),
        agentPhone: '+2250000099',
      );
    }
    AppClock.definir(debutCycle.add(const Duration(days: 21)));

    await pump(
      tester,
      db,
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      membres: [ctx.membre],
    );

    await tester.tap(find.text('Demander prêt'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '10000');
    await tester.tap(find.text('Enregistrer la demande'));
    await tester.pumpAndSettle();

    final demandes = await db.demandesEnAttenteDuCycle(ctx.cycleId);
    expect(demandes, hasLength(1));
    expect(demandes.single.montantDemandeFcfa, 10000);
  });

  testWidgets('contribution au fonds de solidarité obligatoire', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
      montantAmendeAbsenceFcfa: 200,
      montantSolidariteObligatoireFcfa: 100,
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
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      nombreCarnets: 1,
    );
    final membre = await (db.select(
      db.members,
    )..where((m) => m.id.equals(membreId))).getSingle();

    await pump(
      tester,
      db,
      groupId: groupId,
      cycleId: cycleId,
      membres: [membre],
    );

    // "Fonds solidarité" est activé (groupe l'a rendu obligatoire).
    await tester.tap(find.text('Fonds solidarité'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final contributions = await (db.select(
      db.fondsSolidariteContributions,
    )..where((f) => f.memberId.equals(membreId))).get();
    expect(contributions, hasLength(1));
    expect(contributions.single.montantFcfa, 100);
  });

  testWidgets('enregistrer et passer au membre suivant avance dans la liste',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final aya = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
      joinedAt: debutCycle,
    );
    final seydou = await db.ajouterMembre(
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
    for (final id in [aya, seydou]) {
      await db.definirCarnetsEngages(
        groupId: groupId,
        cycleId: cycleId,
        memberId: id,
        nombreCarnets: 1,
      );
    }
    final membres = await db.membresDuGroupe(groupId);

    await pump(
      tester,
      db,
      groupId: groupId,
      cycleId: cycleId,
      membres: membres,
    );

    expect(find.textContaining('Épargne — 1/2'), findsOneWidget);
    expect(find.text('Aya Kone'), findsOneWidget);

    await tester.tap(find.text('Enregistrer et passer au membre suivant'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Épargne — 2/2'), findsOneWidget);
    expect(find.text('Seydou Traore'), findsOneWidget);
    expect(find.text('Enregistrer et terminer'), findsOneWidget);
  });
}

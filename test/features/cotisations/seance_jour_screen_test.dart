import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/cotisations/seance_jour_screen.dart';
import 'package:cotisapp/state/providers.dart';

/// Écran "Séance du jour" — voir RETOURS_TERRAIN.md, point 20 : vue
/// d'ensemble en lecture seule de la journée ouverte. Aucune action
/// possible ici (déplacées vers l'écran Cotisation, voir
/// cotisation_membre_screen_test.dart).
void main() {
  final debutCycle = DateTime(2024, 1, 4); // jeudi

  setUp(() => AppClock.definir(debutCycle));
  tearDown(() => AppClock.definir(null));

  Future<({String groupId, String cycleId, String membreId})> preparer(
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
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  Future<void> pump(
    WidgetTester tester,
    AppDatabase db, {
    required String groupId,
    required String cycleId,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
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
          home: SeanceJourScreen(groupId: groupId, cycleId: cycleId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('un membre pas encore traité est signalé, sans aucune action possible',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparer(db);

    await pump(tester, db, groupId: ctx.groupId, cycleId: ctx.cycleId);

    expect(find.text('Aya Kone'), findsOneWidget);
    expect(find.text('À traiter'), findsOneWidget);

    await tester.tap(find.text('Aya Kone'));
    await tester.pumpAndSettle();

    expect(find.textContaining('lecture seule'), findsOneWidget);
    expect(find.textContaining('Rien enregistré'), findsOneWidget);
    // Aucun contrôle de saisie — toutes les actions ont déménagé sur
    // l'écran Cotisation.
    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.text('Absent'), findsNothing);
    expect(find.text('Demander un crédit aujourd\'hui'), findsNothing);
  });

  testWidgets('récap : cotisation enregistrée aujourd\'hui, visible en lecture seule',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparer(db);
    await db.enregistrerEncaissementMembre(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsParCarnet: {1: 2},
      recordedByPhone: '+2250000099',
      date: debutCycle,
    );

    await pump(tester, db, groupId: ctx.groupId, cycleId: ctx.cycleId);
    expect(find.text('Réglé aujourd\'hui'), findsOneWidget);

    await tester.tap(find.text('Aya Kone'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 part(s)'), findsOneWidget);
  });

  testWidgets('récap : présence anticipée visible, marquée "à confirmer à la clôture"',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparer(db);
    await db.marquerPresenceAnticipee(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      date: debutCycle,
      codeSysteme: AppDatabase.codeSystemeAbsence,
      agentPhone: '+2250000099',
    );

    await pump(tester, db, groupId: ctx.groupId, cycleId: ctx.cycleId);
    expect(find.textContaining('Absent'), findsOneWidget);

    await tester.tap(find.text('Aya Kone'));
    await tester.pumpAndSettle();

    expect(find.textContaining('anticipé'), findsOneWidget);
  });
}

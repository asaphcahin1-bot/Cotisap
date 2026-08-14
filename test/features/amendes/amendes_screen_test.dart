import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/amendes/amendes_screen.dart';
import 'package:cotisapp/state/providers.dart';

/// Écran "Amendes" dédié — voir DECISIONS.md, "Section Amendes dédiée".
void main() {
  Future<({String groupId, String cycleId, String membreId})> preparer(
    AppDatabase db,
  ) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
    );
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  testWidgets(
      'filtre en attente/réglées/annulées, paie une amende en attente',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparer(db);

    final amendeEnAttenteId = await db.enregistrerAmende(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      montantFcfa: 500,
      motif: 'Bavardage',
      recordedByPhone: '+2250000099',
    );
    final amendeRegleeId = await db.enregistrerAmende(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      montantFcfa: 300,
      motif: 'Retard',
      recordedByPhone: '+2250000099',
    );
    await db.confirmerAmende(amendeRegleeId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
        ],
        child: MaterialApp(
          home: AmendesScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Filtre par défaut : en attente — seule "Bavardage" est visible.
    expect(find.textContaining('Bavardage'), findsOneWidget);
    expect(find.textContaining('Retard'), findsNothing);

    await tester.tap(find.text('Réglées'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Retard'), findsOneWidget);
    expect(find.textContaining('Bavardage'), findsNothing);

    await tester.tap(find.text('Toutes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bavardage'), findsOneWidget);
    expect(find.textContaining('Retard'), findsOneWidget);

    await tester.tap(find.text('En attente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(await db.soldeRestantAmendeFcfa(amendeEnAttenteId), 0);
    expect(find.textContaining('Bavardage'), findsNothing);
  });

  testWidgets('propose "Erreur" seulement pour une amende auto-générée', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ctx = await preparer(db);

    await db.enregistrerAmende(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      montantFcfa: 100,
      motif: 'Absence',
      motifCodeSysteme: AppDatabase.codeSystemeAbsence,
      recordedByPhone: '+2250000099',
      estAutoGeneree: true,
    );
    await db.enregistrerAmende(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      montantFcfa: 200,
      motif: 'Bavardage',
      recordedByPhone: '+2250000099',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
        ],
        child: MaterialApp(
          home: AmendesScreen(groupId: ctx.groupId, cycleId: ctx.cycleId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Erreur'), findsOneWidget);
    expect(find.text('Payer'), findsNWidgets(2));
  });
}

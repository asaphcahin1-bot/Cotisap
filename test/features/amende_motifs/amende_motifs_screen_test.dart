import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/amende_motifs/amende_motifs_screen.dart';
import 'package:cotisapp/state/providers.dart';

void main() {
  testWidgets('créer un motif, le voir dans la liste, puis le désactiver', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: AmendeMotifsScreen(groupId: groupId)),
      ),
    );
    await tester.pumpAndSettle();

    // Un groupe naît déjà avec les 3 motifs système (voir DECISIONS.md,
    // "Motifs d'amende prédéfinis") — jamais la liste vide.
    expect(find.textContaining('Aucun motif configuré'), findsNothing);
    expect(find.text('Absence'), findsOneWidget);
    expect(find.text('Part impayée'), findsOneWidget);
    expect(find.text('Payé par un tiers'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Libellé (ex : Bavardage)'),
      'Bavardage',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montant (FCFA)'),
      '200',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Bavardage'), findsOneWidget);
    expect(find.textContaining('200 FCFA'), findsOneWidget);

    // Désactive le motif "Bavardage" via l'interrupteur de sa ligne —
    // les 3 motifs système en ont aussi un, viser celui de sa ListTile.
    final bavardageTile = find.ancestor(
      of: find.text('Bavardage'),
      matching: find.byType(ListTile),
    );
    await tester.tap(find.descendant(of: bavardageTile, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    expect(find.textContaining('désactivé'), findsOneWidget);
    final motifs = await db.motifsAmendeDuGroupe(groupId);
    expect(motifs.singleWhere((m) => m.libelle == 'Bavardage').actif, isFalse);
  });
}

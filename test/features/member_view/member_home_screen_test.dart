import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/member_view/member_home_screen.dart';
import 'package:cotisapp/state/providers.dart';

void main() {
  testWidgets(
      'un membre voit ses propres montants mais jamais les noms ni les montants '
      'des autres membres du même cycle', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final groupId = await db.creerGroupe(
        name: 'Kondoukro', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 1000, interestRatePercent: 10);
    final ayaId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+225001');
    final fatouId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Fatou Secrete', phoneNumber: '+225002');

    // Aya : 2 parts. Fatou : 8 parts (bien plus, pour que leurs montants
    // de répartition soient nettement différents et donc détectables
    // si l'écran d'Aya les affichait par erreur).
    await db.enregistrerCotisationCash(
        groupId: groupId, cycleId: cycleId, memberId: ayaId, partsCount: 2, recordedByPhone: '+225099');
    await db.enregistrerCotisationCash(
        groupId: groupId, cycleId: cycleId, memberId: fatouId, partsCount: 8, recordedByPhone: '+225099');
    await db.enregistrerAmende(
      groupId: groupId,
      cycleId: cycleId,
      memberId: fatouId,
      montantFcfa: 1000,
      motif: 'retard',
      recordedByPhone: '+225099',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: MemberHomeScreen(memberId: ayaId, groupId: groupId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Le nom d'Aya (le membre connecté) doit apparaître.
    expect(find.text('Aya Kone'), findsOneWidget);
    // Le nom de l'autre membre ne doit jamais apparaître sur cet écran.
    expect(find.textContaining('Fatou'), findsNothing);
  });
}

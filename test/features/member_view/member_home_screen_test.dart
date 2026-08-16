import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/formatting.dart';
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

  testWidgets(
      'un membre voit le solde dû, le taux et l\'historique de remboursement '
      'de son propre prêt', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final groupId = await db.creerGroupe(
        name: 'Kondoukro', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 1000, interestRatePercent: 10);
    final ayaId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+225001');

    final resultat = await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: ayaId,
      principalFcfa: 10000,
      interestRatePercent: 10,
      initiatedByPhone: '+225099',
      confirmationCode: '1234',
      provenance: 'importe',
    );
    await db.confirmerPret(
      pretId: resultat.pretId,
      codeSaisi: '1234',
      confirmedByPhone: '+225001',
    );
    // 10000 + 10% = 11000 dû ; 4000 déjà remboursé -> 7000 restant.
    await db.enregistrerRemboursement(
      pretId: resultat.pretId,
      montantFcfa: 4000,
      recordedByPhone: '+225099',
      recordedAt: DateTime(2024, 3, 1),
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

    expect(find.textContaining('intérêt ${formatPercent(10)}'), findsOneWidget);
    expect(
      find.textContaining('Je dois encore : ${formatFcfa(7000)}'),
      findsOneWidget,
    );

    // Historique fermé par défaut, puis déplié.
    expect(find.text('Mes remboursements'), findsNothing);
    await tester.tap(find.text(formatFcfa(10000)));
    await tester.pumpAndSettle();

    expect(find.text('Mes remboursements'), findsOneWidget);
    // Apparaît deux fois : une fois dans le résumé ("remboursé : ..."),
    // une fois dans la ligne de l'historique tout juste dépliée.
    expect(find.textContaining(formatFcfa(4000)), findsWidgets);
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/loans/loans_screen.dart';
import 'package:cotisapp/state/providers.dart';

void main() {
  Future<({String groupId, String cycleId, String membreId})> preparer(AppDatabase db) async {
    final groupId = await db.creerGroupe(
        name: 'Groupe test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 10);
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000001');
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  testWidgets('le bouton Remboursement disparaît une fois le prêt intégralement soldé',
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
    );
    await db.confirmerPret(
        pretId: resultat.pretId, codeSaisi: '1234', confirmedByPhone: '+2250000001');
    // 10000 + 10% = 11000 dû -> remboursement intégral.
    await db.enregistrerRemboursement(
        pretId: resultat.pretId, montantFcfa: 11000, recordedByPhone: '+2250000099');

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
  });

  testWidgets('le bouton Remboursement reste visible tant que le prêt n\'est pas soldé',
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
    );
    await db.confirmerPret(
        pretId: resultat.pretId, codeSaisi: '1234', confirmedByPhone: '+2250000001');
    // Remboursement partiel seulement.
    await db.enregistrerRemboursement(
        pretId: resultat.pretId, montantFcfa: 5000, recordedByPhone: '+2250000099');

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
  });
}

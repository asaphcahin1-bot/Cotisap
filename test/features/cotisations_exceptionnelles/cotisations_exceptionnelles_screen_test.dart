import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/core/formatting.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/cotisations_exceptionnelles/cotisations_exceptionnelles_screen.dart';
import 'package:cotisapp/state/providers.dart';

/// Écran "Cotisations exceptionnelles" — voir DECISIONS.md, "Cotisations
/// exceptionnelles".
void main() {
  final maintenant = DateTime(2024, 1, 4);

  setUp(() => AppClock.definir(maintenant));
  tearDown(() => AppClock.definir(null));

  testWidgets(
      'déclare un événement, appliqué aux membres déjà présents, avec suivi de la collecte',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 5,
    );
    await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
      joinedAt: maintenant,
    );
    await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Seydou Traore',
      phoneNumber: '+2250000002',
      joinedAt: maintenant,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: maintenant,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
        ],
        child: MaterialApp(
          home: CotisationsExceptionnellesScreen(
            groupId: groupId,
            cycleId: cycleId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune cotisation exceptionnelle déclarée.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Déclarer un événement'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Événement (ex. "Mariage de Awa Koné")'),
      'Mariage de Awa',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montant par membre (FCFA)'),
      '1000',
    );
    await tester.tap(find.text('Déclarer'));
    await tester.pumpAndSettle();

    expect(find.text('Mariage de Awa'), findsOneWidget);
    expect(find.textContaining('2 membre(s) concerné(s)'), findsOneWidget);
    expect(find.textContaining('Collecté : 0 FCFA /'), findsOneWidget);

    final evts = await db.cotisationsExceptionnellesDuCycle(cycleId);
    expect(evts, hasLength(1));
    expect(evts.single.montantFcfa, 1000);
  });

  testWidgets(
      'une fois la date limite dépassée, affiche le détail par membre '
      '(payé / déduit automatiquement)', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 5,
    );
    final ayaId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
      joinedAt: maintenant,
    );
    await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Seydou Traore',
      phoneNumber: '+2250000002',
      joinedAt: maintenant,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: maintenant,
    );
    final evtId = await db.enregistrerCotisationExceptionnelle(
      groupId: groupId,
      cycleId: cycleId,
      motif: 'Décès du père de Seydou',
      montantFcfa: 1000,
      dateLimite: DateTime(2024, 1, 9),
      createdByPhone: '+2250000099',
    );
    // Aya paie avant la date limite ; Seydou ne paie jamais.
    await db.enregistrerContributionFondsSolidarite(
      groupId: groupId,
      cycleId: cycleId,
      memberId: ayaId,
      montantFcfa: 1000,
      motif: 'Décès du père de Seydou',
      recordedByPhone: '+2250000099',
      cotisationExceptionnelleId: evtId,
    );

    // La date limite est maintenant dépassée.
    AppClock.definir(DateTime(2024, 1, 10));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
        ],
        child: MaterialApp(
          home: CotisationsExceptionnellesScreen(
            groupId: groupId,
            cycleId: cycleId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('(dépassée)'), findsOneWidget);

    await tester.tap(find.text('Décès du père de Seydou'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('a expiré le 9/1/2024'),
      findsOneWidget,
      reason: 'message explicite d\'expiration, demandé par le fondateur',
    );
    expect(find.widgetWithText(ListTile, 'Aya Kone'), findsOneWidget);
    expect(find.textContaining('Payé — ${formatFcfa(1000)}'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Seydou Traore'), findsOneWidget);
    expect(
      find.textContaining('Déduit automatiquement — ${formatFcfa(1000)}'),
      findsOneWidget,
    );
  });
}

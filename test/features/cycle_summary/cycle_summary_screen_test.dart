import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/data/auth/auth_gateway.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/features/cycle_summary/cycle_summary_screen.dart';
import 'package:cotisapp/state/providers.dart';

/// Écran de répartition de fin de cycle — formule "caisse disponible"
/// (voir DECISIONS.md, "Nouvelle formule de partage" et "Les amendes ne
/// sont plus une dette"). Vérifie que l'écran affiche correctement les
/// deux cas : un membre sans dette de prêt (part du bénéfice collectif,
/// même avec une amende non soldée — elle réduit ses parts reconnues
/// mais ne le prive jamais du bénéfice) et un membre avec une dette de
/// prêt (plafonné à sa cotisation, aucun bénéfice).
void main() {
  testWidgets(
    'affiche la caisse disponible, et distingue un membre sans dette d\'un membre endetté',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final groupId = await db.creerGroupe(
        name: 'Groupe test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 10,
      );
      final ayaId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
      );
      final seydouId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Seydou Traore',
        phoneNumber: '+2250000002',
      );
      final modibId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Modibo Sanogo',
        phoneNumber: '+2250000003',
      );

      // Aya : 5 parts, aucune amende, aucune dette -> profite pleinement
      // du bénéfice collectif.
      await db.enregistrerCotisationCash(
        groupId: groupId,
        cycleId: cycleId,
        memberId: ayaId,
        partsCount: 5,
        recordedByPhone: '+2250000099',
      );
      // Seydou : 5 parts, une amende non soldée -> une amende n'est plus
      // une dette (voir DECISIONS.md) : elle réduit seulement ses parts
      // reconnues (4, plus un résidu), il profite quand même du bénéfice
      // collectif sur ces 4 parts.
      await db.enregistrerCotisationCash(
        groupId: groupId,
        cycleId: cycleId,
        memberId: seydouId,
        partsCount: 5,
        recordedByPhone: '+2250000099',
      );
      await db.enregistrerAmende(
        groupId: groupId,
        cycleId: cycleId,
        memberId: seydouId,
        montantFcfa: 500,
        motif: 'Retard',
        recordedByPhone: '+2250000099',
      );
      // Modibo : 2 parts, un prêt non remboursé -> seule une dette de
      // prêt confirmée bloque encore le bénéfice collectif.
      await db.enregistrerCotisationCash(
        groupId: groupId,
        cycleId: cycleId,
        memberId: modibId,
        partsCount: 2,
        recordedByPhone: '+2250000099',
      );
      final pret = await db.enregistrerPret(
        groupId: groupId,
        cycleId: cycleId,
        memberId: modibId,
        principalFcfa: 3000,
        interestRatePercent: 10,
        initiatedByPhone: '+2250000099',
        confirmationCode: '1234',
        provenance: 'importe',
      );
      await db.confirmerPret(
        pretId: pret.pretId,
        codeSaisi: '1234',
        confirmedByPhone: '+2250000003',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: CycleSummaryScreen(groupId: groupId, cycleId: cycleId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Carte "caisse disponible" visible pour un cycle en cours.
      expect(find.textContaining('Caisse disponible'), findsOneWidget);
      expect(find.textContaining('Valeur par part'), findsOneWidget);

      // Aya ET Seydou (malgré son amende non soldée) profitent du
      // bénéfice collectif.
      expect(
        find.textContaining('part du bénéfice collectif'),
        findsNWidgets(2),
      );
      // Seydou n'apparaît qu'avec 4 parts reconnues (5 - 1 pour son
      // amende de 500 F), pas 5.
      expect(find.textContaining('4 part(s)'), findsOneWidget);
      // Modibo, endetté par son prêt, n'en profite pas.
      expect(
        find.textContaining('aucun bénéfice (dette en cours)'),
        findsOneWidget,
      );

      // Le détail de la dette de Modibo est affiché (prêt non remboursé).
      expect(find.textContaining('Dette totale'), findsOneWidget);
    },
  );

  testWidgets(
    'un cycle déjà clos relit les montants figés, sans caisse/valeur par part',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final groupId = await db.creerGroupe(
        name: 'Groupe test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 10,
      );
      final ayaId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
      );
      await db.enregistrerCotisationCash(
        groupId: groupId,
        cycleId: cycleId,
        memberId: ayaId,
        partsCount: 5,
        recordedByPhone: '+2250000099',
      );
      // Condition de clôture (voir DECISIONS.md, "Clôture de cycle
      // conditionnée au paiement de tous les membres").
      await db.confirmerPaiementMembre(
        groupId: groupId,
        cycleId: cycleId,
        memberId: ayaId,
        confirmedByPhone: '+2250000099',
      );

      await db.cloturerCycleEtOuvrirSuivant(
        groupId: groupId,
        cycleIdACloturer: cycleId,
        nouveauPartValueFcfa: 1000,
        nouveauInterestRatePercent: 10,
        recordedByPhone: '+2250000099',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: CycleSummaryScreen(groupId: groupId, cycleId: cycleId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pas de recalcul de la caisse/valeur par part pour un cycle clos
      // (voir DECISIONS.md) — seul le résultat déjà réparti par membre.
      expect(find.textContaining('Caisse disponible'), findsNothing);
      expect(find.text('Aya Kone'), findsOneWidget);
      expect(find.textContaining('Cycle clôturé'), findsOneWidget);
    },
  );

  testWidgets(
    'choisir un motif du catalogue pré-remplit le montant, et enregistre l\'amende',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final groupId = await db.creerGroupe(
        name: 'Groupe test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 10,
      );
      final ayaId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
      );
      await db.enregistrerCotisationCash(
        groupId: groupId,
        cycleId: cycleId,
        memberId: ayaId,
        partsCount: 5,
        recordedByPhone: '+2250000099',
      );
      await db.creerMotifAmende(
        groupId: groupId,
        libelle: 'Bavardage',
        montantFcfa: 200,
      );

      // Fenêtre agrandie : la carte des dates de début/fin de cycle
      // pousse le bouton "Ajouter une amende" plus bas (voir
      // RETOURS_TERRAIN.md, point 25.6).
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: CycleSummaryScreen(groupId: groupId, cycleId: cycleId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajouter une amende'));
      await tester.pumpAndSettle();

      // Membre.
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Membre'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aya Kone').last);
      await tester.pumpAndSettle();

      // Motif du catalogue -> pré-remplit le montant.
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Motif'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Bavardage').last);
      await tester.pumpAndSettle();

      final montantField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Montant (FCFA)'),
      );
      expect(montantField.controller!.text, '200');

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Le mode de paiement est demandé immédiatement (voir DECISIONS.md,
      // "Mode de paiement de l'amende demandé immédiatement").
      expect(find.text('Mode de paiement de l\'amende'), findsOneWidget);
      await tester.tap(find.text('Pas maintenant'));
      await tester.pumpAndSettle();

      final amendes = await db.amendesDuMembre(ayaId, cycleId);
      expect(amendes, hasLength(1));
      expect(amendes.single.motif, 'Bavardage');
      expect(amendes.single.montantFcfa, 200);
      expect(
        await db.montantAmendesNonSoldeesFcfa(
          memberId: ayaId,
          cycleId: cycleId,
        ),
        200, // pas encore réglée — reste payable en cash à tout moment.
      );
    },
  );

  testWidgets(
    '"Clôturer ce cycle" reste désactivé tant que tous les membres ne sont pas cochés "payé"',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final groupId = await db.creerGroupe(
        name: 'Groupe test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 10,
      );
      final ayaId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
      );
      final seydouId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Seydou Traore',
        phoneNumber: '+2250000002',
      );
      for (final membreId in [ayaId, seydouId]) {
        await db.enregistrerCotisationCash(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          partsCount: 2,
          recordedByPhone: '+2250000099',
        );
      }

      // Fenêtre agrandie : les totaux amendes/intérêts ajoutés en tête de
      // liste poussent le reste hors du viewport de test par défaut (voir
      // la note "ListView lazy-building" dans les gotchas établis).
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
            home: CycleSummaryScreen(groupId: groupId, cycleId: cycleId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aucun membre confirmé -> bouton désactivé, avertissement affiché.
      expect(
        find.textContaining('membre(s) pas encore confirmé'),
        findsOneWidget,
      );
      var closeButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Clôturer ce cycle'),
      );
      expect(closeButton.onPressed, isNull);

      // Confirmer un seul des deux membres.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('membre(s) pas encore confirmé'),
        findsOneWidget,
      );
      closeButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Clôturer ce cycle'),
      );
      expect(closeButton.onPressed, isNull);

      // Confirmer le second -> bouton activé, plus d'avertissement.
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('membre(s) pas encore confirmé'),
        findsNothing,
      );
      closeButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Clôturer ce cycle'),
      );
      expect(closeButton.onPressed, isNotNull);

      expect(
        await db.membresConfirmesPayesDuCycle(cycleId),
        {ayaId, seydouId},
      );
    },
  );

  group(
    'Reconduction d\'un prêt non soldé au cycle suivant (voir DECISIONS.md, "Dette de prêt au rouge")',
    () {
      testWidgets(
        'propose la reconduction à la clôture, jamais automatique, exige la confirmation du prêt successeur',
        (tester) async {
          final db = AppDatabase(NativeDatabase.memory());
          addTearDown(db.close);

          final groupId = await db.creerGroupe(
            name: 'Groupe test',
            cycleDurationMonths: 9,
            meetingFrequency: 'mensuelle',
          );
          final cycleId = await db.ouvrirCycle(
            groupId: groupId,
            cycleNumber: 1,
            partValueFcfa: 1000,
            interestRatePercent: 10,
          );
          final modiboId = await db.ajouterMembre(
            groupId: groupId,
            fullName: 'Modibo Sanogo',
            phoneNumber: '+2250000003',
          );
          await db.enregistrerCotisationCash(
            groupId: groupId,
            cycleId: cycleId,
            memberId: modiboId,
            partsCount: 2,
            recordedByPhone: '+2250000099',
          );
          final pret = await db.enregistrerPret(
            groupId: groupId,
            cycleId: cycleId,
            memberId: modiboId,
            principalFcfa: 3000,
            interestRatePercent: 10,
            initiatedByPhone: '+2250000099',
            provenance: 'importe', // confirmé automatiquement, jamais soldé
          );
          await db.confirmerPaiementMembre(
            groupId: groupId,
            cycleId: cycleId,
            memberId: modiboId,
            confirmedByPhone: '+2250000099',
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                currentPhoneNumberProvider.overrideWith(
                  (ref) => '+2250000099',
                ),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CycleSummaryScreen(
                            groupId: groupId,
                            cycleId: cycleId,
                          ),
                        ),
                      ),
                      child: const Text('Ouvrir'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ouvrir'));
          await tester.pumpAndSettle();

          // Le bouton est en bas d'une ListView, hors du viewport de
          // test par défaut — même bug de construction paresseuse déjà
          // rencontré ailleurs dans ce projet (voir DECISIONS.md/session) :
          // il faut le faire défiler dans la vue avant de taper dessus.
          await tester.ensureVisible(
            find.text('Clôturer ce cycle', skipOffstage: false),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Clôturer ce cycle'));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('prêt(s) pas encore totalement remboursé'),
            findsOneWidget,
          );
          await tester.tap(
            find.text('Clôturer et ouvrir le cycle suivant'),
          );
          await tester.pumpAndSettle();

          // Proposition de reconduction — jamais automatique.
          expect(find.text('Prêt non soldé'), findsOneWidget);
          await tester.tap(find.text('Oui, le membre est d\'accord'));
          await tester.pumpAndSettle();

          // Le prêt successeur exige sa propre confirmation, comme tout
          // nouveau prêt (Modibo a un téléphone -> code SMS).
          expect(find.text('Confirmation du prêt'), findsOneWidget);
          await tester.enterText(
            find.byType(TextFormField),
            DevAuthGateway.codeDeTest,
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
          await tester.pumpAndSettle();

          // Le successeur est un nouveau prêt qui pointe VERS l'ancien
          // via renouvelePretId — pas l'inverse (l'ancien n'est jamais
          // modifié, voir DECISIONS.md, "Dette de prêt au rouge").
          final tousLesPrets = await (db.select(db.prets)).get();
          expect(tousLesPrets, hasLength(2));
          final nouveauPret = tousLesPrets.firstWhere(
            (p) => p.id != pret.pretId,
          );
          expect(nouveauPret.renouvelePretId, pret.pretId);
          expect(nouveauPret.cycleId, isNot(cycleId));
          expect(nouveauPret.provenance, 'renouvellement');
          expect(nouveauPret.estAuRougeDesLeDepart, isTrue);
          expect(await db.pretEstConfirme(nouveauPret.id), isTrue);
        },
      );

      testWidgets('refuser la reconduction ne modifie rien', (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final groupId = await db.creerGroupe(
          name: 'Groupe test',
          cycleDurationMonths: 9,
          meetingFrequency: 'mensuelle',
        );
        final cycleId = await db.ouvrirCycle(
          groupId: groupId,
          cycleNumber: 1,
          partValueFcfa: 1000,
          interestRatePercent: 10,
        );
        final modiboId = await db.ajouterMembre(
          groupId: groupId,
          fullName: 'Modibo Sanogo',
          phoneNumber: '+2250000003',
        );
        await db.enregistrerCotisationCash(
          groupId: groupId,
          cycleId: cycleId,
          memberId: modiboId,
          partsCount: 2,
          recordedByPhone: '+2250000099',
        );
        final pret = await db.enregistrerPret(
          groupId: groupId,
          cycleId: cycleId,
          memberId: modiboId,
          principalFcfa: 3000,
          interestRatePercent: 10,
          initiatedByPhone: '+2250000099',
          provenance: 'importe',
        );
        await db.confirmerPaiementMembre(
          groupId: groupId,
          cycleId: cycleId,
          memberId: modiboId,
          confirmedByPhone: '+2250000099',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              currentPhoneNumberProvider.overrideWith((ref) => '+2250000099'),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CycleSummaryScreen(
                          groupId: groupId,
                          cycleId: cycleId,
                        ),
                      ),
                    ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.text('Clôturer ce cycle', skipOffstage: false),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clôturer ce cycle'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Clôturer et ouvrir le cycle suivant'));
        await tester.pumpAndSettle();

        expect(find.text('Prêt non soldé'), findsOneWidget);
        await tester.tap(find.text('Non — laisser tel quel'));
        await tester.pumpAndSettle();

        final ancienPret = await (db.select(db.prets)
              ..where((p) => p.id.equals(pret.pretId)))
            .getSingle();
        expect(ancienPret.renouvelePretId, isNull);
        final tousLesPrets = await (db.select(db.prets)).get();
        expect(tousLesPrets, hasLength(1));
      });
    },
  );
}

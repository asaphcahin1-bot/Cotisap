import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Motifs d'amende prédéfinis + validation de cohérence par carnet —
/// voir DECISIONS.md, "Motifs d'amende prédéfinis" et "Validation de
/// cohérence des motifs par carnet".
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'creerGroupe crée automatiquement les 3 motifs système avec libellés explicatifs',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
        montantAmendeAbsenceFcfa: 500,
        montantAmendePartImpayeeFcfa: 300,
        montantAmendePayeParTiersFcfa: 100,
      );

      final motifs = await db.motifsAmendeDuGroupe(groupId);
      expect(motifs, hasLength(3));

      final absence = motifs.singleWhere(
        (m) => m.codeSysteme == AppDatabase.codeSystemeAbsence,
      );
      expect(absence.libelle, 'Absence');
      expect(absence.montantFcfa, 500);
      expect(absence.description, 'Le membre n\'est pas présent à la réunion.');

      final partImpayee = motifs.singleWhere(
        (m) => m.codeSysteme == AppDatabase.codeSystemePartImpayee,
      );
      expect(partImpayee.libelle, 'Part impayée');
      expect(partImpayee.montantFcfa, 300);

      final payeParTiers = motifs.singleWhere(
        (m) => m.codeSysteme == AppDatabase.codeSystemePayeParTiers,
      );
      expect(payeParTiers.libelle, 'Payé par un tiers');
      expect(payeParTiers.montantFcfa, 100);
    },
  );

  test('les montants des motifs système valent 0 par défaut si non précisés', () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );
    final motifs = await db.motifsAmendeDuGroupe(groupId);
    expect(motifs.every((m) => m.montantFcfa == 0), isTrue);
  });

  test(
    'un motif personnalisé du groupe (codeSysteme null) n\'a pas de description obligatoire',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      await db.creerMotifAmende(
        groupId: groupId,
        libelle: 'Bavardage',
        montantFcfa: 100,
      );
      final motifs = await db.motifsAmendeDuGroupe(groupId);
      final bavardage = motifs.singleWhere((m) => m.libelle == 'Bavardage');
      expect(bavardage.codeSysteme, isNull);
    },
  );

  group('motifsSystemeApplicables', () {
    late String groupId;
    late String membreId;
    late String cycleId;
    final echeance = DateTime(2024, 1, 4);

    setUp(() async {
      groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'hebdomadaire',
        paymentDayOfWeek: DateTime.thursday,
      );
      membreId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
      );
      cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 8,
      );
    });

    test('rien n\'est enregistré : les 3 motifs système restent possibles', () async {
      final applicables = await db.motifsSystemeApplicables(
        memberId: membreId,
        cycleId: cycleId,
        carnetNumero: 1,
        echeanceDate: echeance,
      );
      expect(applicables, {
        AppDatabase.codeSystemeAbsence,
        AppDatabase.codeSystemePartImpayee,
        AppDatabase.codeSystemePayeParTiers,
      });
    });

    test(
      'une cotisation déjà enregistrée pour ce carnet : plus aucun motif système applicable',
      () async {
        await db.enregistrerCotisationCash(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          carnetNumero: 1,
          partsCount: 1,
          recordedByPhone: '+2250000099',
          echeanceDate: echeance,
        );

        final applicables = await db.motifsSystemeApplicables(
          memberId: membreId,
          cycleId: cycleId,
          carnetNumero: 1,
          echeanceDate: echeance,
        );
        expect(applicables, isEmpty);
      },
    );

    test(
      '"payé par un tiers" déjà appliqué pour ce carnet : plus aucun motif système applicable',
      () async {
        await db.enregistrerAmende(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          carnetNumero: 1,
          echeanceDate: echeance,
          montantFcfa: 100,
          motif: 'Payé par un tiers',
          motifCodeSysteme: AppDatabase.codeSystemePayeParTiers,
          recordedByPhone: '+2250000099',
        );

        final applicables = await db.motifsSystemeApplicables(
          memberId: membreId,
          cycleId: cycleId,
          carnetNumero: 1,
          echeanceDate: echeance,
        );
        expect(applicables, isEmpty);
      },
    );

    test(
      'la restriction est propre au carnet concerné, jamais au membre entier',
      () async {
        await db.enregistrerCotisationCash(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          carnetNumero: 1,
          partsCount: 1,
          recordedByPhone: '+2250000099',
          echeanceDate: echeance,
        );

        // Carnet 1 : réglé, plus rien d'applicable.
        expect(
          await db.motifsSystemeApplicables(
            memberId: membreId,
            cycleId: cycleId,
            carnetNumero: 1,
            echeanceDate: echeance,
          ),
          isEmpty,
        );
        // Carnet 2 : rien n'y a encore été enregistré, les 3 restent possibles.
        expect(
          await db.motifsSystemeApplicables(
            memberId: membreId,
            cycleId: cycleId,
            carnetNumero: 2,
            echeanceDate: echeance,
          ),
          {
            AppDatabase.codeSystemeAbsence,
            AppDatabase.codeSystemePartImpayee,
            AppDatabase.codeSystemePayeParTiers,
          },
        );
      },
    );

    test(
      'une amende annulée (erreur) ne bloque plus les motifs système',
      () async {
        final amendeId = await db.enregistrerAmende(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          carnetNumero: 1,
          echeanceDate: echeance,
          montantFcfa: 100,
          motif: 'Payé par un tiers',
          motifCodeSysteme: AppDatabase.codeSystemePayeParTiers,
          recordedByPhone: '+2250000099',
        );
        await db.annulerAmende(
          amendeId: amendeId,
          raison: 'Erreur de saisie',
          annuleParPhone: '+2250000099',
        );

        final applicables = await db.motifsSystemeApplicables(
          memberId: membreId,
          cycleId: cycleId,
          carnetNumero: 1,
          echeanceDate: echeance,
        );
        expect(applicables, isNotEmpty);
      },
    );
  });
}

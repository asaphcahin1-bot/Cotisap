import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Condition de clôture : tous les membres ayant des parts sur le cycle
/// doivent avoir été confirmés comme payés — voir DECISIONS.md, "Clôture
/// de cycle conditionnée au paiement de tous les membres".
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'refuse de clôturer tant qu\'un membre n\'est pas confirmé payé',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final membre1 = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
      );
      final membre2 = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Seydou Traore',
        phoneNumber: '+2250000002',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 0,
      );
      for (final membreId in [membre1, membre2]) {
        await db.enregistrerCotisationCash(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          partsCount: 1,
          recordedByPhone: '+2250000099',
        );
      }

      // Aucun membre confirmé -> refuse.
      expect(
        () => db.cloturerCycleEtOuvrirSuivant(
          groupId: groupId,
          cycleIdACloturer: cycleId,
          nouveauPartValueFcfa: 1000,
          nouveauInterestRatePercent: 0,
        ),
        throwsStateError,
      );

      // Un seul des deux confirmé -> refuse toujours.
      await db.confirmerPaiementMembre(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membre1,
        confirmedByPhone: '+2250000099',
      );
      expect(
        () => db.cloturerCycleEtOuvrirSuivant(
          groupId: groupId,
          cycleIdACloturer: cycleId,
          nouveauPartValueFcfa: 1000,
          nouveauInterestRatePercent: 0,
        ),
        throwsStateError,
      );

      // Les deux confirmés -> la clôture réussit.
      await db.confirmerPaiementMembre(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membre2,
        confirmedByPhone: '+2250000099',
      );
      final cycleSuivantId = await db.cloturerCycleEtOuvrirSuivant(
        groupId: groupId,
        cycleIdACloturer: cycleId,
        nouveauPartValueFcfa: 1000,
        nouveauInterestRatePercent: 0,
      );
      final cycle = await (db.select(
        db.cycles,
      )..where((c) => c.id.equals(cycleId))).getSingle();
      expect(cycle.status, 'cloture');
      expect(cycleSuivantId, isNotEmpty);
    },
  );

  test(
    'un cycle sans aucun membre à répartir se clôture sans confirmation requise',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 1000,
        interestRatePercent: 0,
      );

      await db.cloturerCycleEtOuvrirSuivant(
        groupId: groupId,
        cycleIdACloturer: cycleId,
        nouveauPartValueFcfa: 1000,
        nouveauInterestRatePercent: 0,
      );

      final cycle = await (db.select(
        db.cycles,
      )..where((c) => c.id.equals(cycleId))).getSingle();
      expect(cycle.status, 'cloture');
    },
  );

  test(
    'annulerConfirmationPaiementMembre décoche une confirmation posée par erreur',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
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
        partValueFcfa: 1000,
        interestRatePercent: 0,
      );

      await db.confirmerPaiementMembre(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membreId,
        confirmedByPhone: '+2250000099',
      );
      expect(await db.membresConfirmesPayesDuCycle(cycleId), {membreId});

      await db.annulerConfirmationPaiementMembre(
        cycleId: cycleId,
        memberId: membreId,
      );
      expect(await db.membresConfirmesPayesDuCycle(cycleId), isEmpty);
    },
  );

  test(
    'confirmerPaiementMembre est idempotent (pas de doublon)',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
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
        partValueFcfa: 1000,
        interestRatePercent: 0,
      );

      for (var i = 0; i < 3; i++) {
        await db.confirmerPaiementMembre(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          confirmedByPhone: '+2250000099',
        );
      }
      expect(await db.membresConfirmesPayesDuCycle(cycleId), {membreId});
    },
  );
}

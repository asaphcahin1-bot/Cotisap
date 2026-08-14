import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Paiement partiel d'une amende — voir DECISIONS.md, "Paiement
/// partiel d'une amende". Un membre peut s'acquitter d'une amende en
/// plusieurs fois, à tout moment.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<({String groupId, String cycleId, String membreId, String amendeId})>
  preparerAvecAmende({int montantFcfa = 500}) async {
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
      partValueFcfa: 500,
      interestRatePercent: 8,
    );
    final amendeId = await db.enregistrerAmende(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      montantFcfa: montantFcfa,
      motif: 'Test',
      recordedByPhone: '+2250000099',
    );
    return (
      groupId: groupId,
      cycleId: cycleId,
      membreId: membreId,
      amendeId: amendeId,
    );
  }

  test('une amende neuve a un solde restant égal à son montant', () async {
    final ctx = await preparerAvecAmende(montantFcfa: 500);
    expect(await db.soldeRestantAmendeFcfa(ctx.amendeId), 500);
  });

  test('un paiement partiel réduit le solde restant sans solder l\'amende', () async {
    final ctx = await preparerAvecAmende(montantFcfa: 500);
    await db.enregistrerPaiementAmende(
      amendeId: ctx.amendeId,
      montantFcfa: 200,
      recordedByPhone: '+2250000099',
    );

    expect(await db.soldeRestantAmendeFcfa(ctx.amendeId), 300);
    final amende = await (db.select(
      db.amendes,
    )..where((a) => a.id.equals(ctx.amendeId))).getSingle();
    expect(amende.confirmedAt, isNull, reason: 'pas encore intégralement payée');
  });

  test(
    'plusieurs paiements partiels s\'additionnent et soldent l\'amende une fois le total atteint',
    () async {
      final ctx = await preparerAvecAmende(montantFcfa: 500);
      await db.enregistrerPaiementAmende(
        amendeId: ctx.amendeId,
        montantFcfa: 200,
        recordedByPhone: '+2250000099',
      );
      await db.enregistrerPaiementAmende(
        amendeId: ctx.amendeId,
        montantFcfa: 300,
        recordedByPhone: '+2250000099',
      );

      expect(await db.soldeRestantAmendeFcfa(ctx.amendeId), 0);
      final amende = await (db.select(
        db.amendes,
      )..where((a) => a.id.equals(ctx.amendeId))).getSingle();
      expect(amende.confirmedAt, isNotNull);
      expect(
        amende.reviewedAt,
        isNotNull,
        reason: 'payer équivaut à avoir revu, comme confirmerAmende',
      );
    },
  );

  test(
    'montantAmendesNonSoldeesFcfa ne compte que le solde restant, pas le montant brut',
    () async {
      final ctx = await preparerAvecAmende(montantFcfa: 500);
      await db.enregistrerPaiementAmende(
        amendeId: ctx.amendeId,
        montantFcfa: 200,
        recordedByPhone: '+2250000099',
      );

      final montant = await db.montantAmendesNonSoldeesFcfa(
        memberId: ctx.membreId,
        cycleId: ctx.cycleId,
      );
      expect(montant, 300);
    },
  );

  test(
    'une amende intégralement payée en plusieurs fois n\'apparaît plus dans les non soldées',
    () async {
      final ctx = await preparerAvecAmende(montantFcfa: 500);
      await db.enregistrerPaiementAmende(
        amendeId: ctx.amendeId,
        montantFcfa: 500,
        recordedByPhone: '+2250000099',
      );

      final nonSoldees = await db.amendesNonSoldeesDuMembre(
        memberId: ctx.membreId,
        cycleId: ctx.cycleId,
      );
      expect(nonSoldees, isEmpty);
    },
  );

  test('confirmerAmende reste inchangé : règle toujours la totalité en un geste', () async {
    final ctx = await preparerAvecAmende(montantFcfa: 500);
    await db.confirmerAmende(ctx.amendeId);

    final amende = await (db.select(
      db.amendes,
    )..where((a) => a.id.equals(ctx.amendeId))).getSingle();
    expect(amende.confirmedAt, isNotNull);
    // amendesNonSoldeesDuMembre l'exclut déjà via confirmedAt, peu
    // importe l'état du registre de paiements.
    final nonSoldees = await db.amendesNonSoldeesDuMembre(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(nonSoldees, isEmpty);
  });

  test('rejette un paiement de montant nul ou négatif', () async {
    final ctx = await preparerAvecAmende(montantFcfa: 500);
    expect(
      () => db.enregistrerPaiementAmende(
        amendeId: ctx.amendeId,
        montantFcfa: 0,
        recordedByPhone: '+2250000099',
      ),
      throwsArgumentError,
    );
  });
}

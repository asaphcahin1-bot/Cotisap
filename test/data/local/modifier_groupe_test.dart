import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('modifie le groupe et le cycle tant qu\'aucune cotisation n\'existe', () async {
    final groupId = await db.creerGroupe(
      name: 'Ancien nom',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 5,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);

    expect(await db.cycleADesCotisations(cycleId), isFalse);

    await db.modifierGroupeEtCycle(
      groupId: groupId,
      cycleId: cycleId,
      name: 'Nouveau nom',
      cycleDurationMonths: 12,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: 4,
      partValueFcfa: 1000,
      interestRatePercent: 12,
      lateFeeFcfa: 200,
      loanDurationDays: 60,
    );

    final groupe = await (db.select(db.groups)..where((g) => g.id.equals(groupId))).getSingle();
    final cycle = await (db.select(db.cycles)..where((c) => c.id.equals(cycleId))).getSingle();

    expect(groupe.name, 'Nouveau nom');
    expect(groupe.cycleDurationMonths, 12);
    expect(groupe.meetingFrequency, 'hebdomadaire');
    expect(groupe.paymentDayOfWeek, 4);
    expect(groupe.paymentDayOfMonth1, isNull); // remplacé, plus mensuel
    expect(cycle.partValueFcfa, 1000);
    expect(cycle.interestRatePercent, 12);
    expect(cycle.lateFeeFcfa, 200);
    expect(cycle.loanDurationDays, 60);
  });

  test('refuse la modification dès qu\'une cotisation existe sur le cycle', () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle', paymentDayOfMonth1: 5);
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Aya Kone', phoneNumber: '+2250000000');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 500, interestRatePercent: 8);
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsCount: 1,
      recordedByPhone: '+2250000099',
    );

    expect(await db.cycleADesCotisations(cycleId), isTrue);

    expect(
      () => db.modifierGroupeEtCycle(
        groupId: groupId,
        cycleId: cycleId,
        name: 'Nom modifié',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
        paymentDayOfMonth1: 5,
        partValueFcfa: 999,
        interestRatePercent: 8,
        lateFeeFcfa: 0,
        loanDurationDays: 90,
      ),
      throwsStateError,
    );

    // Rien n'a changé.
    final groupe = await (db.select(db.groups)..where((g) => g.id.equals(groupId))).getSingle();
    expect(groupe.name, 'Test');
  });
}

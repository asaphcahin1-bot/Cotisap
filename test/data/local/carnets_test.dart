import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Numéro de série physique persistant par carnet — voir DECISIONS.md,
/// "Numéro de série physique par carnet".
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'definirCarnetsEngages crée automatiquement le numéro de série du carnet engagé',
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
        partValueFcfa: 500,
        interestRatePercent: 8,
      );

      await db.definirCarnetsEngages(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membreId,
      );

      final carnet1 = await db.carnetDuMembre(
        memberId: membreId,
        carnetNumero: 1,
      );
      expect(carnet1, isNotNull);
      expect(carnet1!.numeroSerie, 'C-001');
    },
  );

  test(
    'les numéros de série ne se réinitialisent jamais et s\'incrémentent au niveau du '
    'groupe — un membre = un carnet, donc un membre = un numéro',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final aya = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Aya Kone',
        phoneNumber: '+2250000001',
      );
      final seydou = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Seydou Traore',
        phoneNumber: '+2250000002',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 8,
      );

      await db.definirCarnetsEngages(
        groupId: groupId,
        cycleId: cycleId,
        memberId: aya,
      );
      await db.definirCarnetsEngages(
        groupId: groupId,
        cycleId: cycleId,
        memberId: seydou,
      );

      final ayaCarnet1 = await db.carnetDuMembre(memberId: aya, carnetNumero: 1);
      final seydouCarnet1 = await db.carnetDuMembre(
        memberId: seydou,
        carnetNumero: 1,
      );
      expect(ayaCarnet1!.numeroSerie, 'C-001');
      expect(seydouCarnet1!.numeroSerie, 'C-002');
    },
  );

  test(
    'un carnet réengagé au cycle suivant garde le même numéro de série',
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
      final cycle1Id = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 8,
      );
      await db.definirCarnetsEngages(
        groupId: groupId,
        cycleId: cycle1Id,
        memberId: membreId,
        nombreCarnets: 1,
      );
      final numeroInitial =
          (await db.carnetDuMembre(memberId: membreId, carnetNumero: 1))!
              .numeroSerie;

      final cycle2Id = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 2,
        partValueFcfa: 500,
        interestRatePercent: 8,
      );
      await db.definirCarnetsEngages(
        groupId: groupId,
        cycleId: cycle2Id,
        memberId: membreId,
        nombreCarnets: 1,
      );
      final numeroSuivant =
          (await db.carnetDuMembre(memberId: membreId, carnetNumero: 1))!
              .numeroSerie;

      expect(numeroSuivant, numeroInitial);
    },
  );

  test(
    'genererOuRecupererCarnet accepte un numéro de série manuel (carnet physique déjà numéroté)',
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

      final numero = await db.genererOuRecupererCarnet(
        groupId: groupId,
        memberId: membreId,
        carnetNumero: 1,
        numeroSerieManuel: 'C-099',
      );
      expect(numero, 'C-099');

      // Le prochain auto-généré évite ce numéro déjà pris.
      final autreMembre = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Seydou Traore',
        phoneNumber: '+2250000002',
      );
      final numeroSuivant = await db.genererOuRecupererCarnet(
        groupId: groupId,
        memberId: autreMembre,
        carnetNumero: 1,
      );
      expect(numeroSuivant, 'C-100');
    },
  );

  test('refuse un numéro de série manuel déjà utilisé dans le groupe', () async {
    final groupId = await db.creerGroupe(
      name: 'Test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );
    final aya = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Aya Kone',
      phoneNumber: '+2250000001',
    );
    final seydou = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Seydou Traore',
      phoneNumber: '+2250000002',
    );
    await db.genererOuRecupererCarnet(
      groupId: groupId,
      memberId: aya,
      carnetNumero: 1,
      numeroSerieManuel: 'C-050',
    );

    expect(
      () => db.genererOuRecupererCarnet(
        groupId: groupId,
        memberId: seydou,
        carnetNumero: 1,
        numeroSerieManuel: 'C-050',
      ),
      throwsStateError,
    );
  });

  test('redefinirNumeroSerieCarnet corrige un numéro déjà créé', () async {
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
    await db.genererOuRecupererCarnet(
      groupId: groupId,
      memberId: membreId,
      carnetNumero: 1,
    );

    await db.redefinirNumeroSerieCarnet(
      memberId: membreId,
      carnetNumero: 1,
      nouveauNumeroSerie: 'C-777',
    );

    final carnet = await db.carnetDuMembre(memberId: membreId, carnetNumero: 1);
    expect(carnet!.numeroSerie, 'C-777');
  });
}

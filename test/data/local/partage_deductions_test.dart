import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Déduction des dettes au moment du partage de fin de cycle — voir
/// DECISIONS.md, "Déduction des dettes au partage". Reprend les
/// scénarios donnés par le fondateur (montant à percevoir supérieur,
/// égal, ou inférieur à la dette).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'une amende non soldée réduit les parts reconnues du membre à la clôture — jamais une dette (voir DECISIONS.md, "Les amendes ne sont plus une dette")',
    () async {
      final groupId = await db.creerGroupe(
          name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle', paymentDayOfMonth1: 5);
      final membre1 = await db.ajouterMembre(
          groupId: groupId, fullName: 'À jour', phoneNumber: '+2250000001');
      final membre2 = await db.ajouterMembre(
          groupId: groupId, fullName: 'Amende impayée', phoneNumber: '+2250000002');
      final cycleId = await db.ouvrirCycle(
          groupId: groupId, cycleNumber: 1, partValueFcfa: 1000, interestRatePercent: 0);

      for (final membreId in [membre1, membre2]) {
        await db.definirCarnetsEngages(
            groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 1);
        await db.enregistrerCotisationCash(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          partsCount: 2, // 2000 F cotisés par membre
          recordedByPhone: '+2250000099',
        );
      }
      await db.enregistrerAmende(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membre2,
        montantFcfa: 500,
        motif: 'Absence non justifiée',
        recordedByPhone: '+2250000099',
      );

      // Une amende n'est plus une dette, quel que soit le membre : le
      // solde de prêt est le seul élément de detteMembreFcfa désormais.
      expect(await db.detteMembreFcfa(groupId: groupId, memberId: membre1, cycleId: cycleId), 0);
      expect(await db.detteMembreFcfa(groupId: groupId, memberId: membre2, cycleId: cycleId), 0);

      // Condition de clôture (voir DECISIONS.md, "Clôture de cycle
      // conditionnée au paiement de tous les membres").
      for (final membreId in [membre1, membre2]) {
        await db.confirmerPaiementMembre(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membreId,
          confirmedByPhone: '+2250000099',
        );
      }

      await db.cloturerCycleEtOuvrirSuivant(
        groupId: groupId,
        cycleIdACloturer: cycleId,
        nouveauPartValueFcfa: 1000,
        nouveauInterestRatePercent: 0,
        recordedByPhone: '+2250000099',
      );

      final deductions = await db.partageDeductionsDuCycle(cycleId);
      expect(deductions, hasLength(2));

      // membre2 : 2000 F cotisés, 500 F d'amende non soldée -> reste
      // 1500 F -> 1 part reconnue (1000 F) + 500 F de résidu (voir
      // AmendeReductionCalculator). Pot commun = 2000 (membre1) + 1000
      // (part reconnue de membre2) = 3000 ; + 500 F d'amende récupérée
      // par déduction (rejoint la caisse comme si payée cash) = 3500.
      // total_parts = 2 (membre1) + 1 (membre2) = 3 ->
      // valeur_par_part = 3500 / 3 = 1166.67 (arrondi par membre).
      final d1 = deductions.firstWhere((d) => d.memberId == membre1);
      expect(d1.detteFcfa, 0);
      expect(d1.montantDeduitFcfa, 0);
      expect(d1.pertAvecFcfa, 0);
      expect(d1.montantNetFcfa, d1.montantBrutFcfa);
      // 2 x 1166.67 arrondi = 2333.
      expect(d1.montantBrutFcfa, 2333);

      final d2 = deductions.firstWhere((d) => d.memberId == membre2);
      expect(d2.detteFcfa, 0); // aucune dette : l'amende n'en est pas une
      expect(d2.montantDeduitFcfa, 0);
      expect(d2.pertAvecFcfa, 0);
      // 1 x 1166.67 arrondi (1167) + 500 F de résidu, sans bénéfice dessus.
      expect(d2.montantBrutFcfa, 1667);
      expect(d2.montantNetFcfa, d2.montantBrutFcfa);

      // Conservation : rien ne se perd ni ne se crée — ce qui est
      // distribué correspond exactement à ce qui a été cotisé.
      expect(d1.montantBrutFcfa + d2.montantBrutFcfa, 4000);

      // Réglée par déduction à la clôture : ne doit plus jamais
      // réapparaître comme non soldée.
      expect(
        await db.montantAmendesNonSoldeesFcfa(
          memberId: membre2,
          cycleId: cycleId,
        ),
        0,
      );
    },
  );

  test('une dette (prêt non remboursé) supérieure au montant à percevoir : membre reçoit 0, perte AVEC enregistrée',
      () async {
    final groupId = await db.creerGroupe(
        name: 'Test', cycleDurationMonths: 9, meetingFrequency: 'mensuelle', paymentDayOfMonth1: 5);
    final membreId = await db.ajouterMembre(
        groupId: groupId, fullName: 'Gros emprunteur', phoneNumber: '+2250000003');
    final cycleId = await db.ouvrirCycle(
        groupId: groupId, cycleNumber: 1, partValueFcfa: 1000, interestRatePercent: 0);
    await db.definirCarnetsEngages(
        groupId: groupId, cycleId: cycleId, memberId: membreId, nombreCarnets: 1);
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsCount: 1, // 1000 F brut, aucun intérêt/amende dans le pot
      recordedByPhone: '+2250000099',
    );

    // `importe` : ce test veut un prêt largement supérieur à la caisse
    // disponible (55 000 F de dette pour 1 000 F cotisés), justement le
    // genre de situation que le rationnement des crédits (voir
    // DECISIONS.md) empêche désormais pour un nouveau prêt `direct` —
    // ici on représente une dette déjà existante, pas une nouvelle
    // décision de prêt à faire passer par cette règle.
    final pret = await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      principalFcfa: 50000,
      interestRatePercent: 10,
      initiatedByPhone: '+2250000099',
      confirmationCode: '1234',
      provenance: 'importe',
    );
    await db.confirmerPret(
        pretId: pret.pretId, codeSaisi: '1234', confirmedByPhone: '+2250000003');
    // Aucun remboursement -> solde dû = 50000 + 5000 = 55000.

    final dette =
        await db.detteMembreFcfa(groupId: groupId, memberId: membreId, cycleId: cycleId);
    expect(dette, 55000);

    // Condition de clôture (voir DECISIONS.md, "Clôture de cycle
    // conditionnée au paiement de tous les membres") — même un membre
    // endetté (net à 0) doit être confirmé.
    await db.confirmerPaiementMembre(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      confirmedByPhone: '+2250000099',
    );

    await db.cloturerCycleEtOuvrirSuivant(
      groupId: groupId,
      cycleIdACloturer: cycleId,
      nouveauPartValueFcfa: 1000,
      nouveauInterestRatePercent: 0,
      recordedByPhone: '+2250000099',
    );

    final deductions = await db.partageDeductionsDuCycle(cycleId);
    final d = deductions.single;
    expect(d.montantBrutFcfa, 1000);
    expect(d.detteFcfa, 55000);
    expect(d.montantDeduitFcfa, 1000);
    expect(d.montantNetFcfa, 0);
    expect(d.pertAvecFcfa, 54000);
  });
}

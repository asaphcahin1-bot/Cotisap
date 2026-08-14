import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/data/local/database.dart';

/// Catalogue de motifs d'amende par groupe — voir DECISIONS.md,
/// "Catalogue de motifs d'amende". Config simple (pas une table
/// financière) : modifier ou désactiver un motif ne change jamais une
/// amende déjà enregistrée avec ce motif.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('creerMotifAmende crée un motif actif par défaut', () async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );

    final motifId = await db.creerMotifAmende(
      groupId: groupId,
      libelle: 'Bavardage',
      montantFcfa: 200,
    );

    // Un groupe naît déjà avec les 3 motifs système (voir DECISIONS.md,
    // "Motifs d'amende prédéfinis") — le motif personnalisé s'ajoute à
    // ceux-là, jamais seul.
    final motifs = await db.motifsAmendeDuGroupe(groupId);
    expect(motifs, hasLength(4));
    final bavardage = motifs.singleWhere((m) => m.id == motifId);
    expect(bavardage.libelle, 'Bavardage');
    expect(bavardage.montantFcfa, 200);
    expect(bavardage.actif, isTrue);
    expect(bavardage.codeSysteme, isNull);
  });

  test('motifsAmendeActifsDuGroupe ne renvoie que les motifs actifs', () async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );
    final id1 = await db.creerMotifAmende(
      groupId: groupId,
      libelle: 'Bavardage',
      montantFcfa: 200,
    );
    await db.creerMotifAmende(
      groupId: groupId,
      libelle: 'Téléphone',
      montantFcfa: 300,
    );

    await db.definirActifMotifAmende(motifId: id1, actif: false);

    // 3 motifs système + "Téléphone" restent actifs ; "Bavardage" désactivé.
    final actifs = await db.motifsAmendeActifsDuGroupe(groupId);
    expect(actifs, hasLength(4));
    expect(actifs.any((m) => m.libelle == 'Bavardage'), isFalse);
    expect(actifs.any((m) => m.libelle == 'Téléphone'), isTrue);

    // Le motif désactivé reste visible dans la liste complète.
    final tous = await db.motifsAmendeDuGroupe(groupId);
    expect(tous, hasLength(5));
  });

  test('un motif désactivé peut être réactivé', () async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );
    final motifId = await db.creerMotifAmende(
      groupId: groupId,
      libelle: 'Bavardage',
      montantFcfa: 200,
    );
    await db.definirActifMotifAmende(motifId: motifId, actif: false);
    await db.definirActifMotifAmende(motifId: motifId, actif: true);

    final actifs = await db.motifsAmendeActifsDuGroupe(groupId);
    expect(actifs.any((m) => m.id == motifId), isTrue);
  });

  test(
    'modifierMotifAmende change libellé et montant, sans toucher aux amendes déjà enregistrées',
    () async {
      final groupId = await db.creerGroupe(
        name: 'Groupe test',
        cycleDurationMonths: 9,
        meetingFrequency: 'mensuelle',
      );
      final membreId = await db.ajouterMembre(
        groupId: groupId,
        fullName: 'Membre test',
      );
      final cycleId = await db.ouvrirCycle(
        groupId: groupId,
        cycleNumber: 1,
        partValueFcfa: 500,
        interestRatePercent: 10,
      );
      final motifId = await db.creerMotifAmende(
        groupId: groupId,
        libelle: 'Bavardage',
        montantFcfa: 200,
      );

      // Une amende enregistrée "à la main" avec le libellé/montant du
      // motif au moment de sa création (l'écran copie ces valeurs dans le
      // formulaire — aucune référence vivante au motif lui-même).
      await db.enregistrerAmende(
        groupId: groupId,
        cycleId: cycleId,
        memberId: membreId,
        montantFcfa: 200,
        motif: 'Bavardage',
        recordedByPhone: '+2250000099',
      );

      // Le responsable change d'avis : Bavardage passe à 500 F.
      await db.modifierMotifAmende(
        motifId: motifId,
        libelle: 'Bavardage',
        montantFcfa: 500,
      );

      final motifs = await db.motifsAmendeDuGroupe(groupId);
      expect(motifs.singleWhere((m) => m.id == motifId).montantFcfa, 500);

      // L'amende déjà enregistrée garde son montant d'origine.
      final amendes = await db.amendesDuMembre(membreId, cycleId);
      expect(amendes.single.montantFcfa, 200);
    },
  );
}

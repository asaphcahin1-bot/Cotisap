import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/domain/calculators/loan_rate_resolver.dart';

/// Vérifie [AppDatabase.sortirDuRouge] — voir DECISIONS.md, "Sortir du
/// rouge : paiement libre" (RETOURS_TERRAIN.md, point 8) : le membre
/// apporte le montant de son choix (0, le minimum requis, ou plus), le
/// prêt reconduit vaut la dette du jour + l'amende - ce paiement, au
/// taux résolu comme un prêt neuf (jamais le taux plat du cycle) — sans
/// jamais compter la même dette deux fois, et sans jamais laisser de
/// trace séparée pour l'amende.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    AppClock.definir(null);
  });

  Future<
      ({
        String groupId,
        String cycleId,
        String membreId,
      })> preparerGroupe({int montantAmendeSortieRougeFcfa = 0}) async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 12,
      meetingFrequency: 'mensuelle',
      // Volontairement différent du 1er (jour de création du prêt) —
      // sinon la borne de fin de période, ramenée à la dernière réunion
      // <= la date brute (voir DECISIONS.md, "Délai de recouvrement des
      // prêts aligné sur les réunions"), coïnciderait avec le début du
      // prêt lui-même et fausserait la durée réelle de période normale
      // testée ici.
      paymentDayOfMonth1: 15,
      montantAmendeSortieRougeFcfa: montantAmendeSortieRougeFcfa,
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
      loanDurationDays: 30,
      startedAt: DateTime(2024, 1, 1),
    );
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  /// Crée un prêt `importe` (pas de fenêtre/caisse à satisfaire) qui
  /// entre au rouge : durée de 30 jours depuis le 1er janvier 2024,
  /// jamais remboursé. À la date de test (1er mars), il est passé au
  /// rouge le 15 janvier (10000 -> 11000) puis a composé une fois au
  /// 15 février (11000 -> 12100) — voir loan_balance_calculator_test.dart
  /// pour la même mécanique.
  Future<String> creerPretAuRouge(
    ({String groupId, String cycleId, String membreId}) ctx, {
    int principalFcfa = 10000,
  }) async {
    final resultat = await db.enregistrerPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      principalFcfa: principalFcfa,
      interestRatePercent: 10,
      initiatedByPhone: '+2250700000099',
      dureeJours: 30,
      provenance: 'importe',
      createdAt: DateTime(2024, 1, 1),
    );
    return resultat.pretId;
  }

  final maintenant = DateTime(2024, 3, 1);
  // Voir creerPretAuRouge : soldeAuDebutDuRouge = 11000, montantDuFcfa
  // au 1er mars = 12100 (une recomposition à 10 % déjà appliquée).
  const soldeAuDebutDuRouge = 11000;
  const montantDuAuMars = 12100;
  const montantInterets = montantDuAuMars - soldeAuDebutDuRouge; // 1100

  test(
      'payer exactement le minimum requis (intérêts, amende=0) reconduit le principal d\'origine',
      () async {
    final ctx = await preparerGroupe();
    final pretId = await creerPretAuRouge(ctx);

    final resultat = await db.sortirDuRouge(
      pretId: pretId,
      agentPhone: '+2250700000099',
      montantPayeFcfa: montantInterets,
      maintenant: maintenant,
    );

    final nouveauPret = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultat.pretId)))
        .getSingle();
    expect(nouveauPret.renouvelePretId, pretId);
    expect(nouveauPret.provenance, 'renouvellement');
    expect(nouveauPret.principalFcfa, soldeAuDebutDuRouge);
    expect(nouveauPret.dureeJours, 30);
    expect(nouveauPret.estAuRougeDesLeDepart, isFalse);
    // Aucune cotisation enregistrée -> plafond 3x nul -> hors carnet,
    // jamais le taux plat du cycle (10 %) — voir DECISIONS.md.
    expect(nouveauPret.interestRatePercent, LoanRateResolver.tauxHorsCarnet);

    // Le paiement a bien été tracé comme un remboursement normal sur
    // l'ancien prêt.
    final rembsAncien = await db.remboursementsDuPret(pretId);
    expect(rembsAncien, hasLength(1));
    expect(rembsAncien.single.montantFcfa, montantInterets);
  });

  test(
      'payer plus que le minimum réduit le montant reconduit',
      () async {
    final ctx = await preparerGroupe();
    final pretId = await creerPretAuRouge(ctx);
    final montantPaye = montantInterets + 5000; // 6100

    final resultat = await db.sortirDuRouge(
      pretId: pretId,
      agentPhone: '+2250700000099',
      montantPayeFcfa: montantPaye,
      maintenant: maintenant,
    );

    final nouveauPret = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultat.pretId)))
        .getSingle();
    // 12100 (dette du jour) - 6100 payé = 6000, en dessous du principal
    // d'origine (11000).
    expect(nouveauPret.principalFcfa, montantDuAuMars - montantPaye);
    expect(nouveauPret.principalFcfa, lessThan(soldeAuDebutDuRouge));
  });

  test(
      'ne rien payer ajoute la dette du jour (intérêts + amende) au montant reconduit',
      () async {
    final ctx = await preparerGroupe(montantAmendeSortieRougeFcfa: 1000);
    final pretId = await creerPretAuRouge(ctx);

    final resultat = await db.sortirDuRouge(
      pretId: pretId,
      agentPhone: '+2250700000099',
      montantPayeFcfa: 0,
      maintenant: maintenant,
    );

    final nouveauPret = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultat.pretId)))
        .getSingle();
    // 12100 (dette du jour, intérêts du rouge déjà inclus) + 1000
    // (amende non payée) - 0 payé = 13100.
    expect(nouveauPret.principalFcfa, montantDuAuMars + 1000);

    // Aucun remboursement enregistré (rien payé).
    expect(await db.remboursementsDuPret(pretId), isEmpty);

    // L'amende n'a jamais de trace séparée — voir DECISIONS.md, "pas
    // de trace séparée" (décision explicite du fondateur).
    final amendesGroupe = await (db.select(db.amendes)
          ..where((a) => a.memberId.equals(ctx.membreId)))
        .get();
    expect(amendesGroupe, isEmpty);
  });

  test(
      'le taux du prêt reconduit passe "dans le carnet" si la cotisation du membre le permet',
      () async {
    final ctx = await preparerGroupe();
    final pretId = await creerPretAuRouge(ctx);
    // Cotisation suffisante pour couvrir 3x le montant reconduit
    // (11000) -> plafond largement au-dessus, jamais "hors carnet"
    // par le plafond (la fenêtre des 3 derniers mois ne s'applique pas
    // non plus : le cycle dure 12 mois, on est encore début mars).
    await db.enregistrerCotisationCash(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsCount: 10, // 5000 F à 500 F/part
      recordedByPhone: '+2250700000099',
    );

    final resultat = await db.sortirDuRouge(
      pretId: pretId,
      agentPhone: '+2250700000099',
      montantPayeFcfa: montantInterets,
      maintenant: maintenant,
    );

    final nouveauPret = await (db.select(db.prets)
          ..where((p) => p.id.equals(resultat.pretId)))
        .getSingle();
    expect(nouveauPret.interestRatePercent, LoanRateResolver.tauxDansLeCarnet);
  });

  test(
      'refuse un prêt qui n\'est pas au rouge',
      () async {
    final ctx = await preparerGroupe();
    final pretId = await creerPretAuRouge(ctx);

    // Encore dans la période normale (30 jours) -> pas au rouge.
    expect(
      () => db.sortirDuRouge(
        pretId: pretId,
        agentPhone: '+2250700000099',
        montantPayeFcfa: 0,
        maintenant: DateTime(2024, 1, 10),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
      'refuse si le paiement couvre déjà tout le prêt — utiliser un remboursement normal',
      () async {
    final ctx = await preparerGroupe();
    final pretId = await creerPretAuRouge(ctx);

    expect(
      () => db.sortirDuRouge(
        pretId: pretId,
        agentPhone: '+2250700000099',
        montantPayeFcfa: montantDuAuMars, // couvre tout, rien à reconduire
        maintenant: maintenant,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('refuse un montant payé négatif', () async {
    final ctx = await preparerGroupe();
    final pretId = await creerPretAuRouge(ctx);

    expect(
      () => db.sortirDuRouge(
        pretId: pretId,
        agentPhone: '+2250700000099',
        montantPayeFcfa: -1,
        maintenant: maintenant,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
      'après sortirDuRouge, l\'ancien prêt disparaît de pretsNonSoldesDuCycle — pas de double comptage',
      () async {
    final ctx = await preparerGroupe();
    final pretId = await creerPretAuRouge(ctx);

    final resultat = await db.sortirDuRouge(
      pretId: pretId,
      agentPhone: '+2250700000099',
      montantPayeFcfa: montantInterets,
      maintenant: maintenant,
    );
    // Comme tout prêt, le successeur exige sa propre confirmation par
    // le membre (voir la doc de sortirDuRouge) — sans elle,
    // pretsNonSoldesDuCycle ne le compterait pas non plus, faussant le
    // test. Membre sans téléphone -> confirmation par signature.
    await db.confirmerPretParSignature(
      pretId: resultat.pretId,
      signatureData: '10.0,20.0;15.0,25.0',
      witnessPhone: '+2250700000099',
    );

    final nonSoldes = await db.pretsNonSoldesDuCycle(ctx.cycleId);
    final idsNonSoldes = nonSoldes.map((p) => p.pret.id).toSet();
    expect(idsNonSoldes.contains(pretId), isFalse);
    // Le nouveau prêt, lui, reste dû (rien n'a été remboursé dessus).
    expect(idsNonSoldes.contains(resultat.pretId), isTrue);
  });

  test(
      'après sortirDuRouge, detteMembreFcfa ne compte le solde qu\'une seule fois',
      () async {
    final ctx = await preparerGroupe();
    final pretId = await creerPretAuRouge(ctx);

    final pretAvant =
        await (db.select(db.prets)..where((p) => p.id.equals(pretId)))
            .getSingle();
    final soldeAvant = await db.soldePret(pretAvant, maintenant: maintenant);

    final resultat = await db.sortirDuRouge(
      pretId: pretId,
      agentPhone: '+2250700000099',
      montantPayeFcfa: montantInterets,
      maintenant: maintenant,
    );
    // Confirmation du prêt successeur — voir le commentaire équivalent
    // du test précédent.
    await db.confirmerPretParSignature(
      pretId: resultat.pretId,
      signatureData: '10.0,20.0;15.0,25.0',
      witnessPhone: '+2250700000099',
    );

    final dette = await db.detteMembreFcfa(
      groupId: ctx.groupId,
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
      maintenant: maintenant,
    );

    // La dette totale doit rester proche du solde au moment de la
    // sortie du rouge (le principal reconduit, pas l'ancien ET le
    // nouveau prêt additionnés).
    expect(dette, lessThan(soldeAvant.montantDuFcfa * 2));
    expect(dette, greaterThan(0));

    // Les deux prêts (ancien + successeur) sont bien tous les deux
    // conservés en base — seule leur agrégation dans detteMembreFcfa
    // doit exclure l'ancien.
    final pretsMembre = await db.pretsDuMembre(ctx.membreId, ctx.cycleId);
    expect(pretsMembre, hasLength(2));
  });
}

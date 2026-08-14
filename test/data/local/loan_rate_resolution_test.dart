import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';
import 'package:cotisapp/domain/calculators/loan_rate_resolver.dart';

/// Vérifie la brique DB qui alimente [LoanRateResolver] côté écran Prêts
/// (voir DECISIONS.md, "Résolution automatique du taux de prêt") :
/// [AppDatabase.totalEmprunteEnCoursFcfa] doit refléter le total réel
/// emprunté par un membre, tous prêts confondus, et seulement les prêts
/// confirmés non soldés.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<({String groupId, String cycleId, String membreId})> preparerGroupe() async {
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
    );
    final membreId = await db.ajouterMembre(groupId: groupId, fullName: 'Membre test');
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
    );
    return (groupId: groupId, cycleId: cycleId, membreId: membreId);
  }

  test('un prêt non confirmé ne compte pas dans le total emprunté en cours', () async {
    // Fenêtre de crédit + caisse disponible (voir DECISIONS.md) : ce
    // test veut un prêt `direct` non confirmé (pas `importe`, qui
    // confirme automatiquement) — satisfait les deux conditions
    // explicitement plutôt que de contourner via `importe`.
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'mensuelle',
      paymentDayOfMonth1: 5,
    );
    final membreId = await db.ajouterMembre(groupId: groupId, fullName: 'Membre test');
    final debutCycle = DateTime(2024, 1, 5);
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      partsCount: 30, // 15000 F — au-dessus du prêt demandé
      recordedByPhone: '+2250700000099',
    );
    AppClock.definir(DateTime(2024, 2, 5)); // 2e réunion -> fenêtre ouverte
    addTearDown(() => AppClock.definir(null));

    await db.enregistrerPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      principalFcfa: 10000,
      interestRatePercent: LoanRateResolver.tauxDansLeCarnet,
      initiatedByPhone: '+2250700000099',
    );

    final total = await db.totalEmprunteEnCoursFcfa(
      memberId: membreId,
      cycleId: cycleId,
    );
    expect(total, 0);
  });

  test('un prêt confirmé compte dans le total emprunté en cours', () async {
    final ctx = await preparerGroupe();
    final resultat = await db.enregistrerPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      principalFcfa: 10000,
      interestRatePercent: LoanRateResolver.tauxDansLeCarnet,
      initiatedByPhone: '+2250700000099',
      provenance: 'importe',
    );
    await db.confirmerPretParSignature(
      pretId: resultat.pretId,
      signatureData: '10.0,20.0;15.0,25.0',
      witnessPhone: '+2250700000099',
    );

    final total = await db.totalEmprunteEnCoursFcfa(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(total, 10000);
  });

  test('deux prêts confirmés s\'additionnent dans le total emprunté en cours', () async {
    final ctx = await preparerGroupe();
    for (final montant in [10000, 5000]) {
      final resultat = await db.enregistrerPret(
        groupId: ctx.groupId,
        cycleId: ctx.cycleId,
        memberId: ctx.membreId,
        principalFcfa: montant,
        interestRatePercent: LoanRateResolver.tauxDansLeCarnet,
        initiatedByPhone: '+2250700000099',
        provenance: 'importe',
      );
      await db.confirmerPretParSignature(
        pretId: resultat.pretId,
        signatureData: '10.0,20.0;15.0,25.0',
        witnessPhone: '+2250700000099',
      );
    }

    final total = await db.totalEmprunteEnCoursFcfa(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(total, 15000);
  });

  test(
      'un prêt intégralement remboursé ne compte plus dans le total emprunté en cours',
      () async {
    final ctx = await preparerGroupe();
    final resultat = await db.enregistrerPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      principalFcfa: 10000,
      interestRatePercent: LoanRateResolver.tauxDansLeCarnet,
      initiatedByPhone: '+2250700000099',
      provenance: 'importe',
    );
    await db.confirmerPretParSignature(
      pretId: resultat.pretId,
      signatureData: '10.0,20.0;15.0,25.0',
      witnessPhone: '+2250700000099',
    );
    // Principal + intérêt à 10 % = 11000.
    await db.enregistrerRemboursement(
      pretId: resultat.pretId,
      montantFcfa: 11000,
      recordedByPhone: '+2250700000099',
    );

    final total = await db.totalEmprunteEnCoursFcfa(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(total, 0);
  });

  test(
      'bout en bout : le total réel emprunté fait basculer un second prêt hors carnet',
      () async {
    final ctx = await preparerGroupe();
    // Cotise 10000 -> plafond 30000.
    await db.enregistrerCotisationCash(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      partsCount: 20,
      recordedByPhone: '+2250700000099',
    );
    final cotise = await db.totalCotiseFcfa(memberId: ctx.membreId, cycleId: ctx.cycleId);
    expect(cotise, 10000);

    // Premier prêt de 25000, confirmé -> encore sous le plafond (30000).
    final premier = await db.enregistrerPret(
      groupId: ctx.groupId,
      cycleId: ctx.cycleId,
      memberId: ctx.membreId,
      principalFcfa: 25000,
      interestRatePercent: LoanRateResolver.tauxDansLeCarnet,
      initiatedByPhone: '+2250700000099',
      provenance: 'importe',
    );
    await db.confirmerPretParSignature(
      pretId: premier.pretId,
      signatureData: '10.0,20.0;15.0,25.0',
      witnessPhone: '+2250700000099',
    );

    final empruntesEnCours = await db.totalEmprunteEnCoursFcfa(
      memberId: ctx.membreId,
      cycleId: ctx.cycleId,
    );
    expect(empruntesEnCours, 25000);

    // Un second prêt de 10000 ferait 35000 au total -> dépasse 30000,
    // même si 10000 seul serait resté sous le plafond.
    final resolution = const LoanRateResolver().resoudre(
      cotiseTotalFcfa: cotise,
      empruntesEnCoursFcfa: empruntesEnCours,
      principalDemandeFcfa: 10000,
      maintenant: DateTime(2024, 1, 1),
      finDeCycle: DateTime(2025, 1, 1),
    );
    expect(resolution.horsCarnet, isTrue);
    expect(resolution.tauxPercent, LoanRateResolver.tauxHorsCarnet);
  });
}

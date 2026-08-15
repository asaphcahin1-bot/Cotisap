import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/core/app_clock.dart';
import 'package:cotisapp/data/local/database.dart';

/// Vérifie l'indépendance entre les prêts et la détection de la journée
/// de cotisation — voir RETOURS_TERRAIN.md, point 25.7 : le fondateur a
/// signalé qu'après avoir validé un prêt hors fenêtre de crédit, l'écran
/// Cotisation n'affichait plus aucune journée pour continuer à cotiser.
///
/// Ce test confirme qu'aucun mécanisme de prêt (demande, acceptation,
/// confirmation — même tardive, hors fenêtre) n'écrit quoi que ce soit
/// dans le registre des échéances de cotisation (`Echeances`), et que
/// `journeeCotisationEnAttente` continue de fonctionner normalement
/// après. N'a pas reproduit le symptôme signalé : les deux mécanismes
/// sont, dans le code actuel, entièrement indépendants.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    AppClock.definir(null);
    await db.close();
  });

  test(
      'confirmer un prêt tardivement (hors fenêtre de crédit) ne bloque pas '
      'la détection de la journée de cotisation suivante', () async {
    // 4 janvier 2024 est un jeudi.
    final debutCycle = DateTime(2024, 1, 4);
    final groupId = await db.creerGroupe(
      name: 'Groupe test',
      cycleDurationMonths: 9,
      meetingFrequency: 'hebdomadaire',
      paymentDayOfWeek: DateTime.thursday,
    );
    final membreId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Membre test',
      phoneNumber: '+2250000001',
      joinedAt: debutCycle,
    );
    final cycleId = await db.ouvrirCycle(
      groupId: groupId,
      cycleNumber: 1,
      partValueFcfa: 500,
      interestRatePercent: 10,
      startedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
    );

    AppClock.definir(debutCycle);

    // Un autre membre finance la caisse disponible — pour ne jamais
    // toucher aux échéances du membre testé ci-dessous.
    final bailleurId = await db.ajouterMembre(
      groupId: groupId,
      fullName: 'Bailleur de fonds',
      phoneNumber: '+2250000002',
      joinedAt: debutCycle,
    );
    await db.definirCarnetsEngages(
      groupId: groupId,
      cycleId: cycleId,
      memberId: bailleurId,
    );
    await db.enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: bailleurId,
      carnetNumero: 1,
      partsCount: 5,
      recordedByPhone: '+2250000099',
      echeanceDate: debutCycle,
    );

    // Vérifie l'état de référence avant toute opération de prêt.
    final journeeAvant = await db.journeeCotisationEnAttente(
      groupId: groupId,
      cycleId: cycleId,
    );
    expect(journeeAvant, debutCycle);

    // Demande et acceptation d'un prêt pendant la 4e réunion — fenêtre
    // de crédit ouverte (voir DECISIONS.md, "Fenêtres de crédit selon la
    // fréquence de réunion").
    final semaine4 = debutCycle.add(const Duration(days: 21));
    AppClock.definir(semaine4);
    final demandeId = await db.demanderPret(
      groupId: groupId,
      cycleId: cycleId,
      memberId: membreId,
      montantDemandeFcfa: 2000,
      recordedByPhone: '+2250000099',
    );
    final resultat = await db.accepterDemandePret(
      demandeId: demandeId,
      montantAccepteFcfa: 2000,
      agentPhone: '+2250000099',
      confirmationCode: '1234',
    );

    // Confirmation "tardive" : bien après la fenêtre de crédit, sans
    // rapport avec la journée de cotisation.
    AppClock.definir(semaine4.add(const Duration(days: 60)));
    final confirme = await db.confirmerPret(
      pretId: resultat.pretId,
      codeSaisi: '1234',
      confirmedByPhone: '+2250000001',
    );
    expect(confirme, isTrue,
        reason: 'la confirmation n\'est jamais re-bloquée par la fenêtre — '
            'seule la demande initiale l\'est');

    // La détection de la journée de cotisation reste intacte : aucune
    // ligne Echeances n'a été touchée par les opérations de prêt
    // ci-dessus.
    final lignes = await db.echeancesDuMembre(
      memberId: membreId,
      cycleId: cycleId,
    );
    expect(lignes, isEmpty,
        reason: 'aucune opération de prêt ne doit jamais écrire dans '
            'Echeances');

    final journeeApres = await db.journeeCotisationEnAttente(
      groupId: groupId,
      cycleId: cycleId,
    );
    expect(journeeApres, debutCycle,
        reason: 'la 1re réunion, jamais clôturée, reste normalement '
            'détectée comme en attente après les opérations de prêt');
  });
}

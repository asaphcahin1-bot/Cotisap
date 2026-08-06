import '../../core/app_clock.dart';
import '../local/database.dart';
import '../../domain/calculators/echeance_calculator.dart';

/// Détecte les échéances closes non couvertes par chaque membre actif
/// d'un groupe et applique automatiquement l'amende de retard configurée
/// (skill avec-business-rules, section "Retard de cotisation") —
/// **jamais pour l'échéance en cours**, seulement pour celles déjà
/// passées et pas encore sanctionnées. L'agent revoit ensuite chaque
/// amende ainsi posée (confirmer / signaler une erreur) — voir
/// [AppDatabase.amendesEnAttenteRevue].
///
/// Appelé à chaque ouverture de l'écran Cotisations plutôt qu'à un
/// instant précis : idempotent (n'applique jamais deux fois pour la
/// même échéance manquée), donc sans risque à rejouer souvent.
class AmendeAutoService {
  final AppDatabase db;

  const AmendeAutoService(this.db);

  /// [maintenant] est injectable pour les tests (comportement déterministe
  /// plutôt que dépendant de l'horloge réelle) — par défaut
  /// `DateTime.now()` en usage normal.
  Future<void> detecterEtAppliquer({
    required String groupId,
    required String cycleId,
    required String recordedByPhone,
    DateTime? maintenant,
  }) async {
    final now = maintenant ?? AppClock.now();
    final cycle = await (db.select(db.cycles)..where((c) => c.id.equals(cycleId))).getSingle();
    if (cycle.lateFeeFcfa <= 0) return; // groupe sans amende automatique

    final groupe = await (db.select(db.groups)..where((g) => g.id.equals(groupId))).getSingle();
    final membres = await db.membresDuGroupe(groupId);

    for (final membre in membres) {
      final carnets =
          await db.carnetsEngagesDuMembre(memberId: membre.id, cycleId: cycleId);
      if (carnets == null) continue; // pas encore de carnets engagés ce cycle

      final montantParEcheance = carnets.partsCount * cycle.partValueFcfa;
      if (montantParEcheance <= 0) continue;

      List<DateTime> echeances;
      try {
        echeances = const EcheanceCalculator().echeancesPassees(
          debutCycle: cycle.startedAt,
          meetingFrequency: groupe.meetingFrequency,
          paymentDayOfWeek: groupe.paymentDayOfWeek,
          paymentDayOfMonth1: groupe.paymentDayOfMonth1,
          paymentDayOfMonth2: groupe.paymentDayOfMonth2,
          maintenant: now,
        );
      } on ArgumentError {
        continue; // jour de paiement non configuré, rien à détecter
      }
      // La dernière échéance de la liste est toujours l'échéance en
      // cours (pas encore close) — jamais sanctionnée (voir
      // DECISIONS.md : "aucune amende le jour même").
      final echeancesClosesCount = echeances.length - 1;
      if (echeancesClosesCount <= 0) continue;

      final totalPayeFcfa =
          await db.totalCotiseFcfa(memberId: membre.id, cycleId: cycleId);
      final couvertureEnEcheances = totalPayeFcfa ~/ montantParEcheance;
      final echeancesNonCouvertes = echeancesClosesCount - couvertureEnEcheances;
      if (echeancesNonCouvertes <= 0) continue;

      final dejaAppliquees =
          await db.amendesAutoDuMembre(memberId: membre.id, cycleId: cycleId);
      final manquantes = echeancesNonCouvertes - dejaAppliquees.length;

      for (var i = 0; i < manquantes; i++) {
        await db.enregistrerAmende(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membre.id,
          montantFcfa: cycle.lateFeeFcfa,
          motif: 'Retard de cotisation',
          recordedByPhone: recordedByPhone,
          estAutoGeneree: true,
        );
      }
    }
  }
}

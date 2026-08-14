import 'echeance_calculator.dart';

/// Détermine si les inscriptions de nouveaux membres doivent être
/// fermées pour un cycle — voir DECISIONS.md, "Inscription de
/// nouveaux membres : sans limite, sauf fin de cycle" (RETOURS_TERRAIN.md,
/// point 16) : un membre peut rejoindre le groupe à **n'importe quel
/// moment du cycle**, sauf dans les **2 dernières réunions avant sa
/// fin prévue** — fermeture automatique à partir de ce seuil.
/// **Remplace** l'ancienne règle ("fermé dès la clôture de la
/// première journée de cotisation"), abandonnée par le fondateur.
///
/// Pure Dart, aucune dépendance à la base — testable directement,
/// comme [LoanWindowCalculator].
class MembershipClosureCalculator {
  const MembershipClosureCalculator();

  static const int reunionsAvantFermeture = 2;

  /// Vrai si les inscriptions doivent être fermées à [maintenant] —
  /// c'est-à-dire s'il reste [reunionsAvantFermeture] réunions ou
  /// moins avant [finDeCycle] (`cycle.startedAt` + `group.cycleDurationMonths`).
  bool inscriptionsFermees({
    required DateTime debutCycle,
    required DateTime finDeCycle,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
    required DateTime maintenant,
  }) {
    final restantes = reunionsRestantesAvantFinDeCycle(
      debutCycle: debutCycle,
      finDeCycle: finDeCycle,
      meetingFrequency: meetingFrequency,
      paymentDayOfWeek: paymentDayOfWeek,
      paymentDayOfMonth1: paymentDayOfMonth1,
      paymentDayOfMonth2: paymentDayOfMonth2,
      maintenant: maintenant,
    );
    return restantes <= reunionsAvantFermeture;
  }

  /// Nombre de réunions restantes avant la fin prévue du cycle —
  /// purement informatif pour l'écran (ex. "encore 3 réunions avant la
  /// fermeture des inscriptions"). Peut être négatif si [maintenant]
  /// dépasse déjà [finDeCycle] (cycle en retard, pas encore clôturé) —
  /// reste alors sous le seuil de fermeture, jamais rouvert.
  int reunionsRestantesAvantFinDeCycle({
    required DateTime debutCycle,
    required DateTime finDeCycle,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
    required DateTime maintenant,
  }) {
    List<DateTime> toutesLesReunions;
    List<DateTime> reunionsPassees;
    try {
      toutesLesReunions = const EcheanceCalculator().echeancesPassees(
        debutCycle: debutCycle,
        meetingFrequency: meetingFrequency,
        paymentDayOfWeek: paymentDayOfWeek,
        paymentDayOfMonth1: paymentDayOfMonth1,
        paymentDayOfMonth2: paymentDayOfMonth2,
        maintenant: finDeCycle,
      );
      reunionsPassees = const EcheanceCalculator().echeancesPassees(
        debutCycle: debutCycle,
        meetingFrequency: meetingFrequency,
        paymentDayOfWeek: paymentDayOfWeek,
        paymentDayOfMonth1: paymentDayOfMonth1,
        paymentDayOfMonth2: paymentDayOfMonth2,
        maintenant: maintenant,
      );
    } on ArgumentError {
      // Fréquence mal configurée -> ne bloque jamais silencieusement
      // une inscription légitime pour une raison technique ; un
      // nombre élevé garde les inscriptions ouvertes par défaut.
      return reunionsAvantFermeture + 1;
    }
    return toutesLesReunions.length - reunionsPassees.length;
  }
}

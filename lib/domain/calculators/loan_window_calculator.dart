import 'echeance_calculator.dart';

/// Détermine si une nouvelle demande de prêt peut être initiée à un
/// instant donné, selon la fréquence des réunions du groupe — voir
/// DECISIONS.md, "Fenêtres de crédit selon la fréquence de réunion"
/// (RETOURS_TERRAIN.md, point 10) :
/// - `hebdomadaire` : le premier prêt seulement à partir de la
///   **4e réunion**, puis de nouveau toutes les 4 réunions (8e, 12e...) ;
/// - `bimensuelle`/`mensuelle` : à chaque **2e réunion** (2e, 4e, 6e...).
///
/// Une fenêtre reste ouverte depuis la réunion concernée jusqu'à la
/// réunion suivante (pas seulement le jour même de la réunion) — même
/// esprit que [AppDatabase.journeeCotisationEnAttente] : l'agent peut
/// initier le prêt n'importe quel jour de cette période, pas
/// uniquement le jour exact de la réunion.
///
/// Pure Dart, aucune dépendance à la base — testable directement,
/// comme [EcheanceCalculator].
class LoanWindowCalculator {
  const LoanWindowCalculator();

  bool fenetreOuverte({
    required DateTime debutCycle,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
    required DateTime maintenant,
  }) {
    List<DateTime> echeances;
    try {
      echeances = const EcheanceCalculator().echeancesPassees(
        debutCycle: debutCycle,
        meetingFrequency: meetingFrequency,
        paymentDayOfWeek: paymentDayOfWeek,
        paymentDayOfMonth1: paymentDayOfMonth1,
        paymentDayOfMonth2: paymentDayOfMonth2,
        maintenant: maintenant,
      );
    } on ArgumentError {
      return false;
    }
    if (echeances.isEmpty) return false;

    final intervalle = meetingFrequency == 'hebdomadaire' ? 4 : 2;
    final numeroReunion = echeances.length;
    return numeroReunion % intervalle == 0;
  }

  /// Nombre de réunions restantes avant la prochaine fenêtre de crédit
  /// — purement informatif pour l'écran (ex. "encore 2 réunions avant
  /// le prochain prêt possible"). 0 si la fenêtre est déjà ouverte.
  int reunionsAvantProchaineFenetre({
    required DateTime debutCycle,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
    required DateTime maintenant,
  }) {
    List<DateTime> echeances;
    try {
      echeances = const EcheanceCalculator().echeancesPassees(
        debutCycle: debutCycle,
        meetingFrequency: meetingFrequency,
        paymentDayOfWeek: paymentDayOfWeek,
        paymentDayOfMonth1: paymentDayOfMonth1,
        paymentDayOfMonth2: paymentDayOfMonth2,
        maintenant: maintenant,
      );
    } on ArgumentError {
      return 0;
    }
    final intervalle = meetingFrequency == 'hebdomadaire' ? 4 : 2;
    final numeroReunion = echeances.length;
    final reste = numeroReunion % intervalle;
    return reste == 0 ? 0 : intervalle - reste;
  }
}

/// Calcule les dates d'échéance de cotisation d'un membre — skill
/// avec-business-rules, section "Retard de cotisation" : les
/// cotisations tombent à date fixe (jour de paiement configuré sur le
/// groupe), pas sur une simple période glissante.
///
/// **Pas de rattrapage** (décision du fondateur, 2026-08-09) : une
/// échéance manquée n'est jamais rattrapable, seule l'amende prédéfinie
/// s'applique — ce calculateur ne cumule donc plus aucun "solde dû", il
/// se limite à produire les dates d'échéance elles-mêmes.
///
/// Pure Dart, aucune dépendance à la base — testable directement, comme
/// [EndOfCycleCalculator].
class EcheanceCalculator {
  const EcheanceCalculator();

  /// Toutes les dates d'échéance passées d'un cycle, du début du cycle
  /// jusqu'à [maintenant] inclus.
  ///
  /// Selon [meetingFrequency] :
  /// - `hebdomadaire` : [paymentDayOfWeek] obligatoire (1 = lundi ... 7 =
  ///   dimanche)
  /// - `mensuelle` : [paymentDayOfMonth1] obligatoire (jour du mois, ex.
  ///   5) — clampé au dernier jour du mois si le mois est plus court (ex.
  ///   jour 31 en février -> 28/29)
  /// - `bimensuelle` : [paymentDayOfMonth1] et [paymentDayOfMonth2]
  ///   obligatoires
  List<DateTime> echeancesPassees({
    required DateTime debutCycle,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
    required DateTime maintenant,
  }) {
    final debut = _dateSeule(debutCycle);
    final fin = _dateSeule(maintenant);
    if (fin.isBefore(debut)) return [];

    switch (meetingFrequency) {
      case 'hebdomadaire':
        if (paymentDayOfWeek == null || paymentDayOfWeek < 1 || paymentDayOfWeek > 7) {
          throw ArgumentError(
            'paymentDayOfWeek (1-7) est obligatoire pour une fréquence hebdomadaire.',
          );
        }
        return _echeancesHebdomadaires(debut, fin, paymentDayOfWeek);

      case 'mensuelle':
        if (paymentDayOfMonth1 == null || paymentDayOfMonth1 < 1 || paymentDayOfMonth1 > 31) {
          throw ArgumentError(
            'paymentDayOfMonth1 (1-31) est obligatoire pour une fréquence mensuelle.',
          );
        }
        return _echeancesMensuelles(debut, fin, [paymentDayOfMonth1]);

      case 'bimensuelle':
        if (paymentDayOfMonth1 == null ||
            paymentDayOfMonth2 == null ||
            paymentDayOfMonth1 < 1 ||
            paymentDayOfMonth1 > 31 ||
            paymentDayOfMonth2 < 1 ||
            paymentDayOfMonth2 > 31) {
          throw ArgumentError(
            'paymentDayOfMonth1 et paymentDayOfMonth2 (1-31) sont obligatoires '
            'pour une fréquence bimensuelle.',
          );
        }
        return _echeancesMensuelles(debut, fin, [paymentDayOfMonth1, paymentDayOfMonth2]);

      default:
        throw ArgumentError('meetingFrequency inconnue : $meetingFrequency');
    }
  }

  /// Un carnet peut recevoir entre 1 et 5 parts **par jour au total**
  /// (règle confirmée par un responsable de terrain) — pas parce qu'un
  /// membre rattrape des semaines manquées (ça n'existe plus), mais
  /// parce qu'il choisit de déposer plus qu'une part ce jour-là.
  /// Plusieurs transactions le même jour pour le même carnet
  /// s'additionnent, jamais au-delà de ce plafond (voir
  /// [AppDatabase.partsDejaAjouteesAujourdhui]).
  static const int maxPartsParTransaction = 5;

  int montantMaxTransactionFcfa(int valeurPartFcfa) =>
      maxPartsParTransaction * valeurPartFcfa;

  /// Vrai si [montantFcfa] est un multiple exact de [valeurPartFcfa],
  /// entre 1 et 5 fois cette valeur — "aucun montant intermédiaire n'est
  /// autorisé" (règle confirmée par un responsable de terrain, voir
  /// DECISIONS.md).
  bool estUnMontantValide({required int montantFcfa, required int valeurPartFcfa}) {
    if (valeurPartFcfa <= 0 || montantFcfa <= 0) return false;
    if (montantFcfa % valeurPartFcfa != 0) return false;
    final parts = montantFcfa ~/ valeurPartFcfa;
    return parts >= 1 && parts <= maxPartsParTransaction;
  }

  static DateTime _dateSeule(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> _echeancesHebdomadaires(DateTime debut, DateTime fin, int jourSemaine) {
    // DateTime.weekday : 1 = lundi ... 7 = dimanche, même convention que
    // paymentDayOfWeek.
    var decalage = jourSemaine - debut.weekday;
    if (decalage < 0) decalage += 7;
    var courante = debut.add(Duration(days: decalage));

    final resultat = <DateTime>[];
    while (!courante.isAfter(fin)) {
      resultat.add(courante);
      courante = courante.add(const Duration(days: 7));
    }
    return resultat;
  }

  List<DateTime> _echeancesMensuelles(DateTime debut, DateTime fin, List<int> joursDuMois) {
    final joursTries = [...joursDuMois]..sort();
    final resultat = <DateTime>[];
    var annee = debut.year;
    var mois = debut.month;

    while (true) {
      for (final jour in joursTries) {
        final date = DateTime(annee, mois, _clampJour(annee, mois, jour));
        if (date.isBefore(debut)) continue;
        if (date.isAfter(fin)) return resultat..sort();
        resultat.add(date);
      }
      mois++;
      if (mois > 12) {
        mois = 1;
        annee++;
      }
      // Garde-fou : au-delà d'un siècle de mois, on arrête (évite une
      // boucle infinie en cas d'erreur de saisie de date).
      if (annee > debut.year + 100) break;
    }
    return resultat..sort();
  }

  static int _clampJour(int annee, int mois, int jour) {
    final dernierJour = DateTime(annee, mois + 1, 0).day;
    return jour > dernierJour ? dernierJour : jour;
  }
}

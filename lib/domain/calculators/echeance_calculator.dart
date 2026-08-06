/// Calcule les dates d'échéance de cotisation et le solde dû cumulé d'un
/// membre — skill avec-business-rules, section "Retard de cotisation" :
/// les cotisations tombent à date fixe (jour de paiement configuré sur
/// le groupe), pas sur une simple période glissante. Un membre qui rate
/// une échéance voit le manque s'accumuler sur la suivante — jamais
/// remis à zéro silencieusement.
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

  /// Solde dû cumulé à ce jour pour un membre : (nombre d'échéances
  /// passées × carnets engagés × valeur du carnet) − ce qu'il a déjà payé
  /// sur ce cycle. Jamais négatif (un membre en avance doit 0, pas une
  /// dette négative).
  int soldeDuFcfa({
    required List<DateTime> echeancesPassees,
    required int carnetsEngages,
    required int valeurCarnetFcfa,
    required int montantDejaPayeFcfa,
  }) {
    final duTotal = echeancesPassees.length * carnetsEngages * valeurCarnetFcfa;
    final solde = duTotal - montantDejaPayeFcfa;
    return solde > 0 ? solde : 0;
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

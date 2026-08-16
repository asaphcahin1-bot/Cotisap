/// Ajoute [jours] jours **calendaires** à [date], jamais une addition de
/// durée en temps écoulé — voir DECISIONS.md, "Échéances décalées par
/// le changement d'heure (DST)". `DateTime.add(Duration(days: n))`
/// ajoute n×24h en temps absolu ; si l'intervalle traverse un
/// changement d'heure (l'appareil n'est pas forcément réglé sur un
/// fuseau ouest-africain, qui n'a pas d'heure d'été), le résultat peut
/// tomber une heure avant minuit du bon jour — donc sur la veille.
/// Construire directement depuis les composants calendaires (`year`,
/// `month`, `day + jours`) contourne complètement le problème :
/// `DateTime` normalise un `day` hors bornes en changeant de mois/année
/// selon le calendrier, jamais selon un décompte d'heures écoulées.
DateTime ajouterJoursCalendaires(DateTime date, int jours) =>
    DateTime(date.year, date.month, date.day + jours);

/// Nombre de jours **calendaires** entre [plusRecente] et [plusAncienne]
/// (positif si [plusRecente] est après) — jamais `DateTime.difference`
/// directement entre deux dates locales pour ce genre de compte : cette
/// méthode renvoie un temps écoulé réel, qui peut valoir 89 ou 91 jours
/// pour un intervalle de calendrier de 90 jours si un changement
/// d'heure tombe entre les deux (même défaut que l'addition, voir
/// [ajouterJoursCalendaires]). Convertir les deux dates en UTC **avec
/// les mêmes composants calendaires** avant de soustraire élimine le
/// problème : UTC n'a jamais d'heure d'été, donc la différence obtenue
/// est toujours l'exact décompte de jours de calendrier, quel que soit
/// le fuseau réel de l'appareil.
int joursCalendairesEntre(DateTime plusRecente, DateTime plusAncienne) {
  final a = DateTime.utc(
    plusRecente.year,
    plusRecente.month,
    plusRecente.day,
  );
  final b = DateTime.utc(
    plusAncienne.year,
    plusAncienne.month,
    plusAncienne.day,
  );
  return a.difference(b).inDays;
}

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

  /// Première date d'échéance strictement après [apres], selon la même
  /// cadence que [echeancesPassees] — utilisé pour annoncer la date de
  /// la prochaine réunion juste après la clôture d'une journée (voir
  /// DECISIONS.md, "Date de la prochaine réunion après clôture").
  /// Fenêtre de recherche large (40 jours) : couvre le plus grand écart
  /// possible entre deux échéances (mensuelle), quelle que soit la
  /// fréquence configurée.
  DateTime prochaineEcheance({
    required DateTime apres,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
  }) {
    final horizon = ajouterJoursCalendaires(apres, 40);
    final echeances = echeancesPassees(
      debutCycle: apres,
      meetingFrequency: meetingFrequency,
      paymentDayOfWeek: paymentDayOfWeek,
      paymentDayOfMonth1: paymentDayOfMonth1,
      paymentDayOfMonth2: paymentDayOfMonth2,
      maintenant: horizon,
    );
    return echeances.firstWhere((d) => d.isAfter(_dateSeule(apres)));
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
    var courante = ajouterJoursCalendaires(debut, decalage);

    final resultat = <DateTime>[];
    while (!courante.isAfter(fin)) {
      resultat.add(courante);
      courante = ajouterJoursCalendaires(courante, 7);
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

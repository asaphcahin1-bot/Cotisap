/// Résolution automatique du taux d'intérêt d'un nouveau prêt — règles
/// convenues avec le fondateur le 2026-08-08 puis précisées le
/// 2026-08-09 (voir DECISIONS.md, "Résolution automatique du taux de
/// prêt : plafond 3x, dans/hors carnet, fenêtre des 3 derniers mois").
///
/// Deux règles, jamais bloquantes — seulement un taux plus cher :
/// 1. **Plafond souple de 3x l'épargne cotisée** : si le total emprunté
///    par le membre sur ce cycle (prêts non soldés + ce nouveau prêt)
///    dépasse 3x ce qu'il a déjà cotisé, le prêt entier bascule "hors
///    carnet" (15 %) au lieu de "dans le carnet" (10 %) — jamais un
///    taux mixte sur un même prêt.
/// 2. **Fenêtre des 3 derniers mois du cycle** : tout nouveau prêt
///    initié dans cette fenêtre est automatiquement "hors carnet"
///    (15 %), quel que soit le montant — jamais de blocage, l'agent
///    peut toujours enregistrer le prêt.
///
/// Valeurs codées en dur pour l'instant (multiplicateur, taux, fenêtre)
/// — configurables par groupe dans un second temps, une fois les
/// règles stabilisées (décision explicite du fondateur, voir
/// ROADMAP.md).
///
/// Pure Dart, aucune dépendance à la base — testable directement. Le
/// taux renvoyé est ensuite figé sur la ligne [Prets.interestRatePercent]
/// au moment de la création, jamais recalculé après coup (même principe
/// que [LoanBalanceCalculator], qui suppose déjà un taux figé).
library;

/// [horsCarnet] est vrai dès que l'une des deux règles s'applique.
/// [raison] est nul quand le prêt reste "dans le carnet" (10 %), sinon
/// explique laquelle des deux règles a déclenché le taux "hors carnet"
/// (15 %) — à afficher à l'agent avant qu'il valide le montant.
class LoanRateResolution {
  final double tauxPercent;
  final bool horsCarnet;
  final String? raison;

  const LoanRateResolution({
    required this.tauxPercent,
    required this.horsCarnet,
    this.raison,
  });
}

class LoanRateResolver {
  const LoanRateResolver();

  static const int multiplicateurPlafond = 3;
  static const double tauxDansLeCarnet = 10;
  static const double tauxHorsCarnet = 15;
  static const int moisAvantFinDeCycle = 3;

  /// [cotiseTotalFcfa] : tout ce que le membre a déjà cotisé sur ce
  /// cycle, tous carnets confondus (voir [AppDatabase.totalCotiseFcfa]).
  /// [empruntesEnCoursFcfa] : somme des principaux de ses prêts
  /// confirmés non encore soldés sur ce cycle, **avant** ce nouveau prêt
  /// (voir [AppDatabase.pretsNonSoldesDuCycle], filtré par membre).
  /// [finDeCycle] : date de fin prévue du cycle (`cycle.startedAt` +
  /// `group.cycleDurationMonths`), pas forcément déjà atteinte.
  LoanRateResolution resoudre({
    required int cotiseTotalFcfa,
    required int empruntesEnCoursFcfa,
    required int principalDemandeFcfa,
    required DateTime maintenant,
    required DateTime finDeCycle,
  }) {
    if (cotiseTotalFcfa < 0) {
      throw ArgumentError('cotiseTotalFcfa ne peut pas être négatif.');
    }
    if (empruntesEnCoursFcfa < 0) {
      throw ArgumentError('empruntesEnCoursFcfa ne peut pas être négatif.');
    }
    if (principalDemandeFcfa <= 0) {
      throw ArgumentError('principalDemandeFcfa doit être positif.');
    }

    // DateTime normalise automatiquement un mois hors [1, 12] (ex :
    // month - 3 < 1 recule à l'année précédente) — précision suffisante
    // pour un seuil métier au mois près, pas une date d'échéance exacte
    // (contrairement à EcheanceCalculator, qui doit être précis au
    // jour près).
    final debutFenetre = DateTime(
      finDeCycle.year,
      finDeCycle.month - moisAvantFinDeCycle,
      finDeCycle.day,
    );
    if (!maintenant.isBefore(debutFenetre)) {
      return const LoanRateResolution(
        tauxPercent: tauxHorsCarnet,
        horsCarnet: true,
        raison:
            'Hors carnet : prêt initié dans les $moisAvantFinDeCycle '
            'derniers mois du cycle.',
      );
    }

    final plafondFcfa = cotiseTotalFcfa * multiplicateurPlafond;
    final totalApresPretFcfa = empruntesEnCoursFcfa + principalDemandeFcfa;
    if (totalApresPretFcfa > plafondFcfa) {
      return LoanRateResolution(
        tauxPercent: tauxHorsCarnet,
        horsCarnet: true,
        raison:
            'Hors carnet : total emprunté ($totalApresPretFcfa FCFA) '
            'dépasse $multiplicateurPlafond x l\'épargne cotisée '
            '($plafondFcfa FCFA).',
      );
    }

    return const LoanRateResolution(
      tauxPercent: tauxDansLeCarnet,
      horsCarnet: false,
    );
  }
}

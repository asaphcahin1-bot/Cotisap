/// Réduction du nombre de parts reconnues d'un membre pour cause
/// d'amende(s) non soldée(s) au moment du partage — voir DECISIONS.md,
/// "Les amendes ne sont plus une dette" (2026-08-09).
///
/// Remplace l'ancien traitement (amende comptée comme une dette,
/// déduite du montant net, plafonnée à 0, perte AVEC possible) : si un
/// membre paie son amende cash, rien ne change (elle rejoint la caisse
/// comme avant). Si elle reste impayée jusqu'à la clôture du cycle,
/// elle est automatiquement déduite de sa cotisation, avec un exemple
/// donné par le fondateur : cotisé 10 000 F (10 parts), amende de 200 F
/// impayée -> reste 9 800 F -> seulement **9 parts** génèrent une part
/// du bénéfice collectif, les 800 F restants lui reviennent tels quels
/// sans bénéfice dessus, et les 200 F rejoignent la caisse commune
/// exactement comme si l'amende avait été payée cash.
///
/// Pure Dart, aucune dépendance à la base — testable directement, comme
/// [EndOfCycleCalculator].
library;

class AmendeReductionResult {
  /// Parts qui génèrent une part du bénéfice collectif — toujours
  /// inférieur ou égal au nombre de parts brutes du membre.
  final int partsReconnues;

  /// Ce qui reste après les parts reconnues (toujours strictement
  /// inférieur à la valeur d'une part) — rendu tel quel au membre, sans
  /// aucune part du bénéfice collectif dessus.
  final int residuFcfa;

  /// = min(rawCotisationFcfa, amendesNonSoldeesFcfa) — ce que sa
  /// cotisation a réellement pu couvrir. Jamais plus que sa cotisation
  /// (les amendes ne sont jamais une dette — voir DECISIONS.md :
  /// l'éventuel excédent n'est simplement pas recouvré, sans perte
  /// enregistrée nulle part).
  final int montantEffectivementDeduitFcfa;

  const AmendeReductionResult({
    required this.partsReconnues,
    required this.residuFcfa,
    required this.montantEffectivementDeduitFcfa,
  });
}

class AmendeReductionCalculator {
  const AmendeReductionCalculator();

  AmendeReductionResult calculer({
    required int rawCotisationFcfa,
    required int amendesNonSoldeesFcfa,
    required int valeurPartFcfa,
  }) {
    if (rawCotisationFcfa < 0) {
      throw ArgumentError('rawCotisationFcfa ne peut pas être négatif.');
    }
    if (amendesNonSoldeesFcfa < 0) {
      throw ArgumentError('amendesNonSoldeesFcfa ne peut pas être négatif.');
    }
    if (valeurPartFcfa <= 0) {
      throw ArgumentError('valeurPartFcfa doit être positif.');
    }

    final montantDeduit = amendesNonSoldeesFcfa < rawCotisationFcfa
        ? amendesNonSoldeesFcfa
        : rawCotisationFcfa;
    final reste = rawCotisationFcfa - montantDeduit;
    final partsReconnues = reste ~/ valeurPartFcfa;
    final residu = reste - partsReconnues * valeurPartFcfa;

    return AmendeReductionResult(
      partsReconnues: partsReconnues,
      residuFcfa: residu,
      montantEffectivementDeduitFcfa: montantDeduit,
    );
  }
}

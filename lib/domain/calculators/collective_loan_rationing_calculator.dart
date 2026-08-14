/// Rationnement collectif des crédits — voir DECISIONS.md, "Rationnement
/// collectif des crédits" (RETOURS_TERRAIN.md, point 13) : quand
/// plusieurs membres demandent un prêt au même moment et que le total
/// dépasse la caisse disponible, chacun reçoit une offre proportionnelle
/// à sa demande plutôt qu'un simple "premier arrivé, premier servi".
///
/// **Redistribution immédiate** (décision explicite du fondateur) : dès
/// qu'un demandeur accepte ou se désiste, la part proposée aux suivants
/// est recalculée avec la caisse et le total encore demandé —
/// [allocationProposeeFcfa] doit donc être rappelée à chaque étape avec
/// la liste des demandes **encore en attente** à cet instant précis,
/// jamais une répartition figée calculée une seule fois pour tout le
/// lot.
///
/// Pure Dart, aucune dépendance à la base — testable directement,
/// comme [LoanRateResolver].
class CollectiveLoanRationingCalculator {
  const CollectiveLoanRationingCalculator();

  /// Montant à proposer à la **première** entrée de
  /// [montantsDemandesEnAttenteFcfa] (ordre FIFO — c'est celle qu'on
  /// traite maintenant, les suivantes sont juste là pour calculer le
  /// total encore demandé), compte tenu de la caisse encore disponible
  /// à cet instant.
  ///
  /// - Si le total de **toutes** les demandes en attente (elle
  ///   incluse) tient dans la caisse, elle est proposée intégralement.
  /// - Sinon, proposée au prorata de sa part du total demandé :
  ///   `montant × caisse ÷ total`, arrondi à l'entier inférieur — ne
  ///   dépasse jamais la caisse réelle par arrondi.
  int allocationProposeeFcfa({
    required List<int> montantsDemandesEnAttenteFcfa,
    required int caisseDisponibleFcfa,
  }) {
    if (montantsDemandesEnAttenteFcfa.isEmpty) return 0;
    final montant = montantsDemandesEnAttenteFcfa.first;
    if (montant <= 0) {
      throw ArgumentError('Le montant demandé doit être positif.');
    }
    if (caisseDisponibleFcfa <= 0) return 0;

    final total = montantsDemandesEnAttenteFcfa.fold<int>(0, (a, b) => a + b);
    if (total <= caisseDisponibleFcfa) return montant;
    return (montant * caisseDisponibleFcfa / total).floor();
  }
}

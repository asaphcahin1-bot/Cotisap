/// Moteur de calcul de la répartition de fin de cycle.
///
/// Implémente exactement la formule du skill `avec-business-rules` :
/// 1. total_interets_amendes = intérêts perçus sur les prêts + amendes collectées
/// 2. valeur_par_part = total_interets_amendes / total_parts_du_groupe
/// 3. part_individuelle_membre = valeur_par_part * nombre_de_parts_du_membre
/// 4. montant_total_reçu = cotisation_totale_membre (parts × valeur de la part) + part_individuelle_membre
///
/// Vocabulaire : ce fichier garde "part" comme terme technique interne
/// (hérité du skill avec-business-rules). Côté interface, ce même concept
/// s'affiche "carnet" — voir le skill localisation-fr-afrique-ouest. Pour
/// éviter toute confusion avec le second sens de "part" (la part du
/// bénéfice reçue par le membre), ce champ s'appelle ici
/// `beneficeIndividuel` plutôt que `partIndividuelle`.
///
/// Le fonds de solidarité n'apparaît volontairement dans aucun champ de
/// [EndOfCycleInput] : il ne doit jamais entrer dans ce calcul (skill
/// `avec-business-rules`, section "Fonds de solidarité").
///
/// Cette classe est pure (aucune dépendance à la base de données) pour
/// rester testable indépendamment du stockage — voir
/// test/domain/calculators/end_of_cycle_calculator_test.dart.
library;

class MemberParts {
  final String memberId;
  final int totalParts;

  const MemberParts({required this.memberId, required this.totalParts});
}

class EndOfCycleInput {
  /// Parts totales achetées par chaque membre sur le cycle.
  final List<MemberParts> partsByMember;

  /// Valeur d'une part, fixée par le groupe en début de cycle.
  final int partValueFcfa;

  /// Somme des intérêts réellement perçus (prêts confirmés et remboursés
  /// intégralement avant la clôture du cycle). Un prêt non remboursé
  /// entièrement à la clôture ne contribue pas d'intérêt au calcul —
  /// hypothèse retenue faute de règle précisée pour les prêts en défaut
  /// ou partiellement remboursés (voir DECISIONS.md).
  final double totalInterestCollectedFcfa;

  /// Somme des amendes collectées sur le cycle.
  final double totalFinesCollectedFcfa;

  const EndOfCycleInput({
    required this.partsByMember,
    required this.partValueFcfa,
    required this.totalInterestCollectedFcfa,
    required this.totalFinesCollectedFcfa,
  });
}

class MemberCycleResult {
  final String memberId;
  final int totalParts;
  final double cotisationTotale;
  final double beneficeIndividuel;
  final double montantTotalRecu;

  const MemberCycleResult({
    required this.memberId,
    required this.totalParts,
    required this.cotisationTotale,
    required this.beneficeIndividuel,
    required this.montantTotalRecu,
  });
}

class EndOfCycleResult {
  final double totalInteretsAmendes;
  final double valeurParPart;
  final int totalPartsGroupe;
  final List<MemberCycleResult> resultatsParMembre;

  const EndOfCycleResult({
    required this.totalInteretsAmendes,
    required this.valeurParPart,
    required this.totalPartsGroupe,
    required this.resultatsParMembre,
  });
}

class EndOfCycleCalculator {
  const EndOfCycleCalculator();

  EndOfCycleResult calculer(EndOfCycleInput input) {
    if (input.partsByMember.isEmpty) {
      throw ArgumentError('Aucun membre avec des parts pour ce cycle.');
    }

    final totalPartsGroupe = input.partsByMember.fold<int>(
      0,
      (sum, m) => sum + m.totalParts,
    );
    if (totalPartsGroupe <= 0) {
      throw ArgumentError('Le total de parts du groupe doit être positif.');
    }

    final totalInteretsAmendes =
        input.totalInterestCollectedFcfa + input.totalFinesCollectedFcfa;
    final valeurParPart = totalInteretsAmendes / totalPartsGroupe;

    final resultats = input.partsByMember.map((membre) {
      final cotisationTotale =
          (membre.totalParts * input.partValueFcfa).toDouble();
      final beneficeIndividuel = valeurParPart * membre.totalParts;
      return MemberCycleResult(
        memberId: membre.memberId,
        totalParts: membre.totalParts,
        cotisationTotale: cotisationTotale,
        beneficeIndividuel: beneficeIndividuel,
        montantTotalRecu: cotisationTotale + beneficeIndividuel,
      );
    }).toList();

    return EndOfCycleResult(
      totalInteretsAmendes: totalInteretsAmendes,
      valeurParPart: valeurParPart,
      totalPartsGroupe: totalPartsGroupe,
      resultatsParMembre: resultats,
    );
  }
}

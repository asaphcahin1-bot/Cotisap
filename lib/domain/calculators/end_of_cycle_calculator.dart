/// Moteur de calcul de la répartition de fin de cycle — formule "caisse
/// disponible" (voir DECISIONS.md, "Nouvelle formule de partage : caisse
/// disponible", 2026-08-09, remplace l'ancienne formule
/// intérêts+amendes / total_parts).
///
/// 1. `caisse_disponible = cotisations mises en commun (hors résidus,
///    voir [EndOfCycleInput.cotisationsTotalesGroupeFcfa]) + amendes
///    réglées + intérêts perçus (sur les prêts intégralement remboursés)
///    − dettes en cours (capital des prêts pas encore intégralement
///    remboursés, tout le groupe)` — jamais négative (clampée à 0).
/// 2. `valeur_par_part = caisse_disponible / total_parts_du_groupe`
/// 3. Pour chaque membre :
///    - **sans dette de prêt** : montant brut = `valeur_par_part ×
///      ses_parts` (part complète du bénéfice collectif) +
///      [MemberCycleInput.residuSansBonusFcfa] (le résidu d'une
///      éventuelle réduction pour amende non soldée — voir
///      `AmendeReductionCalculator`, DECISIONS.md "Les amendes ne sont
///      plus une dette" : `totalParts` et `residuSansBonusFcfa` sont
///      déjà calculés en amont par l'appelant à partir de sa
///      cotisation brute réduite de ses amendes non soldées) ;
///    - **avec une dette de prêt, quel qu'en soit le montant** :
///      montant brut = **[MemberCycleInput.cotisationTotaleFcfa]
///      exactement** (déjà net de toute réduction pour amende),
///      aucune part du bénéfice collectif en plus. Sa dette est
///      ensuite déduite de ce montant brut plafonné, via
///      [DebtDeductionCalculator] — inchangé, déjà testé séparément.
///
/// **Important** : [MemberCycleInput.detteFcfa] ne représente plus que
/// le solde de prêt confirmé non remboursé — les amendes n'en font
/// plus partie (voir DECISIONS.md). Une amende non soldée influence ce
/// calcul uniquement via `totalParts`/`residuSansBonusFcfa`, jamais via
/// `detteFcfa`.
///
/// Vocabulaire : "part" reste le terme technique interne (skill
/// avec-business-rules) ; côté interface, ce même concept s'affiche
/// "carnet" (skill localisation-fr-afrique-ouest).
///
/// Le fonds de solidarité n'apparaît volontairement dans aucun champ de
/// [EndOfCycleInput] : il ne doit jamais entrer dans ce calcul (skill
/// avec-business-rules, section "Fonds de solidarité").
///
/// Cette classe est pure (aucune dépendance à la base de données) pour
/// rester testable indépendamment du stockage — voir
/// test/domain/calculators/end_of_cycle_calculator_test.dart.
library;

import 'debt_deduction_calculator.dart';

class MemberCycleInput {
  final String memberId;

  /// Parts qui génèrent une part du bénéfice collectif — déjà réduites
  /// en amont si le membre a une amende non soldée (voir
  /// `AmendeReductionCalculator.partsReconnues`).
  final int totalParts;

  /// Ce que ce membre a droit de récupérer au minimum, cotisation
  /// brute déjà réduite de ses amendes non soldées le cas échéant
  /// (`partsReconnues × valeur_de_la_part + résidu`) — son plancher
  /// s'il a une dette de prêt.
  final int cotisationTotaleFcfa;

  /// Solde de prêt confirmé non remboursé — **plus jamais les amendes**
  /// (voir DECISIONS.md, "Les amendes ne sont plus une dette"). Voir
  /// `AppDatabase.detteMembreFcfa`.
  final int detteFcfa;

  /// Résidu d'une réduction pour amende non soldée (voir
  /// `AmendeReductionCalculator.residuFcfa`) — rendu au membre sans
  /// générer de part du bénéfice collectif. 0 si aucune amende non
  /// soldée. Ignoré si le membre a une dette de prêt (auquel cas
  /// [cotisationTotaleFcfa] sert déjà de plafond complet, résidu
  /// inclus).
  final int residuSansBonusFcfa;

  const MemberCycleInput({
    required this.memberId,
    required this.totalParts,
    required this.cotisationTotaleFcfa,
    required this.detteFcfa,
    this.residuSansBonusFcfa = 0,
  });
}

class MemberCycleResult {
  final String memberId;
  final int totalParts;
  final int cotisationTotaleFcfa;

  /// Faux si ce membre avait une dette de prêt au moment du partage —
  /// dans ce cas [montantBrutFcfa] est plafonné à
  /// [cotisationTotaleFcfa], sans aucune part du bénéfice collectif.
  final bool aBeneficieDuBonus;

  /// `valeur_par_part × ses_parts + résidu` s'il n'a pas de dette de
  /// prêt, sinon exactement [cotisationTotaleFcfa] — avant déduction
  /// de la dette.
  final int montantBrutFcfa;

  final int detteFcfa;
  final int montantDeduitFcfa;
  final int montantNetFcfa;
  final int pertAvecFcfa;

  const MemberCycleResult({
    required this.memberId,
    required this.totalParts,
    required this.cotisationTotaleFcfa,
    required this.aBeneficieDuBonus,
    required this.montantBrutFcfa,
    required this.detteFcfa,
    required this.montantDeduitFcfa,
    required this.montantNetFcfa,
    required this.pertAvecFcfa,
  });
}

class EndOfCycleInput {
  final List<MemberCycleInput> membres;

  /// Total mis en commun ("dans le pot") pour générer la valeur de la
  /// part — **exclut tout résidu** ([MemberCycleInput.residuSansBonusFcfa])
  /// même s'il est inclus dans le [MemberCycleInput.cotisationTotaleFcfa]
  /// individuel de chaque membre : le résidu n'entre jamais dans le pot,
  /// il revient tel quel à son membre, financé par sa propre cotisation
  /// (jamais par celle des autres). Donc **`sum(membres.totalParts) ×
  /// valeur_de_la_part`, pas `sum(membres.cotisationTotaleFcfa)`** — ce
  /// dernier inclurait les résidus et gonflerait `valeurParPart` d'un
  /// montant qui serait ensuite reversé une seconde fois (voir
  /// DECISIONS.md, "Les amendes ne sont plus une dette" : l'invariant de
  /// conservation vérifié par les tests est `caisseDisponible +
  /// sum(residuSansBonusFcfa) == sum(cotisationBrute_avant_réduction)`).
  /// Fourni séparément plutôt que recalculé pour rester une classe pure
  /// sans logique de vérification d'invariant côté appelant.
  final int cotisationsTotalesGroupeFcfa;

  /// Amendes réglées (confirmées, non annulées) — jamais les amendes
  /// encore en attente ni annulées, voir DECISIONS.md.
  final int amendesRegleesFcfa;

  /// Intérêts perçus sur les prêts intégralement remboursés avant la
  /// clôture (voir `AppDatabase.totalInteretsPercusDuCycle`, inchangé).
  final double interetsPercusFcfa;

  /// Capital des prêts confirmés pas encore intégralement remboursés,
  /// tout le groupe (voir `AppDatabase.totalPrincipalNonRembourseDuCycle`).
  final int dettesEnCoursGroupeFcfa;

  const EndOfCycleInput({
    required this.membres,
    required this.cotisationsTotalesGroupeFcfa,
    required this.amendesRegleesFcfa,
    required this.interetsPercusFcfa,
    required this.dettesEnCoursGroupeFcfa,
  });
}

class EndOfCycleResult {
  final int caisseDisponibleFcfa;
  final double valeurParPart;
  final int totalPartsGroupe;
  final List<MemberCycleResult> resultatsParMembre;

  const EndOfCycleResult({
    required this.caisseDisponibleFcfa,
    required this.valeurParPart,
    required this.totalPartsGroupe,
    required this.resultatsParMembre,
  });
}

class EndOfCycleCalculator {
  const EndOfCycleCalculator();

  EndOfCycleResult calculer(EndOfCycleInput input) {
    if (input.membres.isEmpty) {
      throw ArgumentError('Aucun membre avec des parts pour ce cycle.');
    }
    if (input.cotisationsTotalesGroupeFcfa < 0) {
      throw ArgumentError(
        'cotisationsTotalesGroupeFcfa ne peut pas être négatif.',
      );
    }
    if (input.amendesRegleesFcfa < 0) {
      throw ArgumentError('amendesRegleesFcfa ne peut pas être négatif.');
    }
    if (input.interetsPercusFcfa < 0) {
      throw ArgumentError('interetsPercusFcfa ne peut pas être négatif.');
    }
    if (input.dettesEnCoursGroupeFcfa < 0) {
      throw ArgumentError('dettesEnCoursGroupeFcfa ne peut pas être négatif.');
    }

    final totalPartsGroupe = input.membres.fold<int>(
      0,
      (sum, m) => sum + m.totalParts,
    );
    if (totalPartsGroupe <= 0) {
      throw ArgumentError('Le total de parts du groupe doit être positif.');
    }

    final caisseBrute =
        input.cotisationsTotalesGroupeFcfa +
        input.amendesRegleesFcfa +
        input.interetsPercusFcfa -
        input.dettesEnCoursGroupeFcfa;
    // Jamais négative : un groupe dont les prêts non remboursés
    // dépassent le reste de la caisse ne "doit" rien à personne
    // au-delà de ce qu'il a réellement (même principe que
    // LoanBalanceCalculator, "le solde dû ne descend jamais sous zéro").
    final caisseDisponible = caisseBrute <= 0 ? 0 : caisseBrute.round();
    final valeurParPart = caisseDisponible / totalPartsGroupe;

    final resultats = input.membres.map((m) {
      if (m.totalParts < 0) {
        throw ArgumentError(
          'totalParts ne peut pas être négatif (membre ${m.memberId}).',
        );
      }
      if (m.cotisationTotaleFcfa < 0) {
        throw ArgumentError(
          'cotisationTotaleFcfa ne peut pas être négatif (membre ${m.memberId}).',
        );
      }
      if (m.detteFcfa < 0) {
        throw ArgumentError(
          'detteFcfa ne peut pas être négatif (membre ${m.memberId}).',
        );
      }
      if (m.residuSansBonusFcfa < 0) {
        throw ArgumentError(
          'residuSansBonusFcfa ne peut pas être négatif (membre ${m.memberId}).',
        );
      }

      final aDette = m.detteFcfa > 0;
      final montantBrut = aDette
          ? m.cotisationTotaleFcfa
          : (valeurParPart * m.totalParts).round() + m.residuSansBonusFcfa;
      final deduction = const DebtDeductionCalculator().calculer(
        montantBrutFcfa: montantBrut,
        detteFcfa: m.detteFcfa,
      );
      return MemberCycleResult(
        memberId: m.memberId,
        totalParts: m.totalParts,
        cotisationTotaleFcfa: m.cotisationTotaleFcfa,
        aBeneficieDuBonus: !aDette,
        montantBrutFcfa: montantBrut,
        detteFcfa: m.detteFcfa,
        montantDeduitFcfa: deduction.montantDeduitFcfa,
        montantNetFcfa: deduction.montantNetFcfa,
        pertAvecFcfa: deduction.pertAvecFcfa,
      );
    }).toList();

    return EndOfCycleResult(
      caisseDisponibleFcfa: caisseDisponible,
      valeurParPart: valeurParPart,
      totalPartsGroupe: totalPartsGroupe,
      resultatsParMembre: resultats,
    );
  }
}

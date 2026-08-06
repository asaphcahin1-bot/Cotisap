import '../local/database.dart';
import '../../domain/import/historical_import_parser.dart';

/// Orchestre l'écriture en base des lignes déjà analysées par
/// [HistoricalImportParser]. Le parseur reste pur (aucune dépendance à
/// drift) — cette classe fait le pont avec [AppDatabase].
class HistoricalImportService {
  final AppDatabase database;

  HistoricalImportService(this.database);

  /// Vérifie que chaque nom de membre du CSV correspond bien à un membre
  /// déjà créé dans le groupe (correspondance exacte, insensible à la
  /// casse). On ne crée jamais de membre automatiquement depuis un CSV :
  /// un membre nécessite un numéro de téléphone (skill
  /// two-tier-access-model), que le format d'import de ce skill ne
  /// fournit pas.
  Map<String, Member> resoudreMembres(
    Set<String> nomsCsv,
    List<Member> membresDuGroupe,
  ) {
    final parNomNormalise = {
      for (final m in membresDuGroupe) m.fullName.trim().toLowerCase(): m,
    };
    final resolus = <String, Member>{};
    for (final nom in nomsCsv) {
      final membre = parNomNormalise[nom.trim().toLowerCase()];
      if (membre != null) {
        resolus[nom] = membre;
      }
    }
    return resolus;
  }

  List<String> nomsIntrouvables(Set<String> nomsCsv, Map<String, Member> resolus) {
    return nomsCsv.where((n) => !resolus.containsKey(n)).toList()..sort();
  }

  /// Écrit toutes les lignes valides en base, avec `provenance = 'importe'`.
  ///
  /// Traitement dans l'ordre chronologique : un remboursement ne peut
  /// être rattaché qu'à un prêt importé précédemment dans le même lot
  /// (le format CSV du skill historical-data-import ne référence pas
  /// explicitement un prêt — voir DECISIONS.md pour cette limite connue).
  /// Une ligne de remboursement sans prêt importé disponible est
  /// signalée dans `avertissements` plutôt qu'ignorée silencieusement.
  Future<HistoricalImportOutcome> executer({
    required String groupId,
    required String cycleId,
    required List<LigneImportAnalysee> lignes,
    required Map<String, Member> membresResolus,
    required int partValueFcfa,
    required double interestRatePercent,
    required String confirmedByPhone,
  }) async {
    final lignesTriees = [...lignes]..sort((a, b) => a.date.compareTo(b.date));
    final avertissements = <String>[];
    final pretsImportesParMembre = <String, List<_PretEnCours>>{};
    var nbEcritures = 0;

    for (final ligne in lignesTriees) {
      final membre = membresResolus[ligne.nomMembre];
      if (membre == null) continue; // déjà bloqué en amont par nomsIntrouvables

      switch (ligne.type) {
        case TypeOperationImportee.cotisation:
          final parts = (ligne.montantFcfa / partValueFcfa).round().clamp(1, 999999);
          await database.enregistrerCotisationCash(
            groupId: groupId,
            cycleId: cycleId,
            memberId: membre.id,
            partsCount: parts,
            recordedByPhone: confirmedByPhone,
            provenance: 'importe',
            estApproximatif: ligne.estApproximatif || (parts * partValueFcfa != ligne.montantFcfa),
            recordedAt: ligne.date,
          );
          nbEcritures++;
          break;

        case TypeOperationImportee.pret:
          final resultat = await database.enregistrerPret(
            groupId: groupId,
            cycleId: cycleId,
            memberId: membre.id,
            principalFcfa: ligne.montantFcfa,
            interestRatePercent: interestRatePercent,
            initiatedByPhone: confirmedByPhone,
            confirmationCode: 'importe',
            provenance: 'importe',
            estApproximatif: ligne.estApproximatif,
            createdAt: ligne.date,
          );
          final montantDu = ligne.montantFcfa + (ligne.montantFcfa * interestRatePercent / 100);
          pretsImportesParMembre.putIfAbsent(ligne.nomMembre, () => []).add(
                _PretEnCours(pretId: resultat.pretId, montantDu: montantDu),
              );
          nbEcritures++;
          break;

        case TypeOperationImportee.remboursement:
          final pretsMembre = pretsImportesParMembre[ligne.nomMembre];
          final pretOuvert = pretsMembre?.firstWhere(
            (p) => p.dejaRembourse < p.montantDu,
            orElse: () => _PretEnCours.aucun,
          );
          if (pretOuvert == null || identical(pretOuvert, _PretEnCours.aucun)) {
            avertissements.add(
              'Ligne ${ligne.numeroLigne} : remboursement de ${ligne.montantFcfa} FCFA pour '
              '${ligne.nomMembre} ignoré — aucun prêt importé correspondant trouvé avant cette date.',
            );
            continue;
          }
          await database.enregistrerRemboursement(
            pretId: pretOuvert.pretId,
            montantFcfa: ligne.montantFcfa,
            recordedByPhone: confirmedByPhone,
            provenance: 'importe',
            estApproximatif: ligne.estApproximatif,
            recordedAt: ligne.date,
          );
          pretOuvert.dejaRembourse += ligne.montantFcfa;
          nbEcritures++;
          break;

        case TypeOperationImportee.amende:
          await database.enregistrerAmende(
            groupId: groupId,
            cycleId: cycleId,
            memberId: membre.id,
            montantFcfa: ligne.montantFcfa,
            motif: 'Amende importée',
            recordedByPhone: confirmedByPhone,
            provenance: 'importe',
            estApproximatif: ligne.estApproximatif,
            recordedAt: ligne.date,
          );
          nbEcritures++;
          break;

        case TypeOperationImportee.fondsSolidarite:
          await database.enregistrerContributionFondsSolidarite(
            groupId: groupId,
            cycleId: cycleId,
            memberId: membre.id,
            montantFcfa: ligne.montantFcfa,
            motif: 'Contribution importée',
            recordedByPhone: confirmedByPhone,
            provenance: 'importe',
            estApproximatif: ligne.estApproximatif,
            recordedAt: ligne.date,
          );
          nbEcritures++;
          break;
      }
    }

    return HistoricalImportOutcome(
      nbEcritures: nbEcritures,
      avertissements: avertissements,
    );
  }
}

class _PretEnCours {
  static final aucun = _PretEnCours(pretId: '', montantDu: 0);

  final String pretId;
  final double montantDu;
  double dejaRembourse = 0;

  _PretEnCours({required this.pretId, required this.montantDu});
}

class HistoricalImportOutcome {
  final int nbEcritures;
  final List<String> avertissements;

  const HistoricalImportOutcome({
    required this.nbEcritures,
    required this.avertissements,
  });
}

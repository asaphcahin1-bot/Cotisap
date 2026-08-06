import 'package:drift/drift.dart';

/// Colonnes communes à toutes les tables financières en ajout seul.
///
/// [previousHash] référence le hash de la dernière ligne insérée dans la
/// même table au moment de l'écriture (null pour la toute première ligne).
/// [hash] est calculé une fois par `HashChain.compute()` dans la couche
/// base de données et n'est jamais recalculé ni modifié après coup.
mixin HashChainColumns on Table {
  TextColumn get previousHash => text().nullable()();
  TextColumn get hash => text()();
}

/// Colonnes communes aux tables financières qui peuvent recevoir de
/// l'historique importé (skill historical-data-import), en plus des
/// écritures créées directement par l'app.
mixin ProvenanceColumns on Table {
  /// `direct` = créé et vérifié en temps réel via l'app.
  /// `importe` = déclaré rétroactivement (carnet papier, CSV) au moment
  /// où un groupe bascule vers CotisApp. Jamais fusionné avec `direct`
  /// dans le même champ — reste distinguable pour un audit ou un litige.
  TextColumn get provenance => text().withDefault(const Constant('direct'))();

  /// Le carnet papier d'origine n'a pas toujours une date ou un montant
  /// exacts. Ce champ marque une ligne importée dont la précision n'est
  /// pas garantie, plutôt que de forcer une précision que la source
  /// n'avait pas.
  BoolColumn get estApproximatif =>
      boolean().withDefault(const Constant(false))();
}

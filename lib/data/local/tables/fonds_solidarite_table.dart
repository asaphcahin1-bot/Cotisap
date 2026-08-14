import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Une contribution au fonds de solidarité. Caisse séparée, à but
/// social — n'est JAMAIS lue par le calculateur de fin de cycle (skill
/// avec-business-rules : "ne jamais faire transiter ce fonds par la
/// même colonne de données que les parts de cotisation"). [memberId]
/// est nullable : une contribution peut être une décision collective du
/// groupe plutôt qu'un versement individuel.
class FondsSolidariteContributions extends Table with HashChainColumns, ProvenanceColumns {
  @override
  String get tableName => 'fonds_solidarite_contributions';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().nullable().references(Members, #id)();
  IntColumn get montantFcfa => integer()();
  TextColumn get motif => text()();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Renseigné quand cette contribution règle (en partie ou en
  /// totalité) une cotisation exceptionnelle précise — voir
  /// [CotisationsExceptionnelles] et DECISIONS.md, "Cotisations
  /// exceptionnelles". `null` pour une contribution "ordinaire" (fonds
  /// obligatoire récurrent, ou libre).
  TextColumn get cotisationExceptionnelleId =>
      text().nullable().references(CotisationsExceptionnelles, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Une cotisation exceptionnelle (mariage, décès, accouchement...) —
/// voir DECISIONS.md, "Cotisations exceptionnelles" : déclarée une
/// seule fois par l'agent (motif + montant + date limite), s'applique
/// **automatiquement à tous les membres déjà présents dans le groupe**
/// au moment de la déclaration (jamais aux membres qui rejoignent
/// après — même principe que [Members.joinedAt] pour les échéances de
/// cotisation). Chaque membre doit ce même montant, réglable à tout
/// moment avant la date limite ; passé ce délai, le solde restant est
/// automatiquement déduit de ses parts à la clôture du cycle (voir
/// [AppDatabase.preparerPartageCycle]) — jamais avant, jamais une
/// dette qui s'accumule.
///
/// Table financière en ajout seul pour l'événement lui-même (comme
/// [Amendes]) — mais `motif`/`montantFcfa`/`dateLimite` restent
/// modifiables ensuite (voir [AppDatabase.modifierCotisationExceptionnelle],
/// RETOURS_TERRAIN.md) : c'est une définition, pas un mouvement
/// d'argent. Les paiements réels contre elle
/// ([FondsSolidariteContributions]) sont, eux, définitivement
/// intouchables.
class CotisationsExceptionnelles extends Table with HashChainColumns {
  @override
  String get tableName => 'cotisations_exceptionnelles';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get motif => text()();
  IntColumn get montantFcfa => integer()();
  DateTimeColumn get dateLimite => dateTime()();
  TextColumn get createdByPhone => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

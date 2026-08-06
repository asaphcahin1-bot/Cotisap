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

  @override
  Set<Column> get primaryKey => {id};
}

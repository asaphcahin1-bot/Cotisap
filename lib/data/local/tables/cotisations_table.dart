import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Une ligne de cotisation (achat de parts). [source] ne prend que deux
/// valeurs (skill avec-business-rules) : `cash` (saisie par l'agent en
/// réunion) ou `distance` (paiement à distance — hors périmètre de cette
/// étape, jamais écrit par le code actuel, mais le champ existe déjà
/// pour que le calculateur de fin de cycle reste correct sans
/// distinction de traitement le jour où la V1 paiement sera branchée).
///
/// En ajout seul : aucune cotisation confirmée en réunion n'est modifiée
/// après coup.
class Cotisations extends Table with HashChainColumns, ProvenanceColumns {
  @override
  String get tableName => 'cotisations';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get partsCount => integer()();
  TextColumn get source => text().withDefault(const Constant('cash'))();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

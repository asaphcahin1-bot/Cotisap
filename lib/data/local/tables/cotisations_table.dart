import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Une ligne de cotisation (dépôt de parts dans UN carnet précis —
/// [carnetNumero], 1 ou 2). [source] ne prend que deux valeurs (skill
/// avec-business-rules) : `cash` (saisie par l'agent en réunion) ou
/// `distance` (paiement à distance — hors périmètre de cette étape,
/// jamais écrit par le code actuel, mais le champ existe déjà pour que
/// le calculateur de fin de cycle reste correct sans distinction de
/// traitement le jour où la V1 paiement sera branchée).
///
/// [partsCount] est le nombre de parts déposées dans ce carnet par
/// cette transaction précise. Le cumul du jour pour un même carnet ne
/// peut jamais dépasser 5 parts (voir DECISIONS.md, "Plafond de 5
/// parts par carnet et par jour") ; une échéance manquée n'est en
/// revanche jamais rattrapable (voir "Amende seule, jamais de
/// rattrapage") — ce nombre varie seulement selon ce que le membre
/// choisit de déposer ce jour-là.
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

  /// 1 ou 2 — quel carnet du membre cette cotisation concerne. Toujours
  /// 1 pour un import historique (skill historical-data-import ne
  /// distingue pas les carnets).
  IntColumn get carnetNumero => integer().withDefault(const Constant(1))();

  IntColumn get partsCount => integer()();
  TextColumn get source => text().withDefault(const Constant('cash'))();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Date de l'échéance (journée de cotisation) à laquelle cette
  /// transaction se rattache — distincte de [recordedAt] (l'horodatage
  /// réel/simulé de la saisie, qui peut différer si l'agent saisit une
  /// journée en retard). Sert de base au plafond cumulatif journalier
  /// ([AppDatabase.partsDejaAjouteesAujourdhui]) : additionner par
  /// [recordedAt] mélangerait des échéances différentes saisies le même
  /// jour réel, et raterait plusieurs transactions pour la même échéance
  /// saisies à des instants réels différents. Nullable pour les lignes
  /// importées avant l'ajout de cette colonne (voir DECISIONS.md).
  DateTimeColumn get echeanceDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

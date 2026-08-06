import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Une amende collectée pendant le cycle (ex. absence non justifiée,
/// retard). Contribue au calcul de fin de cycle au même titre que les
/// intérêts de prêts (skill avec-business-rules, étape 1 de la formule).
class Amendes extends Table with HashChainColumns, ProvenanceColumns {
  @override
  String get tableName => 'amendes';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get montantFcfa => integer()();
  TextColumn get motif => text()();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Vrai si créée automatiquement pour une échéance manquée (skill
  /// avec-business-rules, section "Retard de cotisation"), plutôt que
  /// saisie librement par l'agent. Sert à cibler les amendes proposées à
  /// la revue de l'agent à la séance suivante — voir
  /// [AppDatabase.amendesEnAttenteRevue].
  BoolColumn get estAutoGeneree => boolean().withDefault(const Constant(false))();

  /// Renseigné quand l'agent a explicitement confirmé une amende
  /// auto-générée à la séance de revue — évite qu'elle réapparaisse
  /// indéfiniment dans la liste à revoir une fois traitée.
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Annulation d'une amende (erreur d'enregistrement — le membre avait en
/// réalité payé, voir DECISIONS.md) — toujours une nouvelle ligne qui
/// référence l'amende d'origine, jamais une suppression ni une
/// modification directe.
class AmendeAnnulations extends Table with HashChainColumns {
  @override
  String get tableName => 'amende_annulations';

  TextColumn get id => text()();
  TextColumn get amendeId => text().references(Amendes, #id)();
  TextColumn get raison => text()();
  TextColumn get annuleParPhone => text()();
  DateTimeColumn get annuleAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

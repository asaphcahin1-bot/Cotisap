import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';

/// Une affectation de rôle sur un groupe : soit un rôle du comité de
/// gestion (presidente | secretaire | tresoriere | compteuse), soit le
/// rôle applicatif "agent" qui porte l'accès complet dans le modèle à
/// deux niveaux (skill two-tier-access-model). Une même personne peut
/// avoir plusieurs lignes de rôle.
///
/// En ajout seul : changer d'agent entre deux cycles ne modifie jamais
/// une ligne existante, ça ajoute une révocation (voir
/// [AgentAssignmentRevocations]) puis une nouvelle affectation.
class AgentAssignments extends Table with HashChainColumns {
  @override
  String get tableName => 'agent_assignments';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get memberId => text().nullable().references(Members, #id)();
  TextColumn get phoneNumber => text()();
  TextColumn get role => text()();
  DateTimeColumn get assignedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Une affectation est considérée active tant qu'aucune révocation ne la
/// référence — jamais de suppression ni de modification de la ligne
/// d'affectation d'origine.
class AgentAssignmentRevocations extends Table with HashChainColumns {
  @override
  String get tableName => 'agent_assignment_revocations';

  TextColumn get id => text()();
  TextColumn get assignmentId => text().references(AgentAssignments, #id)();
  DateTimeColumn get revokedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

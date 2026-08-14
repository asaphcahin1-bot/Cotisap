import 'package:drift/drift.dart';

import 'groups_table.dart';

/// Un cycle de 9 à 12 mois pour un groupe. La valeur de la part et le
/// taux d'intérêt sont figés au début du cycle (skill avec-business-rules)
/// et ne changent pas en cours de route même si le groupe modifie ses
/// paramètres par défaut pour le cycle suivant.
class Cycles extends Table {
  @override
  String get tableName => 'cycles';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  IntColumn get cycleNumber => integer()();
  DateTimeColumn get startedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get partValueFcfa => integer()();
  RealColumn get interestRatePercent => real()();

  /// Amende automatique suggérée pour un membre en retard de cotisation
  /// sur une période (skill avec-business-rules, section "Retard de
  /// cotisation") — fixée à la création du cycle, comme la valeur du
  /// carnet et le taux d'intérêt. 0 = pas d'amende de retard pour ce
  /// groupe.
  IntColumn get lateFeeFcfa => integer().withDefault(const Constant(0))();

  /// Durée d'une période de prêt, en jours (skill avec-business-rules,
  /// section "Prêts") — fixée à la création du cycle, comme la valeur du
  /// carnet. Si un prêt n'est pas intégralement remboursé à l'échéance,
  /// le même taux d'intérêt se réapplique au solde restant pour une
  /// nouvelle période de même durée, et ainsi de suite (voir
  /// LoanBalanceCalculator).
  IntColumn get loanDurationDays => integer().withDefault(const Constant(90))();

  /// en_cours | cloture
  TextColumn get status => text().withDefault(const Constant('en_cours'))();

  /// Renseigné dès que la toute première journée de cotisation du cycle
  /// est clôturée ([AppDatabase.cloturerJourneeCotisation]) — à partir de
  /// là, plus aucun membre ne peut être ajouté à ce cycle (voir
  /// DECISIONS.md, "Clôture de la journée de cotisation"). Null tant que
  /// la liste des participants reste ouverte.
  DateTimeColumn get inscriptionsFermeesAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

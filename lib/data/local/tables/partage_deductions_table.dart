import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Trace, pour chaque membre, la déduction de dette appliquée au moment
/// du partage de fin de cycle (règle métier précisée par le fondateur,
/// voir DECISIONS.md — "Déduction des dettes au partage").
///
/// Une ligne par membre, écrite une seule fois, au moment où
/// [AppDatabase.cloturerCycleEtOuvrirSuivant] clôture effectivement le
/// cycle — jamais à la simple prévisualisation de l'écran de
/// répartition, qui peut être consultée plusieurs fois avant la
/// clôture réelle. En ajout seul comme le reste des tables financières :
/// une fois écrite, cette ligne fait foi que la dette du membre pour ce
/// cycle a été régularisée (déduite ou perdue), elle ne doit jamais être
/// recomptée pour un cycle suivant.
class PartageDeductions extends Table with HashChainColumns {
  @override
  String get tableName => 'partage_deductions';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();

  /// Montant brut que le membre aurait dû percevoir avant déduction
  /// (cotisation totale + bénéfice individuel — voir
  /// EndOfCycleCalculator).
  IntColumn get montantBrutFcfa => integer()();

  /// Dette totale au moment du partage : arriéré de cotisation non
  /// rattrapé + amendes non soldées + solde de prêt non remboursé.
  IntColumn get detteFcfa => integer()();

  /// min(montantBrutFcfa, detteFcfa).
  IntColumn get montantDeduitFcfa => integer()();

  /// montantBrutFcfa - montantDeduitFcfa (jamais négatif).
  IntColumn get montantNetFcfa => integer()();

  /// detteFcfa - montantDeduitFcfa : partie de la dette que le montant à
  /// percevoir ne suffisait pas à couvrir, enregistrée comme perte pour
  /// l'AVEC (0 si la dette a été intégralement couverte).
  IntColumn get pertAvecFcfa => integer().withDefault(const Constant(0))();

  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

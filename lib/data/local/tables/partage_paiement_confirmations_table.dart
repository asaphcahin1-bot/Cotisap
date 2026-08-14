import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Confirmation explicite, par membre, qu'il a bien reçu son paiement de
/// fin de cycle — voir DECISIONS.md, "Clôture de cycle conditionnée au
/// paiement de tous les membres". Condition de clôture d'un cycle : voir
/// [AppDatabase.cloturerCycleEtOuvrirSuivant].
///
/// Table de configuration/workflow (comme [CarnetsEngages]), pas
/// financière : une case cochée par erreur avant la clôture doit
/// pouvoir être décochée librement (voir
/// [AppDatabase.annulerConfirmationPaiementMembre]). Une fois le cycle
/// clos, ces lignes ne sont plus jamais modifiées ni supprimées — figées
/// dans l'historique au même titre que le reste du cycle, simplement
/// parce que l'écran ne les rend plus modifiables pour un cycle clos.
class PartagePaiementConfirmations extends Table {
  @override
  String get tableName => 'partage_paiement_confirmations';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  DateTimeColumn get confirmedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get confirmedByPhone => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {cycleId, memberId},
  ];
}

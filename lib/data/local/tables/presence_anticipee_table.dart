import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Présence anticipée par carnet, saisie par l'agent depuis l'écran
/// "Séance du jour" (voir RETOURS_TERRAIN.md, point 6) **pendant** la
/// journée de cotisation, membre par membre — avant la clôture
/// officielle. Purement une intention/un brouillon : ne crée ni amende
/// ni échéance à elle seule. [AppDatabase.cloturerJourneeCotisation] la
/// relit comme valeur par défaut de `resolutions` pour chaque carnet
/// encore "à traiter" (voir [AppDatabase.clefResolutionCarnet]), au lieu
/// de retomber systématiquement sur "Absence" — l'agent garde la main
/// pour corriger avant de valider la clôture.
///
/// Table de configuration/workflow (comme [CarnetsEngages]), pas
/// financière/hash-chaînée — une ligne par (cycle, membre, carnet,
/// date), librement réécrite tant que la journée n'est pas clôturée.
/// Nettoyée automatiquement par [AppDatabase.cloturerJourneeCotisation]
/// une fois la journée close (n'a plus aucun sens ensuite).
class PresenceAnticipee extends Table {
  @override
  String get tableName => 'presence_anticipee';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get carnetNumero => integer()();
  DateTimeColumn get echeanceDate => dateTime()();
  TextColumn get codeSysteme => text()();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {cycleId, memberId, carnetNumero, echeanceDate},
      ];
}

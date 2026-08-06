import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// L'engagement d'un membre pour un cycle donné : combien de carnets il
/// s'engage à payer à chaque échéance (1 à 5). Choisi à l'entrée dans le
/// cycle (inscription du membre, ou ouverture d'un nouveau cycle pour un
/// membre déjà présent), **définitif dès le premier paiement enregistré
/// pour ce cycle** ([lockedAt] renseigné) — voir DECISIONS.md.
///
/// Une ligne par (membre, cycle) — voir [uniqueKeys]. Ce n'est
/// volontairement pas une table en ajout seul comme les tables
/// financières : avant le premier paiement, corriger un choix n'est pas
/// un enregistrement financier.
class CarnetsEngages extends Table {
  @override
  String get tableName => 'carnets_engages';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get partsCount => integer()();
  DateTimeColumn get lockedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {cycleId, memberId},
      ];
}

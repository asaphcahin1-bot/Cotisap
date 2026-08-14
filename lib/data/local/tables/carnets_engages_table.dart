import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// [nombreCarnets] vaut toujours **1** — un membre a droit à un seul
/// carnet (décision du fondateur, voir DECISIONS.md "Un membre = un
/// seul carnet", qui annule et remplace l'ancienne règle "1 ou 2").
/// Une personne qui détient plusieurs carnets physiques est inscrite
/// comme autant de membres distincts, chacun identifié par son propre
/// nom et numéro de téléphone (uniques par groupe, voir
/// [AppDatabase.nomOuTelephoneDejaUtiliseDansLeGroupe]). La colonne
/// reste un entier (plutôt qu'un booléen) pour compatibilité avec le
/// schéma existant, mais toute autre valeur que 1 est refusée par
/// [AppDatabase.definirCarnetsEngages].
///
/// Choisi à l'entrée dans le cycle, **définitif dès le premier paiement
/// enregistré pour ce cycle** ([lockedAt] renseigné) — voir DECISIONS.md.
/// Contrairement à l'ancien modèle, ce nombre ne multiplie plus rien :
/// chaque carnet suit ensuite ses propres échéances et son propre
/// arriéré indépendamment (voir [Echeances], [Cotisations]) — le nombre
/// de parts déposées à chaque cotisation est libre (1 à 5, minimum 1),
/// pas fixé ici.
///
/// Une ligne par (membre, cycle). Ce n'est volontairement pas une table
/// en ajout seul comme les tables financières : avant le premier
/// paiement, corriger un choix n'est pas un enregistrement financier.
class CarnetsEngages extends Table {
  @override
  String get tableName => 'carnets_engages';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get nombreCarnets => integer()();
  DateTimeColumn get lockedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {cycleId, memberId},
      ];
}

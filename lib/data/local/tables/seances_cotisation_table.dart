import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'cycles_table.dart';

/// Clôture explicite d'une journée de cotisation par l'agent — décision
/// prise avec le fondateur (voir DECISIONS.md, "Clôture de la journée de
/// cotisation") : ce n'est plus l'horloge du téléphone qui décide en
/// silence qu'une échéance est close, c'est un geste explicite de
/// l'agent, à la fin de la réunion. C'est ce geste qui :
/// 1. fige définitivement qui a payé et qui est absent pour cette date
///    (écrit les lignes [Echeances] `non_paye` restantes) ;
/// 2. si c'est la toute première séance du cycle, trace la date
///    (`Cycles.inscriptionsFermeesAt`, purement informatif — ne ferme
///    plus les inscriptions, voir DECISIONS.md, "Inscription de
///    nouveaux membres : sans limite, sauf fin de cycle").
///
/// **Définitif, sans mécanisme d'annulation** (voir DECISIONS.md,
/// "Suppression d'Annuler la clôture", 2026-08-13) : une clôture faite
/// par erreur n'est plus rattrapable, contrairement à l'ancien
/// comportement (`annulerClotureJournee`, retiré) qui la permettait
/// tant que rien ne s'était passé depuis — l'agent doit être certain
/// avant de clôturer.
class SeancesCotisation extends Table with HashChainColumns {
  @override
  String get tableName => 'seances_cotisation';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get clotureeParPhone => text()();
  DateTimeColumn get clotureeAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {cycleId, date},
      ];
}

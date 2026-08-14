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
/// Contrairement aux tables financières, une clôture faite par erreur
/// peut être **supprimée directement** — même principe que
/// `annulerClotureCycle` pour un cycle — mais uniquement si rien ne
/// s'est passé depuis (aucune cotisation enregistrée après ce moment) :
/// voir `AppDatabase.annulerClotureJournee`. Pas de risque d'intégrité à
/// protéger tant que cette condition tient, donc pas besoin d'une table
/// d'annulation séparée comme pour les amendes/prêts.
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

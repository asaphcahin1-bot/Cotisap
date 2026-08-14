import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';
import 'cotisations_table.dart';
import 'amendes_table.dart';

/// Registre d'échéances : une ligne par membre, par **carnet**
/// ([carnetNumero], 1 ou 2 — chaque carnet suit ses échéances
/// indépendamment, voir DECISIONS.md) et par échéance (date de
/// paiement), qu'elle soit payée ou non. C'est ce qui permet
/// l'historique des cotisations groupé par date avec un statut
/// Payé/Non payé.
///
/// **Pas de rattrapage** (décision du fondateur, 2026-08-09) : une
/// échéance non couverte à la clôture de la journée reste
/// définitivement à 0 part — seule l'amende prédéfinie s'applique,
/// aucun mécanisme ne permet de la rattraper plus tard. En
/// contrepartie, un carnet peut recevoir **1 à 5 parts en une seule
/// journée** ([partsPayees]) — pas parce que le membre rattrape des
/// semaines manquées, mais parce qu'il choisit de déposer plus qu'une
/// part ce jour-là (règle confirmée par un responsable de terrain).
/// Plusieurs transactions le même jour pour le même carnet
/// s'additionnent (voir [AppDatabase.partsDejaAjouteesAujourdhui]),
/// jamais au-delà de 5 au total.
///
/// En ajout seul comme le reste des tables financières : une échéance
/// d'abord enregistrée `non_paye` (à la clôture de la journée de
/// cotisation — voir [AppDatabase.cloturerJourneeCotisation]) ou une
/// ligne `paye` complétée par une transaction supplémentaire le même
/// jour n'est jamais corrigée sur place — une **nouvelle** ligne est
/// toujours écrite. La lecture retient toujours la ligne la plus
/// récente pour un triplet (membre, carnet, date d'échéance).
class Echeances extends Table with HashChainColumns {
  @override
  String get tableName => 'echeances';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get carnetNumero => integer().withDefault(const Constant(1))();
  DateTimeColumn get echeanceDate => dateTime()();

  /// Valeur d'une seule part — sert de référence pour le rythme minimum
  /// attendu (1 part), pas un "montant dû" cumulable : voir la note de
  /// classe, il n'y a plus d'arriéré à calculer.
  IntColumn get montantDuFcfa => integer()();
  IntColumn get montantPayeFcfa => integer().withDefault(const Constant(0))();

  /// Nombre de parts effectivement payées ce jour-là dans ce carnet (0
  /// sur une ligne `non_paye`, 1 à 5 sur une ligne `paye` — cumulé sur
  /// la journée si plusieurs transactions, voir la note de classe).
  IntColumn get partsPayees => integer().withDefault(const Constant(0))();

  /// Vestige de l'ancien modèle avec rattrapage (avant le 2026-08-09) :
  /// toujours 0 désormais, conservé uniquement pour ne pas casser les
  /// lignes déjà écrites avant ce changement.
  IntColumn get arrieresFcfa => integer().withDefault(const Constant(0))();
  IntColumn get amendeFcfa => integer().withDefault(const Constant(0))();

  /// paye | non_paye
  TextColumn get statut => text()();

  TextColumn get cotisationId => text().nullable().references(Cotisations, #id)();
  TextColumn get amendeId => text().nullable().references(Amendes, #id)();

  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

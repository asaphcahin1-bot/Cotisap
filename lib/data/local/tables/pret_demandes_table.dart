import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Une **demande** de prêt — voir DECISIONS.md, "Rationnement collectif
/// des crédits" (RETOURS_TERRAIN.md, point 13) : distincte d'un [Pret]
/// réel, elle capture seulement l'intention d'un membre ("je voudrais
/// X FCFA") sans être immédiatement soumise au plafond de caisse
/// disponible — c'est justement ce qui sera négocié collectivement si
/// plusieurs demandes coexistent et dépassent la caisse (voir
/// [AppDatabase.demanderPret]/[AppDatabase.accepterDemandePret]).
///
/// Ligne immuable, comme [Prets] : son statut ("en attente" /
/// "accordée" / "refusée") n'est **pas** une colonne mutable ici — il
/// se déduit de l'existence d'un [Prets] référençant cette demande
/// (voir [Prets.demandeId]) ou d'une ligne dans [PretDemandeRefus].
class PretDemandes extends Table with HashChainColumns {
  @override
  String get tableName => 'pret_demandes';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get montantDemandeFcfa => integer()();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Refus d'une demande de prêt (le membre se désiste, ou l'agent
/// l'annule) — toujours une nouvelle ligne qui référence la demande
/// d'origine, jamais une suppression ni une colonne de statut mutable
/// sur [PretDemandes] (même principe que [PretAnnulations]).
class PretDemandeRefus extends Table with HashChainColumns {
  @override
  String get tableName => 'pret_demande_refus';

  TextColumn get id => text()();
  TextColumn get demandeId => text().references(PretDemandes, #id)();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get refusedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

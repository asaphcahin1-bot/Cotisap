import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Une amende collectée pendant le cycle (ex. absence non justifiée,
/// retard). Contribue au calcul de fin de cycle au même titre que les
/// intérêts de prêts (skill avec-business-rules, étape 1 de la formule).
class Amendes extends Table with HashChainColumns, ProvenanceColumns {
  @override
  String get tableName => 'amendes';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get montantFcfa => integer()();
  TextColumn get motif => text()();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Carnet concerné (1 ou 2) — une amende est désormais propre à un
  /// carnet, jamais partagée entre les 2 carnets d'un même membre (voir
  /// DECISIONS.md, "Amende par carnet, pas par membre").
  IntColumn get carnetNumero => integer().withDefault(const Constant(1))();

  /// Date de l'échéance/réunion concernée — sert à la validation de
  /// cohérence entre motifs système (voir
  /// [AppDatabase.motifsSystemeApplicables]) et à la vérification
  /// interactive à la clôture de journée. `null` pour une amende
  /// manuelle sans échéance précise (ex. importée).
  DateTimeColumn get echeanceDate => dateTime().nullable()();

  /// Copie figée (jamais une référence vivante, comme [motif]/
  /// [montantFcfa]) du `codeSysteme` du motif au moment de la saisie —
  /// `null` pour un motif ajouté manuellement par le groupe. Permet de
  /// reconnaître les 3 motifs système même si leur libellé a été
  /// renommé depuis.
  TextColumn get motifCodeSysteme => text().nullable()();

  /// Vrai si créée automatiquement pour une échéance manquée (skill
  /// avec-business-rules, section "Retard de cotisation"), plutôt que
  /// saisie librement par l'agent. Sert à cibler les amendes proposées à
  /// la revue de l'agent à la séance suivante — voir
  /// [AppDatabase.amendesEnAttenteRevue].
  BoolColumn get estAutoGeneree => boolean().withDefault(const Constant(false))();

  /// Renseigné quand cette amende a été **réglée** — cash (immédiat) ou
  /// par déduction automatique de la cotisation à la clôture du cycle
  /// (voir DECISIONS.md, "Les amendes ne sont plus une dette"). Une
  /// amende avec `confirmedAt == null` est "non soldée" (compte pour
  /// [AppDatabase.montantAmendesNonSoldeesFcfa]). Régler une amende
  /// renseigne aussi [reviewedAt] s'il ne l'était pas déjà (payer
  /// équivaut à l'avoir revue).
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  /// Renseigné quand l'agent a validé une amende auto-générée à la
  /// séance de revue ("Confirmer telle quelle" — voir DECISIONS.md,
  /// "Écran Cotisations moins chargé") — confirme seulement que
  /// l'absence est réelle, **n'implique aucun règlement cash** ;
  /// distinct de [confirmedAt]. Évite qu'elle réapparaisse
  /// indéfiniment dans la liste bloquante à revoir une fois traitée,
  /// qu'elle soit déjà payée ou non.
  DateTimeColumn get reviewedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Un paiement (partiel ou total) contre une amende — même principe que
/// [PretRemboursements] pour les prêts (voir DECISIONS.md, "Paiement
/// partiel d'une amende") : plusieurs paiements peuvent s'accumuler
/// contre la même amende avant qu'elle soit intégralement soldée.
class AmendePaiements extends Table with HashChainColumns {
  @override
  String get tableName => 'amende_paiements';

  TextColumn get id => text()();
  TextColumn get amendeId => text().references(Amendes, #id)();
  IntColumn get montantFcfa => integer()();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Annulation d'une amende (erreur d'enregistrement — le membre avait en
/// réalité payé, voir DECISIONS.md) — toujours une nouvelle ligne qui
/// référence l'amende d'origine, jamais une suppression ni une
/// modification directe.
class AmendeAnnulations extends Table with HashChainColumns {
  @override
  String get tableName => 'amende_annulations';

  TextColumn get id => text()();
  TextColumn get amendeId => text().references(Amendes, #id)();
  TextColumn get raison => text()();
  TextColumn get annuleParPhone => text()();
  DateTimeColumn get annuleAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

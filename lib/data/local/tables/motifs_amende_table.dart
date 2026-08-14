import 'package:drift/drift.dart';

import 'groups_table.dart';

/// Catalogue des motifs d'amende configurables par groupe (ex.
/// "Bavardage", "Téléphone en réunion", "Absence non justifiée"),
/// chacun avec son propre montant — remplace la saisie entièrement
/// libre (montant + motif retapés à chaque fois) par un choix rapide
/// dans une liste (voir DECISIONS.md, "Catalogue de motifs d'amende").
///
/// Volontairement **pas** une table financière en ajout seul comme
/// [Amendes] : ceci est de la configuration (comme [Groups]/[Cycles]),
/// pas une transaction. [Amendes.motif]/[Amendes.montantFcfa] restent
/// de simples valeurs texte/entier au moment de l'enregistrement — ce
/// catalogue ne fait que pré-remplir le formulaire, aucune référence
/// vivante n'existe entre une amende déjà enregistrée et le motif qui
/// l'a inspirée. Modifier ou désactiver un motif ici ne change donc
/// jamais rétroactivement une amende déjà enregistrée.
class MotifsAmende extends Table {
  @override
  String get tableName => 'motifs_amende';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get libelle => text()();
  IntColumn get montantFcfa => integer()();

  /// Phrase courte en français simple expliquant le motif à l'agent
  /// (ex. "Le membre n'est pas présent à la réunion.") — voir
  /// DECISIONS.md, "Motifs d'amende prédéfinis".
  TextColumn get description => text().nullable()();

  /// Identifiant stable des 3 motifs système créés automatiquement à la
  /// création du groupe (`absence`, `part_impayee`, `paye_par_tiers`) —
  /// `null` pour un motif ajouté manuellement par le groupe. Sert à la
  /// validation de cohérence entre motifs (voir
  /// `AppDatabase.motifsApplicablesAuCarnet`) : reconnaître ces 3 motifs
  /// même si leur libellé a été renommé.
  TextColumn get codeSysteme => text().nullable()();

  /// Faux = retiré du choix proposé pour une nouvelle amende, sans
  /// toucher à l'historique (jamais une suppression — un motif déjà
  /// utilisé reste visible dans l'écran de gestion, juste plus proposé
  /// à la création).
  BoolColumn get actif => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

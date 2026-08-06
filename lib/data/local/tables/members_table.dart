import 'package:drift/drift.dart';

import 'groups_table.dart';

/// Un membre d'un groupe AVEC. Identifié de préférence par son numéro de
/// téléphone personnel (skill two-tier-access-model /
/// member-consent-rules), mais [phoneNumber] est nullable : un membre
/// sans aucun téléphone (pas seulement sans smartphone) peut exister
/// dans l'app. Conséquences documentées dans DECISIONS.md — en
/// résumé : ce membre ne peut jamais utiliser l'accès "membre" en
/// lecture seule (qui s'identifie par numéro), et la confirmation de
/// ses prêts passe par signature capturée en personne plutôt que par
/// code SMS (skill member-consent-rules, section "Cas des membres sans
/// smartphone").
///
/// Ce n'est volontairement pas une table en ajout seul : corriger une
/// coquille dans un nom ou un numéro n'est pas un enregistrement
/// financier et ne présente pas de risque de litige.
class Members extends Table {
  @override
  String get tableName => 'members';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get fullName => text()();
  TextColumn get phoneNumber => text().nullable()();
  DateTimeColumn get joinedAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

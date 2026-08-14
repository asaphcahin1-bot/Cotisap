import 'package:drift/drift.dart';

import 'groups_table.dart';
import 'members_table.dart';

/// Identité **persistante** d'un carnet physique — un numéro de série
/// unique par groupe (format `C-001`, `C-002`...), jamais réutilisé,
/// qui ne se réinitialise jamais d'un cycle à l'autre — voir
/// DECISIONS.md, "Numéro de série physique par carnet".
///
/// Distinct de [CarnetsEngages] (le choix, par cycle, du nombre de
/// carnets d'un membre) et de `carnetNumero` (1 ou 2, la position du
/// carnet chez son membre, utilisée par [Cotisations]/[Echeances]/
/// [Amendes]) — volontairement pour ne jamais confondre les deux dans
/// l'interface : `carnetNumero` reste la clé technique interne,
/// [numeroSerie] est ce qui s'affiche à l'agent et au membre.
///
/// Une ligne par (membre, carnetNumero) — créée une seule fois, la
/// première fois que ce créneau de carnet est engagé, puis réutilisée
/// telle quelle à chaque cycle suivant. Pas une table financière en
/// ajout seul (comme [CarnetsEngages]) : le numéro peut être corrigé
/// par l'agent si le membre a déjà un vrai carnet physique numéroté.
class Carnets extends Table {
  @override
  String get tableName => 'carnets';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get memberId => text().references(Members, #id)();

  /// 1 ou 2 — la position du carnet chez son membre, jamais réutilisée
  /// comme identifiant affiché (voir [numeroSerie]).
  IntColumn get carnetNumero => integer()();

  /// Numéro de série affiché — format `C-001`, généré automatiquement
  /// (prochain numéro disponible dans la séquence du groupe) ou saisi
  /// manuellement par l'agent si le carnet physique en a déjà un.
  TextColumn get numeroSerie => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {memberId, carnetNumero},
    {groupId, numeroSerie},
  ];
}

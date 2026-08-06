import 'package:drift/drift.dart';

/// Un groupe AVEC. Champs structurels uniquement — la valeur de la part
/// et le taux d'intérêt sont fixés par cycle (voir [Cycles]), pas ici,
/// car le skill avec-business-rules précise qu'ils sont "définis par le
/// groupe en début de cycle", donc potentiellement différents d'un
/// cycle à l'autre.
class Groups extends Table {
  @override
  String get tableName => 'groups';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 9 à 12 mois habituellement (skill avec-business-rules) — laissé
  /// libre en base, validé côté formulaire de création.
  IntColumn get cycleDurationMonths =>
      integer().withDefault(const Constant(9))();

  /// hebdomadaire | bimensuelle | mensuelle
  TextColumn get meetingFrequency =>
      text().withDefault(const Constant('mensuelle'))();

  /// Jour de paiement fixe — la cotisation tombe toujours ce jour précis,
  /// pas une simple période glissante depuis le début du cycle. Un seul
  /// des deux groupes de colonnes ci-dessous est renseigné selon
  /// [meetingFrequency] :
  /// - hebdomadaire -> [paymentDayOfWeek] (1 = lundi ... 7 = dimanche)
  /// - mensuelle -> [paymentDayOfMonth1] seul (ex. le 5 de chaque mois)
  /// - bimensuelle -> [paymentDayOfMonth1] et [paymentDayOfMonth2]
  ///   (ex. le 5 et le 20)
  IntColumn get paymentDayOfWeek => integer().nullable()();
  IntColumn get paymentDayOfMonth1 => integer().nullable()();
  IntColumn get paymentDayOfMonth2 => integer().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

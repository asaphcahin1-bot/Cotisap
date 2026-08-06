// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleDurationMonthsMeta =
      const VerificationMeta('cycleDurationMonths');
  @override
  late final GeneratedColumn<int> cycleDurationMonths = GeneratedColumn<int>(
    'cycle_duration_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(9),
  );
  static const VerificationMeta _meetingFrequencyMeta = const VerificationMeta(
    'meetingFrequency',
  );
  @override
  late final GeneratedColumn<String> meetingFrequency = GeneratedColumn<String>(
    'meeting_frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mensuelle'),
  );
  static const VerificationMeta _paymentDayOfWeekMeta = const VerificationMeta(
    'paymentDayOfWeek',
  );
  @override
  late final GeneratedColumn<int> paymentDayOfWeek = GeneratedColumn<int>(
    'payment_day_of_week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentDayOfMonth1Meta =
      const VerificationMeta('paymentDayOfMonth1');
  @override
  late final GeneratedColumn<int> paymentDayOfMonth1 = GeneratedColumn<int>(
    'payment_day_of_month1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentDayOfMonth2Meta =
      const VerificationMeta('paymentDayOfMonth2');
  @override
  late final GeneratedColumn<int> paymentDayOfMonth2 = GeneratedColumn<int>(
    'payment_day_of_month2',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    cycleDurationMonths,
    meetingFrequency,
    paymentDayOfWeek,
    paymentDayOfMonth1,
    paymentDayOfMonth2,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Group> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cycle_duration_months')) {
      context.handle(
        _cycleDurationMonthsMeta,
        cycleDurationMonths.isAcceptableOrUnknown(
          data['cycle_duration_months']!,
          _cycleDurationMonthsMeta,
        ),
      );
    }
    if (data.containsKey('meeting_frequency')) {
      context.handle(
        _meetingFrequencyMeta,
        meetingFrequency.isAcceptableOrUnknown(
          data['meeting_frequency']!,
          _meetingFrequencyMeta,
        ),
      );
    }
    if (data.containsKey('payment_day_of_week')) {
      context.handle(
        _paymentDayOfWeekMeta,
        paymentDayOfWeek.isAcceptableOrUnknown(
          data['payment_day_of_week']!,
          _paymentDayOfWeekMeta,
        ),
      );
    }
    if (data.containsKey('payment_day_of_month1')) {
      context.handle(
        _paymentDayOfMonth1Meta,
        paymentDayOfMonth1.isAcceptableOrUnknown(
          data['payment_day_of_month1']!,
          _paymentDayOfMonth1Meta,
        ),
      );
    }
    if (data.containsKey('payment_day_of_month2')) {
      context.handle(
        _paymentDayOfMonth2Meta,
        paymentDayOfMonth2.isAcceptableOrUnknown(
          data['payment_day_of_month2']!,
          _paymentDayOfMonth2Meta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cycleDurationMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_duration_months'],
      )!,
      meetingFrequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meeting_frequency'],
      )!,
      paymentDayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_day_of_week'],
      ),
      paymentDayOfMonth1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_day_of_month1'],
      ),
      paymentDayOfMonth2: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_day_of_month2'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final String id;
  final String name;

  /// 9 à 12 mois habituellement (skill avec-business-rules) — laissé
  /// libre en base, validé côté formulaire de création.
  final int cycleDurationMonths;

  /// hebdomadaire | bimensuelle | mensuelle
  final String meetingFrequency;

  /// Jour de paiement fixe — la cotisation tombe toujours ce jour précis,
  /// pas une simple période glissante depuis le début du cycle. Un seul
  /// des deux groupes de colonnes ci-dessous est renseigné selon
  /// [meetingFrequency] :
  /// - hebdomadaire -> [paymentDayOfWeek] (1 = lundi ... 7 = dimanche)
  /// - mensuelle -> [paymentDayOfMonth1] seul (ex. le 5 de chaque mois)
  /// - bimensuelle -> [paymentDayOfMonth1] et [paymentDayOfMonth2]
  ///   (ex. le 5 et le 20)
  final int? paymentDayOfWeek;
  final int? paymentDayOfMonth1;
  final int? paymentDayOfMonth2;
  final DateTime createdAt;
  const Group({
    required this.id,
    required this.name,
    required this.cycleDurationMonths,
    required this.meetingFrequency,
    this.paymentDayOfWeek,
    this.paymentDayOfMonth1,
    this.paymentDayOfMonth2,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['cycle_duration_months'] = Variable<int>(cycleDurationMonths);
    map['meeting_frequency'] = Variable<String>(meetingFrequency);
    if (!nullToAbsent || paymentDayOfWeek != null) {
      map['payment_day_of_week'] = Variable<int>(paymentDayOfWeek);
    }
    if (!nullToAbsent || paymentDayOfMonth1 != null) {
      map['payment_day_of_month1'] = Variable<int>(paymentDayOfMonth1);
    }
    if (!nullToAbsent || paymentDayOfMonth2 != null) {
      map['payment_day_of_month2'] = Variable<int>(paymentDayOfMonth2);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: Value(name),
      cycleDurationMonths: Value(cycleDurationMonths),
      meetingFrequency: Value(meetingFrequency),
      paymentDayOfWeek: paymentDayOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDayOfWeek),
      paymentDayOfMonth1: paymentDayOfMonth1 == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDayOfMonth1),
      paymentDayOfMonth2: paymentDayOfMonth2 == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDayOfMonth2),
      createdAt: Value(createdAt),
    );
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      cycleDurationMonths: serializer.fromJson<int>(
        json['cycleDurationMonths'],
      ),
      meetingFrequency: serializer.fromJson<String>(json['meetingFrequency']),
      paymentDayOfWeek: serializer.fromJson<int?>(json['paymentDayOfWeek']),
      paymentDayOfMonth1: serializer.fromJson<int?>(json['paymentDayOfMonth1']),
      paymentDayOfMonth2: serializer.fromJson<int?>(json['paymentDayOfMonth2']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'cycleDurationMonths': serializer.toJson<int>(cycleDurationMonths),
      'meetingFrequency': serializer.toJson<String>(meetingFrequency),
      'paymentDayOfWeek': serializer.toJson<int?>(paymentDayOfWeek),
      'paymentDayOfMonth1': serializer.toJson<int?>(paymentDayOfMonth1),
      'paymentDayOfMonth2': serializer.toJson<int?>(paymentDayOfMonth2),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    int? cycleDurationMonths,
    String? meetingFrequency,
    Value<int?> paymentDayOfWeek = const Value.absent(),
    Value<int?> paymentDayOfMonth1 = const Value.absent(),
    Value<int?> paymentDayOfMonth2 = const Value.absent(),
    DateTime? createdAt,
  }) => Group(
    id: id ?? this.id,
    name: name ?? this.name,
    cycleDurationMonths: cycleDurationMonths ?? this.cycleDurationMonths,
    meetingFrequency: meetingFrequency ?? this.meetingFrequency,
    paymentDayOfWeek: paymentDayOfWeek.present
        ? paymentDayOfWeek.value
        : this.paymentDayOfWeek,
    paymentDayOfMonth1: paymentDayOfMonth1.present
        ? paymentDayOfMonth1.value
        : this.paymentDayOfMonth1,
    paymentDayOfMonth2: paymentDayOfMonth2.present
        ? paymentDayOfMonth2.value
        : this.paymentDayOfMonth2,
    createdAt: createdAt ?? this.createdAt,
  );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      cycleDurationMonths: data.cycleDurationMonths.present
          ? data.cycleDurationMonths.value
          : this.cycleDurationMonths,
      meetingFrequency: data.meetingFrequency.present
          ? data.meetingFrequency.value
          : this.meetingFrequency,
      paymentDayOfWeek: data.paymentDayOfWeek.present
          ? data.paymentDayOfWeek.value
          : this.paymentDayOfWeek,
      paymentDayOfMonth1: data.paymentDayOfMonth1.present
          ? data.paymentDayOfMonth1.value
          : this.paymentDayOfMonth1,
      paymentDayOfMonth2: data.paymentDayOfMonth2.present
          ? data.paymentDayOfMonth2.value
          : this.paymentDayOfMonth2,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cycleDurationMonths: $cycleDurationMonths, ')
          ..write('meetingFrequency: $meetingFrequency, ')
          ..write('paymentDayOfWeek: $paymentDayOfWeek, ')
          ..write('paymentDayOfMonth1: $paymentDayOfMonth1, ')
          ..write('paymentDayOfMonth2: $paymentDayOfMonth2, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    cycleDurationMonths,
    meetingFrequency,
    paymentDayOfWeek,
    paymentDayOfMonth1,
    paymentDayOfMonth2,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.name == this.name &&
          other.cycleDurationMonths == this.cycleDurationMonths &&
          other.meetingFrequency == this.meetingFrequency &&
          other.paymentDayOfWeek == this.paymentDayOfWeek &&
          other.paymentDayOfMonth1 == this.paymentDayOfMonth1 &&
          other.paymentDayOfMonth2 == this.paymentDayOfMonth2 &&
          other.createdAt == this.createdAt);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> cycleDurationMonths;
  final Value<String> meetingFrequency;
  final Value<int?> paymentDayOfWeek;
  final Value<int?> paymentDayOfMonth1;
  final Value<int?> paymentDayOfMonth2;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.cycleDurationMonths = const Value.absent(),
    this.meetingFrequency = const Value.absent(),
    this.paymentDayOfWeek = const Value.absent(),
    this.paymentDayOfMonth1 = const Value.absent(),
    this.paymentDayOfMonth2 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    required String name,
    this.cycleDurationMonths = const Value.absent(),
    this.meetingFrequency = const Value.absent(),
    this.paymentDayOfWeek = const Value.absent(),
    this.paymentDayOfMonth1 = const Value.absent(),
    this.paymentDayOfMonth2 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Group> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? cycleDurationMonths,
    Expression<String>? meetingFrequency,
    Expression<int>? paymentDayOfWeek,
    Expression<int>? paymentDayOfMonth1,
    Expression<int>? paymentDayOfMonth2,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (cycleDurationMonths != null)
        'cycle_duration_months': cycleDurationMonths,
      if (meetingFrequency != null) 'meeting_frequency': meetingFrequency,
      if (paymentDayOfWeek != null) 'payment_day_of_week': paymentDayOfWeek,
      if (paymentDayOfMonth1 != null)
        'payment_day_of_month1': paymentDayOfMonth1,
      if (paymentDayOfMonth2 != null)
        'payment_day_of_month2': paymentDayOfMonth2,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? cycleDurationMonths,
    Value<String>? meetingFrequency,
    Value<int?>? paymentDayOfWeek,
    Value<int?>? paymentDayOfMonth1,
    Value<int?>? paymentDayOfMonth2,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      cycleDurationMonths: cycleDurationMonths ?? this.cycleDurationMonths,
      meetingFrequency: meetingFrequency ?? this.meetingFrequency,
      paymentDayOfWeek: paymentDayOfWeek ?? this.paymentDayOfWeek,
      paymentDayOfMonth1: paymentDayOfMonth1 ?? this.paymentDayOfMonth1,
      paymentDayOfMonth2: paymentDayOfMonth2 ?? this.paymentDayOfMonth2,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cycleDurationMonths.present) {
      map['cycle_duration_months'] = Variable<int>(cycleDurationMonths.value);
    }
    if (meetingFrequency.present) {
      map['meeting_frequency'] = Variable<String>(meetingFrequency.value);
    }
    if (paymentDayOfWeek.present) {
      map['payment_day_of_week'] = Variable<int>(paymentDayOfWeek.value);
    }
    if (paymentDayOfMonth1.present) {
      map['payment_day_of_month1'] = Variable<int>(paymentDayOfMonth1.value);
    }
    if (paymentDayOfMonth2.present) {
      map['payment_day_of_month2'] = Variable<int>(paymentDayOfMonth2.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cycleDurationMonths: $cycleDurationMonths, ')
          ..write('meetingFrequency: $meetingFrequency, ')
          ..write('paymentDayOfWeek: $paymentDayOfWeek, ')
          ..write('paymentDayOfMonth1: $paymentDayOfMonth1, ')
          ..write('paymentDayOfMonth2: $paymentDayOfMonth2, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    fullName,
    phoneNumber,
    joinedAt,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<Member> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final String id;
  final String groupId;
  final String fullName;
  final String? phoneNumber;
  final DateTime joinedAt;
  final bool active;
  const Member({
    required this.id,
    required this.groupId,
    required this.fullName,
    this.phoneNumber,
    required this.joinedAt,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    map['joined_at'] = Variable<DateTime>(joinedAt);
    map['active'] = Variable<bool>(active);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      fullName: Value(fullName),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      joinedAt: Value(joinedAt),
      active: Value(active),
    );
  }

  factory Member.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      fullName: serializer.fromJson<String>(json['fullName']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'fullName': serializer.toJson<String>(fullName),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
      'active': serializer.toJson<bool>(active),
    };
  }

  Member copyWith({
    String? id,
    String? groupId,
    String? fullName,
    Value<String?> phoneNumber = const Value.absent(),
    DateTime? joinedAt,
    bool? active,
  }) => Member(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    fullName: fullName ?? this.fullName,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    joinedAt: joinedAt ?? this.joinedAt,
    active: active ?? this.active,
  );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, fullName, phoneNumber, joinedAt, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.fullName == this.fullName &&
          other.phoneNumber == this.phoneNumber &&
          other.joinedAt == this.joinedAt &&
          other.active == this.active);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> fullName;
  final Value<String?> phoneNumber;
  final Value<DateTime> joinedAt;
  final Value<bool> active;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String groupId,
    required String fullName,
    this.phoneNumber = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       fullName = Value(fullName);
  static Insertable<Member> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? fullName,
    Expression<String>? phoneNumber,
    Expression<DateTime>? joinedAt,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? fullName,
    Value<String?>? phoneNumber,
    Value<DateTime>? joinedAt,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      joinedAt: joinedAt ?? this.joinedAt,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentAssignmentsTable extends AgentAssignments
    with TableInfo<$AgentAssignmentsTable, AgentAssignment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentAssignmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignedAtMeta = const VerificationMeta(
    'assignedAt',
  );
  @override
  late final GeneratedColumn<DateTime> assignedAt = GeneratedColumn<DateTime>(
    'assigned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    id,
    groupId,
    memberId,
    phoneNumber,
    role,
    assignedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_assignments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentAssignment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_phoneNumberMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('assigned_at')) {
      context.handle(
        _assignedAtMeta,
        assignedAt.isAcceptableOrUnknown(data['assigned_at']!, _assignedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentAssignment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentAssignment(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      assignedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}assigned_at'],
      )!,
    );
  }

  @override
  $AgentAssignmentsTable createAlias(String alias) {
    return $AgentAssignmentsTable(attachedDatabase, alias);
  }
}

class AgentAssignment extends DataClass implements Insertable<AgentAssignment> {
  final String? previousHash;
  final String hash;
  final String id;
  final String groupId;
  final String? memberId;
  final String phoneNumber;
  final String role;
  final DateTime assignedAt;
  const AgentAssignment({
    this.previousHash,
    required this.hash,
    required this.id,
    required this.groupId,
    this.memberId,
    required this.phoneNumber,
    required this.role,
    required this.assignedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    map['phone_number'] = Variable<String>(phoneNumber);
    map['role'] = Variable<String>(role);
    map['assigned_at'] = Variable<DateTime>(assignedAt);
    return map;
  }

  AgentAssignmentsCompanion toCompanion(bool nullToAbsent) {
    return AgentAssignmentsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      id: Value(id),
      groupId: Value(groupId),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      phoneNumber: Value(phoneNumber),
      role: Value(role),
      assignedAt: Value(assignedAt),
    );
  }

  factory AgentAssignment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentAssignment(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      role: serializer.fromJson<String>(json['role']),
      assignedAt: serializer.fromJson<DateTime>(json['assignedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'memberId': serializer.toJson<String?>(memberId),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'role': serializer.toJson<String>(role),
      'assignedAt': serializer.toJson<DateTime>(assignedAt),
    };
  }

  AgentAssignment copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? id,
    String? groupId,
    Value<String?> memberId = const Value.absent(),
    String? phoneNumber,
    String? role,
    DateTime? assignedAt,
  }) => AgentAssignment(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    memberId: memberId.present ? memberId.value : this.memberId,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    role: role ?? this.role,
    assignedAt: assignedAt ?? this.assignedAt,
  );
  AgentAssignment copyWithCompanion(AgentAssignmentsCompanion data) {
    return AgentAssignment(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      role: data.role.present ? data.role.value : this.role,
      assignedAt: data.assignedAt.present
          ? data.assignedAt.value
          : this.assignedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentAssignment(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('role: $role, ')
          ..write('assignedAt: $assignedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    id,
    groupId,
    memberId,
    phoneNumber,
    role,
    assignedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentAssignment &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.memberId == this.memberId &&
          other.phoneNumber == this.phoneNumber &&
          other.role == this.role &&
          other.assignedAt == this.assignedAt);
}

class AgentAssignmentsCompanion extends UpdateCompanion<AgentAssignment> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> id;
  final Value<String> groupId;
  final Value<String?> memberId;
  final Value<String> phoneNumber;
  final Value<String> role;
  final Value<DateTime> assignedAt;
  final Value<int> rowid;
  const AgentAssignmentsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.role = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentAssignmentsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    required String id,
    required String groupId,
    this.memberId = const Value.absent(),
    required String phoneNumber,
    required String role,
    this.assignedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       groupId = Value(groupId),
       phoneNumber = Value(phoneNumber),
       role = Value(role);
  static Insertable<AgentAssignment> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? memberId,
    Expression<String>? phoneNumber,
    Expression<String>? role,
    Expression<DateTime>? assignedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (memberId != null) 'member_id': memberId,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (role != null) 'role': role,
      if (assignedAt != null) 'assigned_at': assignedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentAssignmentsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? id,
    Value<String>? groupId,
    Value<String?>? memberId,
    Value<String>? phoneNumber,
    Value<String>? role,
    Value<DateTime>? assignedAt,
    Value<int>? rowid,
  }) {
    return AgentAssignmentsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      assignedAt: assignedAt ?? this.assignedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<DateTime>(assignedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentAssignmentsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('memberId: $memberId, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('role: $role, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentAssignmentRevocationsTable extends AgentAssignmentRevocations
    with
        TableInfo<$AgentAssignmentRevocationsTable, AgentAssignmentRevocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentAssignmentRevocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignmentIdMeta = const VerificationMeta(
    'assignmentId',
  );
  @override
  late final GeneratedColumn<String> assignmentId = GeneratedColumn<String>(
    'assignment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES agent_assignments (id)',
    ),
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    id,
    assignmentId,
    revokedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_assignment_revocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentAssignmentRevocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('assignment_id')) {
      context.handle(
        _assignmentIdMeta,
        assignmentId.isAcceptableOrUnknown(
          data['assignment_id']!,
          _assignmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assignmentIdMeta);
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentAssignmentRevocation map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentAssignmentRevocation(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assignmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignment_id'],
      )!,
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      )!,
    );
  }

  @override
  $AgentAssignmentRevocationsTable createAlias(String alias) {
    return $AgentAssignmentRevocationsTable(attachedDatabase, alias);
  }
}

class AgentAssignmentRevocation extends DataClass
    implements Insertable<AgentAssignmentRevocation> {
  final String? previousHash;
  final String hash;
  final String id;
  final String assignmentId;
  final DateTime revokedAt;
  const AgentAssignmentRevocation({
    this.previousHash,
    required this.hash,
    required this.id,
    required this.assignmentId,
    required this.revokedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['id'] = Variable<String>(id);
    map['assignment_id'] = Variable<String>(assignmentId);
    map['revoked_at'] = Variable<DateTime>(revokedAt);
    return map;
  }

  AgentAssignmentRevocationsCompanion toCompanion(bool nullToAbsent) {
    return AgentAssignmentRevocationsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      id: Value(id),
      assignmentId: Value(assignmentId),
      revokedAt: Value(revokedAt),
    );
  }

  factory AgentAssignmentRevocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentAssignmentRevocation(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      id: serializer.fromJson<String>(json['id']),
      assignmentId: serializer.fromJson<String>(json['assignmentId']),
      revokedAt: serializer.fromJson<DateTime>(json['revokedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'id': serializer.toJson<String>(id),
      'assignmentId': serializer.toJson<String>(assignmentId),
      'revokedAt': serializer.toJson<DateTime>(revokedAt),
    };
  }

  AgentAssignmentRevocation copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? id,
    String? assignmentId,
    DateTime? revokedAt,
  }) => AgentAssignmentRevocation(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    id: id ?? this.id,
    assignmentId: assignmentId ?? this.assignmentId,
    revokedAt: revokedAt ?? this.revokedAt,
  );
  AgentAssignmentRevocation copyWithCompanion(
    AgentAssignmentRevocationsCompanion data,
  ) {
    return AgentAssignmentRevocation(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      id: data.id.present ? data.id.value : this.id,
      assignmentId: data.assignmentId.present
          ? data.assignmentId.value
          : this.assignmentId,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentAssignmentRevocation(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('assignmentId: $assignmentId, ')
          ..write('revokedAt: $revokedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(previousHash, hash, id, assignmentId, revokedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentAssignmentRevocation &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.id == this.id &&
          other.assignmentId == this.assignmentId &&
          other.revokedAt == this.revokedAt);
}

class AgentAssignmentRevocationsCompanion
    extends UpdateCompanion<AgentAssignmentRevocation> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> id;
  final Value<String> assignmentId;
  final Value<DateTime> revokedAt;
  final Value<int> rowid;
  const AgentAssignmentRevocationsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.id = const Value.absent(),
    this.assignmentId = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentAssignmentRevocationsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    required String id,
    required String assignmentId,
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       assignmentId = Value(assignmentId);
  static Insertable<AgentAssignmentRevocation> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? id,
    Expression<String>? assignmentId,
    Expression<DateTime>? revokedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (id != null) 'id': id,
      if (assignmentId != null) 'assignment_id': assignmentId,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentAssignmentRevocationsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? id,
    Value<String>? assignmentId,
    Value<DateTime>? revokedAt,
    Value<int>? rowid,
  }) {
    return AgentAssignmentRevocationsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      revokedAt: revokedAt ?? this.revokedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assignmentId.present) {
      map['assignment_id'] = Variable<String>(assignmentId.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentAssignmentRevocationsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('assignmentId: $assignmentId, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CyclesTable extends Cycles with TableInfo<$CyclesTable, Cycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _cycleNumberMeta = const VerificationMeta(
    'cycleNumber',
  );
  @override
  late final GeneratedColumn<int> cycleNumber = GeneratedColumn<int>(
    'cycle_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partValueFcfaMeta = const VerificationMeta(
    'partValueFcfa',
  );
  @override
  late final GeneratedColumn<int> partValueFcfa = GeneratedColumn<int>(
    'part_value_fcfa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interestRatePercentMeta =
      const VerificationMeta('interestRatePercent');
  @override
  late final GeneratedColumn<double> interestRatePercent =
      GeneratedColumn<double>(
        'interest_rate_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lateFeeFcfaMeta = const VerificationMeta(
    'lateFeeFcfa',
  );
  @override
  late final GeneratedColumn<int> lateFeeFcfa = GeneratedColumn<int>(
    'late_fee_fcfa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _loanDurationDaysMeta = const VerificationMeta(
    'loanDurationDays',
  );
  @override
  late final GeneratedColumn<int> loanDurationDays = GeneratedColumn<int>(
    'loan_duration_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en_cours'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    cycleNumber,
    startedAt,
    endedAt,
    partValueFcfa,
    interestRatePercent,
    lateFeeFcfa,
    loanDurationDays,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('cycle_number')) {
      context.handle(
        _cycleNumberMeta,
        cycleNumber.isAcceptableOrUnknown(
          data['cycle_number']!,
          _cycleNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cycleNumberMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('part_value_fcfa')) {
      context.handle(
        _partValueFcfaMeta,
        partValueFcfa.isAcceptableOrUnknown(
          data['part_value_fcfa']!,
          _partValueFcfaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partValueFcfaMeta);
    }
    if (data.containsKey('interest_rate_percent')) {
      context.handle(
        _interestRatePercentMeta,
        interestRatePercent.isAcceptableOrUnknown(
          data['interest_rate_percent']!,
          _interestRatePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_interestRatePercentMeta);
    }
    if (data.containsKey('late_fee_fcfa')) {
      context.handle(
        _lateFeeFcfaMeta,
        lateFeeFcfa.isAcceptableOrUnknown(
          data['late_fee_fcfa']!,
          _lateFeeFcfaMeta,
        ),
      );
    }
    if (data.containsKey('loan_duration_days')) {
      context.handle(
        _loanDurationDaysMeta,
        loanDurationDays.isAcceptableOrUnknown(
          data['loan_duration_days']!,
          _loanDurationDaysMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      cycleNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_number'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      partValueFcfa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part_value_fcfa'],
      )!,
      interestRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate_percent'],
      )!,
      lateFeeFcfa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}late_fee_fcfa'],
      )!,
      loanDurationDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loan_duration_days'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $CyclesTable createAlias(String alias) {
    return $CyclesTable(attachedDatabase, alias);
  }
}

class Cycle extends DataClass implements Insertable<Cycle> {
  final String id;
  final String groupId;
  final int cycleNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int partValueFcfa;
  final double interestRatePercent;

  /// Amende automatique suggérée pour un membre en retard de cotisation
  /// sur une période (skill avec-business-rules, section "Retard de
  /// cotisation") — fixée à la création du cycle, comme la valeur du
  /// carnet et le taux d'intérêt. 0 = pas d'amende de retard pour ce
  /// groupe.
  final int lateFeeFcfa;

  /// Durée d'une période de prêt, en jours (skill avec-business-rules,
  /// section "Prêts") — fixée à la création du cycle, comme la valeur du
  /// carnet. Si un prêt n'est pas intégralement remboursé à l'échéance,
  /// le même taux d'intérêt se réapplique au solde restant pour une
  /// nouvelle période de même durée, et ainsi de suite (voir
  /// LoanBalanceCalculator).
  final int loanDurationDays;

  /// en_cours | cloture
  final String status;
  const Cycle({
    required this.id,
    required this.groupId,
    required this.cycleNumber,
    required this.startedAt,
    this.endedAt,
    required this.partValueFcfa,
    required this.interestRatePercent,
    required this.lateFeeFcfa,
    required this.loanDurationDays,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['cycle_number'] = Variable<int>(cycleNumber);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['part_value_fcfa'] = Variable<int>(partValueFcfa);
    map['interest_rate_percent'] = Variable<double>(interestRatePercent);
    map['late_fee_fcfa'] = Variable<int>(lateFeeFcfa);
    map['loan_duration_days'] = Variable<int>(loanDurationDays);
    map['status'] = Variable<String>(status);
    return map;
  }

  CyclesCompanion toCompanion(bool nullToAbsent) {
    return CyclesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      cycleNumber: Value(cycleNumber),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      partValueFcfa: Value(partValueFcfa),
      interestRatePercent: Value(interestRatePercent),
      lateFeeFcfa: Value(lateFeeFcfa),
      loanDurationDays: Value(loanDurationDays),
      status: Value(status),
    );
  }

  factory Cycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cycle(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      cycleNumber: serializer.fromJson<int>(json['cycleNumber']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      partValueFcfa: serializer.fromJson<int>(json['partValueFcfa']),
      interestRatePercent: serializer.fromJson<double>(
        json['interestRatePercent'],
      ),
      lateFeeFcfa: serializer.fromJson<int>(json['lateFeeFcfa']),
      loanDurationDays: serializer.fromJson<int>(json['loanDurationDays']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'cycleNumber': serializer.toJson<int>(cycleNumber),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'partValueFcfa': serializer.toJson<int>(partValueFcfa),
      'interestRatePercent': serializer.toJson<double>(interestRatePercent),
      'lateFeeFcfa': serializer.toJson<int>(lateFeeFcfa),
      'loanDurationDays': serializer.toJson<int>(loanDurationDays),
      'status': serializer.toJson<String>(status),
    };
  }

  Cycle copyWith({
    String? id,
    String? groupId,
    int? cycleNumber,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? partValueFcfa,
    double? interestRatePercent,
    int? lateFeeFcfa,
    int? loanDurationDays,
    String? status,
  }) => Cycle(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    cycleNumber: cycleNumber ?? this.cycleNumber,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    partValueFcfa: partValueFcfa ?? this.partValueFcfa,
    interestRatePercent: interestRatePercent ?? this.interestRatePercent,
    lateFeeFcfa: lateFeeFcfa ?? this.lateFeeFcfa,
    loanDurationDays: loanDurationDays ?? this.loanDurationDays,
    status: status ?? this.status,
  );
  Cycle copyWithCompanion(CyclesCompanion data) {
    return Cycle(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      cycleNumber: data.cycleNumber.present
          ? data.cycleNumber.value
          : this.cycleNumber,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      partValueFcfa: data.partValueFcfa.present
          ? data.partValueFcfa.value
          : this.partValueFcfa,
      interestRatePercent: data.interestRatePercent.present
          ? data.interestRatePercent.value
          : this.interestRatePercent,
      lateFeeFcfa: data.lateFeeFcfa.present
          ? data.lateFeeFcfa.value
          : this.lateFeeFcfa,
      loanDurationDays: data.loanDurationDays.present
          ? data.loanDurationDays.value
          : this.loanDurationDays,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cycle(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleNumber: $cycleNumber, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('partValueFcfa: $partValueFcfa, ')
          ..write('interestRatePercent: $interestRatePercent, ')
          ..write('lateFeeFcfa: $lateFeeFcfa, ')
          ..write('loanDurationDays: $loanDurationDays, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    cycleNumber,
    startedAt,
    endedAt,
    partValueFcfa,
    interestRatePercent,
    lateFeeFcfa,
    loanDurationDays,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cycle &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.cycleNumber == this.cycleNumber &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.partValueFcfa == this.partValueFcfa &&
          other.interestRatePercent == this.interestRatePercent &&
          other.lateFeeFcfa == this.lateFeeFcfa &&
          other.loanDurationDays == this.loanDurationDays &&
          other.status == this.status);
}

class CyclesCompanion extends UpdateCompanion<Cycle> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<int> cycleNumber;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> partValueFcfa;
  final Value<double> interestRatePercent;
  final Value<int> lateFeeFcfa;
  final Value<int> loanDurationDays;
  final Value<String> status;
  final Value<int> rowid;
  const CyclesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.cycleNumber = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.partValueFcfa = const Value.absent(),
    this.interestRatePercent = const Value.absent(),
    this.lateFeeFcfa = const Value.absent(),
    this.loanDurationDays = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CyclesCompanion.insert({
    required String id,
    required String groupId,
    required int cycleNumber,
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    required int partValueFcfa,
    required double interestRatePercent,
    this.lateFeeFcfa = const Value.absent(),
    this.loanDurationDays = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       cycleNumber = Value(cycleNumber),
       partValueFcfa = Value(partValueFcfa),
       interestRatePercent = Value(interestRatePercent);
  static Insertable<Cycle> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<int>? cycleNumber,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? partValueFcfa,
    Expression<double>? interestRatePercent,
    Expression<int>? lateFeeFcfa,
    Expression<int>? loanDurationDays,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (cycleNumber != null) 'cycle_number': cycleNumber,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (partValueFcfa != null) 'part_value_fcfa': partValueFcfa,
      if (interestRatePercent != null)
        'interest_rate_percent': interestRatePercent,
      if (lateFeeFcfa != null) 'late_fee_fcfa': lateFeeFcfa,
      if (loanDurationDays != null) 'loan_duration_days': loanDurationDays,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CyclesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<int>? cycleNumber,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? partValueFcfa,
    Value<double>? interestRatePercent,
    Value<int>? lateFeeFcfa,
    Value<int>? loanDurationDays,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return CyclesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      partValueFcfa: partValueFcfa ?? this.partValueFcfa,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      lateFeeFcfa: lateFeeFcfa ?? this.lateFeeFcfa,
      loanDurationDays: loanDurationDays ?? this.loanDurationDays,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (cycleNumber.present) {
      map['cycle_number'] = Variable<int>(cycleNumber.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (partValueFcfa.present) {
      map['part_value_fcfa'] = Variable<int>(partValueFcfa.value);
    }
    if (interestRatePercent.present) {
      map['interest_rate_percent'] = Variable<double>(
        interestRatePercent.value,
      );
    }
    if (lateFeeFcfa.present) {
      map['late_fee_fcfa'] = Variable<int>(lateFeeFcfa.value);
    }
    if (loanDurationDays.present) {
      map['loan_duration_days'] = Variable<int>(loanDurationDays.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CyclesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleNumber: $cycleNumber, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('partValueFcfa: $partValueFcfa, ')
          ..write('interestRatePercent: $interestRatePercent, ')
          ..write('lateFeeFcfa: $lateFeeFcfa, ')
          ..write('loanDurationDays: $loanDurationDays, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CotisationsTable extends Cotisations
    with TableInfo<$CotisationsTable, Cotisation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CotisationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('direct'),
  );
  static const VerificationMeta _estApproximatifMeta = const VerificationMeta(
    'estApproximatif',
  );
  @override
  late final GeneratedColumn<bool> estApproximatif = GeneratedColumn<bool>(
    'est_approximatif',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("est_approximatif" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _partsCountMeta = const VerificationMeta(
    'partsCount',
  );
  @override
  late final GeneratedColumn<int> partsCount = GeneratedColumn<int>(
    'parts_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _recordedByPhoneMeta = const VerificationMeta(
    'recordedByPhone',
  );
  @override
  late final GeneratedColumn<String> recordedByPhone = GeneratedColumn<String>(
    'recorded_by_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    groupId,
    cycleId,
    memberId,
    partsCount,
    source,
    recordedByPhone,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cotisations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cotisation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    if (data.containsKey('est_approximatif')) {
      context.handle(
        _estApproximatifMeta,
        estApproximatif.isAcceptableOrUnknown(
          data['est_approximatif']!,
          _estApproximatifMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('parts_count')) {
      context.handle(
        _partsCountMeta,
        partsCount.isAcceptableOrUnknown(data['parts_count']!, _partsCountMeta),
      );
    } else if (isInserting) {
      context.missing(_partsCountMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('recorded_by_phone')) {
      context.handle(
        _recordedByPhoneMeta,
        recordedByPhone.isAcceptableOrUnknown(
          data['recorded_by_phone']!,
          _recordedByPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedByPhoneMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cotisation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cotisation(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
      estApproximatif: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}est_approximatif'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      partsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parts_count'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      recordedByPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_phone'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $CotisationsTable createAlias(String alias) {
    return $CotisationsTable(attachedDatabase, alias);
  }
}

class Cotisation extends DataClass implements Insertable<Cotisation> {
  final String? previousHash;
  final String hash;

  /// `direct` = créé et vérifié en temps réel via l'app.
  /// `importe` = déclaré rétroactivement (carnet papier, CSV) au moment
  /// où un groupe bascule vers CotisApp. Jamais fusionné avec `direct`
  /// dans le même champ — reste distinguable pour un audit ou un litige.
  final String provenance;

  /// Le carnet papier d'origine n'a pas toujours une date ou un montant
  /// exacts. Ce champ marque une ligne importée dont la précision n'est
  /// pas garantie, plutôt que de forcer une précision que la source
  /// n'avait pas.
  final bool estApproximatif;
  final String id;
  final String groupId;
  final String cycleId;
  final String memberId;
  final int partsCount;
  final String source;
  final String recordedByPhone;
  final DateTime recordedAt;
  const Cotisation({
    this.previousHash,
    required this.hash,
    required this.provenance,
    required this.estApproximatif,
    required this.id,
    required this.groupId,
    required this.cycleId,
    required this.memberId,
    required this.partsCount,
    required this.source,
    required this.recordedByPhone,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['provenance'] = Variable<String>(provenance);
    map['est_approximatif'] = Variable<bool>(estApproximatif);
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['cycle_id'] = Variable<String>(cycleId);
    map['member_id'] = Variable<String>(memberId);
    map['parts_count'] = Variable<int>(partsCount);
    map['source'] = Variable<String>(source);
    map['recorded_by_phone'] = Variable<String>(recordedByPhone);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  CotisationsCompanion toCompanion(bool nullToAbsent) {
    return CotisationsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
      id: Value(id),
      groupId: Value(groupId),
      cycleId: Value(cycleId),
      memberId: Value(memberId),
      partsCount: Value(partsCount),
      source: Value(source),
      recordedByPhone: Value(recordedByPhone),
      recordedAt: Value(recordedAt),
    );
  }

  factory Cotisation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cotisation(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      provenance: serializer.fromJson<String>(json['provenance']),
      estApproximatif: serializer.fromJson<bool>(json['estApproximatif']),
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      partsCount: serializer.fromJson<int>(json['partsCount']),
      source: serializer.fromJson<String>(json['source']),
      recordedByPhone: serializer.fromJson<String>(json['recordedByPhone']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'provenance': serializer.toJson<String>(provenance),
      'estApproximatif': serializer.toJson<bool>(estApproximatif),
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'cycleId': serializer.toJson<String>(cycleId),
      'memberId': serializer.toJson<String>(memberId),
      'partsCount': serializer.toJson<int>(partsCount),
      'source': serializer.toJson<String>(source),
      'recordedByPhone': serializer.toJson<String>(recordedByPhone),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  Cotisation copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? provenance,
    bool? estApproximatif,
    String? id,
    String? groupId,
    String? cycleId,
    String? memberId,
    int? partsCount,
    String? source,
    String? recordedByPhone,
    DateTime? recordedAt,
  }) => Cotisation(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    provenance: provenance ?? this.provenance,
    estApproximatif: estApproximatif ?? this.estApproximatif,
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    cycleId: cycleId ?? this.cycleId,
    memberId: memberId ?? this.memberId,
    partsCount: partsCount ?? this.partsCount,
    source: source ?? this.source,
    recordedByPhone: recordedByPhone ?? this.recordedByPhone,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  Cotisation copyWithCompanion(CotisationsCompanion data) {
    return Cotisation(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      estApproximatif: data.estApproximatif.present
          ? data.estApproximatif.value
          : this.estApproximatif,
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      partsCount: data.partsCount.present
          ? data.partsCount.value
          : this.partsCount,
      source: data.source.present ? data.source.value : this.source,
      recordedByPhone: data.recordedByPhone.present
          ? data.recordedByPhone.value
          : this.recordedByPhone,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cotisation(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('partsCount: $partsCount, ')
          ..write('source: $source, ')
          ..write('recordedByPhone: $recordedByPhone, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    groupId,
    cycleId,
    memberId,
    partsCount,
    source,
    recordedByPhone,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cotisation &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.provenance == this.provenance &&
          other.estApproximatif == this.estApproximatif &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.cycleId == this.cycleId &&
          other.memberId == this.memberId &&
          other.partsCount == this.partsCount &&
          other.source == this.source &&
          other.recordedByPhone == this.recordedByPhone &&
          other.recordedAt == this.recordedAt);
}

class CotisationsCompanion extends UpdateCompanion<Cotisation> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> provenance;
  final Value<bool> estApproximatif;
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> cycleId;
  final Value<String> memberId;
  final Value<int> partsCount;
  final Value<String> source;
  final Value<String> recordedByPhone;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const CotisationsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.partsCount = const Value.absent(),
    this.source = const Value.absent(),
    this.recordedByPhone = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CotisationsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    required String id,
    required String groupId,
    required String cycleId,
    required String memberId,
    required int partsCount,
    this.source = const Value.absent(),
    required String recordedByPhone,
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       groupId = Value(groupId),
       cycleId = Value(cycleId),
       memberId = Value(memberId),
       partsCount = Value(partsCount),
       recordedByPhone = Value(recordedByPhone);
  static Insertable<Cotisation> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? provenance,
    Expression<bool>? estApproximatif,
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? cycleId,
    Expression<String>? memberId,
    Expression<int>? partsCount,
    Expression<String>? source,
    Expression<String>? recordedByPhone,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (provenance != null) 'provenance': provenance,
      if (estApproximatif != null) 'est_approximatif': estApproximatif,
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (memberId != null) 'member_id': memberId,
      if (partsCount != null) 'parts_count': partsCount,
      if (source != null) 'source': source,
      if (recordedByPhone != null) 'recorded_by_phone': recordedByPhone,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CotisationsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? provenance,
    Value<bool>? estApproximatif,
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? cycleId,
    Value<String>? memberId,
    Value<int>? partsCount,
    Value<String>? source,
    Value<String>? recordedByPhone,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return CotisationsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      provenance: provenance ?? this.provenance,
      estApproximatif: estApproximatif ?? this.estApproximatif,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cycleId: cycleId ?? this.cycleId,
      memberId: memberId ?? this.memberId,
      partsCount: partsCount ?? this.partsCount,
      source: source ?? this.source,
      recordedByPhone: recordedByPhone ?? this.recordedByPhone,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (estApproximatif.present) {
      map['est_approximatif'] = Variable<bool>(estApproximatif.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (partsCount.present) {
      map['parts_count'] = Variable<int>(partsCount.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (recordedByPhone.present) {
      map['recorded_by_phone'] = Variable<String>(recordedByPhone.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CotisationsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('partsCount: $partsCount, ')
          ..write('source: $source, ')
          ..write('recordedByPhone: $recordedByPhone, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CarnetsEngagesTable extends CarnetsEngages
    with TableInfo<$CarnetsEngagesTable, CarnetsEngage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CarnetsEngagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _partsCountMeta = const VerificationMeta(
    'partsCount',
  );
  @override
  late final GeneratedColumn<int> partsCount = GeneratedColumn<int>(
    'parts_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lockedAtMeta = const VerificationMeta(
    'lockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockedAt = GeneratedColumn<DateTime>(
    'locked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    cycleId,
    memberId,
    partsCount,
    lockedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'carnets_engages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CarnetsEngage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('parts_count')) {
      context.handle(
        _partsCountMeta,
        partsCount.isAcceptableOrUnknown(data['parts_count']!, _partsCountMeta),
      );
    } else if (isInserting) {
      context.missing(_partsCountMeta);
    }
    if (data.containsKey('locked_at')) {
      context.handle(
        _lockedAtMeta,
        lockedAt.isAcceptableOrUnknown(data['locked_at']!, _lockedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cycleId, memberId},
  ];
  @override
  CarnetsEngage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CarnetsEngage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      partsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parts_count'],
      )!,
      lockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_at'],
      ),
    );
  }

  @override
  $CarnetsEngagesTable createAlias(String alias) {
    return $CarnetsEngagesTable(attachedDatabase, alias);
  }
}

class CarnetsEngage extends DataClass implements Insertable<CarnetsEngage> {
  final String id;
  final String groupId;
  final String cycleId;
  final String memberId;
  final int partsCount;
  final DateTime? lockedAt;
  const CarnetsEngage({
    required this.id,
    required this.groupId,
    required this.cycleId,
    required this.memberId,
    required this.partsCount,
    this.lockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['cycle_id'] = Variable<String>(cycleId);
    map['member_id'] = Variable<String>(memberId);
    map['parts_count'] = Variable<int>(partsCount);
    if (!nullToAbsent || lockedAt != null) {
      map['locked_at'] = Variable<DateTime>(lockedAt);
    }
    return map;
  }

  CarnetsEngagesCompanion toCompanion(bool nullToAbsent) {
    return CarnetsEngagesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      cycleId: Value(cycleId),
      memberId: Value(memberId),
      partsCount: Value(partsCount),
      lockedAt: lockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedAt),
    );
  }

  factory CarnetsEngage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CarnetsEngage(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      partsCount: serializer.fromJson<int>(json['partsCount']),
      lockedAt: serializer.fromJson<DateTime?>(json['lockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'cycleId': serializer.toJson<String>(cycleId),
      'memberId': serializer.toJson<String>(memberId),
      'partsCount': serializer.toJson<int>(partsCount),
      'lockedAt': serializer.toJson<DateTime?>(lockedAt),
    };
  }

  CarnetsEngage copyWith({
    String? id,
    String? groupId,
    String? cycleId,
    String? memberId,
    int? partsCount,
    Value<DateTime?> lockedAt = const Value.absent(),
  }) => CarnetsEngage(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    cycleId: cycleId ?? this.cycleId,
    memberId: memberId ?? this.memberId,
    partsCount: partsCount ?? this.partsCount,
    lockedAt: lockedAt.present ? lockedAt.value : this.lockedAt,
  );
  CarnetsEngage copyWithCompanion(CarnetsEngagesCompanion data) {
    return CarnetsEngage(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      partsCount: data.partsCount.present
          ? data.partsCount.value
          : this.partsCount,
      lockedAt: data.lockedAt.present ? data.lockedAt.value : this.lockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CarnetsEngage(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('partsCount: $partsCount, ')
          ..write('lockedAt: $lockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupId, cycleId, memberId, partsCount, lockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CarnetsEngage &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.cycleId == this.cycleId &&
          other.memberId == this.memberId &&
          other.partsCount == this.partsCount &&
          other.lockedAt == this.lockedAt);
}

class CarnetsEngagesCompanion extends UpdateCompanion<CarnetsEngage> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> cycleId;
  final Value<String> memberId;
  final Value<int> partsCount;
  final Value<DateTime?> lockedAt;
  final Value<int> rowid;
  const CarnetsEngagesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.partsCount = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CarnetsEngagesCompanion.insert({
    required String id,
    required String groupId,
    required String cycleId,
    required String memberId,
    required int partsCount,
    this.lockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       cycleId = Value(cycleId),
       memberId = Value(memberId),
       partsCount = Value(partsCount);
  static Insertable<CarnetsEngage> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? cycleId,
    Expression<String>? memberId,
    Expression<int>? partsCount,
    Expression<DateTime>? lockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (memberId != null) 'member_id': memberId,
      if (partsCount != null) 'parts_count': partsCount,
      if (lockedAt != null) 'locked_at': lockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CarnetsEngagesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? cycleId,
    Value<String>? memberId,
    Value<int>? partsCount,
    Value<DateTime?>? lockedAt,
    Value<int>? rowid,
  }) {
    return CarnetsEngagesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cycleId: cycleId ?? this.cycleId,
      memberId: memberId ?? this.memberId,
      partsCount: partsCount ?? this.partsCount,
      lockedAt: lockedAt ?? this.lockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (partsCount.present) {
      map['parts_count'] = Variable<int>(partsCount.value);
    }
    if (lockedAt.present) {
      map['locked_at'] = Variable<DateTime>(lockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CarnetsEngagesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('partsCount: $partsCount, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PretsTable extends Prets with TableInfo<$PretsTable, Pret> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PretsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('direct'),
  );
  static const VerificationMeta _estApproximatifMeta = const VerificationMeta(
    'estApproximatif',
  );
  @override
  late final GeneratedColumn<bool> estApproximatif = GeneratedColumn<bool>(
    'est_approximatif',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("est_approximatif" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _principalFcfaMeta = const VerificationMeta(
    'principalFcfa',
  );
  @override
  late final GeneratedColumn<int> principalFcfa = GeneratedColumn<int>(
    'principal_fcfa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interestRatePercentMeta =
      const VerificationMeta('interestRatePercent');
  @override
  late final GeneratedColumn<double> interestRatePercent =
      GeneratedColumn<double>(
        'interest_rate_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dureeJoursMeta = const VerificationMeta(
    'dureeJours',
  );
  @override
  late final GeneratedColumn<int> dureeJours = GeneratedColumn<int>(
    'duree_jours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initiatedByPhoneMeta = const VerificationMeta(
    'initiatedByPhone',
  );
  @override
  late final GeneratedColumn<String> initiatedByPhone = GeneratedColumn<String>(
    'initiated_by_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmationCodeMeta = const VerificationMeta(
    'confirmationCode',
  );
  @override
  late final GeneratedColumn<String> confirmationCode = GeneratedColumn<String>(
    'confirmation_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    groupId,
    cycleId,
    memberId,
    principalFcfa,
    interestRatePercent,
    dureeJours,
    initiatedByPhone,
    confirmationCode,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Pret> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    if (data.containsKey('est_approximatif')) {
      context.handle(
        _estApproximatifMeta,
        estApproximatif.isAcceptableOrUnknown(
          data['est_approximatif']!,
          _estApproximatifMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('principal_fcfa')) {
      context.handle(
        _principalFcfaMeta,
        principalFcfa.isAcceptableOrUnknown(
          data['principal_fcfa']!,
          _principalFcfaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_principalFcfaMeta);
    }
    if (data.containsKey('interest_rate_percent')) {
      context.handle(
        _interestRatePercentMeta,
        interestRatePercent.isAcceptableOrUnknown(
          data['interest_rate_percent']!,
          _interestRatePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_interestRatePercentMeta);
    }
    if (data.containsKey('duree_jours')) {
      context.handle(
        _dureeJoursMeta,
        dureeJours.isAcceptableOrUnknown(data['duree_jours']!, _dureeJoursMeta),
      );
    }
    if (data.containsKey('initiated_by_phone')) {
      context.handle(
        _initiatedByPhoneMeta,
        initiatedByPhone.isAcceptableOrUnknown(
          data['initiated_by_phone']!,
          _initiatedByPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initiatedByPhoneMeta);
    }
    if (data.containsKey('confirmation_code')) {
      context.handle(
        _confirmationCodeMeta,
        confirmationCode.isAcceptableOrUnknown(
          data['confirmation_code']!,
          _confirmationCodeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pret map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pret(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
      estApproximatif: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}est_approximatif'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      principalFcfa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal_fcfa'],
      )!,
      interestRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate_percent'],
      )!,
      dureeJours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duree_jours'],
      ),
      initiatedByPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initiated_by_phone'],
      )!,
      confirmationCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmation_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PretsTable createAlias(String alias) {
    return $PretsTable(attachedDatabase, alias);
  }
}

class Pret extends DataClass implements Insertable<Pret> {
  final String? previousHash;
  final String hash;

  /// `direct` = créé et vérifié en temps réel via l'app.
  /// `importe` = déclaré rétroactivement (carnet papier, CSV) au moment
  /// où un groupe bascule vers CotisApp. Jamais fusionné avec `direct`
  /// dans le même champ — reste distinguable pour un audit ou un litige.
  final String provenance;

  /// Le carnet papier d'origine n'a pas toujours une date ou un montant
  /// exacts. Ce champ marque une ligne importée dont la précision n'est
  /// pas garantie, plutôt que de forcer une précision que la source
  /// n'avait pas.
  final bool estApproximatif;
  final String id;
  final String groupId;
  final String cycleId;
  final String memberId;
  final int principalFcfa;
  final double interestRatePercent;

  /// Copié depuis `cycle.loanDurationDays` au moment de la création du
  /// prêt (même logique que [interestRatePercent] : figé sur le prêt,
  /// pas relu depuis le cycle au moment du calcul). Nullable : un prêt
  /// importé d'un historique papier peut ne pas avoir de durée connue —
  /// dans ce cas [LoanBalanceCalculator] applique l'intérêt une seule
  /// fois, sans recomposition, plutôt que de deviner une durée.
  final int? dureeJours;
  final String initiatedByPhone;

  /// Code de confirmation que le membre doit saisir pour valider le
  /// prêt. En mode dev, un code de test fixe (voir DevAuthGateway) ;
  /// en production, un code envoyé par SMS via Supabase Auth/Twilio.
  /// Nullable : un membre sans téléphone (voir [Members]) n'a pas de
  /// code à recevoir — son prêt est confirmé par signature à la place
  /// (voir [PretConfirmations]).
  final String? confirmationCode;
  final DateTime createdAt;
  const Pret({
    this.previousHash,
    required this.hash,
    required this.provenance,
    required this.estApproximatif,
    required this.id,
    required this.groupId,
    required this.cycleId,
    required this.memberId,
    required this.principalFcfa,
    required this.interestRatePercent,
    this.dureeJours,
    required this.initiatedByPhone,
    this.confirmationCode,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['provenance'] = Variable<String>(provenance);
    map['est_approximatif'] = Variable<bool>(estApproximatif);
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['cycle_id'] = Variable<String>(cycleId);
    map['member_id'] = Variable<String>(memberId);
    map['principal_fcfa'] = Variable<int>(principalFcfa);
    map['interest_rate_percent'] = Variable<double>(interestRatePercent);
    if (!nullToAbsent || dureeJours != null) {
      map['duree_jours'] = Variable<int>(dureeJours);
    }
    map['initiated_by_phone'] = Variable<String>(initiatedByPhone);
    if (!nullToAbsent || confirmationCode != null) {
      map['confirmation_code'] = Variable<String>(confirmationCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PretsCompanion toCompanion(bool nullToAbsent) {
    return PretsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
      id: Value(id),
      groupId: Value(groupId),
      cycleId: Value(cycleId),
      memberId: Value(memberId),
      principalFcfa: Value(principalFcfa),
      interestRatePercent: Value(interestRatePercent),
      dureeJours: dureeJours == null && nullToAbsent
          ? const Value.absent()
          : Value(dureeJours),
      initiatedByPhone: Value(initiatedByPhone),
      confirmationCode: confirmationCode == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmationCode),
      createdAt: Value(createdAt),
    );
  }

  factory Pret.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pret(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      provenance: serializer.fromJson<String>(json['provenance']),
      estApproximatif: serializer.fromJson<bool>(json['estApproximatif']),
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      principalFcfa: serializer.fromJson<int>(json['principalFcfa']),
      interestRatePercent: serializer.fromJson<double>(
        json['interestRatePercent'],
      ),
      dureeJours: serializer.fromJson<int?>(json['dureeJours']),
      initiatedByPhone: serializer.fromJson<String>(json['initiatedByPhone']),
      confirmationCode: serializer.fromJson<String?>(json['confirmationCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'provenance': serializer.toJson<String>(provenance),
      'estApproximatif': serializer.toJson<bool>(estApproximatif),
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'cycleId': serializer.toJson<String>(cycleId),
      'memberId': serializer.toJson<String>(memberId),
      'principalFcfa': serializer.toJson<int>(principalFcfa),
      'interestRatePercent': serializer.toJson<double>(interestRatePercent),
      'dureeJours': serializer.toJson<int?>(dureeJours),
      'initiatedByPhone': serializer.toJson<String>(initiatedByPhone),
      'confirmationCode': serializer.toJson<String?>(confirmationCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Pret copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? provenance,
    bool? estApproximatif,
    String? id,
    String? groupId,
    String? cycleId,
    String? memberId,
    int? principalFcfa,
    double? interestRatePercent,
    Value<int?> dureeJours = const Value.absent(),
    String? initiatedByPhone,
    Value<String?> confirmationCode = const Value.absent(),
    DateTime? createdAt,
  }) => Pret(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    provenance: provenance ?? this.provenance,
    estApproximatif: estApproximatif ?? this.estApproximatif,
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    cycleId: cycleId ?? this.cycleId,
    memberId: memberId ?? this.memberId,
    principalFcfa: principalFcfa ?? this.principalFcfa,
    interestRatePercent: interestRatePercent ?? this.interestRatePercent,
    dureeJours: dureeJours.present ? dureeJours.value : this.dureeJours,
    initiatedByPhone: initiatedByPhone ?? this.initiatedByPhone,
    confirmationCode: confirmationCode.present
        ? confirmationCode.value
        : this.confirmationCode,
    createdAt: createdAt ?? this.createdAt,
  );
  Pret copyWithCompanion(PretsCompanion data) {
    return Pret(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      estApproximatif: data.estApproximatif.present
          ? data.estApproximatif.value
          : this.estApproximatif,
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      principalFcfa: data.principalFcfa.present
          ? data.principalFcfa.value
          : this.principalFcfa,
      interestRatePercent: data.interestRatePercent.present
          ? data.interestRatePercent.value
          : this.interestRatePercent,
      dureeJours: data.dureeJours.present
          ? data.dureeJours.value
          : this.dureeJours,
      initiatedByPhone: data.initiatedByPhone.present
          ? data.initiatedByPhone.value
          : this.initiatedByPhone,
      confirmationCode: data.confirmationCode.present
          ? data.confirmationCode.value
          : this.confirmationCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pret(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('principalFcfa: $principalFcfa, ')
          ..write('interestRatePercent: $interestRatePercent, ')
          ..write('dureeJours: $dureeJours, ')
          ..write('initiatedByPhone: $initiatedByPhone, ')
          ..write('confirmationCode: $confirmationCode, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    groupId,
    cycleId,
    memberId,
    principalFcfa,
    interestRatePercent,
    dureeJours,
    initiatedByPhone,
    confirmationCode,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pret &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.provenance == this.provenance &&
          other.estApproximatif == this.estApproximatif &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.cycleId == this.cycleId &&
          other.memberId == this.memberId &&
          other.principalFcfa == this.principalFcfa &&
          other.interestRatePercent == this.interestRatePercent &&
          other.dureeJours == this.dureeJours &&
          other.initiatedByPhone == this.initiatedByPhone &&
          other.confirmationCode == this.confirmationCode &&
          other.createdAt == this.createdAt);
}

class PretsCompanion extends UpdateCompanion<Pret> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> provenance;
  final Value<bool> estApproximatif;
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> cycleId;
  final Value<String> memberId;
  final Value<int> principalFcfa;
  final Value<double> interestRatePercent;
  final Value<int?> dureeJours;
  final Value<String> initiatedByPhone;
  final Value<String?> confirmationCode;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PretsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.principalFcfa = const Value.absent(),
    this.interestRatePercent = const Value.absent(),
    this.dureeJours = const Value.absent(),
    this.initiatedByPhone = const Value.absent(),
    this.confirmationCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PretsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    required String id,
    required String groupId,
    required String cycleId,
    required String memberId,
    required int principalFcfa,
    required double interestRatePercent,
    this.dureeJours = const Value.absent(),
    required String initiatedByPhone,
    this.confirmationCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       groupId = Value(groupId),
       cycleId = Value(cycleId),
       memberId = Value(memberId),
       principalFcfa = Value(principalFcfa),
       interestRatePercent = Value(interestRatePercent),
       initiatedByPhone = Value(initiatedByPhone);
  static Insertable<Pret> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? provenance,
    Expression<bool>? estApproximatif,
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? cycleId,
    Expression<String>? memberId,
    Expression<int>? principalFcfa,
    Expression<double>? interestRatePercent,
    Expression<int>? dureeJours,
    Expression<String>? initiatedByPhone,
    Expression<String>? confirmationCode,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (provenance != null) 'provenance': provenance,
      if (estApproximatif != null) 'est_approximatif': estApproximatif,
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (memberId != null) 'member_id': memberId,
      if (principalFcfa != null) 'principal_fcfa': principalFcfa,
      if (interestRatePercent != null)
        'interest_rate_percent': interestRatePercent,
      if (dureeJours != null) 'duree_jours': dureeJours,
      if (initiatedByPhone != null) 'initiated_by_phone': initiatedByPhone,
      if (confirmationCode != null) 'confirmation_code': confirmationCode,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PretsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? provenance,
    Value<bool>? estApproximatif,
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? cycleId,
    Value<String>? memberId,
    Value<int>? principalFcfa,
    Value<double>? interestRatePercent,
    Value<int?>? dureeJours,
    Value<String>? initiatedByPhone,
    Value<String?>? confirmationCode,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PretsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      provenance: provenance ?? this.provenance,
      estApproximatif: estApproximatif ?? this.estApproximatif,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cycleId: cycleId ?? this.cycleId,
      memberId: memberId ?? this.memberId,
      principalFcfa: principalFcfa ?? this.principalFcfa,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      dureeJours: dureeJours ?? this.dureeJours,
      initiatedByPhone: initiatedByPhone ?? this.initiatedByPhone,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (estApproximatif.present) {
      map['est_approximatif'] = Variable<bool>(estApproximatif.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (principalFcfa.present) {
      map['principal_fcfa'] = Variable<int>(principalFcfa.value);
    }
    if (interestRatePercent.present) {
      map['interest_rate_percent'] = Variable<double>(
        interestRatePercent.value,
      );
    }
    if (dureeJours.present) {
      map['duree_jours'] = Variable<int>(dureeJours.value);
    }
    if (initiatedByPhone.present) {
      map['initiated_by_phone'] = Variable<String>(initiatedByPhone.value);
    }
    if (confirmationCode.present) {
      map['confirmation_code'] = Variable<String>(confirmationCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PretsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('principalFcfa: $principalFcfa, ')
          ..write('interestRatePercent: $interestRatePercent, ')
          ..write('dureeJours: $dureeJours, ')
          ..write('initiatedByPhone: $initiatedByPhone, ')
          ..write('confirmationCode: $confirmationCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PretConfirmationsTable extends PretConfirmations
    with TableInfo<$PretConfirmationsTable, PretConfirmation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PretConfirmationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pretIdMeta = const VerificationMeta('pretId');
  @override
  late final GeneratedColumn<String> pretId = GeneratedColumn<String>(
    'pret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prets (id)',
    ),
  );
  static const VerificationMeta _methodeMeta = const VerificationMeta(
    'methode',
  );
  @override
  late final GeneratedColumn<String> methode = GeneratedColumn<String>(
    'methode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('code'),
  );
  static const VerificationMeta _codeSaisiMeta = const VerificationMeta(
    'codeSaisi',
  );
  @override
  late final GeneratedColumn<String> codeSaisi = GeneratedColumn<String>(
    'code_saisi',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedByPhoneMeta = const VerificationMeta(
    'confirmedByPhone',
  );
  @override
  late final GeneratedColumn<String> confirmedByPhone = GeneratedColumn<String>(
    'confirmed_by_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _witnessPhoneMeta = const VerificationMeta(
    'witnessPhone',
  );
  @override
  late final GeneratedColumn<String> witnessPhone = GeneratedColumn<String>(
    'witness_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signatureDataMeta = const VerificationMeta(
    'signatureData',
  );
  @override
  late final GeneratedColumn<String> signatureData = GeneratedColumn<String>(
    'signature_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    id,
    pretId,
    methode,
    codeSaisi,
    confirmedByPhone,
    witnessPhone,
    signatureData,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pret_confirmations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PretConfirmation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pret_id')) {
      context.handle(
        _pretIdMeta,
        pretId.isAcceptableOrUnknown(data['pret_id']!, _pretIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pretIdMeta);
    }
    if (data.containsKey('methode')) {
      context.handle(
        _methodeMeta,
        methode.isAcceptableOrUnknown(data['methode']!, _methodeMeta),
      );
    }
    if (data.containsKey('code_saisi')) {
      context.handle(
        _codeSaisiMeta,
        codeSaisi.isAcceptableOrUnknown(data['code_saisi']!, _codeSaisiMeta),
      );
    }
    if (data.containsKey('confirmed_by_phone')) {
      context.handle(
        _confirmedByPhoneMeta,
        confirmedByPhone.isAcceptableOrUnknown(
          data['confirmed_by_phone']!,
          _confirmedByPhoneMeta,
        ),
      );
    }
    if (data.containsKey('witness_phone')) {
      context.handle(
        _witnessPhoneMeta,
        witnessPhone.isAcceptableOrUnknown(
          data['witness_phone']!,
          _witnessPhoneMeta,
        ),
      );
    }
    if (data.containsKey('signature_data')) {
      context.handle(
        _signatureDataMeta,
        signatureData.isAcceptableOrUnknown(
          data['signature_data']!,
          _signatureDataMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PretConfirmation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PretConfirmation(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pret_id'],
      )!,
      methode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}methode'],
      )!,
      codeSaisi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_saisi'],
      ),
      confirmedByPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_by_phone'],
      ),
      witnessPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}witness_phone'],
      ),
      signatureData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_data'],
      ),
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      )!,
    );
  }

  @override
  $PretConfirmationsTable createAlias(String alias) {
    return $PretConfirmationsTable(attachedDatabase, alias);
  }
}

class PretConfirmation extends DataClass
    implements Insertable<PretConfirmation> {
  final String? previousHash;
  final String hash;
  final String id;
  final String pretId;
  final String methode;
  final String? codeSaisi;
  final String? confirmedByPhone;
  final String? witnessPhone;
  final String? signatureData;
  final DateTime confirmedAt;
  const PretConfirmation({
    this.previousHash,
    required this.hash,
    required this.id,
    required this.pretId,
    required this.methode,
    this.codeSaisi,
    this.confirmedByPhone,
    this.witnessPhone,
    this.signatureData,
    required this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['id'] = Variable<String>(id);
    map['pret_id'] = Variable<String>(pretId);
    map['methode'] = Variable<String>(methode);
    if (!nullToAbsent || codeSaisi != null) {
      map['code_saisi'] = Variable<String>(codeSaisi);
    }
    if (!nullToAbsent || confirmedByPhone != null) {
      map['confirmed_by_phone'] = Variable<String>(confirmedByPhone);
    }
    if (!nullToAbsent || witnessPhone != null) {
      map['witness_phone'] = Variable<String>(witnessPhone);
    }
    if (!nullToAbsent || signatureData != null) {
      map['signature_data'] = Variable<String>(signatureData);
    }
    map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    return map;
  }

  PretConfirmationsCompanion toCompanion(bool nullToAbsent) {
    return PretConfirmationsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      id: Value(id),
      pretId: Value(pretId),
      methode: Value(methode),
      codeSaisi: codeSaisi == null && nullToAbsent
          ? const Value.absent()
          : Value(codeSaisi),
      confirmedByPhone: confirmedByPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedByPhone),
      witnessPhone: witnessPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(witnessPhone),
      signatureData: signatureData == null && nullToAbsent
          ? const Value.absent()
          : Value(signatureData),
      confirmedAt: Value(confirmedAt),
    );
  }

  factory PretConfirmation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PretConfirmation(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      id: serializer.fromJson<String>(json['id']),
      pretId: serializer.fromJson<String>(json['pretId']),
      methode: serializer.fromJson<String>(json['methode']),
      codeSaisi: serializer.fromJson<String?>(json['codeSaisi']),
      confirmedByPhone: serializer.fromJson<String?>(json['confirmedByPhone']),
      witnessPhone: serializer.fromJson<String?>(json['witnessPhone']),
      signatureData: serializer.fromJson<String?>(json['signatureData']),
      confirmedAt: serializer.fromJson<DateTime>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'id': serializer.toJson<String>(id),
      'pretId': serializer.toJson<String>(pretId),
      'methode': serializer.toJson<String>(methode),
      'codeSaisi': serializer.toJson<String?>(codeSaisi),
      'confirmedByPhone': serializer.toJson<String?>(confirmedByPhone),
      'witnessPhone': serializer.toJson<String?>(witnessPhone),
      'signatureData': serializer.toJson<String?>(signatureData),
      'confirmedAt': serializer.toJson<DateTime>(confirmedAt),
    };
  }

  PretConfirmation copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? id,
    String? pretId,
    String? methode,
    Value<String?> codeSaisi = const Value.absent(),
    Value<String?> confirmedByPhone = const Value.absent(),
    Value<String?> witnessPhone = const Value.absent(),
    Value<String?> signatureData = const Value.absent(),
    DateTime? confirmedAt,
  }) => PretConfirmation(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    id: id ?? this.id,
    pretId: pretId ?? this.pretId,
    methode: methode ?? this.methode,
    codeSaisi: codeSaisi.present ? codeSaisi.value : this.codeSaisi,
    confirmedByPhone: confirmedByPhone.present
        ? confirmedByPhone.value
        : this.confirmedByPhone,
    witnessPhone: witnessPhone.present ? witnessPhone.value : this.witnessPhone,
    signatureData: signatureData.present
        ? signatureData.value
        : this.signatureData,
    confirmedAt: confirmedAt ?? this.confirmedAt,
  );
  PretConfirmation copyWithCompanion(PretConfirmationsCompanion data) {
    return PretConfirmation(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      id: data.id.present ? data.id.value : this.id,
      pretId: data.pretId.present ? data.pretId.value : this.pretId,
      methode: data.methode.present ? data.methode.value : this.methode,
      codeSaisi: data.codeSaisi.present ? data.codeSaisi.value : this.codeSaisi,
      confirmedByPhone: data.confirmedByPhone.present
          ? data.confirmedByPhone.value
          : this.confirmedByPhone,
      witnessPhone: data.witnessPhone.present
          ? data.witnessPhone.value
          : this.witnessPhone,
      signatureData: data.signatureData.present
          ? data.signatureData.value
          : this.signatureData,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PretConfirmation(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('pretId: $pretId, ')
          ..write('methode: $methode, ')
          ..write('codeSaisi: $codeSaisi, ')
          ..write('confirmedByPhone: $confirmedByPhone, ')
          ..write('witnessPhone: $witnessPhone, ')
          ..write('signatureData: $signatureData, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    id,
    pretId,
    methode,
    codeSaisi,
    confirmedByPhone,
    witnessPhone,
    signatureData,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PretConfirmation &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.id == this.id &&
          other.pretId == this.pretId &&
          other.methode == this.methode &&
          other.codeSaisi == this.codeSaisi &&
          other.confirmedByPhone == this.confirmedByPhone &&
          other.witnessPhone == this.witnessPhone &&
          other.signatureData == this.signatureData &&
          other.confirmedAt == this.confirmedAt);
}

class PretConfirmationsCompanion extends UpdateCompanion<PretConfirmation> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> id;
  final Value<String> pretId;
  final Value<String> methode;
  final Value<String?> codeSaisi;
  final Value<String?> confirmedByPhone;
  final Value<String?> witnessPhone;
  final Value<String?> signatureData;
  final Value<DateTime> confirmedAt;
  final Value<int> rowid;
  const PretConfirmationsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.id = const Value.absent(),
    this.pretId = const Value.absent(),
    this.methode = const Value.absent(),
    this.codeSaisi = const Value.absent(),
    this.confirmedByPhone = const Value.absent(),
    this.witnessPhone = const Value.absent(),
    this.signatureData = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PretConfirmationsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    required String id,
    required String pretId,
    this.methode = const Value.absent(),
    this.codeSaisi = const Value.absent(),
    this.confirmedByPhone = const Value.absent(),
    this.witnessPhone = const Value.absent(),
    this.signatureData = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       pretId = Value(pretId);
  static Insertable<PretConfirmation> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? id,
    Expression<String>? pretId,
    Expression<String>? methode,
    Expression<String>? codeSaisi,
    Expression<String>? confirmedByPhone,
    Expression<String>? witnessPhone,
    Expression<String>? signatureData,
    Expression<DateTime>? confirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (id != null) 'id': id,
      if (pretId != null) 'pret_id': pretId,
      if (methode != null) 'methode': methode,
      if (codeSaisi != null) 'code_saisi': codeSaisi,
      if (confirmedByPhone != null) 'confirmed_by_phone': confirmedByPhone,
      if (witnessPhone != null) 'witness_phone': witnessPhone,
      if (signatureData != null) 'signature_data': signatureData,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PretConfirmationsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? id,
    Value<String>? pretId,
    Value<String>? methode,
    Value<String?>? codeSaisi,
    Value<String?>? confirmedByPhone,
    Value<String?>? witnessPhone,
    Value<String?>? signatureData,
    Value<DateTime>? confirmedAt,
    Value<int>? rowid,
  }) {
    return PretConfirmationsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      id: id ?? this.id,
      pretId: pretId ?? this.pretId,
      methode: methode ?? this.methode,
      codeSaisi: codeSaisi ?? this.codeSaisi,
      confirmedByPhone: confirmedByPhone ?? this.confirmedByPhone,
      witnessPhone: witnessPhone ?? this.witnessPhone,
      signatureData: signatureData ?? this.signatureData,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pretId.present) {
      map['pret_id'] = Variable<String>(pretId.value);
    }
    if (methode.present) {
      map['methode'] = Variable<String>(methode.value);
    }
    if (codeSaisi.present) {
      map['code_saisi'] = Variable<String>(codeSaisi.value);
    }
    if (confirmedByPhone.present) {
      map['confirmed_by_phone'] = Variable<String>(confirmedByPhone.value);
    }
    if (witnessPhone.present) {
      map['witness_phone'] = Variable<String>(witnessPhone.value);
    }
    if (signatureData.present) {
      map['signature_data'] = Variable<String>(signatureData.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PretConfirmationsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('pretId: $pretId, ')
          ..write('methode: $methode, ')
          ..write('codeSaisi: $codeSaisi, ')
          ..write('confirmedByPhone: $confirmedByPhone, ')
          ..write('witnessPhone: $witnessPhone, ')
          ..write('signatureData: $signatureData, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PretRemboursementsTable extends PretRemboursements
    with TableInfo<$PretRemboursementsTable, PretRemboursement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PretRemboursementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('direct'),
  );
  static const VerificationMeta _estApproximatifMeta = const VerificationMeta(
    'estApproximatif',
  );
  @override
  late final GeneratedColumn<bool> estApproximatif = GeneratedColumn<bool>(
    'est_approximatif',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("est_approximatif" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pretIdMeta = const VerificationMeta('pretId');
  @override
  late final GeneratedColumn<String> pretId = GeneratedColumn<String>(
    'pret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prets (id)',
    ),
  );
  static const VerificationMeta _montantFcfaMeta = const VerificationMeta(
    'montantFcfa',
  );
  @override
  late final GeneratedColumn<int> montantFcfa = GeneratedColumn<int>(
    'montant_fcfa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedByPhoneMeta = const VerificationMeta(
    'recordedByPhone',
  );
  @override
  late final GeneratedColumn<String> recordedByPhone = GeneratedColumn<String>(
    'recorded_by_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    pretId,
    montantFcfa,
    recordedByPhone,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pret_remboursements';
  @override
  VerificationContext validateIntegrity(
    Insertable<PretRemboursement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    if (data.containsKey('est_approximatif')) {
      context.handle(
        _estApproximatifMeta,
        estApproximatif.isAcceptableOrUnknown(
          data['est_approximatif']!,
          _estApproximatifMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pret_id')) {
      context.handle(
        _pretIdMeta,
        pretId.isAcceptableOrUnknown(data['pret_id']!, _pretIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pretIdMeta);
    }
    if (data.containsKey('montant_fcfa')) {
      context.handle(
        _montantFcfaMeta,
        montantFcfa.isAcceptableOrUnknown(
          data['montant_fcfa']!,
          _montantFcfaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montantFcfaMeta);
    }
    if (data.containsKey('recorded_by_phone')) {
      context.handle(
        _recordedByPhoneMeta,
        recordedByPhone.isAcceptableOrUnknown(
          data['recorded_by_phone']!,
          _recordedByPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedByPhoneMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PretRemboursement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PretRemboursement(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
      estApproximatif: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}est_approximatif'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pret_id'],
      )!,
      montantFcfa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant_fcfa'],
      )!,
      recordedByPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_phone'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $PretRemboursementsTable createAlias(String alias) {
    return $PretRemboursementsTable(attachedDatabase, alias);
  }
}

class PretRemboursement extends DataClass
    implements Insertable<PretRemboursement> {
  final String? previousHash;
  final String hash;

  /// `direct` = créé et vérifié en temps réel via l'app.
  /// `importe` = déclaré rétroactivement (carnet papier, CSV) au moment
  /// où un groupe bascule vers CotisApp. Jamais fusionné avec `direct`
  /// dans le même champ — reste distinguable pour un audit ou un litige.
  final String provenance;

  /// Le carnet papier d'origine n'a pas toujours une date ou un montant
  /// exacts. Ce champ marque une ligne importée dont la précision n'est
  /// pas garantie, plutôt que de forcer une précision que la source
  /// n'avait pas.
  final bool estApproximatif;
  final String id;
  final String pretId;
  final int montantFcfa;
  final String recordedByPhone;
  final DateTime recordedAt;
  const PretRemboursement({
    this.previousHash,
    required this.hash,
    required this.provenance,
    required this.estApproximatif,
    required this.id,
    required this.pretId,
    required this.montantFcfa,
    required this.recordedByPhone,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['provenance'] = Variable<String>(provenance);
    map['est_approximatif'] = Variable<bool>(estApproximatif);
    map['id'] = Variable<String>(id);
    map['pret_id'] = Variable<String>(pretId);
    map['montant_fcfa'] = Variable<int>(montantFcfa);
    map['recorded_by_phone'] = Variable<String>(recordedByPhone);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  PretRemboursementsCompanion toCompanion(bool nullToAbsent) {
    return PretRemboursementsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
      id: Value(id),
      pretId: Value(pretId),
      montantFcfa: Value(montantFcfa),
      recordedByPhone: Value(recordedByPhone),
      recordedAt: Value(recordedAt),
    );
  }

  factory PretRemboursement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PretRemboursement(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      provenance: serializer.fromJson<String>(json['provenance']),
      estApproximatif: serializer.fromJson<bool>(json['estApproximatif']),
      id: serializer.fromJson<String>(json['id']),
      pretId: serializer.fromJson<String>(json['pretId']),
      montantFcfa: serializer.fromJson<int>(json['montantFcfa']),
      recordedByPhone: serializer.fromJson<String>(json['recordedByPhone']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'provenance': serializer.toJson<String>(provenance),
      'estApproximatif': serializer.toJson<bool>(estApproximatif),
      'id': serializer.toJson<String>(id),
      'pretId': serializer.toJson<String>(pretId),
      'montantFcfa': serializer.toJson<int>(montantFcfa),
      'recordedByPhone': serializer.toJson<String>(recordedByPhone),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  PretRemboursement copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? provenance,
    bool? estApproximatif,
    String? id,
    String? pretId,
    int? montantFcfa,
    String? recordedByPhone,
    DateTime? recordedAt,
  }) => PretRemboursement(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    provenance: provenance ?? this.provenance,
    estApproximatif: estApproximatif ?? this.estApproximatif,
    id: id ?? this.id,
    pretId: pretId ?? this.pretId,
    montantFcfa: montantFcfa ?? this.montantFcfa,
    recordedByPhone: recordedByPhone ?? this.recordedByPhone,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  PretRemboursement copyWithCompanion(PretRemboursementsCompanion data) {
    return PretRemboursement(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      estApproximatif: data.estApproximatif.present
          ? data.estApproximatif.value
          : this.estApproximatif,
      id: data.id.present ? data.id.value : this.id,
      pretId: data.pretId.present ? data.pretId.value : this.pretId,
      montantFcfa: data.montantFcfa.present
          ? data.montantFcfa.value
          : this.montantFcfa,
      recordedByPhone: data.recordedByPhone.present
          ? data.recordedByPhone.value
          : this.recordedByPhone,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PretRemboursement(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('pretId: $pretId, ')
          ..write('montantFcfa: $montantFcfa, ')
          ..write('recordedByPhone: $recordedByPhone, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    pretId,
    montantFcfa,
    recordedByPhone,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PretRemboursement &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.provenance == this.provenance &&
          other.estApproximatif == this.estApproximatif &&
          other.id == this.id &&
          other.pretId == this.pretId &&
          other.montantFcfa == this.montantFcfa &&
          other.recordedByPhone == this.recordedByPhone &&
          other.recordedAt == this.recordedAt);
}

class PretRemboursementsCompanion extends UpdateCompanion<PretRemboursement> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> provenance;
  final Value<bool> estApproximatif;
  final Value<String> id;
  final Value<String> pretId;
  final Value<int> montantFcfa;
  final Value<String> recordedByPhone;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const PretRemboursementsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    this.id = const Value.absent(),
    this.pretId = const Value.absent(),
    this.montantFcfa = const Value.absent(),
    this.recordedByPhone = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PretRemboursementsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    required String id,
    required String pretId,
    required int montantFcfa,
    required String recordedByPhone,
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       pretId = Value(pretId),
       montantFcfa = Value(montantFcfa),
       recordedByPhone = Value(recordedByPhone);
  static Insertable<PretRemboursement> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? provenance,
    Expression<bool>? estApproximatif,
    Expression<String>? id,
    Expression<String>? pretId,
    Expression<int>? montantFcfa,
    Expression<String>? recordedByPhone,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (provenance != null) 'provenance': provenance,
      if (estApproximatif != null) 'est_approximatif': estApproximatif,
      if (id != null) 'id': id,
      if (pretId != null) 'pret_id': pretId,
      if (montantFcfa != null) 'montant_fcfa': montantFcfa,
      if (recordedByPhone != null) 'recorded_by_phone': recordedByPhone,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PretRemboursementsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? provenance,
    Value<bool>? estApproximatif,
    Value<String>? id,
    Value<String>? pretId,
    Value<int>? montantFcfa,
    Value<String>? recordedByPhone,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return PretRemboursementsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      provenance: provenance ?? this.provenance,
      estApproximatif: estApproximatif ?? this.estApproximatif,
      id: id ?? this.id,
      pretId: pretId ?? this.pretId,
      montantFcfa: montantFcfa ?? this.montantFcfa,
      recordedByPhone: recordedByPhone ?? this.recordedByPhone,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (estApproximatif.present) {
      map['est_approximatif'] = Variable<bool>(estApproximatif.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pretId.present) {
      map['pret_id'] = Variable<String>(pretId.value);
    }
    if (montantFcfa.present) {
      map['montant_fcfa'] = Variable<int>(montantFcfa.value);
    }
    if (recordedByPhone.present) {
      map['recorded_by_phone'] = Variable<String>(recordedByPhone.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PretRemboursementsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('pretId: $pretId, ')
          ..write('montantFcfa: $montantFcfa, ')
          ..write('recordedByPhone: $recordedByPhone, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PretAnnulationsTable extends PretAnnulations
    with TableInfo<$PretAnnulationsTable, PretAnnulation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PretAnnulationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pretIdMeta = const VerificationMeta('pretId');
  @override
  late final GeneratedColumn<String> pretId = GeneratedColumn<String>(
    'pret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prets (id)',
    ),
  );
  static const VerificationMeta _raisonMeta = const VerificationMeta('raison');
  @override
  late final GeneratedColumn<String> raison = GeneratedColumn<String>(
    'raison',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annuleParPhoneMeta = const VerificationMeta(
    'annuleParPhone',
  );
  @override
  late final GeneratedColumn<String> annuleParPhone = GeneratedColumn<String>(
    'annule_par_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annuleAtMeta = const VerificationMeta(
    'annuleAt',
  );
  @override
  late final GeneratedColumn<DateTime> annuleAt = GeneratedColumn<DateTime>(
    'annule_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    id,
    pretId,
    raison,
    annuleParPhone,
    annuleAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pret_annulations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PretAnnulation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pret_id')) {
      context.handle(
        _pretIdMeta,
        pretId.isAcceptableOrUnknown(data['pret_id']!, _pretIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pretIdMeta);
    }
    if (data.containsKey('raison')) {
      context.handle(
        _raisonMeta,
        raison.isAcceptableOrUnknown(data['raison']!, _raisonMeta),
      );
    } else if (isInserting) {
      context.missing(_raisonMeta);
    }
    if (data.containsKey('annule_par_phone')) {
      context.handle(
        _annuleParPhoneMeta,
        annuleParPhone.isAcceptableOrUnknown(
          data['annule_par_phone']!,
          _annuleParPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annuleParPhoneMeta);
    }
    if (data.containsKey('annule_at')) {
      context.handle(
        _annuleAtMeta,
        annuleAt.isAcceptableOrUnknown(data['annule_at']!, _annuleAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PretAnnulation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PretAnnulation(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pret_id'],
      )!,
      raison: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raison'],
      )!,
      annuleParPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annule_par_phone'],
      )!,
      annuleAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}annule_at'],
      )!,
    );
  }

  @override
  $PretAnnulationsTable createAlias(String alias) {
    return $PretAnnulationsTable(attachedDatabase, alias);
  }
}

class PretAnnulation extends DataClass implements Insertable<PretAnnulation> {
  final String? previousHash;
  final String hash;
  final String id;
  final String pretId;
  final String raison;
  final String annuleParPhone;
  final DateTime annuleAt;
  const PretAnnulation({
    this.previousHash,
    required this.hash,
    required this.id,
    required this.pretId,
    required this.raison,
    required this.annuleParPhone,
    required this.annuleAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['id'] = Variable<String>(id);
    map['pret_id'] = Variable<String>(pretId);
    map['raison'] = Variable<String>(raison);
    map['annule_par_phone'] = Variable<String>(annuleParPhone);
    map['annule_at'] = Variable<DateTime>(annuleAt);
    return map;
  }

  PretAnnulationsCompanion toCompanion(bool nullToAbsent) {
    return PretAnnulationsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      id: Value(id),
      pretId: Value(pretId),
      raison: Value(raison),
      annuleParPhone: Value(annuleParPhone),
      annuleAt: Value(annuleAt),
    );
  }

  factory PretAnnulation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PretAnnulation(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      id: serializer.fromJson<String>(json['id']),
      pretId: serializer.fromJson<String>(json['pretId']),
      raison: serializer.fromJson<String>(json['raison']),
      annuleParPhone: serializer.fromJson<String>(json['annuleParPhone']),
      annuleAt: serializer.fromJson<DateTime>(json['annuleAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'id': serializer.toJson<String>(id),
      'pretId': serializer.toJson<String>(pretId),
      'raison': serializer.toJson<String>(raison),
      'annuleParPhone': serializer.toJson<String>(annuleParPhone),
      'annuleAt': serializer.toJson<DateTime>(annuleAt),
    };
  }

  PretAnnulation copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? id,
    String? pretId,
    String? raison,
    String? annuleParPhone,
    DateTime? annuleAt,
  }) => PretAnnulation(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    id: id ?? this.id,
    pretId: pretId ?? this.pretId,
    raison: raison ?? this.raison,
    annuleParPhone: annuleParPhone ?? this.annuleParPhone,
    annuleAt: annuleAt ?? this.annuleAt,
  );
  PretAnnulation copyWithCompanion(PretAnnulationsCompanion data) {
    return PretAnnulation(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      id: data.id.present ? data.id.value : this.id,
      pretId: data.pretId.present ? data.pretId.value : this.pretId,
      raison: data.raison.present ? data.raison.value : this.raison,
      annuleParPhone: data.annuleParPhone.present
          ? data.annuleParPhone.value
          : this.annuleParPhone,
      annuleAt: data.annuleAt.present ? data.annuleAt.value : this.annuleAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PretAnnulation(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('pretId: $pretId, ')
          ..write('raison: $raison, ')
          ..write('annuleParPhone: $annuleParPhone, ')
          ..write('annuleAt: $annuleAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    id,
    pretId,
    raison,
    annuleParPhone,
    annuleAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PretAnnulation &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.id == this.id &&
          other.pretId == this.pretId &&
          other.raison == this.raison &&
          other.annuleParPhone == this.annuleParPhone &&
          other.annuleAt == this.annuleAt);
}

class PretAnnulationsCompanion extends UpdateCompanion<PretAnnulation> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> id;
  final Value<String> pretId;
  final Value<String> raison;
  final Value<String> annuleParPhone;
  final Value<DateTime> annuleAt;
  final Value<int> rowid;
  const PretAnnulationsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.id = const Value.absent(),
    this.pretId = const Value.absent(),
    this.raison = const Value.absent(),
    this.annuleParPhone = const Value.absent(),
    this.annuleAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PretAnnulationsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    required String id,
    required String pretId,
    required String raison,
    required String annuleParPhone,
    this.annuleAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       pretId = Value(pretId),
       raison = Value(raison),
       annuleParPhone = Value(annuleParPhone);
  static Insertable<PretAnnulation> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? id,
    Expression<String>? pretId,
    Expression<String>? raison,
    Expression<String>? annuleParPhone,
    Expression<DateTime>? annuleAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (id != null) 'id': id,
      if (pretId != null) 'pret_id': pretId,
      if (raison != null) 'raison': raison,
      if (annuleParPhone != null) 'annule_par_phone': annuleParPhone,
      if (annuleAt != null) 'annule_at': annuleAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PretAnnulationsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? id,
    Value<String>? pretId,
    Value<String>? raison,
    Value<String>? annuleParPhone,
    Value<DateTime>? annuleAt,
    Value<int>? rowid,
  }) {
    return PretAnnulationsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      id: id ?? this.id,
      pretId: pretId ?? this.pretId,
      raison: raison ?? this.raison,
      annuleParPhone: annuleParPhone ?? this.annuleParPhone,
      annuleAt: annuleAt ?? this.annuleAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pretId.present) {
      map['pret_id'] = Variable<String>(pretId.value);
    }
    if (raison.present) {
      map['raison'] = Variable<String>(raison.value);
    }
    if (annuleParPhone.present) {
      map['annule_par_phone'] = Variable<String>(annuleParPhone.value);
    }
    if (annuleAt.present) {
      map['annule_at'] = Variable<DateTime>(annuleAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PretAnnulationsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('pretId: $pretId, ')
          ..write('raison: $raison, ')
          ..write('annuleParPhone: $annuleParPhone, ')
          ..write('annuleAt: $annuleAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AmendesTable extends Amendes with TableInfo<$AmendesTable, Amende> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmendesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('direct'),
  );
  static const VerificationMeta _estApproximatifMeta = const VerificationMeta(
    'estApproximatif',
  );
  @override
  late final GeneratedColumn<bool> estApproximatif = GeneratedColumn<bool>(
    'est_approximatif',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("est_approximatif" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _montantFcfaMeta = const VerificationMeta(
    'montantFcfa',
  );
  @override
  late final GeneratedColumn<int> montantFcfa = GeneratedColumn<int>(
    'montant_fcfa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motifMeta = const VerificationMeta('motif');
  @override
  late final GeneratedColumn<String> motif = GeneratedColumn<String>(
    'motif',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedByPhoneMeta = const VerificationMeta(
    'recordedByPhone',
  );
  @override
  late final GeneratedColumn<String> recordedByPhone = GeneratedColumn<String>(
    'recorded_by_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _estAutoGenereeMeta = const VerificationMeta(
    'estAutoGeneree',
  );
  @override
  late final GeneratedColumn<bool> estAutoGeneree = GeneratedColumn<bool>(
    'est_auto_generee',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("est_auto_generee" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    groupId,
    cycleId,
    memberId,
    montantFcfa,
    motif,
    recordedByPhone,
    recordedAt,
    estAutoGeneree,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amendes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Amende> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    if (data.containsKey('est_approximatif')) {
      context.handle(
        _estApproximatifMeta,
        estApproximatif.isAcceptableOrUnknown(
          data['est_approximatif']!,
          _estApproximatifMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('montant_fcfa')) {
      context.handle(
        _montantFcfaMeta,
        montantFcfa.isAcceptableOrUnknown(
          data['montant_fcfa']!,
          _montantFcfaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montantFcfaMeta);
    }
    if (data.containsKey('motif')) {
      context.handle(
        _motifMeta,
        motif.isAcceptableOrUnknown(data['motif']!, _motifMeta),
      );
    } else if (isInserting) {
      context.missing(_motifMeta);
    }
    if (data.containsKey('recorded_by_phone')) {
      context.handle(
        _recordedByPhoneMeta,
        recordedByPhone.isAcceptableOrUnknown(
          data['recorded_by_phone']!,
          _recordedByPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedByPhoneMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('est_auto_generee')) {
      context.handle(
        _estAutoGenereeMeta,
        estAutoGeneree.isAcceptableOrUnknown(
          data['est_auto_generee']!,
          _estAutoGenereeMeta,
        ),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Amende map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Amende(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
      estApproximatif: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}est_approximatif'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      montantFcfa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant_fcfa'],
      )!,
      motif: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motif'],
      )!,
      recordedByPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_phone'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      estAutoGeneree: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}est_auto_generee'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $AmendesTable createAlias(String alias) {
    return $AmendesTable(attachedDatabase, alias);
  }
}

class Amende extends DataClass implements Insertable<Amende> {
  final String? previousHash;
  final String hash;

  /// `direct` = créé et vérifié en temps réel via l'app.
  /// `importe` = déclaré rétroactivement (carnet papier, CSV) au moment
  /// où un groupe bascule vers CotisApp. Jamais fusionné avec `direct`
  /// dans le même champ — reste distinguable pour un audit ou un litige.
  final String provenance;

  /// Le carnet papier d'origine n'a pas toujours une date ou un montant
  /// exacts. Ce champ marque une ligne importée dont la précision n'est
  /// pas garantie, plutôt que de forcer une précision que la source
  /// n'avait pas.
  final bool estApproximatif;
  final String id;
  final String groupId;
  final String cycleId;
  final String memberId;
  final int montantFcfa;
  final String motif;
  final String recordedByPhone;
  final DateTime recordedAt;

  /// Vrai si créée automatiquement pour une échéance manquée (skill
  /// avec-business-rules, section "Retard de cotisation"), plutôt que
  /// saisie librement par l'agent. Sert à cibler les amendes proposées à
  /// la revue de l'agent à la séance suivante — voir
  /// [AppDatabase.amendesEnAttenteRevue].
  final bool estAutoGeneree;

  /// Renseigné quand l'agent a explicitement confirmé une amende
  /// auto-générée à la séance de revue — évite qu'elle réapparaisse
  /// indéfiniment dans la liste à revoir une fois traitée.
  final DateTime? confirmedAt;
  const Amende({
    this.previousHash,
    required this.hash,
    required this.provenance,
    required this.estApproximatif,
    required this.id,
    required this.groupId,
    required this.cycleId,
    required this.memberId,
    required this.montantFcfa,
    required this.motif,
    required this.recordedByPhone,
    required this.recordedAt,
    required this.estAutoGeneree,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['provenance'] = Variable<String>(provenance);
    map['est_approximatif'] = Variable<bool>(estApproximatif);
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['cycle_id'] = Variable<String>(cycleId);
    map['member_id'] = Variable<String>(memberId);
    map['montant_fcfa'] = Variable<int>(montantFcfa);
    map['motif'] = Variable<String>(motif);
    map['recorded_by_phone'] = Variable<String>(recordedByPhone);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['est_auto_generee'] = Variable<bool>(estAutoGeneree);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  AmendesCompanion toCompanion(bool nullToAbsent) {
    return AmendesCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
      id: Value(id),
      groupId: Value(groupId),
      cycleId: Value(cycleId),
      memberId: Value(memberId),
      montantFcfa: Value(montantFcfa),
      motif: Value(motif),
      recordedByPhone: Value(recordedByPhone),
      recordedAt: Value(recordedAt),
      estAutoGeneree: Value(estAutoGeneree),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory Amende.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Amende(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      provenance: serializer.fromJson<String>(json['provenance']),
      estApproximatif: serializer.fromJson<bool>(json['estApproximatif']),
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      montantFcfa: serializer.fromJson<int>(json['montantFcfa']),
      motif: serializer.fromJson<String>(json['motif']),
      recordedByPhone: serializer.fromJson<String>(json['recordedByPhone']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      estAutoGeneree: serializer.fromJson<bool>(json['estAutoGeneree']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'provenance': serializer.toJson<String>(provenance),
      'estApproximatif': serializer.toJson<bool>(estApproximatif),
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'cycleId': serializer.toJson<String>(cycleId),
      'memberId': serializer.toJson<String>(memberId),
      'montantFcfa': serializer.toJson<int>(montantFcfa),
      'motif': serializer.toJson<String>(motif),
      'recordedByPhone': serializer.toJson<String>(recordedByPhone),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'estAutoGeneree': serializer.toJson<bool>(estAutoGeneree),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  Amende copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? provenance,
    bool? estApproximatif,
    String? id,
    String? groupId,
    String? cycleId,
    String? memberId,
    int? montantFcfa,
    String? motif,
    String? recordedByPhone,
    DateTime? recordedAt,
    bool? estAutoGeneree,
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => Amende(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    provenance: provenance ?? this.provenance,
    estApproximatif: estApproximatif ?? this.estApproximatif,
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    cycleId: cycleId ?? this.cycleId,
    memberId: memberId ?? this.memberId,
    montantFcfa: montantFcfa ?? this.montantFcfa,
    motif: motif ?? this.motif,
    recordedByPhone: recordedByPhone ?? this.recordedByPhone,
    recordedAt: recordedAt ?? this.recordedAt,
    estAutoGeneree: estAutoGeneree ?? this.estAutoGeneree,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  Amende copyWithCompanion(AmendesCompanion data) {
    return Amende(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      estApproximatif: data.estApproximatif.present
          ? data.estApproximatif.value
          : this.estApproximatif,
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      montantFcfa: data.montantFcfa.present
          ? data.montantFcfa.value
          : this.montantFcfa,
      motif: data.motif.present ? data.motif.value : this.motif,
      recordedByPhone: data.recordedByPhone.present
          ? data.recordedByPhone.value
          : this.recordedByPhone,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      estAutoGeneree: data.estAutoGeneree.present
          ? data.estAutoGeneree.value
          : this.estAutoGeneree,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Amende(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('montantFcfa: $montantFcfa, ')
          ..write('motif: $motif, ')
          ..write('recordedByPhone: $recordedByPhone, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('estAutoGeneree: $estAutoGeneree, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    groupId,
    cycleId,
    memberId,
    montantFcfa,
    motif,
    recordedByPhone,
    recordedAt,
    estAutoGeneree,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Amende &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.provenance == this.provenance &&
          other.estApproximatif == this.estApproximatif &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.cycleId == this.cycleId &&
          other.memberId == this.memberId &&
          other.montantFcfa == this.montantFcfa &&
          other.motif == this.motif &&
          other.recordedByPhone == this.recordedByPhone &&
          other.recordedAt == this.recordedAt &&
          other.estAutoGeneree == this.estAutoGeneree &&
          other.confirmedAt == this.confirmedAt);
}

class AmendesCompanion extends UpdateCompanion<Amende> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> provenance;
  final Value<bool> estApproximatif;
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> cycleId;
  final Value<String> memberId;
  final Value<int> montantFcfa;
  final Value<String> motif;
  final Value<String> recordedByPhone;
  final Value<DateTime> recordedAt;
  final Value<bool> estAutoGeneree;
  final Value<DateTime?> confirmedAt;
  final Value<int> rowid;
  const AmendesCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.montantFcfa = const Value.absent(),
    this.motif = const Value.absent(),
    this.recordedByPhone = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.estAutoGeneree = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AmendesCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    required String id,
    required String groupId,
    required String cycleId,
    required String memberId,
    required int montantFcfa,
    required String motif,
    required String recordedByPhone,
    this.recordedAt = const Value.absent(),
    this.estAutoGeneree = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       groupId = Value(groupId),
       cycleId = Value(cycleId),
       memberId = Value(memberId),
       montantFcfa = Value(montantFcfa),
       motif = Value(motif),
       recordedByPhone = Value(recordedByPhone);
  static Insertable<Amende> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? provenance,
    Expression<bool>? estApproximatif,
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? cycleId,
    Expression<String>? memberId,
    Expression<int>? montantFcfa,
    Expression<String>? motif,
    Expression<String>? recordedByPhone,
    Expression<DateTime>? recordedAt,
    Expression<bool>? estAutoGeneree,
    Expression<DateTime>? confirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (provenance != null) 'provenance': provenance,
      if (estApproximatif != null) 'est_approximatif': estApproximatif,
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (memberId != null) 'member_id': memberId,
      if (montantFcfa != null) 'montant_fcfa': montantFcfa,
      if (motif != null) 'motif': motif,
      if (recordedByPhone != null) 'recorded_by_phone': recordedByPhone,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (estAutoGeneree != null) 'est_auto_generee': estAutoGeneree,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AmendesCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? provenance,
    Value<bool>? estApproximatif,
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? cycleId,
    Value<String>? memberId,
    Value<int>? montantFcfa,
    Value<String>? motif,
    Value<String>? recordedByPhone,
    Value<DateTime>? recordedAt,
    Value<bool>? estAutoGeneree,
    Value<DateTime?>? confirmedAt,
    Value<int>? rowid,
  }) {
    return AmendesCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      provenance: provenance ?? this.provenance,
      estApproximatif: estApproximatif ?? this.estApproximatif,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cycleId: cycleId ?? this.cycleId,
      memberId: memberId ?? this.memberId,
      montantFcfa: montantFcfa ?? this.montantFcfa,
      motif: motif ?? this.motif,
      recordedByPhone: recordedByPhone ?? this.recordedByPhone,
      recordedAt: recordedAt ?? this.recordedAt,
      estAutoGeneree: estAutoGeneree ?? this.estAutoGeneree,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (estApproximatif.present) {
      map['est_approximatif'] = Variable<bool>(estApproximatif.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (montantFcfa.present) {
      map['montant_fcfa'] = Variable<int>(montantFcfa.value);
    }
    if (motif.present) {
      map['motif'] = Variable<String>(motif.value);
    }
    if (recordedByPhone.present) {
      map['recorded_by_phone'] = Variable<String>(recordedByPhone.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (estAutoGeneree.present) {
      map['est_auto_generee'] = Variable<bool>(estAutoGeneree.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmendesCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('montantFcfa: $montantFcfa, ')
          ..write('motif: $motif, ')
          ..write('recordedByPhone: $recordedByPhone, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('estAutoGeneree: $estAutoGeneree, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AmendeAnnulationsTable extends AmendeAnnulations
    with TableInfo<$AmendeAnnulationsTable, AmendeAnnulation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmendeAnnulationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amendeIdMeta = const VerificationMeta(
    'amendeId',
  );
  @override
  late final GeneratedColumn<String> amendeId = GeneratedColumn<String>(
    'amende_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES amendes (id)',
    ),
  );
  static const VerificationMeta _raisonMeta = const VerificationMeta('raison');
  @override
  late final GeneratedColumn<String> raison = GeneratedColumn<String>(
    'raison',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annuleParPhoneMeta = const VerificationMeta(
    'annuleParPhone',
  );
  @override
  late final GeneratedColumn<String> annuleParPhone = GeneratedColumn<String>(
    'annule_par_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annuleAtMeta = const VerificationMeta(
    'annuleAt',
  );
  @override
  late final GeneratedColumn<DateTime> annuleAt = GeneratedColumn<DateTime>(
    'annule_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    id,
    amendeId,
    raison,
    annuleParPhone,
    annuleAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amende_annulations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AmendeAnnulation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amende_id')) {
      context.handle(
        _amendeIdMeta,
        amendeId.isAcceptableOrUnknown(data['amende_id']!, _amendeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_amendeIdMeta);
    }
    if (data.containsKey('raison')) {
      context.handle(
        _raisonMeta,
        raison.isAcceptableOrUnknown(data['raison']!, _raisonMeta),
      );
    } else if (isInserting) {
      context.missing(_raisonMeta);
    }
    if (data.containsKey('annule_par_phone')) {
      context.handle(
        _annuleParPhoneMeta,
        annuleParPhone.isAcceptableOrUnknown(
          data['annule_par_phone']!,
          _annuleParPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annuleParPhoneMeta);
    }
    if (data.containsKey('annule_at')) {
      context.handle(
        _annuleAtMeta,
        annuleAt.isAcceptableOrUnknown(data['annule_at']!, _annuleAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AmendeAnnulation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AmendeAnnulation(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amendeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amende_id'],
      )!,
      raison: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raison'],
      )!,
      annuleParPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annule_par_phone'],
      )!,
      annuleAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}annule_at'],
      )!,
    );
  }

  @override
  $AmendeAnnulationsTable createAlias(String alias) {
    return $AmendeAnnulationsTable(attachedDatabase, alias);
  }
}

class AmendeAnnulation extends DataClass
    implements Insertable<AmendeAnnulation> {
  final String? previousHash;
  final String hash;
  final String id;
  final String amendeId;
  final String raison;
  final String annuleParPhone;
  final DateTime annuleAt;
  const AmendeAnnulation({
    this.previousHash,
    required this.hash,
    required this.id,
    required this.amendeId,
    required this.raison,
    required this.annuleParPhone,
    required this.annuleAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['id'] = Variable<String>(id);
    map['amende_id'] = Variable<String>(amendeId);
    map['raison'] = Variable<String>(raison);
    map['annule_par_phone'] = Variable<String>(annuleParPhone);
    map['annule_at'] = Variable<DateTime>(annuleAt);
    return map;
  }

  AmendeAnnulationsCompanion toCompanion(bool nullToAbsent) {
    return AmendeAnnulationsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      id: Value(id),
      amendeId: Value(amendeId),
      raison: Value(raison),
      annuleParPhone: Value(annuleParPhone),
      annuleAt: Value(annuleAt),
    );
  }

  factory AmendeAnnulation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AmendeAnnulation(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      id: serializer.fromJson<String>(json['id']),
      amendeId: serializer.fromJson<String>(json['amendeId']),
      raison: serializer.fromJson<String>(json['raison']),
      annuleParPhone: serializer.fromJson<String>(json['annuleParPhone']),
      annuleAt: serializer.fromJson<DateTime>(json['annuleAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'id': serializer.toJson<String>(id),
      'amendeId': serializer.toJson<String>(amendeId),
      'raison': serializer.toJson<String>(raison),
      'annuleParPhone': serializer.toJson<String>(annuleParPhone),
      'annuleAt': serializer.toJson<DateTime>(annuleAt),
    };
  }

  AmendeAnnulation copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? id,
    String? amendeId,
    String? raison,
    String? annuleParPhone,
    DateTime? annuleAt,
  }) => AmendeAnnulation(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    id: id ?? this.id,
    amendeId: amendeId ?? this.amendeId,
    raison: raison ?? this.raison,
    annuleParPhone: annuleParPhone ?? this.annuleParPhone,
    annuleAt: annuleAt ?? this.annuleAt,
  );
  AmendeAnnulation copyWithCompanion(AmendeAnnulationsCompanion data) {
    return AmendeAnnulation(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      id: data.id.present ? data.id.value : this.id,
      amendeId: data.amendeId.present ? data.amendeId.value : this.amendeId,
      raison: data.raison.present ? data.raison.value : this.raison,
      annuleParPhone: data.annuleParPhone.present
          ? data.annuleParPhone.value
          : this.annuleParPhone,
      annuleAt: data.annuleAt.present ? data.annuleAt.value : this.annuleAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AmendeAnnulation(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('amendeId: $amendeId, ')
          ..write('raison: $raison, ')
          ..write('annuleParPhone: $annuleParPhone, ')
          ..write('annuleAt: $annuleAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    id,
    amendeId,
    raison,
    annuleParPhone,
    annuleAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AmendeAnnulation &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.id == this.id &&
          other.amendeId == this.amendeId &&
          other.raison == this.raison &&
          other.annuleParPhone == this.annuleParPhone &&
          other.annuleAt == this.annuleAt);
}

class AmendeAnnulationsCompanion extends UpdateCompanion<AmendeAnnulation> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> id;
  final Value<String> amendeId;
  final Value<String> raison;
  final Value<String> annuleParPhone;
  final Value<DateTime> annuleAt;
  final Value<int> rowid;
  const AmendeAnnulationsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.id = const Value.absent(),
    this.amendeId = const Value.absent(),
    this.raison = const Value.absent(),
    this.annuleParPhone = const Value.absent(),
    this.annuleAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AmendeAnnulationsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    required String id,
    required String amendeId,
    required String raison,
    required String annuleParPhone,
    this.annuleAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       amendeId = Value(amendeId),
       raison = Value(raison),
       annuleParPhone = Value(annuleParPhone);
  static Insertable<AmendeAnnulation> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? id,
    Expression<String>? amendeId,
    Expression<String>? raison,
    Expression<String>? annuleParPhone,
    Expression<DateTime>? annuleAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (id != null) 'id': id,
      if (amendeId != null) 'amende_id': amendeId,
      if (raison != null) 'raison': raison,
      if (annuleParPhone != null) 'annule_par_phone': annuleParPhone,
      if (annuleAt != null) 'annule_at': annuleAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AmendeAnnulationsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? id,
    Value<String>? amendeId,
    Value<String>? raison,
    Value<String>? annuleParPhone,
    Value<DateTime>? annuleAt,
    Value<int>? rowid,
  }) {
    return AmendeAnnulationsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      id: id ?? this.id,
      amendeId: amendeId ?? this.amendeId,
      raison: raison ?? this.raison,
      annuleParPhone: annuleParPhone ?? this.annuleParPhone,
      annuleAt: annuleAt ?? this.annuleAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amendeId.present) {
      map['amende_id'] = Variable<String>(amendeId.value);
    }
    if (raison.present) {
      map['raison'] = Variable<String>(raison.value);
    }
    if (annuleParPhone.present) {
      map['annule_par_phone'] = Variable<String>(annuleParPhone.value);
    }
    if (annuleAt.present) {
      map['annule_at'] = Variable<DateTime>(annuleAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmendeAnnulationsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('id: $id, ')
          ..write('amendeId: $amendeId, ')
          ..write('raison: $raison, ')
          ..write('annuleParPhone: $annuleParPhone, ')
          ..write('annuleAt: $annuleAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FondsSolidariteContributionsTable extends FondsSolidariteContributions
    with
        TableInfo<
          $FondsSolidariteContributionsTable,
          FondsSolidariteContribution
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FondsSolidariteContributionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('direct'),
  );
  static const VerificationMeta _estApproximatifMeta = const VerificationMeta(
    'estApproximatif',
  );
  @override
  late final GeneratedColumn<bool> estApproximatif = GeneratedColumn<bool>(
    'est_approximatif',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("est_approximatif" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _cycleIdMeta = const VerificationMeta(
    'cycleId',
  );
  @override
  late final GeneratedColumn<String> cycleId = GeneratedColumn<String>(
    'cycle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cycles (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _montantFcfaMeta = const VerificationMeta(
    'montantFcfa',
  );
  @override
  late final GeneratedColumn<int> montantFcfa = GeneratedColumn<int>(
    'montant_fcfa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motifMeta = const VerificationMeta('motif');
  @override
  late final GeneratedColumn<String> motif = GeneratedColumn<String>(
    'motif',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedByPhoneMeta = const VerificationMeta(
    'recordedByPhone',
  );
  @override
  late final GeneratedColumn<String> recordedByPhone = GeneratedColumn<String>(
    'recorded_by_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    groupId,
    cycleId,
    memberId,
    montantFcfa,
    motif,
    recordedByPhone,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fonds_solidarite_contributions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FondsSolidariteContribution> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    if (data.containsKey('est_approximatif')) {
      context.handle(
        _estApproximatifMeta,
        estApproximatif.isAcceptableOrUnknown(
          data['est_approximatif']!,
          _estApproximatifMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('cycle_id')) {
      context.handle(
        _cycleIdMeta,
        cycleId.isAcceptableOrUnknown(data['cycle_id']!, _cycleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cycleIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    }
    if (data.containsKey('montant_fcfa')) {
      context.handle(
        _montantFcfaMeta,
        montantFcfa.isAcceptableOrUnknown(
          data['montant_fcfa']!,
          _montantFcfaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montantFcfaMeta);
    }
    if (data.containsKey('motif')) {
      context.handle(
        _motifMeta,
        motif.isAcceptableOrUnknown(data['motif']!, _motifMeta),
      );
    } else if (isInserting) {
      context.missing(_motifMeta);
    }
    if (data.containsKey('recorded_by_phone')) {
      context.handle(
        _recordedByPhoneMeta,
        recordedByPhone.isAcceptableOrUnknown(
          data['recorded_by_phone']!,
          _recordedByPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedByPhoneMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FondsSolidariteContribution map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FondsSolidariteContribution(
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
      estApproximatif: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}est_approximatif'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      cycleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cycle_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      ),
      montantFcfa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant_fcfa'],
      )!,
      motif: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motif'],
      )!,
      recordedByPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_phone'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $FondsSolidariteContributionsTable createAlias(String alias) {
    return $FondsSolidariteContributionsTable(attachedDatabase, alias);
  }
}

class FondsSolidariteContribution extends DataClass
    implements Insertable<FondsSolidariteContribution> {
  final String? previousHash;
  final String hash;

  /// `direct` = créé et vérifié en temps réel via l'app.
  /// `importe` = déclaré rétroactivement (carnet papier, CSV) au moment
  /// où un groupe bascule vers CotisApp. Jamais fusionné avec `direct`
  /// dans le même champ — reste distinguable pour un audit ou un litige.
  final String provenance;

  /// Le carnet papier d'origine n'a pas toujours une date ou un montant
  /// exacts. Ce champ marque une ligne importée dont la précision n'est
  /// pas garantie, plutôt que de forcer une précision que la source
  /// n'avait pas.
  final bool estApproximatif;
  final String id;
  final String groupId;
  final String cycleId;
  final String? memberId;
  final int montantFcfa;
  final String motif;
  final String recordedByPhone;
  final DateTime recordedAt;
  const FondsSolidariteContribution({
    this.previousHash,
    required this.hash,
    required this.provenance,
    required this.estApproximatif,
    required this.id,
    required this.groupId,
    required this.cycleId,
    this.memberId,
    required this.montantFcfa,
    required this.motif,
    required this.recordedByPhone,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || previousHash != null) {
      map['previous_hash'] = Variable<String>(previousHash);
    }
    map['hash'] = Variable<String>(hash);
    map['provenance'] = Variable<String>(provenance);
    map['est_approximatif'] = Variable<bool>(estApproximatif);
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['cycle_id'] = Variable<String>(cycleId);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    map['montant_fcfa'] = Variable<int>(montantFcfa);
    map['motif'] = Variable<String>(motif);
    map['recorded_by_phone'] = Variable<String>(recordedByPhone);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  FondsSolidariteContributionsCompanion toCompanion(bool nullToAbsent) {
    return FondsSolidariteContributionsCompanion(
      previousHash: previousHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previousHash),
      hash: Value(hash),
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
      id: Value(id),
      groupId: Value(groupId),
      cycleId: Value(cycleId),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      montantFcfa: Value(montantFcfa),
      motif: Value(motif),
      recordedByPhone: Value(recordedByPhone),
      recordedAt: Value(recordedAt),
    );
  }

  factory FondsSolidariteContribution.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FondsSolidariteContribution(
      previousHash: serializer.fromJson<String?>(json['previousHash']),
      hash: serializer.fromJson<String>(json['hash']),
      provenance: serializer.fromJson<String>(json['provenance']),
      estApproximatif: serializer.fromJson<bool>(json['estApproximatif']),
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      cycleId: serializer.fromJson<String>(json['cycleId']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      montantFcfa: serializer.fromJson<int>(json['montantFcfa']),
      motif: serializer.fromJson<String>(json['motif']),
      recordedByPhone: serializer.fromJson<String>(json['recordedByPhone']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'previousHash': serializer.toJson<String?>(previousHash),
      'hash': serializer.toJson<String>(hash),
      'provenance': serializer.toJson<String>(provenance),
      'estApproximatif': serializer.toJson<bool>(estApproximatif),
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'cycleId': serializer.toJson<String>(cycleId),
      'memberId': serializer.toJson<String?>(memberId),
      'montantFcfa': serializer.toJson<int>(montantFcfa),
      'motif': serializer.toJson<String>(motif),
      'recordedByPhone': serializer.toJson<String>(recordedByPhone),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  FondsSolidariteContribution copyWith({
    Value<String?> previousHash = const Value.absent(),
    String? hash,
    String? provenance,
    bool? estApproximatif,
    String? id,
    String? groupId,
    String? cycleId,
    Value<String?> memberId = const Value.absent(),
    int? montantFcfa,
    String? motif,
    String? recordedByPhone,
    DateTime? recordedAt,
  }) => FondsSolidariteContribution(
    previousHash: previousHash.present ? previousHash.value : this.previousHash,
    hash: hash ?? this.hash,
    provenance: provenance ?? this.provenance,
    estApproximatif: estApproximatif ?? this.estApproximatif,
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    cycleId: cycleId ?? this.cycleId,
    memberId: memberId.present ? memberId.value : this.memberId,
    montantFcfa: montantFcfa ?? this.montantFcfa,
    motif: motif ?? this.motif,
    recordedByPhone: recordedByPhone ?? this.recordedByPhone,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  FondsSolidariteContribution copyWithCompanion(
    FondsSolidariteContributionsCompanion data,
  ) {
    return FondsSolidariteContribution(
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      hash: data.hash.present ? data.hash.value : this.hash,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      estApproximatif: data.estApproximatif.present
          ? data.estApproximatif.value
          : this.estApproximatif,
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      cycleId: data.cycleId.present ? data.cycleId.value : this.cycleId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      montantFcfa: data.montantFcfa.present
          ? data.montantFcfa.value
          : this.montantFcfa,
      motif: data.motif.present ? data.motif.value : this.motif,
      recordedByPhone: data.recordedByPhone.present
          ? data.recordedByPhone.value
          : this.recordedByPhone,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FondsSolidariteContribution(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('montantFcfa: $montantFcfa, ')
          ..write('motif: $motif, ')
          ..write('recordedByPhone: $recordedByPhone, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    previousHash,
    hash,
    provenance,
    estApproximatif,
    id,
    groupId,
    cycleId,
    memberId,
    montantFcfa,
    motif,
    recordedByPhone,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FondsSolidariteContribution &&
          other.previousHash == this.previousHash &&
          other.hash == this.hash &&
          other.provenance == this.provenance &&
          other.estApproximatif == this.estApproximatif &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.cycleId == this.cycleId &&
          other.memberId == this.memberId &&
          other.montantFcfa == this.montantFcfa &&
          other.motif == this.motif &&
          other.recordedByPhone == this.recordedByPhone &&
          other.recordedAt == this.recordedAt);
}

class FondsSolidariteContributionsCompanion
    extends UpdateCompanion<FondsSolidariteContribution> {
  final Value<String?> previousHash;
  final Value<String> hash;
  final Value<String> provenance;
  final Value<bool> estApproximatif;
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> cycleId;
  final Value<String?> memberId;
  final Value<int> montantFcfa;
  final Value<String> motif;
  final Value<String> recordedByPhone;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const FondsSolidariteContributionsCompanion({
    this.previousHash = const Value.absent(),
    this.hash = const Value.absent(),
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.cycleId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.montantFcfa = const Value.absent(),
    this.motif = const Value.absent(),
    this.recordedByPhone = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FondsSolidariteContributionsCompanion.insert({
    this.previousHash = const Value.absent(),
    required String hash,
    this.provenance = const Value.absent(),
    this.estApproximatif = const Value.absent(),
    required String id,
    required String groupId,
    required String cycleId,
    this.memberId = const Value.absent(),
    required int montantFcfa,
    required String motif,
    required String recordedByPhone,
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       id = Value(id),
       groupId = Value(groupId),
       cycleId = Value(cycleId),
       montantFcfa = Value(montantFcfa),
       motif = Value(motif),
       recordedByPhone = Value(recordedByPhone);
  static Insertable<FondsSolidariteContribution> custom({
    Expression<String>? previousHash,
    Expression<String>? hash,
    Expression<String>? provenance,
    Expression<bool>? estApproximatif,
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? cycleId,
    Expression<String>? memberId,
    Expression<int>? montantFcfa,
    Expression<String>? motif,
    Expression<String>? recordedByPhone,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (previousHash != null) 'previous_hash': previousHash,
      if (hash != null) 'hash': hash,
      if (provenance != null) 'provenance': provenance,
      if (estApproximatif != null) 'est_approximatif': estApproximatif,
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (memberId != null) 'member_id': memberId,
      if (montantFcfa != null) 'montant_fcfa': montantFcfa,
      if (motif != null) 'motif': motif,
      if (recordedByPhone != null) 'recorded_by_phone': recordedByPhone,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FondsSolidariteContributionsCompanion copyWith({
    Value<String?>? previousHash,
    Value<String>? hash,
    Value<String>? provenance,
    Value<bool>? estApproximatif,
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? cycleId,
    Value<String?>? memberId,
    Value<int>? montantFcfa,
    Value<String>? motif,
    Value<String>? recordedByPhone,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return FondsSolidariteContributionsCompanion(
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      provenance: provenance ?? this.provenance,
      estApproximatif: estApproximatif ?? this.estApproximatif,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      cycleId: cycleId ?? this.cycleId,
      memberId: memberId ?? this.memberId,
      montantFcfa: montantFcfa ?? this.montantFcfa,
      motif: motif ?? this.motif,
      recordedByPhone: recordedByPhone ?? this.recordedByPhone,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (estApproximatif.present) {
      map['est_approximatif'] = Variable<bool>(estApproximatif.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (cycleId.present) {
      map['cycle_id'] = Variable<String>(cycleId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (montantFcfa.present) {
      map['montant_fcfa'] = Variable<int>(montantFcfa.value);
    }
    if (motif.present) {
      map['motif'] = Variable<String>(motif.value);
    }
    if (recordedByPhone.present) {
      map['recorded_by_phone'] = Variable<String>(recordedByPhone.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FondsSolidariteContributionsCompanion(')
          ..write('previousHash: $previousHash, ')
          ..write('hash: $hash, ')
          ..write('provenance: $provenance, ')
          ..write('estApproximatif: $estApproximatif, ')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('cycleId: $cycleId, ')
          ..write('memberId: $memberId, ')
          ..write('montantFcfa: $montantFcfa, ')
          ..write('motif: $motif, ')
          ..write('recordedByPhone: $recordedByPhone, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $AgentAssignmentsTable agentAssignments = $AgentAssignmentsTable(
    this,
  );
  late final $AgentAssignmentRevocationsTable agentAssignmentRevocations =
      $AgentAssignmentRevocationsTable(this);
  late final $CyclesTable cycles = $CyclesTable(this);
  late final $CotisationsTable cotisations = $CotisationsTable(this);
  late final $CarnetsEngagesTable carnetsEngages = $CarnetsEngagesTable(this);
  late final $PretsTable prets = $PretsTable(this);
  late final $PretConfirmationsTable pretConfirmations =
      $PretConfirmationsTable(this);
  late final $PretRemboursementsTable pretRemboursements =
      $PretRemboursementsTable(this);
  late final $PretAnnulationsTable pretAnnulations = $PretAnnulationsTable(
    this,
  );
  late final $AmendesTable amendes = $AmendesTable(this);
  late final $AmendeAnnulationsTable amendeAnnulations =
      $AmendeAnnulationsTable(this);
  late final $FondsSolidariteContributionsTable fondsSolidariteContributions =
      $FondsSolidariteContributionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    groups,
    members,
    agentAssignments,
    agentAssignmentRevocations,
    cycles,
    cotisations,
    carnetsEngages,
    prets,
    pretConfirmations,
    pretRemboursements,
    pretAnnulations,
    amendes,
    amendeAnnulations,
    fondsSolidariteContributions,
  ];
}

typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      required String id,
      required String name,
      Value<int> cycleDurationMonths,
      Value<String> meetingFrequency,
      Value<int?> paymentDayOfWeek,
      Value<int?> paymentDayOfMonth1,
      Value<int?> paymentDayOfMonth2,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> cycleDurationMonths,
      Value<String> meetingFrequency,
      Value<int?> paymentDayOfWeek,
      Value<int?> paymentDayOfMonth1,
      Value<int?> paymentDayOfMonth2,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, Group> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MembersTable, List<Member>> _membersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: 'groups__id__members__group_id',
  );

  $$MembersTableProcessedTableManager get membersRefs {
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AgentAssignmentsTable, List<AgentAssignment>>
  _agentAssignmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.agentAssignments,
    aliasName: 'groups__id__agent_assignments__group_id',
  );

  $$AgentAssignmentsTableProcessedTableManager get agentAssignmentsRefs {
    final manager = $$AgentAssignmentsTableTableManager(
      $_db,
      $_db.agentAssignments,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _agentAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CyclesTable, List<Cycle>> _cyclesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cycles,
    aliasName: 'groups__id__cycles__group_id',
  );

  $$CyclesTableProcessedTableManager get cyclesRefs {
    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cyclesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CotisationsTable, List<Cotisation>>
  _cotisationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cotisations,
    aliasName: 'groups__id__cotisations__group_id',
  );

  $$CotisationsTableProcessedTableManager get cotisationsRefs {
    final manager = $$CotisationsTableTableManager(
      $_db,
      $_db.cotisations,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cotisationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CarnetsEngagesTable, List<CarnetsEngage>>
  _carnetsEngagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.carnetsEngages,
    aliasName: 'groups__id__carnets_engages__group_id',
  );

  $$CarnetsEngagesTableProcessedTableManager get carnetsEngagesRefs {
    final manager = $$CarnetsEngagesTableTableManager(
      $_db,
      $_db.carnetsEngages,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_carnetsEngagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PretsTable, List<Pret>> _pretsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.prets,
    aliasName: 'groups__id__prets__group_id',
  );

  $$PretsTableProcessedTableManager get pretsRefs {
    final manager = $$PretsTableTableManager(
      $_db,
      $_db.prets,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pretsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AmendesTable, List<Amende>> _amendesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.amendes,
    aliasName: 'groups__id__amendes__group_id',
  );

  $$AmendesTableProcessedTableManager get amendesRefs {
    final manager = $$AmendesTableTableManager(
      $_db,
      $_db.amendes,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_amendesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FondsSolidariteContributionsTable,
    List<FondsSolidariteContribution>
  >
  _fondsSolidariteContributionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.fondsSolidariteContributions,
        aliasName: 'groups__id__fonds_solidarite_contributions__group_id',
      );

  $$FondsSolidariteContributionsTableProcessedTableManager
  get fondsSolidariteContributionsRefs {
    final manager = $$FondsSolidariteContributionsTableTableManager(
      $_db,
      $_db.fondsSolidariteContributions,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _fondsSolidariteContributionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleDurationMonths => $composableBuilder(
    column: $table.cycleDurationMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meetingFrequency => $composableBuilder(
    column: $table.meetingFrequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentDayOfWeek => $composableBuilder(
    column: $table.paymentDayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentDayOfMonth1 => $composableBuilder(
    column: $table.paymentDayOfMonth1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentDayOfMonth2 => $composableBuilder(
    column: $table.paymentDayOfMonth2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membersRefs(
    Expression<bool> Function($$MembersTableFilterComposer f) f,
  ) {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> agentAssignmentsRefs(
    Expression<bool> Function($$AgentAssignmentsTableFilterComposer f) f,
  ) {
    final $$AgentAssignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentAssignments,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentAssignmentsTableFilterComposer(
            $db: $db,
            $table: $db.agentAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cyclesRefs(
    Expression<bool> Function($$CyclesTableFilterComposer f) f,
  ) {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cotisationsRefs(
    Expression<bool> Function($$CotisationsTableFilterComposer f) f,
  ) {
    final $$CotisationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cotisations,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CotisationsTableFilterComposer(
            $db: $db,
            $table: $db.cotisations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> carnetsEngagesRefs(
    Expression<bool> Function($$CarnetsEngagesTableFilterComposer f) f,
  ) {
    final $$CarnetsEngagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carnetsEngages,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarnetsEngagesTableFilterComposer(
            $db: $db,
            $table: $db.carnetsEngages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pretsRefs(
    Expression<bool> Function($$PretsTableFilterComposer f) f,
  ) {
    final $$PretsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableFilterComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> amendesRefs(
    Expression<bool> Function($$AmendesTableFilterComposer f) f,
  ) {
    final $$AmendesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableFilterComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fondsSolidariteContributionsRefs(
    Expression<bool> Function(
      $$FondsSolidariteContributionsTableFilterComposer f,
    )
    f,
  ) {
    final $$FondsSolidariteContributionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.fondsSolidariteContributions,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FondsSolidariteContributionsTableFilterComposer(
                $db: $db,
                $table: $db.fondsSolidariteContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleDurationMonths => $composableBuilder(
    column: $table.cycleDurationMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meetingFrequency => $composableBuilder(
    column: $table.meetingFrequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentDayOfWeek => $composableBuilder(
    column: $table.paymentDayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentDayOfMonth1 => $composableBuilder(
    column: $table.paymentDayOfMonth1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentDayOfMonth2 => $composableBuilder(
    column: $table.paymentDayOfMonth2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get cycleDurationMonths => $composableBuilder(
    column: $table.cycleDurationMonths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meetingFrequency => $composableBuilder(
    column: $table.meetingFrequency,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentDayOfWeek => $composableBuilder(
    column: $table.paymentDayOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentDayOfMonth1 => $composableBuilder(
    column: $table.paymentDayOfMonth1,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentDayOfMonth2 => $composableBuilder(
    column: $table.paymentDayOfMonth2,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($$MembersTableAnnotationComposer a) f,
  ) {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> agentAssignmentsRefs<T extends Object>(
    Expression<T> Function($$AgentAssignmentsTableAnnotationComposer a) f,
  ) {
    final $$AgentAssignmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentAssignments,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentAssignmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.agentAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cyclesRefs<T extends Object>(
    Expression<T> Function($$CyclesTableAnnotationComposer a) f,
  ) {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cotisationsRefs<T extends Object>(
    Expression<T> Function($$CotisationsTableAnnotationComposer a) f,
  ) {
    final $$CotisationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cotisations,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CotisationsTableAnnotationComposer(
            $db: $db,
            $table: $db.cotisations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> carnetsEngagesRefs<T extends Object>(
    Expression<T> Function($$CarnetsEngagesTableAnnotationComposer a) f,
  ) {
    final $$CarnetsEngagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carnetsEngages,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarnetsEngagesTableAnnotationComposer(
            $db: $db,
            $table: $db.carnetsEngages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pretsRefs<T extends Object>(
    Expression<T> Function($$PretsTableAnnotationComposer a) f,
  ) {
    final $$PretsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableAnnotationComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> amendesRefs<T extends Object>(
    Expression<T> Function($$AmendesTableAnnotationComposer a) f,
  ) {
    final $$AmendesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableAnnotationComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fondsSolidariteContributionsRefs<T extends Object>(
    Expression<T> Function(
      $$FondsSolidariteContributionsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$FondsSolidariteContributionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.fondsSolidariteContributions,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FondsSolidariteContributionsTableAnnotationComposer(
                $db: $db,
                $table: $db.fondsSolidariteContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          Group,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (Group, $$GroupsTableReferences),
          Group,
          PrefetchHooks Function({
            bool membersRefs,
            bool agentAssignmentsRefs,
            bool cyclesRefs,
            bool cotisationsRefs,
            bool carnetsEngagesRefs,
            bool pretsRefs,
            bool amendesRefs,
            bool fondsSolidariteContributionsRefs,
          })
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> cycleDurationMonths = const Value.absent(),
                Value<String> meetingFrequency = const Value.absent(),
                Value<int?> paymentDayOfWeek = const Value.absent(),
                Value<int?> paymentDayOfMonth1 = const Value.absent(),
                Value<int?> paymentDayOfMonth2 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                name: name,
                cycleDurationMonths: cycleDurationMonths,
                meetingFrequency: meetingFrequency,
                paymentDayOfWeek: paymentDayOfWeek,
                paymentDayOfMonth1: paymentDayOfMonth1,
                paymentDayOfMonth2: paymentDayOfMonth2,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> cycleDurationMonths = const Value.absent(),
                Value<String> meetingFrequency = const Value.absent(),
                Value<int?> paymentDayOfWeek = const Value.absent(),
                Value<int?> paymentDayOfMonth1 = const Value.absent(),
                Value<int?> paymentDayOfMonth2 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                name: name,
                cycleDurationMonths: cycleDurationMonths,
                meetingFrequency: meetingFrequency,
                paymentDayOfWeek: paymentDayOfWeek,
                paymentDayOfMonth1: paymentDayOfMonth1,
                paymentDayOfMonth2: paymentDayOfMonth2,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GroupsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                membersRefs = false,
                agentAssignmentsRefs = false,
                cyclesRefs = false,
                cotisationsRefs = false,
                carnetsEngagesRefs = false,
                pretsRefs = false,
                amendesRefs = false,
                fondsSolidariteContributionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membersRefs) db.members,
                    if (agentAssignmentsRefs) db.agentAssignments,
                    if (cyclesRefs) db.cycles,
                    if (cotisationsRefs) db.cotisations,
                    if (carnetsEngagesRefs) db.carnetsEngages,
                    if (pretsRefs) db.prets,
                    if (amendesRefs) db.amendes,
                    if (fondsSolidariteContributionsRefs)
                      db.fondsSolidariteContributions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (membersRefs)
                        await $_getPrefetchedData<Group, $GroupsTable, Member>(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._membersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).membersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentAssignmentsRefs)
                        await $_getPrefetchedData<
                          Group,
                          $GroupsTable,
                          AgentAssignment
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._agentAssignmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).agentAssignmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cyclesRefs)
                        await $_getPrefetchedData<Group, $GroupsTable, Cycle>(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._cyclesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(db, table, p0).cyclesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cotisationsRefs)
                        await $_getPrefetchedData<
                          Group,
                          $GroupsTable,
                          Cotisation
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._cotisationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).cotisationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (carnetsEngagesRefs)
                        await $_getPrefetchedData<
                          Group,
                          $GroupsTable,
                          CarnetsEngage
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._carnetsEngagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).carnetsEngagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pretsRefs)
                        await $_getPrefetchedData<Group, $GroupsTable, Pret>(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._pretsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(db, table, p0).pretsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (amendesRefs)
                        await $_getPrefetchedData<Group, $GroupsTable, Amende>(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._amendesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).amendesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fondsSolidariteContributionsRefs)
                        await $_getPrefetchedData<
                          Group,
                          $GroupsTable,
                          FondsSolidariteContribution
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._fondsSolidariteContributionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).fondsSolidariteContributionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      Group,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (Group, $$GroupsTableReferences),
      Group,
      PrefetchHooks Function({
        bool membersRefs,
        bool agentAssignmentsRefs,
        bool cyclesRefs,
        bool cotisationsRefs,
        bool carnetsEngagesRefs,
        bool pretsRefs,
        bool amendesRefs,
        bool fondsSolidariteContributionsRefs,
      })
    >;
typedef $$MembersTableCreateCompanionBuilder =
    MembersCompanion Function({
      required String id,
      required String groupId,
      required String fullName,
      Value<String?> phoneNumber,
      Value<DateTime> joinedAt,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$MembersTableUpdateCompanionBuilder =
    MembersCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> fullName,
      Value<String?> phoneNumber,
      Value<DateTime> joinedAt,
      Value<bool> active,
      Value<int> rowid,
    });

final class $$MembersTableReferences
    extends BaseReferences<_$AppDatabase, $MembersTable, Member> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('members__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AgentAssignmentsTable, List<AgentAssignment>>
  _agentAssignmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.agentAssignments,
    aliasName: 'members__id__agent_assignments__member_id',
  );

  $$AgentAssignmentsTableProcessedTableManager get agentAssignmentsRefs {
    final manager = $$AgentAssignmentsTableTableManager(
      $_db,
      $_db.agentAssignments,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _agentAssignmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CotisationsTable, List<Cotisation>>
  _cotisationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cotisations,
    aliasName: 'members__id__cotisations__member_id',
  );

  $$CotisationsTableProcessedTableManager get cotisationsRefs {
    final manager = $$CotisationsTableTableManager(
      $_db,
      $_db.cotisations,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cotisationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CarnetsEngagesTable, List<CarnetsEngage>>
  _carnetsEngagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.carnetsEngages,
    aliasName: 'members__id__carnets_engages__member_id',
  );

  $$CarnetsEngagesTableProcessedTableManager get carnetsEngagesRefs {
    final manager = $$CarnetsEngagesTableTableManager(
      $_db,
      $_db.carnetsEngages,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_carnetsEngagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PretsTable, List<Pret>> _pretsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.prets,
    aliasName: 'members__id__prets__member_id',
  );

  $$PretsTableProcessedTableManager get pretsRefs {
    final manager = $$PretsTableTableManager(
      $_db,
      $_db.prets,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pretsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AmendesTable, List<Amende>> _amendesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.amendes,
    aliasName: 'members__id__amendes__member_id',
  );

  $$AmendesTableProcessedTableManager get amendesRefs {
    final manager = $$AmendesTableTableManager(
      $_db,
      $_db.amendes,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_amendesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FondsSolidariteContributionsTable,
    List<FondsSolidariteContribution>
  >
  _fondsSolidariteContributionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.fondsSolidariteContributions,
        aliasName: 'members__id__fonds_solidarite_contributions__member_id',
      );

  $$FondsSolidariteContributionsTableProcessedTableManager
  get fondsSolidariteContributionsRefs {
    final manager = $$FondsSolidariteContributionsTableTableManager(
      $_db,
      $_db.fondsSolidariteContributions,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _fondsSolidariteContributionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> agentAssignmentsRefs(
    Expression<bool> Function($$AgentAssignmentsTableFilterComposer f) f,
  ) {
    final $$AgentAssignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentAssignments,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentAssignmentsTableFilterComposer(
            $db: $db,
            $table: $db.agentAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cotisationsRefs(
    Expression<bool> Function($$CotisationsTableFilterComposer f) f,
  ) {
    final $$CotisationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cotisations,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CotisationsTableFilterComposer(
            $db: $db,
            $table: $db.cotisations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> carnetsEngagesRefs(
    Expression<bool> Function($$CarnetsEngagesTableFilterComposer f) f,
  ) {
    final $$CarnetsEngagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carnetsEngages,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarnetsEngagesTableFilterComposer(
            $db: $db,
            $table: $db.carnetsEngages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pretsRefs(
    Expression<bool> Function($$PretsTableFilterComposer f) f,
  ) {
    final $$PretsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableFilterComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> amendesRefs(
    Expression<bool> Function($$AmendesTableFilterComposer f) f,
  ) {
    final $$AmendesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableFilterComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fondsSolidariteContributionsRefs(
    Expression<bool> Function(
      $$FondsSolidariteContributionsTableFilterComposer f,
    )
    f,
  ) {
    final $$FondsSolidariteContributionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.fondsSolidariteContributions,
          getReferencedColumn: (t) => t.memberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FondsSolidariteContributionsTableFilterComposer(
                $db: $db,
                $table: $db.fondsSolidariteContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> agentAssignmentsRefs<T extends Object>(
    Expression<T> Function($$AgentAssignmentsTableAnnotationComposer a) f,
  ) {
    final $$AgentAssignmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentAssignments,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentAssignmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.agentAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cotisationsRefs<T extends Object>(
    Expression<T> Function($$CotisationsTableAnnotationComposer a) f,
  ) {
    final $$CotisationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cotisations,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CotisationsTableAnnotationComposer(
            $db: $db,
            $table: $db.cotisations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> carnetsEngagesRefs<T extends Object>(
    Expression<T> Function($$CarnetsEngagesTableAnnotationComposer a) f,
  ) {
    final $$CarnetsEngagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carnetsEngages,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarnetsEngagesTableAnnotationComposer(
            $db: $db,
            $table: $db.carnetsEngages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pretsRefs<T extends Object>(
    Expression<T> Function($$PretsTableAnnotationComposer a) f,
  ) {
    final $$PretsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableAnnotationComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> amendesRefs<T extends Object>(
    Expression<T> Function($$AmendesTableAnnotationComposer a) f,
  ) {
    final $$AmendesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableAnnotationComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fondsSolidariteContributionsRefs<T extends Object>(
    Expression<T> Function(
      $$FondsSolidariteContributionsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$FondsSolidariteContributionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.fondsSolidariteContributions,
          getReferencedColumn: (t) => t.memberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FondsSolidariteContributionsTableAnnotationComposer(
                $db: $db,
                $table: $db.fondsSolidariteContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          Member,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (Member, $$MembersTableReferences),
          Member,
          PrefetchHooks Function({
            bool groupId,
            bool agentAssignmentsRefs,
            bool cotisationsRefs,
            bool carnetsEngagesRefs,
            bool pretsRefs,
            bool amendesRefs,
            bool fondsSolidariteContributionsRefs,
          })
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                groupId: groupId,
                fullName: fullName,
                phoneNumber: phoneNumber,
                joinedAt: joinedAt,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String fullName,
                Value<String?> phoneNumber = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                groupId: groupId,
                fullName: fullName,
                phoneNumber: phoneNumber,
                joinedAt: joinedAt,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                agentAssignmentsRefs = false,
                cotisationsRefs = false,
                carnetsEngagesRefs = false,
                pretsRefs = false,
                amendesRefs = false,
                fondsSolidariteContributionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (agentAssignmentsRefs) db.agentAssignments,
                    if (cotisationsRefs) db.cotisations,
                    if (carnetsEngagesRefs) db.carnetsEngages,
                    if (pretsRefs) db.prets,
                    if (amendesRefs) db.amendes,
                    if (fondsSolidariteContributionsRefs)
                      db.fondsSolidariteContributions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable: $$MembersTableReferences
                                        ._groupIdTable(db),
                                    referencedColumn: $$MembersTableReferences
                                        ._groupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (agentAssignmentsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          AgentAssignment
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._agentAssignmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).agentAssignmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cotisationsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          Cotisation
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._cotisationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).cotisationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (carnetsEngagesRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          CarnetsEngage
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._carnetsEngagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).carnetsEngagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pretsRefs)
                        await $_getPrefetchedData<Member, $MembersTable, Pret>(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._pretsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(db, table, p0).pretsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (amendesRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          Amende
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._amendesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).amendesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fondsSolidariteContributionsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          FondsSolidariteContribution
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._fondsSolidariteContributionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).fondsSolidariteContributionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      Member,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (Member, $$MembersTableReferences),
      Member,
      PrefetchHooks Function({
        bool groupId,
        bool agentAssignmentsRefs,
        bool cotisationsRefs,
        bool carnetsEngagesRefs,
        bool pretsRefs,
        bool amendesRefs,
        bool fondsSolidariteContributionsRefs,
      })
    >;
typedef $$AgentAssignmentsTableCreateCompanionBuilder =
    AgentAssignmentsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      required String id,
      required String groupId,
      Value<String?> memberId,
      required String phoneNumber,
      required String role,
      Value<DateTime> assignedAt,
      Value<int> rowid,
    });
typedef $$AgentAssignmentsTableUpdateCompanionBuilder =
    AgentAssignmentsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> id,
      Value<String> groupId,
      Value<String?> memberId,
      Value<String> phoneNumber,
      Value<String> role,
      Value<DateTime> assignedAt,
      Value<int> rowid,
    });

final class $$AgentAssignmentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AgentAssignmentsTable, AgentAssignment> {
  $$AgentAssignmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('agent_assignments__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('agent_assignments__member_id__members__id');

  $$MembersTableProcessedTableManager? get memberId {
    final $_column = $_itemColumn<String>('member_id');
    if ($_column == null) return null;
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $AgentAssignmentRevocationsTable,
    List<AgentAssignmentRevocation>
  >
  _agentAssignmentRevocationsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.agentAssignmentRevocations,
    aliasName:
        'agent_assignments__id__agent_assignment_revocations__assignment_id',
  );

  $$AgentAssignmentRevocationsTableProcessedTableManager
  get agentAssignmentRevocationsRefs {
    final manager = $$AgentAssignmentRevocationsTableTableManager(
      $_db,
      $_db.agentAssignmentRevocations,
    ).filter((f) => f.assignmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _agentAssignmentRevocationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AgentAssignmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AgentAssignmentsTable> {
  $$AgentAssignmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> agentAssignmentRevocationsRefs(
    Expression<bool> Function($$AgentAssignmentRevocationsTableFilterComposer f)
    f,
  ) {
    final $$AgentAssignmentRevocationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.agentAssignmentRevocations,
          getReferencedColumn: (t) => t.assignmentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AgentAssignmentRevocationsTableFilterComposer(
                $db: $db,
                $table: $db.agentAssignmentRevocations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AgentAssignmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgentAssignmentsTable> {
  $$AgentAssignmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AgentAssignmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgentAssignmentsTable> {
  $$AgentAssignmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> agentAssignmentRevocationsRefs<T extends Object>(
    Expression<T> Function(
      $$AgentAssignmentRevocationsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$AgentAssignmentRevocationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.agentAssignmentRevocations,
          getReferencedColumn: (t) => t.assignmentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AgentAssignmentRevocationsTableAnnotationComposer(
                $db: $db,
                $table: $db.agentAssignmentRevocations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AgentAssignmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgentAssignmentsTable,
          AgentAssignment,
          $$AgentAssignmentsTableFilterComposer,
          $$AgentAssignmentsTableOrderingComposer,
          $$AgentAssignmentsTableAnnotationComposer,
          $$AgentAssignmentsTableCreateCompanionBuilder,
          $$AgentAssignmentsTableUpdateCompanionBuilder,
          (AgentAssignment, $$AgentAssignmentsTableReferences),
          AgentAssignment,
          PrefetchHooks Function({
            bool groupId,
            bool memberId,
            bool agentAssignmentRevocationsRefs,
          })
        > {
  $$AgentAssignmentsTableTableManager(
    _$AppDatabase db,
    $AgentAssignmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentAssignmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentAssignmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentAssignmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<String> phoneNumber = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> assignedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentAssignmentsCompanion(
                previousHash: previousHash,
                hash: hash,
                id: id,
                groupId: groupId,
                memberId: memberId,
                phoneNumber: phoneNumber,
                role: role,
                assignedAt: assignedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                required String id,
                required String groupId,
                Value<String?> memberId = const Value.absent(),
                required String phoneNumber,
                required String role,
                Value<DateTime> assignedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentAssignmentsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                id: id,
                groupId: groupId,
                memberId: memberId,
                phoneNumber: phoneNumber,
                role: role,
                assignedAt: assignedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AgentAssignmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                memberId = false,
                agentAssignmentRevocationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (agentAssignmentRevocationsRefs)
                      db.agentAssignmentRevocations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable:
                                        $$AgentAssignmentsTableReferences
                                            ._groupIdTable(db),
                                    referencedColumn:
                                        $$AgentAssignmentsTableReferences
                                            ._groupIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (memberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.memberId,
                                    referencedTable:
                                        $$AgentAssignmentsTableReferences
                                            ._memberIdTable(db),
                                    referencedColumn:
                                        $$AgentAssignmentsTableReferences
                                            ._memberIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (agentAssignmentRevocationsRefs)
                        await $_getPrefetchedData<
                          AgentAssignment,
                          $AgentAssignmentsTable,
                          AgentAssignmentRevocation
                        >(
                          currentTable: table,
                          referencedTable: $$AgentAssignmentsTableReferences
                              ._agentAssignmentRevocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AgentAssignmentsTableReferences(
                                db,
                                table,
                                p0,
                              ).agentAssignmentRevocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assignmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AgentAssignmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgentAssignmentsTable,
      AgentAssignment,
      $$AgentAssignmentsTableFilterComposer,
      $$AgentAssignmentsTableOrderingComposer,
      $$AgentAssignmentsTableAnnotationComposer,
      $$AgentAssignmentsTableCreateCompanionBuilder,
      $$AgentAssignmentsTableUpdateCompanionBuilder,
      (AgentAssignment, $$AgentAssignmentsTableReferences),
      AgentAssignment,
      PrefetchHooks Function({
        bool groupId,
        bool memberId,
        bool agentAssignmentRevocationsRefs,
      })
    >;
typedef $$AgentAssignmentRevocationsTableCreateCompanionBuilder =
    AgentAssignmentRevocationsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      required String id,
      required String assignmentId,
      Value<DateTime> revokedAt,
      Value<int> rowid,
    });
typedef $$AgentAssignmentRevocationsTableUpdateCompanionBuilder =
    AgentAssignmentRevocationsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> id,
      Value<String> assignmentId,
      Value<DateTime> revokedAt,
      Value<int> rowid,
    });

final class $$AgentAssignmentRevocationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AgentAssignmentRevocationsTable,
          AgentAssignmentRevocation
        > {
  $$AgentAssignmentRevocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AgentAssignmentsTable _assignmentIdTable(_$AppDatabase db) =>
      db.agentAssignments.createAlias(
        'agent_assignment_revocations__assignment_id__agent_assignments__id',
      );

  $$AgentAssignmentsTableProcessedTableManager get assignmentId {
    final $_column = $_itemColumn<String>('assignment_id')!;

    final manager = $$AgentAssignmentsTableTableManager(
      $_db,
      $_db.agentAssignments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assignmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AgentAssignmentRevocationsTableFilterComposer
    extends Composer<_$AppDatabase, $AgentAssignmentRevocationsTable> {
  $$AgentAssignmentRevocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AgentAssignmentsTableFilterComposer get assignmentId {
    final $$AgentAssignmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignmentId,
      referencedTable: $db.agentAssignments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentAssignmentsTableFilterComposer(
            $db: $db,
            $table: $db.agentAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AgentAssignmentRevocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgentAssignmentRevocationsTable> {
  $$AgentAssignmentRevocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AgentAssignmentsTableOrderingComposer get assignmentId {
    final $$AgentAssignmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignmentId,
      referencedTable: $db.agentAssignments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentAssignmentsTableOrderingComposer(
            $db: $db,
            $table: $db.agentAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AgentAssignmentRevocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgentAssignmentRevocationsTable> {
  $$AgentAssignmentRevocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  $$AgentAssignmentsTableAnnotationComposer get assignmentId {
    final $$AgentAssignmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignmentId,
      referencedTable: $db.agentAssignments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AgentAssignmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.agentAssignments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AgentAssignmentRevocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgentAssignmentRevocationsTable,
          AgentAssignmentRevocation,
          $$AgentAssignmentRevocationsTableFilterComposer,
          $$AgentAssignmentRevocationsTableOrderingComposer,
          $$AgentAssignmentRevocationsTableAnnotationComposer,
          $$AgentAssignmentRevocationsTableCreateCompanionBuilder,
          $$AgentAssignmentRevocationsTableUpdateCompanionBuilder,
          (
            AgentAssignmentRevocation,
            $$AgentAssignmentRevocationsTableReferences,
          ),
          AgentAssignmentRevocation,
          PrefetchHooks Function({bool assignmentId})
        > {
  $$AgentAssignmentRevocationsTableTableManager(
    _$AppDatabase db,
    $AgentAssignmentRevocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentAssignmentRevocationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AgentAssignmentRevocationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AgentAssignmentRevocationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> assignmentId = const Value.absent(),
                Value<DateTime> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentAssignmentRevocationsCompanion(
                previousHash: previousHash,
                hash: hash,
                id: id,
                assignmentId: assignmentId,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                required String id,
                required String assignmentId,
                Value<DateTime> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentAssignmentRevocationsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                id: id,
                assignmentId: assignmentId,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AgentAssignmentRevocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assignmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assignmentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assignmentId,
                                referencedTable:
                                    $$AgentAssignmentRevocationsTableReferences
                                        ._assignmentIdTable(db),
                                referencedColumn:
                                    $$AgentAssignmentRevocationsTableReferences
                                        ._assignmentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AgentAssignmentRevocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgentAssignmentRevocationsTable,
      AgentAssignmentRevocation,
      $$AgentAssignmentRevocationsTableFilterComposer,
      $$AgentAssignmentRevocationsTableOrderingComposer,
      $$AgentAssignmentRevocationsTableAnnotationComposer,
      $$AgentAssignmentRevocationsTableCreateCompanionBuilder,
      $$AgentAssignmentRevocationsTableUpdateCompanionBuilder,
      (AgentAssignmentRevocation, $$AgentAssignmentRevocationsTableReferences),
      AgentAssignmentRevocation,
      PrefetchHooks Function({bool assignmentId})
    >;
typedef $$CyclesTableCreateCompanionBuilder =
    CyclesCompanion Function({
      required String id,
      required String groupId,
      required int cycleNumber,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      required int partValueFcfa,
      required double interestRatePercent,
      Value<int> lateFeeFcfa,
      Value<int> loanDurationDays,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$CyclesTableUpdateCompanionBuilder =
    CyclesCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<int> cycleNumber,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> partValueFcfa,
      Value<double> interestRatePercent,
      Value<int> lateFeeFcfa,
      Value<int> loanDurationDays,
      Value<String> status,
      Value<int> rowid,
    });

final class $$CyclesTableReferences
    extends BaseReferences<_$AppDatabase, $CyclesTable, Cycle> {
  $$CyclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('cycles__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CotisationsTable, List<Cotisation>>
  _cotisationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cotisations,
    aliasName: 'cycles__id__cotisations__cycle_id',
  );

  $$CotisationsTableProcessedTableManager get cotisationsRefs {
    final manager = $$CotisationsTableTableManager(
      $_db,
      $_db.cotisations,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cotisationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CarnetsEngagesTable, List<CarnetsEngage>>
  _carnetsEngagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.carnetsEngages,
    aliasName: 'cycles__id__carnets_engages__cycle_id',
  );

  $$CarnetsEngagesTableProcessedTableManager get carnetsEngagesRefs {
    final manager = $$CarnetsEngagesTableTableManager(
      $_db,
      $_db.carnetsEngages,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_carnetsEngagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PretsTable, List<Pret>> _pretsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.prets,
    aliasName: 'cycles__id__prets__cycle_id',
  );

  $$PretsTableProcessedTableManager get pretsRefs {
    final manager = $$PretsTableTableManager(
      $_db,
      $_db.prets,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pretsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AmendesTable, List<Amende>> _amendesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.amendes,
    aliasName: 'cycles__id__amendes__cycle_id',
  );

  $$AmendesTableProcessedTableManager get amendesRefs {
    final manager = $$AmendesTableTableManager(
      $_db,
      $_db.amendes,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_amendesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FondsSolidariteContributionsTable,
    List<FondsSolidariteContribution>
  >
  _fondsSolidariteContributionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.fondsSolidariteContributions,
        aliasName: 'cycles__id__fonds_solidarite_contributions__cycle_id',
      );

  $$FondsSolidariteContributionsTableProcessedTableManager
  get fondsSolidariteContributionsRefs {
    final manager = $$FondsSolidariteContributionsTableTableManager(
      $_db,
      $_db.fondsSolidariteContributions,
    ).filter((f) => f.cycleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _fondsSolidariteContributionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CyclesTableFilterComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleNumber => $composableBuilder(
    column: $table.cycleNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partValueFcfa => $composableBuilder(
    column: $table.partValueFcfa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lateFeeFcfa => $composableBuilder(
    column: $table.lateFeeFcfa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loanDurationDays => $composableBuilder(
    column: $table.loanDurationDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cotisationsRefs(
    Expression<bool> Function($$CotisationsTableFilterComposer f) f,
  ) {
    final $$CotisationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cotisations,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CotisationsTableFilterComposer(
            $db: $db,
            $table: $db.cotisations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> carnetsEngagesRefs(
    Expression<bool> Function($$CarnetsEngagesTableFilterComposer f) f,
  ) {
    final $$CarnetsEngagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carnetsEngages,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarnetsEngagesTableFilterComposer(
            $db: $db,
            $table: $db.carnetsEngages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pretsRefs(
    Expression<bool> Function($$PretsTableFilterComposer f) f,
  ) {
    final $$PretsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableFilterComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> amendesRefs(
    Expression<bool> Function($$AmendesTableFilterComposer f) f,
  ) {
    final $$AmendesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableFilterComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fondsSolidariteContributionsRefs(
    Expression<bool> Function(
      $$FondsSolidariteContributionsTableFilterComposer f,
    )
    f,
  ) {
    final $$FondsSolidariteContributionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.fondsSolidariteContributions,
          getReferencedColumn: (t) => t.cycleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FondsSolidariteContributionsTableFilterComposer(
                $db: $db,
                $table: $db.fondsSolidariteContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleNumber => $composableBuilder(
    column: $table.cycleNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partValueFcfa => $composableBuilder(
    column: $table.partValueFcfa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lateFeeFcfa => $composableBuilder(
    column: $table.lateFeeFcfa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loanDurationDays => $composableBuilder(
    column: $table.loanDurationDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CyclesTable> {
  $$CyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cycleNumber => $composableBuilder(
    column: $table.cycleNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get partValueFcfa => $composableBuilder(
    column: $table.partValueFcfa,
    builder: (column) => column,
  );

  GeneratedColumn<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lateFeeFcfa => $composableBuilder(
    column: $table.lateFeeFcfa,
    builder: (column) => column,
  );

  GeneratedColumn<int> get loanDurationDays => $composableBuilder(
    column: $table.loanDurationDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cotisationsRefs<T extends Object>(
    Expression<T> Function($$CotisationsTableAnnotationComposer a) f,
  ) {
    final $$CotisationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cotisations,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CotisationsTableAnnotationComposer(
            $db: $db,
            $table: $db.cotisations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> carnetsEngagesRefs<T extends Object>(
    Expression<T> Function($$CarnetsEngagesTableAnnotationComposer a) f,
  ) {
    final $$CarnetsEngagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.carnetsEngages,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CarnetsEngagesTableAnnotationComposer(
            $db: $db,
            $table: $db.carnetsEngages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pretsRefs<T extends Object>(
    Expression<T> Function($$PretsTableAnnotationComposer a) f,
  ) {
    final $$PretsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableAnnotationComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> amendesRefs<T extends Object>(
    Expression<T> Function($$AmendesTableAnnotationComposer a) f,
  ) {
    final $$AmendesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.cycleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableAnnotationComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fondsSolidariteContributionsRefs<T extends Object>(
    Expression<T> Function(
      $$FondsSolidariteContributionsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$FondsSolidariteContributionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.fondsSolidariteContributions,
          getReferencedColumn: (t) => t.cycleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FondsSolidariteContributionsTableAnnotationComposer(
                $db: $db,
                $table: $db.fondsSolidariteContributions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CyclesTable,
          Cycle,
          $$CyclesTableFilterComposer,
          $$CyclesTableOrderingComposer,
          $$CyclesTableAnnotationComposer,
          $$CyclesTableCreateCompanionBuilder,
          $$CyclesTableUpdateCompanionBuilder,
          (Cycle, $$CyclesTableReferences),
          Cycle,
          PrefetchHooks Function({
            bool groupId,
            bool cotisationsRefs,
            bool carnetsEngagesRefs,
            bool pretsRefs,
            bool amendesRefs,
            bool fondsSolidariteContributionsRefs,
          })
        > {
  $$CyclesTableTableManager(_$AppDatabase db, $CyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<int> cycleNumber = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> partValueFcfa = const Value.absent(),
                Value<double> interestRatePercent = const Value.absent(),
                Value<int> lateFeeFcfa = const Value.absent(),
                Value<int> loanDurationDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CyclesCompanion(
                id: id,
                groupId: groupId,
                cycleNumber: cycleNumber,
                startedAt: startedAt,
                endedAt: endedAt,
                partValueFcfa: partValueFcfa,
                interestRatePercent: interestRatePercent,
                lateFeeFcfa: lateFeeFcfa,
                loanDurationDays: loanDurationDays,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required int cycleNumber,
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                required int partValueFcfa,
                required double interestRatePercent,
                Value<int> lateFeeFcfa = const Value.absent(),
                Value<int> loanDurationDays = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CyclesCompanion.insert(
                id: id,
                groupId: groupId,
                cycleNumber: cycleNumber,
                startedAt: startedAt,
                endedAt: endedAt,
                partValueFcfa: partValueFcfa,
                interestRatePercent: interestRatePercent,
                lateFeeFcfa: lateFeeFcfa,
                loanDurationDays: loanDurationDays,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CyclesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                cotisationsRefs = false,
                carnetsEngagesRefs = false,
                pretsRefs = false,
                amendesRefs = false,
                fondsSolidariteContributionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cotisationsRefs) db.cotisations,
                    if (carnetsEngagesRefs) db.carnetsEngages,
                    if (pretsRefs) db.prets,
                    if (amendesRefs) db.amendes,
                    if (fondsSolidariteContributionsRefs)
                      db.fondsSolidariteContributions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable: $$CyclesTableReferences
                                        ._groupIdTable(db),
                                    referencedColumn: $$CyclesTableReferences
                                        ._groupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cotisationsRefs)
                        await $_getPrefetchedData<
                          Cycle,
                          $CyclesTable,
                          Cotisation
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._cotisationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).cotisationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (carnetsEngagesRefs)
                        await $_getPrefetchedData<
                          Cycle,
                          $CyclesTable,
                          CarnetsEngage
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._carnetsEngagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).carnetsEngagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pretsRefs)
                        await $_getPrefetchedData<Cycle, $CyclesTable, Pret>(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._pretsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(db, table, p0).pretsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (amendesRefs)
                        await $_getPrefetchedData<Cycle, $CyclesTable, Amende>(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._amendesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).amendesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fondsSolidariteContributionsRefs)
                        await $_getPrefetchedData<
                          Cycle,
                          $CyclesTable,
                          FondsSolidariteContribution
                        >(
                          currentTable: table,
                          referencedTable: $$CyclesTableReferences
                              ._fondsSolidariteContributionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CyclesTableReferences(
                                db,
                                table,
                                p0,
                              ).fondsSolidariteContributionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cycleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CyclesTable,
      Cycle,
      $$CyclesTableFilterComposer,
      $$CyclesTableOrderingComposer,
      $$CyclesTableAnnotationComposer,
      $$CyclesTableCreateCompanionBuilder,
      $$CyclesTableUpdateCompanionBuilder,
      (Cycle, $$CyclesTableReferences),
      Cycle,
      PrefetchHooks Function({
        bool groupId,
        bool cotisationsRefs,
        bool carnetsEngagesRefs,
        bool pretsRefs,
        bool amendesRefs,
        bool fondsSolidariteContributionsRefs,
      })
    >;
typedef $$CotisationsTableCreateCompanionBuilder =
    CotisationsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      required String id,
      required String groupId,
      required String cycleId,
      required String memberId,
      required int partsCount,
      Value<String> source,
      required String recordedByPhone,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });
typedef $$CotisationsTableUpdateCompanionBuilder =
    CotisationsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      Value<String> id,
      Value<String> groupId,
      Value<String> cycleId,
      Value<String> memberId,
      Value<int> partsCount,
      Value<String> source,
      Value<String> recordedByPhone,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

final class $$CotisationsTableReferences
    extends BaseReferences<_$AppDatabase, $CotisationsTable, Cotisation> {
  $$CotisationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('cotisations__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CyclesTable _cycleIdTable(_$AppDatabase db) =>
      db.cycles.createAlias('cotisations__cycle_id__cycles__id');

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('cotisations__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CotisationsTableFilterComposer
    extends Composer<_$AppDatabase, $CotisationsTable> {
  $$CotisationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partsCount => $composableBuilder(
    column: $table.partsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CotisationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CotisationsTable> {
  $$CotisationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partsCount => $composableBuilder(
    column: $table.partsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CotisationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CotisationsTable> {
  $$CotisationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get partsCount => $composableBuilder(
    column: $table.partsCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CotisationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CotisationsTable,
          Cotisation,
          $$CotisationsTableFilterComposer,
          $$CotisationsTableOrderingComposer,
          $$CotisationsTableAnnotationComposer,
          $$CotisationsTableCreateCompanionBuilder,
          $$CotisationsTableUpdateCompanionBuilder,
          (Cotisation, $$CotisationsTableReferences),
          Cotisation,
          PrefetchHooks Function({bool groupId, bool cycleId, bool memberId})
        > {
  $$CotisationsTableTableManager(_$AppDatabase db, $CotisationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CotisationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CotisationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CotisationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> partsCount = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> recordedByPhone = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CotisationsCompanion(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                partsCount: partsCount,
                source: source,
                recordedByPhone: recordedByPhone,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                required String id,
                required String groupId,
                required String cycleId,
                required String memberId,
                required int partsCount,
                Value<String> source = const Value.absent(),
                required String recordedByPhone,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CotisationsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                partsCount: partsCount,
                source: source,
                recordedByPhone: recordedByPhone,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CotisationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, cycleId = false, memberId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable:
                                        $$CotisationsTableReferences
                                            ._groupIdTable(db),
                                    referencedColumn:
                                        $$CotisationsTableReferences
                                            ._groupIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable:
                                        $$CotisationsTableReferences
                                            ._cycleIdTable(db),
                                    referencedColumn:
                                        $$CotisationsTableReferences
                                            ._cycleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (memberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.memberId,
                                    referencedTable:
                                        $$CotisationsTableReferences
                                            ._memberIdTable(db),
                                    referencedColumn:
                                        $$CotisationsTableReferences
                                            ._memberIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CotisationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CotisationsTable,
      Cotisation,
      $$CotisationsTableFilterComposer,
      $$CotisationsTableOrderingComposer,
      $$CotisationsTableAnnotationComposer,
      $$CotisationsTableCreateCompanionBuilder,
      $$CotisationsTableUpdateCompanionBuilder,
      (Cotisation, $$CotisationsTableReferences),
      Cotisation,
      PrefetchHooks Function({bool groupId, bool cycleId, bool memberId})
    >;
typedef $$CarnetsEngagesTableCreateCompanionBuilder =
    CarnetsEngagesCompanion Function({
      required String id,
      required String groupId,
      required String cycleId,
      required String memberId,
      required int partsCount,
      Value<DateTime?> lockedAt,
      Value<int> rowid,
    });
typedef $$CarnetsEngagesTableUpdateCompanionBuilder =
    CarnetsEngagesCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> cycleId,
      Value<String> memberId,
      Value<int> partsCount,
      Value<DateTime?> lockedAt,
      Value<int> rowid,
    });

final class $$CarnetsEngagesTableReferences
    extends BaseReferences<_$AppDatabase, $CarnetsEngagesTable, CarnetsEngage> {
  $$CarnetsEngagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('carnets_engages__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CyclesTable _cycleIdTable(_$AppDatabase db) =>
      db.cycles.createAlias('carnets_engages__cycle_id__cycles__id');

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('carnets_engages__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CarnetsEngagesTableFilterComposer
    extends Composer<_$AppDatabase, $CarnetsEngagesTable> {
  $$CarnetsEngagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partsCount => $composableBuilder(
    column: $table.partsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CarnetsEngagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CarnetsEngagesTable> {
  $$CarnetsEngagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partsCount => $composableBuilder(
    column: $table.partsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CarnetsEngagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CarnetsEngagesTable> {
  $$CarnetsEngagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get partsCount => $composableBuilder(
    column: $table.partsCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedAt =>
      $composableBuilder(column: $table.lockedAt, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CarnetsEngagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CarnetsEngagesTable,
          CarnetsEngage,
          $$CarnetsEngagesTableFilterComposer,
          $$CarnetsEngagesTableOrderingComposer,
          $$CarnetsEngagesTableAnnotationComposer,
          $$CarnetsEngagesTableCreateCompanionBuilder,
          $$CarnetsEngagesTableUpdateCompanionBuilder,
          (CarnetsEngage, $$CarnetsEngagesTableReferences),
          CarnetsEngage,
          PrefetchHooks Function({bool groupId, bool cycleId, bool memberId})
        > {
  $$CarnetsEngagesTableTableManager(
    _$AppDatabase db,
    $CarnetsEngagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CarnetsEngagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CarnetsEngagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CarnetsEngagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> partsCount = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CarnetsEngagesCompanion(
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                partsCount: partsCount,
                lockedAt: lockedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String cycleId,
                required String memberId,
                required int partsCount,
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CarnetsEngagesCompanion.insert(
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                partsCount: partsCount,
                lockedAt: lockedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CarnetsEngagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, cycleId = false, memberId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable:
                                        $$CarnetsEngagesTableReferences
                                            ._groupIdTable(db),
                                    referencedColumn:
                                        $$CarnetsEngagesTableReferences
                                            ._groupIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable:
                                        $$CarnetsEngagesTableReferences
                                            ._cycleIdTable(db),
                                    referencedColumn:
                                        $$CarnetsEngagesTableReferences
                                            ._cycleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (memberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.memberId,
                                    referencedTable:
                                        $$CarnetsEngagesTableReferences
                                            ._memberIdTable(db),
                                    referencedColumn:
                                        $$CarnetsEngagesTableReferences
                                            ._memberIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CarnetsEngagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CarnetsEngagesTable,
      CarnetsEngage,
      $$CarnetsEngagesTableFilterComposer,
      $$CarnetsEngagesTableOrderingComposer,
      $$CarnetsEngagesTableAnnotationComposer,
      $$CarnetsEngagesTableCreateCompanionBuilder,
      $$CarnetsEngagesTableUpdateCompanionBuilder,
      (CarnetsEngage, $$CarnetsEngagesTableReferences),
      CarnetsEngage,
      PrefetchHooks Function({bool groupId, bool cycleId, bool memberId})
    >;
typedef $$PretsTableCreateCompanionBuilder =
    PretsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      required String id,
      required String groupId,
      required String cycleId,
      required String memberId,
      required int principalFcfa,
      required double interestRatePercent,
      Value<int?> dureeJours,
      required String initiatedByPhone,
      Value<String?> confirmationCode,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PretsTableUpdateCompanionBuilder =
    PretsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      Value<String> id,
      Value<String> groupId,
      Value<String> cycleId,
      Value<String> memberId,
      Value<int> principalFcfa,
      Value<double> interestRatePercent,
      Value<int?> dureeJours,
      Value<String> initiatedByPhone,
      Value<String?> confirmationCode,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PretsTableReferences
    extends BaseReferences<_$AppDatabase, $PretsTable, Pret> {
  $$PretsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('prets__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CyclesTable _cycleIdTable(_$AppDatabase db) =>
      db.cycles.createAlias('prets__cycle_id__cycles__id');

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('prets__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PretConfirmationsTable, List<PretConfirmation>>
  _pretConfirmationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pretConfirmations,
        aliasName: 'prets__id__pret_confirmations__pret_id',
      );

  $$PretConfirmationsTableProcessedTableManager get pretConfirmationsRefs {
    final manager = $$PretConfirmationsTableTableManager(
      $_db,
      $_db.pretConfirmations,
    ).filter((f) => f.pretId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pretConfirmationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PretRemboursementsTable, List<PretRemboursement>>
  _pretRemboursementsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pretRemboursements,
        aliasName: 'prets__id__pret_remboursements__pret_id',
      );

  $$PretRemboursementsTableProcessedTableManager get pretRemboursementsRefs {
    final manager = $$PretRemboursementsTableTableManager(
      $_db,
      $_db.pretRemboursements,
    ).filter((f) => f.pretId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pretRemboursementsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PretAnnulationsTable, List<PretAnnulation>>
  _pretAnnulationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pretAnnulations,
    aliasName: 'prets__id__pret_annulations__pret_id',
  );

  $$PretAnnulationsTableProcessedTableManager get pretAnnulationsRefs {
    final manager = $$PretAnnulationsTableTableManager(
      $_db,
      $_db.pretAnnulations,
    ).filter((f) => f.pretId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _pretAnnulationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PretsTableFilterComposer extends Composer<_$AppDatabase, $PretsTable> {
  $$PretsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get principalFcfa => $composableBuilder(
    column: $table.principalFcfa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dureeJours => $composableBuilder(
    column: $table.dureeJours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initiatedByPhone => $composableBuilder(
    column: $table.initiatedByPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmationCode => $composableBuilder(
    column: $table.confirmationCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pretConfirmationsRefs(
    Expression<bool> Function($$PretConfirmationsTableFilterComposer f) f,
  ) {
    final $$PretConfirmationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pretConfirmations,
      getReferencedColumn: (t) => t.pretId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretConfirmationsTableFilterComposer(
            $db: $db,
            $table: $db.pretConfirmations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pretRemboursementsRefs(
    Expression<bool> Function($$PretRemboursementsTableFilterComposer f) f,
  ) {
    final $$PretRemboursementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pretRemboursements,
      getReferencedColumn: (t) => t.pretId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretRemboursementsTableFilterComposer(
            $db: $db,
            $table: $db.pretRemboursements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pretAnnulationsRefs(
    Expression<bool> Function($$PretAnnulationsTableFilterComposer f) f,
  ) {
    final $$PretAnnulationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pretAnnulations,
      getReferencedColumn: (t) => t.pretId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretAnnulationsTableFilterComposer(
            $db: $db,
            $table: $db.pretAnnulations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PretsTableOrderingComposer
    extends Composer<_$AppDatabase, $PretsTable> {
  $$PretsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get principalFcfa => $composableBuilder(
    column: $table.principalFcfa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dureeJours => $composableBuilder(
    column: $table.dureeJours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initiatedByPhone => $composableBuilder(
    column: $table.initiatedByPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmationCode => $composableBuilder(
    column: $table.confirmationCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PretsTable> {
  $$PretsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get principalFcfa => $composableBuilder(
    column: $table.principalFcfa,
    builder: (column) => column,
  );

  GeneratedColumn<double> get interestRatePercent => $composableBuilder(
    column: $table.interestRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dureeJours => $composableBuilder(
    column: $table.dureeJours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get initiatedByPhone => $composableBuilder(
    column: $table.initiatedByPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confirmationCode => $composableBuilder(
    column: $table.confirmationCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pretConfirmationsRefs<T extends Object>(
    Expression<T> Function($$PretConfirmationsTableAnnotationComposer a) f,
  ) {
    final $$PretConfirmationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pretConfirmations,
          getReferencedColumn: (t) => t.pretId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PretConfirmationsTableAnnotationComposer(
                $db: $db,
                $table: $db.pretConfirmations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> pretRemboursementsRefs<T extends Object>(
    Expression<T> Function($$PretRemboursementsTableAnnotationComposer a) f,
  ) {
    final $$PretRemboursementsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.pretRemboursements,
          getReferencedColumn: (t) => t.pretId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PretRemboursementsTableAnnotationComposer(
                $db: $db,
                $table: $db.pretRemboursements,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> pretAnnulationsRefs<T extends Object>(
    Expression<T> Function($$PretAnnulationsTableAnnotationComposer a) f,
  ) {
    final $$PretAnnulationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pretAnnulations,
      getReferencedColumn: (t) => t.pretId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretAnnulationsTableAnnotationComposer(
            $db: $db,
            $table: $db.pretAnnulations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PretsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PretsTable,
          Pret,
          $$PretsTableFilterComposer,
          $$PretsTableOrderingComposer,
          $$PretsTableAnnotationComposer,
          $$PretsTableCreateCompanionBuilder,
          $$PretsTableUpdateCompanionBuilder,
          (Pret, $$PretsTableReferences),
          Pret,
          PrefetchHooks Function({
            bool groupId,
            bool cycleId,
            bool memberId,
            bool pretConfirmationsRefs,
            bool pretRemboursementsRefs,
            bool pretAnnulationsRefs,
          })
        > {
  $$PretsTableTableManager(_$AppDatabase db, $PretsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PretsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PretsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PretsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> principalFcfa = const Value.absent(),
                Value<double> interestRatePercent = const Value.absent(),
                Value<int?> dureeJours = const Value.absent(),
                Value<String> initiatedByPhone = const Value.absent(),
                Value<String?> confirmationCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PretsCompanion(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                principalFcfa: principalFcfa,
                interestRatePercent: interestRatePercent,
                dureeJours: dureeJours,
                initiatedByPhone: initiatedByPhone,
                confirmationCode: confirmationCode,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                required String id,
                required String groupId,
                required String cycleId,
                required String memberId,
                required int principalFcfa,
                required double interestRatePercent,
                Value<int?> dureeJours = const Value.absent(),
                required String initiatedByPhone,
                Value<String?> confirmationCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PretsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                principalFcfa: principalFcfa,
                interestRatePercent: interestRatePercent,
                dureeJours: dureeJours,
                initiatedByPhone: initiatedByPhone,
                confirmationCode: confirmationCode,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PretsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                cycleId = false,
                memberId = false,
                pretConfirmationsRefs = false,
                pretRemboursementsRefs = false,
                pretAnnulationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pretConfirmationsRefs) db.pretConfirmations,
                    if (pretRemboursementsRefs) db.pretRemboursements,
                    if (pretAnnulationsRefs) db.pretAnnulations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable: $$PretsTableReferences
                                        ._groupIdTable(db),
                                    referencedColumn: $$PretsTableReferences
                                        ._groupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable: $$PretsTableReferences
                                        ._cycleIdTable(db),
                                    referencedColumn: $$PretsTableReferences
                                        ._cycleIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (memberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.memberId,
                                    referencedTable: $$PretsTableReferences
                                        ._memberIdTable(db),
                                    referencedColumn: $$PretsTableReferences
                                        ._memberIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pretConfirmationsRefs)
                        await $_getPrefetchedData<
                          Pret,
                          $PretsTable,
                          PretConfirmation
                        >(
                          currentTable: table,
                          referencedTable: $$PretsTableReferences
                              ._pretConfirmationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PretsTableReferences(
                                db,
                                table,
                                p0,
                              ).pretConfirmationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pretId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pretRemboursementsRefs)
                        await $_getPrefetchedData<
                          Pret,
                          $PretsTable,
                          PretRemboursement
                        >(
                          currentTable: table,
                          referencedTable: $$PretsTableReferences
                              ._pretRemboursementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PretsTableReferences(
                                db,
                                table,
                                p0,
                              ).pretRemboursementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pretId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pretAnnulationsRefs)
                        await $_getPrefetchedData<
                          Pret,
                          $PretsTable,
                          PretAnnulation
                        >(
                          currentTable: table,
                          referencedTable: $$PretsTableReferences
                              ._pretAnnulationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PretsTableReferences(
                                db,
                                table,
                                p0,
                              ).pretAnnulationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pretId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PretsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PretsTable,
      Pret,
      $$PretsTableFilterComposer,
      $$PretsTableOrderingComposer,
      $$PretsTableAnnotationComposer,
      $$PretsTableCreateCompanionBuilder,
      $$PretsTableUpdateCompanionBuilder,
      (Pret, $$PretsTableReferences),
      Pret,
      PrefetchHooks Function({
        bool groupId,
        bool cycleId,
        bool memberId,
        bool pretConfirmationsRefs,
        bool pretRemboursementsRefs,
        bool pretAnnulationsRefs,
      })
    >;
typedef $$PretConfirmationsTableCreateCompanionBuilder =
    PretConfirmationsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      required String id,
      required String pretId,
      Value<String> methode,
      Value<String?> codeSaisi,
      Value<String?> confirmedByPhone,
      Value<String?> witnessPhone,
      Value<String?> signatureData,
      Value<DateTime> confirmedAt,
      Value<int> rowid,
    });
typedef $$PretConfirmationsTableUpdateCompanionBuilder =
    PretConfirmationsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> id,
      Value<String> pretId,
      Value<String> methode,
      Value<String?> codeSaisi,
      Value<String?> confirmedByPhone,
      Value<String?> witnessPhone,
      Value<String?> signatureData,
      Value<DateTime> confirmedAt,
      Value<int> rowid,
    });

final class $$PretConfirmationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PretConfirmationsTable,
          PretConfirmation
        > {
  $$PretConfirmationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PretsTable _pretIdTable(_$AppDatabase db) =>
      db.prets.createAlias('pret_confirmations__pret_id__prets__id');

  $$PretsTableProcessedTableManager get pretId {
    final $_column = $_itemColumn<String>('pret_id')!;

    final manager = $$PretsTableTableManager(
      $_db,
      $_db.prets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pretIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PretConfirmationsTableFilterComposer
    extends Composer<_$AppDatabase, $PretConfirmationsTable> {
  $$PretConfirmationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methode => $composableBuilder(
    column: $table.methode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeSaisi => $composableBuilder(
    column: $table.codeSaisi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedByPhone => $composableBuilder(
    column: $table.confirmedByPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get witnessPhone => $composableBuilder(
    column: $table.witnessPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatureData => $composableBuilder(
    column: $table.signatureData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PretsTableFilterComposer get pretId {
    final $$PretsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableFilterComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretConfirmationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PretConfirmationsTable> {
  $$PretConfirmationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methode => $composableBuilder(
    column: $table.methode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeSaisi => $composableBuilder(
    column: $table.codeSaisi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedByPhone => $composableBuilder(
    column: $table.confirmedByPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get witnessPhone => $composableBuilder(
    column: $table.witnessPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatureData => $composableBuilder(
    column: $table.signatureData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PretsTableOrderingComposer get pretId {
    final $$PretsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableOrderingComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretConfirmationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PretConfirmationsTable> {
  $$PretConfirmationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get methode =>
      $composableBuilder(column: $table.methode, builder: (column) => column);

  GeneratedColumn<String> get codeSaisi =>
      $composableBuilder(column: $table.codeSaisi, builder: (column) => column);

  GeneratedColumn<String> get confirmedByPhone => $composableBuilder(
    column: $table.confirmedByPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get witnessPhone => $composableBuilder(
    column: $table.witnessPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signatureData => $composableBuilder(
    column: $table.signatureData,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  $$PretsTableAnnotationComposer get pretId {
    final $$PretsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableAnnotationComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretConfirmationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PretConfirmationsTable,
          PretConfirmation,
          $$PretConfirmationsTableFilterComposer,
          $$PretConfirmationsTableOrderingComposer,
          $$PretConfirmationsTableAnnotationComposer,
          $$PretConfirmationsTableCreateCompanionBuilder,
          $$PretConfirmationsTableUpdateCompanionBuilder,
          (PretConfirmation, $$PretConfirmationsTableReferences),
          PretConfirmation,
          PrefetchHooks Function({bool pretId})
        > {
  $$PretConfirmationsTableTableManager(
    _$AppDatabase db,
    $PretConfirmationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PretConfirmationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PretConfirmationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PretConfirmationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> pretId = const Value.absent(),
                Value<String> methode = const Value.absent(),
                Value<String?> codeSaisi = const Value.absent(),
                Value<String?> confirmedByPhone = const Value.absent(),
                Value<String?> witnessPhone = const Value.absent(),
                Value<String?> signatureData = const Value.absent(),
                Value<DateTime> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PretConfirmationsCompanion(
                previousHash: previousHash,
                hash: hash,
                id: id,
                pretId: pretId,
                methode: methode,
                codeSaisi: codeSaisi,
                confirmedByPhone: confirmedByPhone,
                witnessPhone: witnessPhone,
                signatureData: signatureData,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                required String id,
                required String pretId,
                Value<String> methode = const Value.absent(),
                Value<String?> codeSaisi = const Value.absent(),
                Value<String?> confirmedByPhone = const Value.absent(),
                Value<String?> witnessPhone = const Value.absent(),
                Value<String?> signatureData = const Value.absent(),
                Value<DateTime> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PretConfirmationsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                id: id,
                pretId: pretId,
                methode: methode,
                codeSaisi: codeSaisi,
                confirmedByPhone: confirmedByPhone,
                witnessPhone: witnessPhone,
                signatureData: signatureData,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PretConfirmationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pretId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pretId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pretId,
                                referencedTable:
                                    $$PretConfirmationsTableReferences
                                        ._pretIdTable(db),
                                referencedColumn:
                                    $$PretConfirmationsTableReferences
                                        ._pretIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PretConfirmationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PretConfirmationsTable,
      PretConfirmation,
      $$PretConfirmationsTableFilterComposer,
      $$PretConfirmationsTableOrderingComposer,
      $$PretConfirmationsTableAnnotationComposer,
      $$PretConfirmationsTableCreateCompanionBuilder,
      $$PretConfirmationsTableUpdateCompanionBuilder,
      (PretConfirmation, $$PretConfirmationsTableReferences),
      PretConfirmation,
      PrefetchHooks Function({bool pretId})
    >;
typedef $$PretRemboursementsTableCreateCompanionBuilder =
    PretRemboursementsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      required String id,
      required String pretId,
      required int montantFcfa,
      required String recordedByPhone,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });
typedef $$PretRemboursementsTableUpdateCompanionBuilder =
    PretRemboursementsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      Value<String> id,
      Value<String> pretId,
      Value<int> montantFcfa,
      Value<String> recordedByPhone,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

final class $$PretRemboursementsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PretRemboursementsTable,
          PretRemboursement
        > {
  $$PretRemboursementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PretsTable _pretIdTable(_$AppDatabase db) =>
      db.prets.createAlias('pret_remboursements__pret_id__prets__id');

  $$PretsTableProcessedTableManager get pretId {
    final $_column = $_itemColumn<String>('pret_id')!;

    final manager = $$PretsTableTableManager(
      $_db,
      $_db.prets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pretIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PretRemboursementsTableFilterComposer
    extends Composer<_$AppDatabase, $PretRemboursementsTable> {
  $$PretRemboursementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PretsTableFilterComposer get pretId {
    final $$PretsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableFilterComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretRemboursementsTableOrderingComposer
    extends Composer<_$AppDatabase, $PretRemboursementsTable> {
  $$PretRemboursementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PretsTableOrderingComposer get pretId {
    final $$PretsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableOrderingComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretRemboursementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PretRemboursementsTable> {
  $$PretRemboursementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$PretsTableAnnotationComposer get pretId {
    final $$PretsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableAnnotationComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretRemboursementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PretRemboursementsTable,
          PretRemboursement,
          $$PretRemboursementsTableFilterComposer,
          $$PretRemboursementsTableOrderingComposer,
          $$PretRemboursementsTableAnnotationComposer,
          $$PretRemboursementsTableCreateCompanionBuilder,
          $$PretRemboursementsTableUpdateCompanionBuilder,
          (PretRemboursement, $$PretRemboursementsTableReferences),
          PretRemboursement,
          PrefetchHooks Function({bool pretId})
        > {
  $$PretRemboursementsTableTableManager(
    _$AppDatabase db,
    $PretRemboursementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PretRemboursementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PretRemboursementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PretRemboursementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> pretId = const Value.absent(),
                Value<int> montantFcfa = const Value.absent(),
                Value<String> recordedByPhone = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PretRemboursementsCompanion(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                pretId: pretId,
                montantFcfa: montantFcfa,
                recordedByPhone: recordedByPhone,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                required String id,
                required String pretId,
                required int montantFcfa,
                required String recordedByPhone,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PretRemboursementsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                pretId: pretId,
                montantFcfa: montantFcfa,
                recordedByPhone: recordedByPhone,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PretRemboursementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pretId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pretId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pretId,
                                referencedTable:
                                    $$PretRemboursementsTableReferences
                                        ._pretIdTable(db),
                                referencedColumn:
                                    $$PretRemboursementsTableReferences
                                        ._pretIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PretRemboursementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PretRemboursementsTable,
      PretRemboursement,
      $$PretRemboursementsTableFilterComposer,
      $$PretRemboursementsTableOrderingComposer,
      $$PretRemboursementsTableAnnotationComposer,
      $$PretRemboursementsTableCreateCompanionBuilder,
      $$PretRemboursementsTableUpdateCompanionBuilder,
      (PretRemboursement, $$PretRemboursementsTableReferences),
      PretRemboursement,
      PrefetchHooks Function({bool pretId})
    >;
typedef $$PretAnnulationsTableCreateCompanionBuilder =
    PretAnnulationsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      required String id,
      required String pretId,
      required String raison,
      required String annuleParPhone,
      Value<DateTime> annuleAt,
      Value<int> rowid,
    });
typedef $$PretAnnulationsTableUpdateCompanionBuilder =
    PretAnnulationsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> id,
      Value<String> pretId,
      Value<String> raison,
      Value<String> annuleParPhone,
      Value<DateTime> annuleAt,
      Value<int> rowid,
    });

final class $$PretAnnulationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PretAnnulationsTable, PretAnnulation> {
  $$PretAnnulationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PretsTable _pretIdTable(_$AppDatabase db) =>
      db.prets.createAlias('pret_annulations__pret_id__prets__id');

  $$PretsTableProcessedTableManager get pretId {
    final $_column = $_itemColumn<String>('pret_id')!;

    final manager = $$PretsTableTableManager(
      $_db,
      $_db.prets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pretIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PretAnnulationsTableFilterComposer
    extends Composer<_$AppDatabase, $PretAnnulationsTable> {
  $$PretAnnulationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raison => $composableBuilder(
    column: $table.raison,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annuleParPhone => $composableBuilder(
    column: $table.annuleParPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get annuleAt => $composableBuilder(
    column: $table.annuleAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PretsTableFilterComposer get pretId {
    final $$PretsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableFilterComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretAnnulationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PretAnnulationsTable> {
  $$PretAnnulationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raison => $composableBuilder(
    column: $table.raison,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annuleParPhone => $composableBuilder(
    column: $table.annuleParPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get annuleAt => $composableBuilder(
    column: $table.annuleAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PretsTableOrderingComposer get pretId {
    final $$PretsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableOrderingComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretAnnulationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PretAnnulationsTable> {
  $$PretAnnulationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get raison =>
      $composableBuilder(column: $table.raison, builder: (column) => column);

  GeneratedColumn<String> get annuleParPhone => $composableBuilder(
    column: $table.annuleParPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get annuleAt =>
      $composableBuilder(column: $table.annuleAt, builder: (column) => column);

  $$PretsTableAnnotationComposer get pretId {
    final $$PretsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pretId,
      referencedTable: $db.prets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PretsTableAnnotationComposer(
            $db: $db,
            $table: $db.prets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PretAnnulationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PretAnnulationsTable,
          PretAnnulation,
          $$PretAnnulationsTableFilterComposer,
          $$PretAnnulationsTableOrderingComposer,
          $$PretAnnulationsTableAnnotationComposer,
          $$PretAnnulationsTableCreateCompanionBuilder,
          $$PretAnnulationsTableUpdateCompanionBuilder,
          (PretAnnulation, $$PretAnnulationsTableReferences),
          PretAnnulation,
          PrefetchHooks Function({bool pretId})
        > {
  $$PretAnnulationsTableTableManager(
    _$AppDatabase db,
    $PretAnnulationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PretAnnulationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PretAnnulationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PretAnnulationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> pretId = const Value.absent(),
                Value<String> raison = const Value.absent(),
                Value<String> annuleParPhone = const Value.absent(),
                Value<DateTime> annuleAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PretAnnulationsCompanion(
                previousHash: previousHash,
                hash: hash,
                id: id,
                pretId: pretId,
                raison: raison,
                annuleParPhone: annuleParPhone,
                annuleAt: annuleAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                required String id,
                required String pretId,
                required String raison,
                required String annuleParPhone,
                Value<DateTime> annuleAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PretAnnulationsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                id: id,
                pretId: pretId,
                raison: raison,
                annuleParPhone: annuleParPhone,
                annuleAt: annuleAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PretAnnulationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pretId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pretId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pretId,
                                referencedTable:
                                    $$PretAnnulationsTableReferences
                                        ._pretIdTable(db),
                                referencedColumn:
                                    $$PretAnnulationsTableReferences
                                        ._pretIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PretAnnulationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PretAnnulationsTable,
      PretAnnulation,
      $$PretAnnulationsTableFilterComposer,
      $$PretAnnulationsTableOrderingComposer,
      $$PretAnnulationsTableAnnotationComposer,
      $$PretAnnulationsTableCreateCompanionBuilder,
      $$PretAnnulationsTableUpdateCompanionBuilder,
      (PretAnnulation, $$PretAnnulationsTableReferences),
      PretAnnulation,
      PrefetchHooks Function({bool pretId})
    >;
typedef $$AmendesTableCreateCompanionBuilder =
    AmendesCompanion Function({
      Value<String?> previousHash,
      required String hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      required String id,
      required String groupId,
      required String cycleId,
      required String memberId,
      required int montantFcfa,
      required String motif,
      required String recordedByPhone,
      Value<DateTime> recordedAt,
      Value<bool> estAutoGeneree,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });
typedef $$AmendesTableUpdateCompanionBuilder =
    AmendesCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      Value<String> id,
      Value<String> groupId,
      Value<String> cycleId,
      Value<String> memberId,
      Value<int> montantFcfa,
      Value<String> motif,
      Value<String> recordedByPhone,
      Value<DateTime> recordedAt,
      Value<bool> estAutoGeneree,
      Value<DateTime?> confirmedAt,
      Value<int> rowid,
    });

final class $$AmendesTableReferences
    extends BaseReferences<_$AppDatabase, $AmendesTable, Amende> {
  $$AmendesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('amendes__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CyclesTable _cycleIdTable(_$AppDatabase db) =>
      db.cycles.createAlias('amendes__cycle_id__cycles__id');

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('amendes__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AmendeAnnulationsTable, List<AmendeAnnulation>>
  _amendeAnnulationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.amendeAnnulations,
        aliasName: 'amendes__id__amende_annulations__amende_id',
      );

  $$AmendeAnnulationsTableProcessedTableManager get amendeAnnulationsRefs {
    final manager = $$AmendeAnnulationsTableTableManager(
      $_db,
      $_db.amendeAnnulations,
    ).filter((f) => f.amendeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _amendeAnnulationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AmendesTableFilterComposer
    extends Composer<_$AppDatabase, $AmendesTable> {
  $$AmendesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motif => $composableBuilder(
    column: $table.motif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get estAutoGeneree => $composableBuilder(
    column: $table.estAutoGeneree,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> amendeAnnulationsRefs(
    Expression<bool> Function($$AmendeAnnulationsTableFilterComposer f) f,
  ) {
    final $$AmendeAnnulationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.amendeAnnulations,
      getReferencedColumn: (t) => t.amendeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendeAnnulationsTableFilterComposer(
            $db: $db,
            $table: $db.amendeAnnulations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AmendesTableOrderingComposer
    extends Composer<_$AppDatabase, $AmendesTable> {
  $$AmendesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motif => $composableBuilder(
    column: $table.motif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get estAutoGeneree => $composableBuilder(
    column: $table.estAutoGeneree,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmendesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AmendesTable> {
  $$AmendesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motif =>
      $composableBuilder(column: $table.motif, builder: (column) => column);

  GeneratedColumn<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get estAutoGeneree => $composableBuilder(
    column: $table.estAutoGeneree,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> amendeAnnulationsRefs<T extends Object>(
    Expression<T> Function($$AmendeAnnulationsTableAnnotationComposer a) f,
  ) {
    final $$AmendeAnnulationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.amendeAnnulations,
          getReferencedColumn: (t) => t.amendeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AmendeAnnulationsTableAnnotationComposer(
                $db: $db,
                $table: $db.amendeAnnulations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AmendesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AmendesTable,
          Amende,
          $$AmendesTableFilterComposer,
          $$AmendesTableOrderingComposer,
          $$AmendesTableAnnotationComposer,
          $$AmendesTableCreateCompanionBuilder,
          $$AmendesTableUpdateCompanionBuilder,
          (Amende, $$AmendesTableReferences),
          Amende,
          PrefetchHooks Function({
            bool groupId,
            bool cycleId,
            bool memberId,
            bool amendeAnnulationsRefs,
          })
        > {
  $$AmendesTableTableManager(_$AppDatabase db, $AmendesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmendesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmendesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmendesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> montantFcfa = const Value.absent(),
                Value<String> motif = const Value.absent(),
                Value<String> recordedByPhone = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<bool> estAutoGeneree = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AmendesCompanion(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                montantFcfa: montantFcfa,
                motif: motif,
                recordedByPhone: recordedByPhone,
                recordedAt: recordedAt,
                estAutoGeneree: estAutoGeneree,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                required String id,
                required String groupId,
                required String cycleId,
                required String memberId,
                required int montantFcfa,
                required String motif,
                required String recordedByPhone,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<bool> estAutoGeneree = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AmendesCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                montantFcfa: montantFcfa,
                motif: motif,
                recordedByPhone: recordedByPhone,
                recordedAt: recordedAt,
                estAutoGeneree: estAutoGeneree,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AmendesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                cycleId = false,
                memberId = false,
                amendeAnnulationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (amendeAnnulationsRefs) db.amendeAnnulations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable: $$AmendesTableReferences
                                        ._groupIdTable(db),
                                    referencedColumn: $$AmendesTableReferences
                                        ._groupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (cycleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cycleId,
                                    referencedTable: $$AmendesTableReferences
                                        ._cycleIdTable(db),
                                    referencedColumn: $$AmendesTableReferences
                                        ._cycleIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (memberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.memberId,
                                    referencedTable: $$AmendesTableReferences
                                        ._memberIdTable(db),
                                    referencedColumn: $$AmendesTableReferences
                                        ._memberIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (amendeAnnulationsRefs)
                        await $_getPrefetchedData<
                          Amende,
                          $AmendesTable,
                          AmendeAnnulation
                        >(
                          currentTable: table,
                          referencedTable: $$AmendesTableReferences
                              ._amendeAnnulationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AmendesTableReferences(
                                db,
                                table,
                                p0,
                              ).amendeAnnulationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.amendeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AmendesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AmendesTable,
      Amende,
      $$AmendesTableFilterComposer,
      $$AmendesTableOrderingComposer,
      $$AmendesTableAnnotationComposer,
      $$AmendesTableCreateCompanionBuilder,
      $$AmendesTableUpdateCompanionBuilder,
      (Amende, $$AmendesTableReferences),
      Amende,
      PrefetchHooks Function({
        bool groupId,
        bool cycleId,
        bool memberId,
        bool amendeAnnulationsRefs,
      })
    >;
typedef $$AmendeAnnulationsTableCreateCompanionBuilder =
    AmendeAnnulationsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      required String id,
      required String amendeId,
      required String raison,
      required String annuleParPhone,
      Value<DateTime> annuleAt,
      Value<int> rowid,
    });
typedef $$AmendeAnnulationsTableUpdateCompanionBuilder =
    AmendeAnnulationsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> id,
      Value<String> amendeId,
      Value<String> raison,
      Value<String> annuleParPhone,
      Value<DateTime> annuleAt,
      Value<int> rowid,
    });

final class $$AmendeAnnulationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AmendeAnnulationsTable,
          AmendeAnnulation
        > {
  $$AmendeAnnulationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AmendesTable _amendeIdTable(_$AppDatabase db) =>
      db.amendes.createAlias('amende_annulations__amende_id__amendes__id');

  $$AmendesTableProcessedTableManager get amendeId {
    final $_column = $_itemColumn<String>('amende_id')!;

    final manager = $$AmendesTableTableManager(
      $_db,
      $_db.amendes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_amendeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AmendeAnnulationsTableFilterComposer
    extends Composer<_$AppDatabase, $AmendeAnnulationsTable> {
  $$AmendeAnnulationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get raison => $composableBuilder(
    column: $table.raison,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annuleParPhone => $composableBuilder(
    column: $table.annuleParPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get annuleAt => $composableBuilder(
    column: $table.annuleAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AmendesTableFilterComposer get amendeId {
    final $$AmendesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.amendeId,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableFilterComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmendeAnnulationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AmendeAnnulationsTable> {
  $$AmendeAnnulationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get raison => $composableBuilder(
    column: $table.raison,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annuleParPhone => $composableBuilder(
    column: $table.annuleParPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get annuleAt => $composableBuilder(
    column: $table.annuleAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AmendesTableOrderingComposer get amendeId {
    final $$AmendesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.amendeId,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableOrderingComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmendeAnnulationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AmendeAnnulationsTable> {
  $$AmendeAnnulationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get raison =>
      $composableBuilder(column: $table.raison, builder: (column) => column);

  GeneratedColumn<String> get annuleParPhone => $composableBuilder(
    column: $table.annuleParPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get annuleAt =>
      $composableBuilder(column: $table.annuleAt, builder: (column) => column);

  $$AmendesTableAnnotationComposer get amendeId {
    final $$AmendesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.amendeId,
      referencedTable: $db.amendes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AmendesTableAnnotationComposer(
            $db: $db,
            $table: $db.amendes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AmendeAnnulationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AmendeAnnulationsTable,
          AmendeAnnulation,
          $$AmendeAnnulationsTableFilterComposer,
          $$AmendeAnnulationsTableOrderingComposer,
          $$AmendeAnnulationsTableAnnotationComposer,
          $$AmendeAnnulationsTableCreateCompanionBuilder,
          $$AmendeAnnulationsTableUpdateCompanionBuilder,
          (AmendeAnnulation, $$AmendeAnnulationsTableReferences),
          AmendeAnnulation,
          PrefetchHooks Function({bool amendeId})
        > {
  $$AmendeAnnulationsTableTableManager(
    _$AppDatabase db,
    $AmendeAnnulationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmendeAnnulationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmendeAnnulationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmendeAnnulationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> amendeId = const Value.absent(),
                Value<String> raison = const Value.absent(),
                Value<String> annuleParPhone = const Value.absent(),
                Value<DateTime> annuleAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AmendeAnnulationsCompanion(
                previousHash: previousHash,
                hash: hash,
                id: id,
                amendeId: amendeId,
                raison: raison,
                annuleParPhone: annuleParPhone,
                annuleAt: annuleAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                required String id,
                required String amendeId,
                required String raison,
                required String annuleParPhone,
                Value<DateTime> annuleAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AmendeAnnulationsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                id: id,
                amendeId: amendeId,
                raison: raison,
                annuleParPhone: annuleParPhone,
                annuleAt: annuleAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AmendeAnnulationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({amendeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (amendeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.amendeId,
                                referencedTable:
                                    $$AmendeAnnulationsTableReferences
                                        ._amendeIdTable(db),
                                referencedColumn:
                                    $$AmendeAnnulationsTableReferences
                                        ._amendeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AmendeAnnulationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AmendeAnnulationsTable,
      AmendeAnnulation,
      $$AmendeAnnulationsTableFilterComposer,
      $$AmendeAnnulationsTableOrderingComposer,
      $$AmendeAnnulationsTableAnnotationComposer,
      $$AmendeAnnulationsTableCreateCompanionBuilder,
      $$AmendeAnnulationsTableUpdateCompanionBuilder,
      (AmendeAnnulation, $$AmendeAnnulationsTableReferences),
      AmendeAnnulation,
      PrefetchHooks Function({bool amendeId})
    >;
typedef $$FondsSolidariteContributionsTableCreateCompanionBuilder =
    FondsSolidariteContributionsCompanion Function({
      Value<String?> previousHash,
      required String hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      required String id,
      required String groupId,
      required String cycleId,
      Value<String?> memberId,
      required int montantFcfa,
      required String motif,
      required String recordedByPhone,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });
typedef $$FondsSolidariteContributionsTableUpdateCompanionBuilder =
    FondsSolidariteContributionsCompanion Function({
      Value<String?> previousHash,
      Value<String> hash,
      Value<String> provenance,
      Value<bool> estApproximatif,
      Value<String> id,
      Value<String> groupId,
      Value<String> cycleId,
      Value<String?> memberId,
      Value<int> montantFcfa,
      Value<String> motif,
      Value<String> recordedByPhone,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

final class $$FondsSolidariteContributionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FondsSolidariteContributionsTable,
          FondsSolidariteContribution
        > {
  $$FondsSolidariteContributionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTable _groupIdTable(_$AppDatabase db) => db.groups.createAlias(
    'fonds_solidarite_contributions__group_id__groups__id',
  );

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CyclesTable _cycleIdTable(_$AppDatabase db) => db.cycles.createAlias(
    'fonds_solidarite_contributions__cycle_id__cycles__id',
  );

  $$CyclesTableProcessedTableManager get cycleId {
    final $_column = $_itemColumn<String>('cycle_id')!;

    final manager = $$CyclesTableTableManager(
      $_db,
      $_db.cycles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cycleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) => db.members
      .createAlias('fonds_solidarite_contributions__member_id__members__id');

  $$MembersTableProcessedTableManager? get memberId {
    final $_column = $_itemColumn<String>('member_id');
    if ($_column == null) return null;
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FondsSolidariteContributionsTableFilterComposer
    extends Composer<_$AppDatabase, $FondsSolidariteContributionsTable> {
  $$FondsSolidariteContributionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motif => $composableBuilder(
    column: $table.motif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableFilterComposer get cycleId {
    final $$CyclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableFilterComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FondsSolidariteContributionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FondsSolidariteContributionsTable> {
  $$FondsSolidariteContributionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motif => $composableBuilder(
    column: $table.motif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableOrderingComposer get cycleId {
    final $$CyclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableOrderingComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FondsSolidariteContributionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FondsSolidariteContributionsTable> {
  $$FondsSolidariteContributionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get estApproximatif => $composableBuilder(
    column: $table.estApproximatif,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get montantFcfa => $composableBuilder(
    column: $table.montantFcfa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motif =>
      $composableBuilder(column: $table.motif, builder: (column) => column);

  GeneratedColumn<String> get recordedByPhone => $composableBuilder(
    column: $table.recordedByPhone,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CyclesTableAnnotationComposer get cycleId {
    final $$CyclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cycleId,
      referencedTable: $db.cycles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CyclesTableAnnotationComposer(
            $db: $db,
            $table: $db.cycles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FondsSolidariteContributionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FondsSolidariteContributionsTable,
          FondsSolidariteContribution,
          $$FondsSolidariteContributionsTableFilterComposer,
          $$FondsSolidariteContributionsTableOrderingComposer,
          $$FondsSolidariteContributionsTableAnnotationComposer,
          $$FondsSolidariteContributionsTableCreateCompanionBuilder,
          $$FondsSolidariteContributionsTableUpdateCompanionBuilder,
          (
            FondsSolidariteContribution,
            $$FondsSolidariteContributionsTableReferences,
          ),
          FondsSolidariteContribution,
          PrefetchHooks Function({bool groupId, bool cycleId, bool memberId})
        > {
  $$FondsSolidariteContributionsTableTableManager(
    _$AppDatabase db,
    $FondsSolidariteContributionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FondsSolidariteContributionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FondsSolidariteContributionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FondsSolidariteContributionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> cycleId = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<int> montantFcfa = const Value.absent(),
                Value<String> motif = const Value.absent(),
                Value<String> recordedByPhone = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FondsSolidariteContributionsCompanion(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                montantFcfa: montantFcfa,
                motif: motif,
                recordedByPhone: recordedByPhone,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> previousHash = const Value.absent(),
                required String hash,
                Value<String> provenance = const Value.absent(),
                Value<bool> estApproximatif = const Value.absent(),
                required String id,
                required String groupId,
                required String cycleId,
                Value<String?> memberId = const Value.absent(),
                required int montantFcfa,
                required String motif,
                required String recordedByPhone,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FondsSolidariteContributionsCompanion.insert(
                previousHash: previousHash,
                hash: hash,
                provenance: provenance,
                estApproximatif: estApproximatif,
                id: id,
                groupId: groupId,
                cycleId: cycleId,
                memberId: memberId,
                montantFcfa: montantFcfa,
                motif: motif,
                recordedByPhone: recordedByPhone,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FondsSolidariteContributionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false, cycleId = false, memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable:
                                    $$FondsSolidariteContributionsTableReferences
                                        ._groupIdTable(db),
                                referencedColumn:
                                    $$FondsSolidariteContributionsTableReferences
                                        ._groupIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (cycleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cycleId,
                                referencedTable:
                                    $$FondsSolidariteContributionsTableReferences
                                        ._cycleIdTable(db),
                                referencedColumn:
                                    $$FondsSolidariteContributionsTableReferences
                                        ._cycleIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable:
                                    $$FondsSolidariteContributionsTableReferences
                                        ._memberIdTable(db),
                                referencedColumn:
                                    $$FondsSolidariteContributionsTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FondsSolidariteContributionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FondsSolidariteContributionsTable,
      FondsSolidariteContribution,
      $$FondsSolidariteContributionsTableFilterComposer,
      $$FondsSolidariteContributionsTableOrderingComposer,
      $$FondsSolidariteContributionsTableAnnotationComposer,
      $$FondsSolidariteContributionsTableCreateCompanionBuilder,
      $$FondsSolidariteContributionsTableUpdateCompanionBuilder,
      (
        FondsSolidariteContribution,
        $$FondsSolidariteContributionsTableReferences,
      ),
      FondsSolidariteContribution,
      PrefetchHooks Function({bool groupId, bool cycleId, bool memberId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$AgentAssignmentsTableTableManager get agentAssignments =>
      $$AgentAssignmentsTableTableManager(_db, _db.agentAssignments);
  $$AgentAssignmentRevocationsTableTableManager
  get agentAssignmentRevocations =>
      $$AgentAssignmentRevocationsTableTableManager(
        _db,
        _db.agentAssignmentRevocations,
      );
  $$CyclesTableTableManager get cycles =>
      $$CyclesTableTableManager(_db, _db.cycles);
  $$CotisationsTableTableManager get cotisations =>
      $$CotisationsTableTableManager(_db, _db.cotisations);
  $$CarnetsEngagesTableTableManager get carnetsEngages =>
      $$CarnetsEngagesTableTableManager(_db, _db.carnetsEngages);
  $$PretsTableTableManager get prets =>
      $$PretsTableTableManager(_db, _db.prets);
  $$PretConfirmationsTableTableManager get pretConfirmations =>
      $$PretConfirmationsTableTableManager(_db, _db.pretConfirmations);
  $$PretRemboursementsTableTableManager get pretRemboursements =>
      $$PretRemboursementsTableTableManager(_db, _db.pretRemboursements);
  $$PretAnnulationsTableTableManager get pretAnnulations =>
      $$PretAnnulationsTableTableManager(_db, _db.pretAnnulations);
  $$AmendesTableTableManager get amendes =>
      $$AmendesTableTableManager(_db, _db.amendes);
  $$AmendeAnnulationsTableTableManager get amendeAnnulations =>
      $$AmendeAnnulationsTableTableManager(_db, _db.amendeAnnulations);
  $$FondsSolidariteContributionsTableTableManager
  get fondsSolidariteContributions =>
      $$FondsSolidariteContributionsTableTableManager(
        _db,
        _db.fondsSolidariteContributions,
      );
}

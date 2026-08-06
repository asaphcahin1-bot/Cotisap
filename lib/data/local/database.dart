import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_clock.dart';
import 'hash_chain.dart';
import 'tables/groups_table.dart';
import 'tables/members_table.dart';
import 'tables/agent_assignments_table.dart';
import 'tables/cycles_table.dart';
import 'tables/cotisations_table.dart';
import 'tables/carnets_engages_table.dart';
import 'tables/prets_table.dart';
import 'tables/amendes_table.dart';
import 'tables/fonds_solidarite_table.dart';

part 'database.g.dart';

const _uuid = Uuid();

@DriftDatabase(tables: [
  Groups,
  Members,
  AgentAssignments,
  AgentAssignmentRevocations,
  Cycles,
  Cotisations,
  CarnetsEngages,
  Prets,
  PretConfirmations,
  PretRemboursements,
  PretAnnulations,
  Amendes,
  AmendeAnnulations,
  FondsSolidariteContributions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(cycles, cycles.lateFeeFcfa);
          }
          if (from < 3) {
            // members.phoneNumber (obligatoire -> nullable),
            // prets.confirmationCode (obligatoire -> nullable) et les
            // nouvelles colonnes de pret_confirmations (méthode
            // code/signature) — SQLite ne permet pas d'assouplir une
            // contrainte NOT NULL par un simple ALTER, donc on recrée
            // ces tables à partir de la définition Dart courante
            // (recopie automatique des colonnes existantes).
            await m.alterTable(TableMigration(members));
            await m.alterTable(TableMigration(prets));
            await m.alterTable(TableMigration(pretConfirmations));
          }
          if (from < 4) {
            // Jour de paiement fixe, carnets engagés par membre/cycle,
            // durée de prêt (renouvellement de l'intérêt composé).
            await m.addColumn(groups, groups.paymentDayOfWeek);
            await m.addColumn(groups, groups.paymentDayOfMonth1);
            await m.addColumn(groups, groups.paymentDayOfMonth2);
            await m.addColumn(cycles, cycles.loanDurationDays);
            await m.addColumn(prets, prets.dureeJours);
            await m.createTable(carnetsEngages);
          }
          if (from < 5) {
            // Amendes automatiques : estAutoGeneree/confirmedAt sur
            // amendes, nouvelle table d'annulation dédiée.
            await m.addColumn(amendes, amendes.estAutoGeneree);
            await m.addColumn(amendes, amendes.confirmedAt);
            await m.createTable(amendeAnnulations);
          }
        },
      );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'cotisapp.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  /// Dernier hash inséré dans [tableName], ou null si la table est vide.
  /// `tableName` n'est jamais une valeur saisie par l'utilisateur — c'est
  /// toujours l'une des constantes `tableName` définies sur les classes
  /// Table de ce projet.
  Future<String?> _lastHashOf(String tableName) async {
    final row = await customSelect(
      'SELECT hash FROM $tableName ORDER BY rowid DESC LIMIT 1',
    ).getSingleOrNull();
    return row?.read<String?>('hash');
  }

  // ---------------------------------------------------------------------
  // Groupes / membres / cycles (tables mutables, pas de chaîne de hash)
  // ---------------------------------------------------------------------

  /// Jour de paiement fixe (skill avec-business-rules, section "Retard de
  /// cotisation") : selon [meetingFrequency], seul le groupe de
  /// paramètres pertinent doit être fourni — [paymentDayOfWeek] pour
  /// `hebdomadaire`, [paymentDayOfMonth1] (+ [paymentDayOfMonth2] pour
  /// `bimensuelle`) sinon. Pas de valeur par défaut devinée : un groupe
  /// sans jour de paiement configuré ne peut pas utiliser
  /// [EcheanceCalculator] (voir écran de création). Modifiable tant
  /// qu'aucune cotisation n'a été enregistrée sur le cycle en cours —
  /// voir [modifierGroupeEtCycle].
  Future<String> creerGroupe({
    required String name,
    required int cycleDurationMonths,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
  }) async {
    final id = _uuid.v4();
    await into(groups).insert(GroupsCompanion.insert(
      id: id,
      name: name,
      cycleDurationMonths: Value(cycleDurationMonths),
      meetingFrequency: Value(meetingFrequency),
      paymentDayOfWeek: Value(paymentDayOfWeek),
      paymentDayOfMonth1: Value(paymentDayOfMonth1),
      paymentDayOfMonth2: Value(paymentDayOfMonth2),
    ));
    return id;
  }

  /// Vrai si au moins une cotisation (cash ou importée) existe sur ce
  /// cycle — sert de verrou pour [modifierGroupeEtCycle] : une fois la
  /// première cotisation enregistrée, les paramètres fondateurs du
  /// groupe/cycle ne doivent plus changer rétroactivement (des calculs
  /// en dépendent déjà).
  Future<bool> cycleADesCotisations(String cycleId) async {
    final rows = await (select(cotisations)..where((c) => c.cycleId.equals(cycleId))).get();
    return rows.isNotEmpty;
  }

  /// Modifie le nom/la durée/la fréquence du groupe et les paramètres du
  /// cycle en cours (valeur du carnet, taux, amende, durée de prêt, jour
  /// de paiement) — **uniquement tant qu'aucune cotisation n'a encore
  /// été enregistrée sur ce cycle** (skill avec-business-rules : ces
  /// paramètres sont "définis en début de cycle", pas modifiables une
  /// fois que des calculs en dépendent déjà). Refuse explicitement côté
  /// base si une cotisation existe déjà — pas seulement un contrôle côté
  /// écran.
  Future<void> modifierGroupeEtCycle({
    required String groupId,
    required String cycleId,
    required String name,
    required int cycleDurationMonths,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
    required int partValueFcfa,
    required double interestRatePercent,
    required int lateFeeFcfa,
    required int loanDurationDays,
  }) async {
    final dejaCotise = await cycleADesCotisations(cycleId);
    if (dejaCotise) {
      throw StateError(
        'Impossible de modifier : une cotisation a déjà été enregistrée sur ce cycle.',
      );
    }
    await transaction(() async {
      await (update(groups)..where((g) => g.id.equals(groupId))).write(
        GroupsCompanion(
          name: Value(name),
          cycleDurationMonths: Value(cycleDurationMonths),
          meetingFrequency: Value(meetingFrequency),
          paymentDayOfWeek: Value(paymentDayOfWeek),
          paymentDayOfMonth1: Value(paymentDayOfMonth1),
          paymentDayOfMonth2: Value(paymentDayOfMonth2),
        ),
      );
      await (update(cycles)..where((c) => c.id.equals(cycleId))).write(
        CyclesCompanion(
          partValueFcfa: Value(partValueFcfa),
          interestRatePercent: Value(interestRatePercent),
          lateFeeFcfa: Value(lateFeeFcfa),
          loanDurationDays: Value(loanDurationDays),
        ),
      );
    });
  }

  /// [phoneNumber] est nullable : un membre sans aucun téléphone
  /// personnel peut être ajouté (voir [Members]). Conséquences : ce
  /// membre n'apparaîtra jamais dans [membresParTelephone] (donc jamais
  /// d'accès "membre" en lecture seule), et ses prêts devront être
  /// confirmés par signature ([confirmerPretParSignature]) plutôt que
  /// par code.
  Future<String> ajouterMembre({
    required String groupId,
    required String fullName,
    String? phoneNumber,
  }) async {
    final id = _uuid.v4();
    await into(members).insert(MembersCompanion.insert(
      id: id,
      groupId: groupId,
      fullName: fullName,
      phoneNumber: Value(phoneNumber),
    ));
    return id;
  }

  /// Tous les enregistrements membre correspondant à un numéro de
  /// téléphone, toutes groupes confondus — une même personne peut être
  /// membre de plusieurs AVEC. Base du mode "membre" en lecture seule
  /// (skill two-tier-access-model) : l'identification se fait par
  /// numéro de téléphone, jamais par sélection manuelle d'un compte.
  Future<List<Member>> membresParTelephone(String phoneNumber) {
    return (select(members)
          ..where((m) => m.phoneNumber.equals(phoneNumber) & m.active.equals(true)))
        .get();
  }

  Future<List<Member>> membresDuGroupe(String groupId) {
    return (select(members)
          ..where((m) => m.groupId.equals(groupId) & m.active.equals(true)))
        .get();
  }

  Future<String> ouvrirCycle({
    required String groupId,
    required int cycleNumber,
    required int partValueFcfa,
    required double interestRatePercent,
    int lateFeeFcfa = 0,
    int loanDurationDays = 90,
    DateTime? startedAt,
  }) async {
    final id = _uuid.v4();
    await into(cycles).insert(CyclesCompanion.insert(
      id: id,
      groupId: groupId,
      cycleNumber: cycleNumber,
      partValueFcfa: partValueFcfa,
      interestRatePercent: interestRatePercent,
      lateFeeFcfa: Value(lateFeeFcfa),
      loanDurationDays: Value(loanDurationDays),
      startedAt: startedAt != null ? Value(startedAt) : const Value.absent(),
    ));
    return id;
  }

  Future<Cycle?> cycleEnCours(String groupId) {
    return (select(cycles)
          ..where((c) => c.groupId.equals(groupId) & c.status.equals('en_cours'))
          ..orderBy([(c) => OrderingTerm.desc(c.cycleNumber)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Clôture le cycle en cours d'un groupe et ouvre immédiatement le
  /// cycle suivant. La valeur du carnet, le taux d'intérêt et l'amende
  /// de retard du nouveau cycle sont fournis explicitement — jamais
  /// recopiés du cycle précédent, car le groupe peut vouloir les changer
  /// (skill avec-business-rules : "définis par le groupe en début de
  /// cycle", potentiellement différents d'un cycle à l'autre).
  ///
  /// Le cycle clos n'est plus jamais ciblé par les écrans de saisie
  /// (cotisations, prêts, amendes) une fois le nouveau cycle ouvert : ces
  /// écrans passent toujours par [cycleEnCours]. Ses données restent
  /// consultables (écran "Cycles") mais figées.
  Future<String> cloturerCycleEtOuvrirSuivant({
    required String groupId,
    required String cycleIdACloturer,
    required int nouveauPartValueFcfa,
    required double nouveauInterestRatePercent,
    int nouveauLateFeeFcfa = 0,
    int nouveauLoanDurationDays = 90,
  }) {
    return transaction(() async {
      final cycleActuel =
          await (select(cycles)..where((c) => c.id.equals(cycleIdACloturer))).getSingle();
      if (cycleActuel.status != 'en_cours') {
        throw StateError('Ce cycle est déjà clos — impossible de le clôturer une seconde fois.');
      }
      await (update(cycles)..where((c) => c.id.equals(cycleIdACloturer))).write(
        CyclesCompanion(
          status: const Value('cloture'),
          endedAt: Value(AppClock.now()),
        ),
      );
      final id = _uuid.v4();
      await into(cycles).insert(CyclesCompanion.insert(
        id: id,
        groupId: groupId,
        cycleNumber: cycleActuel.cycleNumber + 1,
        partValueFcfa: nouveauPartValueFcfa,
        interestRatePercent: nouveauInterestRatePercent,
        lateFeeFcfa: Value(nouveauLateFeeFcfa),
        loanDurationDays: Value(nouveauLoanDurationDays),
      ));
      return id;
    });
  }

  /// Vrai si aucune donnée n'a encore été enregistrée sur ce cycle
  /// (cotisation, prêt, amende, contribution au fonds de solidarité) —
  /// condition d'éligibilité pour [annulerClotureCycle].
  Future<bool> cycleEstVide(String cycleId) async {
    if ((await cotisationsDuCycle(cycleId)).isNotEmpty) return false;
    if ((await pretsDuCycle(cycleId)).isNotEmpty) return false;
    final amendesRows =
        await (select(amendes)..where((a) => a.cycleId.equals(cycleId))).get();
    if (amendesRows.isNotEmpty) return false;
    final fondsRows = await (select(fondsSolidariteContributions)
          ..where((f) => f.cycleId.equals(cycleId)))
        .get();
    if (fondsRows.isNotEmpty) return false;
    return true;
  }

  /// Annule une clôture faite par erreur : rouvre [cycleClotureId] et
  /// supprime [cycleSuivantId] — **uniquement si ce dernier est
  /// strictement vide**. Un cycle recevant déjà des données ne peut pas
  /// être annulé automatiquement : ses cotisations/prêts/amendes portent
  /// un hash qui inclut leur `cycleId`, les réattribuer casserait la
  /// chaîne d'intégrité (voir DECISIONS.md). Dans ce cas, la correction
  /// se fait manuellement, au cas par cas.
  Future<void> annulerClotureCycle({
    required String cycleClotureId,
    required String cycleSuivantId,
  }) async {
    final cycleCloture =
        await (select(cycles)..where((c) => c.id.equals(cycleClotureId))).getSingle();
    final cycleSuivant =
        await (select(cycles)..where((c) => c.id.equals(cycleSuivantId))).getSingle();

    if (cycleCloture.status != 'cloture') {
      throw StateError('Ce cycle n\'est pas clos.');
    }
    if (cycleSuivant.status != 'en_cours') {
      throw StateError('Le cycle suivant n\'est plus en cours.');
    }
    if (cycleSuivant.groupId != cycleCloture.groupId ||
        cycleSuivant.cycleNumber != cycleCloture.cycleNumber + 1) {
      throw StateError('Ces deux cycles ne se suivent pas directement.');
    }
    if (!await cycleEstVide(cycleSuivantId)) {
      throw StateError(
        'Impossible d\'annuler : des données ont déjà été enregistrées sur le nouveau cycle.',
      );
    }

    await transaction(() async {
      await (delete(carnetsEngages)..where((c) => c.cycleId.equals(cycleSuivantId))).go();
      await (delete(cycles)..where((c) => c.id.equals(cycleSuivantId))).go();
      await (update(cycles)..where((c) => c.id.equals(cycleClotureId))).write(
        CyclesCompanion(status: const Value('en_cours'), endedAt: const Value(null)),
      );
    });
  }

  /// Crée un cycle déjà clos, pour rattacher un historique importé qui
  /// représente un cycle antérieur au cycle actuellement ouvert (skill
  /// historical-data-import — voir ROADMAP.md). Contrairement à
  /// [ouvrirCycle], les dates de début et de fin sont connues et fixées
  /// explicitement plutôt que déduites de `AppClock.now()`.
  Future<String> creerCycleHistorique({
    required String groupId,
    required int cycleNumber,
    required int partValueFcfa,
    required double interestRatePercent,
    required DateTime debut,
    required DateTime fin,
    int lateFeeFcfa = 0,
  }) async {
    final id = _uuid.v4();
    await into(cycles).insert(CyclesCompanion.insert(
      id: id,
      groupId: groupId,
      cycleNumber: cycleNumber,
      partValueFcfa: partValueFcfa,
      interestRatePercent: interestRatePercent,
      lateFeeFcfa: Value(lateFeeFcfa),
      startedAt: Value(debut),
      endedAt: Value(fin),
      status: const Value('cloture'),
    ));
    return id;
  }

  Future<List<Cycle>> cyclesDuGroupe(String groupId) {
    return (select(cycles)
          ..where((c) => c.groupId.equals(groupId))
          ..orderBy([(c) => OrderingTerm.desc(c.cycleNumber)]))
        .get();
  }

  /// Prochain numéro de cycle disponible pour ce groupe (1 s'il n'y en a
  /// encore aucun) — sert de valeur par défaut suggérée dans les
  /// formulaires de création de cycle.
  Future<int> prochainNumeroCycle(String groupId) async {
    final tousLesCycles = await cyclesDuGroupe(groupId);
    if (tousLesCycles.isEmpty) return 1;
    return tousLesCycles.map((c) => c.cycleNumber).reduce((a, b) => a > b ? a : b) + 1;
  }

  // ---------------------------------------------------------------------
  // Carnets engagés (choix par membre et par cycle, verrouillé au
  // premier paiement — voir DECISIONS.md)
  // ---------------------------------------------------------------------

  Future<CarnetsEngage?> carnetsEngagesDuMembre({
    required String memberId,
    required String cycleId,
  }) {
    return (select(carnetsEngages)
          ..where((c) => c.memberId.equals(memberId) & c.cycleId.equals(cycleId)))
        .getSingleOrNull();
  }

  Future<List<CarnetsEngage>> carnetsEngagesDuCycle(String cycleId) {
    return (select(carnetsEngages)..where((c) => c.cycleId.equals(cycleId))).get();
  }

  /// Choisit (ou modifie) le nombre de carnets d'un membre pour un cycle.
  /// Refuse si déjà verrouillé (un premier paiement a déjà été enregistré
  /// pour ce membre sur ce cycle) — le choix devient alors définitif pour
  /// le reste du cycle, conformément à la règle métier.
  Future<void> definirCarnetsEngages({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int partsCount,
  }) async {
    if (partsCount < 1 || partsCount > 5) {
      throw ArgumentError('Le nombre de carnets doit être entre 1 et 5.');
    }
    final existant = await carnetsEngagesDuMembre(memberId: memberId, cycleId: cycleId);
    if (existant != null) {
      if (existant.lockedAt != null) {
        throw StateError(
          'Carnets déjà verrouillés pour ce membre sur ce cycle — un premier '
          'paiement a déjà été enregistré.',
        );
      }
      await (update(carnetsEngages)..where((c) => c.id.equals(existant.id)))
          .write(CarnetsEngagesCompanion(partsCount: Value(partsCount)));
    } else {
      await into(carnetsEngages).insert(CarnetsEngagesCompanion.insert(
        id: _uuid.v4(),
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        partsCount: partsCount,
      ));
    }
  }

  /// Verrouille les carnets engagés d'un membre pour un cycle — appelé
  /// automatiquement par [enregistrerCotisationCash] (uniquement pour une
  /// écriture `direct`, jamais pour un import historique) dès le premier
  /// paiement, sans jamais toucher aux lignes déjà verrouillées.
  Future<void> _verrouillerCarnetsSiBesoin({
    required String cycleId,
    required String memberId,
  }) async {
    final existant = await carnetsEngagesDuMembre(memberId: memberId, cycleId: cycleId);
    if (existant != null && existant.lockedAt == null) {
      await (update(carnetsEngages)..where((c) => c.id.equals(existant.id)))
          .write(CarnetsEngagesCompanion(lockedAt: Value(AppClock.now())));
    }
  }

  // ---------------------------------------------------------------------
  // Cotisations (ajout seul)
  // ---------------------------------------------------------------------

  Future<String> enregistrerCotisationCash({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int partsCount,
    required String recordedByPhone,
    String provenance = 'direct',
    bool estApproximatif = false,
    DateTime? recordedAt,
  }) async {
    final id = _uuid.v4();
    final horodatage = recordedAt ?? AppClock.now();
    final previousHash = await _lastHashOf(cotisations.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      groupId,
      cycleId,
      memberId,
      partsCount,
      'cash',
      recordedByPhone,
      horodatage.toIso8601String(),
      provenance,
    ]);
    await into(cotisations).insert(CotisationsCompanion.insert(
      id: id,
      groupId: groupId,
      cycleId: cycleId,
      memberId: memberId,
      partsCount: partsCount,
      source: const Value('cash'),
      recordedByPhone: recordedByPhone,
      recordedAt: Value(horodatage),
      previousHash: Value(previousHash),
      hash: hash,
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
    ));
    if (provenance == 'direct') {
      await _verrouillerCarnetsSiBesoin(cycleId: cycleId, memberId: memberId);
    }
    return id;
  }

  /// Somme, en FCFA, de tout ce qu'un membre a déjà cotisé sur ce cycle
  /// (`partsCount × valeur du carnet du cycle`) — utilisé par
  /// [EcheanceCalculator.soldeDuFcfa] pour calculer le montant restant à
  /// régler.
  Future<int> totalCotiseFcfa({required String memberId, required String cycleId}) async {
    final cycle = await (select(cycles)..where((c) => c.id.equals(cycleId))).getSingle();
    final mesCotisations = await cotisationsDuMembre(memberId, cycleId);
    final totalParts = mesCotisations.fold<int>(0, (s, c) => s + c.partsCount);
    return totalParts * cycle.partValueFcfa;
  }

  Future<List<Cotisation>> cotisationsDuCycle(String cycleId) {
    return (select(cotisations)..where((c) => c.cycleId.equals(cycleId))).get();
  }

  /// Cotisations d'un seul membre sur un cycle — filtrage fait au
  /// niveau de la requête, pas en mémoire après coup, pour rester
  /// cohérent avec le principe du skill two-tier-access-model (même si
  /// ici c'est du SQLite local ; la même requête deviendra une politique
  /// row-level security côté Supabase).
  Future<List<Cotisation>> cotisationsDuMembre(String memberId, String cycleId) {
    return (select(cotisations)
          ..where((c) => c.memberId.equals(memberId) & c.cycleId.equals(cycleId)))
        .get();
  }

  // ---------------------------------------------------------------------
  // Prêts (ajout seul + confirmation par code)
  // ---------------------------------------------------------------------

  /// [confirmationCode] est nullable : null pour un prêt destiné à un
  /// membre sans téléphone (aucun code à envoyer — confirmation par
  /// signature, voir [confirmerPretParSignature]).
  Future<({String pretId, String? confirmationCode})> enregistrerPret({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int principalFcfa,
    required double interestRatePercent,
    required String initiatedByPhone,
    String? confirmationCode,
    int? dureeJours,
    String provenance = 'direct',
    bool estApproximatif = false,
    DateTime? createdAt,
  }) async {
    final id = _uuid.v4();
    final horodatage = createdAt ?? AppClock.now();
    final previousHash = await _lastHashOf(prets.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      groupId,
      cycleId,
      memberId,
      principalFcfa,
      interestRatePercent,
      initiatedByPhone,
      horodatage.toIso8601String(),
      provenance,
    ]);
    await into(prets).insert(PretsCompanion.insert(
      id: id,
      groupId: groupId,
      cycleId: cycleId,
      memberId: memberId,
      principalFcfa: principalFcfa,
      interestRatePercent: interestRatePercent,
      initiatedByPhone: initiatedByPhone,
      confirmationCode: Value(confirmationCode),
      dureeJours: Value(dureeJours),
      createdAt: Value(horodatage),
      previousHash: Value(previousHash),
      hash: hash,
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
    ));
    return (pretId: id, confirmationCode: confirmationCode);
  }

  /// Confirme un prêt si le code saisi correspond. Renvoie false sans
  /// rien écrire si le code est incorrect — un prêt non confirmé ne
  /// doit jamais apparaître comme confirmé (skill member-consent-rules).
  Future<bool> confirmerPret({
    required String pretId,
    required String codeSaisi,
    required String confirmedByPhone,
  }) async {
    final pret = await (select(prets)..where((p) => p.id.equals(pretId))).getSingle();
    if (pret.confirmationCode != codeSaisi) {
      return false;
    }
    final id = _uuid.v4();
    final confirmedAt = AppClock.now();
    final previousHash = await _lastHashOf(pretConfirmations.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      pretId,
      codeSaisi,
      confirmedByPhone,
      confirmedAt.toIso8601String(),
    ]);
    await into(pretConfirmations).insert(PretConfirmationsCompanion.insert(
      id: id,
      pretId: pretId,
      methode: const Value('code'),
      codeSaisi: Value(codeSaisi),
      confirmedByPhone: Value(confirmedByPhone),
      confirmedAt: Value(confirmedAt),
      previousHash: Value(previousHash),
      hash: hash,
    ));
    return true;
  }

  /// Confirme un prêt destiné à un membre sans téléphone, par signature
  /// capturée en personne plutôt que par code (skill member-consent-rules,
  /// "cas des membres sans smartphone"). [witnessPhone] est le numéro de
  /// l'agent présent au moment de la signature — jamais celui d'un tiers
  /// confirmant à la place du membre.
  ///
  /// Refuse explicitement si le membre emprunteur a un téléphone
  /// personnel enregistré : la signature ne doit jamais devenir un
  /// raccourci pour contourner la confirmation SMS individuelle exigée
  /// par le skill member-consent-rules quand elle est possible.
  Future<void> confirmerPretParSignature({
    required String pretId,
    required String signatureData,
    required String witnessPhone,
  }) async {
    final pret = await (select(prets)..where((p) => p.id.equals(pretId))).getSingle();
    final membre =
        await (select(members)..where((m) => m.id.equals(pret.memberId))).getSingle();
    if (membre.phoneNumber != null) {
      throw StateError(
        'Ce membre a un numéro de téléphone enregistré — la confirmation '
        'doit passer par le code SMS, pas par signature.',
      );
    }
    final id = _uuid.v4();
    final confirmedAt = AppClock.now();
    final previousHash = await _lastHashOf(pretConfirmations.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      pretId,
      signatureData,
      witnessPhone,
      confirmedAt.toIso8601String(),
    ]);
    await into(pretConfirmations).insert(PretConfirmationsCompanion.insert(
      id: id,
      pretId: pretId,
      methode: const Value('signature'),
      signatureData: Value(signatureData),
      witnessPhone: Value(witnessPhone),
      confirmedAt: Value(confirmedAt),
      previousHash: Value(previousHash),
      hash: hash,
    ));
  }

  /// Un prêt `direct` est confirmé s'il existe une ligne dans
  /// [PretConfirmations] (consentement SMS individuel du membre, skill
  /// member-consent-rules). Un prêt `importe` est considéré confirmé par
  /// construction : il n'a pu être écrit qu'après la validation
  /// collective du comité de gestion au moment de l'import (skill
  /// historical-data-import) — lui demander en plus une confirmation SMS
  /// individuelle rétroactive n'aurait pas de sens pour un historique
  /// déclaré.
  Future<bool> pretEstConfirme(String pretId) async {
    final pret = await (select(prets)..where((p) => p.id.equals(pretId))).getSingleOrNull();
    if (pret == null) return false;
    if (pret.provenance == 'importe') return true;
    final confirmation = await (select(pretConfirmations)
          ..where((c) => c.pretId.equals(pretId)))
        .getSingleOrNull();
    return confirmation != null;
  }

  Future<String> enregistrerRemboursement({
    required String pretId,
    required int montantFcfa,
    required String recordedByPhone,
    String provenance = 'direct',
    bool estApproximatif = false,
    DateTime? recordedAt,
  }) async {
    final id = _uuid.v4();
    final horodatage = recordedAt ?? AppClock.now();
    final previousHash = await _lastHashOf(pretRemboursements.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      pretId,
      montantFcfa,
      recordedByPhone,
      horodatage.toIso8601String(),
      provenance,
    ]);
    await into(pretRemboursements).insert(PretRemboursementsCompanion.insert(
      id: id,
      pretId: pretId,
      montantFcfa: montantFcfa,
      recordedByPhone: recordedByPhone,
      recordedAt: Value(horodatage),
      previousHash: Value(previousHash),
      hash: hash,
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
    ));
    return id;
  }

  Future<int> totalRembourse(String pretId) async {
    final rows = await (select(pretRemboursements)
          ..where((r) => r.pretId.equals(pretId)))
        .get();
    return rows.fold<int>(0, (sum, r) => sum + r.montantFcfa);
  }

  /// Tous les remboursements d'un prêt, utilisé par
  /// [LoanBalanceCalculator] pour recalculer le solde dû dans l'ordre
  /// chronologique (nécessaire pour l'intérêt qui se recompose).
  Future<List<PretRemboursement>> remboursementsDuPret(String pretId) {
    return (select(pretRemboursements)..where((r) => r.pretId.equals(pretId))).get();
  }

  Future<List<Pret>> pretsDuCycle(String cycleId) {
    return (select(prets)..where((p) => p.cycleId.equals(cycleId))).get();
  }

  Future<List<Pret>> pretsDuMembre(String memberId, String cycleId) {
    return (select(prets)
          ..where((p) => p.memberId.equals(memberId) & p.cycleId.equals(cycleId)))
        .get();
  }

  /// Prêts confirmés du cycle dont le remboursement (principal + intérêt)
  /// n'est pas encore complet — sert d'avertissement, non bloquant, avant
  /// la clôture du cycle (voir [cloturerCycleEtOuvrirSuivant]). Le dossier
  /// source ne précise pas de règle de report de dette d'un cycle à
  /// l'autre : l'app se contente de signaler la situation à l'agent, elle
  /// n'invente aucun mécanisme de transfert (voir DECISIONS.md).
  Future<List<PretNonSolde>> pretsNonSoldesDuCycle(String cycleId) async {
    final pretsCycle = await pretsDuCycle(cycleId);
    final resultat = <PretNonSolde>[];
    for (final pret in pretsCycle) {
      final confirme = await pretEstConfirme(pret.id);
      if (!confirme) continue;
      final interetDu = pret.principalFcfa * pret.interestRatePercent / 100;
      final du = pret.principalFcfa + interetDu;
      final rembourse = await totalRembourse(pret.id);
      final solde = (du - rembourse).round();
      if (solde > 0) {
        resultat.add(PretNonSolde(pret: pret, soldeRestantFcfa: solde));
      }
    }
    return resultat;
  }

  /// Somme des intérêts réellement perçus sur le cycle : uniquement les
  /// prêts confirmés et remboursés intégralement (principal + intérêt)
  /// avant la clôture. Voir la note dans EndOfCycleInput pour la raison
  /// de ce choix.
  Future<double> totalInteretsPercusDuCycle(String cycleId) async {
    final pretsCycle = await pretsDuCycle(cycleId);
    double total = 0;
    for (final pret in pretsCycle) {
      final confirme = await pretEstConfirme(pret.id);
      if (!confirme) continue;
      final interetDu = pret.principalFcfa * pret.interestRatePercent / 100;
      final du = pret.principalFcfa + interetDu;
      final rembourse = await totalRembourse(pret.id);
      if (rembourse >= du) {
        total += interetDu;
      }
    }
    return total;
  }

  // ---------------------------------------------------------------------
  // Amendes (ajout seul)
  // ---------------------------------------------------------------------

  Future<String> enregistrerAmende({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int montantFcfa,
    required String motif,
    required String recordedByPhone,
    String provenance = 'direct',
    bool estApproximatif = false,
    bool estAutoGeneree = false,
    DateTime? recordedAt,
  }) async {
    final id = _uuid.v4();
    final horodatage = recordedAt ?? AppClock.now();
    final previousHash = await _lastHashOf(amendes.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      groupId,
      cycleId,
      memberId,
      montantFcfa,
      motif,
      recordedByPhone,
      horodatage.toIso8601String(),
      provenance,
    ]);
    await into(amendes).insert(AmendesCompanion.insert(
      id: id,
      groupId: groupId,
      cycleId: cycleId,
      memberId: memberId,
      montantFcfa: montantFcfa,
      motif: motif,
      recordedByPhone: recordedByPhone,
      recordedAt: Value(horodatage),
      previousHash: Value(previousHash),
      hash: hash,
      provenance: Value(provenance),
      estApproximatif: Value(estApproximatif),
      estAutoGeneree: Value(estAutoGeneree),
    ));
    return id;
  }

  Future<double> totalAmendesDuCycle(String cycleId) async {
    final rows = await (select(amendes)..where((a) => a.cycleId.equals(cycleId))).get();
    return rows.fold<double>(0, (sum, a) => sum + a.montantFcfa);
  }

  Future<List<Amende>> amendesDuMembre(String memberId, String cycleId) {
    return (select(amendes)
          ..where((a) => a.memberId.equals(memberId) & a.cycleId.equals(cycleId)))
        .get();
  }

  /// Identifiants des amendes annulées parmi [amendeIds] — toujours
  /// vérifié plutôt que supposé, l'annulation ne supprime jamais la
  /// ligne d'origine (voir [AmendeAnnulations]).
  Future<Set<String>> _amendesAnnuleesParmi(Iterable<String> amendeIds) async {
    if (amendeIds.isEmpty) return {};
    final annulations = await (select(amendeAnnulations)
          ..where((a) => a.amendeId.isIn(amendeIds)))
        .get();
    return annulations.map((a) => a.amendeId).toSet();
  }

  /// Amendes auto-générées (retard) toujours actives (non annulées) pour
  /// un membre sur un cycle — sert à compter combien d'échéances
  /// manquées ont déjà été sanctionnées, pour ne jamais en appliquer une
  /// deuxième fois pour la même échéance.
  Future<List<Amende>> amendesAutoDuMembre({
    required String memberId,
    required String cycleId,
  }) async {
    final auto = await (select(amendes)
          ..where((a) =>
              a.memberId.equals(memberId) &
              a.cycleId.equals(cycleId) &
              a.estAutoGeneree.equals(true)))
        .get();
    if (auto.isEmpty) return [];
    final annulees = await _amendesAnnuleesParmi(auto.map((a) => a.id));
    return auto.where((a) => !annulees.contains(a.id)).toList();
  }

  /// Amendes auto-générées en attente de revue par l'agent : ni
  /// confirmées, ni déjà annulées. Affichées à la séance suivant leur
  /// création (skill avec-business-rules, section "Retard de
  /// cotisation").
  Future<List<({Amende amende, Member membre})>> amendesEnAttenteRevue({
    required String groupId,
    required String cycleId,
  }) async {
    final candidates = await (select(amendes)
          ..where((a) =>
              a.groupId.equals(groupId) &
              a.cycleId.equals(cycleId) &
              a.estAutoGeneree.equals(true) &
              a.confirmedAt.isNull()))
        .get();
    if (candidates.isEmpty) return [];
    final annulees = await _amendesAnnuleesParmi(candidates.map((a) => a.id));
    final resultat = <({Amende amende, Member membre})>[];
    for (final a in candidates) {
      if (annulees.contains(a.id)) continue;
      final membre = await (select(members)..where((m) => m.id.equals(a.memberId))).getSingle();
      resultat.add((amende: a, membre: membre));
    }
    return resultat;
  }

  /// L'agent confirme une amende auto-générée telle quelle — ne
  /// réapparaîtra plus dans [amendesEnAttenteRevue].
  Future<void> confirmerAmende(String amendeId) async {
    await (update(amendes)..where((a) => a.id.equals(amendeId)))
        .write(AmendesCompanion(confirmedAt: Value(AppClock.now())));
  }

  /// Annule une amende (erreur d'enregistrement) — jamais une
  /// suppression ni une modification de la ligne d'origine, toujours une
  /// nouvelle ligne qui la référence (voir [AmendeAnnulations]).
  Future<void> annulerAmende({
    required String amendeId,
    required String raison,
    required String annuleParPhone,
  }) async {
    final id = _uuid.v4();
    final annuleAt = AppClock.now();
    final previousHash = await _lastHashOf(amendeAnnulations.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      amendeId,
      raison,
      annuleParPhone,
      annuleAt.toIso8601String(),
    ]);
    await into(amendeAnnulations).insert(AmendeAnnulationsCompanion.insert(
      id: id,
      amendeId: amendeId,
      raison: raison,
      annuleParPhone: annuleParPhone,
      annuleAt: Value(annuleAt),
      previousHash: Value(previousHash),
      hash: hash,
    ));
  }

  /// Corrige une amende auto-générée par erreur : l'annule et enregistre
  /// dans la foulée la cotisation du membre qui avait en réalité été
  /// payée mais pas saisie — à la vraie date du paiement, pas
  /// aujourd'hui (voir DECISIONS.md). Les deux écritures sont atomiques.
  Future<void> corrigerAmendeErreur({
    required String amendeId,
    required String raison,
    required String annuleParPhone,
    required String groupId,
    required String cycleId,
    required String memberId,
    required int partsCount,
    required DateTime dateReelle,
  }) {
    return transaction(() async {
      await annulerAmende(amendeId: amendeId, raison: raison, annuleParPhone: annuleParPhone);
      await enregistrerCotisationCash(
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        partsCount: partsCount,
        recordedByPhone: annuleParPhone,
        recordedAt: dateReelle,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Retard de cotisation (skill avec-business-rules, section "Retard de
  // cotisation") — une période "hebdomadaire"/"bimensuelle"/"mensuelle" est
  // calculée à partir de la fréquence des réunions du groupe et de la date
  // de début du cycle, jamais stockée séparément (pas de table réunions
  // pour cette étape). Un membre est en retard pour la période en cours
  // s'il n'a aucune cotisation ET aucune amende déjà enregistrée depuis le
  // début de cette période — la deuxième condition évite de le signaler à
  // nouveau une fois l'amende déjà appliquée.
  // ---------------------------------------------------------------------

  /// Nombre de jours d'une période selon la fréquence des réunions du
  /// groupe. Approximation volontaire pour "mensuelle" (30 jours plutôt
  /// qu'un vrai calcul de mois calendaire) — suffisant pour détecter un
  /// retard, pas pour facturer un loyer.
  static int _joursParPeriode(String meetingFrequency) {
    switch (meetingFrequency) {
      case 'hebdomadaire':
        return 7;
      case 'bimensuelle':
        return 15;
      case 'mensuelle':
      default:
        return 30;
    }
  }

  /// Début de la période en cours pour un cycle, ou null si le cycle n'a
  /// pas encore commencé (ne devrait pas arriver en usage normal).
  static DateTime? _debutPeriodeEnCours({
    required DateTime cycleStartedAt,
    required String meetingFrequency,
    required DateTime maintenant,
  }) {
    final joursDepuisDebut = maintenant.difference(cycleStartedAt).inDays;
    if (joursDepuisDebut < 0) return null;
    final intervalle = _joursParPeriode(meetingFrequency);
    final periodesEcoulees = joursDepuisDebut ~/ intervalle;
    return cycleStartedAt.add(Duration(days: periodesEcoulees * intervalle));
  }

  /// Membres du groupe n'ayant ni cotisé ni déjà été mis à l'amende
  /// depuis le début de la période en cours. Vide pour un cycle clos —
  /// relancer un membre pour un cycle déjà terminé n'a pas de sens.
  Future<List<MembreEnRetard>> membresEnRetard(String groupId, String cycleId) async {
    final cycle = await (select(cycles)..where((c) => c.id.equals(cycleId))).getSingle();
    if (cycle.status != 'en_cours') return [];

    final groupe = await (select(groups)..where((g) => g.id.equals(groupId))).getSingle();
    final periodeDebut = _debutPeriodeEnCours(
      cycleStartedAt: cycle.startedAt,
      meetingFrequency: groupe.meetingFrequency,
      maintenant: AppClock.now(),
    );
    if (periodeDebut == null) return [];

    final membres = await membresDuGroupe(groupId);
    final enRetard = <MembreEnRetard>[];
    for (final membre in membres) {
      final cotisations = await cotisationsDuMembre(membre.id, cycleId);
      final aCotiseSurLaPeriode =
          cotisations.any((c) => !c.recordedAt.isBefore(periodeDebut));
      if (aCotiseSurLaPeriode) continue;

      final amendesMembre = await amendesDuMembre(membre.id, cycleId);
      final dejaAmendeSurLaPeriode =
          amendesMembre.any((a) => !a.recordedAt.isBefore(periodeDebut));
      if (dejaAmendeSurLaPeriode) continue;

      enRetard.add(MembreEnRetard(membre: membre, periodeDebut: periodeDebut));
    }
    return enRetard;
  }

  // ---------------------------------------------------------------------
  // Fonds de solidarité (ajout seul, jamais lu par le calcul de fin de cycle)
  // ---------------------------------------------------------------------

  Future<String> enregistrerContributionFondsSolidarite({
    required String groupId,
    required String cycleId,
    String? memberId,
    required int montantFcfa,
    required String motif,
    required String recordedByPhone,
    String provenance = 'direct',
    bool estApproximatif = false,
    DateTime? recordedAt,
  }) async {
    final id = _uuid.v4();
    final horodatage = recordedAt ?? AppClock.now();
    final previousHash = await _lastHashOf(fondsSolidariteContributions.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      groupId,
      cycleId,
      memberId,
      montantFcfa,
      motif,
      recordedByPhone,
      horodatage.toIso8601String(),
      provenance,
    ]);
    await into(fondsSolidariteContributions).insert(
      FondsSolidariteContributionsCompanion.insert(
        id: id,
        groupId: groupId,
        cycleId: cycleId,
        memberId: Value(memberId),
        montantFcfa: montantFcfa,
        motif: motif,
        recordedByPhone: recordedByPhone,
        recordedAt: Value(horodatage),
        previousHash: Value(previousHash),
        hash: hash,
        provenance: Value(provenance),
        estApproximatif: Value(estApproximatif),
      ),
    );
    return id;
  }

  Future<int> totalFondsSolidarite(String groupId) async {
    final rows = await (select(fondsSolidariteContributions)
          ..where((f) => f.groupId.equals(groupId)))
        .get();
    return rows.fold<int>(0, (sum, f) => sum + f.montantFcfa);
  }

  // ---------------------------------------------------------------------
  // Affectation du rôle agent (ajout seul)
  // ---------------------------------------------------------------------

  Future<String> affecterRole({
    required String groupId,
    String? memberId,
    required String phoneNumber,
    required String role,
  }) async {
    final id = _uuid.v4();
    final assignedAt = AppClock.now();
    final previousHash = await _lastHashOf(agentAssignments.tableName);
    final hash = HashChain.compute(previousHash: previousHash, fields: [
      id,
      groupId,
      memberId,
      phoneNumber,
      role,
      assignedAt.toIso8601String(),
    ]);
    await into(agentAssignments).insert(AgentAssignmentsCompanion.insert(
      id: id,
      groupId: groupId,
      memberId: Value(memberId),
      phoneNumber: phoneNumber,
      role: role,
      assignedAt: Value(assignedAt),
      previousHash: Value(previousHash),
      hash: hash,
    ));
    return id;
  }
}

class MembreEnRetard {
  final Member membre;
  final DateTime periodeDebut;

  const MembreEnRetard({required this.membre, required this.periodeDebut});
}

/// Un prêt confirmé dont le remboursement n'est pas complet au moment où
/// l'agent envisage de clôturer le cycle — voir [pretsNonSoldesDuCycle].
class PretNonSolde {
  final Pret pret;
  final int soldeRestantFcfa;

  const PretNonSolde({required this.pret, required this.soldeRestantFcfa});
}

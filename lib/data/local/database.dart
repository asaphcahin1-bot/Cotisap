import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_clock.dart';
import '../../domain/calculators/echeance_calculator.dart';
import '../../domain/calculators/loan_balance_calculator.dart';
import '../../domain/calculators/loan_rate_resolver.dart';
import '../../domain/calculators/loan_window_calculator.dart';
import '../../domain/calculators/end_of_cycle_calculator.dart';
import '../../domain/calculators/amende_reduction_calculator.dart';
import '../../domain/calculators/membership_closure_calculator.dart';
import '../../domain/calculators/collective_loan_rationing_calculator.dart';
import 'hash_chain.dart';
import 'tables/groups_table.dart';
import 'tables/members_table.dart';
import 'tables/agent_assignments_table.dart';
import 'tables/cycles_table.dart';
import 'tables/cotisations_table.dart';
import 'tables/carnets_engages_table.dart';
import 'tables/prets_table.dart';
import 'tables/pret_demandes_table.dart';
import 'tables/amendes_table.dart';
import 'tables/fonds_solidarite_table.dart';
import 'tables/echeances_table.dart';
import 'tables/partage_deductions_table.dart';
import 'tables/seances_cotisation_table.dart';
import 'tables/motifs_amende_table.dart';
import 'tables/partage_paiement_confirmations_table.dart';
import 'tables/carnets_table.dart';
import 'tables/presence_anticipee_table.dart';

part 'database.g.dart';

const _uuid = Uuid();

@DriftDatabase(
  tables: [
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
    PretDemandes,
    PretDemandeRefus,
    Amendes,
    AmendeAnnulations,
    AmendePaiements,
    FondsSolidariteContributions,
    CotisationsExceptionnelles,
    Echeances,
    PartageDeductions,
    SeancesCotisation,
    MotifsAmende,
    PartagePaiementConfirmations,
    Carnets,
    PresenceAnticipee,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 22;

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
      if (from < 6) {
        // Registre d'échéances (payé/non payé par membre et par
        // date — voir DECISIONS.md, "Historique des cotisations") et
        // trace des déductions de dette au partage de fin de cycle.
        await m.createTable(echeances);
        await m.createTable(partageDeductions);
      }
      if (from < 7) {
        // Refonte carnet/part (voir DECISIONS.md, "Parts libres par
        // cotisation, minimum 1") : un carnet n'est plus un
        // multiplicateur fixe (1 à 5) mais une entité indépendante (1
        // ou 2 par membre, jamais davantage), et le nombre de parts
        // déposées à chaque cotisation devient libre (1 à 5, minimum
        // 1) plutôt que figé pour tout le cycle. CarnetsEngages et
        // Echeances sont recréées plutôt que migrées colonne par
        // colonne : leurs anciennes valeurs (carnetsEngages comme
        // multiplicateur) ne correspondent à rien dans le nouveau
        // modèle — recréation acceptée à ce stade (aucun groupe réel
        // en production, voir ROADMAP.md).
        await m.deleteTable('carnets_engages');
        await m.createTable(carnetsEngages);
        await m.deleteTable('echeances');
        await m.createTable(echeances);
        await m.addColumn(cotisations, cotisations.carnetNumero);
        await m.addColumn(cycles, cycles.inscriptionsFermeesAt);
        await m.createTable(seancesCotisation);
      }
      if (from < 8) {
        // Suppression du rattrapage (voir DECISIONS.md, "Amende
        // seule, jamais de rattrapage") : une échéance porte
        // désormais un nombre de parts explicite plutôt qu'un
        // simple montant, un carnet pouvant recevoir 1 à 5 parts en
        // une seule journée.
        await m.addColumn(echeances, echeances.partsPayees);
      }
      if (from < 9) {
        // Le plafond cumulatif journalier doit se baser sur la date
        // d'échéance visée, pas sur l'horodatage réel/simulé de la
        // saisie (voir DECISIONS.md, "Le plafond journalier se base
        // sur l'échéance, pas sur l'heure de saisie").
        await m.addColumn(cotisations, cotisations.echeanceDate);
      }
      if (from < 10) {
        // Catalogue de motifs d'amende configurables par groupe (voir
        // DECISIONS.md, "Catalogue de motifs d'amende") — remplace la
        // saisie entièrement libre (motif + montant retapés à chaque
        // fois) par un choix rapide, sans rien changer aux amendes déjà
        // enregistrées (aucune référence vivante entre les deux).
        await m.createTable(motifsAmende);
      }
      if (from < 11) {
        // Distingue "revue" (l'agent confirme que l'absence est réelle,
        // sans impliquer de paiement) de "réglée" (cash ou déduction à
        // la clôture) — voir DECISIONS.md, "Écran Cotisations moins
        // chargé".
        await m.addColumn(amendes, amendes.reviewedAt);
      }
      if (from < 12) {
        // Confirmation par membre du paiement de fin de cycle —
        // condition de clôture (voir DECISIONS.md, "Clôture de cycle
        // conditionnée au paiement de tous les membres").
        await m.createTable(partagePaiementConfirmations);
      }
      if (from < 13) {
        // Numéro de série physique persistant par carnet (voir
        // DECISIONS.md, "Numéro de série physique par carnet").
        await m.createTable(carnets);
      }
      if (from < 14) {
        // Motifs d'amende prédéfinis : libellé explicatif + code système
        // (voir DECISIONS.md, "Motifs d'amende prédéfinis"). Les 3
        // motifs système ne sont créés automatiquement qu'à la création
        // d'un nouveau groupe — un groupe existant migré vers cette
        // version n'en reçoit aucun rétroactivement (pas de valeurs à
        // deviner pour ses montants).
        await m.addColumn(motifsAmende, motifsAmende.description);
        await m.addColumn(motifsAmende, motifsAmende.codeSysteme);
      }
      if (from < 15) {
        // Une amende devient propre à un carnet (voir DECISIONS.md,
        // "Amende par carnet, pas par membre") : carnetNumero (défaut
        // 1, rétrocompatible), date d'échéance concernée, copie figée
        // du code système du motif.
        await m.addColumn(amendes, amendes.carnetNumero);
        await m.addColumn(amendes, amendes.echeanceDate);
        await m.addColumn(amendes, amendes.motifCodeSysteme);
      }
      if (from < 16) {
        // Paiement partiel d'une amende (voir DECISIONS.md, "Paiement
        // partiel d'une amende") — même principe que PretRemboursements.
        await m.createTable(amendePaiements);
      }
      if (from < 17) {
        // Fonds de solidarité obligatoire (voir DECISIONS.md) : montant
        // par carnet, dû à chaque réunion. 0 par défaut pour un groupe
        // migré — comportement historique (contributions libres, aucun
        // solde dû suivi) préservé tel quel.
        await m.addColumn(groups, groups.montantSolidariteObligatoireFcfa);
      }
      if (from < 18) {
        // Cotisations exceptionnelles (voir DECISIONS.md) : événement
        // déclaré une fois, s'applique à tous les membres déjà
        // présents, réglable jusqu'à une date limite propre.
        await m.createTable(cotisationsExceptionnelles);
        await m.addColumn(
          fondsSolidariteContributions,
          fondsSolidariteContributions.cotisationExceptionnelleId,
        );
      }
      if (from < 19) {
        // Dette de prêt "au rouge" (voir DECISIONS.md) : montant fixe
        // pour en sortir, et traçabilité du prêt qui en remplace un
        // autre (sortie du rouge ou reconduction au cycle suivant).
        await m.addColumn(groups, groups.montantAmendeSortieRougeFcfa);
        await m.addColumn(prets, prets.renouvelePretId);
        await m.addColumn(prets, prets.estAuRougeDesLeDepart);
      }
      if (from < 20) {
        // Rationnement collectif des crédits (voir DECISIONS.md) :
        // demandes de prêt en attente, négociées collectivement si
        // leur total dépasse la caisse disponible.
        await m.createTable(pretDemandes);
        await m.createTable(pretDemandeRefus);
        await m.addColumn(prets, prets.demandeId);
      }
      if (from < 21) {
        // Écran "Séance du jour" (voir RETOURS_TERRAIN.md, point 6) :
        // présence anticipée par carnet, saisie pendant la journée,
        // relue comme valeur par défaut à la clôture.
        await m.createTable(presenceAnticipee);
      }
      if (from < 22) {
        // Déduction automatique immédiate d'une cotisation exceptionnelle
        // échue (voir RETOURS_TERRAIN.md, point 25.4, et DECISIONS.md) :
        // distingue une ligne écrite automatiquement (aucun argent réel)
        // d'un vrai versement cash.
        await m.addColumn(
          fondsSolidariteContributions,
          fondsSolidariteContributions.estDeductionAutomatique,
        );
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
  /// [montantAmendeAbsenceFcfa]/[montantAmendePartImpayeeFcfa]/
  /// [montantAmendePayeParTiersFcfa] : montants des 3 motifs d'amende
  /// système, créés automatiquement dans le catalogue du groupe (voir
  /// DECISIONS.md, "Motifs d'amende prédéfinis") — 0 par défaut
  /// (motif présent mais montant à ajuster plus tard via
  /// [modifierMotifAmende], comme [Cycles.lateFeeFcfa]).
  Future<String> creerGroupe({
    required String name,
    required int cycleDurationMonths,
    required String meetingFrequency,
    int? paymentDayOfWeek,
    int? paymentDayOfMonth1,
    int? paymentDayOfMonth2,
    int montantAmendeAbsenceFcfa = 0,
    int montantAmendePartImpayeeFcfa = 0,
    int montantAmendePayeParTiersFcfa = 0,
    int montantSolidariteObligatoireFcfa = 0,
    int montantAmendeSortieRougeFcfa = 0,
  }) async {
    final id = _uuid.v4();
    await into(groups).insert(
      GroupsCompanion.insert(
        id: id,
        name: name,
        cycleDurationMonths: Value(cycleDurationMonths),
        meetingFrequency: Value(meetingFrequency),
        paymentDayOfWeek: Value(paymentDayOfWeek),
        paymentDayOfMonth1: Value(paymentDayOfMonth1),
        paymentDayOfMonth2: Value(paymentDayOfMonth2),
        montantSolidariteObligatoireFcfa: Value(montantSolidariteObligatoireFcfa),
        montantAmendeSortieRougeFcfa: Value(montantAmendeSortieRougeFcfa),
      ),
    );
    // 3 motifs système, toujours présents dès la création du groupe —
    // voir DECISIONS.md, "Motifs d'amende prédéfinis".
    await _creerMotifsSysteme(
      groupId: id,
      montantAbsenceFcfa: montantAmendeAbsenceFcfa,
      montantPartImpayeeFcfa: montantAmendePartImpayeeFcfa,
      montantPayeParTiersFcfa: montantAmendePayeParTiersFcfa,
    );
    return id;
  }

  static const codeSystemeAbsence = 'absence';
  static const codeSystemePartImpayee = 'part_impayee';
  static const codeSystemePayeParTiers = 'paye_par_tiers';

  Future<void> _creerMotifsSysteme({
    required String groupId,
    required int montantAbsenceFcfa,
    required int montantPartImpayeeFcfa,
    required int montantPayeParTiersFcfa,
  }) async {
    final motifs = [
      (
        code: codeSystemeAbsence,
        libelle: 'Absence',
        description: 'Le membre n\'est pas présent à la réunion.',
        montant: montantAbsenceFcfa,
      ),
      (
        code: codeSystemePartImpayee,
        libelle: 'Part impayée',
        description: 'Le membre n\'a pas acheté de parts aujourd\'hui.',
        montant: montantPartImpayeeFcfa,
      ),
      (
        code: codeSystemePayeParTiers,
        libelle: 'Payé par un tiers',
        description:
            'Le membre est absent, mais quelqu\'un d\'autre a apporté son '
            'paiement à sa place.',
        montant: montantPayeParTiersFcfa,
      ),
    ];
    for (final m in motifs) {
      await into(motifsAmende).insert(
        MotifsAmendeCompanion.insert(
          id: _uuid.v4(),
          groupId: groupId,
          libelle: m.libelle,
          montantFcfa: m.montant,
          description: Value(m.description),
          codeSysteme: Value(m.code),
        ),
      );
    }
  }

  /// Vrai si au moins une cotisation (cash ou importée) existe sur ce
  /// cycle — sert de verrou pour [modifierGroupeEtCycle] : une fois la
  /// première cotisation enregistrée, les paramètres fondateurs du
  /// groupe/cycle ne doivent plus changer rétroactivement (des calculs
  /// en dépendent déjà).
  Future<bool> cycleADesCotisations(String cycleId) async {
    final rows = await (select(
      cotisations,
    )..where((c) => c.cycleId.equals(cycleId))).get();
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
          loanDurationDays: Value(loanDurationDays),
        ),
      );
    });
  }

  /// Vrai si [fullName] (comparaison insensible à la casse/aux espaces)
  /// ou [phoneNumber] est déjà utilisé par un autre membre **actif du
  /// même groupe** — voir DECISIONS.md, "Un membre = un seul carnet" :
  /// empêche de contourner la règle en réinscrivant la même identité
  /// pour obtenir un deuxième carnet. Jamais un contrôle global — un
  /// membre peut appartenir à plusieurs groupes avec le même nom et le
  /// même numéro (confirmé par le fondateur).
  Future<bool> nomOuTelephoneDejaUtiliseDansLeGroupe({
    required String groupId,
    required String fullName,
    String? phoneNumber,
  }) async {
    final membresDuGroupe = await (select(
      members,
    )..where((m) => m.groupId.equals(groupId) & m.active.equals(true))).get();
    final nomNormalise = fullName.trim().toLowerCase();
    for (final m in membresDuGroupe) {
      if (m.fullName.trim().toLowerCase() == nomNormalise) return true;
      if (phoneNumber != null &&
          phoneNumber.isNotEmpty &&
          m.phoneNumber == phoneNumber) {
        return true;
      }
    }
    return false;
  }

  /// [phoneNumber] est nullable : un membre sans aucun téléphone
  /// personnel peut être ajouté (voir [Members]). Conséquences : ce
  /// membre n'apparaîtra jamais dans [membresParTelephone] (donc jamais
  /// d'accès "membre" en lecture seule), et ses prêts devront être
  /// confirmés par signature ([confirmerPretParSignature]) plutôt que
  /// par code.
  ///
  /// Refuse dès qu'il reste [MembershipClosureCalculator.reunionsAvantFermeture]
  /// réunions ou moins avant la fin prévue du cycle en cours — un
  /// membre peut sinon rejoindre **à n'importe quel moment du cycle**
  /// (voir DECISIONS.md, "Inscription de nouveaux membres : sans
  /// limite, sauf fin de cycle" — remplace l'ancienne règle "fermé dès
  /// la clôture de la première journée de cotisation", abandonnée par
  /// le fondateur).
  ///
  /// [joinedAt] passe par [AppClock.now()] par défaut plutôt que par
  /// l'horodatage SQL brut (`currentDateAndTime`) — nécessaire depuis que
  /// cette date sert d'ancrage aux échéances d'un membre (voir
  /// DECISIONS.md, "Un membre ajouté en cours de cycle ne doit rien
  /// avant son entrée") : elle doit pouvoir être simulée en mode debug
  /// comme le reste de la logique sensible au temps. Sert aussi de
  /// base au calcul des réunions restantes ci-dessus.
  Future<String> ajouterMembre({
    required String groupId,
    required String fullName,
    String? phoneNumber,
    DateTime? joinedAt,
  }) async {
    // Un membre = un seul carnet, toujours (voir DECISIONS.md) : le
    // même nom ou le même numéro de téléphone ne peut pas servir à
    // obtenir un deuxième carnet dans ce groupe — jamais un contrôle
    // global, un membre peut appartenir à plusieurs groupes avec la
    // même identité.
    if (await nomOuTelephoneDejaUtiliseDansLeGroupe(
      groupId: groupId,
      fullName: fullName,
      phoneNumber: phoneNumber,
    )) {
      throw StateError(
        'Ce nom ou ce numéro de téléphone est déjà utilisé par un membre '
        'de ce groupe — un membre ne peut avoir qu\'un seul carnet.',
      );
    }
    final cycle = await cycleEnCours(groupId);
    final maintenant = joinedAt ?? AppClock.now();
    if (cycle != null) {
      final groupe = await (select(
        groups,
      )..where((g) => g.id.equals(groupId))).getSingle();
      final ferme = const MembershipClosureCalculator().inscriptionsFermees(
        debutCycle: cycle.startedAt,
        finDeCycle: finDeCyclePrevue(cycle, groupe),
        meetingFrequency: groupe.meetingFrequency,
        paymentDayOfWeek: groupe.paymentDayOfWeek,
        paymentDayOfMonth1: groupe.paymentDayOfMonth1,
        paymentDayOfMonth2: groupe.paymentDayOfMonth2,
        maintenant: maintenant,
      );
      if (ferme) {
        throw StateError(
          'Impossible d\'ajouter un membre : les inscriptions sont closes — '
          'moins de ${MembershipClosureCalculator.reunionsAvantFermeture} '
          'réunions avant la fin prévue du cycle.',
        );
      }
    }
    final id = _uuid.v4();
    await into(members).insert(
      MembersCompanion.insert(
        id: id,
        groupId: groupId,
        fullName: fullName,
        phoneNumber: Value(phoneNumber),
        joinedAt: Value(maintenant),
      ),
    );
    return id;
  }

  /// Tous les enregistrements membre correspondant à un numéro de
  /// téléphone, toutes groupes confondus — une même personne peut être
  /// membre de plusieurs AVEC. Base du mode "membre" en lecture seule
  /// (skill two-tier-access-model) : l'identification se fait par
  /// numéro de téléphone, jamais par sélection manuelle d'un compte.
  Future<List<Member>> membresParTelephone(String phoneNumber) {
    return (select(members)..where(
          (m) => m.phoneNumber.equals(phoneNumber) & m.active.equals(true),
        ))
        .get();
  }

  Future<List<Member>> membresDuGroupe(String groupId) {
    return (select(
      members,
    )..where((m) => m.groupId.equals(groupId) & m.active.equals(true))).get();
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
    await into(cycles).insert(
      CyclesCompanion.insert(
        id: id,
        groupId: groupId,
        cycleNumber: cycleNumber,
        partValueFcfa: partValueFcfa,
        interestRatePercent: interestRatePercent,
        lateFeeFcfa: Value(lateFeeFcfa),
        loanDurationDays: Value(loanDurationDays),
        startedAt: startedAt != null ? Value(startedAt) : const Value.absent(),
      ),
    );
    return id;
  }

  Future<Cycle?> cycleEnCours(String groupId) {
    return (select(cycles)
          ..where(
            (c) => c.groupId.equals(groupId) & c.status.equals('en_cours'),
          )
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
    String recordedByPhone = 'inconnu',
  }) {
    return transaction(() async {
      final cycleActuel = await (select(
        cycles,
      )..where((c) => c.id.equals(cycleIdACloturer))).getSingle();
      if (cycleActuel.status != 'en_cours') {
        throw StateError(
          'Ce cycle est déjà clos — impossible de le clôturer une seconde fois.',
        );
      }

      // Condition de clôture (voir DECISIONS.md, "Fonds de solidarité
      // obligatoire" : "tout doit être soldé avant le partage de fin de
      // cycle") — indépendante de la condition "confirmé payé"
      // ci-dessous, vérifiée même pour un membre sans aucune part sur
      // ce cycle.
      final soldesSolidarite = await soldesSolidariteObligatoireNonSoldesDuCycle(
        groupId: groupId,
        cycleId: cycleIdACloturer,
      );
      if (soldesSolidarite.isNotEmpty) {
        throw StateError(
          'Impossible de clôturer : ${soldesSolidarite.length} membre(s) '
          'n\'ont pas soldé leur fonds de solidarité obligatoire.',
        );
      }

      // Déduction des dettes au partage (skill avec-business-rules — voir
      // DECISIONS.md, "Déduction des dettes au partage") : figée
      // maintenant, une fois pour toutes, avant que le cycle ne devienne
      // en lecture seule. cf. [detteMembreFcfa] pour ce qui compte comme
      // dette (prêt uniquement, plus les amendes — voir plus bas).
      //
      // Formule "caisse disponible" (voir DECISIONS.md, "Nouvelle formule
      // de partage" et "Les amendes ne sont plus une dette") :
      // [preparerPartageCycle] réduit déjà la cotisation brute de chaque
      // membre de ses amendes non soldées (voir [AmendeReductionCalculator])
      // avant que [EndOfCycleCalculator] n'applique le plafond "dette de
      // prêt" — les deux réductions se composent, jamais l'inverse.
      final prepared = await preparerPartageCycle(
        groupId: groupId,
        cycleId: cycleIdACloturer,
      );

      // Condition de clôture (voir DECISIONS.md, "Clôture de cycle
      // conditionnée au paiement de tous les membres") : chaque membre
      // ayant des parts sur ce cycle doit avoir été explicitement
      // confirmé comme payé. Vérifié ici aussi (pas seulement le bouton
      // désactivé côté écran) — même principe que les autres invariants
      // de cette méthode.
      if (prepared.membres.isNotEmpty) {
        final confirmes = await membresConfirmesPayesDuCycle(cycleIdACloturer);
        final nonConfirmes = prepared.membres
            .map((m) => m.memberId)
            .where((id) => !confirmes.contains(id))
            .toSet();
        if (nonConfirmes.isNotEmpty) {
          throw StateError(
            'Impossible de clôturer : ${nonConfirmes.length} membre(s) pas '
            'encore confirmé(s) comme payé(s).',
          );
        }
      }

      if (prepared.membres.isNotEmpty) {
        final totalInterets = await totalInteretsPercusDuCycle(
          cycleIdACloturer,
        );
        // Amendes réglées cash (déjà confirmées avant la clôture) + amendes
        // récupérées par déduction de cotisation à l'instant de la
        // clôture — les deux rejoignent la caisse de façon identique (voir
        // DECISIONS.md, "Les amendes ne sont plus une dette").
        final totalAmendesRegleesCash = await totalAmendesRegleesDuCycle(
          cycleIdACloturer,
        );
        final totalAmendesDeduites = prepared.amendesADeduireParMembre.values
            .fold<int>(0, (a, b) => a + b);
        final totalDettesEnCours = await totalPrincipalNonRembourseDuCycle(
          cycleIdACloturer,
        );

        final resultat = const EndOfCycleCalculator().calculer(
          EndOfCycleInput(
            membres: prepared.membres,
            cotisationsTotalesGroupeFcfa:
                prepared.cotisationsEffectivesTotalesFcfa,
            amendesRegleesFcfa: totalAmendesRegleesCash + totalAmendesDeduites,
            interetsPercusFcfa: totalInterets,
            dettesEnCoursGroupeFcfa: totalDettesEnCours,
          ),
        );

        for (final r in resultat.resultatsParMembre) {
          final id = _uuid.v4();
          final recordedAt = AppClock.now();
          final previousHash = await _lastHashOf(partageDeductions.tableName);
          final hash = HashChain.compute(
            previousHash: previousHash,
            fields: [
              id,
              groupId,
              cycleIdACloturer,
              r.memberId,
              r.montantBrutFcfa,
              r.detteFcfa,
              r.montantDeduitFcfa,
              r.montantNetFcfa,
              r.pertAvecFcfa,
              recordedByPhone,
              recordedAt.toIso8601String(),
            ],
          );
          await into(partageDeductions).insert(
            PartageDeductionsCompanion.insert(
              id: id,
              groupId: groupId,
              cycleId: cycleIdACloturer,
              memberId: r.memberId,
              montantBrutFcfa: r.montantBrutFcfa,
              detteFcfa: r.detteFcfa,
              montantDeduitFcfa: r.montantDeduitFcfa,
              montantNetFcfa: r.montantNetFcfa,
              pertAvecFcfa: Value(r.pertAvecFcfa),
              recordedByPhone: recordedByPhone,
              recordedAt: Value(recordedAt),
              previousHash: Value(previousHash),
              hash: hash,
            ),
          );

          // Une amende non soldée entrant dans cette dette est désormais
          // réglée — récupérée par déduction, ou perdue pour l'AVEC : dans
          // les deux cas, elle ne doit plus jamais être recomptée (voir
          // DECISIONS.md, "Déduction des dettes au partage"). Le solde de
          // prêt n'est volontairement jamais touché ici : un prêt reste
          // remboursable après la clôture (voir [pretsNonSoldesDuCycle]).
          final amendesASolder = await amendesNonSoldeesDuMembre(
            memberId: r.memberId,
            cycleId: cycleIdACloturer,
          );
          for (final amende in amendesASolder) {
            await confirmerAmende(amende.id);
          }
        }

        // Cotisations exceptionnelles non payées à temps : déduites
        // automatiquement (voir DECISIONS.md, "Cotisations
        // exceptionnelles") — enregistrées comme une contribution au
        // fonds de solidarité comme n'importe quel versement, jamais
        // ajoutées à la caisse principale (déjà exclu du calcul
        // ci-dessus, voir [preparerPartageCycle]).
        for (final d in prepared.cotisationsExceptionnellesADeduire) {
          // Peut avoir déjà été écrite avant la clôture (voir
          // [appliquerDeductionsCotisationsExceptionnellesEchues],
          // RETOURS_TERRAIN.md point 25.4) — ne complète que ce qui
          // manque encore, jamais une deuxième fois le même montant.
          final dejaDeduit = await _totalDejaDeduitAutomatiquement(
            cotisationExceptionnelleId: d.cotisationExceptionnelleId,
            memberId: d.memberId,
          );
          final aEcrire = d.montantFcfa - dejaDeduit;
          if (aEcrire <= 0) continue;
          await enregistrerContributionFondsSolidarite(
            groupId: groupId,
            cycleId: cycleIdACloturer,
            memberId: d.memberId,
            montantFcfa: aEcrire,
            motif: 'Cotisation exceptionnelle non payée à temps — '
                'déduite automatiquement à la clôture',
            recordedByPhone: recordedByPhone,
            cotisationExceptionnelleId: d.cotisationExceptionnelleId,
            estDeductionAutomatique: true,
          );
        }
      }

      await (update(cycles)..where((c) => c.id.equals(cycleIdACloturer))).write(
        CyclesCompanion(
          status: const Value('cloture'),
          endedAt: Value(AppClock.now()),
        ),
      );
      final id = _uuid.v4();
      await into(cycles).insert(
        CyclesCompanion.insert(
          id: id,
          groupId: groupId,
          cycleNumber: cycleActuel.cycleNumber + 1,
          partValueFcfa: nouveauPartValueFcfa,
          interestRatePercent: nouveauInterestRatePercent,
          lateFeeFcfa: Value(nouveauLateFeeFcfa),
          loanDurationDays: Value(nouveauLoanDurationDays),
        ),
      );
      return id;
    });
  }

  /// Vrai si aucune donnée n'a encore été enregistrée sur ce cycle
  /// (cotisation, prêt, amende, contribution au fonds de solidarité) —
  /// condition d'éligibilité pour [annulerClotureCycle].
  Future<bool> cycleEstVide(String cycleId) async {
    if ((await cotisationsDuCycle(cycleId)).isNotEmpty) return false;
    if ((await pretsDuCycle(cycleId)).isNotEmpty) return false;
    final amendesRows = await (select(
      amendes,
    )..where((a) => a.cycleId.equals(cycleId))).get();
    if (amendesRows.isNotEmpty) return false;
    final fondsRows = await (select(
      fondsSolidariteContributions,
    )..where((f) => f.cycleId.equals(cycleId))).get();
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
    final cycleCloture = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleClotureId))).getSingle();
    final cycleSuivant = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleSuivantId))).getSingle();

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
      await (delete(
        carnetsEngages,
      )..where((c) => c.cycleId.equals(cycleSuivantId))).go();
      await (delete(cycles)..where((c) => c.id.equals(cycleSuivantId))).go();
      await (update(cycles)..where((c) => c.id.equals(cycleClotureId))).write(
        CyclesCompanion(
          status: const Value('en_cours'),
          endedAt: const Value(null),
        ),
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
    await into(cycles).insert(
      CyclesCompanion.insert(
        id: id,
        groupId: groupId,
        cycleNumber: cycleNumber,
        partValueFcfa: partValueFcfa,
        interestRatePercent: interestRatePercent,
        lateFeeFcfa: Value(lateFeeFcfa),
        startedAt: Value(debut),
        endedAt: Value(fin),
        status: const Value('cloture'),
      ),
    );
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
    return tousLesCycles
            .map((c) => c.cycleNumber)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  // ---------------------------------------------------------------------
  // Carnets (combien un membre en détient — 1 ou 2, jamais plus,
  // verrouillé au premier paiement — voir DECISIONS.md)
  // ---------------------------------------------------------------------

  Future<CarnetsEngage?> carnetsEngagesDuMembre({
    required String memberId,
    required String cycleId,
  }) {
    return (select(carnetsEngages)..where(
          (c) => c.memberId.equals(memberId) & c.cycleId.equals(cycleId),
        ))
        .getSingleOrNull();
  }

  Future<List<CarnetsEngage>> carnetsEngagesDuCycle(String cycleId) {
    return (select(
      carnetsEngages,
    )..where((c) => c.cycleId.equals(cycleId))).get();
  }

  /// Engage l'unique carnet d'un membre pour un cycle — **un membre a
  /// droit à un seul carnet, toujours** (décision du fondateur qui
  /// annule et remplace l'ancienne règle "1 ou 2 carnets" : une
  /// personne qui détient plusieurs carnets physiques est désormais
  /// inscrite comme autant de membres distincts, chacun identifié par
  /// son propre nom et numéro de téléphone — voir
  /// [nomOuTelephoneDejaUtiliseDansLeGroupe] et DECISIONS.md). Le
  /// paramètre `nombreCarnets` n'existe plus que pour compatibilité
  /// interne (toujours 1, une valeur différente lève `ArgumentError`).
  /// Refuse si déjà verrouillé (un premier paiement a déjà été
  /// enregistré pour ce membre sur ce cycle) — le choix devient alors
  /// définitif pour le reste du cycle.
  Future<void> definirCarnetsEngages({
    required String groupId,
    required String cycleId,
    required String memberId,
    int nombreCarnets = 1,
  }) async {
    if (nombreCarnets != 1) {
      throw ArgumentError('Un membre ne peut avoir qu\'un seul carnet.');
    }
    final existant = await carnetsEngagesDuMembre(
      memberId: memberId,
      cycleId: cycleId,
    );
    if (existant != null) {
      if (existant.lockedAt != null) {
        // Déjà 1 carnet, déjà verrouillé — rien à faire (idempotent).
        return;
      }
      await (update(carnetsEngages)..where((c) => c.id.equals(existant.id)))
          .write(const CarnetsEngagesCompanion(nombreCarnets: Value(1)));
    } else {
      await into(carnetsEngages).insert(
        CarnetsEngagesCompanion.insert(
          id: _uuid.v4(),
          groupId: groupId,
          cycleId: cycleId,
          memberId: memberId,
          nombreCarnets: 1,
        ),
      );
    }
    // Identité persistante du carnet (numéro de série, voir
    // DECISIONS.md "Numéro de série physique par carnet") — créée une
    // seule fois, réutilisée telle quelle aux cycles suivants si le
    // membre réengage.
    await genererOuRecupererCarnet(
      groupId: groupId,
      memberId: memberId,
      carnetNumero: 1,
    );
  }

  /// Verrouille les carnets engagés d'un membre pour un cycle — appelé
  /// automatiquement par [enregistrerCotisationCash] (uniquement pour une
  /// écriture `direct`, jamais pour un import historique) dès le premier
  /// paiement, sans jamais toucher aux lignes déjà verrouillées.
  Future<void> _verrouillerCarnetsSiBesoin({
    required String cycleId,
    required String memberId,
  }) async {
    final existant = await carnetsEngagesDuMembre(
      memberId: memberId,
      cycleId: cycleId,
    );
    if (existant != null && existant.lockedAt == null) {
      await (update(carnetsEngages)..where((c) => c.id.equals(existant.id)))
          .write(CarnetsEngagesCompanion(lockedAt: Value(AppClock.now())));
    }
  }

  // ---------------------------------------------------------------------
  // Carnets — identité persistante (numéro de série), voir DECISIONS.md
  // "Numéro de série physique par carnet". Distinct de CarnetsEngages
  // (le choix, par cycle, du nombre de carnets) : une ligne par (membre,
  // carnetNumero), créée une fois, réutilisée à chaque cycle suivant.
  // ---------------------------------------------------------------------

  Future<Carnet?> carnetDuMembre({
    required String memberId,
    required int carnetNumero,
  }) {
    return (select(carnets)..where(
          (c) => c.memberId.equals(memberId) & c.carnetNumero.equals(carnetNumero),
        ))
        .getSingleOrNull();
  }

  Future<List<Carnet>> carnetsDuGroupe(String groupId) {
    return (select(carnets)..where((c) => c.groupId.equals(groupId))).get();
  }

  /// Prochain numéro de série disponible dans la séquence du groupe —
  /// jamais réutilisé, même si un carnet plus ancien portait un numéro
  /// supérieur suite à une correction manuelle (voir
  /// [genererOuRecupererCarnet]).
  Future<String> _prochainNumeroSerieDisponible(String groupId) async {
    final existants = await carnetsDuGroupe(groupId);
    var maxNumero = 0;
    for (final c in existants) {
      final match = RegExp(r'^C-(\d+)$').firstMatch(c.numeroSerie);
      if (match == null) continue;
      final n = int.parse(match.group(1)!);
      if (n > maxNumero) maxNumero = n;
    }
    return 'C-${(maxNumero + 1).toString().padLeft(3, '0')}';
  }

  /// Renvoie le numéro de série du carnet (membre, carnetNumero) — le
  /// crée s'il n'existe pas encore. [numeroSerieManuel] permet à l'agent
  /// de saisir un numéro déjà inscrit sur un vrai carnet physique
  /// plutôt que d'accepter le numéro auto-généré ; ignoré si le carnet
  /// existe déjà (son numéro, une fois créé, ne change plus ici — voir
  /// [redefinirNumeroSerieCarnet] pour une correction ultérieure).
  Future<String> genererOuRecupererCarnet({
    required String groupId,
    required String memberId,
    required int carnetNumero,
    String? numeroSerieManuel,
  }) async {
    final existant = await carnetDuMembre(
      memberId: memberId,
      carnetNumero: carnetNumero,
    );
    if (existant != null) return existant.numeroSerie;

    final numeroSerie =
        numeroSerieManuel ?? await _prochainNumeroSerieDisponible(groupId);
    final dejaPris =
        await (select(carnets)..where(
              (c) => c.groupId.equals(groupId) & c.numeroSerie.equals(numeroSerie),
            ))
            .getSingleOrNull();
    if (dejaPris != null) {
      throw StateError(
        'Le numéro de série "$numeroSerie" est déjà utilisé par un autre '
        'carnet de ce groupe.',
      );
    }
    await into(carnets).insert(
      CarnetsCompanion.insert(
        id: _uuid.v4(),
        groupId: groupId,
        memberId: memberId,
        carnetNumero: carnetNumero,
        numeroSerie: numeroSerie,
      ),
    );
    return numeroSerie;
  }

  /// Corrige le numéro de série d'un carnet déjà créé (erreur de saisie,
  /// ou le vrai numéro physique n'était pas encore connu). Ne touche
  /// jamais les cotisations/échéances/amendes déjà enregistrées : elles
  /// continuent de référencer le carnet par (membre, carnetNumero),
  /// jamais par son numéro de série (purement un libellé affiché).
  Future<void> redefinirNumeroSerieCarnet({
    required String memberId,
    required int carnetNumero,
    required String nouveauNumeroSerie,
  }) async {
    final existant = await carnetDuMembre(
      memberId: memberId,
      carnetNumero: carnetNumero,
    );
    if (existant == null) {
      throw StateError('Ce carnet n\'a pas encore été créé.');
    }
    final dejaPris =
        await (select(carnets)..where(
              (c) =>
                  c.groupId.equals(existant.groupId) &
                  c.numeroSerie.equals(nouveauNumeroSerie) &
                  c.id.equals(existant.id).not(),
            ))
            .getSingleOrNull();
    if (dejaPris != null) {
      throw StateError(
        'Le numéro de série "$nouveauNumeroSerie" est déjà utilisé par un '
        'autre carnet de ce groupe.',
      );
    }
    await (update(carnets)..where((c) => c.id.equals(existant.id))).write(
      CarnetsCompanion(numeroSerie: Value(nouveauNumeroSerie)),
    );
  }

  // ---------------------------------------------------------------------
  // Cotisations (ajout seul)
  // ---------------------------------------------------------------------

  /// [carnetNumero] identifie quel carnet du membre cette cotisation
  /// concerne (1 ou 2 — voir DECISIONS.md, "Parts libres par cotisation,
  /// minimum 1"). [partsCount] est le nombre de parts déposées dans CE
  /// carnet par cette transaction (entre 1 et 5 en usage normal, validé
  /// côté écran — voir [EcheanceCalculator.estUnMontantValide]).
  Future<String> enregistrerCotisationCash({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int partsCount,
    required String recordedByPhone,
    int carnetNumero = 1,
    String provenance = 'direct',
    bool estApproximatif = false,
    DateTime? recordedAt,
    DateTime? echeanceDate,
  }) async {
    final id = _uuid.v4();
    final horodatage = recordedAt ?? AppClock.now();
    final previousHash = await _lastHashOf(cotisations.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        cycleId,
        memberId,
        carnetNumero,
        partsCount,
        'cash',
        recordedByPhone,
        horodatage.toIso8601String(),
        provenance,
        echeanceDate?.toIso8601String() ?? '',
      ],
    );
    await into(cotisations).insert(
      CotisationsCompanion.insert(
        id: id,
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        carnetNumero: Value(carnetNumero),
        partsCount: partsCount,
        source: const Value('cash'),
        recordedByPhone: recordedByPhone,
        recordedAt: Value(horodatage),
        echeanceDate: Value(echeanceDate),
        previousHash: Value(previousHash),
        hash: hash,
        provenance: Value(provenance),
        estApproximatif: Value(estApproximatif),
      ),
    );
    if (provenance == 'direct') {
      await _verrouillerCarnetsSiBesoin(cycleId: cycleId, memberId: memberId);
    }
    return id;
  }

  /// Somme, en FCFA, de tout ce qu'un membre a déjà cotisé sur ce cycle,
  /// **tous carnets confondus** (`partsCount × valeur de la part`).
  Future<int> totalCotiseFcfa({
    required String memberId,
    required String cycleId,
  }) async {
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();
    final mesCotisations = await cotisationsDuMembre(memberId, cycleId);
    final totalParts = mesCotisations.fold<int>(0, (s, c) => s + c.partsCount);
    return totalParts * cycle.partValueFcfa;
  }

  /// Comme [totalCotiseFcfa] mais limité à **un seul carnet** — chaque
  /// carnet d'un membre suit ses échéances indépendamment (voir
  /// DECISIONS.md).
  Future<int> totalCotiseParCarnetFcfa({
    required String memberId,
    required String cycleId,
    required int carnetNumero,
  }) async {
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();
    final mesCotisations =
        await (select(cotisations)..where(
              (c) =>
                  c.memberId.equals(memberId) &
                  c.cycleId.equals(cycleId) &
                  c.carnetNumero.equals(carnetNumero),
            ))
            .get();
    final totalParts = mesCotisations.fold<int>(0, (s, c) => s + c.partsCount);
    return totalParts * cycle.partValueFcfa;
  }

  Future<List<Cotisation>> cotisationsDuCycle(String cycleId) {
    return (select(cotisations)..where((c) => c.cycleId.equals(cycleId))).get();
  }

  /// Somme de tout ce qui a été cotisé sur ce cycle, tous membres et
  /// tous carnets confondus — base de la formule "caisse disponible"
  /// (voir [EndOfCycleCalculator], DECISIONS.md "Nouvelle formule de
  /// partage").
  Future<int> totalCotisationsDuCycle(String cycleId) async {
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();
    final toutes = await cotisationsDuCycle(cycleId);
    final totalParts = toutes.fold<int>(0, (s, c) => s + c.partsCount);
    return totalParts * cycle.partValueFcfa;
  }

  /// Cotisations d'un seul membre sur un cycle — filtrage fait au
  /// niveau de la requête, pas en mémoire après coup, pour rester
  /// cohérent avec le principe du skill two-tier-access-model (même si
  /// ici c'est du SQLite local ; la même requête deviendra une politique
  /// row-level security côté Supabase).
  Future<List<Cotisation>> cotisationsDuMembre(
    String memberId,
    String cycleId,
  ) {
    return (select(cotisations)..where(
          (c) => c.memberId.equals(memberId) & c.cycleId.equals(cycleId),
        ))
        .get();
  }

  // ---------------------------------------------------------------------
  // Prêts (ajout seul + confirmation par code)
  // ---------------------------------------------------------------------

  /// [confirmationCode] est nullable : null pour un prêt destiné à un
  /// membre sans téléphone (aucun code à envoyer — confirmation par
  /// signature, voir [confirmerPretParSignature]).
  ///
  /// Pour une écriture `direct` (jamais pour `importe`, un import
  /// historique décrivant des prêts déjà accordés dans le passé selon
  /// les règles d'alors) : refuse si aucune fenêtre de crédit n'est
  /// ouverte (voir [LoanWindowCalculator], DECISIONS.md "Fenêtres de
  /// crédit selon la fréquence de réunion") ou si le montant demandé
  /// dépasse la caisse disponible (voir [caisseDisponibleActuelleFcfa],
  /// DECISIONS.md "Rationnement des crédits selon la caisse
  /// disponible") — vérifié ici aussi, pas seulement côté écran, même
  /// principe que les autres invariants de cette classe. Ni l'une ni
  /// l'autre condition ne s'applique à un `renouvellement` (voir
  /// [sortirDuRouge]/[reconduireCyclePret]) : ce n'est pas un nouvel
  /// argent prêté depuis la caisse, juste la même dette déjà en cours
  /// qui continue sous une nouvelle ligne. [demandeId] : renseigné
  /// quand ce prêt provient du rationnement collectif des crédits
  /// (voir [accepterDemandePret]) — reste `direct`, donc toujours
  /// soumis aux deux contrôles ci-dessus (filet de sécurité, même si
  /// le montant accepté a déjà été calculé pour tenir dans la caisse).
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
    String? renouvelePretId,
    bool estAuRougeDesLeDepart = false,
    String? demandeId,
  }) async {
    final id = _uuid.v4();
    final horodatage = createdAt ?? AppClock.now();

    if (provenance == 'direct') {
      final groupe = await (select(
        groups,
      )..where((g) => g.id.equals(groupId))).getSingle();
      final cycle = await (select(
        cycles,
      )..where((c) => c.id.equals(cycleId))).getSingle();
      final fenetreOuverte = const LoanWindowCalculator().fenetreOuverte(
        debutCycle: cycle.startedAt,
        meetingFrequency: groupe.meetingFrequency,
        paymentDayOfWeek: groupe.paymentDayOfWeek,
        paymentDayOfMonth1: groupe.paymentDayOfMonth1,
        paymentDayOfMonth2: groupe.paymentDayOfMonth2,
        maintenant: horodatage,
      );
      if (!fenetreOuverte) {
        throw StateError(
          'Aucune fenêtre de crédit ouverte pour le moment (voir DECISIONS.md, '
          '"Fenêtres de crédit selon la fréquence de réunion").',
        );
      }
      final caisseDisponible = await caisseDisponibleActuelleFcfa(cycleId);
      if (principalFcfa > caisseDisponible) {
        throw StateError(
          'Montant demandé supérieur à la caisse disponible '
          '($caisseDisponible FCFA).',
        );
      }
    }

    final previousHash = await _lastHashOf(prets.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        cycleId,
        memberId,
        principalFcfa,
        interestRatePercent,
        initiatedByPhone,
        horodatage.toIso8601String(),
        provenance,
      ],
    );
    await into(prets).insert(
      PretsCompanion.insert(
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
        renouvelePretId: Value(renouvelePretId),
        estAuRougeDesLeDepart: Value(estAuRougeDesLeDepart),
        demandeId: Value(demandeId),
      ),
    );
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
    final pret = await (select(
      prets,
    )..where((p) => p.id.equals(pretId))).getSingle();
    if (pret.confirmationCode != codeSaisi) {
      return false;
    }
    final id = _uuid.v4();
    final confirmedAt = AppClock.now();
    final previousHash = await _lastHashOf(pretConfirmations.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        pretId,
        codeSaisi,
        confirmedByPhone,
        confirmedAt.toIso8601String(),
      ],
    );
    await into(pretConfirmations).insert(
      PretConfirmationsCompanion.insert(
        id: id,
        pretId: pretId,
        methode: const Value('code'),
        codeSaisi: Value(codeSaisi),
        confirmedByPhone: Value(confirmedByPhone),
        confirmedAt: Value(confirmedAt),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
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
    final pret = await (select(
      prets,
    )..where((p) => p.id.equals(pretId))).getSingle();
    final membre = await (select(
      members,
    )..where((m) => m.id.equals(pret.memberId))).getSingle();
    if (membre.phoneNumber != null) {
      throw StateError(
        'Ce membre a un numéro de téléphone enregistré — la confirmation '
        'doit passer par le code SMS, pas par signature.',
      );
    }
    final id = _uuid.v4();
    final confirmedAt = AppClock.now();
    final previousHash = await _lastHashOf(pretConfirmations.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        pretId,
        signatureData,
        witnessPhone,
        confirmedAt.toIso8601String(),
      ],
    );
    await into(pretConfirmations).insert(
      PretConfirmationsCompanion.insert(
        id: id,
        pretId: pretId,
        methode: const Value('signature'),
        signatureData: Value(signatureData),
        witnessPhone: Value(witnessPhone),
        confirmedAt: Value(confirmedAt),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
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
    final pret = await (select(
      prets,
    )..where((p) => p.id.equals(pretId))).getSingleOrNull();
    if (pret == null) return false;
    if (pret.provenance == 'importe') return true;
    final confirmation = await (select(
      pretConfirmations,
    )..where((c) => c.pretId.equals(pretId))).getSingleOrNull();
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
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        pretId,
        montantFcfa,
        recordedByPhone,
        horodatage.toIso8601String(),
        provenance,
      ],
    );
    await into(pretRemboursements).insert(
      PretRemboursementsCompanion.insert(
        id: id,
        pretId: pretId,
        montantFcfa: montantFcfa,
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

  Future<int> totalRembourse(String pretId) async {
    final rows = await (select(
      pretRemboursements,
    )..where((r) => r.pretId.equals(pretId))).get();
    return rows.fold<int>(0, (sum, r) => sum + r.montantFcfa);
  }

  /// Tous les remboursements d'un prêt, utilisé par
  /// [LoanBalanceCalculator] pour recalculer le solde dû dans l'ordre
  /// chronologique (nécessaire pour l'intérêt qui se recompose).
  Future<List<PretRemboursement>> remboursementsDuPret(String pretId) {
    return (select(
      pretRemboursements,
    )..where((r) => r.pretId.equals(pretId))).get();
  }

  /// Total remboursé par un membre, tous ses prêts confondus, un jour
  /// précis — utilisé par le récap "Séance du jour" (voir
  /// RETOURS_TERRAIN.md) pour afficher si un membre a réglé une dette
  /// de prêt pendant la réunion du jour.
  Future<int> totalRembourseParMembreAuJour({
    required String memberId,
    required String cycleId,
    required DateTime jour,
  }) async {
    final debut = DateTime(jour.year, jour.month, jour.day);
    final fin = debut.add(const Duration(days: 1));
    final pretsMembre = await pretsDuMembre(memberId, cycleId);
    var total = 0;
    for (final pret in pretsMembre) {
      final remboursements =
          await (select(pretRemboursements)..where(
                (r) =>
                    r.pretId.equals(pret.id) &
                    r.recordedAt.isBiggerOrEqualValue(debut) &
                    r.recordedAt.isSmallerThanValue(fin),
              ))
              .get();
      total += remboursements.fold<int>(0, (s, r) => s + r.montantFcfa);
    }
    return total;
  }

  /// Solde dû d'un prêt à cet instant — recalcule via
  /// [LoanBalanceCalculator], fil aligné sur les réunions du groupe.
  /// Petit assembleur réutilisé **partout** où ce calcul est nécessaire
  /// (voir DECISIONS.md, "Dette de prêt au rouge") — jamais dupliqué
  /// inline, précisément pour que le plafond ci-dessous s'applique
  /// uniformément.
  ///
  /// **Dette perdue à la clôture si non reconduite** (précisé par le
  /// fondateur, voir DECISIONS.md) : une fois le cycle du prêt clos
  /// (`Cycles.status == 'cloture'`), la composition "au rouge" ne va
  /// jamais au-delà de l'instant de la clôture (`Cycles.endedAt`),
  /// même si cette méthode est appelée bien plus tard (écran rouvert
  /// des mois après) — sinon un prêt jamais reconduit continuerait,
  /// dans les calculs, à composer indéfiniment, ce que le fondateur a
  /// explicitement écarté ("on considère la dette comme perdue").
  Future<LoanBalanceResult> soldePret(
    Pret pret, {
    DateTime? maintenant,
  }) async {
    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(pret.groupId))).getSingle();
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(pret.cycleId))).getSingle();
    final rembs = await remboursementsDuPret(pret.id);
    final demande = maintenant ?? AppClock.now();
    final plafondClotureAtteint =
        cycle.status == 'cloture' &&
        cycle.endedAt != null &&
        demande.isAfter(cycle.endedAt!);
    final maintenantEffectif = plafondClotureAtteint
        ? cycle.endedAt!
        : demande;
    return const LoanBalanceCalculator().calculer(
      principalFcfa: pret.principalFcfa,
      interestRatePercent: pret.interestRatePercent,
      dureeJours: pret.dureeJours,
      debut: pret.createdAt,
      remboursements: rembs
          .map(
            (r) => RemboursementSimple(
              montantFcfa: r.montantFcfa,
              date: r.recordedAt,
            ),
          )
          .toList(),
      maintenant: maintenantEffectif,
      meetingFrequency: groupe.meetingFrequency,
      paymentDayOfWeek: groupe.paymentDayOfWeek,
      paymentDayOfMonth1: groupe.paymentDayOfMonth1,
      paymentDayOfMonth2: groupe.paymentDayOfMonth2,
      dejaAuRouge: pret.estAuRougeDesLeDepart,
    );
  }

  /// Date de fin prévue d'un cycle — `cycle.startedAt` +
  /// `group.cycleDurationMonths`, base de la fenêtre des 3 derniers
  /// mois utilisée par [LoanRateResolver] (voir DECISIONS.md,
  /// "Résolution automatique du taux de prêt"). Dupliqué depuis
  /// `loans_screen.dart` (même calcul, 4 lignes) plutôt que de faire
  /// dépendre la couche base d'un widget — pas de dépendance partagée
  /// pour un calcul aussi simple.
  ///
  /// Public depuis le 2026-08-13 (voir RETOURS_TERRAIN.md, point 25.6) :
  /// affichée sur l'écran Répartition à côté de la date de début, pour
  /// que l'agent vérifie que les choix faits à la création du groupe
  /// (durée du cycle) sont bien respectés.
  DateTime finDeCyclePrevue(Cycle cycle, Group groupe) {
    return DateTime(
      cycle.startedAt.year,
      cycle.startedAt.month + groupe.cycleDurationMonths,
      cycle.startedAt.day,
    );
  }

  /// Sort un prêt "au rouge" — voir DECISIONS.md, "Sortir du rouge :
  /// paiement libre" : le membre apporte, aujourd'hui, le montant de
  /// son choix ([montantPayeFcfa], peut être 0). Le prêt reconduit vaut
  /// alors `montantDuFcfa (dette totale du jour, principal + intérêts
  /// du rouge) + amende du groupe - montantPayeFcfa` :
  /// - payer exactement les intérêts + l'amende reconduit le principal
  ///   d'origine tel quel ;
  /// - payer plus réduit d'autant le montant reconduit ;
  /// - payer moins (ou rien) ajoute la différence au montant reconduit
  ///   — l'amende n'a jamais de trace séparée dans ce cas, elle est
  ///   absorbée dans le nouveau prêt (décision explicite du fondateur,
  ///   voir DECISIONS.md).
  ///
  /// Le nouveau prêt repart pour une période normale fraîche (jamais
  /// déjà au rouge, contrairement à une reconduction au cycle suivant
  /// — voir [reconduireCyclePret]), **au taux résolu comme un prêt
  /// neuf** (voir [LoanRateResolver] — jamais le taux plat du cycle,
  /// confirmé par le fondateur). Le prêt d'origine n'est ni modifié ni
  /// supprimé, juste relié via [Prets.renouvelePretId]. Comme tout
  /// prêt, le nouveau nécessite sa propre confirmation par le membre
  /// (voir [confirmationCode]) — ni la fenêtre de crédit ni la caisse
  /// disponible ne s'appliquent ici (voir la doc de [enregistrerPret]).
  Future<({String pretId, String? confirmationCode})> sortirDuRouge({
    required String pretId,
    required String agentPhone,
    required int montantPayeFcfa,
    String? confirmationCode,
    DateTime? maintenant,
  }) async {
    if (montantPayeFcfa < 0) {
      throw ArgumentError('montantPayeFcfa ne peut pas être négatif.');
    }
    final pret = await (select(
      prets,
    )..where((p) => p.id.equals(pretId))).getSingle();
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(pret.cycleId))).getSingle();
    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(pret.groupId))).getSingle();
    final now = maintenant ?? AppClock.now();
    final solde = await soldePret(pret, maintenant: now);

    if (!solde.estAuRouge || solde.soldeAuDebutDuRougeFcfa == null) {
      throw StateError('Ce prêt n\'est pas au rouge — rien à en sortir.');
    }

    final nouveauPrincipal =
        solde.montantDuFcfa +
        groupe.montantAmendeSortieRougeFcfa -
        montantPayeFcfa;
    if (nouveauPrincipal <= 0) {
      throw StateError(
        'Ce paiement couvre déjà tout le prêt — enregistrez un '
        'remboursement normal plutôt qu\'une sortie du rouge.',
      );
    }

    if (montantPayeFcfa > 0) {
      await enregistrerRemboursement(
        pretId: pretId,
        montantFcfa: montantPayeFcfa,
        recordedByPhone: agentPhone,
        recordedAt: now,
      );
    }

    // Taux résolu comme un prêt neuf (voir DECISIONS.md) — le prêt
    // d'origine est sur le point d'être remplacé, exclu du total
    // emprunté en cours pour ne pas se compter lui-même.
    final cotiseTotalFcfa = await totalCotiseFcfa(
      memberId: pret.memberId,
      cycleId: pret.cycleId,
    );
    final empruntesEnCoursAvant = await totalEmprunteEnCoursFcfa(
      memberId: pret.memberId,
      cycleId: pret.cycleId,
    );
    final empruntesEnCoursFcfa =
        (empruntesEnCoursAvant - pret.principalFcfa) < 0
        ? 0
        : empruntesEnCoursAvant - pret.principalFcfa;
    final resolution = const LoanRateResolver().resoudre(
      cotiseTotalFcfa: cotiseTotalFcfa,
      empruntesEnCoursFcfa: empruntesEnCoursFcfa,
      principalDemandeFcfa: nouveauPrincipal,
      maintenant: now,
      finDeCycle: finDeCyclePrevue(cycle, groupe),
    );

    return enregistrerPret(
      groupId: pret.groupId,
      cycleId: pret.cycleId,
      memberId: pret.memberId,
      principalFcfa: nouveauPrincipal,
      interestRatePercent: resolution.tauxPercent,
      initiatedByPhone: agentPhone,
      confirmationCode: confirmationCode,
      dureeJours: cycle.loanDurationDays,
      provenance: 'renouvellement',
      createdAt: now,
      renouvelePretId: pretId,
    );
  }

  /// Reconduit un prêt non soldé à la clôture d'un cycle, dans le
  /// **nouveau** cycle qui vient d'être ouvert — voir DECISIONS.md,
  /// "Dette de prêt au rouge", et RETOURS_TERRAIN.md, point 19.
  /// **Jamais automatique** : n'est appelé qu'après que l'agent a
  /// explicitement demandé et obtenu l'accord du membre (voir l'écran
  /// de clôture de cycle) — cette méthode ne fait aucune vérification
  /// de consentement métier au-delà de la confirmation du prêt
  /// lui-même, exactement comme [sortirDuRouge].
  ///
  /// Le solde restant du prêt d'origine (recalculé via [soldePret] —
  /// jamais la version simplifiée de [pretsNonSoldesDuCycle], qui ne
  /// sert qu'à signaler l'existence d'un solde, pas à le chiffrer avec
  /// précision) devient, **tel quel** (pas de paiement partiel possible
  /// ici — reconduction automatique dans son calcul, contrairement à
  /// [sortirDuRouge] ; seule l'action de reconduire reste manuelle, voir
  /// l'écran de clôture de cycle), le principal d'un **nouveau prêt
  /// successeur** dans le nouveau cycle, **au taux résolu comme un prêt
  /// neuf** (voir [LoanRateResolver], évalué sur le nouveau cycle —
  /// cotisation et emprunts y démarrent à 0, ce qui pousse souvent vers
  /// "hors carnet" en tout début de cycle : confirmé volontaire par le
  /// fondateur). Contrairement à [sortirDuRouge] (sortie dans le même
  /// cycle, nouvelle période normale fraîche), ce successeur est **déjà
  /// au rouge dès sa création** (`estAuRougeDesLeDepart: true`) — le
  /// retard du cycle précédent ne s'efface pas au passage de cycle.
  /// Comme tout prêt, il exige sa propre confirmation par le membre.
  Future<({String pretId, String? confirmationCode})> reconduireCyclePret({
    required String pretId,
    required String nouveauCycleId,
    required String agentPhone,
    String? confirmationCode,
    DateTime? maintenant,
  }) async {
    final pret = await (select(
      prets,
    )..where((p) => p.id.equals(pretId))).getSingle();
    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(pret.groupId))).getSingle();
    final nouveauCycle = await (select(
      cycles,
    )..where((c) => c.id.equals(nouveauCycleId))).getSingle();
    final now = maintenant ?? AppClock.now();
    final solde = await soldePret(pret, maintenant: now);

    if (solde.montantDuFcfa <= 0) {
      throw StateError('Ce prêt est déjà soldé — rien à reconduire.');
    }

    final cotiseTotalFcfa = await totalCotiseFcfa(
      memberId: pret.memberId,
      cycleId: nouveauCycleId,
    );
    final empruntesEnCoursFcfa = await totalEmprunteEnCoursFcfa(
      memberId: pret.memberId,
      cycleId: nouveauCycleId,
    );
    final resolution = const LoanRateResolver().resoudre(
      cotiseTotalFcfa: cotiseTotalFcfa,
      empruntesEnCoursFcfa: empruntesEnCoursFcfa,
      principalDemandeFcfa: solde.montantDuFcfa,
      maintenant: now,
      finDeCycle: finDeCyclePrevue(nouveauCycle, groupe),
    );

    return enregistrerPret(
      groupId: pret.groupId,
      cycleId: nouveauCycleId,
      memberId: pret.memberId,
      principalFcfa: solde.montantDuFcfa,
      interestRatePercent: resolution.tauxPercent,
      initiatedByPhone: agentPhone,
      confirmationCode: confirmationCode,
      dureeJours: nouveauCycle.loanDurationDays,
      provenance: 'renouvellement',
      createdAt: now,
      renouvelePretId: pretId,
      estAuRougeDesLeDepart: true,
    );
  }

  Future<List<Pret>> pretsDuCycle(String cycleId) {
    return (select(prets)..where((p) => p.cycleId.equals(cycleId))).get();
  }

  Future<List<Pret>> pretsDuMembre(String memberId, String cycleId) {
    return (select(prets)..where(
          (p) => p.memberId.equals(memberId) & p.cycleId.equals(cycleId),
        ))
        .get();
  }

  // ---------------------------------------------------------------------
  // Rationnement collectif des crédits (voir DECISIONS.md,
  // "Rationnement collectif des crédits", RETOURS_TERRAIN.md point 13)
  // ---------------------------------------------------------------------

  /// Dépose une **demande** de prêt — distincte d'un [Pret] réel, elle
  /// capture l'intention du membre sans l'accorder tout de suite,
  /// contrairement à [enregistrerPret]. Reste soumise à la fenêtre de
  /// crédit (même contrôle que pour un prêt direct) mais **jamais** au
  /// plafond de caisse disponible — c'est justement ce qui sera
  /// négocié si plusieurs demandes coexistent (voir
  /// [demandesEnAttenteDuCycle], [accepterDemandePret]).
  Future<String> demanderPret({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int montantDemandeFcfa,
    required String recordedByPhone,
    DateTime? createdAt,
  }) async {
    if (montantDemandeFcfa <= 0) {
      throw ArgumentError('montantDemandeFcfa doit être positif.');
    }
    final horodatage = createdAt ?? AppClock.now();
    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(groupId))).getSingle();
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();
    final fenetreOuverte = const LoanWindowCalculator().fenetreOuverte(
      debutCycle: cycle.startedAt,
      meetingFrequency: groupe.meetingFrequency,
      paymentDayOfWeek: groupe.paymentDayOfWeek,
      paymentDayOfMonth1: groupe.paymentDayOfMonth1,
      paymentDayOfMonth2: groupe.paymentDayOfMonth2,
      maintenant: horodatage,
    );
    if (!fenetreOuverte) {
      throw StateError(
        'Aucune fenêtre de crédit ouverte pour le moment (voir DECISIONS.md, '
        '"Fenêtres de crédit selon la fréquence de réunion").',
      );
    }

    final id = _uuid.v4();
    final previousHash = await _lastHashOf(pretDemandes.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        cycleId,
        memberId,
        montantDemandeFcfa,
        recordedByPhone,
        horodatage.toIso8601String(),
      ],
    );
    await into(pretDemandes).insert(
      PretDemandesCompanion.insert(
        id: id,
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        montantDemandeFcfa: montantDemandeFcfa,
        recordedByPhone: recordedByPhone,
        createdAt: Value(horodatage),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
    return id;
  }

  /// Identifiants des demandes déjà résolues — accordées (via
  /// [Prets.demandeId]) ou refusées (via [PretDemandeRefus]) — à
  /// exclure de la file d'attente.
  Future<Set<String>> _idsDesDemandesResolues() async {
    final pretsAvecDemande = await (select(
      prets,
    )..where((p) => p.demandeId.isNotNull())).get();
    final refus = await (select(pretDemandeRefus)).get();
    return {
      for (final p in pretsAvecDemande) p.demandeId!,
      for (final r in refus) r.demandeId,
    };
  }

  /// Demandes de prêt encore en attente d'un cycle, dans l'ordre où
  /// elles ont été déposées (FIFO — premier arrivé, premier traité).
  Future<List<PretDemande>> demandesEnAttenteDuCycle(String cycleId) async {
    final toutes =
        await (select(pretDemandes)
              ..where((d) => d.cycleId.equals(cycleId))
              ..orderBy([(d) => OrderingTerm.asc(d.createdAt)]))
            .get();
    final resolues = await _idsDesDemandesResolues();
    return toutes.where((d) => !resolues.contains(d.id)).toList();
  }

  /// Montant à proposer **maintenant** à la première demande encore en
  /// attente d'un cycle (voir [CollectiveLoanRationingCalculator]) —
  /// recalculé à chaque appel à partir de l'état courant (redistribution
  /// immédiate, voir DECISIONS.md). Null s'il n'y a aucune demande en
  /// attente.
  Future<({PretDemande demande, int montantProposeFcfa})?>
  prochaineDemandeAvecAllocation(String cycleId) async {
    final enAttente = await demandesEnAttenteDuCycle(cycleId);
    if (enAttente.isEmpty) return null;
    final caisse = await caisseDisponibleActuelleFcfa(cycleId);
    final montant = const CollectiveLoanRationingCalculator()
        .allocationProposeeFcfa(
          montantsDemandesEnAttenteFcfa: enAttente
              .map((d) => d.montantDemandeFcfa)
              .toList(),
          caisseDisponibleFcfa: caisse,
        );
    return (demande: enAttente.first, montantProposeFcfa: montant);
  }

  /// Accepte une demande de prêt — pour le montant proposé (voir
  /// [prochaineDemandeAvecAllocation]) ou tout autre montant
  /// explicitement choisi, jamais plus que la demande d'origine. Crée
  /// un [Pret] réel via [enregistrerPret] (mêmes contrôles
  /// fenêtre/caisse en filet de sécurité — voir sa doc), relié à la
  /// demande via [Prets.demandeId], **au taux résolu comme un prêt
  /// neuf** (voir [LoanRateResolver], même principe que
  /// [sortirDuRouge]/[reconduireCyclePret]) — jamais un taux plat.
  /// Comme tout prêt, il exige sa propre confirmation par le membre.
  Future<({String pretId, String? confirmationCode})> accepterDemandePret({
    required String demandeId,
    required int montantAccepteFcfa,
    required String agentPhone,
    String? confirmationCode,
    DateTime? maintenant,
  }) async {
    final demande = await (select(
      pretDemandes,
    )..where((d) => d.id.equals(demandeId))).getSingle();
    if (montantAccepteFcfa <= 0 ||
        montantAccepteFcfa > demande.montantDemandeFcfa) {
      throw ArgumentError(
        'Le montant accepté doit être positif et ne peut pas dépasser le '
        'montant demandé (${demande.montantDemandeFcfa} FCFA).',
      );
    }
    final resolues = await _idsDesDemandesResolues();
    if (resolues.contains(demandeId)) {
      throw StateError('Cette demande a déjà été traitée.');
    }

    final now = maintenant ?? AppClock.now();
    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(demande.groupId))).getSingle();
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(demande.cycleId))).getSingle();
    final cotiseTotalFcfa = await totalCotiseFcfa(
      memberId: demande.memberId,
      cycleId: demande.cycleId,
    );
    final empruntesEnCoursFcfa = await totalEmprunteEnCoursFcfa(
      memberId: demande.memberId,
      cycleId: demande.cycleId,
    );
    final resolution = const LoanRateResolver().resoudre(
      cotiseTotalFcfa: cotiseTotalFcfa,
      empruntesEnCoursFcfa: empruntesEnCoursFcfa,
      principalDemandeFcfa: montantAccepteFcfa,
      maintenant: now,
      finDeCycle: finDeCyclePrevue(cycle, groupe),
    );

    return enregistrerPret(
      groupId: demande.groupId,
      cycleId: demande.cycleId,
      memberId: demande.memberId,
      principalFcfa: montantAccepteFcfa,
      interestRatePercent: resolution.tauxPercent,
      initiatedByPhone: agentPhone,
      confirmationCode: confirmationCode,
      dureeJours: cycle.loanDurationDays,
      createdAt: now,
      demandeId: demandeId,
    );
  }

  /// Refuse (ou annule) une demande de prêt — le membre se désiste,
  /// ou l'agent l'annule. Toujours une nouvelle ligne dans
  /// [PretDemandeRefus], jamais une modification de la demande
  /// d'origine.
  Future<void> refuserDemandePret({
    required String demandeId,
    required String agentPhone,
    DateTime? maintenant,
  }) async {
    final resolues = await _idsDesDemandesResolues();
    if (resolues.contains(demandeId)) {
      throw StateError('Cette demande a déjà été traitée.');
    }
    final id = _uuid.v4();
    final horodatage = maintenant ?? AppClock.now();
    final previousHash = await _lastHashOf(pretDemandeRefus.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [id, demandeId, agentPhone, horodatage.toIso8601String()],
    );
    await into(pretDemandeRefus).insert(
      PretDemandeRefusCompanion.insert(
        id: id,
        demandeId: demandeId,
        recordedByPhone: agentPhone,
        refusedAt: Value(horodatage),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
  }

  /// Prêts confirmés du cycle dont le remboursement (principal + intérêt)
  /// n'est pas encore complet — sert d'avertissement, non bloquant, avant
  /// la clôture du cycle (voir [cloturerCycleEtOuvrirSuivant]). Le dossier
  /// source ne précise pas de règle de report de dette d'un cycle à
  /// l'autre : l'app se contente de signaler la situation à l'agent, elle
  /// n'invente aucun mécanisme de transfert (voir DECISIONS.md).
  /// Identifiants des prêts déjà remplacés par un successeur (sortie du
  /// rouge ou reconduction au cycle suivant, voir
  /// [Prets.renouvelePretId]) — leur solde restant vit désormais sur le
  /// prêt successeur, jamais les deux à la fois (voir DECISIONS.md,
  /// "Dette de prêt au rouge"). À exclure de tout calcul de solde/dette
  /// portant sur le prêt d'origine.
  Future<Set<String>> _idsDesPretsRenouveles() async {
    final tousLesPrets = await (select(prets)).get();
    return tousLesPrets
        .where((p) => p.renouvelePretId != null)
        .map((p) => p.renouvelePretId!)
        .toSet();
  }

  Future<List<PretNonSolde>> pretsNonSoldesDuCycle(String cycleId) async {
    final pretsCycle = await pretsDuCycle(cycleId);
    final idsDejaRenouveles = await _idsDesPretsRenouveles();

    final resultat = <PretNonSolde>[];
    for (final pret in pretsCycle) {
      if (idsDejaRenouveles.contains(pret.id)) continue;
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

  /// Somme des principaux des prêts confirmés non soldés d'UN membre sur
  /// ce cycle — base du plafond souple de 3x l'épargne cotisée (voir
  /// [LoanRateResolver]). Le principal, pas le solde restant dû avec
  /// intérêt : ce plafond porte sur ce que le membre a emprunté, pas sur
  /// ce qu'il reste à rembourser (qui varie avec le temps sans rapport
  /// avec sa capacité d'emprunt).
  Future<int> totalEmprunteEnCoursFcfa({
    required String memberId,
    required String cycleId,
  }) async {
    final nonSoldes = await pretsNonSoldesDuCycle(cycleId);
    return nonSoldes
        .where((p) => p.pret.memberId == memberId)
        .fold<int>(0, (s, p) => s + p.pret.principalFcfa);
  }

  /// Comme [totalEmprunteEnCoursFcfa] mais pour **tout le groupe** —
  /// le "Dettes en cours" de la formule "caisse disponible" (voir
  /// [EndOfCycleCalculator], DECISIONS.md "Nouvelle formule de
  /// partage") : le capital des prêts confirmés pas encore
  /// intégralement remboursés, tous membres confondus.
  Future<int> totalPrincipalNonRembourseDuCycle(String cycleId) async {
    final nonSoldes = await pretsNonSoldesDuCycle(cycleId);
    return nonSoldes.fold<int>(0, (s, p) => s + p.pret.principalFcfa);
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

  /// Argent réellement disponible dans la caisse à cet instant — base
  /// du rationnement des crédits (voir DECISIONS.md, "Rationnement des
  /// crédits selon la caisse disponible", RETOURS_TERRAIN.md point 13 :
  /// "exactement ce qui a été enregistré par l'agent"). Tout ce qui est
  /// entré (cotisations + intérêts perçus + amendes réglées cash) moins
  /// ce qui est sorti sous forme de prêts pas encore remboursés. Ne
  /// tient jamais compte du fonds de solidarité (toujours exclu, voir
  /// DECISIONS.md). Jamais négatif.
  Future<int> caisseDisponibleActuelleFcfa(String cycleId) async {
    final cotisations = await totalCotisationsDuCycle(cycleId);
    final interets = await totalInteretsPercusDuCycle(cycleId);
    final amendes = await totalAmendesRegleesDuCycle(cycleId);
    final principalEnCours = await totalPrincipalNonRembourseDuCycle(cycleId);
    final caisse = cotisations + interets.round() + amendes - principalEnCours;
    return caisse <= 0 ? 0 : caisse;
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
    int carnetNumero = 1,
    DateTime? echeanceDate,
    String? motifCodeSysteme,
    String provenance = 'direct',
    bool estApproximatif = false,
    bool estAutoGeneree = false,
    DateTime? recordedAt,
  }) async {
    final id = _uuid.v4();
    final horodatage = recordedAt ?? AppClock.now();
    final previousHash = await _lastHashOf(amendes.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        cycleId,
        memberId,
        montantFcfa,
        motif,
        recordedByPhone,
        horodatage.toIso8601String(),
        provenance,
        carnetNumero,
        echeanceDate?.toIso8601String() ?? '',
      ],
    );
    await into(amendes).insert(
      AmendesCompanion.insert(
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
        carnetNumero: Value(carnetNumero),
        echeanceDate: Value(echeanceDate),
        motifCodeSysteme: Value(motifCodeSysteme),
      ),
    );
    return id;
  }

  Future<double> totalAmendesDuCycle(String cycleId) async {
    final rows = await (select(
      amendes,
    )..where((a) => a.cycleId.equals(cycleId))).get();
    return rows.fold<double>(0, (sum, a) => sum + a.montantFcfa);
  }

  /// Somme des amendes **réglées** (confirmées, non annulées) sur ce
  /// cycle — jamais celles encore en attente ni celles annulées par
  /// erreur. Base de la formule "caisse disponible" (voir
  /// [EndOfCycleCalculator], DECISIONS.md "Nouvelle formule de
  /// partage") : seul l'argent réellement rentré compte, contrairement
  /// à [totalAmendesDuCycle] (toutes les amendes émises, utilisé
  /// ailleurs).
  Future<int> totalAmendesRegleesDuCycle(String cycleId) async {
    final toutes = await (select(
      amendes,
    )..where((a) => a.cycleId.equals(cycleId))).get();
    if (toutes.isEmpty) return 0;
    final annulees = await _amendesAnnuleesParmi(toutes.map((a) => a.id));
    return toutes
        .where((a) => a.confirmedAt != null && !annulees.contains(a.id))
        .fold<int>(0, (s, a) => s + a.montantFcfa);
  }

  Future<List<Amende>> amendesDuMembre(String memberId, String cycleId) {
    return (select(amendes)..where(
          (a) => a.memberId.equals(memberId) & a.cycleId.equals(cycleId),
        ))
        .get();
  }

  /// Toutes les amendes d'un cycle, tous membres confondus — base de
  /// l'écran "Amendes" dédié (voir DECISIONS.md, "Section Amendes
  /// dédiée"), les plus récentes d'abord.
  Future<List<Amende>> amendesDuCycle(String cycleId) {
    return (select(amendes)
          ..where((a) => a.cycleId.equals(cycleId))
          ..orderBy([(a) => OrderingTerm.desc(a.recordedAt)]))
        .get();
  }

  /// Identifiants des amendes annulées parmi [amendeIds] — toujours
  /// vérifié plutôt que supposé, l'annulation ne supprime jamais la
  /// ligne d'origine (voir [AmendeAnnulations]).
  Future<Set<String>> _amendesAnnuleesParmi(Iterable<String> amendeIds) async {
    if (amendeIds.isEmpty) return {};
    final annulations = await (select(
      amendeAnnulations,
    )..where((a) => a.amendeId.isIn(amendeIds))).get();
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
    final auto =
        await (select(amendes)..where(
              (a) =>
                  a.memberId.equals(memberId) &
                  a.cycleId.equals(cycleId) &
                  a.estAutoGeneree.equals(true),
            ))
            .get();
    if (auto.isEmpty) return [];
    final annulees = await _amendesAnnuleesParmi(auto.map((a) => a.id));
    return auto.where((a) => !annulees.contains(a.id)).toList();
  }

  /// Amendes auto-générées en attente de revue par l'agent : ni
  /// **revues** (`reviewedAt`, voir DECISIONS.md "Écran Cotisations
  /// moins chargé" — distinct de `confirmedAt`, le règlement), ni déjà
  /// annulées. Affichées à la séance suivant leur création (skill
  /// avec-business-rules, section "Retard de cotisation") — **rend la
  /// saisie de cotisation bloquée sur l'écran Cotisations tant que
  /// cette liste n'est pas vide**, voir `record_cotisation_screen.dart`.
  Future<List<({Amende amende, Member membre})>> amendesEnAttenteRevue({
    required String groupId,
    required String cycleId,
  }) async {
    final candidates =
        await (select(amendes)..where(
              (a) =>
                  a.groupId.equals(groupId) &
                  a.cycleId.equals(cycleId) &
                  a.estAutoGeneree.equals(true) &
                  a.reviewedAt.isNull(),
            ))
            .get();
    if (candidates.isEmpty) return [];
    final annulees = await _amendesAnnuleesParmi(candidates.map((a) => a.id));
    final resultat = <({Amende amende, Member membre})>[];
    for (final a in candidates) {
      if (annulees.contains(a.id)) continue;
      final membre = await (select(
        members,
      )..where((m) => m.id.equals(a.memberId))).getSingle();
      resultat.add((amende: a, membre: membre));
    }
    return resultat;
  }

  /// Règle une amende (cash, ou par déduction automatique à la clôture
  /// du cycle — voir DECISIONS.md, "Les amendes ne sont plus une
  /// dette") : renseigne `confirmedAt` et, si ce n'était pas déjà fait,
  /// `reviewedAt` aussi (payer une amende équivaut à l'avoir revue — ne
  /// réapparaîtra plus dans [amendesEnAttenteRevue]).
  Future<void> confirmerAmende(String amendeId) async {
    final amende = await (select(
      amendes,
    )..where((a) => a.id.equals(amendeId))).getSingle();
    final maintenant = AppClock.now();
    await (update(amendes)..where((a) => a.id.equals(amendeId))).write(
      AmendesCompanion(
        confirmedAt: Value(maintenant),
        reviewedAt: amende.reviewedAt == null
            ? Value(maintenant)
            : const Value.absent(),
      ),
    );
  }

  /// Total déjà payé (en plusieurs fois ou en une seule) contre cette
  /// amende — voir DECISIONS.md, "Paiement partiel d'une amende".
  Future<int> totalPayeAmendeFcfa(String amendeId) async {
    final rows = await (select(
      amendePaiements,
    )..where((p) => p.amendeId.equals(amendeId))).get();
    return rows.fold<int>(0, (s, p) => s + p.montantFcfa);
  }

  /// Solde restant à payer sur cette amende — jamais négatif même en cas
  /// de trop-perçu (même principe que `LoanBalanceCalculator`).
  Future<int> soldeRestantAmendeFcfa(String amendeId) async {
    final amende = await (select(
      amendes,
    )..where((a) => a.id.equals(amendeId))).getSingle();
    final paye = await totalPayeAmendeFcfa(amendeId);
    final solde = amende.montantFcfa - paye;
    return solde <= 0 ? 0 : solde;
  }

  /// Règle une amende **en partie ou en totalité** — voir DECISIONS.md,
  /// "Paiement partiel d'une amende". Un membre peut s'acquitter de son
  /// amende à tout moment, en plusieurs fois si besoin (contrairement à
  /// [confirmerAmende], qui règle toujours la totalité en un geste).
  /// Marque l'amende `confirmedAt`/`reviewedAt` (comme [confirmerAmende])
  /// dès que le solde atteint 0, quel que soit le nombre de paiements
  /// qui y ont mené.
  Future<String> enregistrerPaiementAmende({
    required String amendeId,
    required int montantFcfa,
    required String recordedByPhone,
    DateTime? recordedAt,
  }) async {
    if (montantFcfa <= 0) {
      throw ArgumentError('Le montant payé doit être positif.');
    }
    final id = _uuid.v4();
    final horodatage = recordedAt ?? AppClock.now();
    final previousHash = await _lastHashOf(amendePaiements.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        amendeId,
        montantFcfa,
        recordedByPhone,
        horodatage.toIso8601String(),
      ],
    );
    await into(amendePaiements).insert(
      AmendePaiementsCompanion.insert(
        id: id,
        amendeId: amendeId,
        montantFcfa: montantFcfa,
        recordedByPhone: recordedByPhone,
        recordedAt: Value(horodatage),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
    if (await soldeRestantAmendeFcfa(amendeId) == 0) {
      await confirmerAmende(amendeId);
    }
    return id;
  }

  /// L'agent confirme une amende auto-générée **telle quelle** — valide
  /// seulement que l'absence est réelle, **n'implique aucun règlement
  /// cash** (voir DECISIONS.md, "Écran Cotisations moins chargé").
  /// L'amende reste "non soldée" (comptera pour la réduction de parts
  /// au partage — voir `AmendeReductionCalculator` — sauf si réglée
  /// cash séparément avant la clôture, via [confirmerAmende]). Ne
  /// réapparaîtra plus dans [amendesEnAttenteRevue].
  Future<void> validerAmendeTelleQuelle(String amendeId) async {
    await (update(amendes)..where((a) => a.id.equals(amendeId))).write(
      AmendesCompanion(reviewedAt: Value(AppClock.now())),
    );
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
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        amendeId,
        raison,
        annuleParPhone,
        annuleAt.toIso8601String(),
      ],
    );
    await into(amendeAnnulations).insert(
      AmendeAnnulationsCompanion.insert(
        id: id,
        amendeId: amendeId,
        raison: raison,
        annuleParPhone: annuleParPhone,
        annuleAt: Value(annuleAt),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
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
    int carnetNumero = 1,
  }) {
    return transaction(() async {
      await annulerAmende(
        amendeId: amendeId,
        raison: raison,
        annuleParPhone: annuleParPhone,
      );
      await enregistrerCotisationCash(
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        carnetNumero: carnetNumero,
        partsCount: partsCount,
        recordedByPhone: annuleParPhone,
        recordedAt: dateReelle,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Catalogue de motifs d'amende par groupe (config, pas une table
  // financière — voir DECISIONS.md, "Catalogue de motifs d'amende").
  // ---------------------------------------------------------------------

  Future<String> creerMotifAmende({
    required String groupId,
    required String libelle,
    required int montantFcfa,
  }) async {
    final id = _uuid.v4();
    await into(motifsAmende).insert(
      MotifsAmendeCompanion.insert(
        id: id,
        groupId: groupId,
        libelle: libelle,
        montantFcfa: montantFcfa,
      ),
    );
    return id;
  }

  /// Renomme et/ou change le montant d'un motif — ne touche jamais aux
  /// amendes déjà enregistrées avec ce motif (voir doc de
  /// [MotifsAmende] : aucune référence vivante entre les deux).
  Future<void> modifierMotifAmende({
    required String motifId,
    required String libelle,
    required int montantFcfa,
  }) async {
    await (update(motifsAmende)..where((m) => m.id.equals(motifId))).write(
      MotifsAmendeCompanion(
        libelle: Value(libelle),
        montantFcfa: Value(montantFcfa),
      ),
    );
  }

  /// Retire (ou remet) un motif du choix proposé pour une nouvelle
  /// amende — jamais une suppression, l'historique n'est pas concerné.
  Future<void> definirActifMotifAmende({
    required String motifId,
    required bool actif,
  }) async {
    await (update(motifsAmende)..where((m) => m.id.equals(motifId))).write(
      MotifsAmendeCompanion(actif: Value(actif)),
    );
  }

  /// Tous les motifs du groupe (actifs et désactivés) — pour l'écran de
  /// gestion, où l'agent doit pouvoir réactiver un motif désactivé par
  /// erreur.
  Future<List<MotifsAmendeData>> motifsAmendeDuGroupe(String groupId) {
    return (select(motifsAmende)
          ..where((m) => m.groupId.equals(groupId))
          ..orderBy([(m) => OrderingTerm.asc(m.libelle)]))
        .get();
  }

  /// Le motif système actif du groupe pour ce `codeSysteme`, ou `null`
  /// si le groupe n'en a pas (groupe migré avant l'introduction du
  /// catalogue de motifs système, schemaVersion 14 — voir DECISIONS.md,
  /// "Motifs d'amende prédéfinis") : un groupe créé depuis en a
  /// toujours un. Base de la clôture de journée interactive (voir
  /// [cloturerJourneeCotisation]).
  Future<MotifsAmendeData?> motifSystemeDuGroupe({
    required String groupId,
    required String codeSysteme,
  }) {
    return (select(motifsAmende)..where(
          (m) =>
              m.groupId.equals(groupId) &
              m.codeSysteme.equals(codeSysteme) &
              m.actif.equals(true),
        ))
        .getSingleOrNull();
  }

  /// Seulement les motifs actifs — pour la liste proposée à la création
  /// d'une nouvelle amende (voir écran Répartition de fin de cycle).
  Future<List<MotifsAmendeData>> motifsAmendeActifsDuGroupe(String groupId) {
    return (select(motifsAmende)
          ..where((m) => m.groupId.equals(groupId) & m.actif.equals(true))
          ..orderBy([(m) => OrderingTerm.asc(m.libelle)]))
        .get();
  }

  /// Dernière ligne [Echeances] connue pour un triplet (membre, carnet,
  /// échéance), ou `null` si aucune n'existe encore.
  ///
  /// **Jamais `getSingleOrNull` sans `limit(1)` sur cette table** — voir
  /// la doc de classe d'[Echeances] : plusieurs lignes par triplet sont
  /// tolérées par construction ("la lecture retient toujours la ligne la
  /// plus récente"), `getSingleOrNull` seul lève une exception dès qu'un
  /// deuxième résultat existe. Le correctif du 2026-08-13 sur
  /// [motifsSystemeApplicables] (voir DECISIONS.md, "Correction de
  /// motifsSystemeApplicables — carnet déjà résolu") a supprimé la
  /// possibilité d'écrire un nouveau doublon, mais un doublon déjà écrit
  /// avant ce correctif — sur un appareil de terrain resté ouvert
  /// plusieurs jours, par exemple — continuait de faire planter
  /// [membresAbsentsPourDate], [carnetsATraiterPourDate] et
  /// [cloturerJourneeCotisation] à chaque lecture, indéfiniment, sur ce
  /// même triplet (retour terrain du 2026-08-14 : la clôture restait
  /// bloquée malgré l'APK déjà corrigé). Ce helper centralise la lecture
  /// tolérante — `orderBy(desc) + limit(1)` garantit au plus un résultat
  /// quel que soit le nombre de lignes réellement présentes, sans jamais
  /// planter et sans avoir besoin de toucher aux données existantes.
  Future<Echeance?> _derniereEcheancePourCarnet({
    required String memberId,
    required String cycleId,
    required int carnetNumero,
    required DateTime echeanceDate,
  }) {
    return (select(echeances)
          ..where(
            (e) =>
                e.memberId.equals(memberId) &
                e.cycleId.equals(cycleId) &
                e.carnetNumero.equals(carnetNumero) &
                e.echeanceDate.equals(echeanceDate),
          )
          ..orderBy([(e) => OrderingTerm.desc(e.recordedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Détermine quels motifs **système** (absence / part impayée / payé
  /// par un tiers) restent applicables pour CE carnet à CETTE échéance,
  /// selon ce qui y est déjà enregistré — voir DECISIONS.md, "Validation
  /// de cohérence des motifs par carnet". Ne concerne jamais les motifs
  /// personnalisés du groupe (`codeSysteme == null`), toujours proposés.
  ///
  /// - Si une ligne [Echeances] existe déjà pour ce (membre, carnet,
  ///   date) — payée, ou déjà résolue par n'importe quel motif système
  ///   (voir [enregistrerEcheanceNonPayee], toujours écrite par
  ///   [resoudreCarnetImmediat] et [cloturerJourneeCotisation]) : aucun
  ///   des 3 motifs système n'est plus applicable. **Vérification
  ///   corrigée le 2026-08-13** (voir RETOURS_TERRAIN.md, point 24) :
  ///   auparavant, seule une cotisation payée ou un motif "payé par un
  ///   tiers" comptaient comme résolus — "Absence" et "Part impayée"
  ///   restaient invisibles à cette fonction, ce qui permettait de
  ///   résoudre deux fois le même carnet et écrivait une deuxième ligne
  ///   [Echeances] pour le même triplet, cassant ensuite toute requête
  ///   `getSingleOrNull` qui en dépend ([cloturerJourneeCotisation],
  ///   [carnetsATraiterPourDate], et le filet de sécurité 23h qui
  ///   appelle [cloturerJourneeCotisation] en interne).
  /// - Sinon (rien enregistré du tout) : les 3 restent possibles, à
  ///   l'agent de choisir celui qui correspond à la réalité.
  ///
  /// Ne tient pas encore compte d'une éventuelle contribution de
  /// solidarité (Groupe B, pas encore construit) — à revoir une fois ce
  /// chantier en place, une solidarité payée sans cotisation pourrait
  /// devenir un signal supplémentaire de présence.
  Future<Set<String>> motifsSystemeApplicables({
    required String memberId,
    required String cycleId,
    required int carnetNumero,
    required DateTime echeanceDate,
  }) async {
    final cotisationExiste =
        (await (select(cotisations)..where(
                  (c) =>
                      c.memberId.equals(memberId) &
                      c.cycleId.equals(cycleId) &
                      c.carnetNumero.equals(carnetNumero) &
                      c.echeanceDate.equals(echeanceDate),
                ))
                .get())
            .isNotEmpty;
    if (cotisationExiste) return {};

    // Toute ligne Echeances déjà écrite pour ce triplet — quel que soit
    // son statut ou le motif système qui l'a produite — signifie que le
    // carnet est déjà réglé pour cette date (voir doc ci-dessus).
    final echeanceExiste =
        (await (select(echeances)..where(
                  (e) =>
                      e.memberId.equals(memberId) &
                      e.cycleId.equals(cycleId) &
                      e.carnetNumero.equals(carnetNumero) &
                      e.echeanceDate.equals(echeanceDate),
                ))
                .get())
            .isNotEmpty;
    if (echeanceExiste) return {};

    final amendesDuCarnet =
        await (select(amendes)..where(
              (a) =>
                  a.memberId.equals(memberId) &
                  a.cycleId.equals(cycleId) &
                  a.carnetNumero.equals(carnetNumero) &
                  a.echeanceDate.equals(echeanceDate),
            ))
            .get();
    final annulees = await _amendesAnnuleesParmi(
      amendesDuCarnet.map((a) => a.id),
    );
    final payeParTiersApplique = amendesDuCarnet.any(
      (a) =>
          !annulees.contains(a.id) &&
          a.motifCodeSysteme == codeSystemePayeParTiers,
    );
    if (payeParTiersApplique) return {};

    return {codeSystemeAbsence, codeSystemePartImpayee, codeSystemePayeParTiers};
  }

  /// Résout **immédiatement** un carnet pour la journée en cours — voir
  /// RETOURS_TERRAIN.md : remplace l'ancienne "présence anticipée" (une
  /// simple intention, jamais définitive avant la clôture) par une
  /// vraie résolution tout de suite, au moment où l'agent choisit
  /// "Absence" / "Part impayée" / "Payé par un tiers" depuis le bouton
  /// "Ajouter amende" pendant la réunion. Écrit exactement ce que
  /// [cloturerJourneeCotisation] aurait écrit pour ce carnet à la
  /// clôture — l'amende (si le motif a un montant configuré) et
  /// l'échéance `non_paye` qui la référence — mais tout de suite. Le
  /// carnet ainsi résolu n'apparaît plus dans [carnetsATraiterPourDate]
  /// : la clôture n'a plus rien à demander pour lui (voir
  /// [motifsSystemeApplicables]).
  ///
  /// Comme l'amende auto-générée à la clôture, ne demande pas
  /// immédiatement le mode de paiement (voir [validerAmendeTelleQuelle])
  /// — reste payable en cash à tout moment ensuite depuis la fiche
  /// membre ou l'écran Amendes.
  ///
  /// Lève `StateError` si ce carnet est déjà résolu pour cette date
  /// (déjà payé, ou déjà traité par un motif système incompatible —
  /// voir [motifsSystemeApplicables]).
  Future<String?> resoudreCarnetImmediat({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int carnetNumero,
    required DateTime date,
    required String codeSysteme,
    required String agentPhone,
  }) {
    return transaction(() async {
      final cycle = await (select(
        cycles,
      )..where((c) => c.id.equals(cycleId))).getSingle();
      final motifsPossibles = await motifsSystemeApplicables(
        memberId: memberId,
        cycleId: cycleId,
        carnetNumero: carnetNumero,
        echeanceDate: date,
      );
      if (!motifsPossibles.contains(codeSysteme)) {
        throw StateError(
          'Ce carnet est déjà réglé ou déjà résolu pour cette date.',
        );
      }
      final resolu = await _resolutionMotifSysteme(
        groupId: groupId,
        cycle: cycle,
        codeSysteme: codeSysteme,
      );
      String? amendeId;
      if (resolu.montantFcfa > 0) {
        amendeId = await enregistrerAmende(
          groupId: groupId,
          cycleId: cycleId,
          memberId: memberId,
          carnetNumero: carnetNumero,
          echeanceDate: date,
          montantFcfa: resolu.montantFcfa,
          motif: resolu.libelle,
          motifCodeSysteme: codeSysteme,
          recordedByPhone: agentPhone,
          // `estAutoGeneree` = "issue de la résolution par motif système"
          // (comme à la clôture), pas "sans intervention humaine" —
          // l'agent choisit activement le carnet et le motif ici. Garde
          // la cohérence avec cloturerJourneeCotisation : mêmes filtres
          // (amendesAutoDuMembre) et même correction possible ensuite
          // (bouton "Erreur", voir corrigerAmendeErreur).
          estAutoGeneree: true,
          recordedAt: date,
        );
        // Comme à la clôture : choisi interactivement par l'agent, jamais
        // "en attente de revue" (voir DECISIONS.md, "Clôture de journée
        // interactive").
        await validerAmendeTelleQuelle(amendeId);
      }
      await enregistrerEcheanceNonPayee(
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        carnetNumero: carnetNumero,
        echeanceDate: date,
        montantDuFcfa: cycle.partValueFcfa,
        recordedByPhone: agentPhone,
        amendeId: amendeId,
        amendeFcfa: resolu.montantFcfa,
      );
      return amendeId;
    });
  }

  // ---------------------------------------------------------------------
  // Échéances (ajout seul) — registre payé/non payé par membre et par
  // date, base de l'historique groupé par date (voir DECISIONS.md,
  // "Historique des cotisations").
  // ---------------------------------------------------------------------

  /// Toutes les lignes déjà enregistrées (payées ou non, y compris les
  /// lignes remplacées) pour un membre sur un cycle, tous carnets
  /// confondus — utilisé pour savoir quelles (carnet, date) ont déjà une
  /// trace (idempotence de [cloturerJourneeCotisation]).
  Future<List<Echeance>> echeancesDuMembre({
    required String memberId,
    required String cycleId,
  }) {
    return (select(echeances)..where(
          (e) => e.memberId.equals(memberId) & e.cycleId.equals(cycleId),
        ))
        .get();
  }

  /// Enregistre une échéance close et non couverte comme `non_paye`, pour
  /// UN carnet précis — une nouvelle ligne, jamais une modification d'une
  /// ligne existante (même principe que les autres tables financières en
  /// ajout seul). Définitif : aucun mécanisme ne permet plus de la
  /// rattraper ensuite (voir DECISIONS.md, "Amende seule, jamais de
  /// rattrapage") — seule l'amende liée compte.
  Future<void> enregistrerEcheanceNonPayee({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int carnetNumero,
    required DateTime echeanceDate,
    required int montantDuFcfa,
    required String recordedByPhone,
    String? amendeId,
    int amendeFcfa = 0,
  }) async {
    final id = _uuid.v4();
    final horodatage = AppClock.now();
    final previousHash = await _lastHashOf(echeances.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        cycleId,
        memberId,
        carnetNumero,
        echeanceDate.toIso8601String(),
        montantDuFcfa,
        0,
        0,
        amendeFcfa,
        'non_paye',
        recordedByPhone,
        horodatage.toIso8601String(),
      ],
    );
    await into(echeances).insert(
      EcheancesCompanion.insert(
        id: id,
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        carnetNumero: Value(carnetNumero),
        echeanceDate: echeanceDate,
        montantDuFcfa: montantDuFcfa,
        montantPayeFcfa: const Value(0),
        partsPayees: const Value(0),
        amendeFcfa: Value(amendeFcfa),
        statut: 'non_paye',
        amendeId: Value(amendeId),
        recordedByPhone: recordedByPhone,
        recordedAt: Value(horodatage),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
  }

  /// Enregistre le total de parts payées pour UN carnet, à UNE date —
  /// appelé par [_enregistrerCotisationCarnet]. [partsPayees] est le
  /// **total cumulé de la journée** (pas seulement cette transaction) :
  /// une nouvelle ligne `paye` qui remplace la précédente si le membre
  /// complète son paiement en plusieurs fois le même jour (voir
  /// DECISIONS.md, "Plafond de 5 parts par carnet et par jour"). Jamais
  /// une correction sur place — la lecture ([echeancesGroupeesParDate])
  /// retient toujours la plus récente pour un même triplet (membre,
  /// carnet, date).
  Future<void> _enregistrerEcheancePayee({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int carnetNumero,
    required DateTime echeanceDate,
    required int valeurPartFcfa,
    required int partsPayees,
    required String cotisationId,
    required String recordedByPhone,
  }) async {
    final id = _uuid.v4();
    final horodatage = AppClock.now();
    final montantPayeFcfa = partsPayees * valeurPartFcfa;
    final previousHash = await _lastHashOf(echeances.tableName);
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        cycleId,
        memberId,
        carnetNumero,
        echeanceDate.toIso8601String(),
        valeurPartFcfa,
        montantPayeFcfa,
        partsPayees,
        0,
        'paye',
        recordedByPhone,
        horodatage.toIso8601String(),
      ],
    );
    await into(echeances).insert(
      EcheancesCompanion.insert(
        id: id,
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        carnetNumero: Value(carnetNumero),
        echeanceDate: echeanceDate,
        montantDuFcfa: valeurPartFcfa,
        montantPayeFcfa: Value(montantPayeFcfa),
        partsPayees: Value(partsPayees),
        amendeFcfa: const Value(0),
        statut: 'paye',
        cotisationId: Value(cotisationId),
        recordedByPhone: recordedByPhone,
        recordedAt: Value(horodatage),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
  }

  /// État le plus récent de chaque échéance (une par triplet
  /// membre/carnet/date) pour un cycle — une échéance d'abord `non_paye`
  /// puis régularisée apparaît deux fois en base, seule la plus récente
  /// fait foi ici.
  Future<List<Echeance>> _echeancesResoluesDuCycle(String cycleId) async {
    final toutes =
        await (select(echeances)
              ..where((e) => e.cycleId.equals(cycleId))
              ..orderBy([(e) => OrderingTerm.asc(e.recordedAt)]))
            .get();
    final parCle = <String, Echeance>{};
    for (final e in toutes) {
      parCle['${e.memberId}|${e.carnetNumero}|${e.echeanceDate.toIso8601String()}'] =
          e;
    }
    return parCle.values.toList();
  }

  /// Historique des cotisations groupé par date d'échéance (la plus
  /// récente d'abord) — chaque groupe contient l'état résolu le plus
  /// récent de chaque (membre, carnet) pour cette date (payé ou non).
  /// Voir la demande du fondateur, "Historique des cotisations".
  Future<List<EcheanceGroupeeParDate>> echeancesGroupeesParDate(
    String cycleId,
  ) async {
    final resolues = await _echeancesResoluesDuCycle(cycleId);
    final parDate = <DateTime, List<Echeance>>{};
    for (final e in resolues) {
      parDate.putIfAbsent(e.echeanceDate, () => []).add(e);
    }
    final dates = parDate.keys.toList()..sort((a, b) => b.compareTo(a));
    return dates
        .map((d) => EcheanceGroupeeParDate(date: d, lignes: parDate[d]!))
        .toList();
  }

  /// État résolu (le plus récent par triplet membre/carnet) pour UNE
  /// seule date — utilisé pour la vue "encaissements de la journée en
  /// cours" sur l'écran Cotisations (voir DECISIONS.md) : les
  /// paiements apparaissent au fur et à mesure qu'ils sont enregistrés,
  /// avant même que la journée soit clôturée (les échéances non
  /// couvertes, elles, n'apparaissent qu'à la clôture).
  Future<List<Echeance>> echeancesResoluesPourDate({
    required String cycleId,
    required DateTime date,
  }) async {
    final resolues = await _echeancesResoluesDuCycle(cycleId);
    return resolues.where((e) => e.echeanceDate == date).toList();
  }

  /// Amendes non soldées d'un membre sur un cycle : ni confirmées par
  /// l'agent, ni annulées. Base de la fusion cotisation + amende (voir
  /// [enregistrerEncaissementMembre]) et du calcul de dette au partage
  /// (voir [detteMembreFcfa]).
  Future<List<Amende>> amendesNonSoldeesDuMembre({
    required String memberId,
    required String cycleId,
  }) async {
    final mesAmendes = await amendesDuMembre(memberId, cycleId);
    final enAttente = mesAmendes.where((a) => a.confirmedAt == null).toList();
    if (enAttente.isEmpty) return [];
    final annulees = await _amendesAnnuleesParmi(enAttente.map((a) => a.id));
    return enAttente.where((a) => !annulees.contains(a.id)).toList();
  }

  /// Somme des **soldes restants** des amendes non confirmées d'un
  /// membre — pas leur montant brut d'origine : une amende déjà
  /// partiellement payée (voir DECISIONS.md, "Paiement partiel d'une
  /// amende") ne compte plus que pour ce qu'il en reste à payer.
  Future<int> montantAmendesNonSoldeesFcfa({
    required String memberId,
    required String cycleId,
  }) async {
    final nonSoldees = await amendesNonSoldeesDuMembre(
      memberId: memberId,
      cycleId: cycleId,
    );
    var total = 0;
    for (final a in nonSoldees) {
      total += await soldeRestantAmendeFcfa(a.id);
    }
    return total;
  }

  /// Statut de chaque amende d'un cycle : `reglee` (confirmée par
  /// l'agent, ou soldée automatiquement par un encaissement),
  /// `en_attente` (ni réglée ni annulée) ou `annulee` (erreur — voir
  /// [corrigerAmendeErreur]). Utilisé par l'écran Historique pour
  /// afficher ce statut à côté de chaque échéance concernée (voir
  /// DECISIONS.md, "Visibilité du statut d'une amende").
  Future<Map<String, String>> statutsAmendes(String cycleId) async {
    final toutes = await (select(
      amendes,
    )..where((a) => a.cycleId.equals(cycleId))).get();
    if (toutes.isEmpty) return {};
    final annuleesIds = await _amendesAnnuleesParmi(toutes.map((a) => a.id));
    return {
      for (final a in toutes)
        a.id: annuleesIds.contains(a.id)
            ? 'annulee'
            : (a.confirmedAt != null ? 'reglee' : 'en_attente'),
    };
  }

  /// Somme des parts déjà enregistrées pour CE carnet, pour la même
  /// échéance que [jour] — base du plafond cumulatif journalier (voir
  /// [EcheanceCalculator.maxPartsParTransaction] et DECISIONS.md,
  /// "Plafond de 5 parts par carnet et par jour"). Se base sur
  /// [Cotisations.echeanceDate] (la journée de cotisation visée), pas
  /// sur [Cotisations.recordedAt] (l'horodatage réel/simulé de la
  /// saisie) : un agent peut saisir plusieurs transactions pour la même
  /// échéance à des instants réels différents, et ne doit jamais
  /// mélanger deux échéances différentes saisies le même jour réel (voir
  /// DECISIONS.md, "Le plafond journalier se base sur l'échéance, pas
  /// sur l'heure de saisie").
  Future<int> partsDejaAjouteesAujourdhui({
    required String memberId,
    required String cycleId,
    required int carnetNumero,
    required DateTime jour,
  }) async {
    final echeance = DateTime(jour.year, jour.month, jour.day);
    final rows =
        await (select(cotisations)..where(
              (c) =>
                  c.memberId.equals(memberId) &
                  c.cycleId.equals(cycleId) &
                  c.carnetNumero.equals(carnetNumero) &
                  c.echeanceDate.equals(echeance),
            ))
            .get();
    return rows.fold<int>(0, (s, c) => s + c.partsCount);
  }

  /// Écrit la cotisation d'UN carnet pour la journée [dateEcheance] — le
  /// nombre de parts payées ce jour-là est **cumulé** avec ce qui a déjà
  /// été enregistré aujourd'hui pour ce carnet (jamais un rattrapage
  /// d'une autre date : voir DECISIONS.md, "Amende seule, jamais de
  /// rattrapage"). Écrit toujours exactement une ligne [Echeances]
  /// `paye` à jour du total du jour, garantissant qu'un paiement
  /// enregistré n'est jamais invisible dans les vues par date.
  ///
  /// Le plafond de 5 parts s'applique **au cumul de la journée**, pas
  /// seulement à cette transaction : si l'agent a déjà enregistré 3
  /// parts pour ce carnet plus tôt le même jour, il ne peut plus en
  /// ajouter que 2 de plus (règle confirmée par le fondateur, voir
  /// DECISIONS.md).
  Future<String> _enregistrerCotisationCarnet({
    required String groupId,
    required String cycleId,
    required String memberId,
    required int carnetNumero,
    required int partsAPayer,
    required DateTime dateEcheance,
    required String recordedByPhone,
  }) async {
    final dejaAjoutees = await partsDejaAjouteesAujourdhui(
      memberId: memberId,
      cycleId: cycleId,
      carnetNumero: carnetNumero,
      jour: dateEcheance,
    );
    if (dejaAjoutees + partsAPayer >
        EcheanceCalculator.maxPartsParTransaction) {
      throw ArgumentError(
        'Le total des parts pour ce carnet ne peut pas dépasser '
        '${EcheanceCalculator.maxPartsParTransaction} par jour '
        '($dejaAjoutees déjà enregistrée(s) aujourd\'hui).',
      );
    }

    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();

    final cotisationId = await enregistrerCotisationCash(
      groupId: groupId,
      cycleId: cycleId,
      memberId: memberId,
      carnetNumero: carnetNumero,
      partsCount: partsAPayer,
      recordedByPhone: recordedByPhone,
      recordedAt: AppClock.now(),
      echeanceDate: dateEcheance,
    );

    await _enregistrerEcheancePayee(
      groupId: groupId,
      cycleId: cycleId,
      memberId: memberId,
      carnetNumero: carnetNumero,
      echeanceDate: dateEcheance,
      valeurPartFcfa: cycle.partValueFcfa,
      partsPayees: dejaAjoutees + partsAPayer,
      cotisationId: cotisationId,
      recordedByPhone: recordedByPhone,
    );

    return cotisationId;
  }

  /// Encaissement du jour pour un membre : pour chacun de ses carnets, le
  /// nombre de parts choisi (clé = numéro de carnet 1 ou 2, valeur =
  /// parts à déposer dans CE carnet cette fois — absent ou 0 pour ne
  /// rien déposer dans ce carnet). Ne touche **jamais** aux amendes du
  /// membre — les régler est un geste séparé et explicite
  /// ([confirmerAmende], depuis la section "Amendes en attente" de
  /// l'écran Cotisations), même si le membre paie les deux le même jour
  /// (voir DECISIONS.md, "Une amende ne se règle plus jamais
  /// automatiquement" — annule la fusion automatique du 7 août). [date]
  /// est la journée de cotisation ouverte visée — par défaut celle
  /// renvoyée par [journeeCotisationEnAttente] ; refuse si aucune
  /// journée n'est ouverte (voir DECISIONS.md, "La saisie de cotisation
  /// est bloquée entre deux dates de paiement").
  Future<List<String>> enregistrerEncaissementMembre({
    required String groupId,
    required String cycleId,
    required String memberId,
    required Map<int, int> partsParCarnet,
    required String recordedByPhone,
    DateTime? date,
  }) {
    return transaction(() async {
      final dateEcheance =
          date ??
          await journeeCotisationEnAttente(groupId: groupId, cycleId: cycleId);
      if (dateEcheance == null) {
        throw StateError(
          'Aucune journée de cotisation ouverte pour le moment.',
        );
      }
      final cotisationIds = <String>[];
      for (final entry in partsParCarnet.entries) {
        final parts = entry.value;
        if (parts <= 0) continue;
        final cotisationId = await _enregistrerCotisationCarnet(
          groupId: groupId,
          cycleId: cycleId,
          memberId: memberId,
          carnetNumero: entry.key,
          partsAPayer: parts,
          dateEcheance: dateEcheance,
          recordedByPhone: recordedByPhone,
        );
        cotisationIds.add(cotisationId);
      }

      return cotisationIds;
    });
  }

  // ---------------------------------------------------------------------
  // Clôture de la journée de cotisation (voir DECISIONS.md, "Clôture de
  // la journée de cotisation") — l'agent décide explicitement qu'une
  // date de collecte est terminée ; ce geste fige qui a payé et qui est
  // absent, remplace l'ancienne détection automatique basée sur
  // l'horloge.
  // ---------------------------------------------------------------------

  /// Date de la plus ancienne échéance déjà passée mais pas encore
  /// clôturée, ou null si tout est à jour (ou si aucune échéance n'est
  /// encore due). Un pur constat, sans effet de bord — jamais de
  /// clôture automatique ici (voir
  /// [journeeCotisationEnAttenteEtAutoClotureSiDepassee] pour le filet
  /// de sécurité qui, lui, peut clôturer).
  Future<DateTime?> journeeCotisationEnAttente({
    required String groupId,
    required String cycleId,
    DateTime? maintenant,
  }) async {
    final now = maintenant ?? AppClock.now();
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();
    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(groupId))).getSingle();
    List<DateTime> echeances;
    try {
      echeances = const EcheanceCalculator().echeancesPassees(
        debutCycle: cycle.startedAt,
        meetingFrequency: groupe.meetingFrequency,
        paymentDayOfWeek: groupe.paymentDayOfWeek,
        paymentDayOfMonth1: groupe.paymentDayOfMonth1,
        paymentDayOfMonth2: groupe.paymentDayOfMonth2,
        maintenant: now,
      );
    } on ArgumentError {
      return null;
    }
    if (echeances.isEmpty) return null;
    final clotureesRows = await (select(
      seancesCotisation,
    )..where((s) => s.cycleId.equals(cycleId))).get();
    final clotureesDates = clotureesRows.map((s) => s.date).toSet();
    for (final date in echeances) {
      if (!clotureesDates.contains(date)) return date;
    }
    return null;
  }

  /// Filet de sécurité (voir RETOURS_TERRAIN.md) : si le fondateur ne
  /// parvient pas à identifier ce qui empêche le bouton "Clôturer
  /// cette journée" de s'activer, la journée resterait bloquée
  /// indéfiniment sans ce filet — ici, une journée ouverte dont la
  /// date a dépassé 23h se clôture automatiquement, sans attendre le
  /// geste de l'agent, à la prochaine fois que l'app vérifie l'état de
  /// la journée en cours. Boucle pour rattraper plusieurs journées
  /// d'affilée si l'app est restée fermée plusieurs jours.
  ///
  /// Réutilise la présence anticipée déjà saisie depuis "Séance du
  /// jour" s'il y en a (voir [presenceAnticipeeDuJour]), sinon
  /// "Absence" par défaut — exactement comme une clôture manuelle sans
  /// résolutions explicites.
  ///
  /// Appelée par les écrans qui affichent la journée ouverte
  /// (`record_cotisation_screen.dart`, `seance_jour_screen.dart`) —
  /// jamais par [journeeCotisationEnAttente] elle-même, qui reste un
  /// pur constat sans effet de bord.
  Future<DateTime?> journeeCotisationEnAttenteEtAutoClotureSiDepassee({
    required String groupId,
    required String cycleId,
    required String agentPhone,
  }) async {
    while (true) {
      final date = await journeeCotisationEnAttente(
        groupId: groupId,
        cycleId: cycleId,
      );
      if (date == null) return null;
      final seuil = DateTime(date.year, date.month, date.day, 23);
      if (!AppClock.now().isAfter(seuil)) return date;

      final anticipees = await presenceAnticipeeDuJour(
        cycleId: cycleId,
        date: date,
      );
      await cloturerJourneeCotisation(
        groupId: groupId,
        cycleId: cycleId,
        date: date,
        agentPhone: agentPhone,
        resolutions: anticipees,
      );
      // Boucle : re-vérifie si la journée suivante est, elle aussi,
      // déjà en retard.
    }
  }

  /// Dernière séance clôturée d'un cycle (la plus récente par date), ou
  /// null s'il n'y en a aucune — sert à proposer "Annuler la clôture"
  /// juste après coup, voir [annulerClotureJournee].
  Future<SeancesCotisationData?> derniereSeanceCloturee(String cycleId) {
    return (select(seancesCotisation)
          ..where((s) => s.cycleId.equals(cycleId))
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Prévisualisation en lecture seule de ce que
  /// [cloturerJourneeCotisation] s'apprête à faire : les membres déjà
  /// inscrits à cette date qui ont au moins un carnet sans paiement
  /// enregistré pour elle — donc qui écoperont d'une amende (si le
  /// groupe en a configuré une) une fois la clôture confirmée. N'écrit
  /// rien en base — sert à afficher la liste nominative à l'agent avant
  /// qu'il ne valide la clôture définitive (voir DECISIONS.md, "Message
  /// de confirmation avant clôture définitive").
  Future<List<Member>> membresAbsentsPourDate({
    required String groupId,
    required String cycleId,
    required DateTime date,
  }) async {
    final membresGroupe = await membresDuGroupe(groupId);
    final resultat = <Member>[];
    for (final membre in membresGroupe) {
      if (membre.joinedAt.isAfter(date)) continue;
      final carnets = await carnetsEngagesDuMembre(
        memberId: membre.id,
        cycleId: cycleId,
      );
      if (carnets == null) continue;

      for (
        var carnetNumero = 1;
        carnetNumero <= carnets.nombreCarnets;
        carnetNumero++
      ) {
        final existante = await _derniereEcheancePourCarnet(
          memberId: membre.id,
          cycleId: cycleId,
          carnetNumero: carnetNumero,
          echeanceDate: date,
        );
        if (existante == null) {
          resultat.add(membre);
          break; // une seule entrée par membre, même si plusieurs carnets manquent
        }
      }
    }
    return resultat;
  }

  /// Clé utilisée dans `resolutions` (voir [cloturerJourneeCotisation])
  /// pour désigner un carnet précis d'un membre — partagée entre la
  /// base et l'écran pour ne jamais désynchroniser le format.
  static String clefResolutionCarnet(String memberId, int carnetNumero) =>
      '$memberId::$carnetNumero';

  /// Carnets qui n'ont **encore rien** d'enregistré pour cette date (ni
  /// cotisation, ni amende) — voir DECISIONS.md, "Clôture de journée
  /// interactive". Granularité carnet, pas membre (contrairement à
  /// [membresAbsentsPourDate]) : sert à construire l'écran de
  /// résolution avant clôture, un choix par carnet parmi les 3 motifs
  /// système encore possibles pour lui (voir [motifsSystemeApplicables]
  /// — un carnet où l'agent a déjà enregistré manuellement une amende
  /// pendant la journée, ex. "Payé par un tiers", n'apparaît plus ici).
  Future<List<({Member membre, int carnetNumero, Set<String> motifsPossibles})>>
  carnetsATraiterPourDate({
    required String groupId,
    required String cycleId,
    required DateTime date,
  }) async {
    final membresGroupe = await membresDuGroupe(groupId);
    final resultat =
        <({Member membre, int carnetNumero, Set<String> motifsPossibles})>[];
    for (final membre in membresGroupe) {
      if (membre.joinedAt.isAfter(date)) continue;
      final carnets = await carnetsEngagesDuMembre(
        memberId: membre.id,
        cycleId: cycleId,
      );
      if (carnets == null) continue;

      for (
        var carnetNumero = 1;
        carnetNumero <= carnets.nombreCarnets;
        carnetNumero++
      ) {
        final existante = await _derniereEcheancePourCarnet(
          memberId: membre.id,
          cycleId: cycleId,
          carnetNumero: carnetNumero,
          echeanceDate: date,
        );
        if (existante != null) continue;

        final motifs = await motifsSystemeApplicables(
          memberId: membre.id,
          cycleId: cycleId,
          carnetNumero: carnetNumero,
          echeanceDate: date,
        );
        if (motifs.isEmpty) continue;
        resultat.add((
          membre: membre,
          carnetNumero: carnetNumero,
          motifsPossibles: motifs,
        ));
      }
    }
    return resultat;
  }

  /// Libellé par défaut d'un motif système — utilisé seulement pour un
  /// groupe migré sans catalogue de motifs (voir [motifSystemeDuGroupe]).
  String _libelleMotifSystemeParDefaut(String codeSysteme) {
    switch (codeSysteme) {
      case codeSystemePartImpayee:
        return 'Part impayée';
      case codeSystemePayeParTiers:
        return 'Payé par un tiers';
      case codeSystemeAbsence:
      default:
        return 'Absence';
    }
  }

  /// Montant et libellé à appliquer pour un motif système choisi à la
  /// clôture — toujours le catalogue de motifs du groupe (voir
  /// DECISIONS.md, "Motifs d'amende prédéfinis").
  ///
  /// `Cycles.lateFeeFcfa` ("Amende de retard de cotisation") a existé
  /// avant le catalogue et faisait doublon avec le motif "Absence",
  /// avec une règle de priorité peu lisible sur le terrain (voir
  /// RETOURS_TERRAIN.md, point 4) — retiré des écrans Création/Édition
  /// groupe, ne compte plus ici. La colonne reste en base (migration,
  /// jamais supprimée) et sert uniquement de dernier recours pour un
  /// groupe migré sans catalogue (avant schemaVersion 14), où elle
  /// vaut de toute façon le montant historique déjà en place.
  Future<({int montantFcfa, String libelle})> _resolutionMotifSysteme({
    required String groupId,
    required Cycle cycle,
    required String codeSysteme,
  }) async {
    final motif = await motifSystemeDuGroupe(
      groupId: groupId,
      codeSysteme: codeSysteme,
    );
    if (motif != null) {
      return (montantFcfa: motif.montantFcfa, libelle: motif.libelle);
    }
    return (
      montantFcfa: cycle.lateFeeFcfa,
      libelle: _libelleMotifSystemeParDefaut(codeSysteme),
    );
  }

  /// La plus récente amende non annulée déjà enregistrée pour ce
  /// carnet à cette échéance — utilisé à la clôture quand le carnet a
  /// déjà été résolu manuellement pendant la journée (voir
  /// [carnetsATraiterPourDate]) : relie l'échéance à cette amende
  /// plutôt que d'en créer une nouvelle en double.
  Future<Amende?> _derniereAmendeNonAnnulee({
    required String memberId,
    required String cycleId,
    required int carnetNumero,
    required DateTime echeanceDate,
  }) async {
    final candidates =
        await (select(amendes)
              ..where(
                (a) =>
                    a.memberId.equals(memberId) &
                    a.cycleId.equals(cycleId) &
                    a.carnetNumero.equals(carnetNumero) &
                    a.echeanceDate.equals(echeanceDate),
              )
              ..orderBy([(a) => OrderingTerm.desc(a.recordedAt)]))
            .get();
    if (candidates.isEmpty) return null;
    final annulees = await _amendesAnnuleesParmi(candidates.map((a) => a.id));
    for (final a in candidates) {
      if (!annulees.contains(a.id)) return a;
    }
    return null;
  }

  /// Clôture explicitement une journée de cotisation : pour chaque
  /// membre déjà inscrit à cette date, pour chacun de ses carnets sans
  /// paiement enregistré ce jour-là, trace une ligne [Echeances]
  /// `non_paye` et applique une amende — **une amende par carnet
  /// concerné**, jamais partagée entre les carnets d'un même membre
  /// (voir DECISIONS.md, "Amende par carnet, pas par membre"). Si c'est
  /// la toute première séance clôturée du cycle, trace la date
  /// ([Cycles.inscriptionsFermeesAt]) à titre purement informatif —
  /// **ne ferme plus les inscriptions** depuis DECISIONS.md,
  /// "Inscription de nouveaux membres : sans limite, sauf fin de
  /// cycle" (voir [ajouterMembre] pour la vraie règle de fermeture,
  /// basée sur les réunions restantes avant la fin du cycle).
  ///
  /// [resolutions] : le motif système (voir [codeSystemeAbsence] et
  /// consorts) choisi par l'agent pour chaque carnet sans rien
  /// d'enregistré (voir [carnetsATraiterPourDate],
  /// [clefResolutionCarnet]) — DECISIONS.md, "Clôture de journée
  /// interactive" : résolu **le jour même**, plus jamais différé à la
  /// séance suivante. Un carnet non présent dans [resolutions] retombe
  /// sur "Absence" (comportement historique, préservé pour les appels
  /// qui n'utilisent pas encore l'écran de résolution interactif — ex.
  /// import, tests). Un carnet déjà résolu manuellement pendant la
  /// journée (ex. "Payé par un tiers" ajouté via "Ajouter une amende")
  /// n'a besoin d'aucune résolution : son amende existante est reliée
  /// à l'échéance plutôt que dupliquée.
  Future<void> cloturerJourneeCotisation({
    required String groupId,
    required String cycleId,
    required DateTime date,
    required String agentPhone,
    Map<String, String> resolutions = const {},
  }) {
    return transaction(() async {
      final cycle = await (select(
        cycles,
      )..where((c) => c.id.equals(cycleId))).getSingle();
      final dejaCloturee =
          await (select(seancesCotisation)
                ..where((s) => s.cycleId.equals(cycleId) & s.date.equals(date)))
              .getSingleOrNull();
      if (dejaCloturee != null) {
        throw StateError('Cette journée de cotisation est déjà clôturée.');
      }

      final membresGroupe = await membresDuGroupe(groupId);
      for (final membre in membresGroupe) {
        if (membre.joinedAt.isAfter(date))
          continue; // pas encore membre à cette date
        final carnets = await carnetsEngagesDuMembre(
          memberId: membre.id,
          cycleId: cycleId,
        );
        if (carnets == null) continue;

        for (
          var carnetNumero = 1;
          carnetNumero <= carnets.nombreCarnets;
          carnetNumero++
        ) {
          final existante = await _derniereEcheancePourCarnet(
            memberId: membre.id,
            cycleId: cycleId,
            carnetNumero: carnetNumero,
            echeanceDate: date,
          );
          if (existante != null)
            continue; // déjà payé ou déjà tracé pour cette date

          String? amendeId;
          var amendeMontant = 0;
          final motifsRestants = await motifsSystemeApplicables(
            memberId: membre.id,
            cycleId: cycleId,
            carnetNumero: carnetNumero,
            echeanceDate: date,
          );
          if (motifsRestants.isEmpty) {
            // Déjà résolu manuellement pendant la journée — relie
            // l'échéance à l'amende existante plutôt que d'en créer
            // une nouvelle (voir [_derniereAmendeNonAnnulee]).
            final existanteAmende = await _derniereAmendeNonAnnulee(
              memberId: membre.id,
              cycleId: cycleId,
              carnetNumero: carnetNumero,
              echeanceDate: date,
            );
            if (existanteAmende != null) {
              amendeId = existanteAmende.id;
              amendeMontant = existanteAmende.montantFcfa;
            }
          } else {
            final choix =
                resolutions[clefResolutionCarnet(membre.id, carnetNumero)] ??
                codeSystemeAbsence;
            final resolu = await _resolutionMotifSysteme(
              groupId: groupId,
              cycle: cycle,
              codeSysteme: choix,
            );
            if (resolu.montantFcfa > 0) {
              amendeId = await enregistrerAmende(
                groupId: groupId,
                cycleId: cycleId,
                memberId: membre.id,
                carnetNumero: carnetNumero,
                echeanceDate: date,
                montantFcfa: resolu.montantFcfa,
                motif: resolu.libelle,
                motifCodeSysteme: choix,
                recordedByPhone: agentPhone,
                estAutoGeneree: true,
                recordedAt: date,
              );
              // Choisi interactivement par l'agent au moment même de la
              // clôture : jamais "en attente de revue" à la séance
              // suivante (voir DECISIONS.md, "Clôture de journée
              // interactive").
              await validerAmendeTelleQuelle(amendeId);
              amendeMontant = resolu.montantFcfa;
            }
          }

          // Définitif : cette échéance ne sera plus jamais rattrapable
          // (voir DECISIONS.md, "Amende seule, jamais de rattrapage") —
          // seule l'amende compte, aucun arriéré n'est calculé.
          await enregistrerEcheanceNonPayee(
            groupId: groupId,
            cycleId: cycleId,
            memberId: membre.id,
            carnetNumero: carnetNumero,
            echeanceDate: date,
            montantDuFcfa: cycle.partValueFcfa,
            recordedByPhone: agentPhone,
            amendeId: amendeId,
            amendeFcfa: amendeMontant,
          );
        }
      }

      final id = _uuid.v4();
      final clotureeAt = AppClock.now();
      final previousHash = await _lastHashOf(seancesCotisation.tableName);
      final hash = HashChain.compute(
        previousHash: previousHash,
        fields: [
          id,
          groupId,
          cycleId,
          date.toIso8601String(),
          agentPhone,
          clotureeAt.toIso8601String(),
        ],
      );
      await into(seancesCotisation).insert(
        SeancesCotisationCompanion.insert(
          id: id,
          groupId: groupId,
          cycleId: cycleId,
          date: date,
          clotureeParPhone: agentPhone,
          clotureeAt: Value(clotureeAt),
          previousHash: Value(previousHash),
          hash: hash,
        ),
      );

      // Toute première séance clôturée du cycle -> ferme les inscriptions.
      if (cycle.inscriptionsFermeesAt == null) {
        final seancesDejaClotureesAvant =
            await (select(seancesCotisation)..where(
                  (s) =>
                      s.cycleId.equals(cycleId) &
                      s.date.isSmallerThanValue(date),
                ))
                .get();
        if (seancesDejaClotureesAvant.isEmpty) {
          await (update(cycles)..where((c) => c.id.equals(cycleId))).write(
            CyclesCompanion(inscriptionsFermeesAt: Value(clotureeAt)),
          );
        }
      }

      // Ménage : la présence anticipée de cette date n'a plus de sens
      // une fois la journée clôturée (voir [marquerPresenceAnticipee]).
      await (delete(presenceAnticipee)..where(
            (p) => p.cycleId.equals(cycleId) & p.echeanceDate.equals(date),
          ))
          .go();
    });
  }

  /// Enregistre l'intention de l'agent pour un membre absent, saisie
  /// **pendant** la journée depuis l'écran "Séance du jour" — voir
  /// RETOURS_TERRAIN.md, point 6, et la doc de [PresenceAnticipee]. Ne
  /// crée ni amende ni échéance ([cloturerJourneeCotisation] reste seul
  /// à écrire quoi que ce soit de définitif) : applique [codeSysteme] à
  /// chacun des carnets du membre encore "à traiter" pour [date] (les
  /// autres — déjà payés, ou déjà résolus manuellement pendant la
  /// journée — sont ignorés, cohérent avec [carnetsATraiterPourDate]).
  Future<void> marquerPresenceAnticipee({
    required String groupId,
    required String cycleId,
    required String memberId,
    required DateTime date,
    required String codeSysteme,
    required String agentPhone,
  }) async {
    final carnets = await carnetsEngagesDuMembre(
      memberId: memberId,
      cycleId: cycleId,
    );
    if (carnets == null) return;
    final maintenant = AppClock.now();
    await transaction(() async {
      for (
        var carnetNumero = 1;
        carnetNumero <= carnets.nombreCarnets;
        carnetNumero++
      ) {
        final motifs = await motifsSystemeApplicables(
          memberId: memberId,
          cycleId: cycleId,
          carnetNumero: carnetNumero,
          echeanceDate: date,
        );
        if (motifs.isEmpty) continue; // déjà résolu (payé ou amende posée)
        await (delete(presenceAnticipee)..where(
              (p) =>
                  p.cycleId.equals(cycleId) &
                  p.memberId.equals(memberId) &
                  p.carnetNumero.equals(carnetNumero) &
                  p.echeanceDate.equals(date),
            ))
            .go();
        await into(presenceAnticipee).insert(
          PresenceAnticipeeCompanion.insert(
            id: _uuid.v4(),
            groupId: groupId,
            cycleId: cycleId,
            memberId: memberId,
            carnetNumero: carnetNumero,
            echeanceDate: date,
            codeSysteme: codeSysteme,
            recordedByPhone: agentPhone,
            recordedAt: maintenant,
          ),
        );
      }
    });
  }

  /// Efface la présence anticipée d'un membre pour cette date — utilisé
  /// quand l'agent repasse un membre en "Présent" après l'avoir marqué
  /// absent par erreur (voir [marquerPresenceAnticipee]).
  Future<void> effacerPresenceAnticipee({
    required String cycleId,
    required String memberId,
    required DateTime date,
  }) {
    return (delete(presenceAnticipee)..where(
          (p) =>
              p.cycleId.equals(cycleId) &
              p.memberId.equals(memberId) &
              p.echeanceDate.equals(date),
        ))
        .go();
  }

  /// Toute la présence anticipée d'une date, au format `resolutions`
  /// attendu par [cloturerJourneeCotisation] (clé [clefResolutionCarnet])
  /// — permet à l'écran de clôture de pré-remplir avec ce que l'agent a
  /// déjà décidé pendant la journée plutôt que de retomber sur "Absence"
  /// par défaut.
  Future<Map<String, String>> presenceAnticipeeDuJour({
    required String cycleId,
    required DateTime date,
  }) async {
    final rows =
        await (select(presenceAnticipee)..where(
              (p) => p.cycleId.equals(cycleId) & p.echeanceDate.equals(date),
            ))
            .get();
    return {
      for (final r in rows)
        clefResolutionCarnet(r.memberId, r.carnetNumero): r.codeSysteme,
    };
  }

  /// Dette totale d'un membre au moment du partage de fin de cycle :
  /// **uniquement le solde de prêt confirmé non remboursé** (voir
  /// DECISIONS.md, "Les amendes ne sont plus une dette", 2026-08-09) —
  /// les amendes non soldées n'en font plus partie depuis cette
  /// décision : elles sont traitées séparément, par réduction du nombre
  /// de parts reconnues (voir `AmendeReductionCalculator`), jamais par
  /// une dette déduite du montant net. **N'inclut plus d'arriéré de
  /// cotisation** depuis le retrait du rattrapage (2026-08-09, voir
  /// DECISIONS.md "Amende seule, jamais de rattrapage"). N'inclut
  /// jamais un prêt non confirmé (hors calcul, skill
  /// member-consent-rules).
  Future<int> detteMembreFcfa({
    required String groupId,
    required String memberId,
    required String cycleId,
    DateTime? maintenant,
  }) async {
    final now = maintenant ?? AppClock.now();

    var soldePretsFcfa = 0;
    final pretsMembre = await pretsDuMembre(memberId, cycleId);
    final idsDejaRenouveles = await _idsDesPretsRenouveles();
    for (final pret in pretsMembre) {
      if (idsDejaRenouveles.contains(pret.id)) continue;
      if (!await pretEstConfirme(pret.id)) continue;
      // Toujours via soldePret (jamais un calcul dupliqué inline) —
      // c'est ce qui applique le plafond de dette perdue à la clôture
      // (voir la doc de soldePret) de façon uniforme.
      final solde = await soldePret(pret, maintenant: now);
      soldePretsFcfa += solde.montantDuFcfa;
    }

    return soldePretsFcfa;
  }

  Future<List<PartageDeduction>> partageDeductionsDuCycle(String cycleId) {
    return (select(
      partageDeductions,
    )..where((p) => p.cycleId.equals(cycleId))).get();
  }

  /// Prépare, membre par membre, les données nécessaires à
  /// [EndOfCycleCalculator] — réutilisé à la fois par la
  /// prévisualisation d'un cycle encore en cours (écran Répartition) et
  /// par la clôture réelle ([cloturerCycleEtOuvrirSuivant]), pour que
  /// les deux ne divergent jamais.
  ///
  /// Applique la réduction pour amende non soldée (voir
  /// `AmendeReductionCalculator`, DECISIONS.md "Les amendes ne sont
  /// plus une dette"), puis — pour chaque cotisation exceptionnelle
  /// dont la date limite est dépassée et encore due — une seconde
  /// réduction chaînée (voir DECISIONS.md, "Cotisations
  /// exceptionnelles") : `membres` porte déjà les parts reconnues et le
  /// résidu final de chaque membre, prêts à passer tels quels à
  /// `EndOfCycleCalculator`. `cotisationsEffectivesTotalesFcfa` est la
  /// somme des **seules parts reconnues** (`partsReconnues × valeur de
  /// la part`, tous membres confondus) — jamais les cotisations brutes
  /// ni les `cotisationTotaleFcfa` individuels, qui eux incluent le
  /// résidu : celui-ci ne doit jamais entrer dans le pot commun (voir
  /// doc de [EndOfCycleInput.cotisationsTotalesGroupeFcfa]), sous peine
  /// de le reverser deux fois au même membre. `amendesADeduireParMembre`
  /// (ce qui a été effectivement récupéré sur la cotisation de chacun, à
  /// ajouter au terme "amendes" de la caisse et, à la clôture réelle
  /// seulement, à marquer réglé) est fourni séparément pour rester
  /// composable. `cotisationsExceptionnellesADeduire` (détail par
  /// membre et par événement — **jamais ajouté à la caisse**, voir
  /// DECISIONS.md "Fonds de solidarité obligatoire" : "jamais dans la
  /// caisse principale" — juste de quoi enregistrer, à la clôture
  /// réelle seulement, la contribution automatique correspondante).
  Future<
    ({
      List<MemberCycleInput> membres,
      int cotisationsEffectivesTotalesFcfa,
      Map<String, int> amendesADeduireParMembre,
      List<({String memberId, String cotisationExceptionnelleId, int montantFcfa})>
      cotisationsExceptionnellesADeduire,
    })
  >
  preparerPartageCycle({
    required String groupId,
    required String cycleId,
  }) async {
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();
    final cotisationsCycle = await cotisationsDuCycle(cycleId);
    final partsParMembre = <String, int>{};
    for (final c in cotisationsCycle) {
      partsParMembre.update(
        c.memberId,
        (v) => v + c.partsCount,
        ifAbsent: () => c.partsCount,
      );
    }

    // Seules les cotisations exceptionnelles dont la date limite est
    // déjà dépassée peuvent être déduites automatiquement — jamais
    // avant (voir DECISIONS.md) ; triées de la plus ancienne à la plus
    // récente pour un ordre de recouvrement stable et prévisible.
    final maintenant = AppClock.now();
    final evtsEchus = (await cotisationsExceptionnellesDuCycle(cycleId))
        .where((e) => !e.dateLimite.isAfter(maintenant))
        .toList()
      ..sort((a, b) => a.dateLimite.compareTo(b.dateLimite));

    final membresInput = <MemberCycleInput>[];
    final amendesADeduireParMembre = <String, int>{};
    final cotisationsExceptionnellesADeduire =
        <({String memberId, String cotisationExceptionnelleId, int montantFcfa})>[];
    var cotisationsEffectivesTotales = 0;

    for (final entry in partsParMembre.entries) {
      final memberId = entry.key;
      final rawCotisationFcfa = entry.value * cycle.partValueFcfa;
      final amendesNonSoldees = await montantAmendesNonSoldeesFcfa(
        memberId: memberId,
        cycleId: cycleId,
      );
      final reductionAmendes = const AmendeReductionCalculator().calculer(
        rawCotisationFcfa: rawCotisationFcfa,
        amendesNonSoldeesFcfa: amendesNonSoldees,
        valeurPartFcfa: cycle.partValueFcfa,
      );
      if (reductionAmendes.montantEffectivementDeduitFcfa > 0) {
        amendesADeduireParMembre[memberId] =
            reductionAmendes.montantEffectivementDeduitFcfa;
      }

      // Reste après amendes, avant cotisations exceptionnelles — chaque
      // événement échu réduit ce reste à son tour, un par un (jamais
      // regroupés) pour rester attribuable individuellement à chaque
      // événement (voir [soldeCotisationExceptionnelleFcfa]).
      var resteFcfa =
          reductionAmendes.partsReconnues * cycle.partValueFcfa +
          reductionAmendes.residuFcfa;
      for (final evt in evtsEchus) {
        // Basé sur le cash réellement reçu, jamais sur
        // soldeCotisationExceptionnelleFcfa (qui compte aussi les
        // déductions automatiques déjà écrites, voir
        // appliquerDeductionsCotisationsExceptionnellesEchues) — sinon
        // cette réduction serait sautée dès qu'une déduction immédiate a
        // déjà eu lieu, l'annulant à tort au moment du partage.
        final eligible = await _membreEligibleCotisationExceptionnelle(
          memberId: memberId,
          evt: evt,
        );
        if (!eligible) continue;
        final cashVerse = await _totalVerseCashCotisationExceptionnelle(
          cotisationExceptionnelleId: evt.id,
          memberId: memberId,
        );
        final soldeEvt = evt.montantFcfa - cashVerse;
        if (soldeEvt <= 0) continue;
        final reductionEvt = const AmendeReductionCalculator().calculer(
          rawCotisationFcfa: resteFcfa,
          amendesNonSoldeesFcfa: soldeEvt,
          valeurPartFcfa: cycle.partValueFcfa,
        );
        resteFcfa =
            reductionEvt.partsReconnues * cycle.partValueFcfa +
            reductionEvt.residuFcfa;
        if (reductionEvt.montantEffectivementDeduitFcfa > 0) {
          cotisationsExceptionnellesADeduire.add((
            memberId: memberId,
            cotisationExceptionnelleId: evt.id,
            montantFcfa: reductionEvt.montantEffectivementDeduitFcfa,
          ));
        }
      }

      final partsReconnuesFinal = resteFcfa ~/ cycle.partValueFcfa;
      final residuFinal = resteFcfa - partsReconnuesFinal * cycle.partValueFcfa;

      membresInput.add(
        MemberCycleInput(
          memberId: memberId,
          totalParts: partsReconnuesFinal,
          cotisationTotaleFcfa: partsReconnuesFinal * cycle.partValueFcfa + residuFinal,
          detteFcfa: await detteMembreFcfa(
            groupId: groupId,
            memberId: memberId,
            cycleId: cycleId,
          ),
          residuSansBonusFcfa: residuFinal,
        ),
      );
      // N'entre dans le pot (base de `valeur_par_part`) que la portion
      // reconnue après **toutes** les réductions — jamais le résidu, et
      // jamais la portion déduite pour cotisation exceptionnelle (voir
      // doc de [EndOfCycleInput.cotisationsTotalesGroupeFcfa] et
      // DECISIONS.md "jamais dans la caisse principale").
      cotisationsEffectivesTotales += partsReconnuesFinal * cycle.partValueFcfa;
    }

    return (
      membres: membresInput,
      cotisationsEffectivesTotalesFcfa: cotisationsEffectivesTotales,
      amendesADeduireParMembre: amendesADeduireParMembre,
      cotisationsExceptionnellesADeduire: cotisationsExceptionnellesADeduire,
    );
  }

  // ---------------------------------------------------------------------
  // Confirmation de paiement de fin de cycle — condition de clôture
  // (voir DECISIONS.md, "Clôture de cycle conditionnée au paiement de
  // tous les membres").
  // ---------------------------------------------------------------------

  /// Membres déjà confirmés comme payés pour ce cycle.
  Future<Set<String>> membresConfirmesPayesDuCycle(String cycleId) async {
    final rows = await (select(
      partagePaiementConfirmations,
    )..where((p) => p.cycleId.equals(cycleId))).get();
    return rows.map((r) => r.memberId).toSet();
  }

  /// Coche "payé" pour un membre — idempotent (ne crée jamais de doublon
  /// si déjà confirmé). Table de workflow, pas financière : librement
  /// annulable tant que le cycle n'est pas clos, voir
  /// [annulerConfirmationPaiementMembre].
  Future<void> confirmerPaiementMembre({
    required String groupId,
    required String cycleId,
    required String memberId,
    required String confirmedByPhone,
  }) async {
    final existant =
        await (select(partagePaiementConfirmations)..where(
              (p) => p.cycleId.equals(cycleId) & p.memberId.equals(memberId),
            ))
            .getSingleOrNull();
    if (existant != null) return;
    await into(partagePaiementConfirmations).insert(
      PartagePaiementConfirmationsCompanion.insert(
        id: _uuid.v4(),
        groupId: groupId,
        cycleId: cycleId,
        memberId: memberId,
        confirmedByPhone: confirmedByPhone,
      ),
    );
  }

  /// Décoche "payé" (coché par erreur) — un cycle déjà clos ne
  /// présentant plus de case à cocher modifiable côté écran, cette
  /// méthode n'est en pratique jamais appelée après la clôture.
  Future<void> annulerConfirmationPaiementMembre({
    required String cycleId,
    required String memberId,
  }) async {
    await (delete(partagePaiementConfirmations)..where(
          (p) => p.cycleId.equals(cycleId) & p.memberId.equals(memberId),
        ))
        .go();
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
  Future<List<MembreEnRetard>> membresEnRetard(
    String groupId,
    String cycleId,
  ) async {
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();
    if (cycle.status != 'en_cours') return [];

    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(groupId))).getSingle();
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
      final aCotiseSurLaPeriode = cotisations.any(
        (c) => !c.recordedAt.isBefore(periodeDebut),
      );
      if (aCotiseSurLaPeriode) continue;

      final amendesMembre = await amendesDuMembre(membre.id, cycleId);
      final dejaAmendeSurLaPeriode = amendesMembre.any(
        (a) => !a.recordedAt.isBefore(periodeDebut),
      );
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
    String? cotisationExceptionnelleId,
    bool estDeductionAutomatique = false,
  }) async {
    final id = _uuid.v4();
    final horodatage = recordedAt ?? AppClock.now();
    final previousHash = await _lastHashOf(
      fondsSolidariteContributions.tableName,
    );
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        cycleId,
        memberId,
        montantFcfa,
        motif,
        recordedByPhone,
        horodatage.toIso8601String(),
        provenance,
      ],
    );
    await into(fondsSolidariteContributions).insert(
      FondsSolidariteContributionsCompanion.insert(
        id: id,
        groupId: groupId,
        cycleId: cycleId,
        memberId: Value(memberId),
        montantFcfa: montantFcfa,
        motif: motif,
        recordedByPhone: recordedByPhone,
        estDeductionAutomatique: Value(estDeductionAutomatique),
        recordedAt: Value(horodatage),
        previousHash: Value(previousHash),
        hash: hash,
        provenance: Value(provenance),
        estApproximatif: Value(estApproximatif),
        cotisationExceptionnelleId: Value(cotisationExceptionnelleId),
      ),
    );
    return id;
  }

  /// Exclut toute ligne [estDeductionAutomatique] (voir
  /// RETOURS_TERRAIN.md, point 25.4) — cette caisse n'affiche jamais que
  /// de l'argent réellement reçu, jamais une déduction automatique
  /// d'épargne qui n'y a jamais transité.
  Future<int> totalFondsSolidarite(String groupId) async {
    final rows =
        await (select(fondsSolidariteContributions)..where(
              (f) =>
                  f.groupId.equals(groupId) &
                  f.estDeductionAutomatique.equals(false),
            ))
            .get();
    return rows.fold<int>(0, (sum, f) => sum + f.montantFcfa);
  }

  /// Total déjà versé par CE membre au fonds de solidarité **récurrent
  /// obligatoire** sur CE cycle — base du solde dû (voir
  /// [soldeSolidariteObligatoireFcfa]). Ne compte jamais les
  /// contributions liées à une cotisation exceptionnelle précise (voir
  /// [CotisationsExceptionnelles]) : bucket séparé, jamais mélangé
  /// (sinon un versement pour un événement ponctuel solderait à tort
  /// le fonds récurrent, ou l'inverse).
  Future<int> totalVerseFondsSolidariteMembre({
    required String cycleId,
    required String memberId,
  }) async {
    final rows =
        await (select(fondsSolidariteContributions)..where(
              (f) =>
                  f.cycleId.equals(cycleId) &
                  f.memberId.equals(memberId) &
                  f.cotisationExceptionnelleId.isNull(),
            ))
            .get();
    return rows.fold<int>(0, (sum, f) => sum + f.montantFcfa);
  }

  /// Solde dû au fonds de solidarité **obligatoire** pour ce membre sur
  /// ce cycle — voir DECISIONS.md, "Fonds de solidarité obligatoire" :
  /// montant dû cumulé = `Groups.montantSolidariteObligatoireFcfa` ×
  /// nombre de carnets du membre × nombre de réunions déjà passées
  /// depuis son entrée dans le groupe (même calendrier que la
  /// cotisation, voir [EcheanceCalculator]) — moins ce qu'il a déjà
  /// versé. Jamais négatif (un membre en avance n'est simplement "à
  /// jour", voir DECISIONS.md : "souple dans le rythme"). Renvoie 0 si
  /// le groupe n'a pas rendu le fonds obligatoire (montant à 0), ou si
  /// les carnets du membre ne sont pas encore définis.
  Future<int> soldeSolidariteObligatoireFcfa({
    required String groupId,
    required String cycleId,
    required String memberId,
    DateTime? maintenant,
  }) async {
    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(groupId))).getSingle();
    if (groupe.montantSolidariteObligatoireFcfa <= 0) return 0;
    final carnets = await carnetsEngagesDuMembre(
      memberId: memberId,
      cycleId: cycleId,
    );
    if (carnets == null) return 0;
    final membre = await (select(
      members,
    )..where((m) => m.id.equals(memberId))).getSingle();
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();

    List<DateTime> echeances;
    try {
      echeances = const EcheanceCalculator().echeancesPassees(
        debutCycle: cycle.startedAt,
        meetingFrequency: groupe.meetingFrequency,
        paymentDayOfWeek: groupe.paymentDayOfWeek,
        paymentDayOfMonth1: groupe.paymentDayOfMonth1,
        paymentDayOfMonth2: groupe.paymentDayOfMonth2,
        maintenant: maintenant ?? AppClock.now(),
      );
    } on ArgumentError {
      return 0;
    }
    // Jamais avant son entrée dans le groupe (même principe que les
    // échéances de cotisation — voir DECISIONS.md, correction du bug
    // joinedAt).
    final echeancesApplicables = echeances
        .where((d) => !d.isBefore(membre.joinedAt))
        .length;

    final duFcfa = groupe.montantSolidariteObligatoireFcfa *
        carnets.nombreCarnets *
        echeancesApplicables;
    final verseFcfa = await totalVerseFondsSolidariteMembre(
      cycleId: cycleId,
      memberId: memberId,
    );
    final solde = duFcfa - verseFcfa;
    return solde <= 0 ? 0 : solde;
  }

  /// Membres du groupe qui n'ont pas encore soldé leur fonds de
  /// solidarité obligatoire sur ce cycle — base du blocage de clôture
  /// (voir DECISIONS.md, "Fonds de solidarité obligatoire" : "tout doit
  /// être soldé avant le partage de fin de cycle"). Vide si le groupe
  /// n'a pas rendu le fonds obligatoire.
  Future<Map<String, int>> soldesSolidariteObligatoireNonSoldesDuCycle({
    required String groupId,
    required String cycleId,
  }) async {
    final groupe = await (select(
      groups,
    )..where((g) => g.id.equals(groupId))).getSingle();
    if (groupe.montantSolidariteObligatoireFcfa <= 0) return {};
    final membresGroupe = await membresDuGroupe(groupId);
    final resultat = <String, int>{};
    for (final m in membresGroupe) {
      final solde = await soldeSolidariteObligatoireFcfa(
        groupId: groupId,
        cycleId: cycleId,
        memberId: m.id,
      );
      if (solde > 0) resultat[m.id] = solde;
    }
    return resultat;
  }

  // ---------------------------------------------------------------------
  // Cotisations exceptionnelles (mariage, décès, accouchement...) — voir
  // DECISIONS.md, "Cotisations exceptionnelles". Événement déclaré une
  // fois, s'applique automatiquement à tous les membres déjà présents.
  // ---------------------------------------------------------------------

  /// Déclare une cotisation exceptionnelle — une seule fois, jamais
  /// modifiable ensuite. S'applique **automatiquement** à tous les
  /// membres déjà présents dans le groupe à cet instant (jamais à ceux
  /// qui rejoignent après, voir [CotisationsExceptionnelles]) : aucune
  /// ligne par membre n'est créée ici, l'éligibilité et le solde dû se
  /// calculent à la lecture (voir [soldeCotisationExceptionnelleFcfa]).
  Future<String> enregistrerCotisationExceptionnelle({
    required String groupId,
    required String cycleId,
    required String motif,
    required int montantFcfa,
    required DateTime dateLimite,
    required String createdByPhone,
  }) async {
    if (montantFcfa <= 0) {
      throw ArgumentError('Le montant doit être positif.');
    }
    final id = _uuid.v4();
    final horodatage = AppClock.now();
    final previousHash = await _lastHashOf(
      cotisationsExceptionnelles.tableName,
    );
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        cycleId,
        motif,
        montantFcfa,
        dateLimite.toIso8601String(),
        createdByPhone,
        horodatage.toIso8601String(),
      ],
    );
    await into(cotisationsExceptionnelles).insert(
      CotisationsExceptionnellesCompanion.insert(
        id: id,
        groupId: groupId,
        cycleId: cycleId,
        motif: motif,
        montantFcfa: montantFcfa,
        dateLimite: dateLimite,
        createdByPhone: createdByPhone,
        createdAt: Value(horodatage),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
    return id;
  }

  /// Modifie le motif, le montant et/ou la date limite d'une cotisation
  /// exceptionnelle déjà déclarée — décision du fondateur (voir
  /// RETOURS_TERRAIN.md) qui assouplit la doc d'origine ("jamais
  /// modifiable ensuite") : sur le terrain, une date limite ou un
  /// montant annoncés doivent parfois être ajustés après coup (report
  /// de délai, montant révisé). Ne touche qu'à la **définition** de
  /// l'événement — les [FondsSolidariteContributions] déjà enregistrées
  /// contre lui restent, elles, intouchables (hash-chaînées comme
  /// toute table financière) : réduire le montant sous ce qu'un membre
  /// a déjà versé ne le met jamais en trop-perçu négatif (voir
  /// [soldeCotisationExceptionnelleFcfa], toujours plafonné à 0).
  ///
  /// Pas de hash-chaîne à recalculer ici : contrairement à
  /// [enregistrerCotisationExceptionnelle] (l'événement financier
  /// lui-même), cette mise à jour ne crée ni ne modifie aucun
  /// mouvement d'argent — seulement le libellé qui les décrit.
  Future<void> modifierCotisationExceptionnelle({
    required String id,
    required String motif,
    required int montantFcfa,
    required DateTime dateLimite,
  }) async {
    if (montantFcfa <= 0) {
      throw ArgumentError('Le montant doit être positif.');
    }
    await (update(
      cotisationsExceptionnelles,
    )..where((c) => c.id.equals(id))).write(
      CotisationsExceptionnellesCompanion(
        motif: Value(motif),
        montantFcfa: Value(montantFcfa),
        dateLimite: Value(dateLimite),
      ),
    );
  }

  Future<List<CotisationsExceptionnelle>> cotisationsExceptionnellesDuCycle(
    String cycleId,
  ) {
    return (select(cotisationsExceptionnelles)
          ..where((c) => c.cycleId.equals(cycleId))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
        .get();
  }

  /// Vrai si ce membre était déjà présent dans le groupe quand cette
  /// cotisation exceptionnelle a été déclarée — seule condition
  /// d'éligibilité (voir [CotisationsExceptionnelles]).
  Future<bool> _membreEligibleCotisationExceptionnelle({
    required String memberId,
    required CotisationsExceptionnelle evt,
  }) async {
    final membre = await (select(
      members,
    )..where((m) => m.id.equals(memberId))).getSingle();
    return !membre.joinedAt.isAfter(evt.createdAt);
  }

  /// Total déjà versé par ce membre pour CETTE cotisation exceptionnelle
  /// précise (paiement volontaire ou déduction automatique à la
  /// clôture — voir [preparerPartageCycle] — les deux s'additionnent de
  /// la même façon).
  Future<int> totalVerseCotisationExceptionnelle({
    required String cotisationExceptionnelleId,
    required String memberId,
  }) async {
    final rows =
        await (select(fondsSolidariteContributions)..where(
              (f) =>
                  f.cotisationExceptionnelleId.equals(
                    cotisationExceptionnelleId,
                  ) &
                  f.memberId.equals(memberId),
            ))
            .get();
    return rows.fold<int>(0, (sum, f) => sum + f.montantFcfa);
  }

  /// Solde restant dû par ce membre pour CETTE cotisation exceptionnelle
  /// — 0 si le membre n'y est pas éligible (a rejoint après), jamais
  /// négatif.
  Future<int> soldeCotisationExceptionnelleFcfa({
    required CotisationsExceptionnelle evt,
    required String memberId,
  }) async {
    final eligible = await _membreEligibleCotisationExceptionnelle(
      memberId: memberId,
      evt: evt,
    );
    if (!eligible) return 0;
    final verse = await totalVerseCotisationExceptionnelle(
      cotisationExceptionnelleId: evt.id,
      memberId: memberId,
    );
    final solde = evt.montantFcfa - verse;
    return solde <= 0 ? 0 : solde;
  }

  /// Cotisations exceptionnelles encore dues par ce membre sur ce cycle
  /// (montant restant > 0), toutes échéances confondues (passées ou
  /// non — réglable à tout moment, voir DECISIONS.md). Base de la
  /// section "Cotisations exceptionnelles" de la fiche membre.
  Future<List<({CotisationsExceptionnelle evt, int solde})>>
  cotisationsExceptionnellesNonSoldeesDuMembre({
    required String cycleId,
    required String memberId,
  }) async {
    final evts = await cotisationsExceptionnellesDuCycle(cycleId);
    final resultat = <({CotisationsExceptionnelle evt, int solde})>[];
    for (final evt in evts) {
      final solde = await soldeCotisationExceptionnelleFcfa(
        evt: evt,
        memberId: memberId,
      );
      if (solde > 0) resultat.add((evt: evt, solde: solde));
    }
    return resultat;
  }

  /// Nombre de membres éligibles (déjà présents à la déclaration, voir
  /// [CotisationsExceptionnelles]) et total déjà collecté pour cet
  /// événement, tous membres confondus — vue d'ensemble pour l'écran de
  /// déclaration. `totalCollecteFcfa` ne compte jamais une déduction
  /// automatique (voir [estDeductionAutomatique]) : ce chiffre reflète
  /// uniquement l'argent réellement en caisse.
  Future<({int membresEligibles, int totalCollecteFcfa})>
  resumeCotisationExceptionnelle(CotisationsExceptionnelle evt) async {
    final membresGroupe = await membresDuGroupe(evt.groupId);
    var eligibles = 0;
    for (final m in membresGroupe) {
      if (!m.joinedAt.isAfter(evt.createdAt)) eligibles++;
    }
    final rows =
        await (select(fondsSolidariteContributions)..where(
              (f) =>
                  f.cotisationExceptionnelleId.equals(evt.id) &
                  f.estDeductionAutomatique.equals(false),
            ))
            .get();
    final totalCollecte = rows.fold<int>(0, (s, f) => s + f.montantFcfa);
    return (membresEligibles: eligibles, totalCollecteFcfa: totalCollecte);
  }

  /// Détail par membre d'une cotisation exceptionnelle — qui a payé en
  /// cash, qui a été déduit automatiquement à la date limite, qui n'a
  /// encore rien fait (demande du fondateur, voir DECISIONS.md, "Détail
  /// par membre d'une cotisation exceptionnelle"). Uniquement les
  /// membres éligibles (déjà présents à la déclaration de l'événement).
  Future<List<DetailMembreCotisationExceptionnelle>>
  detailCotisationExceptionnelleParMembre(
    CotisationsExceptionnelle evt,
  ) async {
    final membresGroupe = await membresDuGroupe(evt.groupId);
    final eligibles = membresGroupe.where(
      (m) => !m.joinedAt.isAfter(evt.createdAt),
    );
    final resultat = <DetailMembreCotisationExceptionnelle>[];
    for (final membre in eligibles) {
      final verse = await _totalVerseCashCotisationExceptionnelle(
        cotisationExceptionnelleId: evt.id,
        memberId: membre.id,
      );
      final deduit = await _totalDejaDeduitAutomatiquement(
        cotisationExceptionnelleId: evt.id,
        memberId: membre.id,
      );
      resultat.add(
        DetailMembreCotisationExceptionnelle(
          membre: membre,
          montantVerseFcfa: verse,
          montantDeduitAutomatiquementFcfa: deduit,
        ),
      );
    }
    return resultat;
  }

  /// Déduit automatiquement, **immédiatement**, le solde restant de
  /// chaque membre éligible pour toute cotisation exceptionnelle de ce
  /// cycle dont la date limite est dépassée — voir RETOURS_TERRAIN.md,
  /// point 25.4 : avant cette décision, ce même mécanisme n'existait
  /// qu'à la clôture du cycle ([preparerPartageCycle]/
  /// [cloturerCycleEtOuvrirSuivant]), laissant le solde invisible et
  /// intact entre la date limite et la clôture, parfois des mois plus
  /// tard.
  ///
  /// Écrit une ligne [FondsSolidariteContributions] marquée
  /// [estDeductionAutomatique] plutôt qu'un vrai versement — ce
  /// distinguo est ce qui permet à [preparerPartageCycle] de continuer
  /// à réduire les parts reconnues du membre exactement du même montant
  /// que si rien n'avait encore été écrit (voir sa doc) : la ligne
  /// automatique sert au solde affiché et à l'historique, jamais de
  /// nouveau à la réduction elle-même (qui se base uniquement sur le
  /// cash reçu, voir [_totalVerseCashCotisationExceptionnelle]) — sans
  /// ce distinguo, la réduction serait sautée une fois la ligne écrite
  /// (le solde retombant à 0), ce qui annulerait à tort la déduction au
  /// moment du partage.
  ///
  /// **Idempotent** : s'appuie sur [soldeCotisationExceptionnelleFcfa]
  /// (qui compte les lignes automatiques comme réglées), retombé à 0
  /// une fois la déduction écrite — un appel répété (à chaque ouverture
  /// d'écran) ne déduit donc jamais deux fois.
  ///
  /// Sans effet sur un cycle déjà clos.
  Future<void> appliquerDeductionsCotisationsExceptionnellesEchues({
    required String groupId,
    required String cycleId,
    required String agentPhone,
  }) async {
    final cycle = await (select(
      cycles,
    )..where((c) => c.id.equals(cycleId))).getSingle();
    if (cycle.status != 'en_cours') return;

    final maintenant = AppClock.now();
    final evtsEchus = (await cotisationsExceptionnellesDuCycle(cycleId)).where(
      (e) => !e.dateLimite.isAfter(maintenant),
    );
    if (evtsEchus.isEmpty) return;

    final membres = await membresDuGroupe(groupId);
    for (final evt in evtsEchus) {
      for (final membre in membres) {
        final solde = await soldeCotisationExceptionnelleFcfa(
          evt: evt,
          memberId: membre.id,
        );
        if (solde <= 0) continue;
        await enregistrerContributionFondsSolidarite(
          groupId: groupId,
          cycleId: cycleId,
          memberId: membre.id,
          montantFcfa: solde,
          motif: 'Cotisation exceptionnelle non payée à temps — déduite '
              'automatiquement de l\'épargne à la date limite',
          recordedByPhone: agentPhone,
          cotisationExceptionnelleId: evt.id,
          estDeductionAutomatique: true,
        );
      }
    }
  }

  /// Total déjà versé en **cash réel** par ce membre pour cette
  /// cotisation exceptionnelle — exclut toute ligne
  /// [estDeductionAutomatique]. Base de la réduction des parts
  /// reconnues au partage (voir [preparerPartageCycle]) : contrairement
  /// à [soldeCotisationExceptionnelleFcfa] (qui sert à savoir si le
  /// membre "doit encore quelque chose", et compte donc aussi les
  /// déductions automatiques), cette réduction ne doit jamais dépendre
  /// de si [appliquerDeductionsCotisationsExceptionnellesEchues] est
  /// déjà passé ou non — sinon la même réduction serait tantôt
  /// appliquée, tantôt sautée, selon un simple hasard de timing.
  Future<int> _totalVerseCashCotisationExceptionnelle({
    required String cotisationExceptionnelleId,
    required String memberId,
  }) async {
    final rows =
        await (select(fondsSolidariteContributions)..where(
              (f) =>
                  f.cotisationExceptionnelleId.equals(
                    cotisationExceptionnelleId,
                  ) &
                  f.memberId.equals(memberId) &
                  f.estDeductionAutomatique.equals(false),
            ))
            .get();
    return rows.fold<int>(0, (sum, f) => sum + f.montantFcfa);
  }

  /// Total déjà déduit automatiquement (voir [estDeductionAutomatique])
  /// pour ce membre sur cette cotisation exceptionnelle précise — sert à
  /// ne jamais réécrire deux fois la même déduction à la clôture (voir
  /// [cloturerCycleEtOuvrirSuivant]) si
  /// [appliquerDeductionsCotisationsExceptionnellesEchues] est déjà
  /// passé avant.
  Future<int> _totalDejaDeduitAutomatiquement({
    required String cotisationExceptionnelleId,
    required String memberId,
  }) async {
    final rows =
        await (select(fondsSolidariteContributions)..where(
              (f) =>
                  f.cotisationExceptionnelleId.equals(
                    cotisationExceptionnelleId,
                  ) &
                  f.memberId.equals(memberId) &
                  f.estDeductionAutomatique.equals(true),
            ))
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
    final hash = HashChain.compute(
      previousHash: previousHash,
      fields: [
        id,
        groupId,
        memberId,
        phoneNumber,
        role,
        assignedAt.toIso8601String(),
      ],
    );
    await into(agentAssignments).insert(
      AgentAssignmentsCompanion.insert(
        id: id,
        groupId: groupId,
        memberId: Value(memberId),
        phoneNumber: phoneNumber,
        role: role,
        assignedAt: Value(assignedAt),
        previousHash: Value(previousHash),
        hash: hash,
      ),
    );
    return id;
  }
}

class MembreEnRetard {
  final Member membre;
  final DateTime periodeDebut;

  const MembreEnRetard({required this.membre, required this.periodeDebut});
}

/// Toutes les échéances (un membre = une ligne) résolues à une même
/// date — un groupe de l'historique des cotisations, voir
/// [AppDatabase.echeancesGroupeesParDate].
class EcheanceGroupeeParDate {
  final DateTime date;
  final List<Echeance> lignes;

  const EcheanceGroupeeParDate({required this.date, required this.lignes});
}

/// Un prêt confirmé dont le remboursement n'est pas complet au moment où
/// l'agent envisage de clôturer le cycle — voir [pretsNonSoldesDuCycle].
class PretNonSolde {
  final Pret pret;
  final int soldeRestantFcfa;

  const PretNonSolde({required this.pret, required this.soldeRestantFcfa});
}

/// Statut d'un membre éligible pour une cotisation exceptionnelle
/// donnée — voir [DetailMembreCotisationExceptionnelle.statutPour].
enum StatutCotisationExceptionnelleMembre {
  /// Rien versé, ou versement partiel — la date limite n'est pas
  /// encore dépassée.
  enAttente,

  /// Intégralement réglé en cash, aucune déduction automatique.
  paye,

  /// Une déduction automatique a eu lieu (date limite dépassée) —
  /// éventuellement après un versement cash partiel (voir
  /// [DetailMembreCotisationExceptionnelle.montantVerseFcfa]).
  deduitAutomatiquement,
}

/// Détail d'un membre éligible pour une cotisation exceptionnelle — voir
/// [AppDatabase.detailCotisationExceptionnelleParMembre].
class DetailMembreCotisationExceptionnelle {
  final Member membre;
  final int montantVerseFcfa;
  final int montantDeduitAutomatiquementFcfa;

  const DetailMembreCotisationExceptionnelle({
    required this.membre,
    required this.montantVerseFcfa,
    required this.montantDeduitAutomatiquementFcfa,
  });

  /// [montantAttenduFcfa] : le montant par membre de l'événement
  /// (`CotisationsExceptionnelles.montantFcfa`) — nécessaire pour
  /// distinguer un versement cash partiel (encore en attente) d'un
  /// versement complet.
  StatutCotisationExceptionnelleMembre statutPour(int montantAttenduFcfa) {
    if (montantDeduitAutomatiquementFcfa > 0) {
      return StatutCotisationExceptionnelleMembre.deduitAutomatiquement;
    }
    if (montantVerseFcfa >= montantAttenduFcfa && montantAttenduFcfa > 0) {
      return StatutCotisationExceptionnelleMembre.paye;
    }
    return StatutCotisationExceptionnelleMembre.enAttente;
  }
}

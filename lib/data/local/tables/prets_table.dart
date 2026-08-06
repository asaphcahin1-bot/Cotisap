import 'package:drift/drift.dart';

import 'hash_chain_columns.dart';
import 'groups_table.dart';
import 'members_table.dart';
import 'cycles_table.dart';

/// Un prêt. La ligne de création est immuable : ni le montant, ni
/// l'emprunteur ne changent jamais après coup. Le statut
/// "en_attente_confirmation -> confirmé" décrit dans le skill
/// member-consent-rules n'est PAS une colonne mutable ici — c'est
/// l'existence (ou non) d'une ligne dans [PretConfirmations] référençant
/// ce prêt qui fait foi. Ça évite toute modification rétroactive
/// silencieuse d'un enregistrement déjà confirmé.
class Prets extends Table with HashChainColumns, ProvenanceColumns {
  @override
  String get tableName => 'prets';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get cycleId => text().references(Cycles, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  IntColumn get principalFcfa => integer()();
  RealColumn get interestRatePercent => real()();

  /// Copié depuis `cycle.loanDurationDays` au moment de la création du
  /// prêt (même logique que [interestRatePercent] : figé sur le prêt,
  /// pas relu depuis le cycle au moment du calcul). Nullable : un prêt
  /// importé d'un historique papier peut ne pas avoir de durée connue —
  /// dans ce cas [LoanBalanceCalculator] applique l'intérêt une seule
  /// fois, sans recomposition, plutôt que de deviner une durée.
  IntColumn get dureeJours => integer().nullable()();

  TextColumn get initiatedByPhone => text()();

  /// Code de confirmation que le membre doit saisir pour valider le
  /// prêt. En mode dev, un code de test fixe (voir DevAuthGateway) ;
  /// en production, un code envoyé par SMS via Supabase Auth/Twilio.
  /// Nullable : un membre sans téléphone (voir [Members]) n'a pas de
  /// code à recevoir — son prêt est confirmé par signature à la place
  /// (voir [PretConfirmations]).
  TextColumn get confirmationCode => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Un prêt est "confirmé" si et seulement si une ligne existe ici pour
/// lui. Tant qu'aucune ligne n'existe, le prêt reste en attente et
/// n'entre dans aucun calcul de répartition ni solde exigible (skill
/// member-consent-rules).
///
/// Deux méthodes de confirmation, jamais mélangées sur une même ligne
/// (voir [methode]) :
/// - `code` : le membre a un téléphone, il saisit le code reçu (SMS en
///   production, code de test en mode dev). [codeSaisi] et
///   [confirmedByPhone] (son propre numéro) sont renseignés.
/// - `signature` : le membre n'a aucun téléphone (skill
///   member-consent-rules, "cas des membres sans smartphone").
///   [signatureData] (capturée en personne sur l'appareil de l'agent) et
///   [witnessPhone] (le numéro de l'agent témoin, jamais celui d'un
///   tiers agissant pour le membre) sont renseignés à la place.
class PretConfirmations extends Table with HashChainColumns {
  @override
  String get tableName => 'pret_confirmations';

  TextColumn get id => text()();
  TextColumn get pretId => text().references(Prets, #id)();
  TextColumn get methode => text().withDefault(const Constant('code'))();
  TextColumn get codeSaisi => text().nullable()();
  TextColumn get confirmedByPhone => text().nullable()();
  TextColumn get witnessPhone => text().nullable()();
  TextColumn get signatureData => text().nullable()();
  DateTimeColumn get confirmedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Un remboursement (partiel ou total) d'un prêt confirmé.
class PretRemboursements extends Table with HashChainColumns, ProvenanceColumns {
  @override
  String get tableName => 'pret_remboursements';

  TextColumn get id => text()();
  TextColumn get pretId => text().references(Prets, #id)();
  IntColumn get montantFcfa => integer()();
  TextColumn get recordedByPhone => text()();
  DateTimeColumn get recordedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Annulation d'un prêt (erreur de saisie, demande retirée avant
/// confirmation, etc.) — toujours une nouvelle ligne qui référence le
/// prêt d'origine, jamais une suppression.
class PretAnnulations extends Table with HashChainColumns {
  @override
  String get tableName => 'pret_annulations';

  TextColumn get id => text()();
  TextColumn get pretId => text().references(Prets, #id)();
  TextColumn get raison => text()();
  TextColumn get annuleParPhone => text()();
  DateTimeColumn get annuleAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

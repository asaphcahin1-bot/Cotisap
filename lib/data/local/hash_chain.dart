import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Chaîne de hash simple pour les tables financières en ajout seul
/// (cotisations, prêts, remboursements, amendes, fonds de solidarité,
/// affectations d'agent — voir DECISIONS.md, section "Immuabilité").
///
/// Chaque ligne stocke le hash de la dernière ligne insérée dans la même
/// table au moment de son insertion, plus le hash de ses propres champs.
/// Ce n'est pas une signature cryptographique au sens strict, mais ça
/// suffit à détecter qu'une ligne déjà enregistrée a été modifiée
/// directement dans le fichier SQLite — ce que l'application elle-même
/// ne fait jamais (aucune méthode UPDATE/DELETE n'existe sur ces tables,
/// seulement des insertions ; une correction crée une nouvelle ligne qui
/// référence l'originale).
class HashChain {
  const HashChain._();

  static String compute({
    required String? previousHash,
    required List<Object?> fields,
  }) {
    final payload = jsonEncode(<Object?>[previousHash, ...fields]);
    return sha256.convert(utf8.encode(payload)).toString();
  }
}

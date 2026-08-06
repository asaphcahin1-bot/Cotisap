import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth/auth_gateway.dart';
import '../data/local/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final authGatewayProvider = Provider<AuthGateway>((ref) {
  return DevAuthGateway();
});

/// Numéro de téléphone de la personne actuellement utilisatrice de
/// l'app sur cet appareil (agent ou membre). Pas de session Supabase
/// pour cette étape — voir ROADMAP.md.
final currentPhoneNumberProvider = StateProvider<String?>((ref) => null);

/// Rôle choisi explicitement à l'écran d'identification (skill
/// two-tier-access-model : agent = accès complet, membre = lecture
/// seule limitée à ses propres données). Un même numéro peut en
/// théorie être à la fois agent d'un groupe et membre d'un autre — le
/// choix est donc fait par la personne, pas déduit automatiquement.
enum AppMode { agent, membre }

final appModeProvider = StateProvider<AppMode?>((ref) => null);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env/supabase_config.dart';
import 'features/groups/groups_list_screen.dart';
import 'features/member_view/member_lookup_screen.dart';
import 'state/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ne bloque jamais le démarrage de l'app hors ligne (skill
  // offline-first-flutter) : sans identifiants fournis à la compilation
  // (voir ENVIRONMENT.md), l'app démarre normalement en local uniquement —
  // aucune fonctionnalité actuelle n'en dépend encore (la synchronisation
  // et l'authentification réelle restent des étapes séparées, voir
  // ROADMAP.md).
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  runApp(const ProviderScope(child: CotisAppRoot()));
}

class CotisAppRoot extends StatelessWidget {
  const CotisAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CotisApp',
      locale: const Locale('fr', 'FR'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF33456E)),
      ),
      home: const _IdentificationGate(),
    );
  }
}

/// Demande le numéro de téléphone de la personne qui utilise l'app sur
/// cet appareil (l'agent), une fois par lancement. Pas de code de
/// confirmation à ce stade — l'OTP (mode dev pour l'instant, voir
/// AuthGateway) sert spécifiquement au consentement de prêt, pas à cette
/// identification générale (skill two-tier-access-model : identification
/// par numéro de téléphone, pas de mot de passe).
class _IdentificationGate extends ConsumerWidget {
  const _IdentificationGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(currentPhoneNumberProvider);
    final mode = ref.watch(appModeProvider);
    if (phone != null && phone.isNotEmpty && mode == AppMode.agent) {
      return const GroupsListScreen();
    }
    if (phone != null && phone.isNotEmpty && mode == AppMode.membre) {
      return const MemberLookupScreen();
    }
    return const _PhoneEntryScreen();
  }
}

class _PhoneEntryScreen extends ConsumerStatefulWidget {
  const _PhoneEntryScreen();

  @override
  ConsumerState<_PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<_PhoneEntryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('CotisApp', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Gestion des AVEC'),
                const SizedBox(height: 32),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Votre numéro de téléphone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final value = _controller.text.trim();
                    if (value.isEmpty) return;
                    ref.read(currentPhoneNumberProvider.notifier).state = value;
                    ref.read(appModeProvider.notifier).state = AppMode.agent;
                  },
                  child: const Text('Continuer comme agent'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    final value = _controller.text.trim();
                    if (value.isEmpty) return;
                    ref.read(currentPhoneNumberProvider.notifier).state = value;
                    ref.read(appModeProvider.notifier).state = AppMode.membre;
                  },
                  child: const Text('Voir mes informations (membre)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

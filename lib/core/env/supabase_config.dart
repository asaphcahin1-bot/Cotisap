/// Identifiants Supabase, lus au moment de la compilation via
/// `--dart-define-from-file` (voir ENVIRONMENT.md) — jamais codés en dur,
/// jamais commités (skill CLAUDE.md : "Protéger les secrets avec des
/// variables d'environnement. Aucun secret ne doit être commité.").
///
/// Ni [url] ni [publishableKey] ne sont des secrets à proprement parler
/// (la clé publishable est conçue pour être exposée côté client, protégée
/// par les règles RLS côté serveur — voir supabase/migrations/0001_init.sql),
/// mais on les garde hors du contrôle de version pour permettre de changer
/// de projet Supabase (dev/prod) sans toucher au code.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Vrai si les deux valeurs ont été fournies à la compilation. Si faux,
  /// l'app doit rester utilisable hors ligne (skill offline-first-flutter)
  /// — voir l'appel conditionnel dans main.dart.
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

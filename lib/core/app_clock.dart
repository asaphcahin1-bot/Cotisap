import 'package:flutter/foundation.dart';

/// Horloge de l'app — utilisée à la place de `DateTime.now()` partout où
/// le code a besoin de "maintenant" pour ses calculs métier (échéances,
/// amendes automatiques, solde de prêt).
///
/// Renvoie toujours la vraie date en usage normal. **Simulable
/// uniquement en mode debug, ou dans un build de test terrain explicite**
/// (skill offline-first-flutter ne s'applique pas ici, mais même esprit
/// de prudence : jamais de comportement différent en production sans que
/// ce soit délibéré) — permet de dérouler plusieurs semaines/mois de
/// test sans toucher à l'horloge réelle du téléphone (qui peut perturber
/// d'autres apps/services, voir DECISIONS.md).
///
/// **Build de test terrain** (RETOURS_TERRAIN.md, point 5) : un APK
/// release normal (`flutter build apk --release`) reste verrouillé sur
/// `kDebugMode`, donc simulation impossible — c'est ce qui a bloqué le
/// premier test terrain du fondateur. Un build compilé avec
/// `--dart-define=FIELD_TEST_BUILD=true` déverrouille la simulation
/// même en release, réservé aux APK que le fondateur installe lui-même
/// sur son propre téléphone pour dérouler un test — **jamais utilisé
/// pour un vrai déploiement public**, où l'on revient à
/// `flutter build apk --release` sans ce define.
class AppClock {
  AppClock._();

  static const bool _fieldTestBuild = bool.fromEnvironment('FIELD_TEST_BUILD');

  static DateTime? _dateSimulee;

  static DateTime now() => _dateSimulee ?? DateTime.now();

  static bool get estSimulee => _dateSimulee != null;

  /// Vrai en mode debug, ou dans un build de test terrain — seule
  /// condition sous laquelle [definir] a un effet, et seule condition
  /// sous laquelle l'écran doit proposer le bouton "🧪 simuler une
  /// date" (voir `groups_list_screen.dart`).
  static bool get simulationAutorisee => kDebugMode || _fieldTestBuild;

  /// Ignoré silencieusement en dehors des cas ci-dessus — pas seulement
  /// un `assert` (retiré des builds release), une vraie garde à
  /// l'exécution.
  static void definir(DateTime? date) {
    if (!simulationAutorisee) return;
    _dateSimulee = date;
  }
}

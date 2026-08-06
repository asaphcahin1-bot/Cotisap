import 'package:flutter/foundation.dart';

/// Horloge de l'app — utilisée à la place de `DateTime.now()` partout où
/// le code a besoin de "maintenant" pour ses calculs métier (échéances,
/// amendes automatiques, solde de prêt).
///
/// Renvoie toujours la vraie date en usage normal. **Simulable
/// uniquement en mode debug** (skill offline-first-flutter ne s'applique
/// pas ici, mais même esprit de prudence : jamais de comportement
/// différent en production sans que ce soit délibéré) — permet de
/// dérouler plusieurs semaines/mois de test sans toucher à l'horloge
/// réelle du téléphone (qui peut perturber d'autres apps/services, voir
/// DECISIONS.md).
class AppClock {
  AppClock._();

  static DateTime? _dateSimulee;

  static DateTime now() => _dateSimulee ?? DateTime.now();

  static bool get estSimulee => _dateSimulee != null;

  /// Ignoré silencieusement en dehors du mode debug — pas seulement un
  /// `assert` (retiré des builds release), une vraie garde à
  /// l'exécution.
  static void definir(DateTime? date) {
    if (!kDebugMode) return;
    _dateSimulee = date;
  }
}

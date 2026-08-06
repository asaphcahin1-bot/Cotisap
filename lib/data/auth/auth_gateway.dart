/// Abstraction pour l'envoi/vérification de codes de confirmation par
/// téléphone (agent ET membre — même mécanisme, skill
/// two-tier-access-model : "numéro de téléphone + code de confirmation
/// envoyé par SMS, pas de mot de passe à retenir").
///
/// Décision (voir DECISIONS.md) : la production branchera Supabase Auth
/// (téléphone/OTP) avec Twilio comme fournisseur SMS sous-jacent. Aucun
/// compte externe n'est créé pour cette étape — [DevAuthGateway] permet
/// de développer et tester tout le reste sans dépendre d'un service SMS
/// ni d'une connexion réseau.
abstract class AuthGateway {
  /// Envoie (ou simule l'envoi) d'un code de confirmation au numéro
  /// donné. Renvoie le code — en production, le code ne serait jamais
  /// renvoyé ici, seulement livré par SMS ; le mode dev le renvoie pour
  /// permettre de tester le flux sans SMS réel.
  Future<String> envoyerCode(String phoneNumber);
}

class DevAuthGateway implements AuthGateway {
  /// Code de test fixe — jamais utilisé en production. Rend le
  /// développement et les tests manuels indépendants de tout service
  /// SMS externe.
  static const codeDeTest = '123456';

  @override
  Future<String> envoyerCode(String phoneNumber) async {
    return codeDeTest;
  }
}

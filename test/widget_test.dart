import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cotisapp/main.dart';

void main() {
  testWidgets("Écran d'identification affiché au démarrage", (WidgetTester tester) async {
    // Ce test ne touche jamais la base de données : l'écran de saisie du
    // numéro de téléphone s'affiche avant tout accès aux données locales,
    // ce qui permet de le tester sans dépendance sqlite native.
    await tester.pumpWidget(const ProviderScope(child: CotisAppRoot()));

    expect(find.text('CotisApp'), findsOneWidget);
    expect(find.text('Votre numéro de téléphone'), findsOneWidget);
  });
}

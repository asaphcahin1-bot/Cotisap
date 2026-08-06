# Vérifier CotisApp

## Tests automatisés

```bash
flutter test
```

Doit afficher `All tests passed!`. Le test le plus important est
`test/domain/calculators/end_of_cycle_calculator_test.dart` — il
vérifie que le calcul de répartition de fin de cycle respecte
exactement la formule du skill `avec-business-rules` sur un scénario
construit à partir des paramètres réels du dossier source (fourchette
de cotisation 500-5000 FCFA, taux d'intérêt 10 % observé à Kondoukro).

## Analyse statique

```bash
flutter analyze
```

Doit afficher `No issues found!`.

## Parcours manuel (mode avion)

L'app doit fonctionner de bout en bout sans réseau — c'est le point
central du skill `offline-first-flutter`. Pour vérifier :

1. Activer le mode avion sur l'appareil/l'émulateur
2. `flutter run`
3. Entrer un numéro de téléphone (écran d'accueil)
4. Créer un groupe (nom, durée de cycle, fréquence de réunion, valeur
   de la part, taux d'intérêt)
5. Ajouter 2-3 membres
6. Enregistrer quelques cotisations cash pour différents membres avec
   des nombres de parts différents
7. Enregistrer un prêt, le confirmer avec le code de test affiché
   (`123456`), puis enregistrer un remboursement couvrant capital +
   intérêt
8. Ajouter une amende sur un membre
9. Ouvrir "Répartition de fin de cycle" et vérifier que :
   - la valeur ajoutée par part = (intérêts perçus + amendes) / total
     des parts du groupe
   - chaque membre reçoit un montant différent, proportionnel à ses
     parts (jamais un partage égal)
   - le fonds de solidarité (si une contribution a été ajoutée)
     s'affiche séparément et n'influence pas les montants ci-dessus

Si une étape échoue en mode avion, c'est un bug bloquant pour ce
projet — pas un cas limite.

## Après une modification du schéma

Toute modification dans `lib/data/local/tables/` nécessite de
régénérer le code drift avant de relancer les tests :

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Limite connue de cet environnement de développement

Cette machine n'a ni SDK Android installé, ni le mode développeur
Windows activé (requis par Flutter pour les plugins natifs comme
`sqlite3_flutter_libs` sur desktop) — `flutter run` échoue donc ici
avec `Building with plugins requires symlink support`. Ce n'est pas un
bug du projet : `flutter test` et `flutter analyze` (qui ne dépendent
d'aucune des deux) passent tous les deux. Pour un vrai test interactif,
soit activer le mode développeur (`start ms-settings:developers`) pour
tester sur Windows, soit installer Android Studio/le SDK Android et
utiliser un appareil ou un émulateur — la cible réelle de distribution
selon le dossier produit.

import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/import/historical_import_parser.dart';

void main() {
  const parser = HistoricalImportParser();

  group('HistoricalImportParser', () {
    test('analyse des lignes valides avec dates et types variés', () {
      const csv = '''
Aya Kone,2024-03-15,5000,cotisation
Fatou Traore,15/03/2024,50000,pret
Fatou Traore,20/04/2024,55000,remboursement
Awa Diallo,03/2024,500,amende
''';
      final resultat = parser.analyser(csv);

      expect(resultat.erreurs, isEmpty);
      expect(resultat.lignesValides, hasLength(4));
      expect(resultat.nomsMembresDistincts, {'Aya Kone', 'Fatou Traore', 'Awa Diallo'});
      expect(resultat.montantTotalFcfa, 5000 + 50000 + 55000 + 500);
    });

    test('ignore une ligne d\'en-tête si le montant n\'est pas numérique', () {
      const csv = '''
nom,date,montant,type
Aya Kone,2024-03-15,5000,cotisation
''';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, isEmpty);
      expect(resultat.lignesValides, hasLength(1));
    });

    test('marque une date approximative (mois/année seul) sans bloquer l\'import', () {
      const csv = 'Aya Kone,03/2024,5000,cotisation';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, isEmpty);
      expect(resultat.lignesValides.single.estApproximatif, isTrue);
      expect(resultat.lignesValides.single.date, DateTime(2024, 3, 1));
    });

    test('marque un montant approximatif (préfixé "environ") sans bloquer l\'import', () {
      const csv = 'Aya Kone,2024-03-15,environ 5000,cotisation';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, isEmpty);
      expect(resultat.lignesValides.single.estApproximatif, isTrue);
      expect(resultat.lignesValides.single.montantFcfa, 5000);
    });

    test('rejette une ligne avec un type d\'opération inconnu', () {
      const csv = 'Aya Kone,2024-03-15,5000,virement';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, hasLength(1));
      expect(resultat.erreurs.single.numeroLigne, 1);
      expect(resultat.lignesValides, isEmpty);
    });

    test('rejette une ligne avec un montant totalement illisible', () {
      const csv = 'Aya Kone,2024-03-15,inconnu,cotisation';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, hasLength(1));
    });

    test('rejette une ligne avec une date totalement illisible', () {
      const csv = 'Aya Kone,pas une date,5000,cotisation';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, hasLength(1));
    });

    test('rejette une ligne incomplète (moins de 4 champs)', () {
      const csv = 'Aya Kone,2024-03-15,5000';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, hasLength(1));
    });

    test('continue d\'analyser les lignes suivantes après une erreur', () {
      const csv = '''
Aya Kone,pas une date,5000,cotisation
Fatou Traore,2024-03-15,3000,cotisation
''';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, hasLength(1));
      expect(resultat.lignesValides, hasLength(1));
      expect(resultat.lignesValides.single.nomMembre, 'Fatou Traore');
    });

    test('accepte "prêt" avec accent comme synonyme de "pret"', () {
      const csv = 'Fatou Traore,2024-03-15,50000,prêt';
      final resultat = parser.analyser(csv);
      expect(resultat.erreurs, isEmpty);
      expect(resultat.lignesValides.single.type, TypeOperationImportee.pret);
    });
  });
}

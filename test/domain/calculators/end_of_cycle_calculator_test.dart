import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/end_of_cycle_calculator.dart';

void main() {
  group('EndOfCycleCalculator — scénario Kondoukro', () {
    // Le PDF source (CotisApp_Resume.pdf) donne les paramètres réels
    // observés à Kondoukro (cotisations entre 500 et 5000 FCFA, taux
    // d'intérêt 10 %) mais pas un exemple chiffré complet de bout en
    // bout. Ce scénario reprend ces paramètres réels avec des montants
    // choisis pour être vérifiables à la main, afin de garantir que le
    // calculateur respecte exactement la formule du skill
    // avec-business-rules.
    //
    // Valeur de la part : 1000 FCFA (dans la fourchette 500-5000)
    // Taux d'intérêt : 10 % (taux observé à Kondoukro)
    //
    // Aya   : 5 parts -> cotisation 5000 FCFA
    // Fatou : 3 parts -> cotisation 3000 FCFA, a emprunté 50 000 FCFA à 10 %
    //         -> intérêt dû 5000 FCFA, remboursé intégralement avant la
    //         clôture du cycle -> intérêt perçu = 5000 FCFA
    // Awa   : 2 parts -> cotisation 2000 FCFA, a reçu une amende de 500 FCFA
    //         pour une absence non justifiée
    //
    // total_interets_amendes = 5000 + 500 = 5500
    // total_parts_du_groupe = 5 + 3 + 2 = 10
    // valeur_par_part = 5500 / 10 = 550
    //
    // Aya   : part_individuelle = 5 * 550 = 2750 -> total 5000 + 2750 = 7750
    // Fatou : part_individuelle = 3 * 550 = 1650 -> total 3000 + 1650 = 4650
    // Awa   : part_individuelle = 2 * 550 = 1100 -> total 2000 + 1100 = 3100

    const calculator = EndOfCycleCalculator();

    final input = const EndOfCycleInput(
      partsByMember: [
        MemberParts(memberId: 'aya', totalParts: 5),
        MemberParts(memberId: 'fatou', totalParts: 3),
        MemberParts(memberId: 'awa', totalParts: 2),
      ],
      partValueFcfa: 1000,
      totalInterestCollectedFcfa: 5000,
      totalFinesCollectedFcfa: 500,
    );

    test('calcule le total intérêts + amendes', () {
      final result = calculator.calculer(input);
      expect(result.totalInteretsAmendes, 5500);
    });

    test('calcule la valeur ajoutée par part', () {
      final result = calculator.calculer(input);
      expect(result.valeurParPart, 550);
    });

    test('calcule le montant total reçu par chaque membre, au prorata des parts', () {
      final result = calculator.calculer(input);

      final aya = result.resultatsParMembre.firstWhere((m) => m.memberId == 'aya');
      expect(aya.cotisationTotale, 5000);
      expect(aya.beneficeIndividuel, 2750);
      expect(aya.montantTotalRecu, 7750);

      final fatou = result.resultatsParMembre.firstWhere((m) => m.memberId == 'fatou');
      expect(fatou.cotisationTotale, 3000);
      expect(fatou.beneficeIndividuel, 1650);
      expect(fatou.montantTotalRecu, 4650);

      final awa = result.resultatsParMembre.firstWhere((m) => m.memberId == 'awa');
      expect(awa.cotisationTotale, 2000);
      expect(awa.beneficeIndividuel, 1100);
      expect(awa.montantTotalRecu, 3100);
    });

    test('ne répartit jamais à parts égales entre membres', () {
      final result = calculator.calculer(input);
      final montants = result.resultatsParMembre.map((m) => m.montantTotalRecu).toSet();
      // Des nombres de parts différents doivent donner des montants différents.
      expect(montants.length, 3);
    });

    test('la somme distribuée = somme des cotisations + total intérêts/amendes', () {
      final result = calculator.calculer(input);
      final sommeDistribuee = result.resultatsParMembre
          .fold<double>(0, (sum, m) => sum + m.montantTotalRecu);
      final sommeCotisations = result.resultatsParMembre
          .fold<double>(0, (sum, m) => sum + m.cotisationTotale);
      expect(sommeDistribuee, sommeCotisations + result.totalInteretsAmendes);
    });

    test('rejette un cycle sans aucune part', () {
      expect(
        () => calculator.calculer(const EndOfCycleInput(
          partsByMember: [],
          partValueFcfa: 1000,
          totalInterestCollectedFcfa: 0,
          totalFinesCollectedFcfa: 0,
        )),
        throwsArgumentError,
      );
    });
  });
}

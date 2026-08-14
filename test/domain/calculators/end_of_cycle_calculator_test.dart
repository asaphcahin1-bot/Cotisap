import 'package:flutter_test/flutter_test.dart';
import 'package:cotisapp/domain/calculators/end_of_cycle_calculator.dart';

/// Formule "caisse disponible" (voir DECISIONS.md, "Nouvelle formule de
/// partage : caisse disponible", 2026-08-09) — remplace l'ancienne
/// formule intérêts+amendes / total_parts.
void main() {
  const calculator = EndOfCycleCalculator();

  group('scénario Kondoukro — sans aucune dette', () {
    // Reprend les paramètres réels observés à Kondoukro (cotisations
    // entre 500 et 5000 FCFA, taux d'intérêt 10 %), avec des montants
    // choisis pour être vérifiables à la main.
    //
    // Valeur de la part : 1000 FCFA
    //
    // Aya   : 5 parts -> cotisation 5000 FCFA, aucune dette
    // Fatou : 3 parts -> cotisation 3000 FCFA, a emprunté 50 000 FCFA à
    //         10 %, remboursé intégralement -> intérêt perçu 5000 FCFA
    // Awa   : 2 parts -> cotisation 2000 FCFA, a reçu une amende de 500
    //         FCFA (réglée) pour une absence non justifiée
    //
    // caisse_disponible = 10000 (cotisations) + 500 (amendes) + 5000
    //                      (intérêts) - 0 (aucun prêt non remboursé)
    //                    = 15500
    // total_parts = 10 -> valeur_par_part = 1550
    // Aucun membre n'a de dette -> chacun touche valeur_par_part × ses
    // parts (pas de plafond à la cotisation).

    final input = const EndOfCycleInput(
      membres: [
        MemberCycleInput(
          memberId: 'aya',
          totalParts: 5,
          cotisationTotaleFcfa: 5000,
          detteFcfa: 0,
        ),
        MemberCycleInput(
          memberId: 'fatou',
          totalParts: 3,
          cotisationTotaleFcfa: 3000,
          detteFcfa: 0,
        ),
        MemberCycleInput(
          memberId: 'awa',
          totalParts: 2,
          cotisationTotaleFcfa: 2000,
          detteFcfa: 0,
        ),
      ],
      cotisationsTotalesGroupeFcfa: 10000,
      amendesRegleesFcfa: 500,
      interetsPercusFcfa: 5000,
      dettesEnCoursGroupeFcfa: 0,
    );

    test('calcule la caisse disponible', () {
      final result = calculator.calculer(input);
      expect(result.caisseDisponibleFcfa, 15500);
    });

    test('calcule la valeur par part', () {
      final result = calculator.calculer(input);
      expect(result.valeurParPart, 1550);
    });

    test('chaque membre reçoit valeur_par_part × ses parts, sans dette', () {
      final result = calculator.calculer(input);

      final aya = result.resultatsParMembre.firstWhere(
        (m) => m.memberId == 'aya',
      );
      expect(aya.aBeneficieDuBonus, isTrue);
      expect(aya.montantBrutFcfa, 7750);
      expect(aya.montantNetFcfa, 7750);

      final fatou = result.resultatsParMembre.firstWhere(
        (m) => m.memberId == 'fatou',
      );
      expect(fatou.montantNetFcfa, 4650);

      final awa = result.resultatsParMembre.firstWhere(
        (m) => m.memberId == 'awa',
      );
      expect(awa.montantNetFcfa, 3100);
    });

    test('ne répartit jamais à parts égales entre membres', () {
      final result = calculator.calculer(input);
      final montants = result.resultatsParMembre
          .map((m) => m.montantNetFcfa)
          .toSet();
      expect(montants.length, 3);
    });

    test('rejette un cycle sans aucun membre', () {
      expect(
        () => calculator.calculer(
          const EndOfCycleInput(
            membres: [],
            cotisationsTotalesGroupeFcfa: 0,
            amendesRegleesFcfa: 0,
            interetsPercusFcfa: 0,
            dettesEnCoursGroupeFcfa: 0,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('un prêt non remboursé dilue la caisse pour tout le groupe', () {
    // Même groupe que Kondoukro, mais Fatou n'a PAS remboursé son prêt
    // de 50 000 FCFA (donc aucun intérêt perçu sur ce prêt, et son
    // capital est "en cours" — déduit de la caisse commune).
    //
    // caisse_disponible = 10000 + 500 + 0 - 50000 = -39500 -> clampée à 0
    // valeur_par_part = 0 -> tout membre sans dette personnelle touche 0
    // (mais rien de négatif, jamais un membre ne "doit" à l'AVEC juste
    // pour avoir des parts).

    test('la caisse ne descend jamais sous zéro, même très négative', () {
      final result = calculator.calculer(
        const EndOfCycleInput(
          membres: [
            MemberCycleInput(
              memberId: 'aya',
              totalParts: 5,
              cotisationTotaleFcfa: 5000,
              detteFcfa: 0,
            ),
          ],
          cotisationsTotalesGroupeFcfa: 10000,
          amendesRegleesFcfa: 500,
          interetsPercusFcfa: 0,
          dettesEnCoursGroupeFcfa: 50000,
        ),
      );
      expect(result.caisseDisponibleFcfa, 0);
      expect(result.valeurParPart, 0);
      expect(result.resultatsParMembre.single.montantNetFcfa, 0);
    });

    test(
      'une dilution partielle réduit la part de TOUS les membres, pas seulement le débiteur',
      () {
        // Cotisations 10000, amendes 0, intérêts 0, dettes en cours 4000
        // -> caisse 6000, total parts 10 -> valeur_par_part 600 (au lieu
        // de 1000 sans le prêt impayé) : chaque membre touche moins,
        // même Awa qui n'a jamais emprunté.
        final result = calculator.calculer(
          const EndOfCycleInput(
            membres: [
              MemberCycleInput(
                memberId: 'aya',
                totalParts: 5,
                cotisationTotaleFcfa: 5000,
                detteFcfa: 0,
              ),
              MemberCycleInput(
                memberId: 'awa',
                totalParts: 5,
                cotisationTotaleFcfa: 5000,
                detteFcfa: 0,
              ),
            ],
            cotisationsTotalesGroupeFcfa: 10000,
            amendesRegleesFcfa: 0,
            interetsPercusFcfa: 0,
            dettesEnCoursGroupeFcfa: 4000,
          ),
        );
        expect(result.valeurParPart, 600);
        final awa = result.resultatsParMembre.firstWhere(
          (m) => m.memberId == 'awa',
        );
        expect(
          awa.montantNetFcfa,
          3000,
        ); // 600 x 5, moins que sa cotisation de 5000
      },
    );
  });

  group('un membre endetté ne touche aucun bénéfice collectif', () {
    // Reprend l'exemple donné par le fondateur : cotisé 500 000, dette
    // 100 000 au moment du partage -> reçoit exactement 400 000, quel
    // que soit l'état de la caisse collective.
    test('cotisé 500 000, dette 100 000 : reçoit exactement 400 000', () {
      final result = calculator.calculer(
        const EndOfCycleInput(
          membres: [
            MemberCycleInput(
              memberId: 'seydou',
              totalParts: 500,
              cotisationTotaleFcfa: 500000,
              detteFcfa: 100000,
            ),
            // Un second membre pour que le calcul de valeur_par_part reste
            // défini (total_parts > 0 même sans Seydou).
            MemberCycleInput(
              memberId: 'mariam',
              totalParts: 10,
              cotisationTotaleFcfa: 10000,
              detteFcfa: 0,
            ),
          ],
          cotisationsTotalesGroupeFcfa: 510000,
          amendesRegleesFcfa: 100000, // caisse très bénéficiaire cette année
          interetsPercusFcfa: 0,
          dettesEnCoursGroupeFcfa: 0,
        ),
      );

      final seydou = result.resultatsParMembre.firstWhere(
        (m) => m.memberId == 'seydou',
      );
      expect(seydou.aBeneficieDuBonus, isFalse);
      expect(
        seydou.montantBrutFcfa,
        500000,
        reason: 'plafonné à sa cotisation, pas de bénéfice',
      );
      expect(seydou.montantNetFcfa, 400000);
      expect(seydou.pertAvecFcfa, 0);

      // Mariam, elle, profite bien du bénéfice collectif (amendes
      // réglées de 100 000 réparties sur les 510 parts).
      final mariam = result.resultatsParMembre.firstWhere(
        (m) => m.memberId == 'mariam',
      );
      expect(mariam.aBeneficieDuBonus, isTrue);
    });

    test(
      'une dette supérieure à la cotisation : membre reçoit 0, perte pour l\'AVEC',
      () {
        final result = calculator.calculer(
          const EndOfCycleInput(
            membres: [
              MemberCycleInput(
                memberId: 'seydou',
                totalParts: 5,
                cotisationTotaleFcfa: 50000,
                detteFcfa: 80000,
              ),
            ],
            cotisationsTotalesGroupeFcfa: 50000,
            amendesRegleesFcfa: 0,
            interetsPercusFcfa: 0,
            dettesEnCoursGroupeFcfa: 0,
          ),
        );
        final seydou = result.resultatsParMembre.single;
        expect(seydou.montantNetFcfa, 0);
        expect(seydou.montantDeduitFcfa, 50000);
        expect(seydou.pertAvecFcfa, 30000);
      },
    );
  });

  group(
    'résidu d\'une réduction pour amende non soldée (voir AmendeReductionCalculator)',
    () {
      // Reprend l'exemple du fondateur : cotisé 10 000 F, amende de 200 F
      // non soldée -> 9 parts reconnues + 800 F de résidu. Sans dette de
      // prêt : le membre touche le bénéfice sur 9 parts SEULEMENT, plus
      // les 800 F tels quels.
      test(
        'sans dette de prêt : bénéfice sur les parts reconnues + résidu sans bénéfice',
        () {
          final result = calculator.calculer(
            const EndOfCycleInput(
              membres: [
                MemberCycleInput(
                  memberId: 'seydou',
                  totalParts: 9, // déjà réduit par AmendeReductionCalculator
                  cotisationTotaleFcfa: 9800, // 9x1000 + 800 résidu
                  detteFcfa: 0,
                  residuSansBonusFcfa: 800,
                ),
                MemberCycleInput(
                  memberId: 'mariam',
                  totalParts: 1,
                  cotisationTotaleFcfa: 1000,
                  detteFcfa: 0,
                ),
              ],
              // Pot commun = 9x1000 (parts reconnues de Seydou, JAMAIS son
              // résidu — voir doc de
              // EndOfCycleInput.cotisationsTotalesGroupeFcfa) + 1000
              // (Mariam) = 10000. Le résidu de Seydou (800) lui revient
              // à part, financé par sa propre cotisation, jamais par le
              // pot commun.
              cotisationsTotalesGroupeFcfa: 10000,
              amendesRegleesFcfa: 200,
              interetsPercusFcfa: 0,
              dettesEnCoursGroupeFcfa: 0,
            ),
          );
          // total_parts = 9 (Seydou) + 1 (Mariam) = 10 -> valeur_par_part =
          // (10000 + 200) / 10 = 1020.
          expect(result.valeurParPart, 1020);
          final seydou = result.resultatsParMembre.firstWhere(
            (m) => m.memberId == 'seydou',
          );
          // 9 x 1020 (bénéfice sur les 9 parts reconnues) + 800 (résidu,
          // sans bénéfice) = 9980.
          expect(seydou.montantBrutFcfa, 9980);
          expect(seydou.montantNetFcfa, 9980);
          expect(seydou.aBeneficieDuBonus, isTrue);
          final mariam = result.resultatsParMembre.firstWhere(
            (m) => m.memberId == 'mariam',
          );
          expect(mariam.montantBrutFcfa, 1020);
          // Conservation : rien ne se perd ni ne se crée. Tout ce qui est
          // distribué (9980 + 1020 = 11000) correspond exactement à ce
          // que le groupe a réellement collecté (10000 F cotisés bruts +
          // 1000 F cotisés bruts, la seule différence étant la
          // ventilation entre bénéfice collectif et résidu individuel).
          expect(seydou.montantBrutFcfa + mariam.montantBrutFcfa, 11000);
        },
      );

      test(
        'avec une dette de prêt en plus : le résidu est déjà inclus dans le plafond, pas ajouté deux fois',
        () {
          final result = calculator.calculer(
            const EndOfCycleInput(
              membres: [
                MemberCycleInput(
                  memberId: 'seydou',
                  totalParts: 9,
                  cotisationTotaleFcfa: 9800,
                  detteFcfa: 3000,
                  residuSansBonusFcfa: 800,
                ),
              ],
              // Pot commun = 9x1000 (parts reconnues, résidu exclu — voir
              // le test précédent).
              cotisationsTotalesGroupeFcfa: 9000,
              amendesRegleesFcfa: 200,
              interetsPercusFcfa: 0,
              dettesEnCoursGroupeFcfa: 0,
            ),
          );
          final seydou = result.resultatsParMembre.single;
          expect(seydou.aBeneficieDuBonus, isFalse);
          // Plafonné à 9800 (déjà net de l'amende, résidu inclus), pas
          // 9800 + 800 une deuxième fois.
          expect(seydou.montantBrutFcfa, 9800);
          expect(seydou.montantNetFcfa, 6800); // 9800 - 3000 de dette de prêt
        },
      );
    },
  );

  group('validation des entrées', () {
    test('rejette des cotisations totales négatives', () {
      expect(
        () => calculator.calculer(
          const EndOfCycleInput(
            membres: [
              MemberCycleInput(
                memberId: 'a',
                totalParts: 1,
                cotisationTotaleFcfa: 0,
                detteFcfa: 0,
              ),
            ],
            cotisationsTotalesGroupeFcfa: -1,
            amendesRegleesFcfa: 0,
            interetsPercusFcfa: 0,
            dettesEnCoursGroupeFcfa: 0,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejette une dette individuelle négative', () {
      expect(
        () => calculator.calculer(
          const EndOfCycleInput(
            membres: [
              MemberCycleInput(
                memberId: 'a',
                totalParts: 1,
                cotisationTotaleFcfa: 0,
                detteFcfa: -1,
              ),
            ],
            cotisationsTotalesGroupeFcfa: 0,
            amendesRegleesFcfa: 0,
            interetsPercusFcfa: 0,
            dettesEnCoursGroupeFcfa: 0,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejette un total de parts nul', () {
      expect(
        () => calculator.calculer(
          const EndOfCycleInput(
            membres: [
              MemberCycleInput(
                memberId: 'a',
                totalParts: 0,
                cotisationTotaleFcfa: 0,
                detteFcfa: 0,
              ),
            ],
            cotisationsTotalesGroupeFcfa: 0,
            amendesRegleesFcfa: 0,
            interetsPercusFcfa: 0,
            dettesEnCoursGroupeFcfa: 0,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

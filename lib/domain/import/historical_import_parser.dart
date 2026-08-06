/// Parseur de l'import d'historique (skill `historical-data-import`).
///
/// Format attendu, une opération par ligne :
/// `nom du membre,date,montant,type d'opération`
///
/// Types reconnus : cotisation, pret (ou prêt), remboursement, amende,
/// fonds_solidarite (ou fonds).
///
/// Pur (aucune dépendance à drift/Flutter) pour rester testable
/// directement — voir test/domain/import/.
library;

enum TypeOperationImportee {
  cotisation,
  pret,
  remboursement,
  amende,
  fondsSolidarite,
}

class LigneImportAnalysee {
  final int numeroLigne;
  final String nomMembre;
  final DateTime date;
  final int montantFcfa;
  final TypeOperationImportee type;

  /// Le carnet papier d'origine n'a pas toujours une date ou un montant
  /// exacts (skill historical-data-import : "ne pas bloquer un import
  /// parce qu'une date est incertaine ou un montant approximatif").
  final bool estApproximatif;

  const LigneImportAnalysee({
    required this.numeroLigne,
    required this.nomMembre,
    required this.date,
    required this.montantFcfa,
    required this.type,
    required this.estApproximatif,
  });
}

class ErreurImport {
  final int numeroLigne;
  final String message;

  const ErreurImport({required this.numeroLigne, required this.message});
}

class ResultatAnalyseImport {
  final List<LigneImportAnalysee> lignesValides;
  final List<ErreurImport> erreurs;

  const ResultatAnalyseImport({
    required this.lignesValides,
    required this.erreurs,
  });

  bool get aDesErreurs => erreurs.isNotEmpty;

  Set<String> get nomsMembresDistincts =>
      lignesValides.map((l) => l.nomMembre).toSet();

  int get montantTotalFcfa =>
      lignesValides.fold(0, (sum, l) => sum + l.montantFcfa);
}

class HistoricalImportParser {
  const HistoricalImportParser();

  static const _typesReconnus = {
    'cotisation': TypeOperationImportee.cotisation,
    'pret': TypeOperationImportee.pret,
    'prêt': TypeOperationImportee.pret,
    'remboursement': TypeOperationImportee.remboursement,
    'amende': TypeOperationImportee.amende,
    'fonds_solidarite': TypeOperationImportee.fondsSolidarite,
    'fonds': TypeOperationImportee.fondsSolidarite,
  };

  ResultatAnalyseImport analyser(String contenuCsv) {
    final lignesValides = <LigneImportAnalysee>[];
    final erreurs = <ErreurImport>[];

    final lignesBrutes = contenuCsv
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (var i = 0; i < lignesBrutes.length; i++) {
      final numeroLigne = i + 1;
      final champs = lignesBrutes[i].split(',').map((c) => c.trim()).toList();

      if (champs.length < 4) {
        erreurs.add(ErreurImport(
          numeroLigne: numeroLigne,
          message:
              'Ligne incomplète — 4 champs attendus (nom,date,montant,type), ${champs.length} trouvé(s).',
        ));
        continue;
      }

      final nomMembre = champs[0];
      final dateBrute = champs[1];
      final montantBrut = champs[2];
      final typeBrut = champs[3];

      // La première ligne peut être un en-tête (ex. "nom,date,montant,type") —
      // on l'ignore silencieusement seulement si NI le montant NI le type
      // ne sont reconnaissables (une vraie ligne de données invalide avec
      // un type valide mais un montant illisible doit rester une erreur).
      if (numeroLigne == 1 &&
          _extraireMontant(montantBrut) == null &&
          !_typesReconnus.containsKey(typeBrut.toLowerCase())) {
        continue;
      }

      if (nomMembre.isEmpty) {
        erreurs.add(ErreurImport(
          numeroLigne: numeroLigne,
          message: 'Nom du membre manquant.',
        ));
        continue;
      }

      final type = _typesReconnus[typeBrut.toLowerCase()];
      if (type == null) {
        erreurs.add(ErreurImport(
          numeroLigne: numeroLigne,
          message:
              'Type d\'opération "$typeBrut" non reconnu (attendu : cotisation, pret, remboursement, amende, fonds_solidarite).',
        ));
        continue;
      }

      final montant = _extraireMontant(montantBrut);
      if (montant == null) {
        erreurs.add(ErreurImport(
          numeroLigne: numeroLigne,
          message: 'Montant "$montantBrut" illisible.',
        ));
        continue;
      }

      final dateAnalysee = _analyserDate(dateBrute);
      if (dateAnalysee == null) {
        erreurs.add(ErreurImport(
          numeroLigne: numeroLigne,
          message:
              'Date "$dateBrute" illisible (formats acceptés : AAAA-MM-JJ, JJ/MM/AAAA, MM/AAAA, AAAA).',
        ));
        continue;
      }

      final estApproximatif = montant.estApproximatif || dateAnalysee.estApproximative;

      lignesValides.add(LigneImportAnalysee(
        numeroLigne: numeroLigne,
        nomMembre: nomMembre,
        date: dateAnalysee.date,
        montantFcfa: montant.valeur,
        type: type,
        estApproximatif: estApproximatif,
      ));
    }

    return ResultatAnalyseImport(lignesValides: lignesValides, erreurs: erreurs);
  }

  _MontantAnalyse? _extraireMontant(String brut) {
    final estApproximatif = brut.contains('~') ||
        brut.toLowerCase().contains('environ') ||
        brut.toLowerCase().contains('approx');
    final chiffresSeuls = brut.replaceAll(RegExp(r'[^0-9]'), '');
    if (chiffresSeuls.isEmpty) return null;
    final valeur = int.tryParse(chiffresSeuls);
    if (valeur == null) return null;
    return _MontantAnalyse(valeur: valeur, estApproximatif: estApproximatif);
  }

  _DateAnalysee? _analyserDate(String brut) {
    // AAAA-MM-JJ
    final isoComplet = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(brut);
    if (isoComplet != null) {
      return _construireDate(
        annee: isoComplet.group(1)!,
        mois: isoComplet.group(2)!,
        jour: isoComplet.group(3)!,
        estApproximative: false,
      );
    }

    // JJ/MM/AAAA
    final jourMoisAnnee = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(brut);
    if (jourMoisAnnee != null) {
      return _construireDate(
        annee: jourMoisAnnee.group(3)!,
        mois: jourMoisAnnee.group(2)!,
        jour: jourMoisAnnee.group(1)!,
        estApproximative: false,
      );
    }

    // MM/AAAA — jour inconnu, approximatif
    final moisAnnee = RegExp(r'^(\d{1,2})/(\d{4})$').firstMatch(brut);
    if (moisAnnee != null) {
      return _construireDate(
        annee: moisAnnee.group(2)!,
        mois: moisAnnee.group(1)!,
        jour: '1',
        estApproximative: true,
      );
    }

    // AAAA seul — mois et jour inconnus, approximatif
    final anneeSeule = RegExp(r'^(\d{4})$').firstMatch(brut);
    if (anneeSeule != null) {
      return _construireDate(
        annee: anneeSeule.group(1)!,
        mois: '1',
        jour: '1',
        estApproximative: true,
      );
    }

    return null;
  }

  _DateAnalysee? _construireDate({
    required String annee,
    required String mois,
    required String jour,
    required bool estApproximative,
  }) {
    final a = int.tryParse(annee);
    final m = int.tryParse(mois);
    final j = int.tryParse(jour);
    if (a == null || m == null || j == null) return null;
    if (m < 1 || m > 12 || j < 1 || j > 31) return null;
    try {
      final date = DateTime(a, m, j);
      return _DateAnalysee(date: date, estApproximative: estApproximative);
    } catch (_) {
      return null;
    }
  }
}

class _MontantAnalyse {
  final int valeur;
  final bool estApproximatif;
  const _MontantAnalyse({required this.valeur, required this.estApproximatif});
}

class _DateAnalysee {
  final DateTime date;
  final bool estApproximative;
  const _DateAnalysee({required this.date, required this.estApproximative});
}

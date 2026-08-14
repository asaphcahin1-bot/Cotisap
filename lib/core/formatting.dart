import 'package:intl/intl.dart';

/// Formatage des montants — toujours en FCFA, jamais de décimales,
/// séparateur de milliers (skill localisation-fr-afrique-ouest).
String formatFcfa(num montant) {
  final formatter = NumberFormat.decimalPattern('fr_FR');
  return '${formatter.format(montant.round())} FCFA';
}

/// "10 %" plutôt que "10.0 %" : un taux d'intérêt est stocké en `double`
/// (`Prets.interestRatePercent`) mais toujours une valeur ronde en
/// pratique (10 ou 15, voir `LoanRateResolver`) — l'affichage brut d'un
/// double ajoutait un ".0" qui n'apporte rien à l'agent. Garde une
/// décimale si elle existe vraiment (ex : un taux importé non rond).
String formatPercent(double value) {
  final estEntier = value == value.roundToDouble();
  return estEntier ? '${value.toInt()} %' : '$value %';
}

const _joursFr = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

const _moisFr = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Libellé affiché pour une fréquence de réunion — précise le rythme
/// réel entre parenthèses ("une fois par semaine"...) pour lever toute
/// ambiguïté à la création/l'édition d'un groupe (demande du
/// fondateur, 2026-08-08).
String formatMeetingFrequency(String meetingFrequency) {
  switch (meetingFrequency) {
    case 'hebdomadaire':
      return 'Hebdomadaire (une fois par semaine)';
    case 'bimensuelle':
      return 'Bimensuelle (deux fois par mois)';
    case 'mensuelle':
      return 'Mensuelle (une fois par mois)';
    default:
      return meetingFrequency;
  }
}

/// Formatage manuel plutôt que `DateFormat('EEEE d MMMM', 'fr_FR')` : ce
/// projet n'appelle jamais `initializeDateFormatting()` (aucun autre
/// écran n'a besoin des données de locale `intl` pour les dates), une
/// table de noms en dur évite d'ajouter cette dépendance d'initialisation
/// pour ce seul écran.
String formatDateFr(DateTime date) {
  final jour = _joursFr[date.weekday - 1];
  final mois = _moisFr[date.month - 1];
  return '$jour ${date.day} $mois ${date.year}';
}

/// "août 2026" — libellé d'un mois, utilisé pour regrouper l'historique
/// des cotisations par mois (demande du fondateur, voir DECISIONS.md
/// "Historique des cotisations regroupé par mois") : un cycle courant
/// sur plusieurs mois donnerait sinon une liste de dates interminable à
/// faire défiler.
String formatMoisAnneeFr(DateTime date) {
  final mois = _moisFr[date.month - 1];
  return '$mois ${date.year}';
}

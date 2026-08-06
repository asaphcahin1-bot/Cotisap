import 'package:intl/intl.dart';

/// Formatage des montants — toujours en FCFA, jamais de décimales,
/// séparateur de milliers (skill localisation-fr-afrique-ouest).
String formatFcfa(num montant) {
  final formatter = NumberFormat.decimalPattern('fr_FR');
  return '${formatter.format(montant.round())} FCFA';
}

import 'package:flutter/material.dart';

/// Pavé de capture de signature — pas de dépendance externe (skill
/// offline-first-flutter : éviter les paquets tiers évitables après
/// l'expérience file_picker/KGP, voir ROADMAP.md). Sert de preuve de
/// présence en personne pour la confirmation d'un prêt d'un membre sans
/// téléphone (skill member-consent-rules).
///
/// La signature est encodée en texte compact (traits séparés par `|`,
/// points séparés par `;`, coordonnées séparées par `,`) plutôt qu'en
/// image — suffisant comme preuve capturée à l'écran, sans dépendance à
/// un encodeur PNG.
class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _traits = [];

  bool get estVide => _traits.isEmpty;

  void effacer() => setState(_traits.clear);

  /// Encodage compact de la signature capturée, à stocker tel quel dans
  /// `pret_confirmations.signature_data`.
  String exporter() {
    return _traits
        .map((trait) => trait
            .map((p) => '${p.dx.toStringAsFixed(1)},${p.dy.toStringAsFixed(1)}')
            .join(';'))
        .join('|');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onPanStart: (details) {
            setState(() => _traits.add([details.localPosition]));
          },
          onPanUpdate: (details) {
            setState(() => _traits.last.add(details.localPosition));
          },
          child: CustomPaint(
            painter: _SignaturePainter(_traits, Theme.of(context).colorScheme.onSurface),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> traits;
  final Color couleur;

  _SignaturePainter(this.traits, this.couleur);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = couleur
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final trait in traits) {
      for (var i = 0; i < trait.length - 1; i++) {
        canvas.drawLine(trait[i], trait[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Crisp vector-painted official 4-color Google 'G' mark (zero external PNG dependency).
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.21;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red top arc
    canvas.drawArc(
      rect,
      _deg(-145),
      _deg(105),
      false,
      arcPaint(const Color(0xFFEA4335)),
    );
    // Yellow left arc
    canvas.drawArc(
      rect,
      _deg(145),
      _deg(70),
      false,
      arcPaint(const Color(0xFFFBBC05)),
    );
    // Green bottom arc
    canvas.drawArc(
      rect,
      _deg(42),
      _deg(103),
      false,
      arcPaint(const Color(0xFF34A853)),
    );
    // Blue right arc
    canvas.drawArc(
      rect,
      _deg(-12),
      _deg(54),
      false,
      arcPaint(const Color(0xFF4285F4)),
    );

    // Horizontal blue bar of the 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.50,
          size.height * 0.41,
          size.width * 0.46,
          stroke * 0.92,
        ),
        Radius.circular(stroke * 0.18),
      ),
      barPaint,
    );
  }

  double _deg(double d) => d * math.pi / 180.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

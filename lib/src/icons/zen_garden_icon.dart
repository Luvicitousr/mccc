import 'package:flutter/widgets.dart';

/// A simple Zen Garden icon drawn with CustomPainter.
class ZenGardenIcon extends StatelessWidget {
  /// Size of the icon (width and height).
  final double size;
  /// Color of the garden elements (ripples, rock, rake).
  final Color color;

  const ZenGardenIcon({
    Key? key,
    this.size = 24.0,
    this.color = const Color.fromARGB(255, 255, 255, 255),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ZenGardenPainter(color),
      ),
    );
  }
}

class _ZenGardenPainter extends CustomPainter {
  final Color color;
  _ZenGardenPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    // Center point
    final center = Offset(size.width / 2, size.height / 2);

    // Draw ripples (concentric circles)
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        size.width * (0.15 * i),
        paint,
      );
    }

    // Draw rock (oval)
    final rockWidth = size.width * 0.2;
    final rockHeight = size.height * 0.12;
    final rockRect = Rect.fromCenter(
      center: Offset(center.dx - rockWidth, center.dy + rockHeight),
      width: rockWidth,
      height: rockHeight,
    );
    canvas.drawOval(rockRect, paint);

    // Draw rake lines (three parallel curved lines)
    final rakePath = Path();
    final startY = center.dy + size.height * 0.25;
    for (int j = 0; j < 3; j++) {
      final offsetY = startY + j * size.height * 0.05;
      rakePath.moveTo(size.width * 0.2, offsetY);
      rakePath.quadraticBezierTo(
        center.dx,
        offsetY - size.height * 0.1,
        size.width * 0.8,
        offsetY,
      );
    }
    canvas.drawPath(rakePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

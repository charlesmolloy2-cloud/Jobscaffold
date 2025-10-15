import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TempLogo extends StatelessWidget {
  final double size;
  final String text;
  const TempLogo({super.key, this.size = 28, this.text = 'Site bench'});

  @override
  Widget build(BuildContext context) {
    final color = kGreenDark;
    final dot = Container(
      width: size * 0.22,
      height: size * 0.22,
      decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Bridge arc
            CustomPaint(
              size: Size.square(size),
              painter: _BridgePainter(color),
            ),
            // Pylon dots
            Positioned(left: size * 0.18, bottom: size * 0.22, child: dot),
            Positioned(right: size * 0.18, bottom: size * 0.22, child: dot),
          ],
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: size * 0.7,
            color: kBlack,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _BridgePainter extends CustomPainter {
  final Color color;
  _BridgePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    // Simple arc like a bridge span
    path.moveTo(w * 0.1, h * 0.7);
    path.quadraticBezierTo(w * 0.5, h * 0.15, w * 0.9, h * 0.7);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

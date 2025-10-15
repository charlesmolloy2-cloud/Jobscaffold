import 'package:flutter/material.dart';

// SiteBench: A platform for project clarity between contractor and client
// Subtle blueprint grid background for hero sections or full-page wraps.
class BlueprintBackground extends StatelessWidget {
  final Widget child;
  final double gridSize;
  final double lineThickness;
  final Color background;
  final Color lineColor;
  final EdgeInsets padding;

  const BlueprintBackground({
    super.key,
    required this.child,
    this.gridSize = 24,
    this.lineThickness = 0.6,
    this.background = const Color(0xFF1C2A3A), // deep slate-blue
    this.lineColor = const Color(0xFF2E3E52),
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: CustomPaint(
        painter: _GridPainter(gridSize: gridSize, lineThickness: lineThickness, lineColor: lineColor),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double gridSize;
  final double lineThickness;
  final Color lineColor;

  _GridPainter({required this.gridSize, required this.lineThickness, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineThickness;

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.lineThickness != lineThickness ||
        oldDelegate.lineColor != lineColor;
  }
}

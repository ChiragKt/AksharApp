import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/recognition_state.dart';

class DrawingCanvas extends StatelessWidget {
  final List<DrawPoint> points;
  final void Function(Offset offset, bool isStart) onPointAdded;

  const DrawingCanvas({super.key, required this.points, required this.onPointAdded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => onPointAdded(d.localPosition, true),
      onPanUpdate: (d) => onPointAdded(d.localPosition, false),
      child: CustomPaint(
        painter: _CanvasPainter(points: points),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawPoint> points;
  _CanvasPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawBorderOrnament(canvas, size);
    if (points.isEmpty) return;

    // Subtle glow layer
    final glowPaint = Paint()
      ..color = AppTheme.teal.withValues(alpha: 0.2)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Main stroke — matte gold (solid, no gradient)
    final paint = Paint()
      ..color = AppTheme.gold
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool pathOpen = false;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.isStart || i == 0) {
        if (pathOpen) {
          canvas.drawPath(path, glowPaint);
          canvas.drawPath(path, paint);
          path.reset();
        }
        path.moveTo(p.offset.dx, p.offset.dy);
        pathOpen = true;
      } else {
        if (i + 1 < points.length && !points[i + 1].isStart) {
          final mid = Offset(
            (p.offset.dx + points[i + 1].offset.dx) / 2,
            (p.offset.dy + points[i + 1].offset.dy) / 2,
          );
          path.quadraticBezierTo(p.offset.dx, p.offset.dy, mid.dx, mid.dy);
        } else {
          path.lineTo(p.offset.dx, p.offset.dy);
        }
      }
    }

    if (pathOpen) {
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = AppTheme.gold.withValues(alpha: 0.08);
    const spacing = 30.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }
  }

  void _drawBorderOrnament(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.gold.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const inset = 10.0;
    const len = 22.0;
    // Top-left
    canvas.drawLine(Offset(inset, inset + len), Offset(inset, inset), linePaint);
    canvas.drawLine(Offset(inset, inset), Offset(inset + len, inset), linePaint);
    // Top-right
    canvas.drawLine(Offset(size.width - inset, inset + len), Offset(size.width - inset, inset), linePaint);
    canvas.drawLine(Offset(size.width - inset, inset), Offset(size.width - inset - len, inset), linePaint);
    // Bottom-left
    canvas.drawLine(Offset(inset, size.height - inset - len), Offset(inset, size.height - inset), linePaint);
    canvas.drawLine(Offset(inset, size.height - inset), Offset(inset + len, size.height - inset), linePaint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - inset, size.height - inset - len), Offset(size.width - inset, size.height - inset), linePaint);
    canvas.drawLine(Offset(size.width - inset, size.height - inset), Offset(size.width - inset - len, size.height - inset), linePaint);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => old.points != points;
}

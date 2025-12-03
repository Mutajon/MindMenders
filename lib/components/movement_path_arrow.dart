import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MovementPathArrow extends PositionComponent {
  final List<Vector2> pathPoints;
  final Color color;
  final double strokeWidth;

  MovementPathArrow({
    required this.pathPoints,
    this.color = const Color(0xFF448AFF), // Blue
    this.strokeWidth = 4.0,
  });

  @override
  void render(Canvas canvas) {
    if (pathPoints.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(pathPoints.first.x, pathPoints.first.y);

    for (int i = 1; i < pathPoints.length; i++) {
      path.lineTo(pathPoints[i].x, pathPoints[i].y);
    }

    canvas.drawPath(path, paint);

    // Draw arrowhead at the end
    _drawArrowHead(canvas);
  }

  void _drawArrowHead(Canvas canvas) {
    if (pathPoints.length < 2) return;

    final end = pathPoints.last;
    final prev = pathPoints[pathPoints.length - 2];
    
    // Calculate direction vector
    final direction = end - prev;
    if (direction.length == 0) return;
    
    final normalizedDir = direction.normalized();
    final angle = atan2(normalizedDir.y, normalizedDir.x);

    final arrowSize = 12.0;
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(end.x, end.y);
    canvas.rotate(angle);

    final arrowPath = Path();
    arrowPath.moveTo(0, 0);
    arrowPath.lineTo(-arrowSize, -arrowSize / 2);
    arrowPath.lineTo(-arrowSize, arrowSize / 2);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();
  }
}

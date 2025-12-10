import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MovementPathArrow extends PositionComponent {
  final List<Vector2> pathPoints;
  final Color color;
  final double strokeWidth;
  
  // Neural signal properties
  final List<double> _signals = [];
  double _timer = 0;
  final double _spawnInterval = 1.0;
  final double _travelDuration = 0.5;

  MovementPathArrow({
    required this.pathPoints,
    this.color = const Color(0xFF448AFF), // Blue
    this.strokeWidth = 4.0,
  });

  @override
  void update(double dt) {
    super.update(dt);
    
    // Spawn signal
    _timer += dt;
    if (_timer >= _spawnInterval) {
      _timer = 0;
      _signals.add(0.0);
    }
    
    // Move signals
    for (int i = 0; i < _signals.length; i++) {
        _signals[i] += dt / _travelDuration;
    }
    
    // Cleanup finished signals
    _signals.removeWhere((p) => p >= 1.0);
  }

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

    // Draw signals
    _drawSignals(canvas);

    // Draw arrowhead at the end
    _drawArrowHead(canvas);
  }

  void _drawSignals(Canvas canvas) {
      if (_signals.isEmpty) return;
      
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        
      for (final progress in _signals) {
          final pos = _getPointAtProgress(progress);
          // Draw a small segment centered at pos? Or just a dot? 
          // User asked for "glowing small segment".
          // Let's calculate a "tail" for the segment to give it direction/motion blur.
          
          final tailProgress = (progress - 0.05).clamp(0.0, 1.0);
          if (progress != tailProgress) {
              final tailPos = _getPointAtProgress(tailProgress);
              canvas.drawLine(tailPos.toOffset(), pos.toOffset(), glowPaint);
          } else {
              // Just a dot if at start
              canvas.drawCircle(pos.toOffset(), strokeWidth/2, glowPaint..style = PaintingStyle.fill);
          }
      }
  }
  
  Vector2 _getPointAtProgress(double progress) {
      // Calculate total length first (optimization: can cache this)
      double totalLength = 0;
      final segmentLengths = <double>[];
      
      for (int i = 0; i < pathPoints.length - 1; i++) {
          final dist = pathPoints[i].distanceTo(pathPoints[i+1]);
          segmentLengths.add(dist);
          totalLength += dist;
      }
      
      final targetDistance = totalLength * progress;
      double currentDist = 0;
      
      for (int i = 0; i < segmentLengths.length; i++) {
          if (currentDist + segmentLengths[i] >= targetDistance) {
              // Point is in this segment
              final remaining = targetDistance - currentDist;
              final percent = remaining / segmentLengths[i];
              return pathPoints[i] + (pathPoints[i+1] - pathPoints[i]) * percent;
          }
          currentDist += segmentLengths[i];
      }
      
      return pathPoints.last;
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


import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum AttackPathType {
  projectile,
  artillery,
}

class AttackPathIndicator extends PositionComponent {
  final List<Vector2> pathPoints;
  final AttackPathType type;
  final Color color;
  
  // Neural signal properties
  final List<double> _signals = [];
  double _timer = 0;
  final double _spawnInterval = 1.0;
  final double _travelDuration = 0.5;
  
  AttackPathIndicator({
    required this.pathPoints,
    required this.type,
    this.color = const Color(0xFFE1BEE7),
  });

  @override
  void update(double dt) {
    super.update(dt);
    
    // Spawn signal (same logic as movement arrow, can be abstracted but duplication is fine for now)
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
    super.render(canvas);
    
    if (pathPoints.isEmpty) return;
    
    if (type == AttackPathType.projectile) {
      _renderProjectilePath(canvas);
    } else {
      _renderArtilleryPath(canvas);
    }
    
    // Draw signals for both types
    _drawSignals(canvas);
  }
  
  void _drawSignals(Canvas canvas) {
      if (_signals.isEmpty || pathPoints.length < 2) return;
      
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        
       for (final progress in _signals) {
          Vector2 pos;
          Vector2 tailPos;
          
          if (type == AttackPathType.projectile) {
              pos = _getLinearPointAtProgress(progress);
              final tailProgress = (progress - 0.05).clamp(0.0, 1.0);
              tailPos = _getLinearPointAtProgress(tailProgress);
          } else {
              pos = _getBezierPointAtProgress(progress);
              final tailProgress = (progress - 0.05).clamp(0.0, 1.0);
              tailPos = _getBezierPointAtProgress(tailProgress);
          }
          
          if (progress > 0.05) {
             canvas.drawLine(tailPos.toOffset(), pos.toOffset(), glowPaint);
          } else {
             canvas.drawCircle(pos.toOffset(), 2.0, glowPaint..style = PaintingStyle.fill);
          }
      }
  }
  
  Vector2 _getLinearPointAtProgress(double progress) {
      // Linear path interpolation (same as movement arrow)
      // Optimized for simple start/end if pathPoints only has 2 points (common for projectile)
      if (pathPoints.length == 2) {
          return pathPoints.first + (pathPoints.last - pathPoints.first) * progress;
      }
      
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
              final remaining = targetDistance - currentDist;
              final percent = remaining / segmentLengths[i];
              return pathPoints[i] + (pathPoints[i+1] - pathPoints[i]) * percent;
          }
          currentDist += segmentLengths[i];
      }
      return pathPoints.last;
  }
  
  Vector2 _getBezierPointAtProgress(double progress) {
      if (pathPoints.length < 2) return Vector2.zero();
      
      final start = pathPoints.first;
      final end = pathPoints.last;
      
      // Calculate bezier control point (upwards) - MUST match _renderArtilleryPath logic
      final mid = (start + end) / 2;
      final control = mid + Vector2(0, -60);
      
      return _quadraticBezierVector(start, control, end, progress);
  }
  
  Vector2 _quadraticBezierVector(Vector2 p0, Vector2 p1, Vector2 p2, double t) {
    final t1 = 1 - t;
    return p0 * t1 * t1 + p1 * 2 * t1 * t + p2 * t * t;
  }

  void _renderProjectilePath(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
      
    final path = Path();
    path.moveTo(pathPoints.first.x, pathPoints.first.y);
    
    for (int i = 1; i < pathPoints.length; i++) {
        path.lineTo(pathPoints[i].x, pathPoints[i].y);
    }
    
    canvas.drawPath(path, paint);
    
    // Draw Arrow at end
    if (pathPoints.length > 1) {
        final end = pathPoints.last;
        final start = pathPoints[pathPoints.length - 2];
        final dir = (end - start).normalized();
        
        final arrowSize = 8.0;
        final p1 = end - (dir * arrowSize) + (Vector2(dir.y, -dir.x) * (arrowSize / 2));
        final p2 = end - (dir * arrowSize) - (Vector2(dir.y, -dir.x) * (arrowSize / 2));
        
        final arrowPath = Path()
          ..moveTo(end.x, end.y)
          ..lineTo(p1.x, p1.y)
          ..lineTo(p2.x, p2.y)
          ..close();
          
        canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
    }
  }
  
  void _renderArtilleryPath(Canvas canvas) {
    if (pathPoints.length < 2) return;
    
    final start = pathPoints.first;
    final end = pathPoints.last;
    
    final dotColor = const Color(0xFFE1BEE7); // Purple 100
    
    // Calculate bezier control point (upwards)
    final mid = (start + end) / 2;
    final control = mid + Vector2(0, -60); // Arc height
    
    // Draw dotted curve points
    final points = <Offset>[];
    for (double t = 0; t <= 1.0; t += 0.05) {
        final p = _quadraticBezier(start.toOffset(), control.toOffset(), end.toOffset(), t);
        points.add(p);
    }
    
    final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
        canvas.drawCircle(points[i], 3.0, paint);
    }
  }
  
  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final t1 = 1 - t;
    return p0 * t1 * t1 + p1 * 2 * t1 * t + p2 * t * t;
  }
}


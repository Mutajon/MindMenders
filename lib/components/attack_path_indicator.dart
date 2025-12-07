import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum AttackPathType {
  projectile,
  artillery,
}

class AttackPathIndicator extends PositionComponent {
  final List<Vector2> pathPoints;
  final AttackPathType type;
  
  AttackPathIndicator({
    required this.pathPoints,
    required this.type,
  });

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (pathPoints.isEmpty) return;
    
    if (type == AttackPathType.projectile) {
      _renderProjectilePath(canvas);
    } else {
      _renderArtilleryPath(canvas);
    }
  }
  
  void _renderProjectilePath(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.purpleAccent
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
    
    // Rainbow colors
    final colors = [
      Colors.red, Colors.orange, Colors.yellow, 
      Colors.green, Colors.blue, Colors.indigo, Colors.purple
    ];
    
    // Calculate bezier control point (upwards)
    final mid = (start + end) / 2;
    final control = mid + Vector2(0, -60); // Arc height
    
    // Draw dotted rainbow curve
    final path = Path();
    path.moveTo(start.x, start.y);
    path.quadraticBezierTo(control.x, control.y, end.x, end.y);
    
    // We can't easily draw a multi-colored dotted line with standard canvas path in one go
    // Simpler approach: Sample projectile motion path
    
    final points = <Offset>[];
    for (double t = 0; t <= 1.0; t += 0.05) {
        final p = _quadraticBezier(start.toOffset(), control.toOffset(), end.toOffset(), t);
        points.add(p);
    }
    
    for (int i = 0; i < points.length; i++) {
        final p = points[i];
        final color = colors[i % colors.length];
        final paint = Paint()
            ..color = color
            ..style = PaintingStyle.fill;
            
        canvas.drawCircle(p, 3.0, paint);
    }
  }
  
  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final t1 = 1 - t;
    return p0 * t1 * t1 + p1 * 2 * t1 * t + p2 * t * t;
  }
}

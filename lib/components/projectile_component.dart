import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class ProjectileComponent extends PositionComponent {
  final Vector2 startPos;
  final Vector2 targetPos;
  final VoidCallback onHit;
  final bool isArtillery;

  ProjectileComponent({
    required this.startPos,
    required this.targetPos,
    required this.onHit,
    this.isArtillery = false,
  }) : super(position: startPos, size: Vector2(10, 10), anchor: Anchor.center);

  @override
  void onLoad() {
    super.onLoad();
    
    // Add glowing sphere visual
    add(CircleComponent(
        radius: 5,
        paint: Paint()..color = Colors.purpleAccent
    ));
    // Glow
    add(CircleComponent(
        radius: 8,
        position: Vector2(-3, -3), // Re-center slightly larger circle? No, children relative to parent
        // Actually CircleComponent position is top-left of circle bounding box.
        // Parent size is 10,10. Radius 5 fits perfectly.
        // Glow radius 8 -> diameter 16. Needs offset -3,-3 from 0,0 relative? 
        // No, parent is 10x10. render centers on components position? 
        // Wait, CircleComponent draws relative to its own position.
        // Let's just draw in render to be safe/simple.
    ));

    // Move Effect
    if (isArtillery) {
        // Arc movement
        // Bezier curve effect? Flame standard MoveEffect is linear.
        // We can use a path effect or simulate simply.
        // Let's look for MoveAlongPathEffect
        
        final path = Path();
        path.moveTo(startPos.x, startPos.y);
        
        final mid = (startPos + targetPos) / 2;
        final control = mid + Vector2(0, -100); // Higher arc for bullet
        
        path.quadraticBezierTo(control.x, control.y, targetPos.x, targetPos.y);
        
        add(MoveAlongPathEffect(
            path,
            EffectController(duration: 0.8),
            onComplete: () {
                onHit();
                removeFromParent();
            },
            absolute: true, // Path is in world coordinates
        ));
        
    } else {
        // Straight line
        add(MoveEffect.to(
            targetPos,
            EffectController(duration: 0.3, curve: Curves.easeIn),
            onComplete: () {
                onHit();
                removeFromParent();
            }
        ));
    }
  }
  
  @override
  void render(Canvas canvas) {
      // Glow
      final paint = Paint()
        ..color = const Color(0xFFE040FB).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(size.x/2, size.y/2), 12, paint);
      
      // Core
      canvas.drawCircle(Offset(size.x/2, size.y/2), 3, Paint()..color = Colors.white);
  }
}

import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game.dart';
import '../models/tile_model.dart';

/// Debug overlay showing AI movement scoring on tiles
class DebugScoreOverlay extends Component with HasGameRef<MyGame> {
  final Map<TileModel, double> scores;

  DebugScoreOverlay(this.scores) : super(priority: 999);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final entry in scores.entries) {
      final tile = entry.key;
      final score = entry.value;

      // Get tile position
      final tilePos = gameRef.getTilePosition(tile.x, tile.y);
      if (tilePos == null) continue;

      // Draw semi-transparent overlay
      final overlayPaint = Paint()
        ..color = score >= 0
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final path = gameRef.gridUtils.getHexPath();
      canvas.save();
      canvas.translate(tilePos.x, tilePos.y);
      canvas.drawPath(path, overlayPaint);
      canvas.restore();

      // Draw score text
      final textPainter = TextPainter(
        text: TextSpan(
          text: score.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          tilePos.x - textPainter.width / 2,
          tilePos.y - textPainter.height / 2,
        ),
      );
    }
  }
}

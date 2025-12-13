import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/tile_model.dart';
import '../game.dart';
import '../utils/grid_utils.dart';

class IsometricTile extends PositionComponent with TapCallbacks {
  final TileModel tileModel;
  final GridUtils gridUtils;
  final Vector2 centeringOffset;

  bool _isHovered = false;
  Color? _highlightColor;

  IsometricTile({
    required this.tileModel,
    required this.gridUtils,
    required this.centeringOffset,
  }) : super(
          size: Vector2(gridUtils.tileWidth, gridUtils.tileHeight),
          anchor: Anchor.center,
        );

  Sprite? _dendriteSprite;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Apply both grid position and centering offset in onLoad
    // so tile has final position before units read it
    position = gridUtils.gridToScreen(tileModel.x, tileModel.y) + centeringOffset;
    
    if (tileModel.type == 'Dendrite') {
        _dendriteSprite = await Sprite.load('battle/tiles/base_tile.png');
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Translate canvas to center of component so hex is drawn centered
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Get hex path from GridUtils (pointy-top orientation)
    final path = gridUtils.getHexPath();
    
    // Draw Sprite if available (Dendrite)
    if (_dendriteSprite != null) {
        canvas.save();
        canvas.clipPath(path);
        // Draw sprite to cover the tile
        // Assuming the sprite is square/rectangular and needs to cover the hex
        // We render it centered
        _dendriteSprite!.render(
            canvas,
            position: Vector2(-size.x/2, -size.y/2),
            size: size,
        );
        canvas.restore();
    } 

    // Choose color based on tile type
    Color fillColor;
    bool useFill = true;
    
    switch (tileModel.type) {
      case 'Dendrite':
        useFill = _dendriteSprite == null; // Use fill only if sprite is missing
        fillColor = const Color(0xFF808080); // Fallback
        break;
      case 'Brain Damage':
        fillColor = Colors.transparent; // Transparent
        break;
      case 'Neuron':
        fillColor = const Color(0xFFFF00FF); // Fuchsia Purple
        break;
      case 'Memory':
        fillColor = const Color(0xFFFFF59D); // Light Yellow
        break;
      default:
        fillColor = const Color(0xFFBDBDBD);
    }

    // Brighten color if hovered (apply overlay if sprite used)
    if (_isHovered) {
        if (useFill) {
            fillColor = Color.lerp(fillColor, Colors.white, 0.3)!;
        } else {
             // Draw overlay for interaction
             final hoverPaint = Paint()
                ..color = Colors.white.withValues(alpha: 0.3)
                ..style = PaintingStyle.fill;
             canvas.drawPath(path, hoverPaint);
        }
    }

    // Draw the tile fill if needed
    if (useFill) {
        final paint = Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, paint);
    }


    
    // Draw alliance overlay
    if (tileModel.controllable) {
      Color? allianceColor;
      switch (tileModel.alliance.toLowerCase()) {
        case 'menders':
          allianceColor = const Color(0xFF448AFF).withValues(alpha: 0.5); // Blue (20% more opaque)
          break;
        case 'hive':
          allianceColor = const Color(0xFFFF5252).withValues(alpha: 0.3); // Red
          break;
      }
      
      if (allianceColor != null) {
        final alliancePaint = Paint()
          ..color = allianceColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, alliancePaint);
      }
    }



    // Draw highlight overlay
    if (_highlightColor != null) {
        final highlightPaint = Paint()
            ..color = _highlightColor!.withOpacity(0.5)
            ..style = PaintingStyle.fill;
            
        // Fill
        canvas.drawPath(path, highlightPaint);
        
        // Border
        final highlightBorder = Paint()
            ..color = _highlightColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0; // Thicker border
        canvas.drawPath(path, highlightBorder);
    }

    // Draw border (skip for Brain Damage to keep it fully transparent)
    if (tileModel.type != 'Brain Damage') {
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, borderPaint);
    }
    
    // Draw Danger Icon (Warning Amber Rounded)
    if (_isDanger) {
        final iconData = Icons.warning_amber_rounded;
        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(iconData.codePoint),
            style: TextStyle(
              fontSize: 24,
              fontFamily: iconData.fontFamily,
              color: const Color(0xFFFF0000).withValues(alpha: 0.3), // 30% Transparent Red
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(-textPainter.width / 2, -textPainter.height / 2),
        );
    }
    
    canvas.restore();
  }

  void setHovered(bool isHovered) {
    _isHovered = isHovered;
  }

  void setHighlightColor(Color? color) {
    _highlightColor = color;
  }
  
  // Danger state (Warning icon)
  bool _isDanger = false;
  
  void setIsDanger(bool isDanger) {
    _isDanger = isDanger;
  }

  // Deprecated shim if needed, or just remove
  void setMovementTarget(bool isTarget) {
     if (isTarget) {
         _highlightColor = Colors.blue.withValues(alpha: 0.5);
     } else {
         _highlightColor = null;
     }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Use GridUtils for hit detection
    // Adjust point to be relative to center (since GridUtils assumes 0,0 center)
    return gridUtils.containsPoint(point - size / 2);
  }

  @override
  void onTapDown(TapDownEvent event) {
    final game = findParent<MyGame>();
    if (game != null) {
      game.handleTileTap(tileModel);
    }
  }
}

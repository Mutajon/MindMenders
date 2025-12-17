import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../models/tile_model.dart';
import '../game.dart';
import '../utils/grid_utils.dart';

class IsometricTile extends PositionComponent
    with TapCallbacks, HasGameReference<MyGame> {
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

  // Sprites for Dendrite tile variants
  static Map<String, Sprite>? _dendriteSprites;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Apply both grid position and centering offset in onLoad
    // so tile has final position before units read it
    position =
        gridUtils.gridToScreen(tileModel.x, tileModel.y) + centeringOffset;

    // Load static sprites if not already loaded
    if (tileModel.type == 'Dendrite' && _dendriteSprites == null) {
      final image = await game.images.load('battle/tiles/base_tile2.png');
      _dendriteSprites = {
        'default': Sprite(
          image,
          srcPosition: Vector2(0, 0),
          srcSize: Vector2(64, 48),
        ),
        'depression': Sprite(
          image,
          srcPosition: Vector2(0, 48),
          srcSize: Vector2(64, 48),
        ),
        'hatred': Sprite(
          image,
          srcPosition: Vector2(0, 96),
          srcSize: Vector2(64, 48),
        ),
        'focused': Sprite(
          image,
          srcPosition: Vector2(0, 144),
          srcSize: Vector2(64, 48),
        ),
      };

      // Load overlays
      // Grey overlay deleted by user request
      final imgBlue = await game.images.load(
        'battle/tiles/dendriteOverlays/dendriteOverlayBlue.png',
      );
      final imgRed = await game.images.load(
        'battle/tiles/dendriteOverlays/dendriteOverlayRed.png',
      );

      // Store in simple map for easy access by alliance key (normalized)
      _dendriteOverlays = {'menders': Sprite(imgBlue), 'hive': Sprite(imgRed)};
    }
  }

  static Map<String, Sprite>? _dendriteOverlays;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Translate canvas to center of component so hex is drawn centered
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Get hex path from GridUtils (pointy-top orientation)
    final path = gridUtils.getHexPath();

    // Draw Sprite if available (Dendrite)
    if (tileModel.type == 'Dendrite' && _dendriteSprites != null) {
      // Use 'default' sprite for now as requested
      final sprite = _dendriteSprites!['default'];

      if (sprite != null) {
        // No clipping for the sprite itself as it has thickness
        // But we might want to clip children? For now, just draw.
        // Actually, we shouldn't clip to the HEX path because the sprite is taller (48px) than the hex (32px)
        // The extra 16px is thickness.

        // Adjust position:
        // Sprite is 64x48. Top 32px is surface. Center of surface is at (32, 16) in sprite coords.
        // Component (0,0) is center of logical hex.
        // So we draw at (-32, -16).

        sprite.render(
          canvas,
          position: Vector2(-32, -16),
          size: Vector2(64, 48),
        );
      }
    }

    // Choose color based on tile type
    Color fillColor;
    bool useFill = true;

    switch (tileModel.type) {
      case 'Dendrite':
        useFill = false; // Always use sprite for Dendrite now
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

    // Draw alliance overlay (Sprite-based for Dendrite, Color-based for others)
    if (tileModel.controllable) {
      if (tileModel.type == 'Dendrite' && _dendriteOverlays != null) {
        // Sprite-based overlay logic
        Sprite? overlaySprite;
        final allianceKey = tileModel.alliance.toLowerCase();

        if (allianceKey == 'neutral') {
          // No overlay for neutral
          overlaySprite = null;
        } else if (allianceKey == 'menders') {
          overlaySprite = _dendriteOverlays!['menders'];
        } else if (allianceKey == 'hive') {
          overlaySprite = _dendriteOverlays!['hive'];
        } else {
          // Default fallback for unknown alliance (treat as neutral)
          overlaySprite = null;
        }

        if (overlaySprite != null) {
          overlaySprite.render(
            canvas,
            position: Vector2(-32, -16), // Match base sprite position
            size: Vector2(64, 48),
          );
        }
      } else {
        // Fallback or non-Dendrite legacy logic
        Color? allianceColor;
        switch (tileModel.alliance.toLowerCase()) {
          case 'menders':
            allianceColor = const Color(
              0xFF448AFF,
            ).withValues(alpha: 0.5); // Blue (20% more opaque)
            break;
          case 'hive':
            allianceColor = const Color(
              0xFFFF5252,
            ).withValues(alpha: 0.3); // Red
            break;
        }

        if (allianceColor != null) {
          final alliancePaint = Paint()
            ..color = allianceColor
            ..style = PaintingStyle.fill;
          canvas.drawPath(path, alliancePaint);
        }
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

    // Draw Danger Icon (Warning Amber Rounded)
    if (_isDanger) {
      final iconData = Icons.warning_amber_rounded;
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: 24,
            fontFamily: iconData.fontFamily,
            color: const Color(
              0xFFFF0000,
            ).withValues(alpha: 0.3), // 30% Transparent Red
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

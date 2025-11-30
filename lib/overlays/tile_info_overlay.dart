import 'package:flutter/material.dart';
import '../models/tile_model.dart';

class TileInfoOverlay extends StatelessWidget {
  final TileModel? hoveredTile;

  const TileInfoOverlay({
    super.key,
    this.hoveredTile,
  });

  Color _getTileColor(String type) {
    switch (type) {
      case 'grass':
        return const Color(0xFF4CAF50);
      case 'water':
        return const Color(0xFF2196F3);
      case 'building':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  IconData _getTileIcon(String type) {
    switch (type) {
      case 'grass':
        return Icons.grass;
      case 'water':
        return Icons.water;
      case 'building':
        return Icons.apartment;
      default:
        return Icons.crop_square;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hoveredTile == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      bottom: 16,
      child: AnimatedOpacity(
        opacity: hoveredTile != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTileColor(hoveredTile!.type).withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tile icon/preview
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTileColor(hoveredTile!.type),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getTileIcon(hoveredTile!.type),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              // Tile info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hoveredTile!.type.toUpperCase(),
                    style: TextStyle(
                      color: _getTileColor(hoveredTile!.type),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hoveredTile!.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Position: (${hoveredTile!.x}, ${hoveredTile!.y})',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

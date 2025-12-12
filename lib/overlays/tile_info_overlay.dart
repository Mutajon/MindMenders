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
      case 'Dendrite':
        return const Color(0xFF808080); // Gray
      case 'Neuron':
        return const Color(0xFFFF00FF); // Fuchsia Purple
      case 'Brain Damage':
        return const Color(0xFF555555); // Dark Gray for UI visibility
      case 'Memory':
        return Colors.yellow;
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  IconData _getTileIcon(String type) {
    switch (type) {
      case 'Dendrite':
        return Icons.linear_scale;
      case 'Neuron':
        return Icons.circle;
      case 'Brain Damage':
        return Icons.broken_image;
      case 'Memory':
        return Icons.memory;
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
                    hoveredTile!.description.replaceAll('. ', '.\n'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),


                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Control: ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _getAllianceDisplayName(hoveredTile!.alliance),
                        style: TextStyle(
                          color: _getAllianceColor(hoveredTile!.alliance),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAllianceDisplayName(String alliance) {
    switch (alliance.toLowerCase()) {
      case 'menders':
        return 'Menders';
      case 'ai':
      case 'hive':
        return 'Hive';
      default:
        return 'Neutral';
    }
  }

  Color _getAllianceColor(String alliance) {
    switch (alliance.toLowerCase()) {
      case 'menders':
        return Colors.blue;
      case 'ai':
      case 'hive':
        return Colors.red;
      default: // neutral
        return Colors.grey;
    }
  }
}

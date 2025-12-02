import 'package:flutter/material.dart';
import '../models/unit_model.dart';

class UnitInfoOverlay extends StatelessWidget {
  final UnitModel? hoveredUnit;

  const UnitInfoOverlay({
    super.key,
    this.hoveredUnit,
  });

  Color _getUnitColor(String name) {
    if (name.toLowerCase() == 'infector') {
      return const Color(0xFFFF9800); // Orange
    }
    if (name.toLowerCase() == 'manipulator') {
      return const Color(0xFF00BCD4); // Teal
    }
    return const Color(0xFF9E9E9E); // Gray (Default)
  }

  IconData _getUnitIcon(String name) {
    if (name.toLowerCase() == 'infector') {
      return Icons.arrow_upward;
    }
    if (name.toLowerCase() == 'manipulator') {
      return Icons.shield;
    }
    return Icons.person; // Default
  }

  @override
  Widget build(BuildContext context) {
    if (hoveredUnit == null) {
      return const SizedBox.shrink();
    }

    final unitColor = _getUnitColor(hoveredUnit!.name);
    final unitIcon = _getUnitIcon(hoveredUnit!.name);

    return Positioned(
      left: 16,
      top: 16,
      child: AnimatedOpacity(
        opacity: hoveredUnit != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unitColor.withValues(alpha: 0.6),
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
              // Unit icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: unitColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  unitIcon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              // Unit info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hoveredUnit!.name.toUpperCase(),
                    style: TextStyle(
                      color: unitColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatRow(Icons.favorite, 'HP', hoveredUnit!.hp.toString()),
                  _buildStatRow(Icons.flash_on, 'Attack', hoveredUnit!.attackMode),
                  _buildStatRow(Icons.whatshot, 'Damage', hoveredUnit!.damageValue.toString()),
                  _buildStatRow(Icons.directions_walk, 'Movement', hoveredUnit!.movementPoints.toString()),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hoveredUnit!.specialAbility,
                      style: TextStyle(
                        color: Colors.purple.shade200,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

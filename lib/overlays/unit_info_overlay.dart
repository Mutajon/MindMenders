import 'package:flutter/material.dart';
import '../models/unit_model.dart';

class UnitInfoOverlay extends StatelessWidget {
  final UnitModel? hoveredUnit;

  const UnitInfoOverlay({
    super.key,
    this.hoveredUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (hoveredUnit == null) {
      return const SizedBox.shrink();
    }

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
              color: const Color(0xFF4A90E2).withValues(alpha: 0.6),
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
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.shield,
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
                    style: const TextStyle(
                      color: Color(0xFF4A90E2),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatRow(Icons.favorite, 'HP', hoveredUnit!.hp.toString()),
                  _buildStatRow(Icons.flash_on, 'Attack', hoveredUnit!.attackMode),
                  _buildStatRow(Icons.whatshot, 'Damage', hoveredUnit!.damageValue.toString()),
                  _buildStatRow(Icons.shield_outlined, 'Defense', hoveredUnit!.defense.toString()),
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

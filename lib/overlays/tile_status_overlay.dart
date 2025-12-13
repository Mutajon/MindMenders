import 'package:flutter/material.dart';

class TileStatusOverlay extends StatelessWidget {
  final int? damage;
  final bool isDanger;

  const TileStatusOverlay({
    super.key,
    this.damage,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDanger && (damage == null || damage == 0)) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      bottom: 200, // Positioned above TileInfoOverlay (which is bottom 16 + height approx 80)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.8),
            width: 2,
          ),
          boxShadow: [
             BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
             )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'DANGER ZONE: ${damage ?? 0} DAMAGE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

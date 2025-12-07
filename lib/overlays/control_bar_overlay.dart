import 'package:flutter/material.dart';

class ControlBarOverlay extends StatelessWidget {
  final Map<String, double> percentages;

  const ControlBarOverlay({
    super.key,
    required this.percentages,
  });

  @override
  Widget build(BuildContext context) {
    // Default values if empty
    final motherPercent = percentages['Mother'] ?? 0.0;
    final mendersPercent = percentages['Menders'] ?? 0.0;
    final neutralPercent = percentages['Neutral'] ?? 1.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              // Percentages Text Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPercentageLabel('MOTHER', motherPercent, Colors.redAccent),
                  _buildPercentageLabel('NEUTRAL', neutralPercent, Colors.grey),
                  _buildPercentageLabel('MENDERS', mendersPercent, Colors.blueAccent),
                ],
              ),
              const SizedBox(height: 6),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      // Mother (Red) - Left
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: MediaQuery.of(context).size.width * 0.8 * motherPercent, // Scaling width relative to container isn't perfect in Row with flex, using flex is better
                        // But Flex doesn't animate cleanly without custom widgets. 
                        // Let's use Flexible with flex factors derived from percentages * 1000 for precision
                      ),
                      // Actually, let's use the Flex approach for structure, but AnimatedContainer is tricky inside Flex if we want smooth width transitions.
                      // Better approach: multiple containers with simple Flex?
                      // Or a CustomPainter?
                      // Let's try Flexible + AnimatedFractionallySizedBox? No.
                      // Let's stick to a LayoutBuilder or just simple Flexible widgets.
                      // For sleekness and animation, let's try standard Expanded/Flexible with animated flex values? No, flex must be int.
                      
                      // Approach 2: Stack with calculated widths?
                      // Approach 3: Row of simple Containers. For animation, we rely on parent rebuilding?
                      // Implementation:
                      Expanded(
                        flex: (motherPercent * 1000).toInt(),
                        child: Container(color: Colors.redAccent),
                      ),
                      Expanded(
                        flex: (neutralPercent * 1000).toInt(),
                        child: Container(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      Expanded(
                        flex: (mendersPercent * 1000).toInt(),
                        child: Container(color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageLabel(String label, double percent, Color color) {
    return Text(
      '$label ${(percent * 100).toStringAsFixed(1)}%',
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

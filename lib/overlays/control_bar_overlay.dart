import 'package:flutter/material.dart';

class ControlBarOverlay extends StatelessWidget {
  final Map<String, double> percentages;

  const ControlBarOverlay({
    super.key,
    required this.percentages,
  });

  @override
  Widget build(BuildContext context) {
    final motherPercent = percentages['Mother'] ?? 0.0;
    final mendersPercent = percentages['Menders'] ?? 0.0;
    final neutralPercent = percentages['Neutral'] ?? 1.0;

    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5, // Half width
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Percentages Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPercentageLabel('MOTHER', motherPercent, const Color(0xFFFF4444)),
                  _buildPercentageLabel('NEUTRAL', neutralPercent, const Color(0xFF888888)),
                  _buildPercentageLabel('MENDERS', mendersPercent, const Color(0xFF4488FF)),
                ],
              ),
              const SizedBox(height: 12),
              // Progress Bar with Glow
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      // Progress segments
                      Row(
                        children: [
                          // Mother (Red) - Left with glow
                          if (motherPercent > 0)
                            Expanded(
                              flex: (motherPercent * 1000).toInt(),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF2222), Color(0xFFFF6666)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF4444).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Neutral (Gray)
                          if (neutralPercent > 0)
                            Expanded(
                              flex: (neutralPercent * 1000).toInt(),
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                          // Menders (Blue) - Right with glow
                          if (mendersPercent > 0)
                            Expanded(
                              flex: (mendersPercent * 1000).toInt(),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2266FF), Color(0xFF66AAFF)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4488FF).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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
      '$label ${(percent * 100).toStringAsFixed(0)}%',
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
        fontFamily: 'Orbitron',
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

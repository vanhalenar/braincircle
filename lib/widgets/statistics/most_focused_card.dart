import 'package:flutter/material.dart';

// --- Color Palette ---
const Color _primaryGreen = Color(0xFF69B880);
const Color _lightGreenBackground = Color(0xFFF2FBF4);
const Color _paleGreen = Color(0xFFE0F4E6);

class MostFocusedPeriodCard extends StatelessWidget {
  final String value1;
  final String value2;
  final String unit;
  final String description;

  const MostFocusedPeriodCard({
    super.key,
    required this.value1,
    required this.value2,
    required this.unit,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value1,
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
              Baseline(
                baseline: 48,
                baselineType: TextBaseline.alphabetic,
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen.withOpacity(0.8),
                  ),
                ),
              ),
              Text(
                value2,
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 16,
                  letterSpacing: 16 * -0.05,
                  color: _primaryGreen.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 8,
              letterSpacing: 10 * -0.005,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

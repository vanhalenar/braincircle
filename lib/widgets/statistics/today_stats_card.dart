import 'package:flutter/material.dart';

// --- Color Palette ---
const Color _primaryGreen = Color(0xFF69B880);
const Color _lightGreenBackground = Color(0xFFF2FBF4);
const Color _paleGreen = Color(0xFFE0F4E6);

class TodayStatCard extends StatelessWidget {
  final String value;
  final String unit;
  final String description;

  const TodayStatCard({
    super.key,
    required this.value,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
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

import 'package:flutter/material.dart';

// --- Color Palette ---
const Color _primaryGreen = Color(0xFF69B880);
const Color _lightGreenBackground = Color(0xFFF2FBF4);
const Color _paleGreen = Color(0xFFE0F4E6);

class DayName extends StatelessWidget {
  final String name;
  const DayName(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _primaryGreen,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

// --- Color Palette ---
const Color _primaryGreen = Color(0xFF69B880);
const Color _lightGreenBackground = Color(0xFFF2FBF4);
const Color _paleGreen = Color(0xFFE0F4E6);

class CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isCompleted;
  final bool isSelected;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.isCompleted = false,
    this.isSelected = false,
    this.isCurrentMonth = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cellColor = isCompleted ? _primaryGreen : _paleGreen;
    final textColor = isCurrentMonth ? Colors.black87 : Colors.black38;

    return GestureDetector(
      onTap: isCurrentMonth ? onTap : null,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isCurrentMonth ? cellColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.deepOrange, width: 2)
              : null,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            color: isCompleted ? Colors.white : textColor,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

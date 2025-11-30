import 'package:flutter/material.dart';
import 'package:brain_circle/widgets/statistics/daily_data.dart';

// --- Color Palette ---
const Color _primaryGreen = Color(0xFF69B880);
const Color _lightGreenBackground = Color(0xFFF2FBF4);
const Color _paleGreen = Color(0xFFE0F4E6);

class WeeklyBarChart extends StatelessWidget {
  final List<DailyData> data;
  final double maxBarHeight = 96; // vyšší, jako na obrázku

  const WeeklyBarChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((daily) {
        final double filledHeight = (daily.hours / 24) * maxBarHeight;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // --- Bar container ---
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // světle zelené pozadí
                Container(
                  height: maxBarHeight,
                  width: 40,
                  decoration: BoxDecoration(
                    color: _paleGreen,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),

                // vyplněná část (zelená)
                // tmavě zelená část (vyplněná)
                if (daily.hours > 0)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: filledHeight,
                        width: 40,
                        decoration: BoxDecoration(
                          color: _primaryGreen,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),

                      // --- Text, podmíněně nahoře nebo uvnitř ---
                      if (filledHeight >= 20)
                        Text(
                          '${daily.hours}h',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _paleGreen,
                          ),
                        ),
                    ],
                  ),

                // --- pokud je sloupec příliš malý, dáme text nad něj ---
                if (daily.hours > 0 && filledHeight < 20)
                  Padding(
                    padding: EdgeInsets.only(bottom: filledHeight + 4),
                    child: Text(
                      '${daily.hours}h',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // Day label
            Text(
              daily.day,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

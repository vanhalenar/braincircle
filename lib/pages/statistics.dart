import 'package:flutter/material.dart';

// --- Color Palette and Constants ---
// Custom color matching the image's green theme
const Color _primaryGreen = Color(0xFF69B880);
const Color _lightGreenBackground = Color(0xFFF2FBF4);
const Color _paleGreen = Color(0xFFE0F4E6);

// --- Custom Data Models ---
class DailyData {
  final String day;
  final double hours;
  final double maxHours = 9.0; // Reference for scaling the chart bars
  final String label;

  DailyData(this.day, this.hours, this.label);
}

final List<DailyData> mockWeeklyData = [
  DailyData('Mo', 3.0, '3h'),
  DailyData('Tu', 5.0, '5h'),
  DailyData('We', 2.5, '2.5h\n(12%)'), // Example for percentage label
  DailyData('Th', 4.0, '4h'),
  DailyData('Fr', 4.5, '4.5h'),
  DailyData('Sa', 0.0, '0h'),
  DailyData('Su', 0.0, '0h'),
];

// --- 1. Reusable Widget: Today Stat Card ---
class _TodayStatCard extends StatelessWidget {
  final String value;
  final String unit;
  final String description;
  final Color backgroundColor;
  final Widget? icon;

  const _TodayStatCard({
    required this.value,
    required this.unit,
    required this.description,
    this.backgroundColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(4), // minimal padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
        children: [
          // Row with value and unit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 60, // adjust to fit
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

// --- 2. Reusable Widget: Weekly Bar Chart ---
class _WeeklyBarChart extends StatelessWidget {
  final List<DailyData> data;
  final double maxBarHeight = 100.0;

  const _WeeklyBarChart(this.data);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((daily) {
        final double barHeight = (daily.hours / daily.maxHours) * maxBarHeight;

        return Column(
          children: [
            // Hours/Percentage Label (positioned above the bar)
            Text(
              daily.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),

            // The Bar
            Container(
              height: barHeight > 0
                  ? barHeight
                  : 2, // Minimum height for 0 hours
              width: 32,
              decoration: BoxDecoration(
                color: daily.hours > 0 ? _primaryGreen : _paleGreen,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),

            // Day Label
            Text(
              daily.day,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// --- 3. Reusable Widget: Calendar Day Cell ---
class _CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isCompleted;
  final bool isSelected;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  const _CalendarDayCell({
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
      onTap: isCurrentMonth
          ? onTap
          : null, // Only tap on days in the current month
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

// --- Main StatefulWidget and State Implementation ---
class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  // State to manage the calendar pop-up
  int? _selectedDay;

  // Mock data for the selected day pop-up
  final Map<int, String> _dayDetails = {
    10: 'Focused Time: 9h\nCompleted Goals: Study algorithms\nStudy for midterm',
  };

  void _showDayDetails(int day) {
    setState(() {
      _selectedDay = day;
    });

    if (_dayDetails.containsKey(day)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Day 10 Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                // Displaying the mock data
                Text(
                  _dayDetails[day]!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          );
        },
      ).then((_) {
        // Reset selected day when the dialog is closed
        setState(() {
          _selectedDay = null;
        });
      });
    } else {
      // For days without details
      setState(() {
        _selectedDay = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGreenBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Today Section ---
            _buildSectionTitle('Today'),
            _buildTodayStats(),
            const SizedBox(height: 32),

            // --- Weekly Section ---
            _buildSectionTitle('Weekly'),
            _buildWeeklyStats(),
            const SizedBox(height: 32),

            // --- Monthly Section ---
            _buildSectionTitle('Monthly'),
            _buildMonthlyStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          width: 80, // fixed width
          height: 20, // fixed height
          alignment: Alignment.center, // center the text inside the container
          decoration: BoxDecoration(
            color: _primaryGreen, // green background
            borderRadius: BorderRadius.circular(50), // oval shape
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12, // smaller font to fit height
              fontWeight: FontWeight.w400,
              color: Colors.black, // black text
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Widget composition for the Today section
  Widget _buildTodayStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TodayStatCard(
              value: '8',
              unit: 'hours',
              description: 'Total time studied today',
              backgroundColor: _paleGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TodayStatCard(
              value: '4',
              unit: 'days',
              description: 'Study streak',
              backgroundColor: _paleGreen,
              icon: const Text('🔥', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TodayStatCard(
              value: '6-8',
              unit: 'p.m.',
              description: 'Most focused period of day',
              backgroundColor: _paleGreen,
            ),
          ),
        ],
      ),
    );
  }

  // Widget composition for the Weekly section
  Widget _buildWeeklyStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: _primaryGreen),
                onPressed: () {},
              ),
              const Text(
                '12.5. - 18.5.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: _primaryGreen),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Average Text
          const Text(
            '5 Hours',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const Text(
            'DAILY AVERAGE',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          // Bar Chart
          _WeeklyBarChart(mockWeeklyData),
        ],
      ),
    );
  }

  // Widget composition for the Monthly section
  Widget _buildMonthlyStats() {
    // Mock days in the calendar grid (5x7 grid)
    final List<int> days = [
      ...List.generate(4, (i) => 27 + i), // Previous month
      ...List.generate(31, (i) => 1 + i), // Current month (March)
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navigation Row and Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: _primaryGreen),
                    onPressed: () {},
                  ),
                  const Text(
                    'March 2025',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: _primaryGreen),
                    onPressed: () {},
                  ),
                ],
              ),
              const Text(
                'Completed: 23 goals',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day Names Row
          const Row(
            children: [
              _DayName('Su'),
              _DayName('Mo'),
              _DayName('Tu'),
              _DayName('We'),
              _DayName('Th'),
              _DayName('Fr'),
              _DayName('Sa'),
            ],
          ),
          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isCurrentMonth =
                  index >= 4 && index <= 34; // March 1st starts at index 4
              final isCompleted =
                  [6, 10, 13, 17, 20, 24].contains(day) && isCurrentMonth;

              return _CalendarDayCell(
                day: day,
                isCompleted: isCompleted,
                isCurrentMonth: isCurrentMonth,
                isSelected: day == _selectedDay,
                onTap: () => _showDayDetails(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper widget for day names in the calendar
class _DayName extends StatelessWidget {
  final String name;
  const _DayName(this.name);

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

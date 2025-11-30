import 'package:flutter/material.dart';
import 'package:brain_circle/widgets/statistics/today_stats_card.dart';
import 'package:brain_circle/widgets/statistics/most_focused_card.dart';
import 'package:brain_circle/widgets/statistics/weekly_bar_chart.dart';
import 'package:brain_circle/widgets/statistics/calendar_day_cell.dart';
import 'package:brain_circle/widgets/statistics/day_name.dart';
import 'package:brain_circle/widgets/statistics/daily_data.dart';

// --- Color Palette ---
const Color _primaryGreen = Color(0xFF69B880);
const Color _lightGreenBackground = Color(0xFFF2FBF4);
const Color _paleGreen = Color(0xFFE0F4E6);

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  int? _selectedDay;

  // -----------------------
  // WEEK NAVIGATION LOGIC
  // -----------------------

  late DateTime _currentWeekStart;

  /// Vrátí PONDĚLÍ daného týdne podle českého formátu
  DateTime _getMonday(DateTime date) {
    final d = date.toLocal(); // <<< DŮLEŽITÉ – české časové pásmo
    int weekday = d.weekday; // 1 = Mo ... 7 = Su
    return DateTime(
      d.year,
      d.month,
      d.day,
    ).subtract(Duration(days: weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getMonday(DateTime.now());
  }

  /// Formát týdne "24.11. - 30.11."
  String _formatWeek(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    return "${monday.day}.${monday.month}. - ${sunday.day}.${sunday.month}.";
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }
  // -----------------------

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
                    Text(
                      'Day $day Summary',
                      style: const TextStyle(
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
                Text(
                  _dayDetails[day]!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          );
        },
      ).then((_) {
        setState(() {
          _selectedDay = null;
        });
      });
    } else {
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
            _buildSectionTitle('Today'),
            _buildTodayStats(),
            const SizedBox(height: 8),
            _buildSectionTitle('Weekly'),
            _buildWeeklyStats(),
            const SizedBox(height: 8),
            _buildSectionTitle('Monthly'),
            _buildMonthlyStats(),
          ],
        ),
      ),
    );
  }

  // --- Section Title Widget ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          width: 80,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primaryGreen,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // --- Today Stats Section ---
  Widget _buildTodayStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TodayStatCard(
              value: '8',
              unit: 'hours',
              description: 'Total time studied today',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TodayStatCard(
              value: '4',
              unit: 'days',
              description: 'Study streak',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MostFocusedPeriodCard(
              value1: '6',
              value2: '8',
              unit: 'pm',
              description: 'Most focused period of day',
            ),
          ),
        ],
      ),
    );
  }

  // --- Weekly Stats Section ---
  Widget _buildWeeklyStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: _primaryGreen),
                  onPressed: _previousWeek,
                ),
                Text(
                  _formatWeek(_currentWeekStart),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _primaryGreen,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: _primaryGreen),
                  onPressed: _nextWeek,
                ),
              ],
            ),

            // Daily Average
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text(
                  '5 Hours',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'DAILY AVERAGE',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),

            WeeklyBarChart(mockWeeklyData),
          ],
        ),
      ),
    );
  }

  // --- Monthly Stats Section ---
  Widget _buildMonthlyStats() {
    final List<int> days = [
      ...List.generate(4, (i) => 27 + i),
      ...List.generate(31, (i) => 1 + i),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Navigation
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

          Row(
            children: const [
              DayName('Su'),
              DayName('Mo'),
              DayName('Tu'),
              DayName('We'),
              DayName('Th'),
              DayName('Fr'),
              DayName('Sa'),
            ],
          ),

          const SizedBox(height: 4),

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
              final isCurrentMonth = index >= 4 && index <= 34;
              final isCompleted =
                  [6, 10, 13, 17, 20, 24].contains(day) && isCurrentMonth;

              return CalendarDayCell(
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

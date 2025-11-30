class DailyData {
  final String day;
  final double hours;
  final String label;

  DailyData(this.day, this.hours, this.label);
}

final List<DailyData> mockWeeklyData = [
  DailyData('Mo', 24.0, '24h'),
  DailyData('Tu', 5.0, '5h'),
  DailyData('We', 2.5, '2.5h'),
  DailyData('Th', 4.0, '4h'),
  DailyData('Fr', 4.5, '4.5h'),
  DailyData('Sa', 0.0, '0h'),
  DailyData('Su', 0.0, '0h'),
];

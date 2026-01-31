/// Time-related utility functions
class GameTime {
  /// Time of day enum
  static const List<String> timesOfDay = ['morning', 'day', 'evening', 'night'];

  /// Get next time of day
  static String getNextTime(String current) {
    final index = timesOfDay.indexOf(current);
    if (index < 0) return 'morning';
    return timesOfDay[(index + 1) % timesOfDay.length];
  }

  /// Check if it's night time
  static bool isNight(String timeOfDay) => timeOfDay == 'night';

  /// Check if it's day time (for scavenging)
  static bool isDayTime(String timeOfDay) => 
      timeOfDay == 'morning' || timeOfDay == 'day';

  /// Get time of day icon
  static String getTimeIcon(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning': return '🌅';
      case 'day': return '☀️';
      case 'evening': return '🌇';
      case 'night': return '🌙';
      default: return '⏰';
    }
  }

  /// Get time of day name in Vietnamese
  static String getTimeName(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning': return 'Sáng';
      case 'day': return 'Ngày';
      case 'evening': return 'Chiều';
      case 'night': return 'Đêm';
      default: return timeOfDay;
    }
  }
}

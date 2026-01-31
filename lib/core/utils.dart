/// General utility functions
class Utils {
  /// Parse int with default value
  static int parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Parse double with default value
  static double parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Parse bool with default value
  static bool parseBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value != 0;
    return defaultValue;
  }

  /// Parse list with default
  static List<T> parseList<T>(dynamic value, T Function(dynamic) parser) {
    if (value == null) return [];
    if (value is! List) return [];
    return value.map((e) => parser(e)).toList();
  }

  /// Parse map with default
  static Map<String, V> parseMap<V>(dynamic value, V Function(dynamic) parser) {
    if (value == null) return {};
    if (value is! Map) return {};
    return value.map((k, v) => MapEntry(k.toString(), parser(v)));
  }

  /// Safe string get from map
  static String getString(Map<String, dynamic>? map, String key, [String defaultValue = '']) {
    if (map == null) return defaultValue;
    final value = map[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Safe int get from map
  static int getInt(Map<String, dynamic>? map, String key, [int defaultValue = 0]) {
    if (map == null) return defaultValue;
    return parseInt(map[key], defaultValue);
  }

  /// Safe double get from map
  static double getDouble(Map<String, dynamic>? map, String key, [double defaultValue = 0.0]) {
    if (map == null) return defaultValue;
    return parseDouble(map[key], defaultValue);
  }

  /// Safe bool get from map
  static bool getBool(Map<String, dynamic>? map, String key, [bool defaultValue = false]) {
    if (map == null) return defaultValue;
    return parseBool(map[key], defaultValue);
  }

  /// Safe list get from map
  static List<dynamic> getList(Map<String, dynamic>? map, String key) {
    if (map == null) return [];
    final value = map[key];
    if (value is List) return value;
    return [];
  }

  /// Safe map get from map
  static Map<String, dynamic> getMap(Map<String, dynamic>? map, String key) {
    if (map == null) return {};
    final value = map[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  /// Format time in minutes to string
  static String formatTime(int minutes) {
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours giờ';
    return '$hours giờ $mins phút';
  }

  /// Format number with suffix (K, M, etc.)
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

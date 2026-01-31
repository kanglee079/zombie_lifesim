import 'dart:developer' as dev;

/// Game logging utility
class GameLogger {
  static bool _enabled = true;
  static LogLevel _level = LogLevel.debug;

  /// Enable/disable logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Set minimum log level
  static void setLevel(LogLevel level) {
    _level = level;
  }

  /// Log debug message
  static void debug(String message) {
    _log(LogLevel.debug, '🔍', message);
  }

  /// Log info message
  static void info(String message) {
    _log(LogLevel.info, 'ℹ️', message);
  }

  /// Log warning message
  static void warn(String message) {
    _log(LogLevel.warning, '⚠️', message);
  }

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, '❌', message);
    if (error != null) {
      dev.log('Error: $error', name: 'GameError');
      if (stackTrace != null) {
        dev.log('Stack: $stackTrace', name: 'GameError');
      }
    }
  }

  /// Log game event (for game loop tracking)
  static void game(String message) {
    _log(LogLevel.info, '🎮', message, 'Game');
  }

  /// Log data loading
  static void data(String message) {
    _log(LogLevel.debug, '📦', message, 'Data');
  }

  /// Log save/load operations
  static void save(String message) {
    _log(LogLevel.info, '💾', message, 'Save');
  }

  static void _log(LogLevel level, String emoji, String message, [String name = 'ZombieLifeSim']) {
    if (!_enabled) return;
    if (level.index < _level.index) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final formatted = '[$timestamp] $emoji $message';

    dev.log(formatted, name: name);
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

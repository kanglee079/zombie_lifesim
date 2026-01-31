/// Utility class for clamping game values to valid ranges
class Clamp {
  /// Clamp HP value (0-100)
  static int hp(int value, [int max = 100]) {
    return value.clamp(0, max);
  }

  /// Clamp infection value (0-100)
  static int infection(int value) {
    return value.clamp(0, 100);
  }

  /// Clamp general stat value
  static int stat(int value, [int min = 0, int max = 100]) {
    return value.clamp(min, max);
  }

  /// Clamp morale value (0-100)
  static int morale(int value) {
    return value.clamp(0, 100);
  }

  /// Clamp tension value (0-100)
  static int tension(int value) {
    return value.clamp(0, 100);
  }

  /// Clamp reputation value (-100 to 100)
  static int reputation(int value) {
    return value.clamp(-100, 100);
  }

  /// Clamp skill value (0-10)
  static int skill(int value) {
    return value.clamp(0, 10);
  }

  /// Clamp depletion value (0-10)
  static int depletion(int value) {
    return value.clamp(0, 10);
  }

  /// Clamp percentage (0.0-1.0)
  static double percentage(double value) {
    return value.clamp(0.0, 1.0);
  }

  /// Clamp day value (1+)
  static int day(int value) {
    return value.clamp(1, 9999);
  }

  /// Clamp quantity value (0+)
  static int quantity(int value) {
    return value.clamp(0, 9999);
  }
}

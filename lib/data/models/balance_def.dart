/// Balance configuration
class BalanceDef {
  final Map<String, dynamic> raw;
  
  // Parsed common values
  final Map<String, int> clamps;
  final Map<String, List<ProgressionPoint>> progression;

  BalanceDef({
    required this.raw,
    this.clamps = const {},
    this.progression = const {},
  });

  factory BalanceDef.fromJson(Map<String, dynamic> json) {
    // Parse clamps
    final clamps = <String, int>{};
    final clampsRaw = json['clamps'] as Map<String, dynamic>?;
    if (clampsRaw != null) {
      for (final entry in clampsRaw.entries) {
        if (entry.value is Map) {
          clamps['${entry.key}_min'] = entry.value['min'] ?? 0;
          clamps['${entry.key}_max'] = entry.value['max'] ?? 100;
        }
      }
    }

    // Parse progression multipliers
    final progression = <String, List<ProgressionPoint>>{};
    final progressionRaw = json['progression'] as Map<String, dynamic>?;
    if (progressionRaw != null) {
      for (final entry in progressionRaw.entries) {
        final points = <ProgressionPoint>[];
        if (entry.value is List) {
          for (final point in entry.value as List) {
            points.add(ProgressionPoint.fromJson(point));
          }
        }
        progression[entry.key] = points;
      }
    }

    return BalanceDef(
      raw: json,
      clamps: clamps,
      progression: progression,
    );
  }

  factory BalanceDef.defaultBalance() {
    return BalanceDef(
      raw: {
        'clamps': {
          'hp': {'min': 0, 'max': 100},
          'infection': {'min': 0, 'max': 100},
          'hunger': {'min': 0, 'max': 100},
          'thirst': {'min': 0, 'max': 100},
          'fatigue': {'min': 0, 'max': 100},
          'stress': {'min': 0, 'max': 100},
        },
        'dailyTick': {
          'hunger': -15,
          'thirst': -20,
          'fatigue': 10,
          'stress': 5,
          'infectionDecay': -1,
        },
        'nightThreatModel': {
          'floor': 0,
          'cap': 30,
          'damagePerZombie': 2,
          'breachAtHordeOver': 20,
        },
      },
    );
  }

  /// Get a multiplier for the current day from progression
  double getMultiplier(String key, int day) {
    final points = progression[key];
    if (points == null || points.isEmpty) return 1.0;

    // Find the point before and after current day
    ProgressionPoint? before;
    ProgressionPoint? after;

    for (final point in points) {
      if (point.day <= day) {
        before = point;
      } else {
        after = point;
        break;
      }
    }

    if (before == null) {
      return points.first.mult;
    }
    if (after == null) {
      return before.mult;
    }

    // Linear interpolation
    final dayRange = after.day - before.day;
    final multRange = after.mult - before.mult;
    final dayDelta = day - before.day;
    
    return before.mult + (multRange * dayDelta / dayRange);
  }

  /// Get clamp value
  int getClamp(String key, String minOrMax) {
    return clamps['${key}_$minOrMax'] ?? (minOrMax == 'min' ? 0 : 100);
  }
}

/// Progression point for day-based multipliers
class ProgressionPoint {
  final int day;
  final double mult;

  ProgressionPoint({required this.day, required this.mult});

  factory ProgressionPoint.fromJson(Map<String, dynamic> json) {
    return ProgressionPoint(
      day: json['day'] ?? 1,
      mult: (json['mult'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

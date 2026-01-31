/// Balance configuration
class BalanceDef {
  final Map<String, dynamic> raw;

  // Parsed common values
  final Map<String, List<int>> clamps; // key: "player.hp" or "base.defense" -> [min,max]
  final Map<String, List<double>> multipliersByDay;

  BalanceDef({
    required this.raw,
    this.clamps = const {},
    this.multipliersByDay = const {},
  });

  factory BalanceDef.fromJson(Map<String, dynamic> json) {
    // Parse clamps: clamps.player.<stat> = [min, max], clamps.base.<stat> = [min, max]
    final clamps = <String, List<int>>{};
    final clampsRaw = json['clamps'] as Map<String, dynamic>?;
    if (clampsRaw != null) {
      for (final groupEntry in clampsRaw.entries) {
        final group = groupEntry.key.toString();
        final groupMap = groupEntry.value;
        if (groupMap is Map) {
          for (final statEntry in groupMap.entries) {
            final stat = statEntry.key.toString();
            final clampValues = statEntry.value;
            if (clampValues is List && clampValues.length >= 2) {
              final min = _toInt(clampValues[0]) ?? 0;
              final max = _toInt(clampValues[1]) ?? 100;
              clamps['$group.$stat'] = [min, max];
            }
          }
        }
      }
    }

    // Parse progression multipliers: progression.multipliersByDay.<key> = [30 values]
    final multipliersByDay = <String, List<double>>{};
    final progressionRaw = json['progression'] as Map<String, dynamic>?;
    final byDay = progressionRaw?['multipliersByDay'] as Map<String, dynamic>?;
    if (byDay != null) {
      for (final entry in byDay.entries) {
        if (entry.value is List) {
          multipliersByDay[entry.key.toString()] = (entry.value as List)
              .map((e) => (e as num?)?.toDouble() ?? 1.0)
              .toList();
        }
      }
    }

    return BalanceDef(
      raw: json,
      clamps: clamps,
      multipliersByDay: multipliersByDay,
    );
  }

  factory BalanceDef.defaultBalance() {
    return BalanceDef(
      raw: {
        'clamps': {
          'player': {
            'hp': [0, 100],
            'infection': [0, 100],
            'hunger': [0, 100],
            'thirst': [0, 100],
            'fatigue': [0, 100],
            'stress': [0, 100],
            'morale': [-50, 50],
          },
          'base': {
            'defense': [0, 100],
            'power': [0, 100],
            'noise': [0, 100],
            'smell': [0, 100],
            'hope': [0, 100],
            'signalHeat': [0, 100],
          },
        },
        'dailyTick': {
          'playerStatIncreasePerDay': {
            'hunger': 12,
            'thirst': 18,
            'fatigue': 10,
            'stress': 4,
          },
        },
        'carryCapacity': {
          'baseKg': 14,
          'perPartyMemberBonus': 2,
          'backpackBonus': 6,
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
    final values = multipliersByDay[key];
    if (values == null || values.isEmpty) return 1.0;
    final index = (day - 1).clamp(0, values.length - 1);
    return values[index];
  }

  /// Get clamp value
  List<int> getClamp(String path) {
    final normalized = path.contains('.') ? path : 'player.$path';
    return clamps[normalized] ?? const [0, 100];
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

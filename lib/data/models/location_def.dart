/// District definition
class DistrictDef {
  final String id;
  final String name;
  final int minDay;
  final int unlockCostEP;
  final List<dynamic> requirements;
  final bool startUnlocked;
  final List<String> locationIds;
  final List<String> tags;

  DistrictDef({
    required this.id,
    required this.name,
    this.minDay = 1,
    this.unlockCostEP = 0,
    this.requirements = const [],
    this.startUnlocked = false,
    this.locationIds = const [],
    this.tags = const [],
  });

  factory DistrictDef.fromJson(Map<String, dynamic> json) {
    return DistrictDef(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      minDay: json['minDay'] ?? 1,
      unlockCostEP: json['unlockCostEP'] ?? 0,
      requirements: json['requirements'] as List<dynamic>? ?? [],
      startUnlocked: json['startUnlocked'] ?? false,
      locationIds: List<String>.from(json['locationIds'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minDay': minDay,
    'unlockCostEP': unlockCostEP,
    'requirements': requirements,
    'startUnlocked': startUnlocked,
    'locationIds': locationIds,
    'tags': tags,
  };
}

/// Location definition
class LocationDef {
  final String id;
  final String name;
  final String districtId;
  final int baseRisk;
  final String? lootTable; // baseLoot in JSON is actually the loot table ID
  final int depletionStart;
  final String context;
  final List<String> tags;
  final Map<String, dynamic>? unlock;

  LocationDef({
    required this.id,
    required this.name,
    this.districtId = '',
    this.baseRisk = 30,
    this.lootTable,
    this.depletionStart = 0,
    this.context = 'scavenge',
    this.tags = const [],
    this.unlock,
  });

  factory LocationDef.fromJson(Map<String, dynamic> json) {
    return LocationDef(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      districtId: json['districtId'] ?? '',
      baseRisk: _parseIntSafe(json['baseRisk'], 30),
      // In JSON, baseLoot is actually the loot table ID (string)
      lootTable: json['baseLoot']?.toString() ?? json['lootTable']?.toString(),
      depletionStart: _parseIntSafe(json['depletionStart'], 0),
      context: json['context'] ?? 'scavenge',
      tags: List<String>.from(json['tags'] ?? []),
      unlock: json['unlock'] != null ? Map<String, dynamic>.from(json['unlock']) : null,
    );
  }

  /// Safely parse int from dynamic (handles String or int)
  static int _parseIntSafe(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'districtId': districtId,
    'baseRisk': baseRisk,
    'baseLoot': lootTable,
    'depletionStart': depletionStart,
    'context': context,
    'tags': tags,
    'unlock': unlock,
  };
}

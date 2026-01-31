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
  final int baseLoot;
  final int depletionStart;
  final String? lootTable;
  final String context;
  final List<String> tags;
  final Map<String, dynamic>? unlock;

  LocationDef({
    required this.id,
    required this.name,
    this.districtId = '',
    this.baseRisk = 30,
    this.baseLoot = 100,
    this.depletionStart = 0,
    this.lootTable,
    this.context = 'scavenge',
    this.tags = const [],
    this.unlock,
  });

  factory LocationDef.fromJson(Map<String, dynamic> json) {
    return LocationDef(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      districtId: json['districtId'] ?? '',
      baseRisk: json['baseRisk'] ?? 30,
      baseLoot: json['baseLoot'] ?? 100,
      depletionStart: json['depletionStart'] ?? 0,
      lootTable: json['lootTable'],
      context: json['context'] ?? 'scavenge',
      tags: List<String>.from(json['tags'] ?? []),
      unlock: json['unlock'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'districtId': districtId,
    'baseRisk': baseRisk,
    'baseLoot': baseLoot,
    'depletionStart': depletionStart,
    'lootTable': lootTable,
    'context': context,
    'tags': tags,
    'unlock': unlock,
  };
}

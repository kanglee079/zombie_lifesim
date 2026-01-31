/// Trait definition
class TraitDef {
  final String id;
  final String name;
  final String category;
  final String rarity;
  final List<String> tags;
  final String description;
  final TraitModifiers modifiers;

  TraitDef({
    required this.id,
    required this.name,
    this.category = 'general',
    this.rarity = 'common',
    this.tags = const [],
    this.description = '',
    required this.modifiers,
  });

  factory TraitDef.fromJson(Map<String, dynamic> json) {
    return TraitDef(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'general',
      rarity: json['rarity'] ?? 'common',
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'] ?? '',
      modifiers: TraitModifiers.fromJson(json['modifiers']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'rarity': rarity,
    'tags': tags,
    'description': description,
    'modifiers': modifiers.toJson(),
  };
}

/// Trait modifiers
class TraitModifiers {
  final int combatBonus;
  final int stealthBonus;
  final int medicalBonus;
  final int craftBonus;
  final int scavengeBonus;
  final int moraleBonus;
  final int consumptionMod;
  final int tensionMod;
  final Map<String, dynamic> other;

  TraitModifiers({
    this.combatBonus = 0,
    this.stealthBonus = 0,
    this.medicalBonus = 0,
    this.craftBonus = 0,
    this.scavengeBonus = 0,
    this.moraleBonus = 0,
    this.consumptionMod = 0,
    this.tensionMod = 0,
    this.other = const {},
  });

  factory TraitModifiers.fromJson(dynamic json) {
    if (json is List) {
      return TraitModifiers(other: {'_list': json});
    }

    if (json is! Map) {
      return TraitModifiers();
    }

    final map = Map<String, dynamic>.from(json);

    return TraitModifiers(
      combatBonus: map['combatBonus'] ?? map['combat'] ?? 0,
      stealthBonus: map['stealthBonus'] ?? map['stealth'] ?? 0,
      medicalBonus: map['medicalBonus'] ?? map['medical'] ?? 0,
      craftBonus: map['craftBonus'] ?? map['craft'] ?? 0,
      scavengeBonus: map['scavengeBonus'] ?? map['scavenge'] ?? 0,
      moraleBonus: map['moraleBonus'] ?? map['morale'] ?? 0,
      consumptionMod: map['consumptionMod'] ?? map['consumption'] ?? 0,
      tensionMod: map['tensionMod'] ?? map['tension'] ?? 0,
      other: Map<String, dynamic>.from(map)
        ..remove('combatBonus')
        ..remove('combat')
        ..remove('stealthBonus')
        ..remove('stealth')
        ..remove('medicalBonus')
        ..remove('medical')
        ..remove('craftBonus')
        ..remove('craft')
        ..remove('scavengeBonus')
        ..remove('scavenge')
        ..remove('moraleBonus')
        ..remove('morale')
        ..remove('consumptionMod')
        ..remove('consumption')
        ..remove('tensionMod')
        ..remove('tension'),
    );
  }

  Map<String, dynamic> toJson() => {
    'combatBonus': combatBonus,
    'stealthBonus': stealthBonus,
    'medicalBonus': medicalBonus,
    'craftBonus': craftBonus,
    'scavengeBonus': scavengeBonus,
    'moraleBonus': moraleBonus,
    'consumptionMod': consumptionMod,
    'tensionMod': tensionMod,
    ...other,
  };
}

/// NPC template
class NpcTemplate {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> baseStats;
  final NpcTraitPool traitPool;
  final Map<String, int> skills;
  final double consumptionMult;
  final List<String>? namePool;
  final List<String>? rolePool;
  final Map<String, NpcSkillRange> skillRanges;
  final List<NpcStartingItem> startingItems;

  NpcTemplate({
    required this.id,
    required this.name,
    this.description = '',
    this.baseStats = const {},
    required this.traitPool,
    this.skills = const {},
    this.consumptionMult = 1.0,
    this.namePool,
    this.rolePool,
    this.skillRanges = const {},
    this.startingItems = const [],
  });

  factory NpcTemplate.fromJson(Map<String, dynamic> json) {
    return NpcTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      baseStats: Map<String, dynamic>.from(json['baseStats'] ?? {}),
      traitPool: NpcTraitPool.fromJson(json['traitPool'] ?? {}),
      skills: Map<String, int>.from(json['skills'] ?? {}),
      consumptionMult: (json['consumptionMult'] as num?)?.toDouble() ?? 1.0,
      namePool: json['namePool'] != null 
          ? List<String>.from(json['namePool']) 
          : null,
      rolePool: json['rolePool'] != null 
          ? List<String>.from(json['rolePool']) 
          : null,
      skillRanges: (json['skillRanges'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), NpcSkillRange.fromJson(v)),
      ) ?? {},
      startingItems: (json['startingItems'] as List?)
          ?.map((e) => NpcStartingItem.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'baseStats': baseStats,
    'traitPool': traitPool.toJson(),
    'skills': skills,
    'consumptionMult': consumptionMult,
    'namePool': namePool,
    'rolePool': rolePool,
    'skillRanges': skillRanges.map((k, v) => MapEntry(k, v.toJson())),
    'startingItems': startingItems.map((e) => e.toJson()).toList(),
  };
}

/// NPC trait pool config
class NpcTraitPool {
  final int pick;
  final int? pickMin;
  final int? pickMax;
  final Map<String, Map<String, double>> weights;
  final Map<String, double> categoryWeights;
  final List<String> rarities;
  final List<String> fixedTraits;

  NpcTraitPool({
    this.pick = 2,
    this.pickMin,
    this.pickMax,
    this.weights = const {},
    this.categoryWeights = const {},
    this.rarities = const [],
    this.fixedTraits = const [],
  });

  factory NpcTraitPool.fromJson(dynamic json) {
    if (json is List) {
      return NpcTraitPool(
        fixedTraits: json.map((e) => e.toString()).where((e) => e.isNotEmpty).toList(),
      );
    }

    if (json is! Map) {
      return NpcTraitPool();
    }

    final map = Map<String, dynamic>.from(json);
    final pickRaw = map['pick'] ?? map['pickCount'];
    int pick = 2;
    int? pickMin;
    int? pickMax;

    if (pickRaw is List && pickRaw.length >= 2) {
      pickMin = _toInt(pickRaw[0]) ?? 1;
      pickMax = _toInt(pickRaw[1]) ?? pickMin;
      pick = pickMin;
    } else if (pickRaw is num || pickRaw is String) {
      pick = _toInt(pickRaw) ?? 2;
    }

    final weightsRaw = map['weights'];
    final weights = <String, Map<String, double>>{};
    final categoryWeights = <String, double>{};

    if (weightsRaw is Map) {
      for (final entry in weightsRaw.entries) {
        final category = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          weights[category] = value.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          );
        } else if (value is num) {
          categoryWeights[category] = value.toDouble();
        }
      }
    }

    return NpcTraitPool(
      pick: pick,
      pickMin: pickMin,
      pickMax: pickMax,
      weights: weights,
      categoryWeights: categoryWeights,
      rarities: List<String>.from(map['rarities'] ?? map['allowRarities'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'pick': pick,
    'pickMin': pickMin,
    'pickMax': pickMax,
    'weights': weights,
    'categoryWeights': categoryWeights,
    'rarities': rarities,
    'fixedTraits': fixedTraits,
  };
}

/// NPC skill range
class NpcSkillRange {
  final int min;
  final int max;

  NpcSkillRange({required this.min, required this.max});

  factory NpcSkillRange.fromJson(dynamic json) {
    if (json is List && json.isNotEmpty) {
      final min = _toInt(json[0]) ?? 1;
      final max = json.length > 1 ? (_toInt(json[1]) ?? min) : min;
      return NpcSkillRange(min: min, max: max);
    }

    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return NpcSkillRange(
        min: _toInt(map['min']) ?? 1,
        max: _toInt(map['max']) ?? 5,
      );
    }

    return NpcSkillRange(min: 1, max: 5);
  }

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
  };
}

/// NPC starting item
class NpcStartingItem {
  final String itemId;
  final int qty;
  final double chance;

  NpcStartingItem({
    required this.itemId,
    this.qty = 1,
    this.chance = 1.0,
  });

  factory NpcStartingItem.fromJson(Map<String, dynamic> json) {
    return NpcStartingItem(
      itemId: json['itemId'] ?? json['item'] ?? json['id'] ?? '',
      qty: json['qty'] ?? 1,
      chance: (json['chance'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'qty': qty,
    'chance': chance,
  };
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

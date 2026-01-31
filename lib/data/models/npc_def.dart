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
      modifiers: TraitModifiers.fromJson(json['modifiers'] ?? {}),
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

  factory TraitModifiers.fromJson(Map<String, dynamic> json) {
    return TraitModifiers(
      combatBonus: json['combatBonus'] ?? json['combat'] ?? 0,
      stealthBonus: json['stealthBonus'] ?? json['stealth'] ?? 0,
      medicalBonus: json['medicalBonus'] ?? json['medical'] ?? 0,
      craftBonus: json['craftBonus'] ?? json['craft'] ?? 0,
      scavengeBonus: json['scavengeBonus'] ?? json['scavenge'] ?? 0,
      moraleBonus: json['moraleBonus'] ?? json['morale'] ?? 0,
      consumptionMod: json['consumptionMod'] ?? json['consumption'] ?? 0,
      tensionMod: json['tensionMod'] ?? json['tension'] ?? 0,
      other: Map<String, dynamic>.from(json)
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
  final Map<String, Map<String, double>> weights;
  final List<String> rarities;

  NpcTraitPool({
    this.pick = 2,
    this.weights = const {},
    this.rarities = const [],
  });

  factory NpcTraitPool.fromJson(Map<String, dynamic> json) {
    final weightsRaw = json['weights'] as Map?;
    final weights = <String, Map<String, double>>{};
    
    if (weightsRaw != null) {
      for (final entry in weightsRaw.entries) {
        final category = entry.key.toString();
        final categoryWeights = entry.value as Map?;
        if (categoryWeights != null) {
          weights[category] = categoryWeights.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          );
        }
      }
    }

    return NpcTraitPool(
      pick: json['pick'] ?? 2,
      weights: weights,
      rarities: List<String>.from(json['rarities'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'pick': pick,
    'weights': weights,
    'rarities': rarities,
  };
}

/// NPC skill range
class NpcSkillRange {
  final int min;
  final int max;

  NpcSkillRange({required this.min, required this.max});

  factory NpcSkillRange.fromJson(Map<String, dynamic> json) {
    return NpcSkillRange(
      min: json['min'] ?? 1,
      max: json['max'] ?? 5,
    );
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
      itemId: json['itemId'] ?? json['item'] ?? '',
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

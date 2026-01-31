/// Item definition
class ItemDef {
  final String id;
  final String name;
  final String category;
  final String rarity;
  final double weight;
  final bool stackable;
  final int maxStack;
  final List<String> tags;
  final int value;
  final String? description;
  final Map<String, dynamic>? use; // Use effect object

  ItemDef({
    required this.id,
    required this.name,
    required this.category,
    this.rarity = 'common',
    this.weight = 0.1,
    this.stackable = true,
    this.maxStack = 99,
    this.tags = const [],
    this.value = 0,
    this.description,
    this.use,
  });

  factory ItemDef.fromJson(Map<String, dynamic> json) {
    return ItemDef(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'misc',
      rarity: json['rarity'] ?? 'common',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.1,
      stackable: json['stackable'] ?? true,
      maxStack: json['maxStack'] ?? 99,
      tags: List<String>.from(json['tags'] ?? []),
      value: json['value'] ?? 0,
      description: json['description'],
      use: json['use'] != null ? Map<String, dynamic>.from(json['use']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'rarity': rarity,
    'weight': weight,
    'stackable': stackable,
    'maxStack': maxStack,
    'tags': tags,
    'value': value,
    'description': description,
    'use': use,
  };

  bool hasTag(String tag) => tags.contains(tag);
  
  /// Check if item is usable
  bool get isUsable => use != null;
  
  /// Get use cooldown in hours
  int get useCooldownHours => (use?['cooldownHours'] as num?)?.toInt() ?? 0;
  
  /// Get use effects list
  List<Map<String, dynamic>> get useEffects {
    final effects = use?['effects'];
    if (effects is List) {
      return effects.cast<Map<String, dynamic>>();
    }
    return [];
  }
  
  /// Get use log message
  String? get useLog => use?['log'] as String?;
}

/// Loot table definition
class LootTableDef {
  final String id;
  final int rolls;
  final List<LootEntry> entries;

  LootTableDef({
    required this.id,
    this.rolls = 1,
    this.entries = const [],
  });

  factory LootTableDef.fromJson(Map<String, dynamic> json) {
    return LootTableDef(
      id: json['id'] ?? '',
      rolls: json['rolls'] ?? 1,
      entries: (json['entries'] as List?)
          ?.map((e) => LootEntry.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rolls': rolls,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}

/// Loot entry in a table
class LootEntry {
  final String item;
  final double w;
  final int min;
  final int max;

  LootEntry({
    required this.item,
    this.w = 1.0,
    this.min = 1,
    this.max = 1,
  });

  factory LootEntry.fromJson(Map<String, dynamic> json) {
    return LootEntry(
      item: json['item'] ?? '',
      w: (json['w'] as num?)?.toDouble() ?? 1.0,
      min: json['min'] ?? 1,
      max: json['max'] ?? json['min'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'item': item,
    'w': w,
    'min': min,
    'max': max,
  };
}

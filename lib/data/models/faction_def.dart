/// Faction definition
class FactionDef {
  final String id;
  final String name;
  final String desc;
  final double baseBuyMult;
  final double baseSellMult;
  final List<RepTier> repTiers;
  final Map<String, double> demandPremiums;
  final Map<String, double> supplyDiscounts;
  final List<String> tags;
  final FactionReputation reputation;

  FactionDef({
    required this.id,
    required this.name,
    this.desc = '',
    this.baseBuyMult = 1.2,
    this.baseSellMult = 0.5,
    this.repTiers = const [],
    this.demandPremiums = const {},
    this.supplyDiscounts = const {},
    this.tags = const [],
    required this.reputation,
  });

  factory FactionDef.fromJson(Map<String, dynamic> json) {
    return FactionDef(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      desc: json['desc'] ?? '',
      baseBuyMult: (json['baseBuyMult'] as num?)?.toDouble() ?? 1.2,
      baseSellMult: (json['baseSellMult'] as num?)?.toDouble() ?? 0.5,
      repTiers: (json['repTiers'] as List?)
          ?.map((e) => RepTier.fromJson(e))
          .toList() ?? [],
      demandPremiums: _parseDoubleMap(json['demandPremiums']),
      supplyDiscounts: _parseDoubleMap(json['supplyDiscounts']),
      tags: List<String>.from(json['tags'] ?? []),
      reputation: FactionReputation.fromJson(json['reputation'] ?? {}),
    );
  }

  static Map<String, double> _parseDoubleMap(dynamic data) {
    if (data == null || data is! Map) return {};
    return data.map((k, v) => MapEntry(
      k.toString(), 
      (v as num?)?.toDouble() ?? 0.0,
    ));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'desc': desc,
    'baseBuyMult': baseBuyMult,
    'baseSellMult': baseSellMult,
    'repTiers': repTiers.map((e) => e.toJson()).toList(),
    'demandPremiums': demandPremiums,
    'supplyDiscounts': supplyDiscounts,
    'tags': tags,
    'reputation': reputation.toJson(),
  };
}

/// Reputation tier
class RepTier {
  final String id;
  final int min;
  final int max;
  final double buyMult;
  final double sellMult;
  final int offerCount;
  final List<String> forbiddenTags;
  final String? specialTable;

  RepTier({
    required this.id,
    required this.min,
    required this.max,
    this.buyMult = 1.0,
    this.sellMult = 1.0,
    this.offerCount = 6,
    this.forbiddenTags = const [],
    this.specialTable,
  });

  factory RepTier.fromJson(Map<String, dynamic> json) {
    return RepTier(
      id: json['id'] ?? json['name'] ?? '',
      min: json['min'] ?? 0,
      max: json['max'] ?? 100,
      buyMult: (json['buyMult'] as num?)?.toDouble() ?? 1.0,
      sellMult: (json['sellMult'] as num?)?.toDouble() ?? 1.0,
      offerCount: (json['offerCount'] as num?)?.toInt() ?? 6,
      forbiddenTags: List<String>.from(json['forbiddenTags'] ?? []),
      specialTable: json['specialTable'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'min': min,
    'max': max,
    'buyMult': buyMult,
    'sellMult': sellMult,
    'offerCount': offerCount,
    'forbiddenTags': forbiddenTags,
    'specialTable': specialTable,
  };
}

/// Faction reputation config
class FactionReputation {
  final int min;
  final int max;
  final int start;

  FactionReputation({
    this.min = -100,
    this.max = 100,
    this.start = 0,
  });

  factory FactionReputation.fromJson(Map<String, dynamic> json) {
    return FactionReputation(
      min: json['min'] ?? -100,
      max: json['max'] ?? 100,
      start: json['start'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'start': start,
  };
}

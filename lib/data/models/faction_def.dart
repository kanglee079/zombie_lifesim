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
  final String name;
  final int min;
  final int max;
  final double priceMod;

  RepTier({
    required this.name,
    required this.min,
    required this.max,
    this.priceMod = 1.0,
  });

  factory RepTier.fromJson(Map<String, dynamic> json) {
    return RepTier(
      name: json['name'] ?? '',
      min: json['min'] ?? 0,
      max: json['max'] ?? 100,
      priceMod: (json['priceMod'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'min': min,
    'max': max,
    'priceMod': priceMod,
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

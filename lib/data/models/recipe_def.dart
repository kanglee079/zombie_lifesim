/// Recipe definition
class RecipeDef {
  final String id;
  final String name;
  final int timeMinutes;
  final List<RecipeInput> inputs;
  final List<RecipeOutput> outputs;
  final List<String> requiresTools;
  final List<String> requiresFlags;
  final List<dynamic> effectsOnCraft;
  final List<String> tags;
  final String? notes;

  RecipeDef({
    required this.id,
    required this.name,
    this.timeMinutes = 30,
    this.inputs = const [],
    this.outputs = const [],
    this.requiresTools = const [],
    this.requiresFlags = const [],
    this.effectsOnCraft = const [],
    this.tags = const [],
    this.notes,
  });

  /// Safely parse a list that may contain strings or maps
  static List<String> _parseStringList(dynamic list) {
    if (list == null) return [];
    if (list is! List) return [];
    return list.map((e) {
      if (e is String) return e;
      if (e is Map) return e['tag']?.toString() ?? e.toString();
      return e.toString();
    }).toList();
  }

  factory RecipeDef.fromJson(Map<String, dynamic> json) {
    return RecipeDef(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      timeMinutes: json['timeMinutes'] ?? 30,
      inputs: (json['inputs'] as List?)
          ?.map((e) => RecipeInput.fromJson(e))
          .toList() ?? [],
      outputs: (json['outputs'] as List?)
          ?.map((e) => RecipeOutput.fromJson(e))
          .toList() ?? [],
      requiresTools: _parseStringList(json['requiresTools']),
      requiresFlags: _parseStringList(json['requiresFlags']),
      effectsOnCraft: json['effectsOnCraft'] as List<dynamic>? ?? [],
      tags: List<String>.from(json['tags'] ?? []),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'timeMinutes': timeMinutes,
    'inputs': inputs.map((e) => e.toJson()).toList(),
    'outputs': outputs.map((e) => e.toJson()).toList(),
    'requiresTools': requiresTools,
    'requiresFlags': requiresFlags,
    'effectsOnCraft': effectsOnCraft,
    'tags': tags,
    'notes': notes,
  };
}

class RecipeInput {
  final String itemId;
  final int qty;

  RecipeInput({required this.itemId, required this.qty});

  factory RecipeInput.fromJson(Map<String, dynamic> json) {
    return RecipeInput(
      itemId: json['id'] ?? json['itemId'] ?? json['item'] ?? '',
      qty: json['qty'] ?? json['count'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'qty': qty,
  };
}

class RecipeOutput {
  final String itemId;
  final int qty;

  RecipeOutput({required this.itemId, required this.qty});

  factory RecipeOutput.fromJson(Map<String, dynamic> json) {
    return RecipeOutput(
      itemId: json['id'] ?? json['itemId'] ?? json['item'] ?? '',
      qty: json['qty'] ?? json['count'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'qty': qty,
  };
}

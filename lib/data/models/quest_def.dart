/// Quest definition
class QuestDef {
  final String id;
  final String name;
  final String description;
  final List<QuestStage> stages;
  final String type;
  final int minDay;
  final String? startEventId;
  final List<String> requirementsAny;
  final dynamic requirements;
  final String? completionCondition;

  QuestDef({
    required this.id,
    required this.name,
    this.description = '',
    this.stages = const [],
    this.type = 'main',
    this.minDay = 1,
    this.startEventId,
    this.requirementsAny = const [],
    this.requirements,
    this.completionCondition,
  });

  factory QuestDef.fromJson(Map<String, dynamic> json) {
    return QuestDef(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      stages: (json['stages'] as List?)
          ?.map((e) => QuestStage.fromJson(e))
          .toList() ?? [],
      type: json['type'] ?? 'main',
      minDay: json['minDay'] ?? 1,
      startEventId: json['startEventId'],
      requirementsAny: List<String>.from(json['requirementsAny'] ?? []),
      requirements: json['requirements'],
      completionCondition: json['completionCondition'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'stages': stages.map((e) => e.toJson()).toList(),
    'type': type,
    'minDay': minDay,
    'startEventId': startEventId,
    'requirementsAny': requirementsAny,
    'requirements': requirements,
    'completionCondition': completionCondition,
  };

  QuestStage? getStage(int index) {
    if (index < 0 || index >= stages.length) return null;
    return stages[index];
  }
}

/// Quest stage
class QuestStage {
  final String title;
  final String objective;
  final String? hint;
  final List<String>? unlocks;
  final bool isEnding;

  QuestStage({
    required this.title,
    required this.objective,
    this.hint,
    this.unlocks,
    this.isEnding = false,
  });

  factory QuestStage.fromJson(Map<String, dynamic> json) {
    final titleRaw = json['title'] ?? json['name'];
    final objectiveRaw = json['objective'] ?? json['description'];
    final unlocksRaw = json['unlocks'];
    List<String>? unlocks;

    if (unlocksRaw is List) {
      unlocks = unlocksRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (unlocksRaw is String) {
      unlocks = unlocksRaw.isNotEmpty ? [unlocksRaw] : null;
    } else if (unlocksRaw is Map) {
      // Support structured unlocks like { "flags": [...] } or { "flag": "..." }
      final flagsRaw = unlocksRaw['flags'] ?? unlocksRaw['flag'];
      if (flagsRaw is List) {
        unlocks = flagsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      } else if (flagsRaw is String) {
        unlocks = flagsRaw.isNotEmpty ? [flagsRaw] : null;
      } else {
        unlocks = null;
      }
    }

    return QuestStage(
      title: titleRaw?.toString() ?? '',
      objective: objectiveRaw?.toString() ?? '',
      hint: json['hint'],
      unlocks: unlocks,
      isEnding: json['ending'] ?? json['isEnding'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'objective': objective,
    'hint': hint,
    'unlocks': unlocks,
    'isEnding': isEnding,
  };
}

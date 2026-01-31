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
    return QuestStage(
      title: json['title'] ?? '',
      objective: json['objective'] ?? '',
      hint: json['hint'],
      unlocks: json['unlocks'] != null 
          ? List<String>.from(json['unlocks']) 
          : null,
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

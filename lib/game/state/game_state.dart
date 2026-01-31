import '../../core/clamp.dart';

/// Main game state - holds all mutable game data
class GameState {
  int day;
  String timeOfDay;
  int rngSeed;
  bool gameOver;
  String? endingType;
  String? endingId;
  String? endingGrade;
  List<String> endingSummary;
  bool terminalOverlayEnabled;

  PlayerStats playerStats;
  PlayerSkills playerSkills;
  BaseStats baseStats;
  List<PartyMember> party;
  List<InventoryItem> inventory;

  Set<String> flags;
  Map<String, int> factionRep;
  Map<String, QuestState> quests;
  Map<String, LocationState> locationStates;
  Map<String, DistrictState> districtStates;
  Map<String, EventHistory> eventHistory;
  Map<String, dynamic> tempModifiers;
  
  List<LogEntry> log;
  List<String> eventQueue;
  
  int tension;
  int marketScarcity;
  Map<String, int> marketScarcityByTag;
  String marketConditionId;
  int marketConditionDaysLeft;
  
  Map<String, dynamic>? currentEvent;
  ScavengeSession? scavengeSession;

  GameState({
    required this.day,
    required this.timeOfDay,
    required this.rngSeed,
    this.gameOver = false,
    this.endingType,
    this.endingId,
    this.endingGrade,
    this.endingSummary = const [],
    this.terminalOverlayEnabled = true,
    required this.playerStats,
    required this.playerSkills,
    required this.baseStats,
    required this.party,
    required this.inventory,
    required this.flags,
    required this.factionRep,
    required this.quests,
    required this.locationStates,
    required this.districtStates,
    required this.eventHistory,
    required this.tempModifiers,
    required this.log,
    required this.eventQueue,
    this.tension = 0,
    this.marketScarcity = 50,
    this.marketScarcityByTag = const {},
    this.marketConditionId = 'normal',
    this.marketConditionDaysLeft = 0,
    this.currentEvent,
    this.scavengeSession,
  });

  int get signalHeat => baseStats.signalHeat;
  set signalHeat(int value) => baseStats.signalHeat = value;

  /// Create a new game state
  factory GameState.newGame({int? seed}) {
    return GameState(
      day: 1,
      timeOfDay: 'morning',
      rngSeed: seed ?? DateTime.now().millisecondsSinceEpoch,
      playerStats: PlayerStats(),
      playerSkills: PlayerSkills(),
      baseStats: BaseStats(),
      party: [],
      inventory: [],
      flags: {},
      factionRep: {},
      quests: {},
      locationStates: {},
      districtStates: {},
      eventHistory: {},
      tempModifiers: {},
      log: [],
      eventQueue: [],
    );
  }

  /// Add log entry
  void addLog(String text) {
    log.add(LogEntry(day: day, text: text));
    // Keep only last 100 entries
    if (log.length > 100) {
      log.removeRange(0, log.length - 100);
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'day': day,
      'timeOfDay': timeOfDay,
      'rngSeed': rngSeed,
      'gameOver': gameOver,
      'endingType': endingType,
      'endingId': endingId,
      'endingGrade': endingGrade,
      'endingSummary': endingSummary,
      'terminalOverlayEnabled': terminalOverlayEnabled,
      'playerStats': playerStats.toJson(),
      'playerSkills': playerSkills.toJson(),
      'baseStats': baseStats.toJson(),
      'party': party.map((p) => p.toJson()).toList(),
      'inventory': inventory.map((i) => i.toJson()).toList(),
      'flags': flags.toList(),
      'factionRep': factionRep,
      'quests': quests.map((k, v) => MapEntry(k, v.toJson())),
      'locationStates': locationStates.map((k, v) => MapEntry(k, v.toJson())),
      'districtStates': districtStates.map((k, v) => MapEntry(k, v.toJson())),
      'eventHistory': eventHistory.map((k, v) => MapEntry(k, v.toJson())),
      'tempModifiers': tempModifiers,
      'log': log.map((e) => e.toJson()).toList(),
      'tension': tension,
      'signalHeat': baseStats.signalHeat,
      'marketScarcity': marketScarcity,
      'marketScarcityByTag': marketScarcityByTag,
      'marketConditionId': marketConditionId,
      'marketConditionDaysLeft': marketConditionDaysLeft,
      'scavengeSession': scavengeSession?.toJson(),
    };
  }

  /// Create from JSON
  factory GameState.fromJson(Map<String, dynamic> json) {
    final state = GameState(
      day: json['day'] ?? 1,
      timeOfDay: json['timeOfDay'] ?? 'morning',
      rngSeed: json['rngSeed'] ?? DateTime.now().millisecondsSinceEpoch,
      gameOver: json['gameOver'] ?? false,
      endingType: json['endingType'],
      endingId: json['endingId'],
      endingGrade: json['endingGrade'],
      endingSummary: (json['endingSummary'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      terminalOverlayEnabled: json['terminalOverlayEnabled'] ?? true,
      playerStats: PlayerStats.fromJson(json['playerStats'] ?? {}),
      playerSkills: PlayerSkills.fromJson(json['playerSkills'] ?? {}),
      baseStats: BaseStats.fromJson(json['baseStats'] ?? {}),
      party: (json['party'] as List?)
          ?.map((p) => PartyMember.fromJson(p))
          .toList() ?? [],
      inventory: (json['inventory'] as List?)
          ?.map((i) => InventoryItem.fromJson(i))
          .toList() ?? [],
      flags: Set<String>.from(json['flags'] ?? []),
      factionRep: Map<String, int>.from(json['factionRep'] ?? {}),
      quests: (json['quests'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), QuestState.fromJson(v)),
      ) ?? {},
      locationStates: (json['locationStates'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), LocationState.fromJson(v)),
      ) ?? {},
      districtStates: (json['districtStates'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), DistrictState.fromJson(v)),
      ) ?? {},
      eventHistory: (json['eventHistory'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), EventHistory.fromJson(v)),
      ) ?? {},
      tempModifiers: Map<String, dynamic>.from(json['tempModifiers'] ?? {}),
      log: (json['log'] as List?)
          ?.map((e) => LogEntry.fromJson(e))
          .toList() ?? [],
      eventQueue: List<String>.from(json['eventQueue'] ?? []),
      tension: json['tension'] ?? 0,
      marketScarcity: json['marketScarcity'] ?? 50,
      marketScarcityByTag: (json['marketScarcityByTag'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          {},
      marketConditionId: json['marketConditionId'] ?? 'normal',
      marketConditionDaysLeft: json['marketConditionDaysLeft'] ?? 0,
      scavengeSession: json['scavengeSession'] != null
          ? ScavengeSession.fromJson(json['scavengeSession'])
          : null,
    );

    // Backward-compat: top-level signalHeat
    final legacySignalHeat = json['signalHeat'];
    if (legacySignalHeat is num) {
      state.baseStats.signalHeat = legacySignalHeat.toInt();
    }

    // Backward-compat: old endingType
    if (state.endingId == null && state.endingType != null) {
      state.endingId = state.endingType;
    }

    return state;
  }
}

/// Player stats
class PlayerStats {
  int hp;
  int hunger;
  int thirst;
  int fatigue;
  int stress;
  int infection;
  int morale;

  PlayerStats({
    this.hp = 100,
    this.hunger = 15,
    this.thirst = 15,
    this.fatigue = 5,
    this.stress = 5,
    this.infection = 0,
    this.morale = 0,
  });

  Map<String, dynamic> toJson() => {
    'hp': hp,
    'hunger': hunger,
    'thirst': thirst,
    'fatigue': fatigue,
    'stress': stress,
    'infection': infection,
    'morale': morale,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    hp: json['hp'] ?? 100,
    hunger: json['hunger'] ?? 15,
    thirst: json['thirst'] ?? 15,
    fatigue: json['fatigue'] ?? 5,
    stress: json['stress'] ?? 5,
    infection: json['infection'] ?? 0,
    morale: json['morale'] ?? 0,
  );
}

/// Player skills
class PlayerSkills {
  int combat;
  int stealth;
  int medical;
  int craft;
  int scavenge;

  PlayerSkills({
    this.combat = 3,
    this.stealth = 3,
    this.medical = 3,
    this.craft = 3,
    this.scavenge = 3,
  });

  int getByName(String name) {
    switch (name) {
      case 'combat': return combat;
      case 'stealth': return stealth;
      case 'medical': return medical;
      case 'craft': return craft;
      case 'scavenge': return scavenge;
      case 'scout': return scavenge;
      default: return 0;
    }
  }

  void setByName(String name, int value) {
    switch (name) {
      case 'combat': combat = Clamp.skill(value); break;
      case 'stealth': stealth = Clamp.skill(value); break;
      case 'medical': medical = Clamp.skill(value); break;
      case 'craft': craft = Clamp.skill(value); break;
      case 'scavenge': scavenge = Clamp.skill(value); break;
      case 'scout': scavenge = Clamp.skill(value); break;
    }
  }

  Map<String, dynamic> toJson() => {
    'combat': combat,
    'stealth': stealth,
    'medical': medical,
    'craft': craft,
    'scavenge': scavenge,
  };

  factory PlayerSkills.fromJson(Map<String, dynamic> json) => PlayerSkills(
    combat: json['combat'] ?? 3,
    stealth: json['stealth'] ?? 3,
    medical: json['medical'] ?? 3,
    craft: json['craft'] ?? 3,
    scavenge: json['scavenge'] ?? 3,
  );
}

/// Base (shelter) stats
class BaseStats {
  int defense;
  int power;
  int noise;
  int smell;
  int hope;
  int signalHeat;
  int explorationPoints;

  BaseStats({
    this.defense = 10,
    this.power = 0,
    this.noise = 0,
    this.smell = 0,
    this.hope = 0,
    this.signalHeat = 0,
    this.explorationPoints = 0,
  });

  Map<String, dynamic> toJson() => {
    'defense': defense,
    'power': power,
    'noise': noise,
    'smell': smell,
    'hope': hope,
    'signalHeat': signalHeat,
    'explorationPoints': explorationPoints,
  };

  factory BaseStats.fromJson(Map<String, dynamic> json) => BaseStats(
    defense: json['defense'] ?? 10,
    power: json['power'] ?? 0,
    noise: json['noise'] ?? 0,
    smell: json['smell'] ?? 0,
    hope: json['hope'] ?? 0,
    signalHeat: json['signalHeat'] ?? 0,
    explorationPoints: json['explorationPoints'] ?? 0,
  );
}

/// Party member
class PartyMember {
  String id;
  String name;
  String role;
  bool isPlayer;
  int hp;
  int morale;
  List<String> traits;
  Map<String, int> skills;

  PartyMember({
    required this.id,
    required this.name,
    required this.role,
    this.isPlayer = false,
    required this.hp,
    required this.morale,
    required this.traits,
    required this.skills,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'isPlayer': isPlayer,
    'hp': hp,
    'morale': morale,
    'traits': traits,
    'skills': skills,
  };

  factory PartyMember.fromJson(Map<String, dynamic> json) => PartyMember(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    role: json['role'] ?? '',
    isPlayer: json['isPlayer'] ?? false,
    hp: json['hp'] ?? 100,
    morale: json['morale'] ?? 50,
    traits: List<String>.from(json['traits'] ?? []),
    skills: Map<String, int>.from(json['skills'] ?? {}),
  );
}

class ScavengeSession {
  final String locationId;
  final String timeOption;
  final String style;
  int remainingSteps;
  final int totalSteps;

  ScavengeSession({
    required this.locationId,
    required this.timeOption,
    required this.style,
    required this.remainingSteps,
    required this.totalSteps,
  });

  Map<String, dynamic> toJson() => {
    'locationId': locationId,
    'timeOption': timeOption,
    'style': style,
    'remainingSteps': remainingSteps,
    'totalSteps': totalSteps,
  };

  factory ScavengeSession.fromJson(Map<String, dynamic> json) {
    return ScavengeSession(
      locationId: json['locationId'] ?? '',
      timeOption: json['timeOption'] ?? 'normal',
      style: json['style'] ?? 'balanced',
      remainingSteps: json['remainingSteps'] ?? 0,
      totalSteps: json['totalSteps'] ?? 0,
    );
  }
}

/// Inventory item stack
class InventoryItem {
  String itemId;
  int qty;

  InventoryItem({required this.itemId, required this.qty});

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'qty': qty,
  };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    itemId: json['itemId'] ?? '',
    qty: json['qty'] ?? 1,
  );
}

/// Quest state
class QuestState {
  int stage;
  int startDay;

  QuestState({required this.stage, required this.startDay});

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'startDay': startDay,
  };

  factory QuestState.fromJson(Map<String, dynamic> json) => QuestState(
    stage: json['stage'] ?? 0,
    startDay: json['startDay'] ?? 1,
  );
}

/// Location depletion state
class LocationState {
  int depletion;
  int visitCount;
  int lastVisitDay;

  LocationState({
    this.depletion = 0,
    this.visitCount = 0,
    this.lastVisitDay = 0,
  });

  Map<String, dynamic> toJson() => {
    'depletion': depletion,
    'visitCount': visitCount,
    'lastVisitDay': lastVisitDay,
  };

  factory LocationState.fromJson(Map<String, dynamic> json) => LocationState(
    depletion: json['depletion'] ?? 0,
    visitCount: json['visitCount'] ?? 0,
    lastVisitDay: json['lastVisitDay'] ?? 0,
  );
}

/// District unlock state
class DistrictState {
  bool unlocked;

  DistrictState({this.unlocked = false});

  Map<String, dynamic> toJson() => {
    'unlocked': unlocked,
  };

  factory DistrictState.fromJson(Map<String, dynamic> json) => DistrictState(
    unlocked: json['unlocked'] ?? false,
  );
}

/// Event occurrence history
class EventHistory {
  int day;
  int outcomeIndex;

  EventHistory({required this.day, this.outcomeIndex = 0});

  Map<String, dynamic> toJson() => {
    'day': day,
    'outcomeIndex': outcomeIndex,
  };

  factory EventHistory.fromJson(Map<String, dynamic> json) => EventHistory(
    day: json['day'] ?? 0,
    outcomeIndex: json['outcomeIndex'] ?? 0,
  );
}

/// Log entry
class LogEntry {
  int day;
  String text;

  LogEntry({required this.day, required this.text});

  Map<String, dynamic> toJson() => {
    'day': day,
    'text': text,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    day: json['day'] ?? 1,
    text: json['text'] ?? '',
  );
}

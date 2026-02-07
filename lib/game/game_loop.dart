import '../core/logger.dart';
import '../core/clamp.dart';
import '../data/repositories/game_data_repo.dart';
import '../data/models/quest_def.dart';
import 'state/game_state.dart';
import 'state/save_manager.dart';
import 'engine/event_engine.dart';
import 'engine/effect_engine.dart';
import 'engine/requirement_engine.dart';
import 'engine/loot_engine.dart';
import 'engine/depletion_engine.dart';
import 'engine/script_engine.dart';
import 'systems/scavenge_system.dart';
import 'systems/night_system.dart';
import 'systems/craft_system.dart';
import 'systems/trade_system.dart';
import 'systems/npc_system.dart';
import 'systems/quest_system.dart';
import 'systems/daily_tick_system.dart';
import 'systems/countdown_system.dart';
import 'systems/trade_spawn_system.dart';
import 'systems/project_system.dart';
import '../core/rng.dart';

/// Main game loop controller
class GameLoop {
  final GameDataRepository data;
  final SaveManager saveManager;
  late final GameRng rng;

  // Engines
  late final RequirementEngine requirementEngine;
  late final EffectEngine effectEngine;
  late final EventEngine eventEngine;
  late final ScriptEngine scriptEngine;
  late final LootEngine lootEngine;
  late final DepletionEngine depletionEngine;

  // Systems
  late final ScavengeSystem scavengeSystem;
  late final NightSystem nightSystem;
  late final CraftSystem craftSystem;
  late final TradeSystem tradeSystem;
  late final CountdownSystem countdownSystem;
  late final TradeSpawnSystem tradeSpawnSystem;
  late final NpcSystem npcSystem;
  late final QuestSystem questSystem;
  late final DailyTickSystem dailyTickSystem;
  late final ProjectSystem projectSystem;

  GameState? _state;
  GameState get state => _state!;
  bool get hasState => _state != null;

  static const Map<String, String> _contextAlias = {
    'morning': 'base',
    'day': 'base',
    'evening': 'base',
  };

  String _resolveContext(String context) => _contextAlias[context] ?? context;

  Map<String, dynamic> get _clockConfig =>
      data.balance.raw['clock'] as Map<String, dynamic>? ?? const {};

  int _clockStartMinutes() =>
      (_clockConfig['startMinutes'] as num?)?.toInt() ?? 360;

  Map<String, int> _clockThresholds() {
    final raw =
        _clockConfig['timeOfDayThresholds'] as Map<String, dynamic>? ?? {};
    return {
      'morning': (raw['morning'] as num?)?.toInt() ?? 360,
      'day': (raw['day'] as num?)?.toInt() ?? 600,
      'evening': (raw['evening'] as num?)?.toInt() ?? 1020,
      'night': (raw['night'] as num?)?.toInt() ?? 1260,
    };
  }

  int _clockActionMinutes(String key, int fallback) {
    final raw = _clockConfig['actionMinutes'] as Map<String, dynamic>? ?? {};
    return (raw[key] as num?)?.toInt() ?? fallback;
  }

  int _clockScavengeMinutes(String timeOption) {
    final raw = _clockConfig['scavengeMinutes'] as Map<String, dynamic>? ?? {};
    final configured = (raw[timeOption] as num?)?.toInt();
    if (configured != null) return configured;
    switch (timeOption) {
      case 'quick':
        return 30;
      case 'long':
        return 120;
      case 'normal':
      default:
        return 60;
    }
  }

  String _resolveTimeOfDayFromMinutes(int minutes) {
    final thresholds = _clockThresholds();
    if (minutes >= (thresholds['night'] ?? 1260)) return 'night';
    if (minutes >= (thresholds['evening'] ?? 1020)) return 'evening';
    if (minutes >= (thresholds['day'] ?? 600)) return 'day';
    return 'morning';
  }

  void _initializeClock(GameState state) {
    state.clockMinutes = _clockStartMinutes();
    state.clockLastMs = DateTime.now().millisecondsSinceEpoch;
    state.clockCarryMinutes = 0.0;
    state.clockStatCarry = {
      'hunger': 0.0,
      'thirst': 0.0,
      'fatigue': 0.0,
      'stress': 0.0,
    };
    state.timeOfDay = _resolveTimeOfDayFromMinutes(state.clockMinutes);
  }

  void _syncClockAfterLoad(GameState state) {
    state.clockLastMs = DateTime.now().millisecondsSinceEpoch;
    state.timeOfDay = _resolveTimeOfDayFromMinutes(state.clockMinutes);
  }

  void tickClock() {
    if (_state == null) return;
    final state = _state!;
    if (state.gameOver) {
      state.clockLastMs = DateTime.now().millisecondsSinceEpoch;
      return;
    }
    if (state.currentEvent != null) {
      state.clockLastMs = DateTime.now().millisecondsSinceEpoch;
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final last = state.clockLastMs;
    if (last <= 0) {
      state.clockLastMs = now;
      return;
    }

    final deltaMs = now - last;
    if (deltaMs < 500) return;

    final minutesPerSecond =
        (_clockConfig['minutesPerRealSecond'] as num?)?.toDouble() ?? 0.5;
    final maxCatchup =
        (_clockConfig['maxCatchupMinutes'] as num?)?.toInt() ?? 30;
    double deltaMinutes = (deltaMs / 1000.0) * minutesPerSecond;
    deltaMinutes += state.clockCarryMinutes;

    int wholeMinutes = deltaMinutes.floor();
    if (wholeMinutes > maxCatchup) {
      wholeMinutes = maxCatchup;
      state.clockCarryMinutes = 0.0;
    } else {
      state.clockCarryMinutes = deltaMinutes - wholeMinutes;
    }

    if (wholeMinutes <= 0) {
      state.clockLastMs = now;
      return;
    }

    _advanceTimeMinutes(state, wholeMinutes, source: 'clock');
    state.clockLastMs = now;
  }

  void _advanceTimeMinutes(
    GameState state,
    int minutes, {
    String source = 'action',
  }) {
    if (minutes <= 0) return;
    const maxMinutes = 1440;
    final startMinutes = state.clockMinutes;
    int targetMinutes = startMinutes + minutes;

    if (targetMinutes >= maxMinutes) {
      targetMinutes = maxMinutes - 1;
      if (state.tempModifiers['dayOver'] != true) {
        state.tempModifiers['dayOver'] = true;
        state.addLog('🌙 Đã muộn. Bạn nên chuẩn bị qua đêm.');
      }
    }

    final advanceBy = targetMinutes - startMinutes;
    if (advanceBy <= 0) return;

    _applyClockStatIncrements(state, advanceBy);
    state.clockMinutes = targetMinutes;
    state.timeOfDay = _resolveTimeOfDayFromMinutes(state.clockMinutes);
    if (source != 'clock') {
      state.clockLastMs = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void _applyClockStatIncrements(GameState state, int minutes) {
    final dailyTick =
        data.balance.raw['dailyTick'] as Map<String, dynamic>? ?? {};
    final statIncrease =
        dailyTick['playerStatIncreasePerDay'] as Map<String, dynamic>? ?? {};

    final hungerPerDay = (statIncrease['hunger'] as num?)?.toDouble() ?? 12.0;
    final thirstPerDay = (statIncrease['thirst'] as num?)?.toDouble() ?? 18.0;
    final fatiguePerDay = (statIncrease['fatigue'] as num?)?.toDouble() ?? 10.0;
    final stressPerDay = (statIncrease['stress'] as num?)?.toDouble() ?? 4.0;

    final perMinute = {
      'hunger': hungerPerDay / 1440.0,
      'thirst': thirstPerDay / 1440.0,
      'fatigue': fatiguePerDay / 1440.0,
      'stress': stressPerDay / 1440.0,
    };

    final carry = Map<String, double>.from(state.clockStatCarry);

    int apply(String key, int current) {
      final delta = (perMinute[key] ?? 0.0) * minutes;
      final nextCarry = (carry[key] ?? 0.0) + delta;
      final whole = nextCarry.floor();
      carry[key] = nextCarry - whole;
      return whole;
    }

    final hungerDelta = apply('hunger', state.playerStats.hunger);
    final thirstDelta = apply('thirst', state.playerStats.thirst);
    final fatigueDelta = apply('fatigue', state.playerStats.fatigue);
    final stressDelta = apply('stress', state.playerStats.stress);

    if (hungerDelta != 0) {
      state.playerStats.hunger =
          Clamp.stat(state.playerStats.hunger + hungerDelta);
    }
    if (thirstDelta != 0) {
      state.playerStats.thirst =
          Clamp.stat(state.playerStats.thirst + thirstDelta);
    }
    if (fatigueDelta != 0) {
      state.playerStats.fatigue =
          Clamp.stat(state.playerStats.fatigue + fatigueDelta);
    }
    if (stressDelta != 0) {
      state.playerStats.stress =
          Clamp.stat(state.playerStats.stress + stressDelta);
    }

    state.clockStatCarry = carry;
  }

  bool _canPerformTimedAction(String actionLabel) {
    if (_state == null) return false;
    final state = _state!;
    final isDayOver = state.tempModifiers['dayOver'] == true ||
        state.clockMinutes >= 1439;
    if (!isDayOver) return true;

    state.tempModifiers['dayOver'] = true;
    state.addLog('🌙 Đã quá muộn để $actionLabel. Hãy kết thúc ngày.');
    return false;
  }

  GameLoop({required this.data, required this.saveManager});

  /// Initialize engines and systems
  void initialize({int? seed}) {
    rng = GameRng(seed ?? DateTime.now().millisecondsSinceEpoch);

    requirementEngine = RequirementEngine(data: data);
    lootEngine = LootEngine(data: data, rng: rng);
    npcSystem = NpcSystem(data: data, rng: rng);
    effectEngine = EffectEngine(
      data: data,
      rng: rng,
      lootEngine: lootEngine,
      npcSystem: npcSystem,
    );
    scriptEngine = ScriptEngine(
      data: data,
      requirementEngine: requirementEngine,
      effectEngine: effectEngine,
    );
    depletionEngine = DepletionEngine(data: data);
    eventEngine = EventEngine(
      data: data,
      requirementEngine: requirementEngine,
      effectEngine: effectEngine,
      scriptEngine: scriptEngine,
      rng: rng,
    );

    scavengeSystem = ScavengeSystem(
      data: data,
      lootEngine: lootEngine,
      effectEngine: effectEngine,
      depletionEngine: depletionEngine,
      requirementEngine: requirementEngine,
      rng: rng,
    );
    nightSystem = NightSystem(
      data: data,
      rng: rng,
      eventEngine: eventEngine,
      requirementEngine: requirementEngine,
    );
    craftSystem = CraftSystem(data: data, effectEngine: effectEngine);
    tradeSystem = TradeSystem(
      data: data,
      effectEngine: effectEngine,
      rng: rng,
      lootEngine: lootEngine,
    );
    countdownSystem = CountdownSystem();
    tradeSpawnSystem = TradeSpawnSystem(
      data: data,
      requirementEngine: requirementEngine,
      rng: rng,
    );
    questSystem = QuestSystem(
      data: data,
      effectEngine: effectEngine,
      requirementEngine: requirementEngine,
    );
    dailyTickSystem = DailyTickSystem(
      data: data,
      npcSystem: npcSystem,
      depletionEngine: depletionEngine,
      tradeSystem: tradeSystem,
      requirementEngine: requirementEngine,
      eventEngine: eventEngine,
      rng: rng,
      countdownSystem: countdownSystem,
      tradeSpawnSystem: tradeSpawnSystem,
    );
    projectSystem = ProjectSystem(
      data: data,
      effectEngine: effectEngine,
      requirementEngine: requirementEngine,
      rng: rng,
    );

    GameLogger.game('GameLoop initialized');
  }

  /// Start a new game
  Future<void> newGame() async {
    _state = GameState.newGame();
    _initializeClock(_state!);

    // Add player to party
    _state!.party.add(PartyMember(
      id: 'player',
      name: 'Bạn',
      role: 'survivor',
      isPlayer: true,
      hp: 100,
      morale: 0,
      traits: [],
      skills: {
        'combat': 3,
        'stealth': 3,
        'medical': 3,
        'craft': 3,
        'scavenge': 3
      },
    ));

    // Initialize starter district
    for (final district in data.districts.values) {
      if (district.startUnlocked) {
        _state!.districtStates[district.id] = DistrictState(unlocked: true);
      }
    }

    // Add starter items
    effectEngine.addItemToInventory(_state!, 'bandage', 2);
    effectEngine.addItemToInventory(_state!, 'canned_beans', 3);
    effectEngine.addItemToInventory(_state!, 'water_bottle', 2);
    effectEngine.addItemToInventory(_state!, 'knife_kitchen', 1);

    // First day log
    _state!.addLog(
        '☀️ Ngày 1 - Thức dậy sau đại dịch. Cần tìm nơi trú ẩn an toàn.');

    await saveManager.save(_state!);

    GameLogger.game('New game started');
  }

  /// Load existing game
  Future<bool> loadGame() async {
    final loaded = await saveManager.load();
    if (loaded != null) {
      _state = loaded;
      _syncClockAfterLoad(_state!);
      GameLogger.game('Game loaded: Day ${_state!.day}');
      return true;
    }
    return false;
  }

  /// Save current game
  Future<void> saveGame() async {
    if (_state != null) {
      await saveManager.save(_state!);
      GameLogger.game('Game saved');
    }
  }

  /// Process morning phase
  void morningPhase() {
    if (_state == null) return;
    if (_state!.currentEvent != null) {
      GameLogger.game('Morning phase skipped: current event already active.');
      return;
    }

    _state!.timeOfDay = 'morning';

    // Check quest auto-starts
    questSystem.checkAutoStartQuests(_state!);

    if (_state!.eventQueue.isNotEmpty) {
      final nextEventId = _state!.eventQueue.removeAt(0);
      eventEngine.triggerEvent(nextEventId, _state!);
      GameLogger.game('Morning phase: triggered queued event $nextEventId');
      return;
    }

    // Generate morning event
    final event = eventEngine.selectEvent(
      _state!,
      context: _resolveContext(_state!.timeOfDay),
    );
    if (event != null) {
      _state!.currentEvent = event;
    }

    GameLogger.game('Morning phase: Day ${_state!.day}');
  }

  /// Process player choice for current event
  void processChoice(int choiceIndex) {
    if (_state == null || _state!.currentEvent == null) return;

    final currentEvent = _state!.currentEvent!;
    final currentEventId = currentEvent['id'] as String?;
    final isOverflowEvent = currentEventId == 'inv_overflow_drop';
    final isRationingEvent = currentEventId == 'rationing_policy';
    final chosen = _getChoice(currentEvent, choiceIndex);
    eventEngine.processChoice(_state!, currentEvent, choiceIndex);

    final session = _state!.scavengeSession;
    final inScavenge = session != null;

    // Track this event as used in current scavenge session
    if (inScavenge && !isOverflowEvent) {
      final eventId = currentEvent['id'] as String?;
      if (eventId != null) {
        session.usedEventIds.add(eventId);
      }
    }

    if (_state!.currentEvent == currentEvent) {
      _state!.currentEvent = null;
    }

    if (isRationingEvent) {
      _applyRationingChoice(chosen, choiceIndex);
      if (_state!.tempModifiers['pendingNightPhase'] == true) {
        _state!.tempModifiers.remove('pendingNightPhase');
        _executeNightPhase();
      }
      return;
    }

    if (inScavenge) {
      if (_state!.currentEvent == null) {
        if (!isOverflowEvent) {
          session.remainingSteps -= 1;
        }
        if (_triggerInventoryOverflowIfNeeded()) {
          return;
        }
        if (session.remainingSteps > 0) {
          final next = eventEngine.selectEvent(
            _state!,
            context: 'scavenge:${session.locationId}',
            excludeIds: session.usedEventIds,
          );
          if (next != null) {
            _state!.currentEvent = next;
          } else {
            _finishScavengeSession();
          }
        } else {
          _finishScavengeSession();
        }
      }
      return;
    }

    // Move to next phase
    if (_state!.timeOfDay == 'morning') {
      final dayStart = _clockThresholds()['day'] ?? 600;
      if (_state!.clockMinutes < dayStart) {
        _advanceTimeMinutes(_state!, dayStart - _state!.clockMinutes,
            source: 'morning_event');
      } else {
        _state!.timeOfDay = 'day';
      }
    }
  }

  void _finishScavengeSession() {
    final session = _state?.scavengeSession;
    if (_state == null || session == null) return;
    scavengeSystem.finishSession(session, _state!);
    final eveningStart = _clockThresholds()['evening'] ?? 1020;
    final scavengeMinutes = _clockScavengeMinutes(session.timeOption);
    _advanceTimeMinutes(_state!, scavengeMinutes, source: 'scavenge');
    if (_state!.clockMinutes < eveningStart) {
      _advanceTimeMinutes(
        _state!,
        eveningStart - _state!.clockMinutes,
        source: 'scavenge_wrap',
      );
    }
    _state!.scavengeSession = null;
    _state!.currentEvent = null;
  }

  /// Execute scavenge run
  void doScavenge({
    required String locationId,
    required ScavengeTime time,
    required ScavengeStyle style,
  }) {
    if (_state == null) {
      throw StateError('No game state');
    }
    if (!_canPerformTimedAction('khám phá')) return;

    // Start a scavenge session (event-driven)
    final session = scavengeSystem.startSession(
      locationId: locationId,
      time: time,
      style: style,
      state: _state!,
    );
    _state!.scavengeSession = session;

    // Trigger first scavenge event
    final event = eventEngine.selectEvent(
      _state!,
      context: 'scavenge:$locationId',
    );
    if (event != null) {
      _state!.currentEvent = event;
    } else {
      // No event available, finish immediately
      _finishScavengeSession();
    }
  }

  /// Execute crafting
  CraftResult doCraft(String recipeId) {
    if (_state == null) {
      throw StateError('No game state');
    }
    if (!_canPerformTimedAction('chế tạo')) {
      return const CraftResult(
        success: false,
        message: 'Đã quá muộn để chế tạo hôm nay.',
      );
    }

    final result = craftSystem.craft(recipeId, _state!);
    if (result.success) {
      final recipe = data.getRecipe(recipeId);
      final minutes = recipe?.timeMinutes ?? 30;
      _advanceTimeMinutes(_state!, minutes, source: 'craft');
    }
    return result;
  }

  /// Execute trade
  TradeResult doTrade({
    required String itemId,
    required int qty,
    required String factionId,
    required bool isBuying,
  }) {
    if (_state == null) {
      throw StateError('No game state');
    }
    if (!_canPerformTimedAction('giao dịch')) {
      return const TradeResult(
        success: false,
        message: 'Đã quá muộn để giao dịch hôm nay.',
        currencyDelta: 0,
      );
    }

    final result = isBuying
        ? tradeSystem.buyFromTrader(
            itemId: itemId,
            qty: qty,
            factionId: factionId,
            state: _state!,
          )
        : tradeSystem.sellToTrader(
            itemId: itemId,
            qty: qty,
            factionId: factionId,
            state: _state!,
          );

    if (result.success) {
      final minutes = _clockActionMinutes('trade', 30);
      _advanceTimeMinutes(_state!, minutes, source: 'trade');
    }

    return result;
  }

  /// Use an item
  void useItem(String itemId) {
    if (_state == null) return;
    effectEngine.useItem(_state!, itemId);
  }

  /// Process night phase
  NightResult nightPhase() {
    if (_state == null) {
      throw StateError('No game state');
    }

    if (_state!.tempModifiers['rationPolicy'] == null) {
      final rationing = eventEngine.getEvent('rationing_policy');
      if (rationing != null) {
        _state!.currentEvent = Map<String, dynamic>.from(rationing);
        _state!.tempModifiers['pendingNightPhase'] = true;
        return const NightResult(
          wasAttacked: false,
          damage: 0,
          zombiesKilled: 0,
          lostItems: [],
          narrative: 'pending_rationing',
        );
      }
    }

    return _executeNightPhase();
  }

  NightResult _executeNightPhase() {
    _state!.timeOfDay = 'night';

    // Resolve night threats
    final result = nightSystem.resolve(_state!);
    _state!.tempModifiers['nightAttack'] = result.wasAttacked;

    // Move to next day
    dailyTickSystem.tick(_state!);
    _initializeClock(_state!);
    _state!.tempModifiers.remove('dayOver');

    // Process active projects (yields, completions)
    projectSystem.dailyTick(_state!);

    // Check quest completion conditions after daily changes
    questSystem.checkQuestProgress(_state!);

    // Cleanup old event history to prevent memory growth
    _state!.cleanupEventHistory();

    // Start the new day with a morning event if possible
    morningPhase();

    // Autosave
    saveGame();

    return result;
  }

  Map<String, dynamic>? _getChoice(Map<String, dynamic>? event, int index) {
    if (event == null) return null;
    final choices = event['choices'] as List<dynamic>?;
    if (choices == null || index < 0 || index >= choices.length) return null;
    final choice = choices[index];
    return choice is Map<String, dynamic> ? choice : null;
  }

  void _applyRationingChoice(Map<String, dynamic>? choice, int choiceIndex) {
    String policy = 'normal';
    final id = choice?['id']?.toString();
    switch (id) {
      case 'half':
      case 'half_ration':
      case 'halfRation':
        policy = 'half';
        break;
      case 'strict':
        policy = 'strict';
        break;
      case 'normal':
        policy = 'normal';
        break;
      default:
        policy = choiceIndex == 1
            ? 'half'
            : (choiceIndex == 2 ? 'strict' : 'normal');
    }
    _state?.tempModifiers['rationPolicy'] = policy;
  }

  bool _triggerInventoryOverflowIfNeeded() {
    if (_state == null) return false;
    if (!_isInventoryOverCapacity(_state!)) return false;
    final overflowEvent = _buildInventoryOverflowEvent(_state!);
    if (overflowEvent == null) return false;
    _state!.currentEvent = overflowEvent;
    return true;
  }

  bool _isInventoryOverCapacity(GameState state) {
    final weight = _calculateInventoryWeight(state);
    final capacity = _calculateCarryCapacity(state);
    return weight > capacity;
  }

  double _calculateInventoryWeight(GameState state) {
    double total = 0;
    for (final stack in state.inventory) {
      final item = data.getItem(stack.itemId);
      if (item == null) continue;
      total += item.weight * stack.qty;
    }
    return total;
  }

  double _calculateCarryCapacity(GameState state) {
    final config =
        data.balance.raw['carryCapacity'] as Map<String, dynamic>? ?? {};
    final baseKg = (config['baseKg'] as num?)?.toDouble() ?? 14.0;
    final perMember =
        (config['perPartyMemberBonus'] as num?)?.toDouble() ?? 2.0;
    final backpackBonus = (config['backpackBonus'] as num?)?.toDouble() ?? 6.0;

    final partyBonus = (state.party.length - 1).clamp(0, 12) * perMember;
    final backpackCount = state.inventory
        .where((stack) => stack.itemId == 'backpack')
        .fold<int>(0, (sum, stack) => sum + stack.qty);
    return baseKg + partyBonus + backpackCount * backpackBonus;
  }

  Map<String, dynamic>? _buildInventoryOverflowEvent(GameState state) {
    final template = data.events['inv_overflow_drop'];
    if (template == null) return null;
    final event = Map<String, dynamic>.from(template);

    final choices = _buildOverflowChoices(state);
    event['choices'] = choices;
    return event;
  }

  List<Map<String, dynamic>> _buildOverflowChoices(GameState state) {
    final stacks = state.inventory.toList();
    stacks.sort((a, b) {
      final weightA = _stackWeight(a);
      final weightB = _stackWeight(b);
      return weightB.compareTo(weightA);
    });

    const maxChoices = 8;
    final selected = stacks.take(maxChoices);
    final choices = <Map<String, dynamic>>[];
    for (final stack in selected) {
      final item = data.getItem(stack.itemId);
      final name = item?.name ?? stack.itemId;
      final qty = stack.qty;
      choices.add({
        'id': 'drop_${stack.itemId}',
        'label': 'Bỏ $name x$qty',
        'text': 'Bỏ $name x$qty',
        'effects': [
          {
            'type': 'item_remove',
            'id': stack.itemId,
            'qty': qty,
          }
        ],
      });
    }

    return choices;
  }

  double _stackWeight(InventoryItem stack) {
    final item = data.getItem(stack.itemId);
    if (item == null) return 0;
    return item.weight * stack.qty;
  }

  /// Rest action (restore fatigue, pass time)
  void rest() {
    if (_state == null) return;
    if (!_canPerformTimedAction('nghỉ ngơi')) return;

    final restConfig =
        data.balance.raw['dailyTick']?['restAction'] as Map<String, dynamic>? ??
            {};
    final fatigueDelta = (restConfig['fatigueDelta'] as num?)?.toInt() ?? -25;
    final stressDelta = (restConfig['stressDelta'] as num?)?.toInt() ?? -10;
    final moraleDelta = (restConfig['moraleDelta'] as num?)?.toInt() ?? 0;
    final noiseDelta = (restConfig['noiseDelta'] as num?)?.toInt() ?? 0;
    final smellDelta = (restConfig['smellDelta'] as num?)?.toInt() ?? 0;

    _state!.playerStats.fatigue =
        Clamp.stat(_state!.playerStats.fatigue + fatigueDelta);
    _state!.playerStats.stress =
        Clamp.stat(_state!.playerStats.stress + stressDelta);
    _state!.playerStats.morale =
        Clamp.i(_state!.playerStats.morale + moraleDelta, -50, 50);
    _state!.baseStats.noise =
        Clamp.stat(_state!.baseStats.noise + noiseDelta, 0, 100);
    _state!.baseStats.smell =
        Clamp.stat(_state!.baseStats.smell + smellDelta, 0, 100);

    _state!.addLog('😴 Nghỉ ngơi. Phục hồi thể lực.');
    final eveningStart = _clockThresholds()['evening'] ?? 1020;
    if (_state!.clockMinutes < eveningStart) {
      _advanceTimeMinutes(
        _state!,
        eveningStart - _state!.clockMinutes,
        source: 'rest',
      );
    } else {
      final restMinutes = _clockActionMinutes('rest', 120);
      _advanceTimeMinutes(_state!, restMinutes, source: 'rest');
    }

    GameLogger.game('Player rested');
  }

  /// Fortify base action
  void fortifyBase() {
    if (_state == null) return;
    if (!_canPerformTimedAction('gia cố')) return;

    // Check for materials
    bool hasWood = false;
    bool hasNails = false;

    for (final stack in _state!.inventory) {
      if (stack.itemId == 'wood_plank' && stack.qty > 0) hasWood = true;
      if (stack.itemId == 'nails' && stack.qty > 0) hasNails = true;
    }

    if (hasWood && hasNails) {
      effectEngine.removeItemFromInventory(_state!, 'wood_plank', 1);
      effectEngine.removeItemFromInventory(_state!, 'nails', 1);
      _state!.baseStats.defense = Clamp.stat(_state!.baseStats.defense + 5);
      _state!.addLog('🔨 Gia cố căn cứ. Phòng thủ +5.');
    } else {
      _state!.addLog('⚠️ Cần gỗ và đinh để gia cố.');
    }

    final minutes = _clockActionMinutes('fortify', 60);
    _advanceTimeMinutes(_state!, minutes, source: 'fortify');

    GameLogger.game('Fortify base attempted');
  }

  /// Use radio (increases signal heat, may trigger events)
  void useRadio() {
    if (_state == null) return;
    if (!_canPerformTimedAction('bật radio')) return;

    _state!.signalHeat = Clamp.stat(_state!.signalHeat + 10);
    _state!.addLog('📻 Sử dụng radio. Tín hiệu +10.');

    _state!.tempModifiers['usedRadioToday'] = true;

    // Chance for radio event
    final event = eventEngine.selectEvent(_state!, context: 'radio');
    if (event != null) {
      _state!.currentEvent = event;
    }

    final minutes = _clockActionMinutes('radio', 15);
    _advanceTimeMinutes(_state!, minutes, source: 'radio');

    GameLogger.game('Radio used');
  }

  PuzzleResult solveNumbersPuzzle({
    required String district,
    required int grid,
    required int locker,
  }) {
    if (_state == null) {
      throw StateError('No game state');
    }
    final state = _state!;
    final solutionRaw = state.notes['numbers_solution'];
    if (solutionRaw == null || solutionRaw.isEmpty) {
      return const PuzzleResult(
        success: false,
        message: 'Chưa có dữ liệu để giải mã.',
        attemptsToday: 0,
        triangulated: false,
      );
    }

    final parsed = _parseNumbersSolution(solutionRaw);
    if (parsed == null) {
      return const PuzzleResult(
        success: false,
        message: 'Dữ liệu giải mã bị lỗi.',
        attemptsToday: 0,
        triangulated: false,
      );
    }

    final attemptsToday = _incrementPuzzleAttempts(state, 'numbers_station');
    final normalizedDistrict = district.trim().toUpperCase();
    final success = normalizedDistrict == parsed.district &&
        grid == parsed.grid &&
        locker == parsed.locker;

    if (success) {
      state.flags.add('numbers_decoded');
      state.flags.add('unlock_numbers_cache');
      final log = state.notes['numbers_success_log'] ??
          '🔐 Giải mã thành công. Đã mở vị trí kho số.';
      state.addLog(log);
      return PuzzleResult(
        success: true,
        message: 'Giải mã thành công.',
        attemptsToday: attemptsToday,
        triangulated: false,
      );
    }

    state.baseStats.signalHeat =
        Clamp.stat(state.baseStats.signalHeat + 8, 0, 100);
    state.playerStats.stress = Clamp.stat(state.playerStats.stress + 4, 0, 100);
    final triangulated = attemptsToday >= 2;
    if (triangulated) {
      state.flags.add('triangulated');
    }
    final failLog = state.notes['numbers_fail_log'] ??
        '⚠️ Giải mã sai. Tín hiệu bị nhiễu mạnh hơn.';
    state.addLog(failLog);
    return PuzzleResult(
      success: false,
      message: triangulated
          ? 'Sai lần thứ hai. Bạn có thể đã bị lần theo.'
          : 'Giải mã sai. Hãy thử lại.',
      attemptsToday: attemptsToday,
      triangulated: triangulated,
    );
  }

  _NumbersSolution? _parseNumbersSolution(String raw) {
    final parts = raw.split('-');
    if (parts.length < 3) return null;
    final district = parts[0].trim().toUpperCase();
    final grid = int.tryParse(parts[1].trim());
    final locker = int.tryParse(parts[2].trim());
    if (district.isEmpty || grid == null || locker == null) return null;
    return _NumbersSolution(district: district, grid: grid, locker: locker);
  }

  int _incrementPuzzleAttempts(GameState state, String puzzleId) {
    final key = 'puzzle_attempts:$puzzleId:day${state.day}';
    final current = int.tryParse(state.notes[key] ?? '') ?? 0;
    final next = current + 1;
    state.notes[key] = next.toString();
    return next;
  }

  /// Check if game is over
  bool get isGameOver => _state?.gameOver ?? false;

  /// Get ending type
  String? get endingType => _state?.endingType;

  /// Get available locations for scavenging
  List<String> getScavengeLocations() {
    if (_state == null) return [];
    return scavengeSystem.getAvailableLocations(_state!);
  }

  /// Get available recipes
  List<dynamic> getAvailableRecipes() {
    if (_state == null) return [];
    return craftSystem.getAvailableRecipes(_state!);
  }

  /// Get known recipes
  List<dynamic> getKnownRecipes() {
    if (_state == null) return [];
    return craftSystem.getKnownRecipes(_state!);
  }

  /// Get active quests with their states
  List<(QuestDef, QuestState)> getActiveQuests() {
    if (_state == null) return [];
    return questSystem.getActiveQuests(_state!);
  }

  /// Check if recipe can be crafted
  bool canCraft(String recipeId) {
    if (_state == null) return false;
    return craftSystem.canCraft(recipeId, _state!);
  }

  /// Get available base projects
  List<Map<String, dynamic>> getAvailableProjects() {
    if (_state == null) return [];
    return projectSystem.getAvailableProjects(_state!);
  }

  /// Get active project progress list
  List<ProjectProgress> getActiveProjectsProgress() {
    if (_state == null) return [];
    return projectSystem.getActiveProjectsProgress(_state!);
  }

  /// Check if a project can start
  bool canStartProject(String projectId) {
    if (_state == null) return false;
    return projectSystem.canStartProject(_state!, projectId);
  }

  /// Get missing items for a project
  List<Map<String, dynamic>> getProjectMissingItems(String projectId) {
    if (_state == null) return [];
    return projectSystem.getMissingItems(_state!, projectId);
  }

  /// Start a project
  bool startProject(String projectId) {
    if (_state == null) return false;
    return projectSystem.startProject(_state!, projectId);
  }

  /// Get available factions for trade
  List<String> getTradeFactions() {
    if (_state == null) return [];
    return tradeSystem.getAvailableFactions(_state!);
  }

  /// Get trade price
  int getTradePrice(String itemId, String factionId, bool isBuying) {
    if (_state == null) return 0;
    if (isBuying) {
      return tradeSystem.getBuyPrice(itemId, factionId, _state!);
    } else {
      return tradeSystem.getSellPrice(itemId, factionId, _state!);
    }
  }

  /// Generate trade offers
  List<TradeOffer> generateTradeOffers(String factionId) {
    if (_state == null) return [];
    return tradeSystem.generateOffers(factionId, _state!);
  }

  /// Reroll trade offers (applies reroll cost)
  List<TradeOffer> rerollTradeOffers(String factionId) {
    if (_state == null) return [];
    _applyTradeRerollCost(_state!);
    return tradeSystem.generateOffers(factionId, _state!);
  }

  void _applyTradeRerollCost(GameState state) {
    final offerGen =
        data.tradeSystem['offerGeneration'] as Map<String, dynamic>? ?? {};
    final cost = offerGen['rerollCost'] as Map<String, dynamic>? ?? {};
    if (cost.isEmpty) return;
    final type = cost['type']?.toString();
    final effect = Map<String, dynamic>.from(cost);
    if (type == 'baseStat') {
      effect['type'] = 'base';
    }
    effectEngine.executeEffects([effect], state);
  }

  /// Unlock a district
  bool unlockDistrict(String districtId) {
    if (_state == null) return false;

    final district = data.getDistrict(districtId);
    if (district == null) return false;

    if (district.requirements.isNotEmpty &&
        !requirementEngine.check(district.requirements, _state!)) {
      _state!.addLog('⚠️ Chưa đủ điều kiện để mở khu vực này.');
      return false;
    }

    final cost = district.unlockCostEP;
    if (_state!.baseStats.explorationPoints < cost) {
      _state!.addLog('⚠️ Không đủ điểm khám phá. Cần $cost EP.');
      return false;
    }

    _state!.baseStats.explorationPoints -= cost;
    _state!.districtStates[districtId] = DistrictState(unlocked: true);
    _state!.addLog('🗺️ Mở khóa khu vực: ${district.name}');

    GameLogger.game('District unlocked: $districtId');
    return true;
  }
}

class _NumbersSolution {
  final String district;
  final int grid;
  final int locker;

  const _NumbersSolution({
    required this.district,
    required this.grid,
    required this.locker,
  });
}

class PuzzleResult {
  final bool success;
  final String message;
  final int attemptsToday;
  final bool triangulated;

  const PuzzleResult({
    required this.success,
    required this.message,
    required this.attemptsToday,
    required this.triangulated,
  });
}

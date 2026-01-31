import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../core/rng.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import 'npc_system.dart';
import '../engine/depletion_engine.dart';
import '../engine/event_engine.dart';
import '../engine/requirement_engine.dart';
import 'trade_system.dart';
import 'countdown_system.dart';
import 'trade_spawn_system.dart';

/// System for handling daily tick (stat changes, consumption, etc.)
class DailyTickSystem {
  final GameDataRepository data;
  final NpcSystem npcSystem;
  final DepletionEngine depletionEngine;
  final TradeSystem tradeSystem;
  final RequirementEngine requirementEngine;
  final EventEngine eventEngine;
  final GameRng rng;
  final CountdownSystem countdownSystem;
  final TradeSpawnSystem tradeSpawnSystem;

  DailyTickSystem({
    required this.data,
    required this.npcSystem,
    required this.depletionEngine,
    required this.tradeSystem,
    required this.requirementEngine,
    required this.eventEngine,
    required this.rng,
    required this.countdownSystem,
    required this.tradeSpawnSystem,
  });

  /// Execute daily tick
  void tick(GameState state) {
    final balance = data.balance;
    final dailyTick = balance.raw['dailyTick'] as Map<String, dynamic>? ?? {};
    final statIncrease = dailyTick['playerStatIncreasePerDay'] as Map<String, dynamic>? ?? {};
    final rationPolicy = state.tempModifiers['rationPolicy']?.toString();
    final usedRadioToday = state.tempModifiers['usedRadioToday'] == true;

    final hungerInc = (statIncrease['hunger'] as num?)?.toInt() ?? 12;
    final thirstInc = (statIncrease['thirst'] as num?)?.toInt() ?? 18;
    final fatigueInc = (statIncrease['fatigue'] as num?)?.toInt() ?? 10;
    final stressInc = (statIncrease['stress'] as num?)?.toInt() ?? 4;

    // Apply player stat increases (bad meters)
    state.playerStats.hunger = Clamp.stat(state.playerStats.hunger + hungerInc);
    state.playerStats.thirst = Clamp.stat(state.playerStats.thirst + thirstInc);
    state.playerStats.fatigue = Clamp.stat(state.playerStats.fatigue + fatigueInc);
    state.playerStats.stress = Clamp.stat(state.playerStats.stress + stressInc);

    _applyInfectionProgression(state, dailyTick);

    // Consume food/water
    final consumptionResult = _consumeResources(state, rationPolicy: rationPolicy);
    _applyMoraleDaily(state, dailyTick, consumptionResult);
    _applyRationingDeltas(state, rationPolicy);

    // Check critical stats after resource adjustments
    _checkCriticalStats(state);

    // Update party
    npcSystem.updatePartyMorale(state);
    state.tension = npcSystem.calculateTension(state);

    // Base decay
    _applyBaseDecay(state);

    _applyTriangulationCheck(state);

    _applySignalHeatCooldown(state);
    _applyListenerTrace(state, usedRadioToday);

    // Clear expired temp modifiers
    _clearExpiredModifiers(state);
    state.tempModifiers.remove('rationPolicy');

    // Location depletion recovery
    depletionEngine.applyRecovery(state);

    // Update market state
    tradeSystem.updateMarket(state);

    // Update countdowns
    countdownSystem.tick(state);

    // Advance day
    state.day++;
    state.timeOfDay = 'morning';

    state.addLog('☀️ Ngày ${state.day} bắt đầu.');

    tradeSpawnSystem.runDailySpawns(state, context: 'base');

    GameLogger.game('Daily tick completed. Day: ${state.day}');
  }

  /// Check for critical stat effects
  void _checkCriticalStats(GameState state) {
    // HP critical
    if (state.playerStats.hp <= 0) {
      state.gameOver = true;
      state.endingType = 'death_hp';
      state.addLog('💀 Bạn đã chết vì hết máu.');
      return;
    }

    // Infection critical
    if (state.playerStats.infection >= 100) {
      state.gameOver = true;
      state.endingType = 'death_infection';
      state.addLog('🧟 Bạn đã biến thành zombie.');
      return;
    }

    _applyHpThresholdDamage(state);
  }

  void _applyInfectionProgression(GameState state, Map<String, dynamic> dailyTick) {
    final infectionConfig = dailyTick['infection'] as Map<String, dynamic>? ?? {};
    if (state.playerStats.infection <= 0) return;

    int delta = (infectionConfig['ifInfectedDelta'] as num?)?.toInt() ?? 1;

    final hygieneOver = (infectionConfig['ifBadHygieneSmellOver'] as num?)?.toInt() ?? 60;
    if (state.baseStats.smell > hygieneOver) {
      delta += (infectionConfig['badHygieneExtraDelta'] as num?)?.toInt() ?? 1;
    }

    final criticalOver = (infectionConfig['ifNoAntibioticsAndOver'] as num?)?.toInt() ?? 70;
    if (state.playerStats.infection > criticalOver && !_hasItem(state, 'antibiotics')) {
      delta += (infectionConfig['criticalExtraDelta'] as num?)?.toInt() ?? 2;
    }

    state.playerStats.infection = Clamp.infection(state.playerStats.infection + delta);
  }

  void _applyMoraleDaily(
    GameState state,
    Map<String, dynamic> dailyTick,
    _ConsumptionResult consumption,
  ) {
    final moraleConfig = dailyTick['morale'] as Map<String, dynamic>? ?? {};
    int delta = (moraleConfig['baseDelta'] as num?)?.toInt() ?? 0;

    if (consumption.missingFood > 0) {
      delta += (moraleConfig['perMissingFood'] as num?)?.toInt() ?? 0;
    }
    if (consumption.missingWater > 0) {
      delta += (moraleConfig['perMissingWater'] as num?)?.toInt() ?? 0;
    }

    if (consumption.missingFood == 0 && consumption.missingWater == 0) {
      delta += (moraleConfig['perGoodMeal'] as num?)?.toInt() ?? 0;
    }

    if (state.tempModifiers['nightAttack'] == true) {
      delta += (moraleConfig['perNightAttack'] as num?)?.toInt() ?? 0;
      state.tempModifiers.remove('nightAttack');
    }

    final hopeFactor = (moraleConfig['hopeToMoraleFactor'] as num?)?.toDouble() ?? 0.0;
    if (hopeFactor != 0) {
      delta += (state.baseStats.hope * hopeFactor).round();
    }

    state.playerStats.morale = Clamp.i(state.playerStats.morale + delta, -50, 50);
  }

  void _applyRationingDeltas(GameState state, String? rationPolicy) {
    if (rationPolicy == null || rationPolicy.isEmpty || rationPolicy == 'normal') {
      return;
    }

    final partyConfig = data.balance.raw['party'] as Map<String, dynamic>? ?? {};
    final rationing = partyConfig['rationing'] as Map<String, dynamic>? ?? {};
    final key = switch (rationPolicy) {
      'half' => 'halfRation',
      'halfRation' => 'halfRation',
      'strict' => 'strict',
      _ => '',
    };
    if (key.isEmpty) return;

    final ration = rationing[key] as Map<String, dynamic>? ?? {};
    final moraleDelta = (ration['moraleDelta'] as num?)?.toInt() ?? 0;
    final stressDelta = (ration['stressDelta'] as num?)?.toInt() ?? 0;

    if (moraleDelta != 0) {
      state.playerStats.morale = Clamp.morale(state.playerStats.morale + moraleDelta);
    }
    if (stressDelta != 0) {
      state.playerStats.stress = Clamp.stat(state.playerStats.stress + stressDelta);
    }
  }

  void _applyHpThresholdDamage(GameState state) {
    final thresholds =
        data.balance.raw['dailyTick']?['hpDamageThresholds'] as List<dynamic>? ?? [];
    if (thresholds.isEmpty) return;

    int totalHpDelta = 0;
    for (final entry in thresholds) {
      if (entry is! Map) continue;
      final stat = entry['stat']?.toString();
      final over = (entry['over'] as num?)?.toInt();
      final hpDelta = (entry['hpDelta'] as num?)?.toInt() ?? 0;
      if (stat == null || over == null) continue;

      int current = 0;
      switch (stat) {
        case 'hunger':
          current = state.playerStats.hunger;
          break;
        case 'thirst':
          current = state.playerStats.thirst;
          break;
        case 'fatigue':
          current = state.playerStats.fatigue;
          break;
        case 'stress':
          current = state.playerStats.stress;
          break;
        case 'infection':
          current = state.playerStats.infection;
          break;
        default:
          break;
      }

      if (current > over) {
        totalHpDelta += hpDelta;
      }
    }

    if (totalHpDelta != 0) {
      state.playerStats.hp = Clamp.hp(state.playerStats.hp + totalHpDelta);
      if (totalHpDelta < 0) {
        state.addLog('⚠️ Tình trạng xấu khiến bạn mất ${totalHpDelta.abs()} HP.');
      }
    }
  }

  void _applyTriangulationCheck(GameState state) {
    final signalModel =
        data.balance.raw['signalHeatModel'] as Map<String, dynamic>? ?? {};
    final triangulation = signalModel['triangulation'] as Map<String, dynamic>? ?? {};
    final minHeat = (triangulation['minHeat'] as num?)?.toInt() ?? 0;
    final currentHeat = state.baseStats.signalHeat;
    if (currentHeat < minHeat) return;

    final chanceBase = (triangulation['chanceBase'] as num?)?.toDouble() ?? 0.0;
    final chancePerHeat = (triangulation['chancePerHeat'] as num?)?.toDouble() ?? 0.0;
    final cap = (triangulation['cap'] as num?)?.toDouble() ?? 1.0;
    final chance = (chanceBase + currentHeat * chancePerHeat).clamp(0.0, cap);

    if (rng.nextDouble() > chance) return;

    state.tempModifiers['triangulated'] = {
      'value': true,
      'expiresDay': state.day,
    };

    final context = state.timeOfDay == 'night' ? 'night' : 'base';
    if (context == 'night' && _isEventEligible(state, 'end_broadcast_triangulation')) {
      state.eventQueue.add('end_broadcast_triangulation');
      return;
    }

    final selected = _selectTriangulationEvent(state, context);
    if (selected != null) {
      state.eventQueue.add(selected);
    }
  }

  void _applyListenerTrace(GameState state, bool usedRadioToday) {
    int delta = 0;
    final stealth = data.balance.raw['stealthSystem'] as Map<String, dynamic>? ?? {};
    final noiseSources = stealth['noiseSources'] as Map<String, dynamic>? ?? {};
    final broadcastDelta = (noiseSources['radio_broadcast'] as num?)?.toInt() ?? 4;

    if (usedRadioToday) {
      delta += broadcastDelta;
    } else {
      final silent = (stealth['decayActions'] as Map<String, dynamic>?)?['silentDay']
              as Map<String, dynamic>? ??
          {};
      final silentHeatDelta = (silent['signalHeatDelta'] as num?)?.toInt() ?? -4;
      final silentPenalty = silentHeatDelta.abs().clamp(1, 6);
      delta -= silentPenalty;
    }

    if (state.flags.contains('base_signal_booster')) {
      delta += 2;
    }
    if (state.flags.contains('base_signal_jammer') ||
        state.flags.contains('signal_jammer')) {
      delta -= 3;
    }

    final signalModel =
        data.balance.raw['signalHeatModel'] as Map<String, dynamic>? ?? {};
    final triangulation = signalModel['triangulation'] as Map<String, dynamic>? ?? {};
    final minHeat = (triangulation['minHeat'] as num?)?.toInt() ?? 20;
    if (state.baseStats.signalHeat >= minHeat) {
      delta += ((state.baseStats.signalHeat - minHeat) / 10).floor() + 1;
    }

    final before = state.baseStats.listenerTrace;
    final after = Clamp.stat(before + delta, 0, 100);
    state.baseStats.listenerTrace = after;

    _queueListenerThresholdEvent(state, before, after, usedRadioToday);
  }

  void _queueListenerThresholdEvent(
    GameState state,
    int before,
    int after,
    bool usedRadioToday,
  ) {
    final thresholds = [30, 60, 90];
    int? crossed;
    for (final threshold in thresholds) {
      if (before < threshold && after >= threshold) {
        crossed = threshold;
        break;
      }
    }
    if (crossed == null) return;

    final eventId =
        _listenerEventForThreshold(crossed, usedRadioToday, state.timeOfDay);
    if (eventId != null) {
      state.eventQueue.add(eventId);
    }
  }

  String? _listenerEventForThreshold(
    int threshold,
    bool usedRadioToday,
    String timeOfDay,
  ) {
    const eventMap = {
      30: {
        'base': 'listener_trace_30_base',
        'radio': 'listener_trace_30_radio',
      },
      60: {
        'radio': 'listener_trace_60_radio',
        'night': 'listener_trace_60_night',
      },
      90: {
        'base': 'listener_trace_90_base',
        'night': 'listener_trace_90_night',
      },
    };
    final options = eventMap[threshold];
    if (options == null) return null;

    if (timeOfDay == 'night' && options['night'] != null) {
      return options['night'];
    }
    if (usedRadioToday && options['radio'] != null) {
      return options['radio'];
    }
    return options['base'] ?? options['radio'] ?? options['night'];
  }

  void _applySignalHeatCooldown(GameState state) {
    final signalConfig =
        data.balance.raw['signalHeatModel']?['cooldown'] as Map<String, dynamic>? ?? {};
    final usedRadioToday = state.tempModifiers['usedRadioToday'] == true;

    final delta = usedRadioToday
        ? (signalConfig['perDayWithRadio'] as num?)?.toInt() ?? -1
        : (signalConfig['perDayNoRadio'] as num?)?.toInt() ?? -4;

    if (delta != 0) {
      state.baseStats.signalHeat = Clamp.stat(state.baseStats.signalHeat + delta, 0, 100);
    }

    state.tempModifiers.remove('usedRadioToday');
  }

  String? _selectTriangulationEvent(GameState state, String context) {
    final preferred = <Map<String, dynamic>>[];
    final preferredWeights = <double>[];
    final fallback = <Map<String, dynamic>>[];
    final fallbackWeights = <double>[];

    for (final event in data.events.values) {
      final eventId = event['id']?.toString() ?? '';
      if (eventId.isEmpty) continue;
      if (!_matchesContext(event, context)) continue;
      if (!_passesEventFilters(event, state)) continue;

      final group = event['group']?.toString().toLowerCase() ?? '';
      final isPreferred =
          group.contains('faction') || eventId.toLowerCase().contains('raider');
      final weight = _eventWeight(event, state);
      if (isPreferred) {
        preferred.add(event);
        preferredWeights.add(weight);
      } else {
        fallback.add(event);
        fallbackWeights.add(weight);
      }
    }

    Map<String, dynamic>? selected;
    if (preferred.isNotEmpty) {
      selected = _weightedPick(preferred, preferredWeights);
    }

    if (selected == null) {
      selected = eventEngine.selectEvent(state, context: context);
      if (selected != null) {
        return selected['id']?.toString();
      }
    }

    if (selected == null && fallback.isNotEmpty) {
      selected = _weightedPick(fallback, fallbackWeights);
    }

    if (selected == null) return null;
    final selectedId = selected['id'] as String;
    state.eventHistory[selectedId] = EventHistory(day: state.day, outcomeIndex: 0);
    return selectedId;
  }

  bool _isEventEligible(GameState state, String eventId) {
    final event = data.events[eventId];
    if (event == null) return false;
    if (!_matchesContext(event, 'night')) return false;
    return _passesEventFilters(event, state);
  }

  bool _matchesContext(Map<String, dynamic> event, String context) {
    final contextsRaw = event['contexts'] ?? event['context'];
    final contexts = <String>[];
    if (contextsRaw is String) {
      contexts.add(contextsRaw);
    } else if (contextsRaw is List) {
      contexts.addAll(contextsRaw.map((e) => e.toString()));
    }
    if (contexts.isEmpty) return false;
    return contexts.any((c) => c == context || context.startsWith('$c:'));
  }

  bool _passesEventFilters(Map<String, dynamic> event, GameState state) {
    final minDay = (event['minDay'] as num?)?.toInt() ?? 0;
    if (state.day < minDay) return false;

    final cooldownDays = (event['cooldownDays'] as num?)?.toInt() ?? 0;
    if (cooldownDays > 0) {
      final lastOccurrence = state.eventHistory[event['id'] as String? ?? ''];
      if (lastOccurrence != null) {
        final daysSince = state.day - lastOccurrence.day;
        if (daysSince < cooldownDays) return false;
      }
    }

    final repeatable = event['repeatable'] as bool? ?? true;
    if (!repeatable && state.eventHistory.containsKey(event['id'])) {
      return false;
    }

    final requirements = event['requirements'];
    final conditions = event['conditions'];
    if (requirements != null && !requirementEngine.check(requirements, state)) {
      return false;
    }
    if (conditions != null && !requirementEngine.check(conditions, state)) {
      return false;
    }

    return true;
  }

  double _eventWeight(Map<String, dynamic> event, GameState state) {
    double weight = (event['weight'] as num?)?.toDouble() ?? 1.0;
    final group = event['group']?.toString();
    if (group != null) {
      final mod = state.tempModifiers['eventWeightMult:$group'];
      if (mod is Map && mod['mult'] is num) {
        weight *= (mod['mult'] as num).toDouble();
      }
    }
    return weight;
  }

  Map<String, dynamic>? _weightedPick(
    List<Map<String, dynamic>> events,
    List<double> weights,
  ) {
    if (events.isEmpty) return null;
    final index = rng.weightedSelect(weights);
    if (index < 0 || index >= events.length) return null;
    return events[index];
  }

  bool _hasItem(GameState state, String itemId) {
    for (final stack in state.inventory) {
      if (stack.itemId == itemId && stack.qty > 0) return true;
    }
    return false;
  }

  /// Consume food and water
  _ConsumptionResult _consumeResources(GameState state, {String? rationPolicy}) {
    final partyConfig = data.balance.raw['party'] as Map<String, dynamic>? ?? {};
    final consumptionPerPerson =
        partyConfig['dailyConsumptionPerPerson'] as Map<String, dynamic>? ?? {};
    final rationingConfig = partyConfig['rationing'] as Map<String, dynamic>? ?? {};

    final foodPerPerson = (consumptionPerPerson['foodUnits'] as num?)?.toDouble() ?? 1.0;
    final waterPerPerson = (consumptionPerPerson['waterUnits'] as num?)?.toDouble() ?? 1.0;
    double adjustedFood = foodPerPerson;
    double adjustedWater = waterPerPerson;

    if (rationPolicy != null && rationPolicy.isNotEmpty) {
      final key = switch (rationPolicy) {
        'half' => 'halfRation',
        'halfRation' => 'halfRation',
        'strict' => 'strict',
        _ => '',
      };
      if (key.isNotEmpty) {
        final ration = rationingConfig[key] as Map<String, dynamic>? ?? {};
        adjustedFood = (ration['foodUnits'] as num?)?.toDouble() ?? adjustedFood;
        adjustedWater = (ration['waterUnits'] as num?)?.toDouble() ?? adjustedWater;
      }
    }

    final partySize = state.party.length;
    final foodNeededUnits = partySize * adjustedFood;
    final waterNeededUnits = partySize * adjustedWater;

    int foodNeeded = foodNeededUnits.ceil();
    int waterNeeded = waterNeededUnits.ceil();

    int foodConsumed = 0;
    int waterConsumed = 0;

    // Consume food
    for (final stack in state.inventory.toList()) {
      final item = data.getItem(stack.itemId);
      if (item != null && item.hasTag('food') && foodNeeded > 0) {
        final consume = Clamp.i(foodNeeded, 0, stack.qty);
        stack.qty -= consume;
        foodNeeded -= consume;
        foodConsumed += consume;
        
        if (stack.qty <= 0) {
          state.inventory.remove(stack);
        }
      }
    }

    // Consume water
    for (final stack in state.inventory.toList()) {
      final item = data.getItem(stack.itemId);
      if (item != null && item.hasTag('water') && waterNeeded > 0) {
        final consume = Clamp.i(waterNeeded, 0, stack.qty);
        stack.qty -= consume;
        waterNeeded -= consume;
        waterConsumed += consume;
        
        if (stack.qty <= 0) {
          state.inventory.remove(stack);
        }
      }
    }

    // Apply stat relief from consumption
    const hungerReducePerFood = 12;
    const thirstReducePerWater = 18;
    if (foodConsumed > 0) {
      state.playerStats.hunger =
          Clamp.stat(state.playerStats.hunger - hungerReducePerFood * foodConsumed);
    }
    if (waterConsumed > 0) {
      state.playerStats.thirst =
          Clamp.stat(state.playerStats.thirst - thirstReducePerWater * waterConsumed);
    }

    // Log shortages
    if (foodNeeded > 0) {
      state.addLog('⚠️ Thiếu $foodNeeded thức ăn.');
    }
    if (waterNeeded > 0) {
      state.addLog('⚠️ Thiếu $waterNeeded nước.');
    }

    return _ConsumptionResult(
      missingFood: foodNeeded,
      missingWater: waterNeeded,
      foodConsumed: foodConsumed,
      waterConsumed: waterConsumed,
    );
  }

  /// Apply base stat decay
  void _applyBaseDecay(GameState state) {
    final balance = data.balance;
    final baseDecay = balance.raw['baseDecay'] as Map<String, dynamic>? ?? {};
    final perDay = baseDecay['perDay'] as Map<String, dynamic>? ?? {};
    final floor = baseDecay['floor'] as Map<String, dynamic>? ?? {};
    final upgrades = baseDecay['upgrades'] as Map<String, dynamic>? ?? {};

    int noiseDelta = (perDay['noise'] as num?)?.toInt() ?? 0;
    int smellDelta = (perDay['smell'] as num?)?.toInt() ?? 0;
    int signalHeatDelta = (perDay['signalHeat'] as num?)?.toInt() ?? 0;
    double hopeDelta = (perDay['hope'] as num?)?.toDouble() ?? 0;

    for (final entry in upgrades.entries) {
      final flagId = entry.key.toString();
      if (!state.flags.contains(flagId)) continue;
      final upgrade = entry.value as Map<String, dynamic>? ?? {};
      noiseDelta += (upgrade['noiseExtraPerDay'] as num?)?.toInt() ?? 0;
      smellDelta += (upgrade['smellExtraPerDay'] as num?)?.toInt() ?? 0;
      signalHeatDelta += (upgrade['signalHeatExtraPerDay'] as num?)?.toInt() ?? 0;
      hopeDelta += (upgrade['hopeExtraPerDay'] as num?)?.toDouble() ?? 0;
    }

    final noiseFloor = (floor['noise'] as num?)?.toInt() ?? 0;
    final smellFloor = (floor['smell'] as num?)?.toInt() ?? 0;
    final signalHeatFloor = (floor['signalHeat'] as num?)?.toInt() ?? 0;
    final hopeFloor = (floor['hope'] as num?)?.toInt() ?? 0;

    state.baseStats.noise = Clamp.stat(state.baseStats.noise + noiseDelta, noiseFloor, 100);
    state.baseStats.smell = Clamp.stat(state.baseStats.smell + smellDelta, smellFloor, 100);
    state.baseStats.signalHeat =
        Clamp.stat(state.baseStats.signalHeat + signalHeatDelta, signalHeatFloor, 100);
    state.baseStats.hope =
        Clamp.stat(state.baseStats.hope + hopeDelta.round(), hopeFloor, 100);
  }

  /// Clear expired temporary modifiers
  void _clearExpiredModifiers(GameState state) {
    state.tempModifiers.removeWhere((key, value) {
      // Skip non-Map values (e.g., boolean flags like nightAttack, usedRadioToday)
      if (value is! Map) return false;
      final expiresDay = value['expiresDay'] as int? ?? 0;
      return state.day > expiresDay;
    });
  }

  // Depletion recovery handled by DepletionEngine
}

class _ConsumptionResult {
  final int missingFood;
  final int missingWater;
  final int foodConsumed;
  final int waterConsumed;

  const _ConsumptionResult({
    required this.missingFood,
    required this.missingWater,
    required this.foodConsumed,
    required this.waterConsumed,
  });
}

import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import 'npc_system.dart';
import '../engine/depletion_engine.dart';
import 'trade_system.dart';

/// System for handling daily tick (stat changes, consumption, etc.)
class DailyTickSystem {
  final GameDataRepository data;
  final NpcSystem npcSystem;
  final DepletionEngine depletionEngine;
  final TradeSystem tradeSystem;

  DailyTickSystem({
    required this.data,
    required this.npcSystem,
    required this.depletionEngine,
    required this.tradeSystem,
  });

  /// Execute daily tick
  void tick(GameState state) {
    final balance = data.balance;
    final dailyTick = balance.raw['dailyTick'] as Map<String, dynamic>? ?? {};
    final statIncrease = dailyTick['playerStatIncreasePerDay'] as Map<String, dynamic>? ?? {};

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
    final consumptionResult = _consumeResources(state);
    _applyMoraleDaily(state, dailyTick, consumptionResult);

    // Check critical stats after resource adjustments
    _checkCriticalStats(state);

    // Update party
    npcSystem.updatePartyMorale(state);
    state.tension = npcSystem.calculateTension(state);

    // Base decay
    _applyBaseDecay(state);

    _applySignalHeatCooldown(state);

    // Clear expired temp modifiers
    _clearExpiredModifiers(state);

    // Location depletion recovery
    depletionEngine.applyRecovery(state);

    // Update market state
    tradeSystem.updateMarket(state);

    // Advance day
    state.day++;
    state.timeOfDay = 'morning';

    state.addLog('☀️ Ngày ${state.day} bắt đầu.');

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

  bool _hasItem(GameState state, String itemId) {
    for (final stack in state.inventory) {
      if (stack.itemId == itemId && stack.qty > 0) return true;
    }
    return false;
  }

  /// Consume food and water
  _ConsumptionResult _consumeResources(GameState state) {
    final partyConfig = data.balance.raw['party'] as Map<String, dynamic>? ?? {};
    final consumptionPerPerson =
        partyConfig['dailyConsumptionPerPerson'] as Map<String, dynamic>? ?? {};

    final foodPerPerson = (consumptionPerPerson['foodUnits'] as num?)?.toDouble() ?? 1.0;
    final waterPerPerson = (consumptionPerPerson['waterUnits'] as num?)?.toDouble() ?? 1.0;

    final partySize = state.party.length;
    final foodNeededUnits = partySize * foodPerPerson;
    final waterNeededUnits = partySize * waterPerPerson;

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

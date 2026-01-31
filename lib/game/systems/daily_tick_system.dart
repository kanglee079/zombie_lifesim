import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import 'npc_system.dart';

/// System for handling daily tick (stat changes, consumption, etc.)
class DailyTickSystem {
  final GameDataRepository data;
  final NpcSystem npcSystem;

  DailyTickSystem({required this.data, required this.npcSystem});

  /// Execute daily tick
  void tick(GameState state) {
    final balance = data.balance;
    final dailyTick = balance.raw['dailyTick'] as Map<String, dynamic>? ?? {};

    // Get base deltas
    final hungerDelta = (dailyTick['hunger'] as num?)?.toInt() ?? -15;
    final thirstDelta = (dailyTick['thirst'] as num?)?.toInt() ?? -20;
    final fatigueDelta = (dailyTick['fatigue'] as num?)?.toInt() ?? 10;
    final stressDelta = (dailyTick['stress'] as num?)?.toInt() ?? 5;
    final infectionDecay = (dailyTick['infectionDecay'] as num?)?.toInt() ?? -1;

    // Apply player stat changes
    state.playerStats.hunger = Clamp.stat(state.playerStats.hunger + hungerDelta);
    state.playerStats.thirst = Clamp.stat(state.playerStats.thirst + thirstDelta);
    state.playerStats.fatigue = Clamp.stat(state.playerStats.fatigue + fatigueDelta);
    state.playerStats.stress = Clamp.stat(state.playerStats.stress + stressDelta);

    // Infection decay (slow healing if low)
    if (state.playerStats.infection < 20) {
      state.playerStats.infection = Clamp.infection(state.playerStats.infection + infectionDecay);
    }

    // Check critical stats
    _checkCriticalStats(state);

    // Consume food/water
    _consumeResources(state);

    // Update party
    npcSystem.updatePartyMorale(state);
    state.tension = npcSystem.calculateTension(state);

    // Base decay
    _applyBaseDecay(state);

    // Update signal heat decay
    if (state.signalHeat > 0) {
      state.signalHeat = (state.signalHeat - 5).clamp(0, 100);
    }

    // Clear expired temp modifiers
    _clearExpiredModifiers(state);

    // Location depletion recovery
    _recoverDepletion(state);

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

    // Hunger critical - take HP damage
    if (state.playerStats.hunger <= 0) {
      state.playerStats.hp = Clamp.hp(state.playerStats.hp - 10);
      state.addLog('🍽️ Đang chết đói! Mất 10 HP.');
    }

    // Thirst critical - take HP damage
    if (state.playerStats.thirst <= 0) {
      state.playerStats.hp = Clamp.hp(state.playerStats.hp - 15);
      state.addLog('💧 Đang chết khát! Mất 15 HP.');
    }

    // Fatigue critical - reduce effectiveness
    if (state.playerStats.fatigue >= 100) {
      state.addLog('😴 Quá mệt mỏi. Cần nghỉ ngơi.');
    }

    // Stress critical - morale penalty
    if (state.playerStats.stress >= 100) {
      state.addLog('😰 Căng thẳng quá độ. Tinh thần suy giảm.');
    }
  }

  /// Consume food and water
  void _consumeResources(GameState state) {
    final partySize = state.party.length;
    final consumption = npcSystem.getPartyConsumption(state);

    // Consume food
    int foodNeeded = consumption;
    for (final stack in state.inventory.toList()) {
      final item = data.getItem(stack.itemId);
      if (item != null && item.hasTag('food') && foodNeeded > 0) {
        final consume = foodNeeded.clamp(0, stack.qty);
        stack.qty -= consume;
        foodNeeded -= consume;
        
        if (stack.qty <= 0) {
          state.inventory.remove(stack);
        }
      }
    }

    // Consume water
    int waterNeeded = consumption;
    for (final stack in state.inventory.toList()) {
      final item = data.getItem(stack.itemId);
      if (item != null && item.hasTag('water') && waterNeeded > 0) {
        final consume = waterNeeded.clamp(0, stack.qty);
        stack.qty -= consume;
        waterNeeded -= consume;
        
        if (stack.qty <= 0) {
          state.inventory.remove(stack);
        }
      }
    }

    // Log shortages
    if (foodNeeded > 0) {
      state.addLog('⚠️ Thiếu $foodNeeded thức ăn.');
    }
    if (waterNeeded > 0) {
      state.addLog('⚠️ Thiếu $waterNeeded nước.');
    }
  }

  /// Apply base stat decay
  void _applyBaseDecay(GameState state) {
    final balance = data.balance;
    final baseDecay = balance.raw['baseDecay'] as Map<String, dynamic>? ?? {};

    // Defense decay
    final defenseDelta = (baseDecay['defenseDelta'] as num?)?.toInt() ?? -2;
    state.baseStats.defense = Clamp.stat(state.baseStats.defense + defenseDelta, 0, 100);

    // Power decay
    final powerDelta = (baseDecay['powerDelta'] as num?)?.toInt() ?? -1;
    state.baseStats.power = Clamp.stat(state.baseStats.power + powerDelta, 0, 100);

    // Noise natural decay handled in night system
  }

  /// Clear expired temporary modifiers
  void _clearExpiredModifiers(GameState state) {
    state.tempModifiers.removeWhere((key, value) {
      final expiresDay = value['expiresDay'] as int? ?? 0;
      return state.day > expiresDay;
    });
  }

  /// Recover location depletion over time
  void _recoverDepletion(GameState state) {
    final depSystem = data.depletionSystem;
    final recovery = depSystem['recovery'] as Map<String, dynamic>? ?? {};
    final daysBetween = (recovery['daysBetween'] as num?)?.toInt() ?? 3;
    final amount = (recovery['amount'] as num?)?.toInt() ?? 1;

    for (final entry in state.locationStates.entries) {
      final locState = entry.value;
      final daysSinceVisit = state.day - locState.lastVisitDay;
      
      if (daysSinceVisit >= daysBetween && locState.depletion > 0) {
        locState.depletion = (locState.depletion - amount).clamp(0, 10);
      }
    }
  }
}

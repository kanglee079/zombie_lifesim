import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';

/// Engine for executing game effects
class EffectEngine {
  final GameDataRepository data;
  final GameRng rng;

  EffectEngine({required this.data, required this.rng});

  /// Execute a list of effects on game state
  void executeEffects(List<dynamic> effects, GameState state) {
    for (final effect in effects) {
      if (effect is Map<String, dynamic>) {
        _executeEffect(effect, state);
      } else if (effect is String) {
        _executeStringEffect(effect, state);
      }
    }
  }

  /// Execute a single effect
  void _executeEffect(Map<String, dynamic> effect, GameState state) {
    final type = effect['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'stat':
        _executeStatEffect(effect, state);
        break;
      case 'item':
        _executeItemEffect(effect, state);
        break;
      case 'flag':
        _executeFlagEffect(effect, state);
        break;
      case 'rep':
        _executeRepEffect(effect, state);
        break;
      case 'quest':
        _executeQuestEffect(effect, state);
        break;
      case 'event':
        _executeEventEffect(effect, state);
        break;
      case 'unlock':
        _executeUnlockEffect(effect, state);
        break;
      case 'log':
        _executeLogEffect(effect, state);
        break;
      case 'gameOver':
        _executeGameOverEffect(effect, state);
        break;
      case 'random':
        _executeRandomEffect(effect, state);
        break;
      default:
        GameLogger.warn('Unknown effect type: $type');
    }
  }

  /// Execute string-format effect (shorthand)
  void _executeStringEffect(String effect, GameState state) {
    final parts = effect.split(':');
    if (parts.length < 2) return;

    final type = parts[0];
    final value = parts.sublist(1).join(':');

    switch (type) {
      case 'hp':
        final delta = int.tryParse(value) ?? 0;
        state.playerStats.hp = Clamp.hp(state.playerStats.hp + delta);
        break;
      case 'hunger':
        final delta = int.tryParse(value) ?? 0;
        state.playerStats.hunger = Clamp.stat(state.playerStats.hunger + delta);
        break;
      case 'thirst':
        final delta = int.tryParse(value) ?? 0;
        state.playerStats.thirst = Clamp.stat(state.playerStats.thirst + delta);
        break;
      case 'fatigue':
        final delta = int.tryParse(value) ?? 0;
        state.playerStats.fatigue = Clamp.stat(state.playerStats.fatigue + delta);
        break;
      case 'stress':
        final delta = int.tryParse(value) ?? 0;
        state.playerStats.stress = Clamp.stat(state.playerStats.stress + delta);
        break;
      case 'infection':
        final delta = int.tryParse(value) ?? 0;
        state.playerStats.infection = Clamp.infection(state.playerStats.infection + delta);
        break;
      case 'flag':
        state.flags.add(value);
        break;
      case 'item':
        // Format: item:itemId:qty or item:itemId
        final itemParts = value.split(':');
        final itemId = itemParts[0];
        final qty = itemParts.length > 1 ? (int.tryParse(itemParts[1]) ?? 1) : 1;
        if (qty > 0) {
          addItemToInventory(state, itemId, qty);
        } else {
          removeItemFromInventory(state, itemId, qty.abs());
        }
        break;
      case 'log':
        state.addLog(value);
        break;
    }
  }

  /// Execute stat effect
  void _executeStatEffect(Map<String, dynamic> effect, GameState state) {
    final stat = effect['stat'] as String?;
    final delta = (effect['delta'] as num?)?.toInt() ?? 0;
    final set = effect['set'] as num?;

    if (stat == null) return;

    int current = _getStatValue(stat, state);
    int newValue;

    if (set != null) {
      newValue = set.toInt();
    } else {
      newValue = current + delta;
    }

    _setStatValue(stat, newValue, state);
  }

  int _getStatValue(String stat, GameState state) {
    switch (stat) {
      case 'hp':
        return state.playerStats.hp;
      case 'hunger':
        return state.playerStats.hunger;
      case 'thirst':
        return state.playerStats.thirst;
      case 'fatigue':
        return state.playerStats.fatigue;
      case 'stress':
        return state.playerStats.stress;
      case 'infection':
        return state.playerStats.infection;
      case 'defense':
        return state.baseStats.defense;
      case 'power':
        return state.baseStats.power;
      case 'noise':
        return state.baseStats.noise;
      case 'ep':
      case 'explorationPoints':
        return state.baseStats.explorationPoints;
      default:
        return 0;
    }
  }

  void _setStatValue(String stat, int value, GameState state) {
    switch (stat) {
      case 'hp':
        state.playerStats.hp = Clamp.hp(value);
        break;
      case 'hunger':
        state.playerStats.hunger = Clamp.stat(value);
        break;
      case 'thirst':
        state.playerStats.thirst = Clamp.stat(value);
        break;
      case 'fatigue':
        state.playerStats.fatigue = Clamp.stat(value);
        break;
      case 'stress':
        state.playerStats.stress = Clamp.stat(value);
        break;
      case 'infection':
        state.playerStats.infection = Clamp.infection(value);
        break;
      case 'defense':
        state.baseStats.defense = Clamp.stat(value, 0, 100);
        break;
      case 'power':
        state.baseStats.power = Clamp.stat(value, 0, 100);
        break;
      case 'noise':
        state.baseStats.noise = Clamp.stat(value, 0, 100);
        break;
      case 'ep':
      case 'explorationPoints':
        state.baseStats.explorationPoints = value.clamp(0, 9999);
        break;
    }
  }

  /// Execute item effect
  void _executeItemEffect(Map<String, dynamic> effect, GameState state) {
    final itemId = effect['itemId'] as String?;
    final qty = (effect['qty'] as num?)?.toInt() ?? 1;
    final action = effect['action'] as String? ?? 'add';

    if (itemId == null) return;

    if (action == 'add' || qty > 0) {
      addItemToInventory(state, itemId, qty.abs());
    } else if (action == 'remove' || qty < 0) {
      removeItemFromInventory(state, itemId, qty.abs());
    }
  }

  /// Execute flag effect
  void _executeFlagEffect(Map<String, dynamic> effect, GameState state) {
    final flag = effect['flag'] as String?;
    final action = effect['action'] as String? ?? 'set';

    if (flag == null) return;

    if (action == 'set' || action == 'add') {
      state.flags.add(flag);
    } else if (action == 'remove' || action == 'unset') {
      state.flags.remove(flag);
    }
  }

  /// Execute reputation effect
  void _executeRepEffect(Map<String, dynamic> effect, GameState state) {
    final factionId = effect['faction'] as String?;
    final delta = (effect['delta'] as num?)?.toInt() ?? 0;

    if (factionId == null) return;

    final current = state.factionRep[factionId] ?? 0;
    state.factionRep[factionId] = Clamp.reputation(current + delta);
  }

  /// Execute quest effect
  void _executeQuestEffect(Map<String, dynamic> effect, GameState state) {
    final questId = effect['questId'] as String?;
    final action = effect['action'] as String? ?? 'start';
    final stage = (effect['stage'] as num?)?.toInt();

    if (questId == null) return;

    switch (action) {
      case 'start':
        if (!state.quests.containsKey(questId)) {
          state.quests[questId] = QuestState(stage: 0, startDay: state.day);
        }
        break;
      case 'advance':
        final questState = state.quests[questId];
        if (questState != null) {
          questState.stage++;
        }
        break;
      case 'set':
        if (stage != null) {
          final questState = state.quests[questId];
          if (questState != null) {
            questState.stage = stage;
          } else {
            state.quests[questId] = QuestState(stage: stage, startDay: state.day);
          }
        }
        break;
    }
  }

  /// Execute event trigger effect
  void _executeEventEffect(Map<String, dynamic> effect, GameState state) {
    final eventId = effect['eventId'] as String?;
    if (eventId == null) return;

    // Queue event for next processing
    state.eventQueue.add(eventId);
  }

  /// Execute unlock effect
  void _executeUnlockEffect(Map<String, dynamic> effect, GameState state) {
    final target = effect['target'] as String?;
    final id = effect['id'] as String?;

    if (target == null || id == null) return;

    switch (target) {
      case 'district':
        state.districtStates[id] = DistrictState(unlocked: true);
        break;
      case 'recipe':
        state.flags.add('recipe_$id');
        break;
    }
  }

  /// Execute log effect
  void _executeLogEffect(Map<String, dynamic> effect, GameState state) {
    final text = effect['text'] as String?;
    if (text != null) {
      state.addLog(text);
    }
  }

  /// Execute game over effect
  void _executeGameOverEffect(Map<String, dynamic> effect, GameState state) {
    state.gameOver = true;
    state.endingType = effect['ending'] as String? ?? 'unknown';
  }

  /// Execute random effect (pick one from list)
  void _executeRandomEffect(Map<String, dynamic> effect, GameState state) {
    final options = effect['options'] as List<dynamic>?;
    if (options == null || options.isEmpty) return;

    final selected = options[rng.nextInt(options.length)];
    if (selected is Map<String, dynamic>) {
      _executeEffect(selected, state);
    } else if (selected is String) {
      _executeStringEffect(selected, state);
    }
  }

  /// Add item to inventory
  void addItemToInventory(GameState state, String itemId, int qty) {
    final item = data.getItem(itemId);
    if (item == null) {
      GameLogger.warn('Unknown item: $itemId');
      return;
    }

    // Find existing stack
    for (final stack in state.inventory) {
      if (stack.itemId == itemId) {
        if (item.stackable) {
          final maxStack = item.maxStack;
          final canAdd = maxStack - stack.qty;
          final toAdd = qty.clamp(0, canAdd);
          stack.qty += toAdd;
          qty -= toAdd;
        }
        if (qty <= 0) return;
      }
    }

    // Create new stack(s)
    while (qty > 0) {
      final maxStack = item.stackable ? item.maxStack : 1;
      final stackQty = qty.clamp(1, maxStack);
      state.inventory.add(InventoryItem(itemId: itemId, qty: stackQty));
      qty -= stackQty;
    }

    GameLogger.game('Added $qty x $itemId to inventory');
  }

  /// Remove item from inventory
  void removeItemFromInventory(GameState state, String itemId, int qty) {
    for (final stack in state.inventory.toList()) {
      if (stack.itemId == itemId) {
        final toRemove = qty.clamp(0, stack.qty);
        stack.qty -= toRemove;
        qty -= toRemove;

        if (stack.qty <= 0) {
          state.inventory.remove(stack);
        }

        if (qty <= 0) return;
      }
    }

    GameLogger.game('Removed items from inventory, remaining request: $qty');
  }

  /// Use an item (consume and apply effects)
  void useItem(GameState state, String itemId) {
    final item = data.getItem(itemId);
    if (item == null) return;

    if (item.use == null) {
      state.addLog('${item.name} không thể sử dụng.');
      return;
    }

    // Check if player has item
    bool hasItem = false;
    for (final stack in state.inventory) {
      if (stack.itemId == itemId && stack.qty > 0) {
        hasItem = true;
        break;
      }
    }

    if (!hasItem) {
      state.addLog('Bạn không có ${item.name}.');
      return;
    }

    // Remove one from inventory
    removeItemFromInventory(state, itemId, 1);

    // Execute use effects (effects array is inside the use object)
    final effects = item.use!['effects'];
    if (effects is List) {
      executeEffects(effects, state);
    }

    // Log message from item use
    final logMsg = item.useLog ?? 'Sử dụng ${item.name}.';
    state.addLog(logMsg);

    GameLogger.game('Used item: $itemId');
  }
}

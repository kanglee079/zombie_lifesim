import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import '../systems/npc_system.dart';
import 'loot_engine.dart';

/// Engine for executing game effects
class EffectEngine {
  final GameDataRepository data;
  final GameRng rng;
  final LootEngine? lootEngine;
  final NpcSystem? npcSystem;

  EffectEngine({
    required this.data,
    required this.rng,
    this.lootEngine,
    this.npcSystem,
  });

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
      case 'base':
        _executeBaseEffect(effect, state);
        break;
      case 'item':
        _executeItemEffect(effect, state);
        break;
      case 'item_add':
        _executeItemDelta(effect, state, add: true);
        break;
      case 'item_remove':
        _executeItemDelta(effect, state, add: false);
        break;
      case 'items_add':
        _executeItemsDelta(effect, state, add: true);
        break;
      case 'items_remove':
        _executeItemsDelta(effect, state, add: false);
        break;
      case 'flag':
        _executeFlagEffect(effect, state);
        break;
      case 'flag_set':
        _executeFlagToggle(effect, state, set: true);
        break;
      case 'flag_clear':
        _executeFlagToggle(effect, state, set: false);
        break;
      case 'rep':
        _executeRepEffect(effect, state);
        break;
      case 'rep_delta':
        _executeRepDelta(effect, state);
        break;
      case 'quest':
        _executeQuestEffect(effect, state);
        break;
      case 'quest_set_stage':
      case 'quest_stage':
        _executeQuestStageEffect(effect, state);
        break;
      case 'event':
        _executeEventEffect(effect, state);
        break;
      case 'event_immediate':
        _executeImmediateEvent(effect, state);
        break;
      case 'unlock':
        _executeUnlockEffect(effect, state);
        break;
      case 'unlock_district':
        _executeUnlockDistrict(effect, state);
        break;
      case 'log':
        _executeLogEffect(effect, state);
        break;
      case 'gameOver':
      case 'game_end':
        _executeGameOverEffect(effect, state);
        break;
      case 'random':
        _executeRandomEffect(effect, state);
        break;
      case 'loot_table':
        _executeLootTableEffect(effect, state);
        break;
      case 'party_add':
        _executePartyAdd(effect, state);
        break;
      case 'party_remove_random':
        _executePartyRemoveRandom(effect, state);
        break;
      case 'party_skill_xp':
        _executePartySkillXp(effect, state);
        break;
      case 'items_remove_tag':
        _executeItemsRemoveTag(effect, state);
        break;
      case 'open_craft':
      case 'open_scavenge':
      case 'open_trade':
        _executeOpenAction(effect, state);
        break;
      case 'unlock_location_shortcut':
        _executeUnlockLocationShortcut(effect, state);
        break;
      case 'eventWeightMultTemp':
        _executeEventWeightMultTemp(effect, state);
        break;
      case 'tension_delta':
        _executeTensionDelta(effect, state);
        break;
      case 'countdown_set':
        _executeCountdownSet(effect, state);
        break;
      case 'countdown_add':
        _executeCountdownAdd(effect, state);
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
    final target = effect['target']?.toString() ??
        (effect['stat'] != null ? 'player.${effect['stat']}' : null);
    final delta = (effect['delta'] as num?)?.toInt() ?? 0;
    final set = effect['set'] as num?;

    if (target == null) return;

    int current = _getTargetValue(target, state);
    int newValue;

    if (set != null) {
      newValue = set.toInt();
    } else {
      newValue = current + delta;
    }

    _setTargetValue(target, newValue, state);
  }

  int _getTargetValue(String target, GameState state) {
    if (target.startsWith('player.')) {
      final key = target.substring(7);
      switch (key) {
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
        case 'morale':
          return state.playerStats.morale;
        default:
          return 0;
      }
    }

    if (target.startsWith('base.')) {
      final key = target.substring(5);
      switch (key) {
        case 'defense':
          return state.baseStats.defense;
        case 'power':
          return state.baseStats.power;
        case 'noise':
          return state.baseStats.noise;
        case 'smell':
          return state.baseStats.smell;
        case 'hope':
          return state.baseStats.hope;
        case 'signalHeat':
          return state.baseStats.signalHeat;
        case 'listenerTrace':
          return state.baseStats.listenerTrace;
        case 'ep':
        case 'explorationPoints':
          return state.baseStats.explorationPoints;
        default:
          return 0;
      }
    }

    // Legacy fallback
    switch (target) {
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
      case 'morale':
        return state.playerStats.morale;
      case 'defense':
        return state.baseStats.defense;
      case 'power':
        return state.baseStats.power;
      case 'noise':
        return state.baseStats.noise;
      case 'smell':
        return state.baseStats.smell;
      case 'hope':
        return state.baseStats.hope;
      case 'signalHeat':
        return state.baseStats.signalHeat;
      case 'listenerTrace':
        return state.baseStats.listenerTrace;
      case 'ep':
      case 'explorationPoints':
        return state.baseStats.explorationPoints;
      default:
        return 0;
    }
  }

  void _setTargetValue(String target, int value, GameState state) {
    if (target.startsWith('player.')) {
      final key = target.substring(7);
      _setTargetValue(key, value, state);
      return;
    }

    if (target.startsWith('base.')) {
      final key = target.substring(5);
      _setTargetValue(key, value, state);
      return;
    }

    switch (target) {
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
      case 'morale':
        state.playerStats.morale = Clamp.morale(value);
        break;
      case 'defense':
        state.baseStats.defense = Clamp.stat(value);
        break;
      case 'power':
        state.baseStats.power = Clamp.stat(value);
        break;
      case 'noise':
        state.baseStats.noise = Clamp.stat(value);
        break;
      case 'smell':
        state.baseStats.smell = Clamp.stat(value);
        break;
      case 'hope':
        state.baseStats.hope = Clamp.stat(value);
        break;
      case 'signalHeat':
        state.baseStats.signalHeat = Clamp.stat(value);
        break;
      case 'listenerTrace':
        state.baseStats.listenerTrace = Clamp.stat(value);
        break;
      case 'ep':
      case 'explorationPoints':
        state.baseStats.explorationPoints = Clamp.i(value, 0, 9999);
        break;
    }
  }

  void _executeBaseEffect(Map<String, dynamic> effect, GameState state) {
    final target = effect['target']?.toString() ??
        (effect['stat'] != null ? 'base.${effect['stat']}' : null);
    if (target == null) return;
    _executeStatEffect({...effect, 'target': target}, state);
  }

  /// Execute item effect
  void _executeItemEffect(Map<String, dynamic> effect, GameState state) {
    final itemId = effect['itemId'] as String? ?? effect['id'] as String?;
    final qty = (effect['qty'] as num?)?.toInt() ?? 1;
    final action = effect['action'] as String? ?? 'add';

    if (itemId == null) return;

    if (action == 'add' || qty > 0) {
      addItemToInventory(state, itemId, qty.abs());
    } else if (action == 'remove' || qty < 0) {
      removeItemFromInventory(state, itemId, qty.abs());
    }
  }

  void _executeItemDelta(Map<String, dynamic> effect, GameState state, {required bool add}) {
    final itemId = effect['id'] as String? ?? effect['itemId'] as String?;
    final qty = (effect['qty'] as num?)?.toInt() ??
        (effect['count'] as num?)?.toInt() ??
        1;
    if (itemId == null) return;
    if (add) {
      addItemToInventory(state, itemId, qty);
    } else {
      removeItemFromInventory(state, itemId, qty);
    }
  }

  void _executeItemsDelta(Map<String, dynamic> effect, GameState state, {required bool add}) {
    final items = effect['items'] as List<dynamic>?;
    if (items == null) return;
    for (final item in items) {
      if (item is Map) {
        final itemId = item['id']?.toString() ?? item['itemId']?.toString();
        final qty = (item['qty'] as num?)?.toInt() ??
            (item['count'] as num?)?.toInt() ??
            1;
        if (itemId == null) continue;
        if (add) {
          addItemToInventory(state, itemId, qty);
        } else {
          removeItemFromInventory(state, itemId, qty);
        }
      }
    }
  }

  /// Execute flag effect
  void _executeFlagEffect(Map<String, dynamic> effect, GameState state) {
    final flag = effect['flag'] as String? ?? effect['id'] as String?;
    final action = effect['action'] as String? ?? 'set';

    if (flag == null) return;

    if (action == 'set' || action == 'add') {
      state.flags.add(flag);
    } else if (action == 'remove' || action == 'unset') {
      state.flags.remove(flag);
    }
  }

  void _executeFlagToggle(Map<String, dynamic> effect, GameState state, {required bool set}) {
    final flag = effect['id']?.toString() ?? effect['flag']?.toString();
    if (flag == null) return;
    if (set) {
      state.flags.add(flag);
    } else {
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

  void _executeRepDelta(Map<String, dynamic> effect, GameState state) {
    final factionId = effect['factionId']?.toString() ?? effect['faction']?.toString();
    final delta = (effect['delta'] as num?)?.toInt() ?? 0;
    if (factionId == null) return;
    final current = state.factionRep[factionId] ?? 0;
    state.factionRep[factionId] = Clamp.reputation(current + delta);
  }

  /// Execute quest effect
  void _executeQuestEffect(Map<String, dynamic> effect, GameState state) {
    final questId = effect['questId'] as String? ?? effect['id'] as String?;
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

  void _executeQuestStageEffect(Map<String, dynamic> effect, GameState state) {
    final questId = effect['questId']?.toString() ?? effect['id']?.toString();
    final stage = (effect['stage'] as num?)?.toInt();
    if (questId == null || stage == null) return;
    final questState = state.quests[questId];
    if (questState != null) {
      questState.stage = stage;
    } else {
      state.quests[questId] = QuestState(stage: stage, startDay: state.day);
    }
  }

  /// Execute event trigger effect
  void _executeEventEffect(Map<String, dynamic> effect, GameState state) {
    final eventId = effect['eventId'] as String? ?? effect['id'] as String?;
    if (eventId == null) return;

    // Queue event for next processing
    state.eventQueue.add(eventId);
  }

  void _executeImmediateEvent(Map<String, dynamic> effect, GameState state) {
    final eventId = effect['id']?.toString() ?? effect['eventId']?.toString();
    if (eventId == null) return;
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

  void _executeUnlockDistrict(Map<String, dynamic> effect, GameState state) {
    final districtId = effect['districtId']?.toString() ?? effect['id']?.toString();
    if (districtId == null) return;
    state.districtStates[districtId] = DistrictState(unlocked: true);
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
    final endingId =
        effect['endingId']?.toString() ?? effect['ending']?.toString() ?? 'unknown';
    state.endingType = endingId;
    state.endingId = endingId;
    state.endingGrade = effect['grade']?.toString();
    final summaryRaw = effect['summary'];
    if (summaryRaw is List) {
      state.endingSummary = summaryRaw.map((e) => e.toString()).toList();
    } else if (summaryRaw is String) {
      state.endingSummary = [summaryRaw];
    }
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

  void _executeLootTableEffect(Map<String, dynamic> effect, GameState state) {
    final table = effect['table']?.toString();
    if (table == null || lootEngine == null) return;
    final rolls = (effect['rolls'] as num?)?.toInt() ?? 1;
    final loot = lootEngine!.rollLoot(table, rolls: rolls);
    for (final entry in loot.entries) {
      addItemToInventory(state, entry.key, entry.value);
    }
  }

  void _executePartyAdd(Map<String, dynamic> effect, GameState state) {
    final count = (effect['count'] as num?)?.toInt() ?? 1;
    if (npcSystem == null) return;
    final templates = (effect['templates'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    for (int i = 0; i < count; i++) {
      final npc = npcSystem!.generateNpc(
        templateId: templates.isNotEmpty ? templates[i % templates.length] : null,
      );
      state.party.add(npc);
    }
  }

  void _executePartyRemoveRandom(Map<String, dynamic> effect, GameState state) {
    final count = (effect['count'] as num?)?.toInt() ?? 1;
    final candidates = state.party.where((p) => !p.isPlayer).toList();
    if (candidates.isEmpty) return;

    for (int i = 0; i < count && candidates.isNotEmpty; i++) {
      final index = rng.nextInt(candidates.length);
      final member = candidates.removeAt(index);
      state.party.removeWhere((p) => p.id == member.id);
    }
  }

  void _executePartySkillXp(Map<String, dynamic> effect, GameState state) {
    final skill = effect['skill']?.toString();
    final xp = (effect['xp'] as num?)?.toInt() ?? 1;
    if (skill == null) return;
    final current = state.playerSkills.getByName(skill);
    state.playerSkills.setByName(skill, current + xp);
  }

  void _executeItemsRemoveTag(Map<String, dynamic> effect, GameState state) {
    final tag = effect['tag']?.toString();
    final qty = (effect['qty'] as num?)?.toInt() ?? 1;
    if (tag == null || qty <= 0) return;

    int remaining = qty;
    for (final stack in state.inventory.toList()) {
      final item = data.getItem(stack.itemId);
      if (item == null || !item.tags.contains(tag)) continue;

      final removeQty = remaining < stack.qty ? remaining : stack.qty;
      stack.qty -= removeQty;
      remaining -= removeQty;

      if (stack.qty <= 0) {
        state.inventory.remove(stack);
      }

      if (remaining <= 0) break;
    }
  }

  void _executeOpenAction(Map<String, dynamic> effect, GameState state) {
    final type = effect['type']?.toString() ?? 'open';
    final message = switch (type) {
      'open_craft' => '📦 Bạn có thể mở chế tạo.',
      'open_scavenge' => '🧭 Bạn có thể mở khu nhặt đồ.',
      'open_trade' => '💱 Bạn có thể giao dịch với thương nhân.',
      _ => '📌 Có hành động mới.',
    };
    state.addLog(message);
  }

  void _executeUnlockLocationShortcut(Map<String, dynamic> effect, GameState state) {
    state.flags.add('location_shortcut_unlocked');
  }

  void _executeEventWeightMultTemp(Map<String, dynamic> effect, GameState state) {
    final group = effect['group']?.toString();
    final mult = (effect['mult'] as num?)?.toDouble() ??
        (effect['value'] as num?)?.toDouble() ??
        1.0;
    if (group == null) return;
    state.tempModifiers['eventWeightMult:$group'] = {
      'mult': mult,
      'expiresDay': state.day + 2,
    };
  }

  void _executeTensionDelta(Map<String, dynamic> effect, GameState state) {
    final delta = (effect['delta'] as num?)?.toInt() ?? 0;
    state.tension = Clamp.tension(state.tension + delta);
  }

  void _executeCountdownSet(Map<String, dynamic> effect, GameState state) {
    final id = effect['id']?.toString() ?? effect['countdownId']?.toString();
    if (id == null || id.isEmpty) return;
    final days = (effect['days'] as num?)?.toInt() ??
        (effect['value'] as num?)?.toInt() ??
        0;
    state.countdowns[id] = days < 0 ? 0 : days;
    final onExpire = effect['onExpireEventId']?.toString() ??
        effect['eventId']?.toString();
    if (onExpire != null && onExpire.isNotEmpty) {
      state.countdownEvents[id] = onExpire;
    }
  }

  void _executeCountdownAdd(Map<String, dynamic> effect, GameState state) {
    final id = effect['id']?.toString() ?? effect['countdownId']?.toString();
    if (id == null || id.isEmpty) return;
    final delta = (effect['delta'] as num?)?.toInt() ??
        (effect['days'] as num?)?.toInt() ??
        0;
    final current = state.countdowns[id] ?? 0;
    final next = current + delta;
    state.countdowns[id] = next < 0 ? 0 : next;
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
          final toAdd = Clamp.i(qty, 0, canAdd);
          stack.qty += toAdd;
          qty -= toAdd;
        }
        if (qty <= 0) return;
      }
    }

    // Create new stack(s)
    while (qty > 0) {
      final maxStack = item.stackable ? item.maxStack : 1;
      final stackQty = Clamp.i(qty, 1, maxStack);
      state.inventory.add(InventoryItem(itemId: itemId, qty: stackQty));
      qty -= stackQty;
    }

    GameLogger.game('Added $qty x $itemId to inventory');
  }

  /// Remove item from inventory
  void removeItemFromInventory(GameState state, String itemId, int qty) {
    for (final stack in state.inventory.toList()) {
      if (stack.itemId == itemId) {
        final toRemove = Clamp.i(qty, 0, stack.qty);
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

import '../../core/logger.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';

/// Engine for evaluating requirements
class RequirementEngine {
  final GameDataRepository data;

  RequirementEngine({required this.data});

  /// Check if requirements are met
  bool check(dynamic requirements, GameState state) {
    if (requirements == null) return true;

    if (requirements is List) {
      // All requirements must be met (AND)
      return requirements.every((req) => _checkSingle(req, state));
    } else if (requirements is Map<String, dynamic>) {
      return _checkDictRules(requirements, state);
    } else if (requirements is String) {
      return _checkStringRequirement(requirements, state);
    }

    return true;
  }

  /// Check any of requirements (OR)
  bool checkAny(List<dynamic> requirements, GameState state) {
    if (requirements.isEmpty) return true;
    return requirements.any((req) => _checkSingle(req, state));
  }

  /// Check a single requirement
  bool _checkSingle(dynamic requirement, GameState state) {
    if (requirement is String) {
      return _checkStringRequirement(requirement, state);
    } else if (requirement is Map<String, dynamic>) {
      return _checkDictRules(requirement, state);
    }
    return true;
  }

  /// Check string-format requirement
  bool _checkStringRequirement(String req, GameState state) {
    // Parse format: "type:condition"
    final colonIndex = req.indexOf(':');
    if (colonIndex == -1) {
      // Simple flag check
      return state.flags.contains(req);
    }

    final type = req.substring(0, colonIndex);
    final condition = req.substring(colonIndex + 1);

    switch (type) {
      case 'flag':
        return state.flags.contains(condition);
      case '!flag':
        return !state.flags.contains(condition);
      case 'day':
        return _checkNumericCondition(state.day, condition);
      case 'hp':
        return _checkNumericCondition(state.playerStats.hp, condition);
      case 'hunger':
        return _checkNumericCondition(state.playerStats.hunger, condition);
      case 'thirst':
        return _checkNumericCondition(state.playerStats.thirst, condition);
      case 'fatigue':
        return _checkNumericCondition(state.playerStats.fatigue, condition);
      case 'stress':
        return _checkNumericCondition(state.playerStats.stress, condition);
      case 'infection':
        return _checkNumericCondition(state.playerStats.infection, condition);
      case 'item':
        return _checkItemRequirement(condition, state);
      case 'quest':
        return _checkQuestRequirement(condition, state);
      case 'rep':
        return _checkRepRequirement(condition, state);
      case 'skill':
        return _checkSkillRequirement(condition, state);
      case 'party':
        return _checkPartyRequirement(condition, state);
      case 'time':
        return state.timeOfDay == condition;
      default:
        GameLogger.warn('Unknown requirement type: $type');
        return true;
    }
  }

  /// Check dict-format requirements
  bool _checkDictRules(Map<String, dynamic> rules, GameState state) {
    // Handle "any" array (OR)
    final anyRules = rules['any'] as List<dynamic>?;
    if (anyRules != null && anyRules.isNotEmpty) {
      if (!checkAny(anyRules, state)) {
        return false;
      }
    }

    // Handle "all" array (AND)
    final allRules = rules['all'] as List<dynamic>?;
    if (allRules != null) {
      if (!allRules.every((r) => _checkSingle(r, state))) {
        return false;
      }
    }

    // Handle individual stat checks
    for (final entry in rules.entries) {
      if (entry.key == 'any' || entry.key == 'all') continue;

      if (!_checkStatRule(entry.key, entry.value, state)) {
        return false;
      }
    }

    return true;
  }

  /// Check stat-based rule
  bool _checkStatRule(String stat, dynamic value, GameState state) {
    int current;

    switch (stat) {
      case 'day':
        current = state.day;
        break;
      case 'hp':
        current = state.playerStats.hp;
        break;
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
      case 'defense':
        current = state.baseStats.defense;
        break;
      case 'power':
        current = state.baseStats.power;
        break;
      case 'noise':
        current = state.baseStats.noise;
        break;
      case 'ep':
      case 'explorationPoints':
        current = state.baseStats.explorationPoints;
        break;
      case 'partySize':
        current = state.party.length;
        break;
      case 'tension':
        current = state.tension;
        break;
      default:
        return true;
    }

    if (value is num) {
      return current >= value.toInt();
    } else if (value is Map<String, dynamic>) {
      final min = (value['min'] as num?)?.toInt();
      final max = (value['max'] as num?)?.toInt();
      final eq = (value['eq'] as num?)?.toInt();

      if (min != null && current < min) return false;
      if (max != null && current > max) return false;
      if (eq != null && current != eq) return false;

      return true;
    } else if (value is String) {
      return _checkNumericCondition(current, value);
    }

    return true;
  }

  /// Check numeric condition string (>=5, <10, ==3, etc.)
  bool _checkNumericCondition(int current, String condition) {
    final cleaned = condition.trim();

    if (cleaned.startsWith('>=')) {
      final target = int.tryParse(cleaned.substring(2).trim()) ?? 0;
      return current >= target;
    } else if (cleaned.startsWith('<=')) {
      final target = int.tryParse(cleaned.substring(2).trim()) ?? 0;
      return current <= target;
    } else if (cleaned.startsWith('>')) {
      final target = int.tryParse(cleaned.substring(1).trim()) ?? 0;
      return current > target;
    } else if (cleaned.startsWith('<')) {
      final target = int.tryParse(cleaned.substring(1).trim()) ?? 0;
      return current < target;
    } else if (cleaned.startsWith('==') || cleaned.startsWith('=')) {
      final startIdx = cleaned.startsWith('==') ? 2 : 1;
      final target = int.tryParse(cleaned.substring(startIdx).trim()) ?? 0;
      return current == target;
    } else if (cleaned.startsWith('!=')) {
      final target = int.tryParse(cleaned.substring(2).trim()) ?? 0;
      return current != target;
    } else {
      // Just a number - treat as minimum
      final target = int.tryParse(cleaned) ?? 0;
      return current >= target;
    }
  }

  /// Check item requirement (has item)
  bool _checkItemRequirement(String condition, GameState state) {
    // Format: itemId or itemId:qty
    final parts = condition.split(':');
    final itemId = parts[0];
    final reqQty = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;

    int totalQty = 0;
    for (final stack in state.inventory) {
      if (stack.itemId == itemId) {
        totalQty += stack.qty;
      }
    }

    return totalQty >= reqQty;
  }

  /// Check quest requirement
  bool _checkQuestRequirement(String condition, GameState state) {
    // Format: questId or questId:stage
    final parts = condition.split(':');
    final questId = parts[0];

    final questState = state.quests[questId];
    if (questState == null) return false;

    if (parts.length > 1) {
      final reqStage = int.tryParse(parts[1]) ?? 0;
      return questState.stage >= reqStage;
    }

    return true; // Quest exists
  }

  /// Check reputation requirement
  bool _checkRepRequirement(String condition, GameState state) {
    // Format: factionId:value
    final parts = condition.split(':');
    if (parts.length < 2) return true;

    final factionId = parts[0];
    final reqRep = int.tryParse(parts[1]) ?? 0;
    final currentRep = state.factionRep[factionId] ?? 0;

    return currentRep >= reqRep;
  }

  /// Check skill requirement
  bool _checkSkillRequirement(String condition, GameState state) {
    // Format: skillName:level
    final parts = condition.split(':');
    if (parts.length < 2) return true;

    final skillName = parts[0];
    final reqLevel = int.tryParse(parts[1]) ?? 0;
    final currentLevel = state.playerSkills.getByName(skillName);

    return currentLevel >= reqLevel;
  }

  /// Check party requirement
  bool _checkPartyRequirement(String condition, GameState state) {
    // Format: size:value or trait:traitId
    final parts = condition.split(':');
    if (parts.length < 2) return true;

    final type = parts[0];
    final value = parts[1];

    switch (type) {
      case 'size':
        final reqSize = int.tryParse(value) ?? 0;
        return state.party.length >= reqSize;
      case 'trait':
        // Check if any party member has trait
        return state.party.any((m) => m.traits.contains(value));
      case 'role':
        // Check if any party member has role
        return state.party.any((m) => m.role == value);
      default:
        return true;
    }
  }
}

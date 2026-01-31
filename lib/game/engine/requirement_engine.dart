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
    } else if (requirements is Map) {
      return _checkDictRules(Map<String, dynamic>.from(requirements), state);
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
    final parser = _ExpressionParser(req, state, this);
    return parser.evaluate();
  }

  /// Check dict-format requirements
  bool _checkDictRules(Map<String, dynamic> rules, GameState state) {
    if (rules.isEmpty) return true;

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

    // Flags rules
    final flagsAny = rules['flagsAny'] as List<dynamic>?;
    if (flagsAny != null && flagsAny.isNotEmpty) {
      final anyMet = flagsAny.any((f) => state.flags.contains(f.toString()));
      if (!anyMet) return false;
    }

    final flagsAll = rules['flagsAll'] as List<dynamic>?;
    if (flagsAll != null && flagsAll.isNotEmpty) {
      final allMet = flagsAll.every((f) => state.flags.contains(f.toString()));
      if (!allMet) return false;
    }

    final flagsNone = rules['flagsNone'] as List<dynamic>?;
    if (flagsNone != null && flagsNone.isNotEmpty) {
      final noneMet = flagsNone.every((f) => !state.flags.contains(f.toString()));
      if (!noneMet) return false;
    }

    // Item rules
    final items = rules['items'] as List<dynamic>?;
    if (items != null) {
      for (final item in items) {
        if (item is Map) {
          final itemId = item['id']?.toString();
          final qty = (item['qty'] as num?)?.toInt() ?? 1;
          if (itemId == null || !_hasItemQty(state, itemId, qty)) {
            return false;
          }
        }
      }
    }

    final itemsAll = rules['itemsAll'] as List<dynamic>?;
    if (itemsAll != null) {
      for (final item in itemsAll) {
        if (item is Map) {
          final itemId = item['id']?.toString();
          final qty = (item['qty'] as num?)?.toInt() ?? 1;
          if (itemId == null || !_hasItemQty(state, itemId, qty)) {
            return false;
          }
        }
      }
    }

    final itemsAny = rules['itemsAny'] as List<dynamic>?;
    if (itemsAny != null && itemsAny.isNotEmpty) {
      bool any = false;
      for (final item in itemsAny) {
        if (item is Map) {
          final itemId = item['id']?.toString();
          final qty = (item['qty'] as num?)?.toInt() ?? 1;
          if (itemId != null && _hasItemQty(state, itemId, qty)) {
            any = true;
            break;
          }
        }
      }
      if (!any) return false;
    }

    // Player/base min stats
    final playerMin = rules['playerMin'] as Map?;
    if (playerMin != null) {
      for (final entry in playerMin.entries) {
        final rawKey = entry.key.toString();
        final key = rawKey.startsWith('player.') ? rawKey : 'player.$rawKey';
        final min = (entry.value as num?)?.toInt();
        if (min == null) continue;
        final current = _getNumericValueByPath(key, state);
        if (current == null || current < min) return false;
      }
    }

    final baseMin = rules['baseMin'] as Map?;
    if (baseMin != null) {
      for (final entry in baseMin.entries) {
        final rawKey = entry.key.toString();
        final key = rawKey.startsWith('base.') ? rawKey : 'base.$rawKey';
        final min = (entry.value as num?)?.toInt();
        if (min == null) continue;
        final current = _getNumericValueByPath(key, state);
        if (current == null || current < min) return false;
      }
    }

    final questMinStage = rules['questMinStage'] as Map?;
    if (questMinStage != null) {
      for (final entry in questMinStage.entries) {
        final questId = entry.key.toString();
        final minStage = (entry.value as num?)?.toInt() ?? 0;
        final questState = state.quests[questId];
        if (questState == null || questState.stage < minStage) {
          return false;
        }
      }
    }

    // Handle individual stat checks (legacy)
    for (final entry in rules.entries) {
      if (entry.key == 'any' ||
          entry.key == 'all' ||
          entry.key == 'flagsAny' ||
          entry.key == 'flagsAll' ||
          entry.key == 'flagsNone' ||
          entry.key == 'items' ||
          entry.key == 'playerMin' ||
          entry.key == 'baseMin' ||
          entry.key == 'questMinStage' ||
          entry.key == 'itemsAll' ||
          entry.key == 'itemsAny') {
        continue;
      }

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
      case 'morale':
        current = state.playerStats.morale;
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
      case 'smell':
        current = state.baseStats.smell;
        break;
      case 'hope':
        current = state.baseStats.hope;
        break;
      case 'signalHeat':
        current = state.baseStats.signalHeat;
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

  bool _hasItemQty(GameState state, String itemId, int qty) {
    return _getItemQty(state, itemId) >= qty;
  }

  int _getItemQty(GameState state, String itemId) {
    int totalQty = 0;
    for (final stack in state.inventory) {
      if (stack.itemId == itemId) {
        totalQty += stack.qty;
      }
    }
    return totalQty;
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

  int? _getNumericValueByPath(String path, GameState state) {
    if (path == 'day') return state.day;
    if (path == 'tension') return state.tension;
    if (path == 'party.size' || path == 'partySize') return state.party.length;
    if (path == 'party.tension') return state.tension;
    if (path == 'avgDistrictDepletion') return _getAvgDistrictDepletion(state);

    if (path.startsWith('player.')) {
      final key = path.substring(7);
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
          return null;
      }
    }

    if (path.startsWith('base.')) {
      final key = path.substring(5);
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
        case 'explorationPoints':
        case 'ep':
          return state.baseStats.explorationPoints;
        default:
          return null;
      }
    }

    return null;
  }

  int _getAvgDistrictDepletion(GameState state) {
    int total = 0;
    int count = 0;

    // Prefer current scavenge district if available
    if (state.scavengeSession != null) {
      final locationId = state.scavengeSession!.locationId;
      for (final district in data.districts.values) {
        if (!district.locationIds.contains(locationId)) continue;
        for (final locId in district.locationIds) {
          final loc = data.getLocation(locId);
          if (loc == null) continue;
          final locState = state.locationStates[locId];
          final depletion = locState?.depletion ?? loc.depletionStart;
          total += depletion;
          count += 1;
        }
        break;
      }
    }

    if (count == 0) {
      for (final district in data.districts.values) {
        final stateInfo = state.districtStates[district.id];
        final unlocked = district.startUnlocked || (stateInfo?.unlocked ?? false);
        if (!unlocked) continue;
        for (final locationId in district.locationIds) {
          final loc = data.getLocation(locationId);
          if (loc == null) continue;
          final locState = state.locationStates[locationId];
          final depletion = locState?.depletion ?? loc.depletionStart;
          total += depletion;
          count += 1;
        }
      }
    }
    if (count == 0) return 0;
    return (total / count).round();
  }

  bool _canCraftRecipe(String recipeId, GameState state) {
    final recipe = data.getRecipe(recipeId);
    if (recipe == null) return false;

    for (final tool in recipe.requiresTools) {
      if (!_hasToolRequirement(state, tool)) {
        return false;
      }
    }

    for (final flag in recipe.requiresFlags) {
      if (!state.flags.contains(flag)) {
        return false;
      }
    }

    for (final input in recipe.inputs) {
      if (!_hasItemQty(state, input.itemId, input.qty)) {
        return false;
      }
    }

    return true;
  }

  bool _hasToolRequirement(GameState state, String requirement) {
    if (!requirement.startsWith('tool:')) {
      return _getItemQty(state, requirement) > 0;
    }

    final toolTag = requirement.substring(5);
    for (final stack in state.inventory) {
      if (stack.qty <= 0) continue;
      final item = data.getItem(stack.itemId);
      if (item == null) continue;
      if (item.tags.contains(toolTag)) {
        return true;
      }
    }

    return false;
  }
}

class _ExpressionParser {
  final List<String> _tokens;
  int _index = 0;
  final GameState state;
  final RequirementEngine engine;

  _ExpressionParser(String input, this.state, this.engine)
      : _tokens = _tokenize(input);

  bool evaluate() {
    if (_tokens.isEmpty) return true;
    try {
      final value = _parseExpression();
      return _truthy(value);
    } catch (e) {
      GameLogger.warn('Requirement parse error: $e');
      return false;
    }
  }

  dynamic _parseExpression() => _parseOr();

  dynamic _parseOr() {
    var left = _parseAnd();
    while (_match('||')) {
      final right = _parseAnd();
      left = _truthy(left) || _truthy(right);
    }
    return left;
  }

  dynamic _parseAnd() {
    var left = _parseComparison();
    while (_match('&&')) {
      final right = _parseComparison();
      left = _truthy(left) && _truthy(right);
    }
    return left;
  }

  dynamic _parseComparison() {
    var left = _parsePrimary();
    final op = _peek();
    if (op == '==' ||
        op == '!=' ||
        op == '>=' ||
        op == '<=' ||
        op == '>' ||
        op == '<') {
      _advance();
      final right = _parsePrimary();
      return _compare(left, right, op!);
    }
    return left;
  }

  dynamic _parsePrimary() {
    final token = _peek();
    if (token == null) {
      throw StateError('Unexpected end of expression');
    }
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw StateError('Expected closing )');
      }
      return value;
    }

    _advance();
    return _resolveToken(token);
  }

  bool _compare(dynamic left, dynamic right, String op) {
    final leftNum = _toNum(left);
    final rightNum = _toNum(right);

    if (leftNum != null && rightNum != null) {
      switch (op) {
        case '==':
          return leftNum == rightNum;
        case '!=':
          return leftNum != rightNum;
        case '>=':
          return leftNum >= rightNum;
        case '<=':
          return leftNum <= rightNum;
        case '>':
          return leftNum > rightNum;
        case '<':
          return leftNum < rightNum;
      }
    }

    final leftBool = _truthy(left);
    final rightBool = _truthy(right);
    switch (op) {
      case '==':
        return leftBool == rightBool;
      case '!=':
        return leftBool != rightBool;
      case '>=':
        return (leftBool ? 1 : 0) >= (rightBool ? 1 : 0);
      case '<=':
        return (leftBool ? 1 : 0) <= (rightBool ? 1 : 0);
      case '>':
        return (leftBool ? 1 : 0) > (rightBool ? 1 : 0);
      case '<':
        return (leftBool ? 1 : 0) < (rightBool ? 1 : 0);
      default:
        return false;
    }
  }

  dynamic _resolveToken(String token) {
    final numValue = _toNum(token);
    if (numValue != null) return numValue;

    if (token == 'true') return true;
    if (token == 'false') return false;

    if (token.startsWith('flag:')) {
      final flag = token.substring(5);
      return state.flags.contains(flag);
    }
    if (token.startsWith('flagAny:')) {
      final raw = token.substring(8);
      final parts = raw.split('|').where((e) => e.isNotEmpty).toList();
      if (parts.isEmpty) return false;
      return parts.any((f) => state.flags.contains(f));
    }
    if (token.startsWith('!flag:')) {
      final flag = token.substring(6);
      return !state.flags.contains(flag);
    }
    if (token.startsWith('hasItem:') || token.startsWith('item:')) {
      final raw = token.startsWith('hasItem:') ? token.substring(8) : token.substring(5);
      final parts = raw.split(':');
      final itemId = parts[0];
      return engine._getItemQty(state, itemId);
    }
    if (token.startsWith('districtLocked:')) {
      final districtId = token.substring(15);
      final district = engine.data.getDistrict(districtId);
      if (district == null) return true;
      final stateInfo = state.districtStates[districtId];
      final unlocked = district.startUnlocked || (stateInfo?.unlocked ?? false);
      return !unlocked;
    }
    if (token.startsWith('canCraft:')) {
      final recipeId = token.substring(9);
      return engine._canCraftRecipe(recipeId, state);
    }
    if (token.startsWith('skill:')) {
      return engine._checkSkillRequirement(token.substring(6), state);
    }
    if (token.startsWith('nearTrader:')) {
      final factionId = token.substring(11);
      if (engine.data.factions.containsKey(factionId)) {
        final rep = state.factionRep[factionId] ?? 0;
        return rep > -50;
      }
      return false;
    }
    if (token.startsWith('rep:')) {
      return engine._checkRepRequirement(token.substring(4), state);
    }
    if (token.startsWith('party:')) {
      return engine._checkPartyRequirement(token.substring(6), state);
    }
    if (token.startsWith('quest:')) {
      final raw = token.substring(6);
      final stageIndex = raw.indexOf('.stage');
      if (stageIndex != -1) {
        final questId = raw.substring(0, stageIndex);
        final questState = state.quests[questId];
        return questState?.stage ?? 0;
      }
      final questState = state.quests[raw];
      return questState != null;
    }

    final pathValue = engine._getNumericValueByPath(token, state);
    if (pathValue != null) return pathValue;

    // Fallback: treat bare token as flag
    if (state.flags.contains(token)) return true;

    GameLogger.warn('Unknown requirement token: $token');
    return false;
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  bool _truthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value != null;
  }

  bool _match(String token) {
    if (_peek() == token) {
      _advance();
      return true;
    }
    return false;
  }

  String? _peek() {
    if (_index >= _tokens.length) return null;
    return _tokens[_index];
  }

  void _advance() {
    if (_index < _tokens.length) _index++;
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    int i = 0;

    bool isIdentChar(String c) {
      final code = c.codeUnitAt(0);
      final isAlphaNum =
          (code >= 48 && code <= 57) || // 0-9
          (code >= 65 && code <= 90) || // A-Z
          (code >= 97 && code <= 122); // a-z
      return isAlphaNum ||
          c == '_' ||
          c == '.' ||
          c == ':' ||
          c == '-' ||
          c == '/' ||
          c == '|';
    }

    while (i < input.length) {
      final ch = input[i];

      if (ch.trim().isEmpty) {
        i++;
        continue;
      }

      if (ch == '(' || ch == ')') {
        tokens.add(ch);
        i++;
        continue;
      }

      if (i + 1 < input.length) {
        final two = input.substring(i, i + 2);
        if (two == '&&' || two == '||' || two == '>=' || two == '<=' || two == '==' || two == '!=') {
          tokens.add(two);
          i += 2;
          continue;
        }
      }

      if (ch == '>' || ch == '<') {
        tokens.add(ch);
        i++;
        continue;
      }

      if (ch == '-' && i + 1 < input.length && _isDigit(input[i + 1])) {
        final start = i;
        i++;
        while (i < input.length && _isDigit(input[i])) {
          i++;
        }
        tokens.add(input.substring(start, i));
        continue;
      }

      if (_isDigit(ch)) {
        final start = i;
        i++;
        while (i < input.length && _isDigit(input[i])) {
          i++;
        }
        if (i < input.length && input[i] == '.') {
          i++;
          while (i < input.length && _isDigit(input[i])) {
            i++;
          }
        }
        tokens.add(input.substring(start, i));
        continue;
      }

      if (isIdentChar(ch)) {
        final start = i;
        i++;
        while (i < input.length && isIdentChar(input[i])) {
          i++;
        }
        tokens.add(input.substring(start, i));
        continue;
      }

      // Unknown char, skip
      i++;
    }

    return tokens;
  }

  static bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }
}

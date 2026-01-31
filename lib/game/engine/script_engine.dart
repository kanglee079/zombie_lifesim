import '../../core/logger.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import 'effect_engine.dart';
import 'requirement_engine.dart';

class ScriptResult {
  final bool success;
  final String outcome;

  const ScriptResult({required this.success, required this.outcome});
}

/// Engine for executing scripted checks/branches from data
class ScriptEngine {
  final GameDataRepository data;
  final RequirementEngine requirementEngine;
  final EffectEngine effectEngine;

  ScriptEngine({
    required this.data,
    required this.requirementEngine,
    required this.effectEngine,
  });

  ScriptResult run(String scriptId, GameState state) {
    final script = data.getScript(scriptId);
    if (script == null) {
      GameLogger.warn('Unknown script: $scriptId');
      return const ScriptResult(success: false, outcome: 'fail');
    }

    final type = script['type']?.toString() ?? 'check';
    switch (type) {
      case 'check':
        return _runCheck(script, state);
      case 'branch':
        return _runBranch(script, state);
      default:
        GameLogger.warn('Unknown script type: $type');
        return const ScriptResult(success: false, outcome: 'fail');
    }
  }

  ScriptResult _runCheck(Map<String, dynamic> script, GameState state) {
    final checks = script['checks'] as List<dynamic>? ?? [];
    for (final entry in checks) {
      if (entry is! Map) continue;
      final ifAll = entry['ifAll'] as List<dynamic>? ?? const [];
      final ifAny = entry['ifAny'] as List<dynamic>? ?? const [];

      if (ifAll.isNotEmpty && !requirementEngine.check(ifAll, state)) {
        continue;
      }
      if (ifAny.isNotEmpty && !requirementEngine.checkAny(ifAny, state)) {
        continue;
      }

      final require = entry['require'] as List<dynamic>? ?? const [];
      final requireOk = _checkRequireList(require, state);
      if (requireOk) {
        final effects = entry['onPassEffects'] as List<dynamic>? ?? const [];
        if (effects.isNotEmpty) {
          effectEngine.executeEffects(effects, state);
        }
        final outcome = entry['onPass']?.toString() ?? 'success';
        return ScriptResult(success: outcome == 'success', outcome: outcome);
      }

      final onFail = entry['onFail']?.toString() ?? 'fail';
      if (onFail == 'continue') {
        continue;
      }
      return ScriptResult(success: false, outcome: onFail);
    }

    return const ScriptResult(success: false, outcome: 'fail');
  }

  ScriptResult _runBranch(Map<String, dynamic> script, GameState state) {
    final branches = script['branches'] as List<dynamic>? ?? [];
    for (final entry in branches) {
      if (entry is! Map) continue;
      final ifAll = entry['ifAll'] as List<dynamic>? ?? const [];
      final ifAny = entry['ifAny'] as List<dynamic>? ?? const [];

      if (ifAll.isNotEmpty && !requirementEngine.check(ifAll, state)) {
        continue;
      }
      if (ifAny.isNotEmpty && !requirementEngine.checkAny(ifAny, state)) {
        continue;
      }

      final effects = entry['effects'] as List<dynamic>? ?? const [];
      if (effects.isNotEmpty) {
        effectEngine.executeEffects(effects, state);
      }
      return const ScriptResult(success: true, outcome: 'branch');
    }

    return const ScriptResult(success: false, outcome: 'fail');
  }

  bool _checkRequireList(List<dynamic> require, GameState state) {
    for (final entry in require) {
      if (entry is! Map) continue;
      final type = entry['type']?.toString();
      switch (type) {
        case 'item':
          final id = entry['id']?.toString();
          final qty = (entry['qty'] as num?)?.toInt() ?? 1;
          if (id == null || !_hasItemQty(state, id, qty)) {
            return false;
          }
          break;
        case 'tag':
          final tag = entry['tag']?.toString();
          final qty = (entry['qty'] as num?)?.toInt() ?? 1;
          if (tag == null || !_hasTagQty(state, tag, qty)) {
            return false;
          }
          break;
        default:
          // Allow string requirements embedded
          if (type == null && entry.containsKey('req')) {
            final req = entry['req'];
            if (req != null && !requirementEngine.check(req, state)) {
              return false;
            }
          }
          break;
      }
    }
    return true;
  }

  bool _hasItemQty(GameState state, String itemId, int qty) {
    int total = 0;
    for (final stack in state.inventory) {
      if (stack.itemId == itemId) {
        total += stack.qty;
      }
    }
    return total >= qty;
  }

  bool _hasTagQty(GameState state, String tag, int qty) {
    int total = 0;
    for (final stack in state.inventory) {
      final item = data.getItem(stack.itemId);
      if (item != null && item.hasTag(tag)) {
        total += stack.qty;
        if (total >= qty) return true;
      }
    }
    return total >= qty;
  }
}

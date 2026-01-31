import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';

class DepletionModifiers {
  final double lootMult;
  final double riskMult;
  final double rareMult;
  final String stageId;
  final String stageLabel;

  const DepletionModifiers({
    required this.lootMult,
    required this.riskMult,
    required this.rareMult,
    required this.stageId,
    required this.stageLabel,
  });
}

class DepletionEngine {
  final GameDataRepository data;

  DepletionEngine({required this.data});

  DepletionModifiers getModifiers(int depletion) {
    final system = data.depletionSystem;
    final stages = system['stages'] as List<dynamic>? ?? [];

    Map<String, dynamic>? stage;
    for (final s in stages) {
      if (s is Map<String, dynamic>) {
        final min = (s['min'] as num?)?.toInt() ?? 0;
        final max = (s['max'] as num?)?.toInt() ?? 100;
        if (depletion >= min && depletion <= max) {
          stage = s;
          break;
        }
      }
    }

    stage ??= const {
      'id': 'fresh',
      'label': 'Còn phong phú',
      'lootMult': 1.0,
      'riskMult': 1.0,
      'rareMult': 1.0,
    };

    final baseLoot = (stage['lootMult'] as num?)?.toDouble() ?? 1.0;
    final baseRisk = (stage['riskMult'] as num?)?.toDouble() ?? 1.0;
    final baseRare = (stage['rareMult'] as num?)?.toDouble() ?? 1.0;

    final over = Clamp.i(depletion - 50, 0, 50);
    final lootMult = (baseLoot * (1 - 0.0025 * over)).clamp(0.05, 3.0);
    final riskMult = (baseRisk * (1 + 0.0020 * depletion)).clamp(0.2, 3.0);
    final rareMult = (baseRare * (1 - 0.003 * depletion)).clamp(0.05, 3.0);

    return DepletionModifiers(
      lootMult: lootMult,
      riskMult: riskMult,
      rareMult: rareMult,
      stageId: stage['id']?.toString() ?? 'fresh',
      stageLabel: stage['label']?.toString() ?? 'Còn phong phú',
    );
  }

  void applyVisit({
    required LocationState locState,
    required String timeOption,
    required String style,
    required GameState state,
  }) {
    final system = data.depletionSystem;
    final visitDelta = system['visitDelta'] as Map<String, dynamic>? ?? {};

    final timeMap = visitDelta['timeOption'] as Map<String, dynamic>? ?? {};
    final styleMap = visitDelta['style'] as Map<String, dynamic>? ?? {};
    final toolsMap = visitDelta['toolsBonus'] as Map<String, dynamic>? ?? {};

    final timeDelta = (timeMap[timeOption] as num?)?.toInt() ?? 0;
    final styleDelta = (styleMap[style] as num?)?.toInt() ?? 0;
    final toolsDelta = _getToolsBonus(state, toolsMap);
    final cap = (visitDelta['capPerVisit'] as num?)?.toInt() ?? 22;

    final delta = Clamp.i(timeDelta + styleDelta + toolsDelta, 0, cap);

    locState.depletion = Clamp.depletion(locState.depletion + delta);
    locState.visitCount++;
    locState.lastVisitDay = state.day;
  }

  void applyRecovery(GameState state) {
    final system = data.depletionSystem;
    final recovery = system['recovery'] as Map<String, dynamic>? ?? {};
    final perDay = (recovery['perDay'] as num?)?.toDouble() ?? 0.6;
    final minDays = (recovery['minDaysBeforeRecovery'] as num?)?.toInt() ?? 2;
    final maxRecoverable = (recovery['maxRecoverable'] as num?)?.toInt() ?? 35;
    final modifiersByFlags = recovery['modifiersByFlags'] as Map<String, dynamic>? ?? {};

    double effectivePerDay = perDay;
    int effectiveMaxRecoverable = maxRecoverable;

    for (final entry in modifiersByFlags.entries) {
      final flag = entry.key.toString();
      if (!state.flags.contains(flag)) continue;
      if (entry.value is Map) {
        final map = Map<String, dynamic>.from(entry.value);
        effectivePerDay = (map['perDay'] as num?)?.toDouble() ?? effectivePerDay;
        effectiveMaxRecoverable =
            (map['maxRecoverable'] as num?)?.toInt() ?? effectiveMaxRecoverable;
      }
    }

    for (final entry in state.locationStates.entries) {
      final locState = entry.value;
      final daysSinceVisit = state.day - locState.lastVisitDay;
      if (daysSinceVisit < minDays) continue;

      final target = effectiveMaxRecoverable;
      if (locState.depletion <= target) continue;

      final newValue = (locState.depletion - effectivePerDay).round();
      locState.depletion = Clamp.depletion(newValue < target ? target : newValue);
    }
  }

  int _getToolsBonus(GameState state, Map<String, dynamic> toolsMap) {
    int bonus = 0;
    if (_hasItem(state, 'backpack')) {
      bonus += (toolsMap['hasBackpack'] as num?)?.toInt() ?? 0;
    }
    if (_hasItem(state, 'crowbar')) {
      bonus += (toolsMap['hasCrowbar'] as num?)?.toInt() ?? 0;
    }
    if (_hasItem(state, 'lockpick_set')) {
      bonus += (toolsMap['hasLockpick'] as num?)?.toInt() ?? 0;
    }
    return bonus;
  }

  bool _hasItem(GameState state, String itemId) {
    for (final stack in state.inventory) {
      if (stack.itemId == itemId && stack.qty > 0) return true;
    }
    return false;
  }
}

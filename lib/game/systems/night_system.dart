import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import '../engine/event_engine.dart';
import '../engine/requirement_engine.dart';

/// Result of night threat resolution
class NightResult {
  final bool wasAttacked;
  final int damage;
  final int zombiesKilled;
  final List<String> lostItems;
  final String narrative;

  const NightResult({
    required this.wasAttacked,
    required this.damage,
    required this.zombiesKilled,
    required this.lostItems,
    required this.narrative,
  });
}

/// System for resolving night threats
class NightSystem {
  final GameDataRepository data;
  final GameRng rng;
  final EventEngine eventEngine;
  final RequirementEngine requirementEngine;

  NightSystem({
    required this.data,
    required this.rng,
    required this.eventEngine,
    required this.requirementEngine,
  });

  /// Resolve night threats
  NightResult resolve(GameState state) {
    final balance = data.balance;
    final nightModel = balance.raw['nightThreatModel'] as Map<String, dynamic>? ?? {};
    final coeffs = nightModel['coefficients'] as Map<String, dynamic>? ?? {};
    final clampRange = (nightModel['clamp'] as List?) ?? [0, 100];
    final clampMin = (clampRange[0] as num?)?.toInt() ?? 0;
    final clampMax = (clampRange.length > 1 ? clampRange[1] : clampRange[0] as num?)
            ?.toInt() ??
        100;

    final nightBaseThreat = _getNightBaseThreat(state.day);
    final threat = _computeThreat(nightBaseThreat, coeffs, state);
    final threatClamped = Clamp.i(threat.round(), clampMin, clampMax);
    state.tempModifiers['nightThreat'] = threatClamped;

    final probability = nightModel['probability'] as Map<String, dynamic>? ?? {};
    final baseP = (probability['base'] as num?)?.toDouble() ?? 0.0;
    final scale = (probability['scale'] as num?)?.toDouble() ?? 0.0;
    final cap = (probability['cap'] as num?)?.toDouble() ?? 1.0;
    final pNight = (baseP + threatClamped * scale).clamp(0.0, cap);

    final roll = rng.nextDouble();
    if (roll > pNight) {
      state.addLog('🌙 Đêm yên ắng. Không có dấu hiệu tấn công.');
      GameLogger.game('Night: threat=$threatClamped, attacked=false, p=$pNight');
      return const NightResult(
        wasAttacked: false,
        damage: 0,
        zombiesKilled: 0,
        lostItems: [],
        narrative: 'quiet',
      );
    }

    final severity = _resolveSeverity(threatClamped, nightModel['severityTiers']);
    final event = _selectNightEvent(state, severity);
    if (event != null) {
      state.currentEvent = event;
    } else {
      state.addLog('⚠️ Đêm hỗn loạn, nhưng không có sự kiện cụ thể.');
    }

    _applyAfterAttack(state, nightModel['afterAttack']);

    GameLogger.game('Night: threat=$threatClamped, attacked=true, p=$pNight, tier=$severity');

    return const NightResult(
      wasAttacked: true,
      damage: 0,
      zombiesKilled: 0,
      lostItems: [],
      narrative: 'attack',
    );
  }

  double _getNightBaseThreat(int day) {
    final progression = data.balance.raw['progression'] as Map<String, dynamic>? ?? {};
    final multipliers = progression['multipliersByDay'] as Map<String, dynamic>? ?? {};
    final list = multipliers['nightBaseThreat'] as List<dynamic>? ?? const [];
    if (list.isEmpty) return 0.0;
    final index = Clamp.i(day - 1, 0, list.length - 1);
    return (list[index] as num?)?.toDouble() ?? 0.0;
  }

  double _computeThreat(
    double nightBaseThreat,
    Map<String, dynamic> coeffs,
    GameState state,
  ) {
    final coeffBase = (coeffs['base'] as num?)?.toDouble() ?? 1.0;
    final coeffNoise = (coeffs['noise'] as num?)?.toDouble() ?? 0.0;
    final coeffSmell = (coeffs['smell'] as num?)?.toDouble() ?? 0.0;
    final coeffSignal = (coeffs['signalHeat'] as num?)?.toDouble() ?? 0.0;
    final coeffDefense = (coeffs['defense'] as num?)?.toDouble() ?? 0.0;
    final coeffHope = (coeffs['hope'] as num?)?.toDouble() ?? 0.0;
    final coeffFatigue = (coeffs['fatigue'] as num?)?.toDouble() ?? 0.0;
    final coeffParty = (coeffs['partySize'] as num?)?.toDouble() ?? 0.0;

    final base = state.baseStats;
    final partySize = (state.party.length - 1).clamp(0, 50);
    return nightBaseThreat * coeffBase +
        base.noise * coeffNoise +
        base.smell * coeffSmell +
        base.signalHeat * coeffSignal +
        base.defense * coeffDefense +
        base.hope * coeffHope +
        (state.playerStats.fatigue - 50) * coeffFatigue +
        partySize * coeffParty;
  }

  String _resolveSeverity(int threat, dynamic tiersRaw) {
    if (tiersRaw is! List) return 'minor';
    for (final tier in tiersRaw) {
      if (tier is! Map) continue;
      final under = (tier['threatUnder'] as num?)?.toInt() ?? 101;
      if (threat <= under) {
        return tier['id']?.toString() ?? 'minor';
      }
    }
    return 'siege';
  }

  Map<String, dynamic>? _selectNightEvent(GameState state, String severity) {
    final preferred = <Map<String, dynamic>>[];
    final preferredWeights = <double>[];
    final fallback = <Map<String, dynamic>>[];
    final fallbackWeights = <double>[];

    for (final event in data.events.values) {
      final eventId = event['id']?.toString() ?? '';
      if (eventId.isEmpty) continue;
      if (!_matchesContext(event, 'night')) continue;

      if (!_passesEventFilters(event, state)) continue;

      final weight = _eventWeight(event, state);
      if (_isPreferredBySeverity(event, eventId, severity)) {
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
      // Fall back to standard night selection via EventEngine.
      selected = eventEngine.selectEvent(state, context: 'night');
      if (selected != null) {
        return selected;
      }
    }

    if (selected == null && fallback.isNotEmpty) {
      selected = _weightedPick(fallback, fallbackWeights);
    }

    if (selected == null) return null;

    final selectedId = selected['id'] as String;
    state.eventHistory[selectedId] = EventHistory(day: state.day, outcomeIndex: 0);
    return selected;
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

  bool _isPreferredBySeverity(
    Map<String, dynamic> event,
    String eventId,
    String severity,
  ) {
    final id = eventId.toLowerCase();
    final group = event['group']?.toString().toLowerCase() ?? '';
    if (severity == 'minor') {
      return id.contains('scratching') || id.contains('passing') || id.contains('fever');
    }
    if (severity == 'siege') {
      final idMatch = id.contains('siege') || id.contains('raid') || id.contains('ambush');
      final groupMatch = group.contains('late_war') || group.contains('ending');
      return idMatch || groupMatch;
    }
    return false;
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

  void _applyAfterAttack(GameState state, dynamic afterAttackRaw) {
    final afterAttack = afterAttackRaw as Map<String, dynamic>? ?? {};
    final noiseDelta = (afterAttack['noiseDelta'] as num?)?.toInt() ?? 0;
    final smellDelta = (afterAttack['smellDelta'] as num?)?.toInt() ?? 0;
    final hopeDelta = (afterAttack['hopeDelta'] as num?)?.toInt() ?? 0;

    if (noiseDelta != 0) {
      state.baseStats.noise = Clamp.stat(state.baseStats.noise + noiseDelta, 0, 100);
    }
    if (smellDelta != 0) {
      state.baseStats.smell = Clamp.stat(state.baseStats.smell + smellDelta, 0, 100);
    }
    if (hopeDelta != 0) {
      state.baseStats.hope = Clamp.stat(state.baseStats.hope + hopeDelta, 0, 100);
    }
  }
}

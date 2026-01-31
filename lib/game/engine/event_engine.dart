import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import 'requirement_engine.dart';
import 'effect_engine.dart';
import 'script_engine.dart';

/// Engine for selecting and processing events
class EventEngine {
  final GameDataRepository data;
  final RequirementEngine requirementEngine;
  final EffectEngine effectEngine;
  final ScriptEngine? scriptEngine;
  final GameRng rng;

  EventEngine({
    required this.data,
    required this.requirementEngine,
    required this.effectEngine,
    this.scriptEngine,
    required this.rng,
  });

  /// Select an event for the current context
  Map<String, dynamic>? selectEvent(GameState state, {String? context, Set<String>? excludeIds}) {
    context ??= state.timeOfDay;
    excludeIds ??= {};

    // Get eligible events
    final eligible = <Map<String, dynamic>>[];
    final weights = <double>[];

    for (final event in data.events.values) {
      final eventId = event['id'] as String;
      
      // Skip events already used in current session
      if (excludeIds.contains(eventId)) {
        continue;
      }

      // Check context
      final contextsRaw = event['contexts'] ?? event['context'];
      final contexts = <String>[];
      if (contextsRaw is String) {
        contexts.add(contextsRaw);
      } else if (contextsRaw is List) {
        contexts.addAll(contextsRaw.map((e) => e.toString()));
      }
      if (contexts.isNotEmpty) {
        final matches = contexts.any((c) {
          if (c == context) return true;
          if (context != null && context.startsWith('$c:')) return true;
          return false;
        });
        if (!matches) continue;
      }

      // Check minDay
      final minDay = (event['minDay'] as num?)?.toInt() ?? 0;
      if (state.day < minDay) {
        continue;
      }

      // Check cooldown
      final cooldownDays = (event['cooldownDays'] as num?)?.toInt() ?? 0;
      if (cooldownDays > 0) {
        final lastOccurrence = state.eventHistory[eventId];
        if (lastOccurrence != null) {
          final daysSince = state.day - lastOccurrence.day;
          if (daysSince < cooldownDays) {
            continue;
          }
        }
      }

      // Check repeatable
      final repeatable = event['repeatable'] as bool? ?? true;
      if (!repeatable && state.eventHistory.containsKey(eventId)) {
        continue;
      }

      // Check requirements
      final requirements = event['requirements'];
      final conditions = event['conditions'];
      if (requirements != null && !requirementEngine.check(requirements, state)) {
        continue;
      }
      if (conditions != null && !requirementEngine.check(conditions, state)) {
        continue;
      }

      // Add to eligible list
      eligible.add(event);
      double weight = (event['weight'] as num?)?.toDouble() ?? 1.0;
      final group = event['group']?.toString();
      if (group != null) {
        final mod = state.tempModifiers['eventWeightMult:$group'];
        if (mod is Map && mod['mult'] is num) {
          weight *= (mod['mult'] as num).toDouble();
        }
      }
      weights.add(weight);
    }

    if (eligible.isEmpty) {
      return null;
    }

    // Select by weighted random
    final index = rng.weightedSelect(weights);
    if (index < 0 || index >= eligible.length) {
      return null;
    }

    final selected = eligible[index];
    final selectedId = selected['id'] as String;

    // Record in history
    state.eventHistory[selectedId] = EventHistory(
      day: state.day,
      outcomeIndex: 0,
    );

    GameLogger.game('Event selected: $selectedId');

    return selected;
  }

  /// Process player choice for current event
  void processChoice(GameState state, Map<String, dynamic> event, int choiceIndex) {
    final eventId = event['id'] as String;
    final choices = event['choices'] as List<dynamic>?;

    if (choices == null || choiceIndex >= choices.length) {
      GameLogger.warn('Invalid choice index: $choiceIndex for event $eventId');
      return;
    }

    final choice = choices[choiceIndex] as Map<String, dynamic>;

    // Check choice requirements
    final choiceRequirements = choice['requirements'] ?? choice['conditions'];
    if (choiceRequirements != null &&
        !requirementEngine.check(choiceRequirements, state)) {
      GameLogger.warn('Choice requirements not met for event $eventId');
      return;
    }

    // Update event history with chosen outcome
    state.eventHistory[eventId] = EventHistory(
      day: state.day,
      outcomeIndex: choiceIndex,
    );

    // Process choice based on schema
    _processChoiceOutcome(choice, state, event);

    // Process queued immediate events (if any)
    if (state.eventQueue.isNotEmpty) {
      final nextEventId = state.eventQueue.removeAt(0);
      triggerEvent(nextEventId, state);
    }

    GameLogger.game('Event $eventId: chose option $choiceIndex');
  }

  /// Process choice outcome (handles different schemas)
  void _processChoiceOutcome(
    Map<String, dynamic> choice,
    GameState state,
    Map<String, dynamic> event,
  ) {
    // Apply cost effects (always)
    final costEffects = choice['costEffects'] as List<dynamic>?;
    if (costEffects != null && costEffects.isNotEmpty) {
      effectEngine.executeEffects(costEffects, state);
    }

    // Schema v1: outcomes list
    final outcomes = choice['outcomes'] as List<dynamic>?;
    if (outcomes != null && outcomes.isNotEmpty) {
      _processOutcomes(outcomes, state);
      return;
    }

    // Schema A: Direct effects on choice
    final effects = choice['effects'] as List<dynamic>?;
    if (effects != null) {
      effectEngine.executeEffects(effects, state);
      return;
    }

    // Schema B: Outcome object with text and effects
    final outcome = choice['outcome'] as Map<String, dynamic>?;
    if (outcome != null) {
      final outcomeText = outcome['text'] as String?;
      if (outcomeText != null) {
        state.addLog(outcomeText);
      }
      final outcomeEffects = outcome['effects'] as List<dynamic>?;
      if (outcomeEffects != null) {
        effectEngine.executeEffects(outcomeEffects, state);
      }
      return;
    }

    // Schema C: Resolve with probability outcomes
    final resolve = choice['resolve'] as Map<String, dynamic>?;
    if (resolve != null) {
      _processResolve(resolve, state);
      return;
    }

    // Shorthand: Just text response
    final resultText = choice['result'] as String?;
    if (resultText != null) {
      state.addLog(resultText);
    }
  }

  void _processOutcomes(List<dynamic> outcomes, GameState state) {
    final weights = <double>[];
    final entries = <Map<String, dynamic>>[];

    for (final outcome in outcomes) {
      if (outcome is Map<String, dynamic>) {
        final chance = (outcome['chance'] as num?)?.toDouble() ?? 1.0;
        weights.add(chance);
        entries.add(outcome);
      }
    }

    if (entries.isEmpty) return;

    final index = rng.weightedSelect(weights);
    final safeIndex = (index < 0 || index >= entries.length) ? 0 : index;
    final selected = entries[safeIndex];
    final text = selected['text'] as String?;
    if (text != null) {
      state.addLog(text);
    }

    final effects = selected['effects'] as List<dynamic>?;
    if (effects != null) {
      effectEngine.executeEffects(effects, state);
    }
  }

  /// Process resolve block (supports v2/v3 schemas)
  void _processResolve(Map<String, dynamic> resolve, GameState state) {
    final kind = resolve['kind'] ?? resolve['type'];

    // Legacy outcomes list
    final outcomes = resolve['outcomes'] as List<dynamic>?;
    if (outcomes != null && outcomes.isNotEmpty) {
      _processOutcomes(outcomes, state);
      return;
    }

    switch (kind) {
      case 'script':
        _processScriptResolve(resolve, state);
        return;
      case 'auto':
        _applyResolveBlock(resolve, state);
        return;
      case 'chance':
        _processChanceResolve(resolve, state);
        return;
      case 'skill':
        _processSkillResolve(resolve, state);
        return;
      default:
        _applyResolveBlock(resolve, state);
    }
  }

  void _processChanceResolve(Map<String, dynamic> resolve, GameState state) {
    final chance = (resolve['chance'] as num?)?.toDouble() ??
        (resolve['p'] as num?)?.toDouble() ??
        (resolve['baseP'] as num?)?.toDouble() ??
        0.5;

    final roll = rng.nextDouble();
    if (roll <= chance) {
      _applyResolveBlock(resolve['success'], state, successFallback: resolve);
    } else {
      _applyResolveBlock(resolve['fail'], state, failFallback: resolve);
    }
  }

  void _processSkillResolve(Map<String, dynamic> resolve, GameState state) {
    final skill = resolve['skill']?.toString() ?? 'scavenge';
    final dc = (resolve['dc'] as num?)?.toInt() ?? 0;
    final baseP = (resolve['baseP'] as num?)?.toDouble() ??
        (resolve['p'] as num?)?.toDouble() ??
        0.5;

    final skillLevel = state.playerSkills.getByName(skill);
    final bonus = (skillLevel - dc) * 0.05;
    final chance = (baseP + bonus).clamp(0.0, 1.0);

    final roll = rng.nextDouble();
    if (roll <= chance) {
      _applyResolveBlock(resolve['success'], state, successFallback: resolve);
    } else {
      _applyResolveBlock(resolve['fail'], state, failFallback: resolve);
    }
  }

  void _processScriptResolve(Map<String, dynamic> resolve, GameState state) {
    final scriptId = resolve['id']?.toString() ?? resolve['scriptId']?.toString();
    if (scriptId == null || scriptEngine == null) {
      GameLogger.warn('Script resolve missing id');
      return;
    }

    final result = scriptEngine!.run(scriptId, state);

    final successEffects = resolve['successEffects'] as List<dynamic>?;
    final failEffects = resolve['failEffects'] as List<dynamic>?;

    if (result.success) {
      if (successEffects != null) {
        effectEngine.executeEffects(successEffects, state);
      }
    } else {
      if (failEffects != null) {
        effectEngine.executeEffects(failEffects, state);
      }
    }
  }

  void _applyResolveBlock(
    dynamic block,
    GameState state, {
    Map<String, dynamic>? successFallback,
    Map<String, dynamic>? failFallback,
  }) {
    if (block is Map<String, dynamic>) {
      final log = block['log'] as String?;
      if (log != null) {
        state.addLog(log);
      }
      final effects = block['effects'] as List<dynamic>?;
      if (effects != null) {
        effectEngine.executeEffects(effects, state);
      }
      return;
    }

    // v3 style: resolve contains successEffects/failEffects
    if (successFallback != null || failFallback != null) {
      final effects = successFallback?['successEffects'] ??
          failFallback?['failEffects'] ??
          successFallback?['effects'] ??
          failFallback?['effects'];
      if (effects is List) {
        effectEngine.executeEffects(effects, state);
      }

      final log = successFallback?['successLog'] ??
          failFallback?['failLog'] ??
          successFallback?['log'] ??
          failFallback?['log'];
      if (log is String) {
        state.addLog(log);
      }
    }
  }

  /// Get event by ID
  Map<String, dynamic>? getEvent(String eventId) {
    return data.events[eventId];
  }

  /// Trigger a specific event
  void triggerEvent(String eventId, GameState state) {
    final event = data.events[eventId];
    if (event == null) {
      GameLogger.warn('Unknown event: $eventId');
      return;
    }

    state.currentEvent = event;
    GameLogger.game('Event triggered: $eventId');
  }
}

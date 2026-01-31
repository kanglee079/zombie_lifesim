import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import 'requirement_engine.dart';
import 'effect_engine.dart';

/// Engine for selecting and processing events
class EventEngine {
  final GameDataRepository data;
  final RequirementEngine requirementEngine;
  final EffectEngine effectEngine;
  final GameRng rng;

  EventEngine({
    required this.data,
    required this.requirementEngine,
    required this.effectEngine,
    required this.rng,
  });

  /// Select an event for the current context
  Map<String, dynamic>? selectEvent(GameState state, {String? context}) {
    context ??= state.timeOfDay;

    // Get eligible events
    final eligible = <Map<String, dynamic>>[];
    final weights = <double>[];

    for (final event in data.events.values) {
      // Check context
      final contexts = event['contexts'] as List<dynamic>? ?? [];
      if (contexts.isNotEmpty && !contexts.contains(context)) {
        continue;
      }

      // Check minDay
      final minDay = (event['minDay'] as num?)?.toInt() ?? 0;
      if (state.day < minDay) {
        continue;
      }

      // Check cooldown
      final eventId = event['id'] as String;
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
      if (requirements != null) {
        if (!requirementEngine.check(requirements, state)) {
          continue;
        }
      }

      // Add to eligible list
      eligible.add(event);
      weights.add((event['weight'] as num?)?.toDouble() ?? 1.0);
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
    final eventId = selected['id'] as String;

    // Record in history
    state.eventHistory[eventId] = EventHistory(
      day: state.day,
      outcomeIndex: 0,
    );

    GameLogger.game('Event selected: $eventId');

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

    // Update event history with chosen outcome
    state.eventHistory[eventId] = EventHistory(
      day: state.day,
      outcomeIndex: choiceIndex,
    );

    // Process choice based on schema
    _processChoiceOutcome(choice, state, event);

    GameLogger.game('Event $eventId: chose option $choiceIndex');
  }

  /// Process choice outcome (handles different schemas)
  void _processChoiceOutcome(
    Map<String, dynamic> choice,
    GameState state,
    Map<String, dynamic> event,
  ) {
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

  /// Process resolve block (probability-based outcomes)
  void _processResolve(Map<String, dynamic> resolve, GameState state) {
    final outcomes = resolve['outcomes'] as List<dynamic>?;
    if (outcomes == null || outcomes.isEmpty) return;

    // Check for skill-based resolution
    final skill = resolve['skill'] as String?;
    int skillBonus = 0;
    if (skill != null) {
      skillBonus = state.playerSkills.getByName(skill);
    }

    // Roll for outcome
    final roll = rng.nextDouble() * 100 + skillBonus * 5;

    // Find matching outcome based on probability thresholds
    Map<String, dynamic>? selectedOutcome;

    for (final outcome in outcomes) {
      final prob = (outcome['prob'] as num?)?.toDouble() ?? 50;
      if (roll <= prob) {
        selectedOutcome = outcome as Map<String, dynamic>;
        break;
      }
    }

    // Fallback to last outcome
    selectedOutcome ??= outcomes.last as Map<String, dynamic>;

    // Apply outcome
    final outcomeText = selectedOutcome['text'] as String?;
    if (outcomeText != null) {
      state.addLog(outcomeText);
    }

    final effects = selectedOutcome['effects'] as List<dynamic>?;
    if (effects != null) {
      effectEngine.executeEffects(effects, state);
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

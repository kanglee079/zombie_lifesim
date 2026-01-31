import '../../core/logger.dart';
import '../../data/models/quest_def.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import '../engine/effect_engine.dart';

/// System for managing quests
class QuestSystem {
  final GameDataRepository data;
  final EffectEngine effectEngine;

  QuestSystem({required this.data, required this.effectEngine});

  /// Start a quest
  bool startQuest(String questId, GameState state) {
    final quest = data.getQuest(questId);
    if (quest == null) {
      GameLogger.warn('Unknown quest: $questId');
      return false;
    }

    // Check if already active
    if (state.quests.containsKey(questId)) {
      return false;
    }

    // Check minDay
    if (state.day < quest.minDay) {
      return false;
    }

    // Check requirements
    if (quest.requirementsAny.isNotEmpty) {
      bool anyMet = false;
      for (final req in quest.requirementsAny) {
        // Simple flag check
        if (req.startsWith('flag:')) {
          final flag = req.substring(5);
          if (state.flags.contains(flag)) {
            anyMet = true;
            break;
          }
        }
      }
      if (!anyMet && quest.requirementsAny.isNotEmpty) {
        return false;
      }
    }

    // Initialize quest state
    state.quests[questId] = QuestState(stage: 0, startDay: state.day);

    // Log
    state.addLog('📋 Nhận nhiệm vụ mới: ${quest.name}');

    GameLogger.game('Quest started: $questId');
    return true;
  }

  /// Advance quest to next stage
  bool advanceQuest(String questId, GameState state) {
    final quest = data.getQuest(questId);
    final questState = state.quests[questId];

    if (quest == null || questState == null) return false;

    final nextStage = questState.stage + 1;
    if (nextStage >= quest.stages.length) {
      return false;
    }

    questState.stage = nextStage;

    // Apply stage unlocks
    final stage = quest.getStage(nextStage);
    if (stage?.unlocks != null) {
      for (final unlock in stage!.unlocks!) {
        state.flags.add(unlock);
      }
    }

    // Check for ending
    if (stage?.isEnding ?? false) {
      state.gameOver = true;
      state.endingType = '${questId}_stage_$nextStage';
      state.addLog('🎉 Kết thúc game: ${stage!.title}');
    }

    state.addLog('📋 ${quest.name}: ${stage?.title ?? "Giai đoạn $nextStage"}');

    GameLogger.game('Quest advanced: $questId to stage $nextStage');
    return true;
  }

  /// Set quest to specific stage
  bool setQuestStage(String questId, int stage, GameState state) {
    final quest = data.getQuest(questId);
    if (quest == null) return false;

    // Auto-start if not active
    if (!state.quests.containsKey(questId)) {
      state.quests[questId] = QuestState(stage: 0, startDay: state.day);
    }

    final questState = state.quests[questId]!;
    if (stage >= quest.stages.length) return false;

    questState.stage = stage;

    // Apply stage unlocks
    final stageDef = quest.getStage(stage);
    if (stageDef?.unlocks != null) {
      for (final unlock in stageDef!.unlocks!) {
        state.flags.add(unlock);
      }
    }

    // Check for ending
    if (stageDef?.isEnding ?? false) {
      state.gameOver = true;
      state.endingType = '${questId}_stage_$stage';
      state.addLog('🎉 Kết thúc: ${stageDef!.title}');
    }

    GameLogger.game('Quest set: $questId to stage $stage');
    return true;
  }

  /// Check quest completion conditions
  void checkQuestProgress(GameState state) {
    for (final questId in state.quests.keys.toList()) {
      final quest = data.getQuest(questId);
      final questState = state.quests[questId];

      if (quest == null || questState == null) continue;

      // Check completion condition
      if (quest.completionCondition != null) {
        final condition = quest.completionCondition!;
        
        // Simple condition check
        if (condition.startsWith('flag:')) {
          final flag = condition.substring(5);
          if (state.flags.contains(flag)) {
            advanceQuest(questId, state);
          }
        } else if (condition.startsWith('day>=')) {
          final day = int.tryParse(condition.substring(5)) ?? 999;
          if (state.day >= day) {
            advanceQuest(questId, state);
          }
        }
      }
    }
  }

  /// Get active quests
  List<(QuestDef, QuestState)> getActiveQuests(GameState state) {
    final result = <(QuestDef, QuestState)>[];
    
    for (final entry in state.quests.entries) {
      final quest = data.getQuest(entry.key);
      if (quest != null) {
        result.add((quest, entry.value));
      }
    }

    return result;
  }

  /// Get current stage info for a quest
  QuestStage? getCurrentStage(String questId, GameState state) {
    final quest = data.getQuest(questId);
    final questState = state.quests[questId];

    if (quest == null || questState == null) return null;

    return quest.getStage(questState.stage);
  }

  /// Check for quests that should auto-start
  void checkAutoStartQuests(GameState state) {
    for (final quest in data.quests.values) {
      // Skip already active
      if (state.quests.containsKey(quest.id)) continue;

      // Check minDay
      if (state.day < quest.minDay) continue;

      // Check if has startEventId (means it needs to be triggered by event)
      if (quest.startEventId != null) continue;

      // Check requirements
      bool canStart = true;
      if (quest.requirementsAny.isNotEmpty) {
        canStart = false;
        for (final req in quest.requirementsAny) {
          if (req.startsWith('flag:')) {
            final flag = req.substring(5);
            if (state.flags.contains(flag)) {
              canStart = true;
              break;
            }
          }
        }
      }

      if (canStart) {
        startQuest(quest.id, state);
      }
    }
  }
}

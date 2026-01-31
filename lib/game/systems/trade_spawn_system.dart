import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../data/repositories/game_data_repo.dart';
import '../engine/requirement_engine.dart';
import '../state/game_state.dart';

/// System for spawning traders based on trade_system.json rules
class TradeSpawnSystem {
  final GameDataRepository data;
  final RequirementEngine requirementEngine;
  final GameRng rng;

  TradeSpawnSystem({
    required this.data,
    required this.requirementEngine,
    required this.rng,
  });

  void runDailySpawns(GameState state, {String context = 'base'}) {
    final spawns = data.tradeSystem['traderSpawns'] as List<dynamic>? ?? [];
    if (spawns.isEmpty) return;

    for (final entry in spawns) {
      if (entry is! Map) continue;
      if (!_matchesContext(entry, context)) continue;
      final chance = (entry['chancePerDay'] as num?)?.toDouble();
      if (chance == null || chance <= 0) continue;

      final minDay = (entry['minDay'] as num?)?.toInt() ?? 1;
      if (state.day < minDay) continue;

      final blockedFlag = entry['blockedIfFlag']?.toString();
      if (blockedFlag != null && state.flags.contains(blockedFlag)) {
        continue;
      }

      final requirements = entry['requirements'];
      if (requirements != null && !requirementEngine.check(requirements, state)) {
        continue;
      }

      final roll = rng.nextDouble();
      if (roll > chance) continue;

      final eventId = entry['eventId']?.toString() ?? entry['event']?.toString();
      if (eventId != null && eventId.isNotEmpty) {
        state.eventQueue.add(eventId);
        GameLogger.game('Trader spawn: queued $eventId');
        continue;
      }

      final factionId = entry['factionId']?.toString();
      if (factionId != null && factionId.isNotEmpty) {
        state.flags.add('trader_present:$factionId');
        GameLogger.game('Trader spawn: flag trader_present:$factionId');
      }
    }
  }

  bool _matchesContext(Map entry, String context) {
    final raw = entry['context'] ?? entry['contexts'];
    final contexts = <String>[];
    if (raw is String) {
      contexts.add(raw);
    } else if (raw is List) {
      contexts.addAll(raw.map((e) => e.toString()));
    }
    if (contexts.isEmpty) return false;
    return contexts.any((c) => c == context || context.startsWith('$c:'));
  }
}

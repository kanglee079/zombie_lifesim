import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';

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

  NightSystem({required this.data, required this.rng});

  /// Resolve night threats
  NightResult resolve(GameState state) {
    final balance = data.balance;
    final nightModel = balance.raw['nightThreatModel'] as Map<String, dynamic>? ?? {};

    // Get night parameters
    final formula = nightModel['hordeFormula'] as String? ?? 'day + noise - defense';
    final floor = (nightModel['floor'] as num?)?.toInt() ?? 0;
    final cap = (nightModel['cap'] as num?)?.toInt() ?? 30;
    final damagePerZombie = nightModel['damagePerZombie'] as num? ?? 2;
    final breachChance = nightModel['breachAtHordeOver'] as num? ?? 20;

    // Calculate threat level
    int threatLevel = _calculateThreat(formula, state);
    threatLevel = Clamp.i(threatLevel, floor, cap);

    // Calculate defense
    final defense = state.baseStats.defense;
    final effectiveThreat = Clamp.i((threatLevel - defense * 0.5).round(), 0, cap);

    // Check for breach
    final wasAttacked = effectiveThreat > breachChance;

    int damage = 0;
    int zombiesKilled = 0;
    final lostItems = <String>[];

    if (wasAttacked) {
      // Calculate damage
      final zombiesBreached = Clamp.i((effectiveThreat - breachChance).round(), 1, 20);
      damage = (zombiesBreached * damagePerZombie).round();

      // Apply damage to player
      state.playerStats.hp = Clamp.hp(state.playerStats.hp - damage);

      // Calculate zombies killed by defense
      zombiesKilled = Clamp.i((defense * 0.3).round(), 0, threatLevel);

      // Chance to lose items
      if (rng.nextBool(0.2 * zombiesBreached)) {
        // Lose a random item
        if (state.inventory.isNotEmpty) {
          final lostIndex = rng.nextInt(state.inventory.length);
          final lostItem = state.inventory[lostIndex];
          lostItems.add(lostItem.itemId);
          state.inventory.removeAt(lostIndex);
        }
      }
    }

    // Reduce noise
    state.baseStats.noise = Clamp.stat(state.baseStats.noise - 10, 0, 100);

    // Build narrative
    final narrative = _buildNarrative(
      threatLevel: threatLevel,
      wasAttacked: wasAttacked,
      damage: damage,
      zombiesKilled: zombiesKilled,
      lostItems: lostItems,
    );

    state.addLog(narrative);

    GameLogger.game('Night: threat=$threatLevel, attacked=$wasAttacked, damage=$damage');

    return NightResult(
      wasAttacked: wasAttacked,
      damage: damage,
      zombiesKilled: zombiesKilled,
      lostItems: lostItems,
      narrative: narrative,
    );
  }

  /// Calculate threat level from formula
  int _calculateThreat(String formula, GameState state) {
    // Simple formula parser: day + noise - defense
    int threat = state.day;
    threat += (state.baseStats.noise * 0.5).round();
    threat -= (state.baseStats.defense * 0.3).round();
    
    // Add signal heat contribution
    threat += (state.signalHeat * 0.2).round();
    
    return threat;
  }

  /// Build narrative text
  String _buildNarrative({
    required int threatLevel,
    required bool wasAttacked,
    required int damage,
    required int zombiesKilled,
    required List<String> lostItems,
  }) {
    final buffer = StringBuffer();

    buffer.write('🌙 Đêm qua');

    if (threatLevel <= 5) {
      buffer.write(', mọi thứ yên tĩnh. ');
    } else if (threatLevel <= 15) {
      buffer.write(', có tiếng động ở xa. ');
    } else {
      buffer.write(', zombie vây quanh căn cứ. ');
    }

    if (wasAttacked) {
      buffer.write('💀 Căn cứ bị tấn công! ');
      if (damage > 0) {
        buffer.write('Bạn bị thương, mất $damage HP. ');
      }
      if (zombiesKilled > 0) {
        buffer.write('Tiêu diệt $zombiesKilled zombie. ');
      }
      if (lostItems.isNotEmpty) {
        buffer.write('Mất ${lostItems.length} vật phẩm trong hỗn loạn. ');
      }
    } else {
      if (threatLevel > 10) {
        buffer.write('Hàng phòng thủ đã giữ vững. ');
      }
      if (zombiesKilled > 0) {
        buffer.write('Tiêu diệt $zombiesKilled zombie. ');
      }
    }

    return buffer.toString().trim();
  }
}

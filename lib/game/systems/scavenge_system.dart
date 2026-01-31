import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import '../engine/loot_engine.dart';
import '../engine/effect_engine.dart';

/// Scavenge time option
enum ScavengeTime {
  quick(1, 30, 0.6, 0.5),
  normal(2, 60, 1.0, 1.0),
  thorough(4, 120, 1.5, 1.8);

  final int timeSlots;
  final int minutes;
  final double lootMult;
  final double riskMult;

  const ScavengeTime(this.timeSlots, this.minutes, this.lootMult, this.riskMult);
}

/// Scavenge style option
enum ScavengeStyle {
  stealth(0.6, 0.7, 1.5),
  balanced(1.0, 1.0, 1.0),
  aggressive(1.4, 1.5, 0.7);

  final double lootMult;
  final double riskMult;
  final double stealthMult;

  const ScavengeStyle(this.lootMult, this.riskMult, this.stealthMult);
}

/// Result of a scavenge run
class ScavengeResult {
  final bool success;
  final Map<String, int> loot;
  final int hpLost;
  final int infectionGained;
  final bool wasAmbushed;
  final String narrative;
  final int epGained;

  const ScavengeResult({
    required this.success,
    required this.loot,
    required this.hpLost,
    required this.infectionGained,
    required this.wasAmbushed,
    required this.narrative,
    required this.epGained,
  });
}

/// System for handling scavenge runs
class ScavengeSystem {
  final GameDataRepository data;
  final LootEngine lootEngine;
  final EffectEngine effectEngine;
  final GameRng rng;

  ScavengeSystem({
    required this.data,
    required this.lootEngine,
    required this.effectEngine,
    required this.rng,
  });

  /// Execute a scavenge run
  ScavengeResult execute({
    required String locationId,
    required ScavengeTime time,
    required ScavengeStyle style,
    required GameState state,
  }) {
    final location = data.getLocation(locationId);
    if (location == null) {
      GameLogger.warn('Unknown location: $locationId');
      return ScavengeResult(
        success: false,
        loot: {},
        hpLost: 0,
        infectionGained: 0,
        wasAmbushed: false,
        narrative: 'Không tìm thấy địa điểm.',
        epGained: 0,
      );
    }

    final balance = data.balance;
    final dayMult = balance.getMultiplier('scavengeLoot', state.day);
    final riskMult = balance.getMultiplier('scavengeRisk', state.day);

    // Get location state
    final locState = state.locationStates.putIfAbsent(
      locationId,
      () => LocationState(),
    );

    // Calculate depletion modifier
    final depletionMod = _getDepletionModifier(locState.depletion);

    // Calculate final loot multiplier
    final finalLootMult = dayMult * time.lootMult * style.lootMult * depletionMod.lootMult;

    // Calculate final risk
    final baseRisk = location.baseRisk / 100.0;
    final finalRisk = (baseRisk * riskMult * time.riskMult * style.riskMult * depletionMod.riskMult)
        .clamp(0.0, 0.95);

    // Roll for danger
    final dangerRoll = rng.nextDouble();
    final wasAmbushed = dangerRoll < finalRisk;

    int hpLost = 0;
    int infectionGained = 0;

    if (wasAmbushed) {
      // Calculate damage based on combat skill
      final combatSkill = state.playerSkills.combat;
      final baseDamage = rng.range(5, 20);
      hpLost = (baseDamage * (1.0 - combatSkill * 0.05)).round().clamp(1, 50);

      // Chance for infection
      if (rng.nextBool(0.3)) {
        infectionGained = rng.range(5, 15);
      }
    }

    // Roll for loot
    final lootTableId = location.lootTable ?? 'default_scavenge';
    final loot = lootEngine.rollLoot(
      lootTableId,
      rolls: (time.timeSlots * 2 * finalLootMult).round().clamp(1, 10),
      lootMult: finalLootMult,
    );

    // Add loot to inventory
    for (final entry in loot.entries) {
      effectEngine.addItemToInventory(state, entry.key, entry.value);
    }

    // Update depletion
    locState.depletion = Clamp.depletion(locState.depletion + 1);
    locState.visitCount++;
    locState.lastVisitDay = state.day;

    // Award exploration points
    final epGained = rng.range(1, 3);
    state.baseStats.explorationPoints += epGained;

    // Apply damage
    state.playerStats.hp = Clamp.hp(state.playerStats.hp - hpLost);
    state.playerStats.infection = Clamp.infection(state.playerStats.infection + infectionGained);

    // Build narrative
    final narrative = _buildNarrative(
      location: location.name,
      time: time,
      style: style,
      wasAmbushed: wasAmbushed,
      lootCount: loot.values.fold(0, (a, b) => a + b),
      hpLost: hpLost,
      infectionGained: infectionGained,
    );

    state.addLog(narrative);

    GameLogger.game('Scavenge: $locationId, loot: ${loot.length} types, hp lost: $hpLost');

    return ScavengeResult(
      success: true,
      loot: loot,
      hpLost: hpLost,
      infectionGained: infectionGained,
      wasAmbushed: wasAmbushed,
      narrative: narrative,
      epGained: epGained,
    );
  }

  /// Get depletion modifier
  ({double lootMult, double riskMult, double rareMult}) _getDepletionModifier(int depletion) {
    if (depletion <= 0) {
      return (lootMult: 1.0, riskMult: 1.0, rareMult: 1.0);
    } else if (depletion <= 2) {
      return (lootMult: 0.85, riskMult: 1.0, rareMult: 0.9);
    } else if (depletion <= 4) {
      return (lootMult: 0.7, riskMult: 1.1, rareMult: 0.7);
    } else if (depletion <= 6) {
      return (lootMult: 0.5, riskMult: 1.2, rareMult: 0.4);
    } else {
      return (lootMult: 0.25, riskMult: 1.3, rareMult: 0.1);
    }
  }

  /// Build narrative text
  String _buildNarrative({
    required String location,
    required ScavengeTime time,
    required ScavengeStyle style,
    required bool wasAmbushed,
    required int lootCount,
    required int hpLost,
    required int infectionGained,
  }) {
    final buffer = StringBuffer();

    // Opening
    buffer.write('Bạn đã khám phá $location ');
    switch (time) {
      case ScavengeTime.quick:
        buffer.write('trong thời gian ngắn. ');
        break;
      case ScavengeTime.normal:
        buffer.write('trong khoảng một giờ. ');
        break;
      case ScavengeTime.thorough:
        buffer.write('một cách kỹ lưỡng. ');
        break;
    }

    // Ambush
    if (wasAmbushed) {
      buffer.write('💀 Bạn đã bị zombie tấn công! ');
      if (hpLost > 0) {
        buffer.write('Mất $hpLost HP. ');
      }
      if (infectionGained > 0) {
        buffer.write('🦠 Nhiễm trùng +$infectionGained. ');
      }
    }

    // Loot
    if (lootCount > 0) {
      buffer.write('📦 Thu thập được $lootCount vật phẩm.');
    } else {
      buffer.write('Không tìm thấy gì hữu ích.');
    }

    return buffer.toString();
  }

  /// Get available locations for scavenging
  List<String> getAvailableLocations(GameState state) {
    final available = <String>[];

    for (final districtEntry in data.districts.entries) {
      final districtId = districtEntry.key;
      final district = districtEntry.value;
      final districtState = state.districtStates[districtId];

      // Check if district is unlocked
      final isUnlocked = district.startUnlocked || (districtState?.unlocked ?? false);
      if (!isUnlocked) continue;

      // Check minDay
      if (state.day < district.minDay) continue;

      // Add all locations in this district
      available.addAll(district.locationIds);
    }

    return available;
  }
}

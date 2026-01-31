import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../../data/models/location_def.dart';
import '../state/game_state.dart';
import '../engine/loot_engine.dart';
import '../engine/effect_engine.dart';
import '../engine/depletion_engine.dart';
import '../engine/requirement_engine.dart';

/// Scavenge time option
enum ScavengeTime {
  quick(30),
  normal(60),
  long(120);

  final int minutes;

  const ScavengeTime(this.minutes);
}

/// Scavenge style option
enum ScavengeStyle {
  stealth,
  balanced,
  greedy,
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
  final DepletionEngine depletionEngine;
  final RequirementEngine requirementEngine;
  final GameRng rng;

  ScavengeSystem({
    required this.data,
    required this.lootEngine,
    required this.effectEngine,
    required this.depletionEngine,
    required this.requirementEngine,
    required this.rng,
  });

  ScavengeSession startSession({
    required String locationId,
    required ScavengeTime time,
    required ScavengeStyle style,
    required GameState state,
  }) {
    final timeId = _mapTimeOption(time);
    final styleId = _mapStyleOption(style);
    final scavengeModel =
        data.balance.raw['scavengeModel'] as Map<String, dynamic>? ?? {};
    final timeOptions = scavengeModel['timeOptions'] as Map<String, dynamic>? ?? {};
    final timeConfig = timeOptions[timeId] as Map<String, dynamic>? ?? {};
    final events = (timeConfig['events'] as num?)?.toInt() ?? 2;

    return ScavengeSession(
      locationId: locationId,
      timeOption: timeId,
      style: styleId,
      remainingSteps: events,
      totalSteps: events,
    );
  }

  void finishSession(ScavengeSession session, GameState state) {
    final location = data.getLocation(session.locationId);
    final locState = state.locationStates.putIfAbsent(
      session.locationId,
      () => LocationState(depletion: location?.depletionStart ?? 0),
    );

    depletionEngine.applyVisit(
      locState: locState,
      timeOption: session.timeOption,
      style: session.style,
      state: state,
    );

    final scavengeModel =
        data.balance.raw['scavengeModel'] as Map<String, dynamic>? ?? {};
    final timeOptions = scavengeModel['timeOptions'] as Map<String, dynamic>? ?? {};
    final styleOptions = scavengeModel['styles'] as Map<String, dynamic>? ?? {};

    final timeConfig = timeOptions[session.timeOption] as Map<String, dynamic>? ?? {};
    final styleConfig = styleOptions[session.style] as Map<String, dynamic>? ?? {};

    final fatigueDelta = (timeConfig['fatigueDelta'] as num?)?.toInt() ?? 0;
    final noiseDelta = (styleConfig['noiseDelta'] as num?)?.toInt() ?? 0;

    if (fatigueDelta != 0) {
      state.playerStats.fatigue = Clamp.stat(state.playerStats.fatigue + fatigueDelta);
    }
    if (noiseDelta != 0) {
      state.baseStats.noise = Clamp.stat(state.baseStats.noise + noiseDelta, 0, 100);
    }

    final locationName = location?.name ?? session.locationId;
    state.addLog('🧭 Kết thúc khám phá $locationName.');
  }

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
    final dayLootMult = balance.getMultiplier('scavengeLoot', state.day);
    final dayRiskMult = balance.getMultiplier('scavengeRisk', state.day);
    final scavengeModel =
        balance.raw['scavengeModel'] as Map<String, dynamic>? ?? {};
    final timeOptions = scavengeModel['timeOptions'] as Map<String, dynamic>? ?? {};
    final styleOptions = scavengeModel['styles'] as Map<String, dynamic>? ?? {};
    final timeConfig = timeOptions[_mapTimeOption(time)] as Map<String, dynamic>? ?? {};
    final styleConfig = styleOptions[_mapStyleOption(style)] as Map<String, dynamic>? ?? {};
    final timeLootMult = (timeConfig['lootMult'] as num?)?.toDouble() ?? 1.0;
    final timeRiskMult = (timeConfig['riskMult'] as num?)?.toDouble() ?? 1.0;
    final styleLootMult = (styleConfig['lootMult'] as num?)?.toDouble() ?? 1.0;
    final styleRiskMult = (styleConfig['riskMult'] as num?)?.toDouble() ?? 1.0;
    final timeSlots = (timeConfig['events'] as num?)?.toInt() ?? 2;

    // Get location state
    final locState = state.locationStates.putIfAbsent(
      locationId,
      () => LocationState(depletion: location.depletionStart),
    );

    // Calculate depletion modifier
    final depletionMod = depletionEngine.getModifiers(locState.depletion);

    // Calculate final loot multiplier
    final finalLootMult = dayLootMult * timeLootMult * styleLootMult * depletionMod.lootMult;

    // Calculate final risk
    final baseRisk = location.baseRisk / 100.0;
    final finalRisk = (baseRisk *
            dayRiskMult *
            timeRiskMult *
            styleRiskMult *
            depletionMod.riskMult)
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
      hpLost = Clamp.i((baseDamage * (1.0 - combatSkill * 0.05)).round(), 1, 50);

      // Chance for infection
      if (rng.nextBool(0.3)) {
        infectionGained = rng.range(5, 15);
      }
    }

    // Roll for loot
    final lootTableId = location.lootTable ?? 'default_scavenge';
    final loot = lootEngine.rollLoot(
      lootTableId,
      rolls: Clamp.i((timeSlots * 2 * finalLootMult).round(), 1, 10),
      lootMult: finalLootMult,
      rareMult: depletionMod.rareMult,
    );

    // Add loot to inventory
    for (final entry in loot.entries) {
      effectEngine.addItemToInventory(state, entry.key, entry.value);
    }

    // Update depletion based on system rules
    depletionEngine.applyVisit(
      locState: locState,
      timeOption: _mapTimeOption(time),
      style: _mapStyleOption(style),
      state: state,
    );

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

  String _mapTimeOption(ScavengeTime time) {
    switch (time) {
      case ScavengeTime.quick:
        return 'quick';
      case ScavengeTime.normal:
        return 'normal';
      case ScavengeTime.long:
        return 'long';
    }
  }

  String _mapStyleOption(ScavengeStyle style) {
    switch (style) {
      case ScavengeStyle.stealth:
        return 'stealth';
      case ScavengeStyle.balanced:
        return 'balanced';
      case ScavengeStyle.greedy:
        return 'greedy';
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
      case ScavengeTime.long:
        buffer.write('trong thời gian dài. ');
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

      // Check district requirements
      if (district.requirements.isNotEmpty &&
          !requirementEngine.check(district.requirements, state)) {
        continue;
      }

      // Add all locations in this district
      for (final locationId in district.locationIds) {
        final location = data.getLocation(locationId);
        if (location == null) continue;
        if (!_isLocationUnlocked(location, state, district)) continue;
        available.add(locationId);
      }
    }

    return available;
  }

  bool _isLocationUnlocked(LocationDef location, GameState state, dynamic district) {
    final unlock = location.unlock;
    if (unlock == null || unlock.isEmpty) return true;

    if (unlock['start'] == true) return true;

    final flag = unlock['flag']?.toString();
    if (flag != null && flag.isNotEmpty) {
      return state.flags.contains(flag);
    }

    final districtId = unlock['district']?.toString();
    if (districtId != null && districtId.isNotEmpty) {
      final stateInfo = state.districtStates[districtId];
      return district.startUnlocked || (stateInfo?.unlocked ?? false);
    }

    return true;
  }
}

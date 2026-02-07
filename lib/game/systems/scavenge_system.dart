import '../../core/rng.dart';
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
    final timeOptions =
        scavengeModel['timeOptions'] as Map<String, dynamic>? ?? {};
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
    final isFirstVisit = !state.locationStates.containsKey(session.locationId);
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
    final timeOptions =
        scavengeModel['timeOptions'] as Map<String, dynamic>? ?? {};
    final styleOptions = scavengeModel['styles'] as Map<String, dynamic>? ?? {};

    final timeConfig =
        timeOptions[session.timeOption] as Map<String, dynamic>? ?? {};
    final styleConfig =
        styleOptions[session.style] as Map<String, dynamic>? ?? {};

    final fatigueDelta = (timeConfig['fatigueDelta'] as num?)?.toInt() ?? 0;
    final noiseDelta = (styleConfig['noiseDelta'] as num?)?.toInt() ?? 0;

    if (fatigueDelta != 0) {
      state.playerStats.fatigue =
          Clamp.stat(state.playerStats.fatigue + fatigueDelta);
    }
    if (noiseDelta != 0) {
      state.baseStats.noise =
          Clamp.stat(state.baseStats.noise + noiseDelta, 0, 100);
    }

    final locationName = location?.name ?? session.locationId;
    state.addLog('🧭 Kết thúc khám phá $locationName.');

    if (isFirstVisit) {
      final epGain = session.timeOption == 'long' ? 2 : 1;
      state.baseStats.explorationPoints =
          Clamp.i(state.baseStats.explorationPoints + epGain, 0, 9999);
      state.addLog('🧭 Khám phá khu mới: +$epGain EP.');
    }
  }

  // Note: Legacy execute() method removed - use startSession()/finishSession() instead

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

  /// Get available locations for scavenging
  List<String> getAvailableLocations(GameState state) {
    final available = <String>[];

    for (final districtEntry in data.districts.entries) {
      final districtId = districtEntry.key;
      final district = districtEntry.value;
      final districtState = state.districtStates[districtId];

      // Check if district is unlocked
      final isUnlocked =
          district.startUnlocked || (districtState?.unlocked ?? false);
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

  bool _isLocationUnlocked(
      LocationDef location, GameState state, dynamic district) {
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

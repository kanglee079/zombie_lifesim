import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/models/npc_def.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';

/// System for managing NPC party members
class NpcSystem {
  final GameDataRepository data;
  final GameRng rng;

  NpcSystem({required this.data, required this.rng});

  /// Generate a new NPC from template
  PartyMember generateNpc({String? templateId}) {
    // Get template
    NpcTemplate? template;
    if (templateId != null) {
      template = data.getNpcTemplate(templateId);
    }
    template ??= data.npcTemplates.values.isNotEmpty
        ? data.npcTemplates.values.first
        : null;

    if (template == null) {
      // Fallback to default NPC
      return PartyMember(
        id: 'npc_${rng.nextInt(10000)}',
        name: 'Survivor',
        role: 'scavenger',
        isPlayer: false,
        hp: 100,
        morale: 50,
        traits: [],
        skills: {'combat': 2, 'stealth': 2, 'medical': 2, 'craft': 2, 'scavenge': 2},
      );
    }

    // Generate name
    final namePool = template.namePool ?? ['Survivor', 'Stranger', 'Wanderer'];
    final name = namePool[rng.nextInt(namePool.length)];

    // Generate role
    final rolePool = template.rolePool ?? ['scavenger', 'fighter', 'medic'];
    final role = rolePool[rng.nextInt(rolePool.length)];

    // Generate traits
    final traits = _generateTraits(template);

    // Generate skills
    final skills = <String, int>{};
    for (final entry in template.skillRanges.entries) {
      skills[entry.key] = rng.range(entry.value.min, entry.value.max);
    }

    // Base stats
    final baseStats = template.baseStats;
    final hp = baseStats['hp'] as int? ?? 100;
    final morale = baseStats['morale'] as int? ?? 50;

    return PartyMember(
      id: 'npc_${rng.nextInt(10000)}',
      name: name,
      role: role,
      isPlayer: false,
      hp: hp,
      morale: morale,
      traits: traits,
      skills: skills,
    );
  }

  /// Generate traits for NPC
  List<String> _generateTraits(NpcTemplate template) {
    final traitPool = template.traitPool;
    int pick = traitPool.pick;
    if (traitPool.pickMin != null && traitPool.pickMax != null) {
      pick = rng.range(traitPool.pickMin!, traitPool.pickMax!);
    }
    
    // Get all available traits
    final allTraits = data.traits.values.toList();
    if (allTraits.isEmpty) return [];

    // Filter by weight and rarity
    final weights = <double>[];
    final candidates = <TraitDef>[];

    final fixedTraits = traitPool.fixedTraits.isNotEmpty ? traitPool.fixedTraits.toSet() : null;

    for (final trait in allTraits) {
      if (fixedTraits != null && !fixedTraits.contains(trait.id)) {
        continue;
      }

      // Check rarity filter
      if (traitPool.rarities.isNotEmpty && !traitPool.rarities.contains(trait.rarity)) {
        continue;
      }

      // Get weight
      double weight = 1.0;
      final traitWeights = traitPool.weights[trait.category];
      if (traitWeights != null && traitWeights.containsKey(trait.id)) {
        weight = traitWeights[trait.id]!;
      } else if (traitPool.categoryWeights.containsKey(trait.category)) {
        weight = traitPool.categoryWeights[trait.category]!;
      }

      candidates.add(trait);
      weights.add(weight);
    }

    if (candidates.isEmpty) return [];

    // Select traits
    final selected = <String>[];
    for (int i = 0; i < pick && candidates.isNotEmpty; i++) {
      final index = rng.weightedSelect(weights);
      if (index >= 0 && index < candidates.length) {
        selected.add(candidates[index].id);
        // Remove to avoid duplicates
        candidates.removeAt(index);
        weights.removeAt(index);
      }
    }

    // Check for conflicts
    return _resolveConflicts(selected);
  }

  /// Resolve trait conflicts
  List<String> _resolveConflicts(List<String> traitIds) {
    final result = <String>[];

    for (final traitId in traitIds) {
      final trait = data.getTrait(traitId);
      if (trait == null) continue;

      // Check if conflicts with any already selected trait
      bool conflicts = false;
      for (final existingId in result) {
        final existing = data.getTrait(existingId);
        if (existing != null) {
          // Check tag conflicts from trait_conflicts.json
          conflicts = _checkTagConflict(trait.tags, existing.tags);
          if (conflicts) break;
        }
      }

      if (!conflicts) {
        result.add(traitId);
      }
    }

    return result;
  }

  /// Check if two trait tag sets conflict
  bool _checkTagConflict(List<String> tags1, List<String> tags2) {
    // Use hardConflicts from data
    final conflicts = data.traitConflicts['hardConflicts'] as List<dynamic>? ?? [];
    
    for (final conflict in conflicts) {
      final tagA = conflict['tagA'] as String?;
      final tagB = conflict['tagB'] as String?;
      if (tagA != null && tagB != null) {
        if ((tags1.contains(tagA) && tags2.contains(tagB)) ||
            (tags1.contains(tagB) && tags2.contains(tagA))) {
          return true;
        }
      }
    }
    return false;
  }

  /// Calculate party tension
  int calculateTension(GameState state) {
    int tension = 0;
    final tensionModel = data.traitConflicts;

    // Base daily tension
    tension += (tensionModel['dailyBase'] as num?)?.toInt() ?? 5;

    // Resource stress
    final food = state.inventory
        .where((s) => data.getItem(s.itemId)?.hasTag('food') ?? false)
        .fold(0, (sum, s) => sum + s.qty);
    if (food < state.party.length * 2) {
      tension += (tensionModel['resourceStress'] as num?)?.toInt() ?? 10;
    }

    // Crowding
    final partySize = state.party.length;
    if (partySize > 4) {
      tension += (partySize - 4) * ((tensionModel['crowding'] as num?)?.toInt() ?? 3);
    }

    // Tag pair rules
    tension += _calculateTagTension(state, tensionModel);

    // Morale effect
    final avgMorale = state.party.fold(0, (sum, p) => sum + p.morale) / state.party.length;
    tension -= (avgMorale * ((tensionModel['moraleEffect'] as num?)?.toDouble() ?? 0.1)).round();

    return Clamp.tension(tension);
  }

  /// Calculate tension from trait tag pairs
  int _calculateTagTension(GameState state, Map<String, dynamic> tensionModel) {
    int tension = 0;
    final rules = tensionModel['tagPairRules'] as List<dynamic>? ?? [];

    // Get all party member tags
    final memberTags = <String, List<String>>{};
    for (final member in state.party) {
      memberTags[member.id] = [];
      for (final traitId in member.traits) {
        final trait = data.getTrait(traitId);
        if (trait != null) {
          memberTags[member.id]!.addAll(trait.tags);
        }
      }
    }

    // Check each pair
    final members = state.party.toList();
    for (int i = 0; i < members.length; i++) {
      for (int j = i + 1; j < members.length; j++) {
        final tags1 = memberTags[members[i].id] ?? [];
        final tags2 = memberTags[members[j].id] ?? [];

        for (final rule in rules) {
          final tagA = rule['tagA'] as String?;
          final tagB = rule['tagB'] as String?;
          final delta = (rule['tensionDelta'] as num?)?.toInt() ?? 0;

          if (tagA != null && tagB != null) {
            if ((tags1.contains(tagA) && tags2.contains(tagB)) ||
                (tags1.contains(tagB) && tags2.contains(tagA))) {
              tension += delta;
            }
          }
        }
      }
    }

    return tension;
  }

  /// Update party morale
  void updatePartyMorale(GameState state) {
    for (final member in state.party) {
      // Base morale decay
      int delta = -1;

      // Food bonus
      final hasFood = state.inventory.any((s) => 
          (data.getItem(s.itemId)?.hasTag('food') ?? false) && s.qty > 0);
      if (hasFood) delta += 2;

      // Safe base bonus
      if (state.baseStats.defense >= 20) delta += 1;

      // Apply tension penalty
      if (state.tension > 50) delta -= (state.tension - 50) ~/ 20;

      member.morale = Clamp.morale(member.morale + delta);
    }
  }

  /// Check for party events (conflicts, etc.)
  List<String> checkPartyEvents(GameState state) {
    final events = <String>[];

    // Check for betrayal
    if (state.tension >= 80) {
      for (final member in state.party.where((p) => !p.isPlayer)) {
        if (member.morale < 20 && rng.nextBool(0.1)) {
          events.add('betrayal_${member.id}');
        }
      }
    }

    // Check for conflicts
    if (state.tension >= 60) {
      if (rng.nextBool(0.2)) {
        events.add('party_conflict');
      }
    }

    return events;
  }

  /// Remove party member
  void removeMember(String memberId, GameState state) {
    state.party.removeWhere((m) => m.id == memberId);
    GameLogger.game('Party member removed: $memberId');
  }

  /// Get party consumption (food needed per day)
  int getPartyConsumption(GameState state) {
    int consumption = 0;
    for (final member in state.party) {
      consumption += 1;
      // Trait modifiers would apply here
    }
    return consumption;
  }
}

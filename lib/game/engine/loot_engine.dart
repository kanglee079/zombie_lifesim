import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';

/// Engine for rolling loot from loot tables
class LootEngine {
  final GameDataRepository data;
  final GameRng rng;

  LootEngine({required this.data, required this.rng});

  /// Roll loot from a loot table
  Map<String, int> rollLoot(
    String tableId, {
    int rolls = 1,
    double lootMult = 1.0,
    double rareMult = 1.0,
  }) {
    final loot = <String, int>{};
    final table = data.getLootTable(tableId);

    if (table == null) {
      GameLogger.warn('Unknown loot table: $tableId');
      return loot;
    }

    // Use table's default rolls if caller passes 0, otherwise use caller's rolls
    final baseRolls = rolls > 0 ? rolls : table.rolls;
    final totalRolls = Clamp.i((baseRolls * lootMult).round(), 1, 20);

    for (int i = 0; i < totalRolls; i++) {
      final item = _rollSingleItem(table.entries, rareMult);
      if (item != null) {
        loot[item.itemId] = (loot[item.itemId] ?? 0) + item.qty;
      }
    }

    return loot;
  }

  /// Roll a single item from entries
  _LootResult? _rollSingleItem(List<dynamic> entries, double rareMult) {
    if (entries.isEmpty) return null;

    // Build weight array
    final weights = <double>[];
    final items = <dynamic>[];

    for (final entry in entries) {
      double weight = (entry.w as num?)?.toDouble() ?? 1.0;

      // Adjust weight for rare items
      final itemId = entry.item as String?;
      if (itemId != null) {
        final item = data.getItem(itemId);
        if (item != null) {
          if (item.rarity == 'rare' ||
              item.rarity == 'epic' ||
              item.rarity == 'legendary') {
            weight *= rareMult;
          }
        }
      }

      weights.add(weight);
      items.add(entry);
    }

    // Select by weighted random
    final index = rng.weightedSelect(weights);
    if (index < 0 || index >= items.length) {
      return null;
    }

    final selected = items[index];
    final itemId = selected.item as String?;
    if (itemId == null) return null;

    // Determine quantity
    final min = (selected.min as num?)?.toInt() ?? 1;
    final max = (selected.max as num?)?.toInt() ?? 1;
    final qty = rng.range(min, max);

    if (qty <= 0) return null;

    return _LootResult(itemId: itemId, qty: qty);
  }

  /// Roll loot based on context (location type)
  Map<String, int> rollContextualLoot({
    required String locationId,
    required int rolls,
    required double dayMult,
    required double depletionMult,
  }) {
    final location = data.getLocation(locationId);
    if (location == null) {
      return rollLoot('default_scavenge', rolls: rolls);
    }

    // Get loot table from location or use default
    final tableId = location.lootTable ?? 'default_scavenge';

    return rollLoot(
      tableId,
      rolls: rolls,
      lootMult: dayMult *
          depletionMult, // No baseLoot multiplier in JSON, default is 1.0
    );
  }

  /// Roll rare item chance
  bool rollRareItem(double baseChance, double rareMult) {
    return rng.nextDouble() < (baseChance * rareMult);
  }
}

class _LootResult {
  final String itemId;
  final int qty;

  _LootResult({required this.itemId, required this.qty});
}

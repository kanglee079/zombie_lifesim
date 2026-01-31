import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../../data/models/faction_def.dart';
import '../state/game_state.dart';
import '../engine/effect_engine.dart';
import '../engine/loot_engine.dart';

/// Offer for sale or purchase
class TradeOffer {
  final String itemId;
  final int qty;
  final int price;
  final bool isBuying; // true = trader is buying from player

  const TradeOffer({
    required this.itemId,
    required this.qty,
    required this.price,
    required this.isBuying,
  });
}

/// Result of a trade
class TradeResult {
  final bool success;
  final String message;
  final int currencyDelta;

  const TradeResult({
    required this.success,
    required this.message,
    required this.currencyDelta,
  });
}

/// System for handling trading with factions
class TradeSystem {
  final GameDataRepository data;
  final EffectEngine effectEngine;
  final GameRng rng;
  final LootEngine lootEngine;

  TradeSystem({
    required this.data,
    required this.effectEngine,
    required this.rng,
    required this.lootEngine,
  });

  /// Calculate buy price (player buying from trader)
  int getBuyPrice(String itemId, String factionId, GameState state) {
    final item = data.getItem(itemId);
    if (item == null) return 999999;

    return _computePrice(
      item: item,
      factionId: factionId,
      state: state,
      isBuying: true,
      withNoise: false,
    );
  }

  /// Calculate sell price (player selling to trader)
  int getSellPrice(String itemId, String factionId, GameState state) {
    final item = data.getItem(itemId);
    if (item == null) return 0;

    return _computePrice(
      item: item,
      factionId: factionId,
      state: state,
      isBuying: false,
      withNoise: false,
    );
  }

  /// Buy item from trader
  TradeResult buyFromTrader({
    required String itemId,
    required int qty,
    required String factionId,
    required GameState state,
  }) {
    final price = getBuyPrice(itemId, factionId, state) * qty;
    final currency = _getCurrency(state);

    if (currency < price) {
      return TradeResult(
        success: false,
        message: 'Không đủ tiền. Cần $price, có $currency.',
        currencyDelta: 0,
      );
    }

    // Deduct currency
    effectEngine.removeItemFromInventory(state, 'currency', price);

    // Add item
    effectEngine.addItemToInventory(state, itemId, qty);

    // Small rep gain
    _addRep(factionId, 1, state);

    final item = data.getItem(itemId);
    state.addLog('💰 Mua ${item?.name ?? itemId} x$qty với giá $price.');

    GameLogger.game('Trade buy: $itemId x$qty for $price from $factionId');

    return TradeResult(
      success: true,
      message: 'Đã mua thành công!',
      currencyDelta: -price,
    );
  }

  /// Sell item to trader
  TradeResult sellToTrader({
    required String itemId,
    required int qty,
    required String factionId,
    required GameState state,
  }) {
    final have = _getItemQty(state, itemId);
    if (have < qty) {
      return TradeResult(
        success: false,
        message: 'Không đủ vật phẩm. Cần $qty, có $have.',
        currencyDelta: 0,
      );
    }

    final price = getSellPrice(itemId, factionId, state) * qty;

    // Remove item
    effectEngine.removeItemFromInventory(state, itemId, qty);

    // Add currency
    effectEngine.addItemToInventory(state, 'currency', price);

    // Small rep gain
    _addRep(factionId, 1, state);

    final item = data.getItem(itemId);
    state.addLog('💰 Bán ${item?.name ?? itemId} x$qty với giá $price.');

    GameLogger.game('Trade sell: $itemId x$qty for $price to $factionId');

    return TradeResult(
      success: true,
      message: 'Đã bán thành công!',
      currencyDelta: price,
    );
  }

  /// Generate random trader offers
  List<TradeOffer> generateOffers(String factionId, GameState state) {
    final faction = data.getFaction(factionId);
    if (faction == null) return [];

    _ensureMarketState(state);

    final tier = _getRepTier(faction, state.factionRep[factionId] ?? 0);
    final offerCount = tier?.offerCount ?? 6;
    final forbiddenTags = tier?.forbiddenTags ?? const <String>[];

    final offers = <TradeOffer>[];
    final commonTableId = 'trade_common_$factionId';
    final specialTableId = tier?.specialTable;

    final commonLoot = lootEngine.rollLoot(commonTableId, rolls: offerCount);
    final specialLoot = specialTableId != null
        ? lootEngine.rollLoot(specialTableId, rolls: (offerCount / 3).ceil())
        : <String, int>{};

    final merged = <String, int>{}
      ..addAll(commonLoot)
      ..addAll(specialLoot);

    for (final entry in merged.entries) {
      final item = data.getItem(entry.key);
      if (item == null) continue;
      if (item.tags.any((t) => forbiddenTags.contains(t))) continue;

      final unitPrice = _computePrice(
        item: item,
        factionId: factionId,
        state: state,
        isBuying: true,
        withNoise: true,
      );
      offers.add(TradeOffer(
        itemId: item.id,
        qty: entry.value,
        price: unitPrice * entry.value,
        isBuying: false,
      ));
    }

    if (offers.length > offerCount) {
      rng.shuffle(offers);
      return offers.take(offerCount).toList();
    }

    return offers;
  }

  /// Get available factions for trading
  List<String> getAvailableFactions(GameState state) {
    return data.factions.keys.where((factionId) {
      final rep = state.factionRep[factionId] ?? 0;
      return rep > -50; // Can't trade with hostile factions
    }).toList();
  }

  int _getCurrency(GameState state) {
    int total = 0;
    for (final stack in state.inventory) {
      if (stack.itemId == 'currency') {
        total += stack.qty;
      }
    }
    return total;
  }

  int _getItemQty(GameState state, String itemId) {
    int total = 0;
    for (final stack in state.inventory) {
      if (stack.itemId == itemId) {
        total += stack.qty;
      }
    }
    return total;
  }

  void _addRep(String factionId, int delta, GameState state) {
    final current = state.factionRep[factionId] ?? 0;
    state.factionRep[factionId] = Clamp.reputation(current + delta);
  }

  void updateMarket(GameState state) {
    _ensureMarketState(state);
    _applyScarcityDrift(state);
    _advanceMarketCondition(state);
  }

  int _computePrice({
    required dynamic item,
    required String factionId,
    required GameState state,
    required bool isBuying,
    required bool withNoise,
  }) {
    final pricing = data.tradeSystem['pricing'] as Map<String, dynamic>? ?? {};
    final faction = data.getFaction(factionId);
    if (faction == null) return 0;

    _ensureMarketState(state);

    final baseValue = item.value;
    final inflation = _getDayInflation(state.day, pricing);
    final scarcityMult = _getScarcityMultiplier(item, state, pricing);
    final conditionMult = _getConditionMultiplier(item, state);
    final tier = _getRepTier(faction, state.factionRep[factionId] ?? 0);

    final defaultBuy = (pricing['defaultBuyMultiplier'] as num?)?.toDouble() ?? 1.25;
    final defaultSell = (pricing['defaultSellMultiplier'] as num?)?.toDouble() ?? 0.75;

    double price = baseValue * inflation * scarcityMult * conditionMult;

    if (isBuying) {
      price *= faction.baseBuyMult;
      price *= tier?.buyMult ?? 1.0;
      price *= defaultBuy;

      for (final tag in item.tags) {
        final discount = faction.supplyDiscounts[tag];
        if (discount != null) {
          price *= discount;
        }
      }
    } else {
      price *= faction.baseSellMult;
      price *= tier?.sellMult ?? 1.0;
      price *= defaultSell;

      for (final tag in item.tags) {
        final premium = faction.demandPremiums[tag];
        if (premium != null) {
          price *= premium;
        }
      }
    }

    price *= _getNoiseMultiplier(state);

    if (withNoise) {
      final noiseRange = (pricing['priceNoiseRandomRange'] as List?) ?? [0.95, 1.05];
      final min = (noiseRange[0] as num?)?.toDouble() ?? 0.95;
      final max = (noiseRange[1] as num?)?.toDouble() ?? 1.05;
      final noise = min + rng.nextDouble() * (max - min);
      price *= noise;
    }

    price = _applyOverrides(item.id, price, pricing);

    final minPrice = (pricing['minPrice'] as num?)?.toInt() ?? 1;
    final maxPrice = (pricing['maxPrice'] as num?)?.toInt() ?? 999;
    return Clamp.i(price.round(), minPrice, maxPrice);
  }

  void _ensureMarketState(GameState state) {
    if (state.marketScarcityByTag.isEmpty) {
      final scarcity = data.tradeSystem['marketScarcity'] as Map<String, dynamic>? ?? {};
      final initial = scarcity['initialIndex'] as Map<String, dynamic>? ?? {};
      state.marketScarcityByTag = initial.map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    }

    if (state.marketConditionId.isEmpty || state.marketConditionDaysLeft <= 0) {
      _rollMarketCondition(state);
    }
  }

  void _applyScarcityDrift(GameState state) {
    final scarcity = data.tradeSystem['marketScarcity'] as Map<String, dynamic>? ?? {};
    final drift = scarcity['dailyDrift'] as Map<String, dynamic>? ?? {};
    final min = (drift['min'] as num?)?.toInt() ?? -4;
    final max = (drift['max'] as num?)?.toInt() ?? 4;

    final impacts = scarcity['eventImpacts'] as List<dynamic>? ?? [];
    for (final entry in state.marketScarcityByTag.entries) {
      final delta = rng.range(min, max);
      int value = entry.value + delta;

      for (final impact in impacts) {
        if (impact is Map &&
            impact['marketCondition'] == state.marketConditionId &&
            impact['tag'] == entry.key) {
          value += (impact['delta'] as num?)?.toInt() ?? 0;
        }
      }

      state.marketScarcityByTag[entry.key] = Clamp.i(value, 0, 100);
    }
  }

  void _advanceMarketCondition(GameState state) {
    if (state.marketConditionDaysLeft > 0) {
      state.marketConditionDaysLeft -= 1;
      return;
    }
    _rollMarketCondition(state);
  }

  void _rollMarketCondition(GameState state) {
    final conditions = data.tradeSystem['marketConditions'] as List<dynamic>? ?? [];
    final candidates = <Map<String, dynamic>>[];
    final weights = <double>[];

    for (final condition in conditions) {
      if (condition is Map<String, dynamic>) {
        final minDay = (condition['minDay'] as num?)?.toInt() ?? 1;
        if (state.day < minDay) continue;
        candidates.add(condition);
        weights.add((condition['weight'] as num?)?.toDouble() ?? 1.0);
      }
    }

    if (candidates.isEmpty) {
      state.marketConditionId = 'normal';
      state.marketConditionDaysLeft = 2;
      return;
    }

    final index = rng.weightedSelect(weights);
    final selected = candidates[index < 0 ? 0 : index];
    state.marketConditionId = selected['id']?.toString() ?? 'normal';

    final duration = selected['durationDays'] as List<dynamic>? ?? [1, 2];
    final min = (duration[0] as num?)?.toInt() ?? 1;
    final maxRaw = duration.length > 1 ? duration[1] : duration[0];
    final max = (maxRaw as num?)?.toInt() ?? min;
    state.marketConditionDaysLeft = rng.range(min, max);
  }

  RepTier? _getRepTier(dynamic faction, int rep) {
    for (final tier in faction.repTiers) {
      if (rep >= tier.min && rep <= tier.max) {
        return tier;
      }
    }
    return null;
  }

  double _getDayInflation(int day, Map<String, dynamic> pricing) {
    final curve = pricing['dayInflationCurve'] as List<dynamic>? ?? [];
    if (curve.isEmpty) return 1.0;
    final index = Clamp.i(day - 1, 0, curve.length - 1);
    return (curve[index] as num?)?.toDouble() ?? 1.0;
  }

  double _getScarcityMultiplier(dynamic item, GameState state, Map<String, dynamic> pricing) {
    final order = (pricing['tagResolutionOrder'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    String? primary;
    for (final tag in order) {
      if (item.tags.contains(tag)) {
        primary = tag;
        break;
      }
    }
    primary ??= item.tags.isNotEmpty ? item.tags.first : null;
    if (primary == null) return 1.0;

    final scarcityIndex = state.marketScarcityByTag[primary] ?? 50;
    double mult = 0.70 + (scarcityIndex / 100) * 1.10;
    if (mult < 0.65) mult = 0.65;
    if (mult > 1.85) mult = 1.85;
    return mult;
  }

  double _getConditionMultiplier(dynamic item, GameState state) {
    final conditions = data.tradeSystem['marketConditions'] as List<dynamic>? ?? [];
    Map<String, dynamic>? condition;
    for (final entry in conditions) {
      if (entry is Map<String, dynamic> && entry['id'] == state.marketConditionId) {
        condition = entry;
        break;
      }
    }
    condition ??= {};
    final tagMult = condition['tagMult'] as Map<String, dynamic>? ?? {};
    double mult = 1.0;
    for (final tag in item.tags) {
      if (tagMult.containsKey(tag)) {
        mult *= (tagMult[tag] as num?)?.toDouble() ?? 1.0;
      }
    }
    return mult;
  }

  double _getNoiseMultiplier(GameState state) {
    return 1.0 + (state.baseStats.noise / 200);
  }

  double _applyOverrides(String itemId, double price, Map<String, dynamic> pricing) {
    final overrides = pricing['overrides'] as List<dynamic>? ?? [];
    for (final override in overrides) {
      if (override is Map<String, dynamic> && override['itemId'] == itemId) {
        final min = (override['min'] as num?)?.toInt();
        final max = (override['max'] as num?)?.toInt();
        if (min != null && price < min) price = min.toDouble();
        if (max != null && price > max) price = max.toDouble();
        break;
      }
    }
    return price;
  }
}

import '../../core/rng.dart';
import '../../core/logger.dart';
import '../../core/clamp.dart';
import '../../data/repositories/game_data_repo.dart';
import '../state/game_state.dart';
import '../engine/effect_engine.dart';

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

  TradeSystem({
    required this.data,
    required this.effectEngine,
    required this.rng,
  });

  /// Calculate buy price (player buying from trader)
  int getBuyPrice(String itemId, String factionId, GameState state) {
    final item = data.getItem(itemId);
    if (item == null) return 999999;

    final faction = data.getFaction(factionId);
    final baseValue = item.value;

    // Get faction multiplier
    double factionMult = faction?.baseBuyMult ?? 1.2;

    // Adjust for reputation
    final rep = state.factionRep[factionId] ?? 0;
    factionMult *= (1.0 - rep * 0.002); // Higher rep = cheaper

    // Adjust for market scarcity
    final scarcity = state.marketScarcity;
    factionMult *= (1.0 + scarcity * 0.01);

    // Day inflation
    final dayInflation = 1.0 + state.day * 0.01;

    return (baseValue * factionMult * dayInflation).round().clamp(1, 999999);
  }

  /// Calculate sell price (player selling to trader)
  int getSellPrice(String itemId, String factionId, GameState state) {
    final item = data.getItem(itemId);
    if (item == null) return 0;

    final faction = data.getFaction(factionId);
    final baseValue = item.value;

    // Get faction multiplier
    double factionMult = faction?.baseSellMult ?? 0.5;

    // Adjust for reputation
    final rep = state.factionRep[factionId] ?? 0;
    factionMult *= (1.0 + rep * 0.002); // Higher rep = better price

    // Check for demand premiums
    if (faction != null) {
      for (final tag in item.tags) {
        final premium = faction.demandPremiums[tag];
        if (premium != null) {
          factionMult *= (1.0 + premium / 100);
        }
      }
    }

    return (baseValue * factionMult).round().clamp(0, 999999);
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

    final offers = <TradeOffer>[];
    final numOffers = rng.range(3, 8);

    // Generate sell offers (trader selling to player)
    for (int i = 0; i < numOffers; i++) {
      final items = data.items.values.where((item) {
        // Filter by rarity
        final rarityOk = ['common', 'uncommon', 'rare'].contains(item.rarity);
        return rarityOk && item.value > 0;
      }).toList();

      if (items.isEmpty) continue;

      final item = items[rng.nextInt(items.length)];
      final qty = rng.range(1, 5);
      final price = getBuyPrice(item.id, factionId, state);

      offers.add(TradeOffer(
        itemId: item.id,
        qty: qty,
        price: price * qty,
        isBuying: false,
      ));
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';

/// Trade bottom sheet
class TradeSheet extends ConsumerStatefulWidget {
  final bool embedded;

  const TradeSheet({super.key, this.embedded = false});

  @override
  ConsumerState<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends ConsumerState<TradeSheet> {
  String? _selectedFaction;
  int _selectedTab = 0; // 0 = buy, 1 = sell

  @override
  Widget build(BuildContext context) {
    final gameLoop = ref.watch(gameLoopProvider);
    if (widget.embedded) {
      return _buildContent(gameLoop, null, true);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return _buildContent(gameLoop, scrollController, false);
      },
    );
  }

  Widget _buildContent(
    AsyncValue<dynamic> gameLoop,
    ScrollController? scrollController,
    bool embedded,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: embedded
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          if (!embedded)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GameColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.store, color: GameColors.gold),
                const SizedBox(width: 12),
                Text('Giao dịch', style: GameTypography.heading2),
                const Spacer(),
                if (!embedded)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Faction selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: gameLoop.when(
              data: (loop) {
                final factions = loop.getTradeFactions();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chọn phe phái', style: GameTypography.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: factions.map((factionId) {
                        final faction = loop.data.getFaction(factionId);
                        final isSelected = _selectedFaction == factionId;

                        return ChoiceChip(
                          label: Text(faction?.name ?? factionId),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFaction = selected ? factionId : null;
                            });
                          },
                          selectedColor: GameColors.gold.withOpacity(0.3),
                          backgroundColor: GameColors.surfaceLight,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? GameColors.gold
                                : GameColors.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi: $e'),
            ),
          ),

          // Tabs
          if (_selectedFaction != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: GameColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? GameColors.success.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Mua',
                          textAlign: TextAlign.center,
                          style: GameTypography.button.copyWith(
                            color: _selectedTab == 0
                                ? GameColors.success
                                : GameColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? GameColors.warning.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Bán',
                          textAlign: TextAlign.center,
                          style: GameTypography.button.copyWith(
                            color: _selectedTab == 1
                                ? GameColors.warning
                                : GameColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Trade list
          Expanded(
            child: _selectedFaction == null
                ? Center(
                    child: Text(
                      'Chọn một phe phái để giao dịch',
                      style: GameTypography.body.copyWith(
                        color: GameColors.textMuted,
                      ),
                    ),
                  )
                : gameLoop.when(
                    data: (loop) => _selectedTab == 0
                        ? _buildBuyList(loop, scrollController ?? ScrollController())
                        : _buildSellList(loop, scrollController ?? ScrollController()),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Lỗi: $e')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyList(dynamic loop, ScrollController controller) {
    final offers = loop.generateTradeOffers(_selectedFaction!);

    if (offers.isEmpty) {
      return Center(
        child: Text(
          'Không có hàng hóa để mua',
          style: GameTypography.body.copyWith(color: GameColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        final item = loop.data.getItem(offer.itemId);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GameColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item?.name ?? offer.itemId,
                      style: GameTypography.body,
                    ),
                    Text(
                      'x${offer.qty}',
                      style: GameTypography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                '${offer.price} 💰',
                style: GameTypography.stat.copyWith(color: GameColors.gold),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(gameStateProvider.notifier).doTrade(
                    itemId: offer.itemId,
                    qty: offer.qty,
                    factionId: _selectedFaction!,
                    isBuying: true,
                  );
                  setState(() {}); // Refresh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.success,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Mua'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSellList(dynamic loop, ScrollController controller) {
    final inventory = ref.watch(inventoryProvider);

    if (inventory.isEmpty) {
      return Center(
        child: Text(
          'Không có vật phẩm để bán',
          style: GameTypography.body.copyWith(color: GameColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: inventory.length,
      itemBuilder: (context, index) {
        final stack = inventory[index];
        final item = loop.data.getItem(stack.itemId);
        final price = loop.getTradePrice(stack.itemId, _selectedFaction!, false);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GameColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item?.name ?? stack.itemId,
                      style: GameTypography.body,
                    ),
                    Text(
                      'Có: ${stack.qty}',
                      style: GameTypography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                '$price 💰/cái',
                style: GameTypography.stat.copyWith(color: GameColors.gold),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(gameStateProvider.notifier).doTrade(
                    itemId: stack.itemId,
                    qty: 1,
                    factionId: _selectedFaction!,
                    isBuying: false,
                  );
                  setState(() {}); // Refresh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameColors.warning,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Bán 1'),
              ),
            ],
          ),
        );
      },
    );
  }
}

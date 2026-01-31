import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/item_tile.dart';

/// Inventory bottom sheet
class InventorySheet extends ConsumerWidget {
  const InventorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final gameLoop = ref.watch(gameLoopProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: GameColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
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
                    const Icon(Icons.inventory_2, color: GameColors.warning),
                    const SizedBox(width: 12),
                    Text('Kho đồ', style: GameTypography.heading2),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GameColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${inventory.length} vật phẩm',
                        style: GameTypography.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Inventory list
              Expanded(
                child: inventory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: GameColors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Kho đồ trống',
                              style: GameTypography.body.copyWith(
                                color: GameColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: inventory.length,
                        itemBuilder: (context, index) {
                          final stack = inventory[index];

                          return gameLoop.when(
                            data: (loop) {
                              final item = loop.data.getItem(stack.itemId);
                              if (item == null) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ItemTile(
                                  item: item,
                                  quantity: stack.qty,
                                  onTap: () => _showItemDetails(
                                    context,
                                    ref,
                                    item,
                                    stack.qty,
                                  ),
                                  onLongPress: () => _showItemActions(
                                    context,
                                    ref,
                                    item,
                                    stack.qty,
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showItemDetails(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    int qty,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameColors.card,
        title: Text(item.name, style: GameTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null)
              Text(item.description!, style: GameTypography.body),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('Số lượng: $qty'),
                const SizedBox(width: 8),
                _buildInfoChip('Cân nặng: ${item.weight}kg'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('Độ hiếm: ${item.rarity}'),
                const SizedBox(width: 8),
                _buildInfoChip('Giá trị: ${item.value}'),
              ],
            ),
          ],
        ),
        actions: [
          if (item.use != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(gameStateProvider.notifier).useItem(item.id);
              },
              child: const Text('Sử dụng'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GameColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GameTypography.caption),
    );
  }

  void _showItemActions(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    int qty,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameColors.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.name, style: GameTypography.heading3),
            const SizedBox(height: 16),
            if (item.use != null)
              ListTile(
                leading: const Icon(Icons.play_arrow, color: GameColors.success),
                title: const Text('Sử dụng'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(gameStateProvider.notifier).useItem(item.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: GameColors.danger),
              title: const Text('Bỏ đi'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement drop item
              },
            ),
          ],
        ),
      ),
    );
  }
}

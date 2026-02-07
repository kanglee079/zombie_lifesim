import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/item_tile.dart';

/// Inventory bottom sheet
class InventorySheet extends ConsumerWidget {
  final bool embedded;

  const InventorySheet({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final gameLoop = ref.watch(gameLoopProvider);

    if (embedded) {
      return _buildContent(context, ref, inventory, gameLoop, null, embedded);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return _buildContent(context, ref, inventory, gameLoop, scrollController, false);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> inventory,
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
                if (!embedded)
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
                    controller: scrollController ?? ScrollController(),
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
              title: Text('Bỏ đi (x$qty)'),
              subtitle: Text(
                'Bỏ 1 cái. Giữ để bỏ hết.',
                style: GameTypography.caption,
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDrop(context, ref, item, 1, qty);
              },
              onLongPress: () {
                Navigator.pop(context);
                _confirmDrop(context, ref, item, qty, qty);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDrop(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    int dropQty,
    int totalQty,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: Text('Bỏ ${item.name}?', style: GameTypography.heading3),
        content: Text(
          'Bạn chắc chắn muốn bỏ ${item.name} x$dropQty?'
          '${dropQty < totalQty ? '\n(Còn lại: ${totalQty - dropQty})' : '\n(Bỏ hết)'}',
          style: GameTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Hủy',
              style: GameTypography.body.copyWith(color: GameColors.textMuted),
            ),
          ),
          if (dropQty < totalQty && totalQty > 1)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(gameStateProvider.notifier).dropItem(item.id, qty: totalQty);
              },
              child: Text(
                'Bỏ hết ($totalQty)',
                style: GameTypography.body.copyWith(color: GameColors.warning),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameStateProvider.notifier).dropItem(item.id, qty: dropQty);
            },
            child: Text(
              'Bỏ x$dropQty',
              style: GameTypography.body.copyWith(color: GameColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

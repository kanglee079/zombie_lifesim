import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';

/// Crafting bottom sheet
class CraftSheet extends ConsumerWidget {
  const CraftSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    const Icon(Icons.build, color: GameColors.info),
                    const SizedBox(width: 12),
                    Text('Chế tạo', style: GameTypography.heading2),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Recipe list
              Expanded(
                child: gameLoop.when(
                  data: (loop) {
                    final recipes = loop.getKnownRecipes();

                    if (recipes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.build_outlined,
                              size: 64,
                              color: GameColors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có công thức nào',
                              style: GameTypography.body.copyWith(
                                color: GameColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        final canCraft = loop.canCraft(recipe.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecipeCard(
                            recipe: recipe,
                            canCraft: canCraft,
                            onCraft: () {
                              ref.read(gameStateProvider.notifier).doCraft(recipe.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã chế tạo ${recipe.name}'),
                                  backgroundColor: GameColors.success,
                                ),
                              );
                            },
                            data: loop.data,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Text('Lỗi: $e'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final dynamic recipe;
  final bool canCraft;
  final VoidCallback onCraft;
  final dynamic data;

  const _RecipeCard({
    required this.recipe,
    required this.canCraft,
    required this.onCraft,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canCraft
              ? GameColors.success.withOpacity(0.5)
              : GameColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GameColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.build, color: GameColors.info, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: GameTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${recipe.timeMinutes} phút',
                      style: GameTypography.caption,
                    ),
                  ],
                ),
              ),
              if (canCraft)
                ElevatedButton(
                  onPressed: onCraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Chế tạo'),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Thiếu NVL',
                    style: GameTypography.caption.copyWith(
                      color: GameColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Inputs
          Text('Nguyên liệu:', style: GameTypography.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (recipe.inputs as List).map<Widget>((input) {
              final item = data.getItem(input.itemId);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item?.name ?? input.itemId} x${input.qty}',
                  style: GameTypography.caption,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Outputs
          Text('Sản phẩm:', style: GameTypography.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (recipe.outputs as List).map<Widget>((output) {
              final item = data.getItem(output.itemId);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: GameColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item?.name ?? output.itemId} x${output.qty}',
                  style: GameTypography.caption.copyWith(
                    color: GameColors.success,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

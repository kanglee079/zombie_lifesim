import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';

/// Crafting bottom sheet
class CraftSheet extends ConsumerStatefulWidget {
  const CraftSheet({super.key});

  @override
  ConsumerState<CraftSheet> createState() => _CraftSheetState();
}

class _CraftSheetState extends ConsumerState<CraftSheet> {
  String _searchQuery = '';
  bool _showCraftableOnly = false;

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(gameStateProvider);
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

              // Search bar + filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GameTypography.body,
                        decoration: InputDecoration(
                          hintText: 'Tìm công thức...',
                          hintStyle: GameTypography.body.copyWith(
                            color: GameColors.textMuted,
                          ),
                          prefixIcon: const Icon(Icons.search,
                              size: 20, color: GameColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: GameColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(
                        'Đủ NVL',
                        style: GameTypography.caption.copyWith(
                          color: _showCraftableOnly
                              ? Colors.white
                              : GameColors.textMuted,
                        ),
                      ),
                      selected: _showCraftableOnly,
                      onSelected: (v) =>
                          setState(() => _showCraftableOnly = v),
                      selectedColor: GameColors.success,
                      backgroundColor: GameColors.surfaceLight,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              // Recipe list
              Expanded(
                child: gameLoop.when(
                  data: (loop) {
                    var recipes = loop.getKnownRecipes();

                    // Filter by search
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      recipes = recipes.where((r) {
                        return r.name.toLowerCase().contains(query) ||
                            r.id.toLowerCase().contains(query);
                      }).toList();
                    }

                    // Filter craftable only
                    if (_showCraftableOnly) {
                      recipes = recipes.where((r) => loop.canCraft(r.id)).toList();
                    }

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
                              _searchQuery.isNotEmpty || _showCraftableOnly
                                  ? 'Không tìm thấy công thức phù hợp'
                                  : 'Chưa có công thức nào',
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
                              final result = ref
                                  .read(gameStateProvider.notifier)
                                  .doCraft(recipe.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: result.success
                                      ? GameColors.success
                                      : GameColors.warning,
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

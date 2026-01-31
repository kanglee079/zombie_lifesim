import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../../data/models/item_def.dart';

/// Item tile for inventory display
class ItemTile extends StatelessWidget {
  final ItemDef item;
  final int quantity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool showQuantity;

  const ItemTile({
    super.key,
    required this.item,
    this.quantity = 1,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.showQuantity = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? GameColors.danger.withOpacity(0.2)
          : GameColors.surfaceLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? GameColors.danger
                  : item.rarity.rarityColor.withOpacity(0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Item icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.rarity.rarityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _getItemIcon(item.category),
                ),
              ),
              const SizedBox(width: 12),

              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GameTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: GameColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.rarity.rarityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.rarity.toUpperCase(),
                            style: GameTypography.caption.copyWith(
                              color: item.rarity.rarityColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.weight > 0)
                          Text(
                            '${item.weight}kg',
                            style: GameTypography.caption,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity
              if (showQuantity && quantity > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'x$quantity',
                    style: GameTypography.stat.copyWith(
                      color: GameColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getItemIcon(String category) {
    IconData icon;
    Color color;

    switch (category.toLowerCase()) {
      case 'weapon':
        icon = Icons.gps_fixed;
        color = GameColors.danger;
        break;
      case 'medical':
        icon = Icons.medical_services;
        color = GameColors.success;
        break;
      case 'food':
        icon = Icons.restaurant;
        color = GameColors.hunger;
        break;
      case 'water':
        icon = Icons.water_drop;
        color = GameColors.thirst;
        break;
      case 'tool':
        icon = Icons.build;
        color = GameColors.warning;
        break;
      case 'material':
        icon = Icons.category;
        color = GameColors.common;
        break;
      case 'armor':
        icon = Icons.shield;
        color = GameColors.info;
        break;
      default:
        icon = Icons.inventory_2;
        color = GameColors.textSecondary;
    }

    return Icon(icon, color: color, size: 22);
  }
}

/// Compact item chip for inline display
class ItemChip extends StatelessWidget {
  final String name;
  final int quantity;
  final String rarity;
  final VoidCallback? onTap;

  const ItemChip({
    super.key,
    required this.name,
    this.quantity = 1,
    this.rarity = 'common',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: rarity.rarityColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GameTypography.bodySmall.copyWith(
                  color: GameColors.textPrimary,
                ),
              ),
              if (quantity > 1) ...[
                const SizedBox(width: 4),
                Text(
                  'x$quantity',
                  style: GameTypography.caption.copyWith(
                    color: GameColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

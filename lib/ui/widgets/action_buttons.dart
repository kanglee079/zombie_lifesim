import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

/// Primary action button
class PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: GameColors.danger,
        disabledBackgroundColor: GameColors.danger.withOpacity(0.5),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: GameColors.textPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(label, style: GameTypography.button),
              ],
            ),
    );
  }
}

/// Secondary action button
class SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(
          color: color ?? GameColors.textMuted.withOpacity(0.5),
        ),
        foregroundColor: color ?? GameColors.textPrimary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// Action grid with multiple buttons
class ActionGrid extends StatelessWidget {
  final List<ActionGridItem> items;
  final int crossAxisCount;

  const ActionGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: items.map((item) => _ActionGridButton(item: item)).toList(),
    );
  }
}

class _ActionGridButton extends StatelessWidget {
  final ActionGridItem item;

  const _ActionGridButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.enabled
          ? GameColors.surfaceLight
          : GameColors.surfaceLight.withOpacity(0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: item.enabled ? item.onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (item.color ?? GameColors.danger).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: item.enabled
                      ? (item.color ?? GameColors.danger)
                      : GameColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: GameTypography.button.copyWith(
                    color: item.enabled
                        ? GameColors.textPrimary
                        : GameColors.textMuted,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionGridItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool enabled;

  const ActionGridItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.color,
    this.enabled = true,
  });
}

/// Quick action bar
class QuickActionBar extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionBar({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: GameColors.surface,
        border: Border(
          top: BorderSide(color: GameColors.surfaceLight),
        ),
      ),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _QuickActionButton(action: action),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                size: 22,
                color: action.highlighted
                    ? GameColors.danger
                    : GameColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                action.label,
                style: GameTypography.caption.copyWith(
                  color: action.highlighted
                      ? GameColors.danger
                      : GameColors.textSecondary,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool highlighted;

  const QuickAction({
    required this.label,
    required this.icon,
    this.onTap,
    this.highlighted = false,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/game_theme.dart';

/// Primary action button with gradient and glow effect
class PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;

  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.loading = false,
    this.color,
  });

  @override
  State<PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<PrimaryActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? GameColors.danger;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(_pressed ? 0.2 : 0.4),
                blurRadius: _pressed ? 4 : 12,
                offset: Offset(0, _pressed ? 2 : 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.loading
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      widget.onPressed?.call();
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: widget.loading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.icon, size: 20, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            widget.label,
                            style: GameTypography.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action button with outline style
class SecondaryActionButton extends StatefulWidget {
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
  State<SecondaryActionButton> createState() => _SecondaryActionButtonState();
}

class _SecondaryActionButtonState extends State<SecondaryActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? GameColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(_hovered ? 0.5 : 0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: GameTypography.button.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced action grid with beautiful buttons
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _ActionGridButton(item: items[index]),
    );
  }
}

class _ActionGridButton extends StatefulWidget {
  final ActionGridItem item;

  const _ActionGridButton({required this.item});

  @override
  State<_ActionGridButton> createState() => _ActionGridButtonState();
}

class _ActionGridButtonState extends State<_ActionGridButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.color ?? GameColors.danger;
    final isEnabled = item.enabled;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    colors: [
                      GameColors.surfaceLight,
                      GameColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isEnabled ? null : GameColors.surfaceLight.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabled
                  ? (_pressed
                      ? color.withOpacity(0.5)
                      : GameColors.surfaceLighter.withOpacity(0.6))
                  : GameColors.surfaceLight.withOpacity(0.3),
              width: _pressed ? 1.5 : 1,
            ),
            boxShadow: isEnabled && _pressed
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled
                  ? () {
                      HapticFeedback.lightImpact();
                      item.onTap?.call();
                    }
                  : null,
              borderRadius: BorderRadius.circular(14),
              splashColor: color.withOpacity(0.1),
              highlightColor: color.withOpacity(0.05),
              child: Container(
                key: item.targetKey,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Icon container with gradient background
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: isEnabled
                            ? LinearGradient(
                                colors: [
                                  color.withOpacity(0.2),
                                  color.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isEnabled ? null : GameColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isEnabled
                              ? color.withOpacity(0.3)
                              : GameColors.surfaceLighter.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: isEnabled ? color : GameColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Label and optional subtitle
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: GameTypography.button.copyWith(
                              color: isEnabled
                                  ? GameColors.textPrimary
                                  : GameColors.textMuted,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.subtitle!,
                              style: GameTypography.small.copyWith(
                                color: isEnabled
                                    ? GameColors.textMuted
                                    : GameColors.textDim,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Arrow indicator
                    if (isEnabled)
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: GameColors.textMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActionGridItem {
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool enabled;
  final GlobalKey? targetKey;

  const ActionGridItem({
    required this.label,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.color,
    this.enabled = true,
    this.targetKey,
  });
}

/// Quick action bar with enhanced styling
class QuickActionBar extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionBar({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GameColors.surface,
        border: const Border(
          top: BorderSide(color: GameColors.surfaceLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final color = action.highlighted ? GameColors.danger : GameColors.textSecondary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              action.onTap?.call();
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: action.highlighted
                    ? GameColors.danger.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        action.icon,
                        size: 24,
                        color: color,
                      ),
                      if (action.badge != null)
                        Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: GameColors.danger,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              action.badge!,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.label,
                    style: GameTypography.tiny.copyWith(
                      color: color,
                      fontWeight:
                          action.highlighted ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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
  final String? badge;

  const QuickAction({
    required this.label,
    required this.icon,
    this.onTap,
    this.highlighted = false,
    this.badge,
  });
}

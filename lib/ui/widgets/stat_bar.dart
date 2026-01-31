import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

/// A stat bar widget that displays a value with a progress bar
class StatBar extends StatefulWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final IconData? icon;
  final bool showLabel;
  final bool compact;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 100,
    required this.color,
    this.icon,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  State<StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<StatBar> {
  double _previousPercent = 0;

  double _calcPercent(int value, int maxValue) {
    if (maxValue <= 0) return 0;
    return (value / maxValue).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _previousPercent = _calcPercent(widget.value, widget.maxValue);
  }

  @override
  void didUpdateWidget(covariant StatBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previousPercent = _calcPercent(oldWidget.value, oldWidget.maxValue);
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _calcPercent(widget.value, widget.maxValue);
    
    if (widget.compact) {
      return _buildCompact(percentage);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 16, color: widget.color),
                      const SizedBox(width: 6),
                    ],
                    Text(widget.label, style: GameTypography.bodySmall),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '${widget.value}/${widget.maxValue}',
                    key: ValueKey(widget.value),
                    style: GameTypography.stat.copyWith(color: widget.color),
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: GameColors.surfaceLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: _previousPercent, end: percentage),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(double percentage) {
    return Row(
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 14, color: widget.color),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: GameColors.surfaceLight,
              borderRadius: BorderRadius.circular(3),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: _previousPercent, end: percentage),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            '${widget.value}',
            key: ValueKey(widget.value),
            style: GameTypography.caption.copyWith(color: widget.color),
          ),
        ),
      ],
    );
  }
}

/// Health bar with danger indication
class HealthBar extends StatelessWidget {
  final int hp;
  final int maxHp;

  const HealthBar({
    super.key,
    required this.hp,
    this.maxHp = 100,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor = GameColors.hp;
    if (hp < 25) {
      barColor = GameColors.danger;
    } else if (hp < 50) {
      barColor = GameColors.warning;
    }

    return StatBar(
      label: 'HP',
      value: hp,
      maxValue: maxHp,
      color: barColor,
      icon: Icons.favorite,
    );
  }
}

/// Infection bar with danger indication
class InfectionBar extends StatelessWidget {
  final int infection;
  final int maxInfection;

  const InfectionBar({
    super.key,
    required this.infection,
    this.maxInfection = 100,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor = GameColors.infection;
    if (infection > 75) {
      barColor = GameColors.danger;
    } else if (infection > 50) {
      barColor = GameColors.warning;
    }

    return StatBar(
      label: 'Nhiễm',
      value: infection,
      maxValue: maxInfection,
      color: barColor,
      icon: Icons.coronavirus,
    );
  }
}

/// Stat bar row for displaying multiple stats
class StatBarRow extends StatelessWidget {
  final int hunger;
  final int thirst;
  final int fatigue;
  final int stress;

  const StatBarRow({
    super.key,
    required this.hunger,
    required this.thirst,
    required this.fatigue,
    required this.stress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatBar(
            label: 'Đói',
            value: hunger,
            color: GameColors.hunger,
            icon: Icons.restaurant,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBar(
            label: 'Khát',
            value: thirst,
            color: GameColors.thirst,
            icon: Icons.water_drop,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBar(
            label: 'Mệt',
            value: fatigue,
            color: GameColors.fatigue,
            icon: Icons.bedtime,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBar(
            label: 'Stress',
            value: stress,
            color: GameColors.stress,
            icon: Icons.psychology,
            compact: true,
          ),
        ),
      ],
    );
  }
}

/// Morale bar
class MoraleBar extends StatelessWidget {
  final int morale;

  const MoraleBar({
    super.key,
    required this.morale,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = ((morale + 50) / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tinh thần', style: GameTypography.bodySmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.self_improvement, size: 14, color: GameColors.morale),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: normalized,
                  child: Container(
                    decoration: BoxDecoration(
                      color: GameColors.morale,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$morale',
              style: GameTypography.caption.copyWith(color: GameColors.morale),
            ),
          ],
        ),
      ],
    );
  }
}

/// Base stats row
class BaseStatRow extends StatelessWidget {
  final int noise;
  final int smell;
  final int hope;
  final int signalHeat;

  const BaseStatRow({
    super.key,
    required this.noise,
    required this.smell,
    required this.hope,
    required this.signalHeat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatBar(
            label: 'Ồn',
            value: noise,
            color: GameColors.noise,
            icon: Icons.volume_up,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBar(
            label: 'Mùi',
            value: smell,
            color: GameColors.smell,
            icon: Icons.air,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBar(
            label: 'Hy vọng',
            value: hope,
            color: GameColors.hope,
            icon: Icons.auto_awesome,
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBar(
            label: 'Tín hiệu',
            value: signalHeat,
            color: GameColors.signalHeat,
            icon: Icons.wifi_tethering,
            compact: true,
          ),
        ),
      ],
    );
  }
}

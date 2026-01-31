import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

/// A stat bar widget that displays a value with a progress bar
class StatBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    
    if (compact) {
      return _buildCompact(percentage);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                    ],
                    Text(label, style: GameTypography.bodySmall),
                  ],
                ),
                Text(
                  '$value/$maxValue',
                  style: GameTypography.stat.copyWith(color: color),
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
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(double percentage) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: GameColors.surfaceLight,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: GameTypography.caption.copyWith(color: color),
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

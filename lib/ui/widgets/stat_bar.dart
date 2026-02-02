import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

/// Enhanced stat bar widget with glow effects and animations
class StatBar extends StatefulWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final IconData? icon;
  final bool showLabel;
  final bool compact;
  final bool showGlow;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 100,
    required this.color,
    this.icon,
    this.showLabel = true,
    this.compact = false,
    this.showGlow = true,
  });

  @override
  State<StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<StatBar> with SingleTickerProviderStateMixin {
  double _previousPercent = 0;
  late AnimationController _pulseController;

  double _calcPercent(int value, int maxValue) {
    if (maxValue <= 0) return 0;
    return (value / maxValue).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _previousPercent = _calcPercent(widget.value, widget.maxValue);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _checkCriticalState();
  }

  void _checkCriticalState() {
    final percent = _calcPercent(widget.value, widget.maxValue);
    // Pulse animation for critical values (low HP or high bad stats)
    if ((widget.label == 'HP' && percent < 0.25) ||
        (widget.label != 'HP' && percent > 0.75)) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant StatBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previousPercent = _calcPercent(oldWidget.value, oldWidget.maxValue);
    _checkCriticalState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (widget.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(widget.icon, size: 14, color: widget.color),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GameTypography.labelLarge.copyWith(
                        color: GameColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    '${widget.value}/${widget.maxValue}',
                    key: ValueKey(widget.value),
                    style: GameTypography.stat.copyWith(
                      color: widget.color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildProgressBar(percentage),
      ],
    );
  }

  Widget _buildProgressBar(double percentage) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value * 0.3;
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: GameColors.surfaceLight,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: GameColors.surfaceLighter.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: _previousPercent, end: percentage),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  children: [
                    // Background gradient
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.color.withOpacity(0.8),
                              widget.color,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    // Shine effect
                    if (value > 0.05)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    // Glow effect for critical
                    if (widget.showGlow && pulseValue > 0)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(pulseValue),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompact(double percentage) {
    return Row(
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 14, color: widget.color),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: GameColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withOpacity(0.7),
                            widget.color,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              '${widget.value}',
              key: ValueKey(widget.value),
              textAlign: TextAlign.right,
              style: GameTypography.stat.copyWith(
                color: widget.color,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Main stats card - HP and Infection with large display
class MainStatsCard extends StatelessWidget {
  final int hp;
  final int maxHp;
  final int infection;
  final int maxInfection;

  const MainStatsCard({
    super.key,
    required this.hp,
    this.maxHp = 100,
    required this.infection,
    this.maxInfection = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GameDecorations.card(),
      child: Row(
        children: [
          // HP Section
          Expanded(
            child: _StatDisplayTappable(
              icon: Icons.favorite,
              label: 'HP',
              value: hp,
              maxValue: maxHp,
              color: _getHpColor(hp),
              isGood: true,
              description: 'Máu của bạn. Về 0 là chết.',
              tips: [
                'HP giảm khi đói, khát, mệt quá cao.',
                'HP giảm khi bị tấn công.',
                'Dùng thuốc để hồi HP.',
                'Nghỉ ngơi và ăn uống đầy đủ giữ HP ổn định.',
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: GameColors.surfaceLighter,
          ),
          // Infection Section
          Expanded(
            child: _StatDisplayTappable(
              icon: Icons.coronavirus,
              label: 'Nhiễm',
              value: infection,
              maxValue: maxInfection,
              color: _getInfectionColor(infection),
              isGood: false,
              description: 'Mức độ nhiễm zombie. Đến 100 là biến thành zombie.',
              tips: [
                'Nhiễm tăng khi bị zombie cắn.',
                'Vệ sinh kém làm nhiễm tăng nhanh hơn.',
                'Thuốc kháng sinh giúp kiểm soát nhiễm.',
                'Không có cách chữa hoàn toàn, chỉ kiểm soát.',
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHpColor(int hp) {
    if (hp < 25) return GameColors.danger;
    if (hp < 50) return GameColors.warning;
    return GameColors.hp;
  }

  Color _getInfectionColor(int infection) {
    if (infection > 75) return GameColors.danger;
    if (infection > 50) return GameColors.warning;
    return GameColors.infection;
  }
}

class _StatDisplayTappable extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final bool isGood;
  final String description;
  final List<String> tips;

  const _StatDisplayTappable({
    required this.icon,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.isGood,
    required this.description,
    required this.tips,
  });

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StatInfoSheet(
        icon: icon,
        label: label,
        value: value,
        color: color,
        description: description,
        tips: tips,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = (value / maxValue).clamp(0.0, 1.0);
    final isCritical = isGood ? percent < 0.25 : percent > 0.75;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showInfo(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isCritical
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GameTypography.labelLarge,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$value',
                            style: GameTypography.statLarge.copyWith(color: color),
                          ),
                          Text(
                            '/$maxValue',
                            style: GameTypography.bodySmall.copyWith(
                              color: GameColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              StatBar(
                label: label,
                value: value,
                maxValue: maxValue,
                color: color,
                showLabel: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary stats row - hunger, thirst, fatigue, stress
class SecondaryStatsRow extends StatelessWidget {
  final int hunger;
  final int thirst;
  final int fatigue;
  final int stress;

  const SecondaryStatsRow({
    super.key,
    required this.hunger,
    required this.thirst,
    required this.fatigue,
    required this.stress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameColors.surfaceLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _MiniStat(
            icon: Icons.restaurant,
            value: hunger,
            color: GameColors.hunger,
            label: 'Đói',
            description: 'Mức độ đói. Ăn thức ăn để giảm.',
            tips: [
              'Đói tăng mỗi ngày.',
              'Đói > 75 sẽ mất HP.',
              'Tìm thức ăn khi khám phá.',
            ],
          ),
          _divider(),
          _MiniStat(
            icon: Icons.water_drop,
            value: thirst,
            color: GameColors.thirst,
            label: 'Khát',
            description: 'Mức độ khát. Uống nước để giảm.',
            tips: [
              'Khát tăng nhanh hơn đói.',
              'Khát > 75 sẽ mất HP.',
              'Nước rất quan trọng để sống.',
            ],
          ),
          _divider(),
          _MiniStat(
            icon: Icons.bedtime,
            value: fatigue,
            color: GameColors.fatigue,
            label: 'Mệt',
            description: 'Mức độ mệt mỏi. Nghỉ ngơi để giảm.',
            tips: [
              'Mệt tăng mỗi ngày.',
              'Mệt > 75 giảm hiệu quả hành động.',
              'Nghỉ ngơi để hồi phục.',
            ],
          ),
          _divider(),
          _MiniStat(
            icon: Icons.psychology,
            value: stress,
            color: GameColors.stress,
            label: 'Stress',
            description: 'Mức độ căng thẳng tinh thần.',
            tips: [
              'Stress tăng khi gặp nguy hiểm.',
              'Stress > 75 giảm tinh thần.',
              'Nghỉ ngơi và hy vọng giúp giảm stress.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: GameColors.surfaceLighter.withOpacity(0.5),
      );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final String label;
  final String description;
  final List<String> tips;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
    required this.description,
    required this.tips,
  });

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StatInfoSheet(
        icon: icon,
        label: label,
        value: value,
        color: color,
        description: description,
        tips: tips,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = value > 75;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInfo(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GameTypography.small.copyWith(
                    color: GameColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isCritical ? GameColors.danger : color,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$value',
                      style: GameTypography.stat.copyWith(
                        color: isCritical ? GameColors.danger : color,
                        fontWeight: isCritical ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Info sheet for displaying stat details
class _StatInfoSheet extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final String description;
  final List<String> tips;

  const _StatInfoSheet({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.description,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GameTypography.heading3.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GameTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$value/100',
                  style: GameTypography.stat.copyWith(
                    color: color,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GameColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: GameColors.gold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mẹo',
                      style: GameTypography.buttonSmall.copyWith(
                        color: GameColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: GameTypography.body.copyWith(color: GameColors.textSecondary)),
                      Expanded(
                        child: Text(
                          tip,
                          style: GameTypography.body.copyWith(
                            color: GameColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Morale display with gradient bar
class MoraleDisplay extends StatelessWidget {
  final int morale;

  const MoraleDisplay({
    super.key,
    required this.morale,
  });

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StatInfoSheet(
        icon: Icons.self_improvement,
        label: 'Tinh thần',
        value: morale + 50, // Normalize to 0-100
        color: GameColors.morale,
        description: 'Tinh thần của đội. Dao động từ -50 đến +50.',
        tips: [
          'Tinh thần cao giúp đội hoạt động hiệu quả.',
          'Tinh thần thấp có thể gây xung đột.',
          'Ăn uống đầy đủ và nghỉ ngơi tăng tinh thần.',
          'Gặp nguy hiểm hoặc thiếu thốn giảm tinh thần.',
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalized = ((morale + 50) / 100).clamp(0.0, 1.0);
    final isPositive = morale >= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showInfo(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: GameColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: GameColors.surfaceLight.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text('Tinh thần', style: GameTypography.labelLarge),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: GameColors.morale.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.self_improvement,
                  size: 16,
                  color: GameColors.morale,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: normalized,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPositive
                                ? [GameColors.morale.withOpacity(0.7), GameColors.morale]
                                : [GameColors.danger.withOpacity(0.7), GameColors.danger],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isPositive ? GameColors.morale : GameColors.danger)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPositive ? '+$morale' : '$morale',
                  style: GameTypography.stat.copyWith(
                    color: isPositive ? GameColors.morale : GameColors.danger,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Base stats row - noise, smell, hope, signal heat
class BaseStatsRow extends StatelessWidget {
  final int noise;
  final int smell;
  final int hope;
  final int signalHeat;

  const BaseStatsRow({
    super.key,
    required this.noise,
    required this.smell,
    required this.hope,
    required this.signalHeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: GameColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BaseStatChip(
            icon: Icons.volume_up,
            value: noise,
            color: GameColors.noise,
            label: 'Ồn',
            description: 'Mức độ ồn ào của căn cứ.',
            tips: [
              'Ồn càng cao, zombie càng dễ phát hiện.',
              'Hoạt động như chế tạo, gia cố tăng ồn.',
              'Ồn giảm dần theo thời gian.',
            ],
          ),
          _BaseStatChip(
            icon: Icons.air,
            value: smell,
            color: GameColors.smell,
            label: 'Mùi',
            description: 'Mức độ mùi hôi của căn cứ.',
            tips: [
              'Mùi cao thu hút zombie.',
              'Xác chết, rác thải tăng mùi.',
              'Dọn dẹp và vệ sinh giảm mùi.',
            ],
          ),
          _BaseStatChip(
            icon: Icons.auto_awesome,
            value: hope,
            color: GameColors.hope,
            label: 'Hy vọng',
            isGood: true,
            description: 'Hy vọng của đội.',
            tips: [
              'Hy vọng cao giúp tinh thần tốt.',
              'Hoàn thành nhiệm vụ tăng hy vọng.',
              'Thất bại và mất mát giảm hy vọng.',
            ],
          ),
          _BaseStatChip(
            icon: Icons.wifi_tethering,
            value: signalHeat,
            color: GameColors.signalHeat,
            label: 'Tín hiệu',
            description: 'Mức độ tín hiệu bị theo dõi.',
            tips: [
              'Tín hiệu càng cao, càng dễ bị truy vết.',
              'Bật radio hoặc thiết bị tăng tín hiệu.',
              'Nếu quá cao, có thể bị triangulation.',
            ],
          ),
        ],
      ),
    );
  }
}

class _BaseStatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final String label;
  final String description;
  final List<String> tips;
  final bool isGood;

  const _BaseStatChip({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
    required this.description,
    required this.tips,
    this.isGood = false,
  });

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StatInfoSheet(
        icon: icon,
        label: label,
        value: value,
        color: color,
        description: description,
        tips: tips,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = isGood ? value < 25 : value > 60;
    final displayColor = isCritical && !isGood ? GameColors.danger : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showInfo(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GameTypography.small.copyWith(
                  color: GameColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: displayColor),
                  const SizedBox(width: 5),
                  Text(
                    '$value',
                    style: GameTypography.stat.copyWith(
                      color: displayColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep old widgets for backward compatibility
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
    return SecondaryStatsRow(
      hunger: hunger,
      thirst: thirst,
      fatigue: fatigue,
      stress: stress,
    );
  }
}

class MoraleBar extends StatelessWidget {
  final int morale;

  const MoraleBar({
    super.key,
    required this.morale,
  });

  @override
  Widget build(BuildContext context) {
    return MoraleDisplay(morale: morale);
  }
}

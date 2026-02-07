import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/game_theme.dart';
import '../../game/state/game_state.dart';

/// Parse log text to extract gains and losses
class LogParser {
  static LogDetails parse(String text) {
    final gains = <LogItem>[];
    final losses = <LogItem>[];

    // Parse gains
    final gainPatterns = [
      RegExp(r'\+(\d+)\s*(?:HP|hp|máu)', caseSensitive: false),
      RegExp(r'\+(\d+)\s*(?:morale|tinh thần)', caseSensitive: false),
      RegExp(r'\+(\d+)\s*(?:defense|phòng thủ)', caseSensitive: false),
      RegExp(r'\+(\d+)\s*(?:hope|hy vọng)', caseSensitive: false),
      RegExp(r'\+(\d+)\s*(?:EP|điểm khám phá)', caseSensitive: false),
      RegExp(r'phòng thủ \+(\d+)', caseSensitive: false),
      RegExp(r'tìm thấy\s+(.+?)(?:\.|,|$)', caseSensitive: false),
      RegExp(r'nhận được\s+(.+?)(?:\.|,|$)', caseSensitive: false),
      RegExp(r'thu được\s+(.+?)(?:\.|,|$)', caseSensitive: false),
      RegExp(r'lấy được\s+(.+?)(?:\.|,|$)', caseSensitive: false),
      RegExp(r'mua\s+(.+?)\s+x(\d+)', caseSensitive: false),
    ];

    for (final pattern in gainPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final value = match.group(1) ?? '';
          final qty = match.groupCount >= 2 ? match.group(2) : null;
          if (value.isNotEmpty) {
            gains.add(LogItem(
              name: value,
              quantity: qty != null ? int.tryParse(qty) : int.tryParse(value),
              type: _getItemType(value, text),
            ));
          }
        }
      }
    }

    // Parse losses
    final lossPatterns = [
      RegExp(r'-(\d+)\s*(?:HP|hp|máu)', caseSensitive: false),
      RegExp(r'mất\s+(\d+)\s*(?:HP|hp|máu)?', caseSensitive: false),
      RegExp(r'-(\d+)\s*(?:morale|tinh thần)', caseSensitive: false),
      RegExp(r'thiếu\s+(\d+)\s*(.+?)(?:\.|,|$)', caseSensitive: false),
      RegExp(r'bán\s+(.+?)\s+x(\d+)', caseSensitive: false),
      RegExp(r'tiêu hao\s+(.+?)(?:\.|,|$)', caseSensitive: false),
    ];

    for (final pattern in lossPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.groupCount >= 1) {
          final value = match.group(1) ?? '';
          final qty = match.groupCount >= 2 ? match.group(2) : null;
          if (value.isNotEmpty) {
            losses.add(LogItem(
              name: value,
              quantity: qty != null ? int.tryParse(qty) : int.tryParse(value),
              type: _getItemType(value, text),
            ));
          }
        }
      }
    }

    return LogDetails(gains: gains, losses: losses);
  }

  static LogItemType _getItemType(String value, String text) {
    final lowerText = text.toLowerCase();
    final lowerValue = value.toLowerCase();

    if (lowerValue.contains('hp') ||
        lowerValue.contains('máu') ||
        lowerText.contains('hp')) {
      return LogItemType.health;
    }
    if (lowerValue.contains('morale') || lowerValue.contains('tinh thần')) {
      return LogItemType.morale;
    }
    if (lowerValue.contains('defense') || lowerValue.contains('phòng thủ')) {
      return LogItemType.defense;
    }
    if (lowerValue.contains('ep') || lowerValue.contains('điểm khám phá')) {
      return LogItemType.exploration;
    }
    return LogItemType.item;
  }
}

class LogDetails {
  final List<LogItem> gains;
  final List<LogItem> losses;

  const LogDetails({required this.gains, required this.losses});

  bool get isEmpty => gains.isEmpty && losses.isEmpty;
  bool get hasGains => gains.isNotEmpty;
  bool get hasLosses => losses.isNotEmpty;
}

class LogItem {
  final String name;
  final int? quantity;
  final LogItemType type;

  const LogItem({required this.name, this.quantity, required this.type});
}

enum LogItemType { item, health, morale, defense, exploration, currency }

/// Category for log entries
class LogCategory {
  final IconData icon;
  final Color color;
  final String label;
  final int priority;

  const LogCategory({
    required this.icon,
    required this.color,
    required this.label,
    this.priority = 0,
  });
}

LogCategory categorizeLogEntry(String text) {
  final lowerText = text.toLowerCase();

  if (lowerText.contains('zombie') ||
      lowerText.contains('tấn công') ||
      lowerText.contains('chiến đấu') ||
      lowerText.contains('chết') ||
      lowerText.contains('bị thương') ||
      lowerText.contains('mất máu') ||
      lowerText.contains('💀') ||
      lowerText.contains('🧟') ||
      lowerText.contains('⚔️')) {
    return const LogCategory(
      icon: Icons.warning_amber_rounded,
      color: GameColors.danger,
      label: 'Nguy hiểm',
      priority: 10,
    );
  }

  if (lowerText.contains('nhiệm vụ') ||
      lowerText.contains('quest') ||
      lowerText.contains('📋') ||
      lowerText.contains('nhận nhiệm vụ')) {
    return const LogCategory(
      icon: Icons.assignment_rounded,
      color: GameColors.gold,
      label: 'Nhiệm vụ',
      priority: 8,
    );
  }

  if (lowerText.contains('tìm thấy') ||
      lowerText.contains('nhận được') ||
      lowerText.contains('thu được') ||
      lowerText.contains('thành công') ||
      lowerText.contains('hoàn thành') ||
      lowerText.contains('chế tạo được') ||
      lowerText.contains('🔨') ||
      lowerText.contains('✅') ||
      lowerText.contains('🎒')) {
    return const LogCategory(
      icon: Icons.check_circle_outline_rounded,
      color: GameColors.success,
      label: 'Thành công',
      priority: 6,
    );
  }

  if (lowerText.contains('mua') ||
      lowerText.contains('bán') ||
      lowerText.contains('💰') ||
      lowerText.contains('giao dịch')) {
    return const LogCategory(
      icon: Icons.monetization_on_rounded,
      color: GameColors.gold,
      label: 'Giao dịch',
      priority: 5,
    );
  }

  if (lowerText.contains('khám phá') ||
      lowerText.contains('tìm kiếm') ||
      lowerText.contains('lục lọi') ||
      lowerText.contains('kết thúc khám phá') ||
      lowerText.contains('🧭') ||
      lowerText.contains('🔍')) {
    return const LogCategory(
      icon: Icons.explore_rounded,
      color: GameColors.info,
      label: 'Khám phá',
      priority: 5,
    );
  }

  if (lowerText.contains('cảnh báo') ||
      lowerText.contains('thiếu') ||
      lowerText.contains('hết') ||
      lowerText.contains('không đủ') ||
      lowerText.contains('⚠️')) {
    return const LogCategory(
      icon: Icons.error_outline_rounded,
      color: GameColors.warning,
      label: 'Cảnh báo',
      priority: 7,
    );
  }

  if (lowerText.contains('radio') ||
      lowerText.contains('tín hiệu') ||
      lowerText.contains('liên lạc') ||
      lowerText.contains('📻') ||
      lowerText.contains('📡')) {
    return const LogCategory(
      icon: Icons.radio_rounded,
      color: GameColors.info,
      label: 'Tín hiệu',
      priority: 4,
    );
  }

  if (lowerText.contains('nghỉ ngơi') ||
      lowerText.contains('ngủ') ||
      lowerText.contains('hồi phục') ||
      lowerText.contains('😴')) {
    return const LogCategory(
      icon: Icons.bedtime_rounded,
      color: GameColors.fatigue,
      label: 'Nghỉ ngơi',
      priority: 3,
    );
  }

  if (lowerText.contains('đêm') || lowerText.contains('🌙')) {
    return const LogCategory(
      icon: Icons.nightlight_rounded,
      color: GameColors.textMuted,
      label: 'Ban đêm',
      priority: 4,
    );
  }

  if (lowerText.contains('ngày') &&
      (lowerText.contains('bắt đầu') ||
          lowerText.contains('kết thúc') ||
          lowerText.contains('thức dậy'))) {
    return const LogCategory(
      icon: Icons.wb_sunny_rounded,
      color: GameColors.gold,
      label: 'Thời gian',
      priority: 2,
    );
  }

  return const LogCategory(
    icon: Icons.info_outline_rounded,
    color: GameColors.textSecondary,
    label: 'Hệ thống',
    priority: 1,
  );
}

/// Main log feed widget - shows current day logs with expand option
class CollapsibleLogFeed extends StatefulWidget {
  final List<LogEntry> entries;
  final int currentDay;

  const CollapsibleLogFeed({
    super.key,
    required this.entries,
    this.currentDay = 1,
  });

  @override
  State<CollapsibleLogFeed> createState() => _CollapsibleLogFeedState();
}

class _CollapsibleLogFeedState extends State<CollapsibleLogFeed> {
  bool _isExpanded = false;
  static const int _collapsedCount = 3;
  static const int _expandedCount = 8;

  // Get entries for current day only
  List<LogEntry> get _currentDayEntries {
    return widget.entries.where((e) => e.day == widget.currentDay).toList();
  }

  // Get entries to display based on expanded state
  List<LogEntry> get _displayEntries {
    final entries = _currentDayEntries;
    final limit = _isExpanded ? _expandedCount : _collapsedCount;
    return entries.take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return _buildEmptyState();
    }

    final currentDayEntries = _currentDayEntries;
    final displayEntries = _displayEntries;
    final hasMoreToShow = currentDayEntries.length > _collapsedCount;
    final totalDays = widget.entries.map((e) => e.day).toSet().length;

    return Container(
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameColors.surfaceLight.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with View All button
          _buildHeader(currentDayEntries.length, totalDays),

          // Current day entries
          if (displayEntries.isEmpty)
            _buildNoDayEntries()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: -30.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      for (var i = 0; i < displayEntries.length; i++)
                        _LogEntryTile(
                          entry: displayEntries[i],
                          isFirst: i == 0,
                          isLast: i == displayEntries.length - 1,
                          isNew: i == 0,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Expand/Collapse button
          if (hasMoreToShow)
            _buildExpandButton(currentDayEntries.length - _collapsedCount),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(int todayCount, int totalDays) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameColors.surfaceLighter,
            GameColors.surfaceLight,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GameColors.info.withOpacity(0.25),
                  GameColors.info.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GameColors.info.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 18,
              color: GameColors.info,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhật ký',
                  style: GameTypography.heading4.copyWith(
                    fontSize: 16,
                    color: GameColors.textPrimary,
                  ),
                ),
                Text(
                  'Ngày ${widget.currentDay} • $todayCount mục',
                  style: GameTypography.small.copyWith(
                    color: GameColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // View All button (next to title)
          if (totalDays > 0)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openFullLogScreen(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: GameColors.info.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: GameColors.info.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: GameColors.info,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tất cả',
                        style: GameTypography.buttonSmall.copyWith(
                          color: GameColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandButton(int remainingCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _isExpanded = !_isExpanded);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: GameColors.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: GameColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  _isExpanded ? 'Thu gọn' : 'Xem thêm ($remainingCount)',
                  style: GameTypography.buttonSmall.copyWith(
                    color: GameColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameColors.surfaceLight.withOpacity(0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GameColors.surfaceLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 32,
              color: GameColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nhật ký trống',
            style: GameTypography.bodyMedium.copyWith(
              color: GameColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDayEntries() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Chưa có sự kiện nào trong ngày ${widget.currentDay}',
        style: GameTypography.bodySmall.copyWith(
          color: GameColors.textMuted,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _openFullLogScreen(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullLogScreen(
          entries: widget.entries,
          initialDay: widget.currentDay,
        ),
      ),
    );
  }
}

/// Log entry tile - compact design
class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;
  final bool isFirst;
  final bool isLast;
  final bool isNew;

  const _LogEntryTile({
    required this.entry,
    this.isFirst = false,
    this.isLast = false,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final category = categorizeLogEntry(entry.text);
    final details = LogParser.parse(entry.text);

    return GestureDetector(
      onTap: () => _showDetail(context, category, details),
      child: Container(
        margin: EdgeInsets.only(
          top: isFirst ? 0 : 3,
          bottom: isLast ? 0 : 3,
        ),
        decoration: BoxDecoration(
          color: isNew ? category.color.withOpacity(0.06) : GameColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNew
                ? category.color.withOpacity(0.35)
                : category.color.withOpacity(0.12),
            width: isNew ? 1.5 : 1,
          ),
          boxShadow: isNew
              ? [
                  BoxShadow(
                    color: category.color.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color indicator
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(category.icon,
                                    size: 11, color: category.color),
                                const SizedBox(width: 4),
                                Text(
                                  category.label,
                                  style: TextStyle(
                                    color: category.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: GameColors.textMuted.withOpacity(0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Text
                      Text(
                        entry.text,
                        style: GameTypography.bodySmall.copyWith(
                          color: GameColors.textPrimary,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Quick details
                      if (!details.isEmpty) ...[
                        const SizedBox(height: 6),
                        _QuickDetailsRow(details: details),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(
      BuildContext context, LogCategory category, LogDetails details) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LogDetailSheet(
        entry: entry,
        category: category,
        details: details,
      ),
    );
  }
}

/// Quick gain/loss chips
class _QuickDetailsRow extends StatelessWidget {
  final LogDetails details;

  const _QuickDetailsRow({required this.details});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 3,
      children: [
        if (details.hasGains)
          for (final gain in details.gains.take(2))
            _QuickChip(
              text: gain.quantity != null ? '+${gain.quantity}' : gain.name,
              color: GameColors.success,
              isGain: true,
            ),
        if (details.hasLosses)
          for (final loss in details.losses.take(2))
            _QuickChip(
              text: loss.quantity != null ? '-${loss.quantity}' : loss.name,
              color: GameColors.danger,
              isGain: false,
            ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool isGain;

  const _QuickChip({
    required this.text,
    required this.color,
    required this.isGain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGain ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 9,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail sheet for single entry
class _LogDetailSheet extends StatelessWidget {
  final LogEntry entry;
  final LogCategory category;
  final LogDetails details;

  const _LogDetailSheet({
    required this.entry,
    required this.category,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: category.color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category.color.withOpacity(0.15),
                  category.color.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(23)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: category.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: GameTypography.heading4.copyWith(
                          color: category.color,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Ngày ${entry.day}',
                        style: GameTypography.bodySmall.copyWith(
                          color: GameColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: GameColors.textMuted,
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: GameTypography.bodyMedium.copyWith(
                    color: GameColors.textPrimary,
                    height: 1.5,
                    fontSize: 16,
                  ),
                ),
                if (details.hasGains) ...[
                  const SizedBox(height: 20),
                  _DetailSection(
                    title: 'Nhận được',
                    icon: Icons.add_circle_rounded,
                    color: GameColors.success,
                    items: details.gains,
                  ),
                ],
                if (details.hasLosses) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Mất',
                    icon: Icons.remove_circle_rounded,
                    color: GameColors.danger,
                    items: details.losses,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<LogItem> items;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GameTypography.buttonSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.quantity != null
                            ? '${item.name} x${item.quantity}'
                            : item.name,
                        style: GameTypography.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Full log screen with day pagination
class FullLogScreen extends StatefulWidget {
  final List<LogEntry> entries;
  final int initialDay;

  const FullLogScreen({
    super.key,
    required this.entries,
    this.initialDay = 1,
  });

  @override
  State<FullLogScreen> createState() => _FullLogScreenState();
}

class _FullLogScreenState extends State<FullLogScreen> {
  late int _selectedDay;
  late PageController _pageController;
  String? _selectedCategory;

  // Get all unique days
  List<int> get _allDays {
    final days = widget.entries.map((e) => e.day).toSet().toList();
    days.sort((a, b) => b.compareTo(a)); // Newest first
    return days;
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
    final initialPage = _allDays.indexOf(_selectedDay);
    _pageController = PageController(
      initialPage: initialPage >= 0 ? initialPage : 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allDays = _allDays;

    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        backgroundColor: GameColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: GameColors.textPrimary,
        ),
        title: Text(
          'Nhật ký sinh tồn',
          style: GameTypography.heading4.copyWith(
            color: GameColors.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GameColors.info.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.entries.length} mục',
              style:
                  GameTypography.buttonSmall.copyWith(color: GameColors.info),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Day selector tabs
          _buildDayTabs(allDays),

          // Category filter
          _buildCategoryFilter(),

          // Entries list
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedDay = allDays[index]);
              },
              itemCount: allDays.length,
              itemBuilder: (context, index) {
                final day = allDays[index];
                final entries = widget.entries
                    .where((e) => e.day == day)
                    .where((e) =>
                        _selectedCategory == null ||
                        categorizeLogEntry(e.text).label == _selectedCategory)
                    .toList();

                return _DayEntriesList(entries: entries, day: day);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs(List<int> days) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: GameColors.surface,
        border: Border(
          bottom: BorderSide(
            color: GameColors.surfaceLight,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _selectedDay == day;
          final entriesCount = widget.entries.where((e) => e.day == day).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDay = day);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            GameColors.gold,
                            GameColors.gold.withOpacity(0.8),
                          ],
                        )
                      : null,
                  color: isSelected ? null : GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? GameColors.gold
                        : GameColors.surfaceLighter,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: GameColors.gold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ngày $day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : GameColors.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : GameColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$entriesCount',
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : GameColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      null,
      'Nguy hiểm',
      'Nhiệm vụ',
      'Thành công',
      'Cảnh báo',
      'Khám phá',
      'Giao dịch',
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final label = cat ?? 'Tất cả';

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = cat);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? GameColors.info : GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : GameColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Entries list for a specific day
class _DayEntriesList extends StatelessWidget {
  final List<LogEntry> entries;
  final int day;

  const _DayEntriesList({required this.entries, required this.day});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: GameColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Không có sự kiện nào',
              style: GameTypography.bodyMedium.copyWith(
                color: GameColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final category = categorizeLogEntry(entry.text);
        final details = LogParser.parse(entry.text);

        return _FullLogEntryCard(
          entry: entry,
          category: category,
          details: details,
          index: index + 1,
        );
      },
    );
  }
}

/// Full log entry card with more details
class _FullLogEntryCard extends StatelessWidget {
  final LogEntry entry;
  final LogCategory category;
  final LogDetails details;
  final int index;

  const _FullLogEntryCard({
    required this.entry,
    required this.category,
    required this.details,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _LogDetailSheet(
            entry: entry,
            category: category,
            details: details,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: GameColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: category.color.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline with number
              Container(
                width: 40,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(category.icon,
                                    size: 12, color: category.color),
                                const SizedBox(width: 4),
                                Text(
                                  category.label,
                                  style: TextStyle(
                                    color: category.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: GameColors.textMuted.withOpacity(0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Text
                      Text(
                        entry.text,
                        style: GameTypography.bodyMedium.copyWith(
                          color: GameColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      // Details
                      if (!details.isEmpty) ...[
                        const SizedBox(height: 10),
                        _QuickDetailsRow(details: details),
                      ],
                    ],
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

/// Legacy LogFeed for backwards compatibility
class LogFeed extends StatelessWidget {
  final List<LogEntry> entries;
  final int maxEntries;
  final bool expanded;

  const LogFeed({
    super.key,
    required this.entries,
    this.maxEntries = 5,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get current day from entries
    final currentDay = entries.isNotEmpty ? entries.first.day : 1;
    return CollapsibleLogFeed(entries: entries, currentDay: currentDay);
  }
}

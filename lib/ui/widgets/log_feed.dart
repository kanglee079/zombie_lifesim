import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/game_theme.dart';
import '../../game/state/game_state.dart';

/// Log feed widget showing recent game events
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
    final displayEntries = expanded
        ? entries
        : entries.take(maxEntries).toList();

    return Container(
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GameColors.surfaceLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: GameColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 16,
                  color: GameColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nhật ký',
                  style: GameTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entries.length} mục',
                  style: GameTypography.caption,
                ),
              ],
            ),
          ),

          // Entries
          if (displayEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chưa có sự kiện nào.',
                style: GameTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          else
            AnimationLimiter(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: displayEntries.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 12,
                  endIndent: 12,
                ),
                itemBuilder: (context, index) {
                  final entry =
                      displayEntries[displayEntries.length - 1 - index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 260),
                    child: SlideAnimation(
                      verticalOffset: 12.0,
                      child: FadeInAnimation(
                        child: _LogEntryTile(entry: entry),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: GameColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'D${entry.day}',
              style: GameTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Entry text
          Expanded(
            child: Text(
              entry.text,
              style: GameTypography.logEntry,
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible log feed
class CollapsibleLogFeed extends StatefulWidget {
  final List<LogEntry> entries;

  const CollapsibleLogFeed({
    super.key,
    required this.entries,
  });

  @override
  State<CollapsibleLogFeed> createState() => _CollapsibleLogFeedState();
}

class _CollapsibleLogFeedState extends State<CollapsibleLogFeed> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LogFeed(
          entries: widget.entries,
          maxEntries: _expanded ? 20 : 3,
          expanded: _expanded,
        ),
        if (widget.entries.length > 3)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
          ),
      ],
    );
  }
}

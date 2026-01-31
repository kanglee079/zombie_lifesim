import 'package:flutter/material.dart';
import '../theme/game_theme.dart';
import '../../game/state/game_state.dart';

/// Log feed widget showing recent game events
class LogFeed extends StatefulWidget {
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
  State<LogFeed> createState() => _LogFeedState();
}

class _LogFeedState extends State<LogFeed> {
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<LogEntry> _displayEntries = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _displayEntries = _buildDisplayEntries(widget.entries);
    _initialized = true;
  }

  @override
  void didUpdateWidget(covariant LogFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextEntries = _buildDisplayEntries(widget.entries);

    if (oldWidget.expanded != widget.expanded ||
        oldWidget.maxEntries != widget.maxEntries ||
        widget.entries.length < oldWidget.entries.length) {
      setState(() {
        _displayEntries = nextEntries;
        _listKey = GlobalKey<AnimatedListState>();
      });
      return;
    }

    if (!_initialized) {
      setState(() {
        _displayEntries = nextEntries;
      });
      return;
    }

    if (nextEntries.length > _displayEntries.length) {
      final addedCount = nextEntries.length - _displayEntries.length;
      final added = nextEntries.take(addedCount).toList();
      for (final entry in added.reversed) {
        _displayEntries.insert(0, entry);
        _listKey.currentState?.insertItem(
          0,
          duration: const Duration(milliseconds: 260),
        );
      }
      setState(() {});
      return;
    }

    if (nextEntries.length != _displayEntries.length) {
      setState(() {
        _displayEntries = nextEntries;
      });
    }
  }

  List<LogEntry> _buildDisplayEntries(List<LogEntry> entries) {
    final sliced = widget.expanded ? entries : entries.take(widget.maxEntries).toList();
    return sliced.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayEntries = _displayEntries;

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
                  '${widget.entries.length} mục',
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
            AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              initialItemCount: displayEntries.length,
              itemBuilder: (context, index, animation) {
                final entry = displayEntries[index];
                return SizeTransition(
                  sizeFactor: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: Column(
                      children: [
                        if (index > 0)
                          const Divider(
                            height: 1,
                            indent: 12,
                            endIndent: 12,
                          ),
                        _LogEntryTile(entry: entry),
                      ],
                    ),
                  ),
                );
              },
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

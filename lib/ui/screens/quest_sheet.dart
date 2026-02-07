import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';
import '../../data/models/quest_def.dart';
import '../../game/state/game_state.dart';

/// Quest journal sheet
class QuestSheet extends ConsumerWidget {
  const QuestSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameLoop = ref.watch(gameLoopProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: GameColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: GameColors.info),
                    const SizedBox(width: 12),
                    Text('Nhật ký nhiệm vụ', style: GameTypography.heading2),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: gameLoop.when(
                  data: (loop) {
                    final quests = loop.getActiveQuests();

                    if (quests.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.assignment_outlined,
                        label: 'Chưa có nhiệm vụ nào đang hoạt động',
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: quests.length,
                      itemBuilder: (context, index) {
                        final (quest, state) = quests[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QuestCard(quest: quest, state: state),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: GameColors.info),
                  ),
                  error: (e, _) => Center(
                    child: Text('Lỗi: $e', style: GameTypography.body),
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

class _QuestCard extends StatelessWidget {
  final QuestDef quest;
  final QuestState state;

  const _QuestCard({required this.quest, required this.state});

  @override
  Widget build(BuildContext context) {
    final stage = quest.getStage(state.stage);
    final stageTitle = stage?.title ?? 'Giai đoạn ${state.stage}';
    final objective = stage?.objective ?? quest.description;
    final hint = stage?.hint?.toString();
    final isEnding = quest.type == 'ending';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnding
              ? GameColors.gold.withOpacity(0.4)
              : GameColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnding
                      ? GameColors.gold.withOpacity(0.15)
                      : GameColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEnding ? Icons.flag : Icons.assignment,
                  color: isEnding ? GameColors.gold : GameColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.name,
                      style: GameTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      stageTitle,
                      style: GameTypography.caption,
                    ),
                  ],
                ),
              ),
              if (isEnding)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GameColors.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ENDING',
                    style: GameTypography.caption.copyWith(
                      color: GameColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (objective.isNotEmpty)
            Text(objective, style: GameTypography.bodySmall),
          if (hint != null && hint.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Gợi ý: $hint',
              style: GameTypography.caption.copyWith(
                color: GameColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: GameColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            label,
            style: GameTypography.body.copyWith(color: GameColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

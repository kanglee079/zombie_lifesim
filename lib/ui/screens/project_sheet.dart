import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';
import '../../game/game_loop.dart';
import '../../game/systems/project_system.dart';

/// Long-term base projects sheet
class ProjectSheet extends ConsumerWidget {
  const ProjectSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
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
                    const Icon(Icons.construction, color: GameColors.gold),
                    const SizedBox(width: 12),
                    Text('Dự án căn cứ', style: GameTypography.heading2),
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
                    final active = loop.getActiveProjectsProgress();
                    final available = loop.getAvailableProjects();

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (gameState == null)
                          _EmptyState(
                            icon: Icons.construction_outlined,
                            label: 'Chưa có dữ liệu dự án',
                          )
                        else ...[
                          if (active.isNotEmpty) ...[
                            Text('Đang thực hiện', style: GameTypography.heading3),
                            const SizedBox(height: 8),
                            ...active.map(
                              (project) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ActiveProjectCard(project: project),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text('Dự án khả dụng', style: GameTypography.heading3),
                          const SizedBox(height: 8),
                          if (available.isEmpty)
                            _EmptyState(
                              icon: Icons.build_outlined,
                              label: 'Chưa có dự án phù hợp ngày này',
                            )
                          else
                            ...available.map((project) {
                              final projectId = project['id']?.toString() ?? '';
                              final canStart = loop.canStartProject(projectId);
                              final missing = loop.getProjectMissingItems(projectId);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ProjectCard(
                                  project: project,
                                  canStart: canStart,
                                  missingItems: missing,
                                  onStart: () {
                                    final started = ref
                                        .read(gameStateProvider.notifier)
                                        .startProject(projectId);
                                    if (started) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Đã bắt đầu dự án ${project['name']}'),
                                          backgroundColor: GameColors.success,
                                        ),
                                      );
                                    }
                                  },
                                  loop: loop,
                                ),
                              );
                            }),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: GameColors.gold),
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

class _ActiveProjectCard extends StatelessWidget {
  final ProjectProgress project;

  const _ActiveProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final progress = project.progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.info.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GameColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer, color: GameColors.info, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: GameTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${project.daysRemaining} ngày còn lại',
                      style: GameTypography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GameTypography.caption.copyWith(
                  color: GameColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            color: GameColors.info,
            backgroundColor: GameColors.surfaceLight,
            minHeight: 6,
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(project.description, style: GameTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final bool canStart;
  final List<Map<String, dynamic>> missingItems;
  final VoidCallback onStart;
  final GameLoop loop;

  const _ProjectCard({
    required this.project,
    required this.canStart,
    required this.missingItems,
    required this.onStart,
    required this.loop,
  });

  @override
  Widget build(BuildContext context) {
    final duration = project['duration'] as int? ?? 1;
    final description = project['description']?.toString() ?? '';
    final requirements =
        (project['requirements'] as Map<String, dynamic>?)?['items'] as List? ??
            const <dynamic>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canStart
              ? GameColors.success.withOpacity(0.5)
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
                  color: GameColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.construction,
                    color: GameColors.gold, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['name']?.toString() ?? 'Dự án',
                      style: GameTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('$duration ngày', style: GameTypography.caption),
                  ],
                ),
              ),
              if (canStart)
                ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.success,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Bắt đầu'),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Thiếu NVL',
                    style: GameTypography.caption.copyWith(
                      color: GameColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(description, style: GameTypography.bodySmall),
          ],
          const SizedBox(height: 10),
          _RequirementList(
            requirements: requirements,
            missingItems: missingItems,
            loop: loop,
          ),
          if (!canStart && missingItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MissingHintList(missingItems: missingItems),
          ],
        ],
      ),
    );
  }
}

class _RequirementList extends StatelessWidget {
  final List<dynamic> requirements;
  final List<Map<String, dynamic>> missingItems;
  final GameLoop loop;

  const _RequirementList({
    required this.requirements,
    required this.missingItems,
    required this.loop,
  });

  @override
  Widget build(BuildContext context) {
    if (requirements.isEmpty) {
      return Text('Không cần nguyên liệu.', style: GameTypography.caption);
    }

    final missingIds = missingItems.map((e) => e['id']).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nguyên liệu', style: GameTypography.caption),
        const SizedBox(height: 6),
        ...requirements.map((req) {
          final itemId = req['id']?.toString() ?? '';
          final qty = req['qty'] as int? ?? 1;
          final item = loop.data.getItem(itemId);
          final name = item?.name ?? itemId;
          final isMissing = missingIds.contains(itemId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  isMissing ? Icons.close : Icons.check,
                  size: 14,
                  color: isMissing ? GameColors.danger : GameColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$name x$qty',
                    style: GameTypography.caption.copyWith(
                      color:
                          isMissing ? GameColors.textMuted : GameColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MissingHintList extends StatelessWidget {
  final List<Map<String, dynamic>> missingItems;

  const _MissingHintList({required this.missingItems});

  @override
  Widget build(BuildContext context) {
    final hints = missingItems
        .map((item) => item['hint']?.toString() ?? '')
        .where((hint) => hint.trim().isNotEmpty)
        .toList();

    if (hints.isEmpty) {
      return Text(
        'Bạn cần tìm thêm nguyên liệu phù hợp.',
        style: GameTypography.caption.copyWith(color: GameColors.textMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gợi ý tìm kiếm', style: GameTypography.caption),
        const SizedBox(height: 4),
        ...hints.map(
          (hint) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $hint',
              style: GameTypography.caption.copyWith(
                color: GameColors.textMuted,
              ),
            ),
          ),
        ),
      ],
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

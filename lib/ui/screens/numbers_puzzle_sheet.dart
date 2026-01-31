import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';

class NumbersPuzzleSheet extends ConsumerStatefulWidget {
  const NumbersPuzzleSheet({super.key});

  @override
  ConsumerState<NumbersPuzzleSheet> createState() => _NumbersPuzzleSheetState();
}

class _NumbersPuzzleSheetState extends ConsumerState<NumbersPuzzleSheet> {
  String _district = 'A';
  int _grid = 1;
  int _locker = 1;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final notes = gameState?.notes ?? const <String, String>{};
    final sequence = notes['numbers_seq'] ?? '...';
    final hint = notes['numbers_hint'] ??
        'Gợi ý: Cộng từng nhóm, lấy số dư 6 (0=6). Nhóm 1=quận, nhóm 2=ô, nhóm 3=tủ.';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
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
                    const Icon(Icons.numbers, color: GameColors.info),
                    const SizedBox(width: 12),
                    Text('Numbers Station', style: GameTypography.heading2),
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
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Dãy số ghi lại', style: GameTypography.heading3),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GameColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sequence,
                        style: GameTypography.body.copyWith(letterSpacing: 1.1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Gợi ý', style: GameTypography.heading3),
                    const SizedBox(height: 6),
                    Text(hint, style: GameTypography.bodySmall),
                    const SizedBox(height: 20),
                    Text('Nhập toạ độ', style: GameTypography.heading3),
                    const SizedBox(height: 12),
                    _buildSelectors(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: gameState == null
                          ? null
                          : () {
                              final result = ref
                                  .read(gameStateProvider.notifier)
                                  .submitNumbersPuzzle(
                                    district: _district,
                                    grid: _grid,
                                    locker: _locker,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: result.success
                                      ? GameColors.success
                                      : GameColors.warning,
                                ),
                              );
                              if (result.success) {
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameColors.info,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Giải mã'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectors() {
    return Row(
      children: [
        Expanded(
          child: _SelectorCard(
            label: 'Quận',
            child: DropdownButton<String>(
              value: _district,
              dropdownColor: GameColors.surface,
              items: ['A', 'B', 'C', 'D', 'E', 'F']
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(d, style: GameTypography.body),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _district = value);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectorCard(
            label: 'Ô',
            child: DropdownButton<int>(
              value: _grid,
              dropdownColor: GameColors.surface,
              items: List.generate(
                6,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1}', style: GameTypography.body),
                ),
              ),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _grid = value);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectorCard(
            label: 'Tủ',
            child: DropdownButton<int>(
              value: _locker,
              dropdownColor: GameColors.surface,
              items: List.generate(
                6,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1}', style: GameTypography.body),
                ),
              ),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _locker = value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectorCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _SelectorCard({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GameColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GameTypography.caption),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

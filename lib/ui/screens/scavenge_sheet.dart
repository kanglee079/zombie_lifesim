import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';
import '../../game/systems/scavenge_system.dart';

/// Scavenge bottom sheet
class ScavengeSheet extends ConsumerStatefulWidget {
  const ScavengeSheet({super.key});

  @override
  ConsumerState<ScavengeSheet> createState() => _ScavengeSheetState();
}

class _ScavengeSheetState extends ConsumerState<ScavengeSheet> {
  String? _selectedLocation;
  ScavengeTime _selectedTime = ScavengeTime.normal;
  ScavengeStyle _selectedStyle = ScavengeStyle.balanced;

  @override
  Widget build(BuildContext context) {
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
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.explore, color: GameColors.warning),
                    const SizedBox(width: 12),
                    Text('Khám phá', style: GameTypography.heading2),
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
                    final locations = loop.getScavengeLocations();

                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Location selection
                          Text('Chọn địa điểm', style: GameTypography.heading3),
                          const SizedBox(height: 12),
                          _buildLocationGrid(locations, loop.data),

                          const SizedBox(height: 24),

                          // Time selection
                          Text('Thời gian', style: GameTypography.heading3),
                          const SizedBox(height: 12),
                          _buildTimeSelection(),

                          const SizedBox(height: 24),

                          // Style selection
                          Text('Phong cách', style: GameTypography.heading3),
                          const SizedBox(height: 12),
                          _buildStyleSelection(),

                          const SizedBox(height: 24),

                          // Go button
                          ElevatedButton(
                            onPressed: _selectedLocation != null
                                ? () => _doScavenge(context, ref)
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: GameColors.warning,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.directions_run),
                                const SizedBox(width: 8),
                                Text(
                                  'Bắt đầu khám phá',
                                  style: GameTypography.button,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Text('Lỗi: $e'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationGrid(List<String> locations, dynamic data) {
    if (locations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: GameColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Chưa mở khóa địa điểm nào',
            style: GameTypography.bodySmall,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: locations.map((locId) {
        final location = data.getLocation(locId);
        final isSelected = _selectedLocation == locId;

        return InkWell(
          onTap: () => setState(() => _selectedLocation = locId),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? GameColors.warning.withOpacity(0.2)
                  : GameColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? GameColors.warning : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.place,
                  size: 18,
                  color: isSelected ? GameColors.warning : GameColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  location?.name ?? locId,
                  style: GameTypography.button.copyWith(
                    color: isSelected
                        ? GameColors.warning
                        : GameColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelection() {
    return Row(
      children: ScavengeTime.values.map((time) {
        final isSelected = _selectedTime == time;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedTime = time),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GameColors.info.withOpacity(0.2)
                      : GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? GameColors.info : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _getTimeLabel(time),
                      style: GameTypography.button.copyWith(
                        color: isSelected
                            ? GameColors.info
                            : GameColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${time.minutes} phút',
                      style: GameTypography.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStyleSelection() {
    return Row(
      children: ScavengeStyle.values.map((style) {
        final isSelected = _selectedStyle == style;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedStyle = style),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GameColors.success.withOpacity(0.2)
                      : GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? GameColors.success : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getStyleIcon(style),
                      size: 24,
                      color: isSelected
                          ? GameColors.success
                          : GameColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStyleLabel(style),
                      style: GameTypography.caption.copyWith(
                        color: isSelected
                            ? GameColors.success
                            : GameColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getTimeLabel(ScavengeTime time) {
    switch (time) {
      case ScavengeTime.quick:
        return 'Nhanh';
      case ScavengeTime.normal:
        return 'Bình thường';
      case ScavengeTime.thorough:
        return 'Kỹ lưỡng';
    }
  }

  String _getStyleLabel(ScavengeStyle style) {
    switch (style) {
      case ScavengeStyle.stealth:
        return 'Lén lút';
      case ScavengeStyle.balanced:
        return 'Cân bằng';
      case ScavengeStyle.aggressive:
        return 'Tấn công';
    }
  }

  IconData _getStyleIcon(ScavengeStyle style) {
    switch (style) {
      case ScavengeStyle.stealth:
        return Icons.visibility_off;
      case ScavengeStyle.balanced:
        return Icons.balance;
      case ScavengeStyle.aggressive:
        return Icons.local_fire_department;
    }
  }

  void _doScavenge(BuildContext context, WidgetRef ref) {
    ref.read(gameStateProvider.notifier).doScavenge(
      locationId: _selectedLocation!,
      time: _selectedTime,
      style: _selectedStyle,
    );
    Navigator.pop(context);
  }
}

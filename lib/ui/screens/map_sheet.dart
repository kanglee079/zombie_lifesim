import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';

/// Map bottom sheet for district and location management
class MapSheet extends ConsumerWidget {
  const MapSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameLoop = ref.watch(gameLoopProvider);
    final gameState = ref.watch(gameStateProvider);

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
                    const Icon(Icons.map, color: GameColors.success),
                    const SizedBox(width: 12),
                    Text('Bản đồ', style: GameTypography.heading2),
                    const Spacer(),
                    // EP indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: GameColors.info.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.explore,
                            size: 14,
                            color: GameColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'EP: ${gameState?.baseStats.explorationPoints ?? 0}',
                            style: GameTypography.caption.copyWith(
                              color: GameColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Districts list
              Expanded(
                child: gameLoop.when(
                  data: (loop) {
                    final districts = loop.data.districts.values.toList();

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: districts.length,
                      itemBuilder: (context, index) {
                        final district = districts[index];
                        final districtState =
                            gameState?.districtStates[district.id];
                        final isUnlocked = district.startUnlocked ||
                            (districtState?.unlocked ?? false);
                        final canUnlock = gameState != null &&
                            gameState.baseStats.explorationPoints >=
                                district.unlockCostEP &&
                            gameState.day >= district.minDay;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _DistrictCard(
                            district: district,
                            isUnlocked: isUnlocked,
                            canUnlock: canUnlock,
                            locations: district.locationIds
                                .map((id) => loop.data.getLocation(id))
                                .whereType<dynamic>()
                                .toList(),
                            locationStates: gameState?.locationStates ?? {},
                            onUnlock: () {
                              ref
                                  .read(gameStateProvider.notifier)
                                  .unlockDistrict(district.id);
                            },
                          ),
                        );
                      },
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
}

class _DistrictCard extends StatelessWidget {
  final dynamic district;
  final bool isUnlocked;
  final bool canUnlock;
  final List<dynamic> locations;
  final Map<String, dynamic> locationStates;
  final VoidCallback onUnlock;

  const _DistrictCard({
    required this.district,
    required this.isUnlocked,
    required this.canUnlock,
    required this.locations,
    required this.locationStates,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? GameColors.success.withOpacity(0.5)
              : GameColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? GameColors.success.withOpacity(0.1)
                  : GameColors.surfaceLight.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? GameColors.success.withOpacity(0.2)
                        : GameColors.textMuted.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isUnlocked ? Icons.lock_open : Icons.lock,
                    size: 20,
                    color:
                        isUnlocked ? GameColors.success : GameColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        district.name,
                        style: GameTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isUnlocked
                              ? GameColors.textPrimary
                              : GameColors.textMuted,
                        ),
                      ),
                      Text(
                        '${locations.length} địa điểm',
                        style: GameTypography.caption,
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  ElevatedButton(
                    onPressed: canUnlock ? onUnlock : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameColors.success,
                      disabledBackgroundColor:
                          GameColors.success.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text('${district.unlockCostEP} EP'),
                  ),
              ],
            ),
          ),

          // Locations
          if (isUnlocked)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Địa điểm:', style: GameTypography.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: locations.map<Widget>((location) {
                      final locState = locationStates[location.id];
                      final depletion = locState?.depletion ?? 0;

                      return _LocationChip(
                        name: location.name,
                        depletion: depletion,
                        risk: location.baseRisk,
                      );
                    }).toList(),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Mở khóa để khám phá khu vực này',
                style: GameTypography.caption.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final String name;
  final int depletion;
  final int risk;

  const _LocationChip({
    required this.name,
    required this.depletion,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: GameColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getDepletionColor(depletion).withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.place,
            size: 14,
            color: _getDepletionColor(depletion),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: GameTypography.caption.copyWith(
              color: GameColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Depletion indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getDepletionColor(depletion),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          // Risk indicator
          Icon(
            Icons.warning_amber,
            size: 12,
            color: _getRiskColor(risk),
          ),
        ],
      ),
    );
  }

  Color _getDepletionColor(int depletion) {
    if (depletion <= 0) return GameColors.success;
    if (depletion <= 2) return GameColors.uncommon;
    if (depletion <= 4) return GameColors.warning;
    if (depletion <= 6) return GameColors.danger;
    return GameColors.textMuted;
  }

  Color _getRiskColor(int risk) {
    if (risk <= 20) return GameColors.success;
    if (risk <= 40) return GameColors.uncommon;
    if (risk <= 60) return GameColors.warning;
    return GameColors.danger;
  }
}

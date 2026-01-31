import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../widgets/stat_bar.dart';
import '../widgets/log_feed.dart';
import '../widgets/event_card.dart';
import '../widgets/action_buttons.dart';
import '../widgets/terminal_overlay.dart';
import '../providers/game_providers.dart';
import 'inventory_sheet.dart';
import 'craft_sheet.dart';
import 'scavenge_sheet.dart';
import 'trade_sheet.dart';
import 'party_sheet.dart';
import 'map_sheet.dart';

/// Main home screen for the game
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final isGameOver = ref.watch(gameOverProvider);

    if (gameState == null) {
      return _buildLoadingScreen();
    }

    if (isGameOver) {
      return _buildGameOverScreen(gameState);
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(gameState),

                // Main content
                Expanded(
                  child: PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation, secondaryAnimation) {
                      return FadeThroughTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        child: child,
                      );
                    },
                    child: _buildTabBody(gameState),
                  ),
                ),
              ],
            ),
          ),
          if (gameState.terminalOverlayEnabled)
            TerminalOverlay(intensity: _overlayIntensity(gameState)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  double _overlayIntensity(dynamic gameState) {
    final signal = (gameState.baseStats.signalHeat as int) / 100;
    final noise = (gameState.baseStats.noise as int) / 100;
    double intensity = 0.12 + signal * 0.5 + noise * 0.2;
    if (gameState.timeOfDay == 'night') {
      intensity += 0.08;
    }
    return intensity.clamp(0.0, 0.9);
  }

  Widget _buildTabBody(dynamic gameState) {
    switch (_currentNavIndex) {
      case 1:
        return const InventorySheet(embedded: true, key: ValueKey('tab_inventory'));
      case 2:
        return const PartySheet(embedded: true, key: ValueKey('tab_party'));
      case 3:
        return const TradeSheet(embedded: true, key: ValueKey('tab_trade'));
      case 4:
        return const MapSheet(embedded: true, key: ValueKey('tab_map'));
      default:
        return _buildOverviewTab(gameState);
    }
  }

  Widget _buildOverviewTab(dynamic gameState) {
    return SingleChildScrollView(
      key: const ValueKey('tab_overview'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats
          _buildStatsPanel(gameState),
          const SizedBox(height: 16),

          // Current event or actions
          if (gameState.currentEvent != null)
            _buildEventCard(gameState)
          else
            _buildActionPanel(gameState),

          const SizedBox(height: 16),

          // Log feed
          CollapsibleLogFeed(entries: gameState.log),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: GameColors.danger),
            const SizedBox(height: 20),
            Text('Đang tải...', style: GameTypography.body),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverScreen(dynamic gameState) {
    final endingId = gameState?.endingId ?? gameState?.endingType;
    final endingGrade = gameState?.endingGrade;
    final summary = (gameState?.endingSummary as List?)?.cast<String>() ?? const <String>[];

    return Scaffold(
      backgroundColor: GameColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                endingId?.contains('death') == true
                    ? Icons.dangerous
                    : Icons.emoji_events,
                size: 80,
                color: endingId?.contains('death') == true
                    ? GameColors.danger
                    : GameColors.gold,
              ),
              const SizedBox(height: 24),
              Text(
                endingId?.contains('death') == true
                    ? 'GAME OVER'
                    : 'KẾT THÚC',
                style: GameTypography.heading1.copyWith(
                  color: endingId?.contains('death') == true
                      ? GameColors.danger
                      : GameColors.gold,
                ),
              ),
              const SizedBox(height: 16),
              if (endingGrade != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    endingGrade.toString().toUpperCase(),
                    style: GameTypography.caption.copyWith(
                      color: GameColors.gold,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (summary.isNotEmpty)
                Column(
                  children: summary
                      .map((line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              line,
                              style: GameTypography.body,
                              textAlign: TextAlign.center,
                            ),
                          ))
                      .toList(),
                )
              else
                Text(
                  _getEndingText(endingId),
                  style: GameTypography.body,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              PrimaryActionButton(
                label: 'Chơi lại',
                icon: Icons.replay,
                onPressed: () {
                  ref.read(gameStateProvider.notifier).newGame();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEndingText(String? ending) {
    switch (ending) {
      case 'death_hp':
        return 'Bạn đã chết vì hết máu. Thế giới tận thế đã cướp đi sinh mạng bạn.';
      case 'death_infection':
        return 'Bạn đã biến thành zombie. Virus đã chiến thắng.';
      default:
        return 'Hành trình của bạn đã kết thúc.';
    }
  }

  Widget _buildHeader(dynamic gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: GameColors.surface,
        border: Border(
          bottom: BorderSide(color: GameColors.surfaceLight),
        ),
      ),
      child: Row(
        children: [
          // Day indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GameColors.danger.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: GameColors.danger),
                const SizedBox(width: 6),
                Text(
                  'Ngày ${gameState.day}',
                  style: GameTypography.button.copyWith(color: GameColors.danger),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Time of day
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GameColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getTimeIcon(gameState.timeOfDay),
                  size: 16,
                  color: GameColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _getTimeText(gameState.timeOfDay),
                  style: GameTypography.bodySmall,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Save button
          IconButton(
            icon: const Icon(Icons.save, size: 22),
            color: GameColors.textSecondary,
            onPressed: () => ref.read(gameStateProvider.notifier).saveGame(),
          ),
          IconButton(
            icon: Icon(
              gameState.terminalOverlayEnabled ? Icons.blur_on : Icons.blur_off,
              size: 22,
            ),
            color: GameColors.textSecondary,
            onPressed: () =>
                ref.read(gameStateProvider.notifier).toggleTerminalOverlay(),
          ),
        ],
      ),
    );
  }

  IconData _getTimeIcon(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning':
        return Icons.wb_sunny;
      case 'day':
        return Icons.light_mode;
      case 'evening':
        return Icons.wb_twilight;
      case 'night':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  String _getTimeText(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning':
        return 'Sáng';
      case 'day':
        return 'Ngày';
      case 'evening':
        return 'Chiều';
      case 'night':
        return 'Đêm';
      default:
        return timeOfDay;
    }
  }

  Widget _buildStatsPanel(dynamic gameState) {
    final stats = gameState.playerStats;
    final base = gameState.baseStats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // HP and Infection bars
          Row(
            children: [
              Expanded(child: HealthBar(hp: stats.hp)),
              const SizedBox(width: 16),
              Expanded(child: InfectionBar(infection: stats.infection)),
            ],
          ),
          const SizedBox(height: 12),

          // Other stats
          StatBarRow(
            hunger: stats.hunger,
            thirst: stats.thirst,
            fatigue: stats.fatigue,
            stress: stats.stress,
          ),
          const SizedBox(height: 10),
          MoraleBar(morale: stats.morale),
          const SizedBox(height: 12),
          BaseStatRow(
            noise: base.noise,
            smell: base.smell,
            hope: base.hope,
            signalHeat: base.signalHeat,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic gameState) {
    final event = gameState.currentEvent;
    if (event == null) return const SizedBox.shrink();

    final motionPreset = _resolveEventMotionPreset(event);
    final choices = (event['choices'] as List? ?? []).asMap().entries.map((e) {
      final choice = e.value as Map<String, dynamic>;
      final enabled = ref.read(gameStateProvider.notifier).isChoiceEnabled(choice);
      return EventChoice(
        index: e.key,
        label: choice['label']?.toString() ?? choice['text']?.toString() ?? 'Chọn',
        hint: enabled ? choice['hint']?.toString() : 'Không đủ điều kiện',
        enabled: enabled,
      );
    }).toList();

    return EventCard(
      title: event['title']?.toString() ?? 'Sự kiện',
      text: event['text']?.toString() ?? '',
      choices: choices,
      motionPreset: motionPreset,
      onChoiceSelected: (index) {
        ref.read(gameStateProvider.notifier).processChoice(index);
      },
    );
  }

  String _resolveEventMotionPreset(Map<String, dynamic> event) {
    final group = event['group']?.toString() ?? '';
    final contexts = event['contexts'] ?? event['context'];
    final contextList = <String>[];
    if (contexts is String) {
      contextList.add(contexts);
    } else if (contexts is List) {
      contextList.addAll(contexts.map((e) => e.toString()));
    }

    final combined = '${group.toLowerCase()} ${contextList.join(' ').toLowerCase()}';
    if (combined.contains('danger')) return 'danger';
    if (combined.contains('radio')) return 'radio';
    if (combined.contains('night')) return 'night';
    if (combined.contains('loot') || combined.contains('scavenge')) return 'loot';
    return 'default';
  }

  Widget _buildActionPanel(dynamic gameState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main actions
        ActionGrid(
          items: [
            ActionGridItem(
              label: 'Khám phá',
              icon: Icons.explore,
              color: GameColors.warning,
              onTap: () => _showScavengeSheet(),
            ),
            ActionGridItem(
              label: 'Chế tạo',
              icon: Icons.build,
              color: GameColors.info,
              onTap: () => _showCraftSheet(),
            ),
            ActionGridItem(
              label: 'Nghỉ ngơi',
              icon: Icons.hotel,
              color: GameColors.fatigue,
              onTap: () {
                ref.read(gameStateProvider.notifier).rest();
                _showActionSnack('😴 Nghỉ ngơi xong. Thể lực hồi lại một chút.');
              },
            ),
            ActionGridItem(
              label: 'Gia cố',
              icon: Icons.security,
              color: GameColors.success,
              onTap: () {
                final hasWood = _hasItemQty(gameState, 'wood_plank', 1);
                final hasNails = _hasItemQty(gameState, 'nails', 1);
                ref.read(gameStateProvider.notifier).fortifyBase();
                if (hasWood && hasNails) {
                  _showActionSnack('🔨 Gia cố thành công. Phòng thủ +5.');
                } else {
                  _showActionSnack('⚠️ Thiếu gỗ hoặc đinh để gia cố.', color: GameColors.warning);
                }
              },
            ),
            ActionGridItem(
              label: 'Radio',
              icon: Icons.radio,
              color: GameColors.danger,
              onTap: () {
                ref.read(gameStateProvider.notifier).useRadio();
                _showActionSnack('📻 Bật radio. Tín hiệu tăng, coi chừng bị để ý.');
              },
            ),
            ActionGridItem(
              label: 'Kết thúc ngày',
              icon: Icons.nightlight,
              color: GameColors.textMuted,
              onTap: () {
                ref.read(gameStateProvider.notifier).nightPhase();
                final day = ref.read(gameStateProvider)?.day ?? gameState.day;
                _showActionSnack('🌙 Kết thúc ngày. Bước sang ngày $day.');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() => _currentNavIndex = index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Tổng quan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Kho đồ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Nhóm',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'Giao dịch',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Bản đồ',
        ),
      ],
    );
  }

  void _showCraftSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CraftSheet(),
    );
  }

  void _showScavengeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ScavengeSheet(),
    );
  }

  bool _hasItemQty(dynamic gameState, String itemId, int qty) {
    if (gameState == null) return false;
    int total = 0;
    for (final stack in gameState.inventory) {
      if (stack.itemId == itemId) {
        final stackQty = (stack.qty as num?)?.toInt() ?? 0;
        total += stackQty;
        if (total >= qty) return true;
      }
    }
    return false;
  }

  void _showActionSnack(String message, {Color? color}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? GameColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

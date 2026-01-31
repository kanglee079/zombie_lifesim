import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../widgets/stat_bar.dart';
import '../widgets/log_feed.dart';
import '../widgets/event_card.dart';
import '../widgets/action_buttons.dart';
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
    final endingType = ref.watch(endingTypeProvider);

    if (gameState == null) {
      return _buildLoadingScreen();
    }

    if (isGameOver) {
      return _buildGameOverScreen(endingType);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(gameState),

            // Main content
            Expanded(
              child: SingleChildScrollView(
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
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

  Widget _buildGameOverScreen(String? ending) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                ending?.contains('death') == true
                    ? Icons.dangerous
                    : Icons.emoji_events,
                size: 80,
                color: ending?.contains('death') == true
                    ? GameColors.danger
                    : GameColors.gold,
              ),
              const SizedBox(height: 24),
              Text(
                ending?.contains('death') == true
                    ? 'GAME OVER'
                    : 'KẾT THÚC',
                style: GameTypography.heading1.copyWith(
                  color: ending?.contains('death') == true
                      ? GameColors.danger
                      : GameColors.gold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getEndingText(ending),
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
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic gameState) {
    final event = gameState.currentEvent;
    if (event == null) return const SizedBox.shrink();

    final choices = (event['choices'] as List? ?? []).asMap().entries.map((e) {
      final choice = e.value as Map<String, dynamic>;
      return EventChoice(
        index: e.key,
        label: choice['label']?.toString() ?? 'Chọn',
        hint: choice['hint']?.toString(),
        enabled: true,
      );
    }).toList();

    return EventCard(
      title: event['title']?.toString() ?? 'Sự kiện',
      text: event['text']?.toString() ?? '',
      choices: choices,
      onChoiceSelected: (index) {
        ref.read(gameStateProvider.notifier).processChoice(index);
      },
    );
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
              onTap: () => ref.read(gameStateProvider.notifier).rest(),
            ),
            ActionGridItem(
              label: 'Gia cố',
              icon: Icons.security,
              color: GameColors.success,
              onTap: () => ref.read(gameStateProvider.notifier).fortifyBase(),
            ),
            ActionGridItem(
              label: 'Radio',
              icon: Icons.radio,
              color: GameColors.danger,
              onTap: () => ref.read(gameStateProvider.notifier).useRadio(),
            ),
            ActionGridItem(
              label: 'Kết thúc ngày',
              icon: Icons.nightlight,
              color: GameColors.textMuted,
              onTap: () => ref.read(gameStateProvider.notifier).nightPhase(),
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
        switch (index) {
          case 1:
            _showInventorySheet();
            break;
          case 2:
            _showPartySheet();
            break;
          case 3:
            _showTradeSheet();
            break;
          case 4:
            _showMapSheet();
            break;
        }
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

  void _showInventorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const InventorySheet(),
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

  void _showTradeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TradeSheet(),
    );
  }

  void _showPartySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PartySheet(),
    );
  }

  void _showMapSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MapSheet(),
    );
  }
}

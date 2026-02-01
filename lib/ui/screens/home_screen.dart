import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'numbers_puzzle_sheet.dart';
import 'guide_sheet.dart';

/// Main home screen for the game
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  String? _activeEventId;
  String? _lastCueEventId;
  bool _choiceLocked = false;
  int? _selectedChoiceIndex;
  bool _choiceFlash = false;
  bool _puzzleOpen = false;
  bool _sheetOpen = false;
  bool _helpOpen = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final isGameOver = ref.watch(gameOverProvider);

    if (gameState == null) {
      return _buildLoadingScreen();
    }

    _maybeOpenPuzzle(gameState);
    _maybeOpenSheet(gameState);
    _maybeOpenHelp(gameState);

    if (isGameOver) {
      return _buildGameOverScreen(gameState);
    }

    if (gameState.currentEvent == null && _activeEventId != null) {
      _syncEventCleared();
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
            TerminalOverlay(
              intensity: _overlayIntensity(gameState),
              pulse: _isSevereEvent(gameState.currentEvent),
            ),
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
    if (_isSevereEvent(gameState.currentEvent)) {
      intensity += 0.15;
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
      child: Column(
        children: [
          Row(
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

              IconButton(
                icon: const Icon(Icons.help_outline, size: 22),
                color: GameColors.textSecondary,
                onPressed: _showGuideSheet,
              ),
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
          const SizedBox(height: 8),
          _buildHudChips(gameState),
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

  Widget _buildHudChips(dynamic gameState) {
    final temp = gameState.tempModifiers as Map?;
    final nightThreat = _readTempInt(temp?['nightThreat']);
    final triangulated = _readTempFlag(temp?['triangulated']);
    final signalHeat = gameState.baseStats.signalHeat as int;
    final countdown = _nextCountdown(gameState.countdowns as Map?);

    final chips = <Widget>[
      _hudChip(
        label: 'Tín hiệu',
        value: '$signalHeat',
        color: GameColors.signalHeat,
        pulse: triangulated,
      ),
      if (nightThreat != null)
        _hudChip(
          label: 'Đe doạ',
          value: '$nightThreat',
          color: GameColors.danger,
        ),
      if (countdown != null)
        _hudChip(
          label: '⏳ ${countdown.key}',
          value: '${countdown.value}d',
          color: GameColors.info,
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _hudChip({
    required String label,
    required String value,
    required Color color,
    bool pulse = false,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GameTypography.caption.copyWith(color: color),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GameTypography.caption.copyWith(
              color: GameColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (!pulse) return chip;
    return chip
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(duration: 600.ms, begin: 0.7, end: 1.0)
        .scale(duration: 600.ms, begin: const Offset(1, 1), end: const Offset(1.03, 1.03));
  }

  bool _readTempFlag(dynamic value) {
    if (value == true) return true;
    if (value is Map && value['value'] == true) return true;
    return false;
  }

  int? _readTempInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is Map && value['value'] is num) {
      return (value['value'] as num).toInt();
    }
    return null;
  }

  MapEntry<String, int>? _nextCountdown(Map? countdowns) {
    if (countdowns == null || countdowns.isEmpty) return null;
    MapEntry<String, int>? next;
    for (final entry in countdowns.entries) {
      final days = (entry.value as num?)?.toInt() ?? 0;
      if (next == null || days < next.value) {
        next = MapEntry(entry.key.toString(), days);
      }
    }
    return next;
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

    _syncEventState(event);
    final motionPreset = _resolveEventMotionPreset(event);
    _playEventCue(event, motionPreset);

    final choices = (event['choices'] as List? ?? []).asMap().entries.map((e) {
      final choice = e.value as Map<String, dynamic>;
      final enabled = ref.read(gameStateProvider.notifier).isChoiceEnabled(choice);
      return EventChoice(
        index: e.key,
        label: choice['label']?.toString() ?? choice['text']?.toString() ?? 'Chọn',
        hint: enabled ? choice['hint']?.toString() : 'Không đủ điều kiện',
        enabled: enabled,
        selected: _selectedChoiceIndex == e.key,
        locked: _choiceLocked,
      );
    }).toList();

    return EventCard(
      title: event['title']?.toString() ?? 'Sự kiện',
      text: event['text']?.toString() ?? '',
      choices: choices,
      motionPreset: motionPreset,
      flash: _choiceFlash,
      onChoiceSelected: (index) {
        _handleChoiceSelect(index, choices[index].label);
      },
    );
  }

  void _syncEventState(Map<String, dynamic> event) {
    final eventId = event['id']?.toString();
    if (_activeEventId == eventId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _activeEventId = eventId;
        _choiceLocked = false;
        _selectedChoiceIndex = null;
        _choiceFlash = false;
      });
    });
  }

  void _syncEventCleared() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _activeEventId = null;
        _choiceLocked = false;
        _selectedChoiceIndex = null;
        _choiceFlash = false;
      });
    });
  }

  void _playEventCue(Map<String, dynamic> event, String motionPreset) {
    final eventId = event['id']?.toString();
    if (eventId == null || eventId == _lastCueEventId) return;
    _lastCueEventId = eventId;

    switch (motionPreset) {
      case 'danger':
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
        break;
      case 'radio':
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.selectionClick();
        break;
      default:
        SystemSound.play(SystemSoundType.click);
        break;
    }
  }

  void _handleChoiceSelect(int index, String label) {
    if (_choiceLocked) return;
    setState(() {
      _choiceLocked = true;
      _selectedChoiceIndex = index;
      _choiceFlash = true;
    });

    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _choiceFlash = false);
    });

    ref.read(gameStateProvider.notifier).processChoice(index);
    _showActionSnack('✅ Đã chọn: $label', color: GameColors.info);
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
    if (combined.contains('danger') ||
        combined.contains('night') ||
        combined.contains('siege') ||
        combined.contains('raid') ||
        combined.contains('ambush')) {
      return 'danger';
    }
    if (combined.contains('radio')) return 'radio';
    if (combined.contains('loot') || combined.contains('scavenge')) return 'loot';
    return 'default';
  }

  bool _isSevereEvent(dynamic event) {
    if (event is! Map<String, dynamic>) return false;
    final group = event['group']?.toString() ?? '';
    final contexts = event['contexts'] ?? event['context'];
    final contextList = <String>[];
    if (contexts is String) {
      contextList.add(contexts);
    } else if (contexts is List) {
      contextList.addAll(contexts.map((e) => e.toString()));
    }
    final combined = '${group.toLowerCase()} ${contextList.join(' ').toLowerCase()}';
    return combined.contains('danger') ||
        combined.contains('night') ||
        combined.contains('siege') ||
        combined.contains('raid') ||
        combined.contains('ambush');
  }

  Widget _buildActionPanel(dynamic gameState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildObjectivePanel(gameState),
        const SizedBox(height: 12),
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
                final after = ref.read(gameStateProvider);
                final eventId = after?.currentEvent?['id']?.toString();
                if (eventId == 'rationing_policy') {
                  _showActionSnack('🍲 Chọn khẩu phần trước khi ngủ.');
                  return;
                }
                final day = after?.day ?? gameState.day;
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

  void _showScavengeSheet({String? initialLocation}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScavengeSheet(initialLocation: initialLocation),
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

  void _showGuideSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GuideSheet(),
    );
  }

  void _maybeOpenPuzzle(dynamic gameState) {
    final openPuzzle = gameState?.tempModifiers?['openPuzzle'];
    if (openPuzzle != 'numbers_station' || _puzzleOpen) return;
    _puzzleOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(gameStateProvider.notifier).clearTempModifier('openPuzzle');
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const NumbersPuzzleSheet(),
      );
      if (!mounted) return;
      setState(() => _puzzleOpen = false);
    });
  }

  void _maybeOpenSheet(dynamic gameState) {
    final openSheet = gameState?.tempModifiers?['openSheet']?.toString();
    if (openSheet == null || _sheetOpen || _puzzleOpen || _helpOpen) return;
    _sheetOpen = true;
    final suggest =
        gameState?.tempModifiers?['openSheet.location']?.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(gameStateProvider.notifier).clearTempModifier('openSheet');
      ref
          .read(gameStateProvider.notifier)
          .clearTempModifier('openSheet.location');
      switch (openSheet) {
        case 'scavenge':
          _showScavengeSheet(initialLocation: suggest);
          break;
        case 'craft':
          _showCraftSheet();
          break;
        case 'trade':
          _showTradeSheet();
          break;
        default:
          break;
      }
      if (!mounted) return;
      setState(() => _sheetOpen = false);
    });
  }

  void _maybeOpenHelp(dynamic gameState) {
    final openHelp = gameState?.tempModifiers?['openHelp'] == true;
    if (!openHelp || _helpOpen || _puzzleOpen) return;
    _helpOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(gameStateProvider.notifier).clearTempModifier('openHelp');
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const GuideSheet(),
      );
      if (!mounted) return;
      setState(() => _helpOpen = false);
    });
  }

  Widget _buildObjectivePanel(dynamic gameState) {
    final objective = _computeObjective(gameState);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: objective.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(objective.icon, color: objective.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  objective.title,
                  style: GameTypography.heading3.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vì sao: ${objective.reason}',
            style: GameTypography.bodySmall,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: objective.action == _ObjectiveAction.none
                ? null
                : () => _handleObjectiveAction(objective, gameState),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: objective.color,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(objective.icon, size: 18),
                const SizedBox(width: 8),
                Text(objective.actionLabel, style: GameTypography.button),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ObjectiveData _computeObjective(dynamic gameState) {
    final stats = gameState.playerStats;
    final base = gameState.baseStats;
    final temp = gameState.tempModifiers as Map?;
    final triangulated = _readTempFlag(temp?['triangulated']);

    if (stats.thirst >= 55) {
      return const _ObjectiveData(
        title: 'Tìm nước',
        reason: 'Khát cao khiến HP tụt nhanh, cần bổ sung nước sớm.',
        actionLabel: 'Đi tìm nước',
        icon: Icons.local_drink,
        color: GameColors.thirst,
        action: _ObjectiveAction.scavenge,
        suggestLocation: 'gas_station',
      );
    }

    if (stats.hunger >= 55) {
      return const _ObjectiveData(
        title: 'Tìm đồ ăn',
        reason: 'Đói cao làm bạn yếu đi, cần tích trữ thức ăn.',
        actionLabel: 'Đi tìm đồ ăn',
        icon: Icons.restaurant,
        color: GameColors.hunger,
        action: _ObjectiveAction.scavenge,
        suggestLocation: 'supermarket',
      );
    }

    if (stats.infection >= 25) {
      return const _ObjectiveData(
        title: 'Tìm thuốc',
        reason: 'Nhiễm trùng đang tăng, hãy tìm thuốc sớm.',
        actionLabel: 'Tìm thuốc',
        icon: Icons.medical_services,
        color: GameColors.infection,
        action: _ObjectiveAction.scavenge,
        suggestLocation: 'pharmacy',
      );
    }

    if (base.defense < 18 && gameState.day >= 3) {
      return const _ObjectiveData(
        title: 'Gia cố căn cứ',
        reason: 'Phòng thủ thấp từ ngày 3 trở đi (cần 1 gỗ + 1 đinh).',
        actionLabel: 'Gia cố ngay',
        icon: Icons.security,
        color: GameColors.success,
        action: _ObjectiveAction.fortify,
      );
    }

    if (triangulated || base.signalHeat >= 35) {
      return const _ObjectiveData(
        title: 'Giữ im lặng hôm nay',
        reason: 'Tín hiệu cao dễ bị dò, nên tránh phát radio.',
        actionLabel: 'Nghỉ ngơi',
        icon: Icons.hotel,
        color: GameColors.info,
        action: _ObjectiveAction.rest,
      );
    }

    return const _ObjectiveData(
      title: 'Khám phá thêm khu vực',
      reason: 'Tìm thêm tài nguyên để chuẩn bị cho những ngày sau.',
      actionLabel: 'Khám phá',
      icon: Icons.explore,
      color: GameColors.warning,
      action: _ObjectiveAction.scavenge,
    );
  }

  void _handleObjectiveAction(_ObjectiveData objective, dynamic gameState) {
    switch (objective.action) {
      case _ObjectiveAction.scavenge:
        _showScavengeSheet(initialLocation: objective.suggestLocation);
        break;
      case _ObjectiveAction.rest:
        ref.read(gameStateProvider.notifier).rest();
        _showActionSnack('😴 Nghỉ ngơi để giảm căng thẳng.');
        break;
      case _ObjectiveAction.fortify:
        final hasWood = _hasItemQty(gameState, 'wood_plank', 1);
        final hasNails = _hasItemQty(gameState, 'nails', 1);
        ref.read(gameStateProvider.notifier).fortifyBase();
        if (hasWood && hasNails) {
          _showActionSnack('🔨 Gia cố thành công. Phòng thủ +5.');
        } else {
          _showActionSnack(
            '⚠️ Thiếu gỗ hoặc đinh để gia cố.',
            color: GameColors.warning,
          );
        }
        break;
      case _ObjectiveAction.none:
        break;
    }
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

enum _ObjectiveAction { scavenge, rest, fortify, none }

class _ObjectiveData {
  final String title;
  final String reason;
  final String actionLabel;
  final IconData icon;
  final Color color;
  final _ObjectiveAction action;
  final String? suggestLocation;

  const _ObjectiveData({
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.icon,
    required this.color,
    required this.action,
    this.suggestLocation,
  });
}

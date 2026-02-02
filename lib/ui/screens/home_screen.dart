import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../theme/game_theme.dart';
import '../widgets/stat_bar.dart';
import '../widgets/log_feed.dart';
import '../widgets/event_card.dart';
import '../widgets/action_buttons.dart';
import '../widgets/terminal_overlay.dart';
import '../providers/game_providers.dart';
import '../../core/time.dart';
import 'inventory_sheet.dart';
import 'craft_sheet.dart';
import 'scavenge_sheet.dart';
import 'trade_sheet.dart';
import 'project_sheet.dart';
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
  bool _coachOpen = false;
  bool _headerExpanded = false;
  Timer? _clockTimer;
  final GlobalKey _keyActionExplore = GlobalKey();
  final GlobalKey _keyActionEndDay = GlobalKey();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(gameStateProvider.notifier).tickClock();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeShowCoachMarks(gameState);
    });

    if (isGameOver) {
      return _buildGameOverScreen(gameState);
    }

    if (gameState.currentEvent == null && _activeEventId != null) {
      _syncEventCleared();
    }

    final navItems = _navItems(gameState);
    final navIndex = _resolveNavIndex(navItems, _currentNavIndex);
    if (navIndex != _currentNavIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _currentNavIndex = navIndex);
      });
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
                    child: _buildTabBody(gameState, navItems[navIndex]),
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
      bottomNavigationBar: _buildBottomNav(navItems, navIndex),
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

  Widget _buildTabBody(dynamic gameState, _NavItem tab) {
    final tabId = tab.locked ? 'overview' : tab.id;
    switch (tabId) {
      case 'inventory':
        return const InventorySheet(
            embedded: true, key: ValueKey('tab_inventory'));
      case 'party':
        return const PartySheet(embedded: true, key: ValueKey('tab_party'));
      case 'trade':
        return const TradeSheet(embedded: true, key: ValueKey('tab_trade'));
      case 'map':
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
          CollapsibleLogFeed(
            entries: gameState.log,
            currentDay: gameState.day,
          ),
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
    final summary =
        (gameState?.endingSummary as List?)?.cast<String>() ?? const <String>[];

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
                endingId?.contains('death') == true ? 'GAME OVER' : 'KẾT THÚC',
                style: GameTypography.heading1.copyWith(
                  color: endingId?.contains('death') == true
                      ? GameColors.danger
                      : GameColors.gold,
                ),
              ),
              const SizedBox(height: 16),
              if (endingGrade != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    final temp = gameState.tempModifiers as Map?;
    final triangulated = _readTempFlag(temp?['triangulated']);
    final signalHeat = gameState.baseStats.signalHeat as int;
    final extraChips = _buildExtraStatusChips(gameState);
    final hasExtra = extraChips.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameColors.surface,
            GameColors.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Brand Row - Logo + Utilities
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Brand
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: GameColors.dangerGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: GameColors.danger.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.coronavirus,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ZOMBIE LIFESIM',
                          style: GameTypography.buttonSmall.copyWith(
                            color: GameColors.textPrimary,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Survive the apocalypse',
                          style: GameTypography.small.copyWith(
                            color: GameColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Utility buttons
                _headerIconButtonNew(
                  icon: Icons.help_outline_rounded,
                  onPressed: _showGuideSheet,
                  tooltip: 'Hướng dẫn',
                ),
                _headerIconButtonNew(
                  icon: Icons.save_outlined,
                  onPressed: () =>
                      ref.read(gameStateProvider.notifier).saveGame(),
                  tooltip: 'Lưu game',
                ),
                _headerIconButtonNew(
                  icon: gameState.terminalOverlayEnabled
                      ? Icons.blur_on
                      : Icons.blur_off,
                  onPressed: () => ref
                      .read(gameStateProvider.notifier)
                      .toggleTerminalOverlay(),
                  tooltip: 'Terminal overlay',
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: GameColors.surfaceLight.withOpacity(0.3),
          ),
          // Status Row - Day, Time, Signal Heat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildDayChipNew(gameState),
                const SizedBox(width: 8),
                _buildTimeChipNew(gameState),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusStripNew(
                    signalHeat: signalHeat,
                    triangulated: triangulated,
                    extraChips: extraChips,
                    hasExtra: hasExtra,
                  ),
                ),
                if (hasExtra)
                  _headerIconButtonSmall(
                    icon:
                        _headerExpanded ? Icons.unfold_less : Icons.unfold_more,
                    onPressed: () =>
                        setState(() => _headerExpanded = !_headerExpanded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButtonNew({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GameColors.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: GameColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerIconButtonSmall({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: GameColors.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: GameColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDayChipNew(dynamic gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: GameColors.dangerGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: GameColors.danger.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Ngày ${gameState.day}',
            style: GameTypography.button.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChipNew(dynamic gameState) {
    final timeOfDay = gameState.timeOfDay as String;
    final timeColor = _getTimeColor(timeOfDay);
    final clockText =
        GameTime.formatClock((gameState.clockMinutes as int?) ?? 0);
    final isLate = gameState.tempModifiers['dayOver'] == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showStatusInfoSheet(
          title: 'Chu kỳ ngày',
          lines: [
            'Sáng: thường có sự kiện khởi đầu.',
            'Ngày: bạn chọn hành động chính.',
            'Chiều/Tối: chuẩn bị qua đêm.',
            'Đêm: có thể xảy ra tấn công.',
            'Đồng hồ chạy theo thời gian thật.',
            'Hành động tiêu tốn thời gian trong ngày.',
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: timeColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTimeIcon(timeOfDay),
                size: 14,
                color: timeColor,
              ),
              const SizedBox(width: 6),
              Text(
                '$clockText • ${_getTimeText(timeOfDay)}',
                style: GameTypography.buttonSmall.copyWith(
                  color: timeColor,
                ),
              ),
              if (isLate) ...[
                const SizedBox(width: 6),
                const Icon(Icons.nightlight_round,
                    size: 12, color: GameColors.danger),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTimeColor(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning':
        return GameColors.gold;
      case 'day':
        return GameColors.warning;
      case 'evening':
        return GameColors.fatigue;
      case 'night':
        return GameColors.info;
      default:
        return GameColors.textSecondary;
    }
  }

  Widget _buildStatusStripNew({
    required int signalHeat,
    required bool triangulated,
    required List<Widget> extraChips,
    required bool hasExtra,
  }) {
    final showExtra = _headerExpanded && hasExtra;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _signalHeatChip(signalHeat, triangulated),
          if (!showExtra && hasExtra) ...[
            const SizedBox(width: 6),
            _moreChip(extraChips.length),
          ],
          if (showExtra) ...[
            const SizedBox(width: 6),
            ...extraChips.map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: chip,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _signalHeatChip(int signalHeat, bool triangulated) {
    final isCritical = signalHeat > 60;
    final color = isCritical ? GameColors.danger : GameColors.signalHeat;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showStatusInfoSheet(
          title: 'Tín hiệu (Signal Heat)',
          lines: [
            'Tín hiệu càng cao càng dễ bị truy vết.',
            'Bật radio hoặc thiết bị khuếch đại sẽ tăng tín hiệu.',
            'Nếu quá cao, có thể bị triangulation ban đêm.',
            'Giữ im lặng hoặc nghỉ ngơi để hạ tín hiệu.',
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(triangulated ? 0.6 : 0.25),
              width: triangulated ? 1.5 : 1,
            ),
            boxShadow: triangulated
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_tethering,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                '$signalHeat',
                style: GameTypography.buttonSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (triangulated) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.gps_fixed,
                  size: 12,
                  color: GameColors.danger,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreChip(int count) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _headerExpanded = true),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: GameColors.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz,
                size: 14,
                color: GameColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '+$count',
                style: GameTypography.buttonSmall.copyWith(
                  color: GameColors.textMuted,
                ),
              ),
            ],
          ),
        ),
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

  List<Widget> _buildExtraStatusChips(dynamic gameState) {
    final temp = gameState.tempModifiers as Map?;
    final nightThreat = _readTempInt(temp?['nightThreat']);
    final countdown = _nextCountdown(gameState.countdowns as Map?);

    return <Widget>[
      if (nightThreat != null)
        _hudChip(
          label: 'Đe doạ',
          value: '$nightThreat',
          color: GameColors.danger,
          compact: true,
          icon: Icons.warning_rounded,
          onTap: () => _showStatusInfoSheet(
            title: 'Đe doạ ban đêm',
            lines: [
              'Đe doạ phụ thuộc ồn, mùi, tín hiệu, phòng thủ và hy vọng.',
              'Mệt mỏi cao và nhóm đông cũng làm tăng nguy cơ.',
              'Đe doạ càng cao → xác suất bị tấn công càng lớn.',
            ],
          ),
        ),
      if (countdown != null)
        _hudChip(
          label: '⏳ ${countdown.key}',
          value: '${countdown.value}d',
          color: GameColors.info,
          compact: true,
          icon: Icons.hourglass_bottom,
          onTap: () => _showStatusInfoSheet(
            title: 'Đếm ngược',
            lines: [
              'Đếm ngược cho sự kiện: ${countdown.key}.',
              'Khi về 0, sự kiện sẽ tự kích hoạt.',
            ],
          ),
        ),
    ];
  }

  Widget _hudChip({
    required String label,
    required String value,
    required Color color,
    bool pulse = false,
    bool compact = false,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final labelStyle =
        (compact ? GameTypography.caption : GameTypography.caption).copyWith(
      color: color,
      fontSize: compact ? 11 : 12,
      letterSpacing: compact ? 0.1 : null,
    );
    final valueStyle = GameTypography.caption.copyWith(
      color: GameColors.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: compact ? 11 : 12,
    );

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: labelStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(value, style: valueStyle),
        ],
      ),
    );

    if (onTap != null) {
      chip = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: chip,
        ),
      );
    }

    if (!pulse) return chip;
    return chip
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(duration: 600.ms, begin: 0.7, end: 1.0)
        .scale(
            duration: 600.ms,
            begin: const Offset(1, 1),
            end: const Offset(1.03, 1.03));
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

    return Column(
      children: [
        // Main stats card - HP and Infection
        MainStatsCard(
          hp: stats.hp,
          infection: stats.infection,
        ),
        const SizedBox(height: 10),

        // Secondary stats row - hunger, thirst, fatigue, stress
        SecondaryStatsRow(
          hunger: stats.hunger,
          thirst: stats.thirst,
          fatigue: stats.fatigue,
          stress: stats.stress,
        ),
        const SizedBox(height: 8),

        // Morale display
        MoraleDisplay(morale: stats.morale),
        const SizedBox(height: 8),

        // Base stats row
        BaseStatsRow(
          noise: base.noise,
          smell: base.smell,
          hope: base.hope,
          signalHeat: base.signalHeat,
        ),
      ],
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
      final enabled =
          ref.read(gameStateProvider.notifier).isChoiceEnabled(choice);
      return EventChoice(
        index: e.key,
        label:
            choice['label']?.toString() ?? choice['text']?.toString() ?? 'Chọn',
        hint: enabled ? choice['hint']?.toString() : 'Không đủ điều kiện',
        enabled: enabled,
        selected: _selectedChoiceIndex == e.key,
        locked: _choiceLocked,
      );
    }).toList();

    // Check if any choice is enabled
    final hasEnabledChoice = choices.any((c) => c.enabled);

    // If no choices are enabled, add a fallback "Skip" choice
    final displayChoices = hasEnabledChoice
        ? choices
        : [
            ...choices,
            EventChoice(
              index: choices.length,
              label: 'Bỏ qua sự kiện này',
              hint: 'Không có lựa chọn khả dụng',
              enabled: true,
              selected: _selectedChoiceIndex == choices.length,
              locked: _choiceLocked,
            ),
          ];

    return EventCard(
      title: event['title']?.toString() ?? 'Sự kiện',
      text: event['text']?.toString() ?? '',
      choices: displayChoices,
      motionPreset: motionPreset,
      flash: _choiceFlash,
      onChoiceSelected: (index) {
        // If this is the fallback skip choice
        if (!hasEnabledChoice && index == choices.length) {
          _handleSkipEvent();
          return;
        }
        _handleChoiceSelect(index, displayChoices[index].label);
      },
    );
  }

  void _handleSkipEvent() {
    if (_choiceLocked) return;
    setState(() {
      _choiceLocked = true;
    });

    // Clear the event without processing any choice
    ref.read(gameStateProvider.notifier).skipCurrentEvent();
    _showActionSnack('⏭️ Đã bỏ qua sự kiện.', color: GameColors.textSecondary);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _choiceLocked = false);
    });
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

    final combined =
        '${group.toLowerCase()} ${contextList.join(' ').toLowerCase()}';
    if (combined.contains('danger') ||
        combined.contains('night') ||
        combined.contains('siege') ||
        combined.contains('raid') ||
        combined.contains('ambush')) {
      return 'danger';
    }
    if (combined.contains('radio')) return 'radio';
    if (combined.contains('loot') || combined.contains('scavenge'))
      return 'loot';
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
    final combined =
        '${group.toLowerCase()} ${contextList.join(' ').toLowerCase()}';
    return combined.contains('danger') ||
        combined.contains('night') ||
        combined.contains('siege') ||
        combined.contains('raid') ||
        combined.contains('ambush');
  }

  Widget _buildActionPanel(dynamic gameState) {
    final items = _buildActionItems(gameState);
    final tradeUnlocked = _isFeatureUnlocked(gameState, 'trade');
    final mapUnlocked = _isFeatureUnlocked(gameState, 'map');
    final projectsUnlocked = _isFeatureUnlocked(gameState, 'projects');
    final hasLockedFeatures =
        !tradeUnlocked || !mapUnlocked || !projectsUnlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildObjectivePanel(gameState),
        const SizedBox(height: 12),
        if (hasLockedFeatures) _buildLockedFeaturesHint(gameState),
        if (hasLockedFeatures) const SizedBox(height: 10),
        // Main actions
        ActionGrid(items: items),
      ],
    );
  }

  List<ActionGridItem> _buildActionItems(dynamic gameState) {
    final day = gameState.day as int? ?? 1;
    final projectsUnlocked = _isFeatureUnlocked(gameState, 'projects');
    final items = <ActionGridItem>[
      ActionGridItem(
        label: 'Khám phá',
        subtitle: 'Tìm vật phẩm',
        icon: Icons.explore,
        color: GameColors.warning,
        onTap: () => _showScavengeSheet(),
        targetKey: _keyActionExplore,
      ),
      ActionGridItem(
        label: 'Chế tạo',
        subtitle: 'Tạo vật phẩm',
        icon: Icons.build,
        color: GameColors.info,
        onTap: () => _showCraftSheet(),
      ),
      ActionGridItem(
        label: 'Dự án',
        subtitle: projectsUnlocked ? 'Nâng cấp dài hạn' : 'Mở sau ngày 3',
        icon: Icons.construction,
        color: GameColors.gold,
        enabled: projectsUnlocked,
        onTap: projectsUnlocked ? () => _showProjectSheet() : null,
      ),
      ActionGridItem(
        label: 'Nghỉ ngơi',
        subtitle: 'Hồi phục sức',
        icon: Icons.hotel,
        color: GameColors.fatigue,
        onTap: () {
          ref.read(gameStateProvider.notifier).rest();
          _showActionSnack('😴 Nghỉ ngơi xong. Thể lực hồi lại một chút.');
        },
      ),
    ];

    // Fortify is always available (core action)
    items.add(
      ActionGridItem(
        label: 'Gia cố',
        subtitle: 'Tăng phòng thủ',
        icon: Icons.security,
        color: GameColors.success,
        onTap: () {
          final hasWood = _hasItemQty(gameState, 'wood_plank', 1);
          final hasNails = _hasItemQty(gameState, 'nails', 1);
          ref.read(gameStateProvider.notifier).fortifyBase();
          if (hasWood && hasNails) {
            _showActionSnack('🔨 Gia cố thành công. Phòng thủ +5.');
          } else {
            _showActionSnack(
              _buildMissingMaterialsHint(gameState, const {
                'wood_plank': 1,
                'nails': 1,
              }),
              color: GameColors.warning,
            );
          }
        },
      ),
    );

    // Radio unlocks after day 2
    if (day >= 2) {
      items.add(
        ActionGridItem(
          label: 'Radio',
          subtitle: 'Nghe tin tức',
          icon: Icons.radio,
          color: GameColors.signalHeat,
          onTap: () {
            ref.read(gameStateProvider.notifier).useRadio();
            _showActionSnack('📻 Bật radio. Tín hiệu tăng, coi chừng bị để ý.');
          },
        ),
      );
    }

    items.add(
      ActionGridItem(
        label: 'Kết thúc ngày',
        subtitle: 'Qua đêm',
        icon: Icons.nightlight_round,
        color: GameColors.info,
        onTap: () {
          ref.read(gameStateProvider.notifier).nightPhase();
          final after = ref.read(gameStateProvider);
          final eventId = after?.currentEvent?['id']?.toString();
          if (eventId == 'rationing_policy') {
            _showActionSnack('🍲 Chọn khẩu phần trước khi ngủ.');
            return;
          }
          final dayNext = after?.day ?? gameState.day;
          _showActionSnack('🌙 Kết thúc ngày. Bước sang ngày $dayNext.');
        },
        targetKey: _keyActionEndDay,
      ),
    );

    return items;
  }

  Widget _buildLockedFeaturesHint(dynamic gameState) {
    final tradeUnlocked = _isFeatureUnlocked(gameState, 'trade');
    final mapUnlocked = _isFeatureUnlocked(gameState, 'map');
    final projectsUnlocked = _isFeatureUnlocked(gameState, 'projects');
    
    final hints = <String>[];
    if (!tradeUnlocked) {
      hints.add('Giao dịch: ngày 5 / gặp thương nhân / bảng việc');
    }
    if (!mapUnlocked) {
      hints.add('Bản đồ: ngày 7 hoặc khám phá 3+ địa điểm');
    }
    if (!projectsUnlocked) hints.add('Dự án: mở sau ngày 3');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GameColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GameColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_open_rounded,
              size: 18, color: GameColors.gold.withOpacity(0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🔓 ${hints.join(' • ')}',
              style: GameTypography.caption.copyWith(
                color: GameColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(List<_NavItem> items, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        final item = items[index];
        if (item.locked) {
          _showStatusInfoSheet(
            title: 'Tính năng đang khóa',
            lines: const [
              'Giao dịch: ngày 5 / gặp thương nhân / bảng việc.',
              'Bản đồ: ngày 7 hoặc khám phá 3+ địa điểm.',
            ],
          );
          return;
        }
        setState(() => _currentNavIndex = index);
      },
      items: items.map((item) => item.item).toList(),
    );
  }

  /// Check if a feature is unlocked based on progression
  bool _isFeatureUnlocked(dynamic gameState, String feature) {
    if (gameState == null) return false;
    final flags = gameState.flags as Set?;
    final day = gameState.day as int? ?? 1;

    switch (feature) {
      case 'trade':
        // Unlock trade after: Day 5 OR discovered a trader
        if (day >= 5) return true;
        if (flags?.contains('unlocked_trade') == true) return true;
        if (flags?.contains('met_trader') == true) return true;
        return false;

      case 'map':
        // Unlock map after: Day 7 OR explored 3+ locations OR completed first quest
        if (day >= 7) return true;
        if (flags?.contains('unlocked_map') == true) return true;
        final locationStates = gameState.locationStates as Map?;
        if (locationStates != null && locationStates.length >= 3) return true;
        final quests = gameState.quests as Map?;
        if (quests != null && quests.values.any((q) => (q.stage as int? ?? 0) >= 1)) return true;
        return false;

      case 'projects':
        // Unlock projects after Day 3 or completed fortify objective
        if (day >= 3) return true;
        if (flags?.contains('unlocked_projects') == true) return true;
        return false;

      default:
        return true;
    }
  }

  int _resolveNavIndex(List<_NavItem> items, int currentIndex) {
    if (items.isEmpty) return 0;
    final clamped = currentIndex.clamp(0, items.length - 1);
    if (items[clamped].locked) return 0;
    return clamped;
  }

  List<_NavItem> _navItems(dynamic gameState) {
    final tradeLocked = !_isFeatureUnlocked(gameState, 'trade');
    final mapLocked = !_isFeatureUnlocked(gameState, 'map');

    return <_NavItem>[
      const _NavItem(
        id: 'overview',
        locked: false,
        item: BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Tổng quan',
        ),
      ),
      const _NavItem(
        id: 'inventory',
        locked: false,
        item: BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Kho đồ',
        ),
      ),
      const _NavItem(
        id: 'party',
        locked: false,
        item: BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Nhóm',
        ),
      ),
      _NavItem(
        id: 'trade',
        locked: tradeLocked,
        item: BottomNavigationBarItem(
          icon: _navIcon(Icons.store, tradeLocked),
          label: 'Giao dịch',
        ),
      ),
      _NavItem(
        id: 'map',
        locked: mapLocked,
        item: BottomNavigationBarItem(
          icon: _navIcon(Icons.map, mapLocked),
          label: 'Bản đồ',
        ),
      ),
    ];
  }

  // Navigation lock is now handled by _isFeatureUnlocked

  Widget _navIcon(IconData icon, bool locked) {
    if (!locked) return Icon(icon);
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, color: GameColors.textMuted),
        const Positioned(
          right: -2,
          top: -2,
          child: Icon(Icons.lock, size: 12, color: GameColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _openModalSheet(Widget child) async {
    setState(() => _sheetOpen = true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => child,
    );
    if (!mounted) return;
    setState(() => _sheetOpen = false);
  }

  void _showCraftSheet() {
    _openModalSheet(const CraftSheet());
  }

  void _showScavengeSheet({String? initialLocation}) {
    _openModalSheet(ScavengeSheet(initialLocation: initialLocation));
  }

  void _showTradeSheet() {
    _openModalSheet(const TradeSheet());
  }

  void _showProjectSheet() {
    _openModalSheet(const ProjectSheet());
  }

  void _showGuideSheet() {
    _openModalSheet(const GuideSheet());
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
    final suggest = gameState?.tempModifiers?['openSheet.location']?.toString();
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
        case 'projects':
          _showProjectSheet();
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
      await _openModalSheet(const GuideSheet());
      if (!mounted) return;
      setState(() => _helpOpen = false);
    });
  }

  void _maybeShowCoachMarks(dynamic gameState) {
    final flags = gameState?.flags as Set?;
    if (gameState == null) return;
    if (_coachOpen || _puzzleOpen || _sheetOpen || _helpOpen) return;
    if (gameState.currentEvent != null) return;
    if (flags?.contains('tutorial_done') == true) return;
    if (flags?.contains('coach_marks_done') == true) return;
    if (gameState.day > 2) return;
    if (_keyActionExplore.currentContext == null ||
        _keyActionEndDay.currentContext == null) {
      return;
    }
    if (Navigator.of(context).canPop()) return;

    final exploreRect = _targetRect(_keyActionExplore);
    final endRect = _targetRect(_keyActionEndDay);
    if (exploreRect == null || endRect == null) return;

    _coachOpen = true;
    final screen = MediaQuery.of(context).size;
    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'coach_explore',
        keyTarget: _keyActionExplore,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        borderSide: BorderSide(
          color: GameColors.warning.withOpacity(0.9),
          width: 2,
        ),
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: _contentAlign(exploreRect, screen),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            builder: (_, __) => _buildCoachContent(
              title: 'Khám phá',
              body: 'Tìm nước, đồ ăn và vật liệu ở các địa điểm khác nhau.',
              step: 1,
              total: 2,
              accent: GameColors.warning,
              icon: Icons.explore,
              alignment: _cardAlign(exploreRect, screen),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'coach_endday',
        keyTarget: _keyActionEndDay,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        borderSide: BorderSide(
          color: GameColors.textMuted.withOpacity(0.9),
          width: 2,
        ),
        enableOverlayTab: true,
        enableTargetTab: false,
        contents: [
          TargetContent(
            align: _contentAlign(endRect, screen),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            builder: (_, __) => _buildCoachContent(
              title: 'Kết thúc ngày',
              body: 'Hoàn thành việc rồi kết thúc ngày để qua đêm.',
              step: 2,
              total: 2,
              accent: GameColors.textMuted,
              icon: Icons.nightlight,
              alignment: _cardAlign(endRect, screen),
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.86),
      paddingFocus: 8,
      alignSkip: Alignment.topRight,
      skipWidget: _buildCoachSkip(),
      textSkip: 'Bỏ qua',
      useSafeArea: true,
      imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
      onFinish: () {
        ref.read(gameStateProvider.notifier).setFlag('coach_marks_done');
        if (!mounted) return;
        setState(() => _coachOpen = false);
      },
      onSkip: () {
        ref.read(gameStateProvider.notifier).setFlag('coach_marks_done');
        if (!mounted) return true;
        setState(() => _coachOpen = false);
        return true;
      },
    ).show(context: context);
  }

  Rect? _targetRect(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final position = box.localToGlobal(Offset.zero);
    return position & box.size;
  }

  ContentAlign _contentAlign(Rect rect, Size screen) {
    return rect.center.dy > screen.height * 0.58
        ? ContentAlign.top
        : ContentAlign.bottom;
  }

  Alignment _cardAlign(Rect rect, Size screen) {
    return rect.center.dx < screen.width * 0.5
        ? Alignment.centerLeft
        : Alignment.centerRight;
  }

  Widget _buildCoachSkip() {
    return Container(
      margin: const EdgeInsets.only(top: 12, right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.surfaceLight),
      ),
      child: Text(
        'Bỏ qua',
        style: GameTypography.caption.copyWith(color: GameColors.textSecondary),
      ),
    );
  }

  Widget _buildCoachContent({
    required String title,
    required String body,
    required int step,
    required int total,
    required Color accent,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GameColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GameColors.surfaceLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: GameTypography.heading3),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GameColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$step/$total',
                      style: GameTypography.caption.copyWith(
                        color: GameColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(body, style: GameTypography.bodySmall),
              const SizedBox(height: 10),
              Text(
                'Chạm nền để tiếp tục',
                style: GameTypography.caption
                    .copyWith(color: GameColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObjectivePanel(dynamic gameState) {
    final objective = _computeObjective(gameState);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            objective.color.withOpacity(0.15),
            objective.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: objective.color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: objective.color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      objective.color.withOpacity(0.3),
                      objective.color.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: objective.color.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(objective.icon, color: objective.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MỤC TIÊU',
                      style: GameTypography.tiny.copyWith(
                        color: objective.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      objective.title,
                      style: GameTypography.heading4.copyWith(
                        color: GameColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: GameColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: GameColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    objective.reason,
                    style: GameTypography.caption.copyWith(
                      color: GameColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ObjectiveActionButton(
            label: objective.actionLabel,
            icon: objective.icon,
            color: objective.color,
            enabled: objective.action != _ObjectiveAction.none,
            onTap: () => _handleObjectiveAction(objective, gameState),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _ObjectiveActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : GameColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled ? Colors.white : GameColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GameTypography.button.copyWith(
                  color: enabled ? Colors.white : GameColors.textMuted,
                ),
              ),
            ],
          ),
        ),
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
            _buildMissingMaterialsHint(gameState, const {
              'wood_plank': 1,
              'nails': 1,
            }),
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

  int _getItemQty(dynamic gameState, String itemId) {
    if (gameState == null) return 0;
    int total = 0;
    for (final stack in gameState.inventory) {
      if (stack.itemId == itemId) {
        total += (stack.qty as num?)?.toInt() ?? 0;
      }
    }
    return total;
  }

  String _buildMissingMaterialsHint(
    dynamic gameState,
    Map<String, int> requirements,
  ) {
    final loop = ref.read(gameLoopProvider).maybeWhen(
          data: (value) => value,
          orElse: () => null,
        );
    final parts = <String>[];

    requirements.forEach((itemId, qty) {
      final have = _getItemQty(gameState, itemId);
      if (have >= qty) return;
      final item = loop?.data.getItem(itemId);
      final name = item?.name ?? itemId;
      final hint = (item?.hint ?? '').trim();
      if (hint.isNotEmpty) {
        parts.add('$name: $hint');
      } else {
        parts.add('$name: cần tìm thêm');
      }
    });

    if (parts.isEmpty) {
      return '⚠️ Thiếu vật liệu để thực hiện.';
    }

    return '⚠️ Thiếu vật liệu. ${parts.join(' • ')}';
  }

  void _showStatusInfoSheet({
    required String title,
    required List<String> lines,
  }) {
    _openModalSheet(
      Container(
        decoration: const BoxDecoration(
          color: GameColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: GameTypography.heading3),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $line', style: GameTypography.bodySmall),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
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

class _NavItem {
  final String id;
  final bool locked;
  final BottomNavigationBarItem item;

  const _NavItem({
    required this.id,
    required this.locked,
    required this.item,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/action_buttons.dart';
import 'home_screen.dart';

/// Title/start screen for the game
class TitleScreen extends ConsumerStatefulWidget {
  const TitleScreen({super.key});

  @override
  ConsumerState<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends ConsumerState<TitleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  bool _loading = false;
  bool _hasSave = false;
  Map<String, dynamic>? _saveInfo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _checkForSave();
  }

  Future<void> _checkForSave() async {
    try {
      final saveManager = await ref.read(saveManagerProvider.future);
      final hasSave = await saveManager.hasSave();
      final saveInfo = hasSave ? await saveManager.getSaveInfo() : null;
      if (mounted) {
        setState(() {
          _hasSave = hasSave;
          _saveInfo = saveInfo;
        });
      }
    } catch (e) {
      // Ignore errors during save check
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameColors.background,
              GameColors.blood.withOpacity(0.3),
              GameColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Title
                  _buildTitle(),

                  const Spacer(flex: 1),

                  // Subtitle
                  Text(
                    'Một trò chơi sinh tồn text-based',
                    style: GameTypography.body.copyWith(
                      color: GameColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'trong thế giới zombie tận thế',
                    style: GameTypography.bodySmall.copyWith(
                      color: GameColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Buttons
                  if (_loading)
                    const CircularProgressIndicator(color: GameColors.danger)
                  else
                    Column(
                      children: [
                        // Continue button (only if save exists)
                        if (_hasSave) ...[
                          PrimaryActionButton(
                            label: 'Tiếp tục',
                            icon: Icons.play_arrow,
                            onPressed: _continueGame,
                          ),
                          if (_saveInfo != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Ngày ${_saveInfo!['day'] ?? 1}',
                                style: GameTypography.caption.copyWith(
                                  color: GameColors.textMuted,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SecondaryActionButton(
                            label: 'Trò chơi mới',
                            icon: Icons.refresh,
                            onPressed: _confirmNewGame,
                          ),
                        ] else ...[
                          PrimaryActionButton(
                            label: 'Bắt đầu',
                            icon: Icons.play_arrow,
                            onPressed: _startNewGame,
                          ),
                        ],
                      ],
                    ),

                  const Spacer(flex: 2),

                  // Version
                  Text(
                    'Version 1.0.0',
                    style: GameTypography.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        // Zombie icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: GameColors.zombie.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: GameColors.danger.withOpacity(0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: GameColors.danger.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🧟',
              style: TextStyle(fontSize: 50),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Title text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              GameColors.danger,
              GameColors.blood,
              GameColors.danger,
            ],
          ).createShader(bounds),
          child: Text(
            'ZOMBIE',
            style: GameTypography.heading1.copyWith(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: Colors.white,
            ),
          ),
        ),

        Text(
          'LIFE SIM',
          style: GameTypography.heading2.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 12,
            color: GameColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmNewGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: Text(
          'Bắt đầu lại?',
          style: GameTypography.heading3,
        ),
        content: Text(
          'Tiến trình hiện tại sẽ bị xóa. Bạn chắc chắn muốn bắt đầu trò chơi mới?',
          style: GameTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GameTypography.body.copyWith(color: GameColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Bắt đầu mới',
              style: GameTypography.body.copyWith(color: GameColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _startNewGame();
    }
  }

  Future<void> _startNewGame() async {
    setState(() => _loading = true);

    try {
      await ref.read(gameStateProvider.notifier).newGame();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: GameColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _continueGame() async {
    setState(() => _loading = true);

    try {
      final success = await ref.read(gameStateProvider.notifier).loadGame();
      if (mounted) {
        if (success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy save game'),
              backgroundColor: GameColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: GameColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

/// Full-screen overlay for day/night transitions
class DayNightTransition extends StatefulWidget {
  final int day;
  final List<String> nightResults;
  final VoidCallback onComplete;

  const DayNightTransition({
    super.key,
    required this.day,
    required this.nightResults,
    required this.onComplete,
  });

  @override
  State<DayNightTransition> createState() => _DayNightTransitionState();
}

class _DayNightTransitionState extends State<DayNightTransition>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _textController;
  late Animation<double> _fadeIn;

  int _currentResultIndex = -1;
  bool _showingResults = false;
  bool _showNewDay = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Phase 1: Fade to black
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Phase 2: Show night text
    setState(() => _showingResults = true);
    await Future.delayed(const Duration(milliseconds: 800));

    // Phase 3: Show results one by one
    for (int i = 0; i < widget.nightResults.length; i++) {
      if (!mounted) return;
      setState(() => _currentResultIndex = i);
      await Future.delayed(const Duration(milliseconds: 600));
    }

    await Future.delayed(const Duration(milliseconds: 800));

    // Phase 4: Show new day
    setState(() {
      _showingResults = false;
      _showNewDay = true;
    });
    await Future.delayed(const Duration(milliseconds: 1500));

    // Phase 5: Fade out
    if (!mounted) return;
    await _fadeController.reverse();

    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return IgnorePointer(
          ignoring: _fadeIn.value < 0.1,
          child: Container(
            color: Colors.black.withOpacity(_fadeIn.value * 0.95),
            child: _fadeIn.value > 0.5
                ? SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: _buildContent(),
                      ),
                    ),
                  )
                : const SizedBox.expand(),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_showNewDay) {
      return _buildNewDay();
    }
    if (_showingResults) {
      return _buildNightResults();
    }
    return const SizedBox.shrink();
  }

  Widget _buildNightResults() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Moon icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.8 + value * 0.2,
                child: const Text(
                  '🌙',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Night title
        Text(
          'Đêm thứ ${widget.day}',
          style: GameTypography.heading1.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontSize: 28,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),

        // Results staggered
        ...List.generate(
          _currentResultIndex + 1,
          (index) {
            if (index > _currentResultIndex) return const SizedBox.shrink();
            return TweenAnimationBuilder<double>(
              key: ValueKey(index),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        widget.nightResults[index],
                        style: GameTypography.body.copyWith(
                          color: _getResultColor(widget.nightResults[index]),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNewDay() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + value * 0.1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌅', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  'Ngày ${widget.day + 1}',
                  style: GameTypography.heading1.copyWith(
                    color: GameColors.gold,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn đã sống sót',
                  style: GameTypography.body.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getResultColor(String text) {
    if (text.contains('tấn công') || text.contains('thiệt hại') || text.contains('mất')) {
      return GameColors.danger.withOpacity(0.9);
    }
    if (text.contains('an toàn') || text.contains('hồi phục') || text.contains('thu hoạch')) {
      return GameColors.success.withOpacity(0.9);
    }
    if (text.contains('cảnh báo') || text.contains('nguy hiểm')) {
      return GameColors.warning.withOpacity(0.9);
    }
    return Colors.white.withOpacity(0.7);
  }
}

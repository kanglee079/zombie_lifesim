import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/game_theme.dart';
import '../motion/motion_wrap.dart';

/// Event card widget for displaying current event with choices
class EventCard extends StatelessWidget {
  final String title;
  final String text;
  final List<EventChoice> choices;
  final void Function(int index)? onChoiceSelected;
  final String motionPreset;
  final bool flash;

  const EventCard({
    super.key,
    required this.title,
    required this.text,
    required this.choices,
    this.onChoiceSelected,
    this.motionPreset = 'default',
    this.flash = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = motionPreset == 'danger';
    final isRadio = motionPreset == 'radio';

    return MotionWrap(
      presetId: motionPreset,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GameColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GameColors.danger.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameColors.danger.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GameColors.danger.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: GameColors.danger.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isRadio ? Icons.radio : Icons.warning_amber_rounded,
                              color: isRadio ? GameColors.info : GameColors.danger,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: GameTypography.heading3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDanger)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: GameColors.danger.withOpacity(0.12),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) {
                              controller.repeat(reverse: true);
                            })
                            .fadeIn(duration: 500.ms)
                            .fadeOut(duration: 500.ms),
                      ),
                    if (isRadio)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: GameColors.info.withOpacity(0.08),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                          ),
                        )
                            .animate(onPlay: (controller) {
                              controller.repeat(reverse: true);
                            })
                            .shimmer(duration: 900.ms)
                            .fade(duration: 700.ms, begin: 0.7, end: 1.0),
                      ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: text.isEmpty
                      ? const SizedBox.shrink()
                      : AnimatedTextKit(
                          key: ValueKey(text),
                          isRepeatingAnimation: false,
                          displayFullTextOnTap: true,
                          stopPauseOnTap: true,
                          animatedTexts: [
                            TypewriterAnimatedText(
                              text,
                              textStyle: GameTypography.body.copyWith(height: 1.6),
                              speed: const Duration(milliseconds: 18),
                            ),
                          ],
                        ),
                ),

                // Choices
                if (choices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: choices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final choice = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _ChoiceButton(
                            choice: choice,
                            onTap: () => onChoiceSelected?.call(index),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: flash ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GameColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Choice button widget
class _ChoiceButton extends StatefulWidget {
  final EventChoice choice;
  final VoidCallback? onTap;

  const _ChoiceButton({
    required this.choice,
    this.onTap,
  });

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final choice = widget.choice;
    final isLocked = choice.locked;
    final isSelected = choice.selected;
    final isEnabled = choice.enabled && !isLocked;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTapDown: (_) {
          if (!isEnabled) return;
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          if (!isEnabled) return;
          setState(() => _pressed = false);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: InkWell(
            onTap: isEnabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onTap?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? GameColors.success.withOpacity(0.12)
                    : isEnabled
                    ? GameColors.surfaceLight
                    : GameColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? GameColors.success.withOpacity(0.8)
                      : isEnabled
                          ? GameColors.textMuted.withOpacity(0.3)
                          : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GameColors.success.withOpacity(0.2)
                          : isEnabled
                          ? GameColors.danger.withOpacity(0.2)
                          : GameColors.textMuted.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${choice.index + 1}',
                        style: GameTypography.button.copyWith(
                          color: isSelected
                              ? GameColors.success
                              : isEnabled
                                  ? GameColors.danger
                                  : GameColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choice.label,
                          style: GameTypography.button.copyWith(
                            color: isSelected
                                ? GameColors.success
                                : isEnabled
                                    ? GameColors.textPrimary
                                    : GameColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                        if (choice.hint != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            choice.hint!,
                            style: GameTypography.bodySmall.copyWith(
                              color: isSelected
                                  ? GameColors.success
                                  : isEnabled
                                      ? GameColors.textSecondary
                                      : GameColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isLocked && isSelected)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GameColors.success,
                      ),
                    )
                  else if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: GameColors.success,
                    )
                  else if (!isEnabled)
                    const Icon(
                      Icons.lock,
                      size: 16,
                      color: GameColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Choice data model
class EventChoice {
  final int index;
  final String label;
  final String? hint;
  final bool enabled;
  final bool selected;
  final bool locked;

  const EventChoice({
    required this.index,
    required this.label,
    this.hint,
    this.enabled = true,
    this.selected = false,
    this.locked = false,
  });
}

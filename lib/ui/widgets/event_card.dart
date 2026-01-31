import 'package:flutter/material.dart';
import '../theme/game_theme.dart';

/// Event card widget for displaying current event with choices
class EventCard extends StatelessWidget {
  final String title;
  final String text;
  final List<EventChoice> choices;
  final void Function(int index)? onChoiceSelected;

  const EventCard({
    super.key,
    required this.title,
    required this.text,
    required this.choices,
    this.onChoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: GameColors.danger,
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

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              style: GameTypography.body.copyWith(height: 1.6),
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
    );
  }
}

/// Choice button widget
class _ChoiceButton extends StatelessWidget {
  final EventChoice choice;
  final VoidCallback? onTap;

  const _ChoiceButton({
    required this.choice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: choice.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: choice.enabled
                ? GameColors.surfaceLight
                : GameColors.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: choice.enabled
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
                  color: choice.enabled
                      ? GameColors.danger.withOpacity(0.2)
                      : GameColors.textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${choice.index + 1}',
                    style: GameTypography.button.copyWith(
                      color: choice.enabled
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
                        color: choice.enabled
                            ? GameColors.textPrimary
                            : GameColors.textMuted,
                      ),
                    ),
                    if (choice.hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        choice.hint!,
                        style: GameTypography.caption.copyWith(
                          color: choice.enabled
                              ? GameColors.textSecondary
                              : GameColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!choice.enabled)
                const Icon(
                  Icons.lock,
                  size: 16,
                  color: GameColors.textMuted,
                ),
            ],
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

  const EventChoice({
    required this.index,
    required this.label,
    this.hint,
    this.enabled = true,
  });
}

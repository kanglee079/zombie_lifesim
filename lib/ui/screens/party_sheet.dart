import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/stat_bar.dart';

/// Party management bottom sheet
class PartySheet extends ConsumerWidget {
  const PartySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final party = ref.watch(partyProvider);
    final gameState = ref.watch(gameStateProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
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
                    const Icon(Icons.people, color: GameColors.info),
                    const SizedBox(width: 12),
                    Text('Nhóm', style: GameTypography.heading2),
                    const Spacer(),
                    // Tension indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTensionColor(gameState?.tension ?? 0)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 14,
                            color: _getTensionColor(gameState?.tension ?? 0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Căng thẳng: ${gameState?.tension ?? 0}',
                            style: GameTypography.caption.copyWith(
                              color: _getTensionColor(gameState?.tension ?? 0),
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

              // Party list
              Expanded(
                child: party.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: GameColors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nhóm trống',
                              style: GameTypography.body.copyWith(
                                color: GameColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: party.length,
                        itemBuilder: (context, index) {
                          final member = party[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PartyMemberCard(member: member),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getTensionColor(int tension) {
    if (tension >= 80) return GameColors.danger;
    if (tension >= 50) return GameColors.warning;
    if (tension >= 30) return GameColors.gold;
    return GameColors.success;
  }
}

class _PartyMemberCard extends StatelessWidget {
  final dynamic member;

  const _PartyMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: member.isPlayer
              ? GameColors.danger.withOpacity(0.5)
              : GameColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: member.isPlayer
                      ? GameColors.danger.withOpacity(0.2)
                      : GameColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    member.isPlayer ? Icons.person : Icons.person_outline,
                    color: member.isPlayer ? GameColors.danger : GameColors.info,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: GameTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (member.isPlayer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: GameColors.danger.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'BẠN',
                              style: GameTypography.caption.copyWith(
                                color: GameColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      member.role,
                      style: GameTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Stats
          Row(
            children: [
              Expanded(
                child: StatBar(
                  label: 'HP',
                  value: member.hp,
                  color: GameColors.hp,
                  icon: Icons.favorite,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatBar(
                  label: 'Tinh thần',
                  value: member.morale,
                  color: GameColors.info,
                  icon: Icons.psychology,
                  compact: true,
                ),
              ),
            ],
          ),

          // Traits
          if ((member.traits as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: (member.traits as List).map<Widget>((traitId) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    traitId,
                    style: GameTypography.caption,
                  ),
                );
              }).toList(),
            ),
          ],

          // Skills
          if ((member.skills as Map).isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (member.skills as Map).entries.map<Widget>((entry) {
                return _SkillBadge(
                  name: _getSkillName(entry.key),
                  level: entry.value,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getSkillName(String key) {
    switch (key) {
      case 'combat':
        return 'Chiến đấu';
      case 'stealth':
        return 'Lén lút';
      case 'medical':
        return 'Y tế';
      case 'craft':
        return 'Chế tạo';
      case 'scavenge':
        return 'Khám phá';
      default:
        return key;
    }
  }
}

class _SkillBadge extends StatelessWidget {
  final String name;
  final int level;

  const _SkillBadge({required this.name, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getSkillColor(level).withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getSkillColor(level).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: GameTypography.caption.copyWith(
              color: _getSkillColor(level),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$level',
            style: GameTypography.caption.copyWith(
              color: _getSkillColor(level),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSkillColor(int level) {
    if (level >= 8) return GameColors.legendary;
    if (level >= 6) return GameColors.epic;
    if (level >= 4) return GameColors.rare;
    if (level >= 2) return GameColors.uncommon;
    return GameColors.common;
  }
}

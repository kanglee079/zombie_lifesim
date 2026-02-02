import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';

class GuideSheet extends ConsumerWidget {
  const GuideSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final tutorialDone = gameState?.flags.contains('tutorial_done') ?? false;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GameColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, color: GameColors.info),
                    const SizedBox(width: 12),
                    Text('Hướng dẫn nhanh', style: GameTypography.heading2),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      'Vòng lặp mỗi ngày',
                      [
                        'Buổi sáng có sự kiện khởi đầu.',
                        'Ban ngày bạn chọn hành động (khám phá, chế tạo, nghỉ).',
                        'Kết thúc ngày để qua đêm và sang ngày mới.',
                        'Đồng hồ chạy theo thời gian thật; hành động tiêu tốn thời gian.',
                      ],
                    ),
                    _buildSection(
                      'Ý nghĩa chỉ số',
                      [
                        'Hunger/Thirst càng cao càng xấu và làm tụt HP.',
                        'Fatigue cao khiến ngày kém hiệu quả.',
                        'Stress cao kéo morale xuống.',
                      ],
                    ),
                    _buildSection(
                      'Noise/Smell/SignalHeat',
                      [
                        'Noise/Smell thu hút zombie về căn cứ.',
                        'SignalHeat thu hút raider và thợ săn tín hiệu.',
                        'Giữ các chỉ số này thấp để sống sót lâu hơn.',
                      ],
                    ),
                    _buildSection(
                      'Thời gian & phong cách khám phá',
                      [
                        'Nhanh: ít rủi ro, ít loot.',
                        'Dài: nhiều loot, rủi ro cao.',
                        'Lén lút giảm ồn, Tham tăng rủi ro.',
                      ],
                    ),
                    _buildSection(
                      'Chế tạo / Giao dịch / Bản đồ',
                      [
                        'Chế tạo đổi nguyên liệu thành trang bị hữu ích.',
                        'Giao dịch giúp đổi đồ dư lấy nhu yếu phẩm.',
                        'Bản đồ mở khóa khu vực mới để khám phá.',
                      ],
                    ),
                    _buildSection(
                      'Numbers Station puzzle',
                      [
                        'Cộng từng nhóm số rồi lấy số dư 6 (0 = 6).',
                        'Nhóm 1 = quận, nhóm 2 = ô, nhóm 3 = tủ.',
                        'Ví dụ: 3+1+9=13 → 13 mod 6 = 1.',
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Feature unlock info (replaces old toggle)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GameColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔓 Mở khóa tính năng',
                            style: GameTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Giao dịch: Mở sau ngày 5, gặp thương nhân, hoặc ghi lịch trên bảng việc',
                            style: GameTypography.caption,
                          ),
                          Text(
                            '• Bản đồ: Mở sau ngày 7, khám phá 3+ địa điểm, hoặc hoàn thành quest',
                            style: GameTypography.caption,
                          ),
                          Text(
                            '• Dự án: Mở sau ngày 3 hoặc lập dự án trên bảng việc',
                            style: GameTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: tutorialDone,
                      onChanged: (value) => ref
                          .read(gameStateProvider.notifier)
                          .setFlag('tutorial_done', enabled: value),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        'Không hiện hướng dẫn nữa',
                        style: GameTypography.body,
                      ),
                      subtitle: Text(
                        'Bạn vẫn có thể mở lại từ nút ?.',
                        style: GameTypography.caption,
                      ),
                      activeColor: GameColors.success,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: GameColors.info,
                      ),
                      child: Text('Đóng', style: GameTypography.button),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<String> lines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GameTypography.heading3),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $line',
                style: GameTypography.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

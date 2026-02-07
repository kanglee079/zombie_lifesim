import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/game_theme.dart';

/// Full onboarding flow for new players
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isTyping = false;
  String _displayedText = '';

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: '🌆',
      title: 'Ngày thứ nhất...',
      story: 'Thành phố đã sụp đổ. Đài phát thanh im bặt từ 72 giờ trước. '
          'Bạn tỉnh dậy trong một căn phòng tối, cửa sổ bị bít kín bằng ván gỗ.\n\n'
          'Bên ngoài, những tiếng rên rỉ vọng lại từ đường phố hoang vắng...',
      color: GameColors.danger,
    ),
    _OnboardingPage(
      icon: '🎒',
      title: 'Thu thập tài nguyên',
      story: 'Nước, thức ăn, vật liệu — mọi thứ đều khan hiếm.\n\n'
          '• Nhấn "Khám phá" để tìm kiếm tài nguyên\n'
          '• Chọn địa điểm và phong cách (lén lút / bình thường / tham lam)\n'
          '• Cẩn thận: khám phá gây tiếng ồn và tiêu hao thể lực',
      color: GameColors.warning,
    ),
    _OnboardingPage(
      icon: '🔨',
      title: 'Xây dựng & Chế tạo',
      story: 'Biến nguyên liệu thành công cụ sinh tồn.\n\n'
          '• "Chế tạo" để tạo vũ khí, thuốc, công cụ\n'
          '• "Gia cố" căn cứ để phòng thủ ban đêm\n'
          '• Bắt đầu "Dự án" dài hạn để nâng cấp căn cứ',
      color: GameColors.info,
    ),
    _OnboardingPage(
      icon: '🌙',
      title: 'Sống sót qua đêm',
      story: 'Mỗi đêm, zombie sẽ tấn công.\n\n'
          '• Phòng thủ cao = ít thiệt hại hơn\n'
          '• Tiếng ồn và mùi thu hút zombie\n'
          '• Tín hiệu radio giúp tìm người sống sót — nhưng cũng bị theo dõi',
      color: GameColors.zombie,
    ),
    _OnboardingPage(
      icon: '📊',
      title: 'Quản lý chỉ số',
      story: 'Theo dõi sức khỏe của bạn:\n\n'
          '• ❤️ HP — Máu. Về 0 = Game Over\n'
          '• 🍖 Đói / 💧 Khát — Tăng mỗi ngày, cần ăn uống\n'
          '• 😰 Mệt / 😤 Stress — Nghỉ ngơi để giảm\n'
          '• 🦠 Nhiễm — Tìm thuốc, không để lây lan\n\n'
          'Nhấn vào bất kỳ chỉ số nào để xem chi tiết!',
      color: GameColors.success,
    ),
    _OnboardingPage(
      icon: '🧟',
      title: 'Bạn đã sẵn sàng?',
      story: 'Mỗi quyết định đều có hậu quả.\n'
          'Mỗi ngày là một cuộc chiến sinh tồn.\n\n'
          'Tìm kiếm. Xây dựng. Kết nối.\n'
          'Trong thế giới nơi mỗi lựa chọn đều quan trọng.\n\n'
          '🎯 Mục tiêu: Sống sót càng lâu càng tốt!',
      color: GameColors.gold,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTyping(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startTyping(int pageIndex) {
    if (pageIndex >= _pages.length) return;
    _isTyping = true;
    _displayedText = '';
    final fullText = _pages[pageIndex].story;
    int charIndex = 0;

    Future.doWhile(() async {
      if (!mounted || _currentPage != pageIndex) return false;
      if (charIndex >= fullText.length) {
        if (mounted) setState(() => _isTyping = false);
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 15));
      if (!mounted || _currentPage != pageIndex) return false;
      charIndex++;
      setState(() {
        _displayedText = fullText.substring(0, charIndex);
      });
      return true;
    });
  }

  void _skipTyping() {
    if (_isTyping) {
      setState(() {
        _displayedText = _pages[_currentPage].story;
        _isTyping = false;
      });
    }
  }

  void _nextPage() {
    if (_isTyping) {
      _skipTyping();
      return;
    }
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      HapticFeedback.mediumImpact();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicators
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(_pages.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? _pages[_currentPage].color
                            : GameColors.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: Text(
                  'Bỏ qua',
                  style: GameTypography.body.copyWith(
                    color: GameColors.textMuted,
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  _startTyping(page);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return GestureDetector(
                    onTap: _skipTyping,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon
                          AnimatedScale(
                            scale: _currentPage == index ? 1.0 : 0.8,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: page.color.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: page.color.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  page.icon,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Title
                          Text(
                            page.title,
                            style: GameTypography.heading1.copyWith(
                              color: page.color,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Story text (typewriter)
                          Container(
                            constraints: const BoxConstraints(minHeight: 180),
                            child: Text(
                              _currentPage == index
                                  ? _displayedText
                                  : page.story,
                              style: GameTypography.body.copyWith(
                                color: GameColors.textSecondary,
                                height: 1.6,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _isTyping
                        ? 'Nhấn để bỏ qua'
                        : _currentPage == _pages.length - 1
                            ? '⚔️ Bắt đầu sinh tồn'
                            : 'Tiếp theo →',
                    style: GameTypography.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String icon;
  final String title;
  final String story;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.story,
    required this.color,
  });
}

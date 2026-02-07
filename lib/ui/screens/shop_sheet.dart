import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/game_theme.dart';
import '../providers/game_providers.dart';
import '../../game/systems/iap_system.dart';

/// Shop screen for in-app purchases
class ShopSheet extends ConsumerStatefulWidget {
  const ShopSheet({super.key});

  @override
  ConsumerState<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends ConsumerState<ShopSheet> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final iap = ref.watch(iapProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: GameColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
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
                  const Text('🛒', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cửa hàng',
                      style: GameTypography.heading2,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      setState(() => _loading = true);
                      await iap.restorePurchases();
                      if (mounted) {
                        setState(() => _loading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã khôi phục giao dịch'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Khôi phục',
                      style: GameTypography.caption.copyWith(
                        color: GameColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GameColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GameColors.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 18, color: GameColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GameTypography.caption.copyWith(
                            color: GameColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: GameColors.gold),
              )
            else
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Premium section
                    _buildSectionHeader('⭐ Premium', 'Trải nghiệm tốt nhất'),
                    _buildPremiumCard(iap),
                    const SizedBox(height: 20),

                    // One-time purchases
                    _buildSectionHeader('🎁 Gói một lần', 'Mua một lần, dùng mãi'),
                    _buildProductCard(
                      iap,
                      IAPProducts.removeAds,
                      isPurchased: iap.isAdFree,
                    ),
                    const SizedBox(height: 20),

                    // Consumable packs
                    _buildSectionHeader('📦 Gói tài nguyên', 'Tăng tốc sinh tồn'),
                    _buildProductCard(iap, IAPProducts.starterPack),
                    const SizedBox(height: 8),
                    _buildProductCard(iap, IAPProducts.survivalKit),
                    const SizedBox(height: 8),
                    _buildProductCard(iap, IAPProducts.resourcePack),
                    const SizedBox(height: 20),

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GameColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '• Giao dịch được xử lý qua App Store / Google Play\n'
                        '• Gói Premium tự động gia hạn\n'
                        '• Hủy bất kỳ lúc nào trong cài đặt thiết bị\n'
                        '• Khôi phục giao dịch nếu đổi thiết bị',
                        style: GameTypography.caption.copyWith(
                          color: GameColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GameTypography.heading3),
          Text(
            subtitle,
            style: GameTypography.caption.copyWith(
              color: GameColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(IAPSystem iap) {
    final weeklyProduct = iap.getProduct(IAPProducts.premiumWeekly);
    final monthlyProduct = iap.getProduct(IAPProducts.premiumMonthly);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameColors.gold.withOpacity(0.15),
            GameColors.gold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GameColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('👑', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium',
                      style: GameTypography.heading3.copyWith(
                        color: GameColors.gold,
                      ),
                    ),
                    if (iap.isPremium)
                      Text(
                        '✅ Đang hoạt động',
                        style: GameTypography.caption.copyWith(
                          color: GameColors.success,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _premiumBenefit('🚫', 'Không quảng cáo'),
          _premiumBenefit('📦', '+20% tài nguyên khi khám phá'),
          _premiumBenefit('🎁', 'Phần thưởng đăng nhập hàng ngày'),
          _premiumBenefit('💾', 'Tự động sao lưu đám mây'),
          const SizedBox(height: 16),
          if (!iap.isPremium) ...[
            Row(
              children: [
                Expanded(
                  child: _buildBuyButton(
                    label: weeklyProduct?.price ?? '₫29.000/tuần',
                    sublabel: 'Hàng tuần',
                    color: GameColors.gold.withOpacity(0.8),
                    onPressed: () =>
                        _purchaseProduct(iap, IAPProducts.premiumWeekly),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBuyButton(
                    label: monthlyProduct?.price ?? '₫79.000/tháng',
                    sublabel: 'Hàng tháng (tiết kiệm)',
                    color: GameColors.gold,
                    onPressed: () =>
                        _purchaseProduct(iap, IAPProducts.premiumMonthly),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _premiumBenefit(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(text, style: GameTypography.body),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    IAPSystem iap,
    String productId, {
    bool isPurchased = false,
  }) {
    final product = iap.getProduct(productId);
    final info = iap.getProductInfo(productId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPurchased
              ? GameColors.success.withOpacity(0.3)
              : GameColors.surfaceLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                info['icon']!,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.title ?? info['name']!,
                  style: GameTypography.bodyMedium,
                ),
                Text(
                  info['description']!,
                  style: GameTypography.caption.copyWith(
                    color: GameColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPurchased)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GameColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✅',
                style: GameTypography.caption.copyWith(
                  color: GameColors.success,
                ),
              ),
            )
          else
            _buildBuyButton(
              label: product?.price ?? '...',
              onPressed: () => _purchaseProduct(iap, productId),
            ),
        ],
      ),
    );
  }

  Widget _buildBuyButton({
    required String label,
    String? sublabel,
    Color color = GameColors.info,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GameTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (sublabel != null)
            Text(
              sublabel,
              style: GameTypography.tiny.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _purchaseProduct(IAPSystem iap, String productId) async {
    final product = iap.getProduct(productId);
    if (product == null) {
      setState(() {
        _error = 'Sản phẩm chưa sẵn sàng. Vui lòng thử lại sau.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await iap.purchase(product);

    if (mounted) {
      setState(() => _loading = false);
      if (!success) {
        setState(() {
          _error = 'Không thể hoàn tất giao dịch.';
        });
      }
    }
  }
}

import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/logger.dart';

/// Product IDs matching App Store & Google Play
class IAPProducts {
  static const String removeAds = 'zombie_lifesim_remove_ads';
  static const String premiumWeekly = 'zombie_lifesim_premium_weekly';
  static const String premiumMonthly = 'zombie_lifesim_premium_monthly';
  static const String starterPack = 'zombie_lifesim_starter_pack';
  static const String survivalKit = 'zombie_lifesim_survival_kit';
  static const String resourcePack = 'zombie_lifesim_resource_pack';

  static const Set<String> allProducts = {
    removeAds,
    premiumWeekly,
    premiumMonthly,
    starterPack,
    survivalKit,
    resourcePack,
  };

  static const Set<String> consumables = {
    starterPack,
    survivalKit,
    resourcePack,
  };

  static const Set<String> subscriptions = {
    premiumWeekly,
    premiumMonthly,
  };

  static const Set<String> nonConsumables = {
    removeAds,
  };
}

/// In-App Purchase system
class IAPSystem {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  bool get isAvailable => _available;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  Set<String> _purchased = {};
  Set<String> get purchasedProducts => _purchased;

  bool get isPremium => _purchased.contains(IAPProducts.premiumWeekly) ||
      _purchased.contains(IAPProducts.premiumMonthly);

  bool get isAdFree => _purchased.contains(IAPProducts.removeAds) || isPremium;

  // Callbacks
  void Function(String productId)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;

  /// Initialize the IAP system
  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      GameLogger.game('IAP not available on this device');
      return;
    }

    // Listen for purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        GameLogger.error('IAP stream error', error);
      },
    );

    // Load products
    await _loadProducts();

    // Restore previous purchases
    await restorePurchases();

    GameLogger.game('IAP initialized. ${_products.length} products loaded.');
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(IAPProducts.allProducts);

    if (response.notFoundIDs.isNotEmpty) {
      GameLogger.warn('IAP products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;

    // Sort by price
    _products.sort((a, b) {
      final priceA = a.rawPrice;
      final priceB = b.rawPrice;
      return priceA.compareTo(priceB);
    });
  }

  /// Purchase a product
  Future<bool> purchase(ProductDetails product) async {
    if (!_available) return false;

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      bool success;
      if (IAPProducts.consumables.contains(product.id)) {
        success = await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
      return success;
    } catch (e) {
      GameLogger.error('IAP purchase error', e);
      onPurchaseError?.call('Không thể mua. Vui lòng thử lại.');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          GameLogger.game('IAP pending: ${purchaseDetails.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchaseDetails);
          break;

        case PurchaseStatus.error:
          GameLogger.error(
            'IAP error: ${purchaseDetails.productID}',
            purchaseDetails.error,
          );
          onPurchaseError?.call(
            purchaseDetails.error?.message ?? 'Lỗi mua hàng',
          );
          if (purchaseDetails.pendingCompletePurchase) {
            _iap.completePurchase(purchaseDetails);
          }
          break;

        case PurchaseStatus.canceled:
          GameLogger.game('IAP canceled: ${purchaseDetails.productID}');
          if (purchaseDetails.pendingCompletePurchase) {
            _iap.completePurchase(purchaseDetails);
          }
          break;
      }
    }
  }

  void _verifyAndDeliver(PurchaseDetails purchaseDetails) {
    // In production, verify with your backend server
    // For now, trust the store receipt
    _purchased.add(purchaseDetails.productID);

    GameLogger.game('IAP delivered: ${purchaseDetails.productID}');
    onPurchaseSuccess?.call(purchaseDetails.productID);

    if (purchaseDetails.pendingCompletePurchase) {
      _iap.completePurchase(purchaseDetails);
    }
  }

  /// Get a specific product
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Get display info for a product (fallback if store not loaded)
  Map<String, String> getProductInfo(String productId) {
    switch (productId) {
      case IAPProducts.removeAds:
        return {
          'name': 'Xóa quảng cáo',
          'description': 'Trải nghiệm game không quảng cáo vĩnh viễn',
          'icon': '🚫',
        };
      case IAPProducts.premiumWeekly:
        return {
          'name': 'Premium (Tuần)',
          'description': 'Không quảng cáo + 20% bonus tài nguyên + Daily rewards',
          'icon': '⭐',
        };
      case IAPProducts.premiumMonthly:
        return {
          'name': 'Premium (Tháng)',
          'description': 'Không quảng cáo + 20% bonus tài nguyên + Daily rewards',
          'icon': '👑',
        };
      case IAPProducts.starterPack:
        return {
          'name': 'Gói khởi đầu',
          'description': 'Nước x5, Đồ ăn x5, Thuốc x2, Ván gỗ x3',
          'icon': '🎁',
        };
      case IAPProducts.survivalKit:
        return {
          'name': 'Kit sinh tồn',
          'description': 'Bộ công cụ đầy đủ + Vật liệu hiếm',
          'icon': '🧰',
        };
      case IAPProducts.resourcePack:
        return {
          'name': 'Gói tài nguyên',
          'description': 'Nước x10, Thức ăn x10, Vật liệu đa dạng',
          'icon': '📦',
        };
      default:
        return {
          'name': productId,
          'description': '',
          'icon': '🛒',
        };
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

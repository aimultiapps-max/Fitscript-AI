import 'package:in_app_purchase/in_app_purchase.dart';

enum PurchaseStartResult { started, unavailable, failed }

class InAppPurchaseService {
  InAppPurchaseService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  Stream<List<PurchaseDetails>> get purchaseUpdates =>
      _inAppPurchase.purchaseStream;

  Future<bool> isStoreAvailable() {
    return _inAppPurchase.isAvailable();
  }

  Future<Map<String, ProductDetails>> loadProducts(
    Set<String> productIds,
  ) async {
    if (productIds.isEmpty) return const <String, ProductDetails>{};
    final response = await _inAppPurchase.queryProductDetails(productIds);
    if (response.error != null || response.productDetails.isEmpty) {
      return const <String, ProductDetails>{};
    }

    return {for (final item in response.productDetails) item.id: item};
  }

  Future<PurchaseStartResult> buyProduct(ProductDetails productDetails) async {
    final isAvailable = await isStoreAvailable();
    if (!isAvailable) return PurchaseStartResult.unavailable;

    try {
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return PurchaseStartResult.started;
    } catch (_) {
      return PurchaseStartResult.failed;
    }
  }

  Future<void> restorePurchases() {
    return _inAppPurchase.restorePurchases();
  }

  Future<void> completePurchase(PurchaseDetails purchaseDetails) {
    return _inAppPurchase.completePurchase(purchaseDetails);
  }
}

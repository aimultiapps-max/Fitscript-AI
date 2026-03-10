import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

enum PurchaseStartResult { started, unavailable, failed }

class InAppPurchaseService {
  InAppPurchaseService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;
  String? _lastPurchaseErrorMessage;

  String? get lastPurchaseErrorMessage => _lastPurchaseErrorMessage;

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
      _lastPurchaseErrorMessage = null;
      if (defaultTargetPlatform == TargetPlatform.android &&
          productDetails is GooglePlayProductDetails) {
        final offerDetails =
            productDetails.productDetails.subscriptionOfferDetails;
        String? offerToken;
        if (offerDetails != null && offerDetails.isNotEmpty) {
          final basePlanOffer = offerDetails.firstWhere(
            (offer) => (offer.offerId ?? '').trim().isEmpty,
            orElse: () => offerDetails.first,
          );
          offerToken = basePlanOffer.offerIdToken;
        }
        final purchaseParam = GooglePlayPurchaseParam(
          productDetails: productDetails,
          offerToken: offerToken,
        );
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        final purchaseParam = PurchaseParam(productDetails: productDetails);
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
      return PurchaseStartResult.started;
    } catch (error) {
      _lastPurchaseErrorMessage =
          'SKU=${productDetails.id}; error=${error.toString()}';
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

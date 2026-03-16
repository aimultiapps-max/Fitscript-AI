import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../../core/services/in_app_purchase_service.dart';

class PremiumUpgradeView extends StatefulWidget {
  const PremiumUpgradeView({super.key, this.autoRestoreOnOpen = false});

  final bool autoRestoreOnOpen;

  @override
  State<PremiumUpgradeView> createState() => _PremiumUpgradeViewState();
}

class _PremiumUpgradeViewState extends State<PremiumUpgradeView> {
  int _selectedPlanIndex = 0;
  String _iosMonthlyProductId = 'com.aimultiapps.fitscriptAi.premium.monthly';
  String _iosYearlyProductId = 'com.aimultiapps.fitscriptAi.premium.yearly';
  String _androidMonthlyProductId = 'monthly.fitscript.ai.premium';
  String _androidYearlyProductId = 'yearly.fitscript.ai.premium';
  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  Map<String, ProductDetails> _products = const {};
  bool _isPurchasing = false;
  bool _isStoreAvailable = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool get _isAndroidPlatform =>
      defaultTargetPlatform == TargetPlatform.android;
  bool get _isIosPlatform => defaultTargetPlatform == TargetPlatform.iOS;

  String get _activeMonthlyProductId =>
      _isAndroidPlatform ? _androidMonthlyProductId : _iosMonthlyProductId;

  String get _activeYearlyProductId =>
      _isAndroidPlatform ? _androidYearlyProductId : _iosYearlyProductId;

  String get _selectedProductId => _selectedPlanIndex == 0
      ? _activeMonthlyProductId
      : _activeYearlyProductId;

  late final TapGestureRecognizer _eulaRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _eulaRecognizer = TapGestureRecognizer()..onTap = _openEula;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
    _purchaseSubscription = _purchaseService.purchaseUpdates.listen(
      _onPurchaseUpdates,
      onError: (_) {
        if (!mounted) return;
        _showPremiumSnackbar(context, 'Purchase stream error occurred.');
      },
    );
    _loadSubscriptionConfig();
    _loadStoreProducts();
    if (widget.autoRestoreOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onRestorePressed(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _eulaRecognizer.dispose();
    _privacyRecognizer.dispose();
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  bool _isManagedSku(String productId) {
    return productId == _iosMonthlyProductId ||
        productId == _iosYearlyProductId ||
        productId == _androidMonthlyProductId ||
        productId == _androidYearlyProductId;
  }

  List<String> _normalizedCandidates(List<String> values) {
    final normalized = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (!normalized.contains(trimmed)) {
        normalized.add(trimmed);
      }
    }
    return normalized;
  }

  String _pickConfiguredOrAvailableSku({
    required List<String> preferred,
    required Map<String, ProductDetails> availableProducts,
    required String currentValue,
  }) {
    for (final sku in preferred) {
      if (availableProducts.containsKey(sku)) {
        return sku;
      }
    }
    if (availableProducts.containsKey(currentValue)) {
      return currentValue;
    }
    return currentValue;
  }

  ProductDetails? _resolveSelectedProduct() {
    final selectedSku = _selectedProductId.trim();
    final direct = _products[selectedSku];
    if (direct != null) return direct;

    final fallback = _products.values.firstWhere((product) {
      final id = product.id.toLowerCase();
      if (_selectedPlanIndex == 0) {
        return id.contains('month');
      }
      return id.contains('year') || id.contains('annual');
    }, orElse: () => _products.values.first);
    return fallback;
  }

  bool _looksLikeIosSku(String sku) {
    final value = sku.toLowerCase();
    return value.startsWith('com.');
  }

  bool _looksLikeAndroidSku(String sku) {
    final value = sku.toLowerCase();
    return value.startsWith('fitscriptai') ||
        value.endsWith('.fitscript.ai.premium') ||
        value.contains('fitscript.ai.premium');
  }

  bool _isSkuCompatibleWithCurrentPlatform(String sku) {
    final normalized = sku.trim();
    final androidSkus = <String>{
      _androidMonthlyProductId,
      _androidYearlyProductId,
    };
    final iosSkus = <String>{_iosMonthlyProductId, _iosYearlyProductId};

    if (_isAndroidPlatform) {
      return androidSkus.contains(normalized) ||
          _looksLikeAndroidSku(normalized);
    }
    if (_isIosPlatform) {
      return iosSkus.contains(normalized) || _looksLikeIosSku(normalized);
    }
    return true;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!_isManagedSku(purchase.productID)) {
        if (purchase.pendingCompletePurchase) {
          await _purchaseService.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) {
          setState(() => _isPurchasing = true);
        }
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (mounted) {
          setState(() => _isPurchasing = false);
        }
        await _markPremiumEntitlement(purchase);
        if (mounted) {
          _showPremiumSnackbar(
            context,
            'Premium activated successfully.\nSKU: ${purchase.productID}',
          );
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() => _isPurchasing = false);
          final message = purchase.error!.message.trim();
          _showPremiumSnackbar(
            context,
            message.isEmpty
                ? 'Purchase failed for SKU: ${purchase.productID}'
                : 'Purchase failed: $message',
          );
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (mounted) {
          setState(() => _isPurchasing = false);
          _showPremiumSnackbar(context, 'Purchase cancelled.');
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _purchaseService.completePurchase(purchase);
      }
    }
  }

  Future<void> _markPremiumEntitlement(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        _showPremiumSnackbar(
          context,
          'User not logged in. Cannot activate premium.',
        );
      }
      debugPrint('[Premium] User not logged in saat _markPremiumEntitlement');
      return;
    }

    final yearlySkus = <String>{
      _iosYearlyProductId,
      _androidYearlyProductId,
      _activeYearlyProductId,
    };
    final isYearly = yearlySkus.contains(purchase.productID);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meta')
          .doc('subscription')
          .set({
            'isPremium': true,
            'plan': isYearly ? 'yearly' : 'monthly',
            'productId': purchase.productID,
            'purchaseId': purchase.purchaseID,
            'verificationData':
                purchase.verificationData.serverVerificationData,
            'source': purchase.verificationData.source,
            'verificationState': 'client_unverified',
            'requiresServerVerification': true,
            'status': purchase.status.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      debugPrint(
        '[Premium] Firestore subscription updated for user: ${user.uid}',
      );
    } catch (e) {
      debugPrint('[Premium] Gagal update Firestore subscription: $e');
      if (mounted) {
        _showPremiumSnackbar(
          context,
          'Gagal mengaktifkan premium. Coba lagi atau hubungi support.',
        );
      }
    }
  }

  Future<void> _onRestorePressed(BuildContext context) async {
    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);
    try {
      await _purchaseService.restorePurchases();
      if (!context.mounted) return;
      _showPremiumSnackbar(
        context,
        'Restore request sent. If previous purchases are found, premium will be activated automatically.',
      );
    } catch (_) {
      if (!context.mounted) return;
      _showPremiumSnackbar(context, 'Unable to restore purchases right now.');
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _loadSubscriptionConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final isAndroid = _isAndroidPlatform;
      final isIOS = _isIosPlatform;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(minutes: 30),
        ),
      );
      await remoteConfig.setDefaults({
        'android_monthly_fitscript_pro': 'monthly.fitscript.ai.premium',
        'android_yearly_fitscript_pro': 'yearly.fitscript.ai.premium',
        'ios_monthly_fitscript_pro':
            'com.aimultiapps.fitscriptAi.premium.monthly',
        'ios_yearly_fitscript_pro':
            'com.aimultiapps.fitscriptAi.premium.yearly',
      });
      await remoteConfig.fetchAndActivate();

      final androidMonthlyCandidates = _normalizedCandidates(<String>[
        remoteConfig.getString('android_monthly_fitscript_pro'),
        _androidMonthlyProductId,
        'monthly.fitscript.ai.premium',
      ]);
      final androidYearlyCandidates = _normalizedCandidates(<String>[
        remoteConfig.getString('android_yearly_fitscript_pro'),
        _androidYearlyProductId,
        'yearly.fitscript.ai.premium',
      ]);

      final iosMonthlyCandidates = _normalizedCandidates(<String>[
        remoteConfig.getString('ios_monthly_fitscript_pro'),
        remoteConfig.getString('monthly_fitscript_pro'),
        _iosMonthlyProductId,
        'com.aimultiapps.fitscriptAi.premium.monthly',
      ]);
      final iosYearlyCandidates = _normalizedCandidates(<String>[
        remoteConfig.getString('ios_yearly_fitscript_pro'),
        remoteConfig.getString('yearly_fitscript_pro'),
        _iosYearlyProductId,
        'com.aimultiapps.fitscriptAi.premium.yearly',
      ]);

      final monthlyCandidates = _normalizedCandidates(<String>[
        if (isAndroid) ...androidMonthlyCandidates,
        if (isIOS) ...iosMonthlyCandidates,
      ]);
      final yearlyCandidates = _normalizedCandidates(<String>[
        if (isAndroid) ...androidYearlyCandidates,
        if (isIOS) ...iosYearlyCandidates,
      ]);

      final discoveryProducts = await _purchaseService.loadProducts({
        ...monthlyCandidates,
        ...yearlyCandidates,
      });

      final monthly = _pickConfiguredOrAvailableSku(
        preferred: monthlyCandidates,
        availableProducts: discoveryProducts,
        currentValue: _activeMonthlyProductId,
      );
      final yearly = _pickConfiguredOrAvailableSku(
        preferred: yearlyCandidates,
        availableProducts: discoveryProducts,
        currentValue: _activeYearlyProductId,
      );

      if (!mounted) return;
      setState(() {
        if (isAndroid) {
          _androidMonthlyProductId = monthly;
          _androidYearlyProductId = yearly;
        } else {
          _iosMonthlyProductId = monthly;
          _iosYearlyProductId = yearly;
        }
      });

      await _loadStoreProducts();
    } catch (_) {}
  }

  Future<void> _loadStoreProducts() async {
    final isAvailable = await _purchaseService.isStoreAvailable();
    final products = await _purchaseService.loadProducts({
      _activeMonthlyProductId.trim(),
      _activeYearlyProductId.trim(),
    });

    if (!mounted) return;
    setState(() {
      _isStoreAvailable = isAvailable;
      _products = products;
    });
  }

  void _showPremiumSnackbar(BuildContext context, String message) {
    final snackTheme = Theme.of(context);
    Get.snackbar(
      'profile_upgrade_info_title'.tr,
      message,
      snackStyle: SnackStyle.FLOATING,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      borderRadius: 16,
      duration: const Duration(milliseconds: 2400),
      shouldIconPulse: false,
      backgroundColor: snackTheme.colorScheme.surfaceContainerHighest,
      colorText: snackTheme.colorScheme.onSurface,
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: snackTheme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.workspace_premium_outlined,
          size: 18,
          color: snackTheme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Future<void> _onUpgradePressed(BuildContext context) async {
    if (_isPurchasing) return;

    final selectedSku = _selectedProductId.trim();

    if (_isAndroidPlatform && !kReleaseMode) {
      _showPremiumSnackbar(
        context,
        'Android purchase test requires a Play-distributed release build (Internal testing). Current build is not release.',
      );
      return;
    }

    if (!_isSkuCompatibleWithCurrentPlatform(selectedSku)) {
      _showPremiumSnackbar(
        context,
        'SKU platform mismatch. Selected SKU: $selectedSku',
      );
      return;
    }

    if (!_isStoreAvailable) {
      _showPremiumSnackbar(context, 'Store is unavailable right now.');
      return;
    }

    final refreshedProducts = await _purchaseService.loadProducts({
      selectedSku,
      _activeMonthlyProductId.trim(),
      _activeYearlyProductId.trim(),
    });
    if (!context.mounted) return;
    if (mounted && refreshedProducts.isNotEmpty) {
      setState(() {
        _products = refreshedProducts;
      });
    }

    final product = _resolveSelectedProduct();
    if (product == null) {
      _showPremiumSnackbar(
        context,
        'Product not found. Selected SKU: $selectedSku\nAvailable: ${_products.keys.join(', ')}',
      );
      return;
    }

    final purchaseSku = product.id;
    if (!_isSkuCompatibleWithCurrentPlatform(purchaseSku)) {
      _showPremiumSnackbar(
        context,
        'Resolved SKU is not valid for this platform: $purchaseSku',
      );
      return;
    }

    setState(() => _isPurchasing = true);
    final result = await _purchaseService.buyProduct(product);
    if (!context.mounted) return;
    setState(() => _isPurchasing = false);

    final message = switch (result) {
      PurchaseStartResult.started =>
        'Purchase flow started.\nSKU: $purchaseSku',
      PurchaseStartResult.unavailable =>
        'Store is unavailable right now.\nSKU: $purchaseSku',
      PurchaseStartResult.failed =>
        'Unable to start purchase flow.\n'
            'Selected: $selectedSku\n'
            'Resolved: $purchaseSku\n'
            'Monthly: ${_activeMonthlyProductId.trim()}\n'
            'Yearly: ${_activeYearlyProductId.trim()}\n'
            '${_purchaseService.lastPurchaseErrorMessage ?? ''}',
    };
    _showPremiumSnackbar(context, message);
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showPremiumSnackbar(context, 'Unable to open link.');
    }
  }

  Future<void> _openEula() async {
    await _openExternalUrl(
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
    );
  }

  Future<void> _openPrivacy() async {
    await _openExternalUrl('https://fitscript-ai.web.app/privacy');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('premium_title'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.16,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'premium_plan_name'.tr,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'premium_subtitle'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PriceChip(
                        label:
                            _products[_activeMonthlyProductId]?.price ??
                            r'$0,0/Month',
                        color: theme.colorScheme.primaryContainer,
                        background: theme.colorScheme.surface.withValues(
                          alpha: 0.9,
                        ),
                      ),
                      _PriceChip(
                        label:
                            _products[_activeYearlyProductId]?.price ??
                            r'$0,0/Year',
                        color: theme.colorScheme.primaryContainer,
                        background: theme.colorScheme.surface.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FeatureTile(
            icon: Icons.document_scanner_outlined,
            title: 'premium_feature_scan_title'.tr,
            subtitle: 'premium_feature_scan_subtitle'.tr,
          ),
          const SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.psychology_alt_outlined,
            title: 'premium_feature_insight_title'.tr,
            subtitle: 'premium_feature_insight_subtitle'.tr,
          ),
          const SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.show_chart_outlined,
            title: 'premium_feature_trend_title'.tr,
            subtitle: 'premium_feature_trend_subtitle'.tr,
          ),
          const SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'premium_feature_export_title'.tr,
            subtitle: 'premium_feature_export_subtitle'.tr,
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            color: theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'premium_pricing_title'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SelectablePriceOption(
                    isSelected: _selectedPlanIndex == 0,
                    title: 'Monthly FitScript AI',
                    description:
                        'Unlimited scans & deep AI health insights for 1 month.',
                    price:
                        _products[_activeMonthlyProductId]?.price ??
                        r'$0,0/Month',
                    onTap: () => setState(() => _selectedPlanIndex = 0),
                  ),
                  const SizedBox(height: 8),
                  _SelectablePriceOption(
                    isSelected: _selectedPlanIndex == 1,
                    title: 'Yearly FitScript AI',
                    description:
                        'Unlimited scans & trend analysis for 1 year. Save 40%!',
                    price:
                        _products[_activeYearlyProductId]?.price ??
                        r'$0,0/Year',
                    onTap: () => setState(() => _selectedPlanIndex = 1),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'premium_pricing_note'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 16),
            child: Text.rich(
              TextSpan(
                text: 'By subscribing, you agree to our ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Use (EULA)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _eulaRecognizer,
                  ),
                  TextSpan(
                    text: ' and ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _privacyRecognizer,
                  ),
                ],
              ),
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isPurchasing
                  ? null
                  : () => _onUpgradePressed(context),
              child: Text(
                _isPurchasing
                    ? 'profile_connecting'.tr
                    : 'premium_cta_upgrade'.tr,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isPurchasing
                  ? null
                  : () => _onRestorePressed(context),
              child: Text('profile_restore_button'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SelectablePriceOption extends StatelessWidget {
  const _SelectablePriceOption({
    required this.isSelected,
    required this.title,
    required this.description,
    required this.price,
    required this.onTap,
  });

  final bool isSelected;
  final String title;
  final String description;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.42)
                : theme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      price,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

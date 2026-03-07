import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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
  String _monthlyProductId = 'com.aimultiapps.fitscriptAi.premium.monthly';
  String _yearlyProductId = 'com.aimultiapps.fitscriptAi.premium.yearly';
  final InAppPurchaseService _purchaseService = InAppPurchaseService();
  Map<String, ProductDetails> _products = const {};
  bool _isPurchasing = false;
  bool _isStoreAvailable = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  String get _selectedProductId =>
      _selectedPlanIndex == 0 ? _monthlyProductId : _yearlyProductId;

  @override
  void initState() {
    super.initState();
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
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  bool _isManagedSku(String productId) {
    return productId == _monthlyProductId || productId == _yearlyProductId;
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
    if (user == null) return;

    final isYearly = purchase.productID == _yearlyProductId;
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
          'verificationData': purchase.verificationData.serverVerificationData,
          'source': purchase.verificationData.source,
          'verificationState': 'client_unverified',
          'requiresServerVerification': true,
          'status': purchase.status.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _onRestorePressed(BuildContext context) async {
    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);
    try {
      await _purchaseService.restorePurchases();
      if (!mounted) return;
      _showPremiumSnackbar(
        context,
        'Restore request sent. If previous purchases are found, premium will be activated automatically.',
      );
    } catch (_) {
      if (!mounted) return;
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
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(minutes: 30),
        ),
      );
      await remoteConfig.setDefaults({
        'monthly_fitscript_pro': _monthlyProductId,
        'yearly_fitscript_pro': _yearlyProductId,
      });
      await remoteConfig.fetchAndActivate();

      final monthly = remoteConfig.getString('monthly_fitscript_pro').trim();
      final yearly = remoteConfig.getString('yearly_fitscript_pro').trim();

      if (!mounted) return;
      setState(() {
        if (monthly.isNotEmpty) {
          _monthlyProductId = monthly;
        }
        if (yearly.isNotEmpty) {
          _yearlyProductId = yearly;
        }
      });

      await _loadStoreProducts();
    } catch (_) {}
  }

  Future<void> _loadStoreProducts() async {
    final isAvailable = await _purchaseService.isStoreAvailable();
    final products = await _purchaseService.loadProducts({
      _monthlyProductId,
      _yearlyProductId,
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

    final selectedSku = _selectedProductId;

    if (!_isStoreAvailable) {
      _showPremiumSnackbar(context, 'Store is unavailable right now.');
      return;
    }

    final product = _products[selectedSku];
    if (product == null) {
      _showPremiumSnackbar(context, 'Product not found for SKU: $selectedSku');
      return;
    }

    setState(() => _isPurchasing = true);
    final result = await _purchaseService.buyProduct(product);
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    final message = switch (result) {
      PurchaseStartResult.started =>
        'Purchase flow started.\nSKU: $selectedSku',
      PurchaseStartResult.unavailable =>
        'Store is unavailable right now.\nSKU: $selectedSku',
      PurchaseStartResult.failed =>
        'Unable to start purchase flow.\nSKU: $selectedSku',
    };
    _showPremiumSnackbar(context, message);
  }

  bool get _isIndonesiaLocale {
    final locale = Get.locale;
    if (locale == null) return false;
    return locale.languageCode.toLowerCase() == 'id' ||
        locale.countryCode?.toUpperCase() == 'ID';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIndonesia = _isIndonesiaLocale;
    final highlightedMonthly = isIndonesia
        ? 'premium_price_id_monthly'.tr
        : 'premium_price_global_monthly'.tr;
    final highlightedYearly = isIndonesia
        ? 'premium_price_id_yearly'.tr
        : 'premium_price_global_yearly'.tr;

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
                        label: highlightedMonthly,
                        color: theme.colorScheme.onPrimaryContainer,
                        background: theme.colorScheme.surface.withValues(
                          alpha: 0.9,
                        ),
                      ),
                      _PriceChip(
                        label: highlightedYearly,
                        color: theme.colorScheme.onPrimaryContainer,
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
                        _products[_monthlyProductId]?.price ?? r'$4,99/Month',
                    onTap: () => setState(() => _selectedPlanIndex = 0),
                  ),
                  const SizedBox(height: 8),
                  _SelectablePriceOption(
                    isSelected: _selectedPlanIndex == 1,
                    title: 'Yearly FitScript AI',
                    description:
                        'Unlimited scans & trend analysis for 1 year. Save 40%!',
                    price: _products[_yearlyProductId]?.price ?? r'$39,99/Year',
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
          const SizedBox(height: 16),
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

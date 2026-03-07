import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PremiumUpgradeView extends StatelessWidget {
  const PremiumUpgradeView({super.key});

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
                  _PriceRow(
                    market: 'premium_pricing_market_id'.tr,
                    monthly: 'premium_price_id_monthly'.tr,
                    yearly: 'premium_price_id_yearly'.tr,
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    market: 'premium_pricing_market_global'.tr,
                    monthly: 'premium_price_global_monthly'.tr,
                    yearly: 'premium_price_global_yearly'.tr,
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
              onPressed: () {
                final snackTheme = Theme.of(context);
                Get.snackbar(
                  'profile_upgrade_info_title'.tr,
                  'profile_upgrade_info_message'.tr,
                  snackStyle: SnackStyle.FLOATING,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  borderRadius: 16,
                  duration: const Duration(milliseconds: 2400),
                  shouldIconPulse: false,
                  backgroundColor:
                      snackTheme.colorScheme.surfaceContainerHighest,
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
              },
              child: Text('premium_cta_upgrade'.tr),
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

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.market,
    required this.monthly,
    required this.yearly,
  });

  final String market;
  final String monthly;
  final String yearly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          market,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(monthly, style: theme.textTheme.bodyMedium),
        Text(
          yearly,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/lab_analysis_service.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return Obx(() {
      final currentIndex = controller.selectedTabIndex.value;
      final pages = _buildPages(context);
      final tabTitles = ['tab_home'.tr, 'tab_history'.tr, 'tab_profile'.tr];
      final title = tabTitles[currentIndex];

      if (isIOS) {
        return AdaptiveScaffold(
          bottomNavigationBar: AdaptiveBottomNavigationBar(
            selectedIndex: currentIndex,
            onTap: controller.onTabChanged,
            items: [
              AdaptiveNavigationDestination(
                icon: 'house',
                selectedIcon: 'house.fill',
                label: 'nav_home'.tr,
              ),
              AdaptiveNavigationDestination(
                icon: 'clock.arrow.circlepath',
                selectedIcon: 'clock.arrow.circlepath',
                label: 'nav_history'.tr,
              ),
              AdaptiveNavigationDestination(
                icon: 'person',
                selectedIcon: 'person.fill',
                label: 'nav_account'.tr,
              ),
            ],
          ),
          body: IndexedStack(index: currentIndex, children: pages),
        );
      }

      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: IndexedStack(index: currentIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: controller.onTabChanged,
          backgroundColor: theme.colorScheme.surfaceContainer,
          indicatorColor: theme.colorScheme.primaryContainer,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'nav_home'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history),
              label: 'nav_history'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: 'nav_account'.tr,
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildPages(BuildContext context) {
    return [
      _HomeMainContent(controller: controller),
      _HistoryPage(controller: controller),
      _ProfilePage(controller: controller),
    ];
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Obx(() {
          final theme = Theme.of(context);
          final histories = controller.analysisHistories;
          final isLoading = controller.isHistoryLoading.value;
          final isPremium = controller.isPremiumUser.value;
          final trendScores = controller.chartTrendScores;
          final trendStartDate = controller.chartTrendStartDateLabel;
          final trendEndDate = controller.chartTrendEndDateLabel;
          final canShowTrend = controller.canShowTrendAnalysis;
          final trendDelta = controller.trendDelta;
          final primaryTrend = controller.primaryBiomarkerTrend;
          final secondaryTrendLabels = controller.secondaryBiomarkerTrendLabels;
          final topBiomarkerTrends = controller.biomarkerTrends
              .take(3)
              .toList();
          final trendMessage = trendDelta > 0.05
              ? 'history_trend_up'.tr
              : trendDelta < -0.05
              ? 'history_trend_down'.tr
              : 'history_trend_stable'.tr;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.42,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.history_edu_outlined,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'history_title'.tr,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'history_subtitle'.tr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timeline_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${controller.totalHistories} ${'history_metric_total'.tr.toLowerCase()}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _StatusChip(
                              status: controller.warningCount > 0
                                  ? LabHistoryStatus.warning
                                  : LabHistoryStatus.normal,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'history_metric_total'.tr,
                      value: '${controller.totalHistories}',
                      icon: Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'history_metric_warning'.tr,
                      value: '${controller.warningCount}',
                      icon: Icons.warning_amber_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'history_metric_improve'.tr,
                      value: '${controller.improveCount}',
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (histories.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.38,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.show_chart_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'history_trend_title'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'history_trend_subtitle'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isPremium && primaryTrend != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'history_trend_focus_label'.trParams({
                            'marker': primaryTrend.label,
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (!isPremium) ...[
                        Text(
                          'history_trend_premium_message'.tr,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: controller.upgradeToPremium,
                          icon: const Icon(Icons.workspace_premium_outlined),
                          label: Text('premium_cta_upgrade'.tr),
                        ),
                      ] else if (canShowTrend) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 88,
                          child: _TrendSparkline(
                            points: trendScores,
                            lineColor: theme.colorScheme.primary,
                            fillColor: theme.colorScheme.primaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trendStartDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              trendEndDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trendMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (secondaryTrendLabels.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'history_trend_other_markers'.trParams({
                              'markers': secondaryTrendLabels.join(', '),
                            }),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (topBiomarkerTrends.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'history_trend_breakdown_title'.tr,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...topBiomarkerTrends.map(
                            (trend) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      _showBiomarkerTrendDetail(context, trend),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          trend.directionCode > 0
                                              ? Icons.trending_up_rounded
                                              : trend.directionCode < 0
                                              ? Icons.trending_down_rounded
                                              : Icons.trending_flat_rounded,
                                          size: 16,
                                          color: trend.directionCode > 0
                                              ? theme.colorScheme.primary
                                              : trend.directionCode < 0
                                              ? theme.colorScheme.error
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'history_trend_breakdown_item'.trParams({
                                              'marker': trend.label,
                                              'count': '${trend.sampleCount}',
                                              'direction':
                                                  trend.directionCode > 0
                                                  ? 'history_trend_direction_up'
                                                        .tr
                                                  : trend.directionCode < 0
                                                  ? 'history_trend_direction_down'
                                                        .tr
                                                  : 'history_trend_direction_flat'
                                                        .tr,
                                            }),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'history_trend_not_enough_data'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (histories.isEmpty)
                Container(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.36,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.timeline_outlined,
                          size: 28,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'history_empty_title'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'history_empty_subtitle'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...histories.map(
                  (history) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryRecordCard(
                      history: history,
                      onTap: () => _showHistoryDetail(context, history),
                      onDelete: () => _confirmDeleteHistory(context, history),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  void _showHistoryDetail(BuildContext context, LabHistoryItem history) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          bottom: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Align(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        history.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusChip(status: history.status),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(history.date, style: theme.textTheme.bodySmall),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => controller.exportHistoryToPdf(history),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text('history_export_button'.tr),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    history.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (history.signals.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'home_analysis_findings_label'.tr,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: history.signals
                        .map(
                          (signal) => Chip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            label: Text(
                              _formatSignal(signal),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.secondaryContainer,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home_analysis_recommendation_label'.tr,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        history.recommendation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'home_analysis_recommendation_sources_label'.tr,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _buildSourceLinks(context, history.sources),
                      ),
                    ],
                  ),
                ),
                if (history.nextSteps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.tertiaryContainer,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home_analysis_next_steps_label'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...history.nextSteps.map(
                          (step) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $step',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteHistory(
    BuildContext context,
    LabHistoryItem history,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          title: Text('history_delete_confirm_title'.tr),
          content: Text(
            'history_delete_confirm_message'.trParams({'title': history.title}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              child: Text('profile_cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: Text('profile_delete_button'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final isDeleted = await controller.deleteHistoryItem(history);
    if (!isDeleted || !context.mounted) return;
    Get.snackbar(
      'history_delete_success_title'.tr,
      'history_delete_success_message'.tr,
      snackStyle: SnackStyle.FLOATING,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      borderRadius: 16,
      duration: const Duration(milliseconds: 2200),
      isDismissible: true,
      shouldIconPulse: false,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      colorText: theme.colorScheme.onSurface,
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.check_rounded,
          size: 18,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      titleText: Text(
        'history_delete_success_title'.tr,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      ),
      messageText: Text(
        'history_delete_success_message'.tr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.16),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  String _formatSignal(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[_\-]+'), ' ');
    if (cleaned.isEmpty) return raw;
    return cleaned
        .split(RegExp(r'\s+'))
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  void _showBiomarkerTrendDetail(
    BuildContext context,
    BiomarkerTrendData trend,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final directionText = trend.directionCode > 0
            ? 'history_trend_direction_up'.tr
            : trend.directionCode < 0
            ? 'history_trend_direction_down'.tr
            : 'history_trend_direction_flat'.tr;

        return SafeArea(
          bottom: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Align(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'history_trend_detail_title'.trParams({
                    'marker': trend.label,
                  }),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'history_trend_detail_subtitle'.trParams({
                    'count': '${trend.sampleCount}',
                    'direction': directionText,
                  }),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 90,
                  child: _TrendSparkline(
                    points: trend.scores,
                    lineColor: theme.colorScheme.primary,
                    fillColor: theme.colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trend.points.first.dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      trend.points.last.dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'history_trend_detail_points_title'.tr,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: trend.points.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final point = entry.value;
                    final statusLabel = point.score <= 1.5
                        ? 'history_status_warning'.tr
                        : point.score >= 2.5
                        ? 'history_status_improve'.tr
                        : 'history_status_normal'.tr;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'history_trend_detail_point_item'.trParams({
                          'index': '$index',
                          'date': point.dateLabel,
                          'status': statusLabel,
                        }),
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({
    required this.history,
    required this.onTap,
    required this.onDelete,
  });

  final LabHistoryItem history;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (history.status) {
      LabHistoryStatus.warning => theme.colorScheme.error,
      LabHistoryStatus.improve => theme.colorScheme.primary,
      LabHistoryStatus.normal => theme.colorScheme.secondary,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainer,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 132,
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              history.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(status: history.status),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'profile_delete_button'.tr,
                            onPressed: onDelete,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              history.date,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        history.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendSparkline extends StatelessWidget {
  const _TrendSparkline({
    required this.points,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> points;
  final Color lineColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendSparklinePainter(
        points: points,
        lineColor: lineColor,
        fillColor: fillColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendSparklinePainter extends CustomPainter {
  const _TrendSparklinePainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> points;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const minValue = 1.0;
    const maxValue = 3.0;
    final xStep = size.width / (points.length - 1);

    final linePath = Path();
    final areaPath = Path();

    for (var i = 0; i < points.length; i++) {
      final normalized = ((points[i] - minValue) / (maxValue - minValue)).clamp(
        0.0,
        1.0,
      );
      final x = i * xStep;
      final y = size.height - (normalized * (size.height - 8)) - 4;

      if (i == 0) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor.withValues(alpha: 0.34);
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lineColor;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendSparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Obx(() {
          final isAnonymous = controller.isAnonymousUser;
          final isLinkingGoogle = controller.isLinkingGoogle.value;
          final isLinkingApple = controller.isLinkingApple.value;
          final isAnyLinking = isLinkingGoogle || isLinkingApple;
          final isDeleting = controller.isDeletingAccount.value;
          final isPremium = controller.isPremiumUser.value;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 2),
              Text(
                'profile_title_account_subscription'.tr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _ProfileSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile_subscription_status'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isPremium
                          ? 'profile_subscription_premium_plan'.tr
                          : 'profile_subscription_free_plan'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPremium
                          ? 'profile_subscription_premium_description'.tr
                          : 'profile_subscription_description'.tr,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (!isPremium) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: controller.upgradeToPremium,
                          child: Text('profile_upgrade_button'.tr),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ProfileSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile_account_sync_title'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAnonymous
                          ? 'profile_account_sync_anonymous'.tr
                          : 'profile_account_sync_connected'.trParams({
                              'name': controller.userName,
                            }),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (isAnonymous) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.34,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${'profile_guest_session_label'.tr}: ',
                                    ),
                                    TextSpan(
                                      text: controller.guestSessionTypeLabel,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (isAnonymous) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isAnyLinking
                              ? null
                              : controller.linkWithGoogle,
                          icon: const Icon(Icons.g_mobiledata),
                          label: Text(
                            isLinkingGoogle
                                ? 'profile_connecting'.tr
                                : 'profile_connect_google'.tr,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isAnyLinking
                              ? null
                              : controller.linkWithApple,
                          icon: const Icon(Icons.apple),
                          label: Text(
                            isLinkingApple
                                ? 'profile_connecting'.tr
                                : 'profile_connect_apple'.tr,
                          ),
                        ),
                      ),
                    ] else
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.verified_user_outlined),
                        title: Text(controller.userName),
                        subtitle: Text(controller.userEmail),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ProfileSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile_trial_usage'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isPremium)
                      Text(
                        'profile_trial_unlimited_message'.tr,
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      ...controller.trialUsage.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                'profile_trial_left'.trParams({
                                  'count': '${entry.value}',
                                }),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ProfileSectionCard(
                child: Column(
                  children: [
                    _ProfileActionTile(
                      icon: Icons.menu_book_outlined,
                      title: 'auth_usage_guide_title'.tr,
                      onTap: controller.openUsageGuide,
                    ),
                    const Divider(height: 1),
                    _ProfileActionTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'profile_privacy_policy'.tr,
                      onTap: controller.openPrivacyPolicy,
                    ),
                    const Divider(height: 1),
                    _ProfileActionTile(
                      icon: Icons.article_outlined,
                      title: 'Terms of Use (EULA)',
                      onTap: controller.openEULA,
                    ),
                    const Divider(height: 1),
                    _ProfileActionTile(
                      icon: Icons.language_outlined,
                      title: 'profile_language'.tr,
                      subtitle: controller.selectedLanguageLabel,
                      onTap: () => _showLanguagePicker(context),
                    ),
                  ],
                ),
              ),
              if (!isAnonymous) ...[
                const SizedBox(height: 12),
                _ProfileSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile_danger_zone'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'profile_danger_zone_description'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isDeleting
                              ? null
                              : controller.deleteAccount,
                          icon: const Icon(Icons.delete_outline),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                          label: Text(
                            isDeleting
                                ? 'profile_deleting'.tr
                                : 'profile_delete_button'.tr,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  icon: Icon(
                    isAnonymous ? Icons.logout : Icons.logout_outlined,
                  ),
                  label: Text(
                    isAnonymous
                        ? 'profile_guest_exit_button'.tr
                        : 'profile_sign_out_button'.tr,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          bottom: false,
          child: Obx(() {
            final selected = controller.selectedLanguageCode.value;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile_language'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.selectedLanguageLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageOptionTile(
                    context: context,
                    code: 'en',
                    selected: selected,
                    label: 'profile_language_english'.tr,
                  ),
                  const SizedBox(height: 8),
                  _buildLanguageOptionTile(
                    context: context,
                    code: 'id',
                    selected: selected,
                    label: 'profile_language_indonesian'.tr,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      label: Text('profile_close'.tr),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLanguageOptionTile({
    required BuildContext context,
    required String code,
    required String selected,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isSelected = selected == code;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        Navigator.of(context).pop();
        await controller.changeLanguage(code);
      },
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.34),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.language_rounded,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('selected-language'),
                        color: theme.colorScheme.primary,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        key: const ValueKey('unselected-language'),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _HomeMainContent extends StatefulWidget {
  const _HomeMainContent({required this.controller});

  final HomeController controller;

  @override
  State<_HomeMainContent> createState() => _HomeMainContentState();
}

class _HomeMainContentState extends State<_HomeMainContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _microAnimationController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);

  @override
  void dispose() {
    _microAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Material(
        color: Colors.transparent,
        child: Obx(() {
          final theme = Theme.of(context);
          final imageBytes = widget.controller.selectedLabImageBytes.value;
          final fileName = widget.controller.selectedLabImageName.value;
          final isPdf = widget.controller.isSelectedFilePdf;
          final isCompressed =
              widget.controller.isSelectedLabFileCompressed.value;
          final fileSizeLabel = widget.controller.selectedFileSizeLabel;
          final originalSizeLabel =
              widget.controller.selectedOriginalFileSizeLabel;
          final pending = widget.controller.pendingAnalysis.value;
          final isPreparingDocument =
              widget.controller.isPreparingDocument.value;
          final isAnalyzing = widget.controller.isAnalyzingLabImage.value;
          final isSaving = widget.controller.isSavingAnalysis.value;
          final isSaved = widget.controller.isCurrentAnalysisSaved.value;
          final canAnalyzeWithTrial = widget.controller.canAnalyzeWithTrial;
          final canSaveWithTrial = widget.controller.canSaveWithTrial;
          final isAiBusy = isPreparingDocument || isAnalyzing;
          final panelShape = RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _GlassPanel(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0, 0.55, 1],
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.94),
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.9),
                    theme.colorScheme.tertiaryContainer.withValues(alpha: 0.92),
                  ],
                ),
                shadowColor: theme.colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedBuilder(
                        animation: _microAnimationController,
                        builder: (context, child) {
                          final scale = isAiBusy
                              ? 1 + (_microAnimationController.value * 0.06)
                              : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: _SmartBadge(
                              icon: Icons.memory_outlined,
                              label: 'AI Engine',
                              background: theme.colorScheme.primaryContainer,
                              foreground: theme.colorScheme.onPrimaryContainer,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.health_and_safety_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'home_title'.tr,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'home_subtitle'.tr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                elevation: 2,
                color: theme.colorScheme.surfaceContainer.withValues(
                  alpha: 0.86,
                ),
                shape: panelShape,
                clipBehavior: Clip.antiAlias,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'home_start_analysis_title'.tr,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'home_start_analysis_subtitle'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FlowPill(
                              index: 1,
                              label: 'Upload',
                              color: theme.colorScheme.primary,
                            ),
                            _FlowPill(
                              index: 2,
                              label: 'Analyze',
                              color: theme.colorScheme.secondary,
                            ),
                            _FlowPill(
                              index: 3,
                              label: 'Save',
                              color: theme.colorScheme.tertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _showUploadOptionsSheet(context),
                            icon: const Icon(Icons.upload_file_outlined),
                            label: Text('home_upload_button'.tr),
                          ),
                        ),
                        if (isPreparingDocument) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'home_preparing_document'.tr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        _FadeSlideSwitcher(
                          visible: imageBytes != null,
                          child: Column(
                            key: ValueKey<String>(
                              'doc-preview-${fileName ?? 'none'}-${isPdf ? 'pdf' : 'img'}',
                            ),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),
                              Text(
                                'home_selected_document'.tr,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!isPdf && imageBytes != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    imageBytes,
                                    height: 190,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf_outlined),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          fileName ?? 'lab_result.pdf',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _MetaPill(
                                    icon: Icons.straighten_outlined,
                                    label: 'home_file_size_label'.trParams({
                                      'size': fileSizeLabel,
                                    }),
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    foregroundColor:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                  if (isCompressed)
                                    _MetaPill(
                                      icon: Icons.compress_outlined,
                                      label: 'home_file_compressed_note'
                                          .trParams({
                                            'before': originalSizeLabel,
                                            'after': fileSizeLabel,
                                          }),
                                      backgroundColor:
                                          theme.colorScheme.tertiaryContainer,
                                      foregroundColor:
                                          theme.colorScheme.onTertiaryContainer,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      (isAnalyzing ||
                                          isPreparingDocument ||
                                          !canAnalyzeWithTrial)
                                      ? null
                                      : widget
                                            .controller
                                            .analyzeSelectedLabImage,
                                  icon: const Icon(
                                    Icons.psychology_alt_outlined,
                                  ),
                                  label: Text(
                                    isPreparingDocument
                                        ? 'home_preparing_document_short'.tr
                                        : isAnalyzing
                                        ? 'home_analyzing_button'.tr
                                        : !canAnalyzeWithTrial
                                        ? 'home_analyze_trial_exhausted_button'
                                              .tr
                                        : 'home_analyze_button'.tr,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _FadeSlideSwitcher(
                visible: pending != null,
                child: Column(
                  key: ValueKey<String>(
                    'pending-analysis-${pending?.title ?? 'none'}',
                  ),
                  children: [
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 2,
                      color: theme.colorScheme.surfaceContainer.withValues(
                        alpha: 0.86,
                      ),
                      shape: panelShape,
                      clipBehavior: Clip.antiAlias,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'home_analysis_result_title'.tr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pending?.title ?? '',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  _StatusChip(
                                    status:
                                        pending?.status ??
                                        LabHistoryStatus.normal,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _AiStatusBanner(
                                status:
                                    pending?.status ?? LabHistoryStatus.normal,
                                animation: _microAnimationController,
                                active: true,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _AnimatedCountPill(
                                    icon: Icons.tune_outlined,
                                    label: 'Signals',
                                    count:
                                        (pending?.signals ?? const <String>[])
                                            .length,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  _AnimatedCountPill(
                                    icon: Icons
                                        .playlist_add_check_circle_outlined,
                                    label: 'Actions',
                                    count:
                                        (pending?.nextSteps ?? const <String>[])
                                            .length,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                child: Text(
                                  pending?.summary ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if ((pending?.signals ?? const <String>[])
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'home_analysis_findings_label'.tr,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      (pending?.signals ?? const <String>[])
                                          .map(
                                            (signal) => Chip(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .secondaryContainer,
                                              label: Text(
                                                _formatSignal(signal),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSecondaryContainer,
                                                    ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: theme.colorScheme.secondaryContainer,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'home_analysis_recommendation_label'.tr,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      pending?.recommendation ?? '',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'home_analysis_recommendation_sources_label'
                                          .tr,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: _buildSourceLinks(
                                        context,
                                        pending?.sources,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if ((pending?.nextSteps ?? const <String>[])
                                  .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: theme.colorScheme.tertiaryContainer,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'home_analysis_next_steps_label'.tr,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...(pending?.nextSteps ??
                                              const <String>[])
                                          .map(
                                            (step) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Text(
                                                '• $step',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onTertiaryContainer,
                                                    ),
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed:
                                      (isSaving || isSaved || !canSaveWithTrial)
                                      ? null
                                      : () => _onSaveAnalysisPressed(context),
                                  child: Text(
                                    isSaving
                                        ? 'home_saving_analysis_button'.tr
                                        : isSaved
                                        ? 'home_saved_analysis_button'.tr
                                        : !canSaveWithTrial
                                        ? 'home_save_trial_exhausted_button'.tr
                                        : 'home_save_analysis_button'.tr,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.55,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'home_disclaimer'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ),
    );
  }

  String _formatSignal(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[_\-]+'), ' ');
    if (cleaned.isEmpty) return raw;
    return cleaned
        .split(RegExp(r'\s+'))
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _onSaveAnalysisPressed(BuildContext context) async {
    final isSaved = await widget.controller.saveAnalyzedResult();
    if (!isSaved || !context.mounted) return;
    _showSaveSuccessSnackbar(context);
  }

  void _showSaveSuccessSnackbar(BuildContext context) {
    final theme = Theme.of(context);
    Get.snackbar(
      'home_saved_dialog_title'.tr,
      'home_saved_dialog_message'.tr,
      snackStyle: SnackStyle.FLOATING,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      borderRadius: 16,
      duration: const Duration(milliseconds: 2500),
      isDismissible: true,
      shouldIconPulse: false,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      colorText: theme.colorScheme.onSurface,
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.check_rounded,
          size: 18,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      titleText: Text(
        'home_saved_dialog_title'.tr,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      ),
      messageText: Text(
        'home_saved_dialog_message'.tr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          widget.controller.onTabChanged(1);
        },
        child: Text(
          'home_saved_dialog_open_history'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.16),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  void _showUploadOptionsSheet(BuildContext context) {
    final outerTheme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: outerTheme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    'home_upload_button'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.34,
                      ),
                    ),
                  ),
                  tileColor: theme.colorScheme.surfaceContainerHighest,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text('home_take_photo_button'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.controller.pickLabImageFromCamera();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.34,
                      ),
                    ),
                  ),
                  tileColor: theme.colorScheme.surfaceContainerHighest,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text('home_pick_gallery_button'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.controller.pickLabImageFromGallery();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.34,
                      ),
                    ),
                  ),
                  tileColor: theme.colorScheme.surfaceContainerHighest,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  title: Text('home_pick_pdf_button'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.controller.pickLabPdfDocument();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AiStatusBanner extends StatelessWidget {
  const _AiStatusBanner({
    required this.status,
    this.animation,
    this.active = false,
  });

  final LabHistoryStatus status;
  final Animation<double>? animation;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = switch (status) {
      LabHistoryStatus.warning => theme.colorScheme.error,
      LabHistoryStatus.improve => theme.colorScheme.primary,
      LabHistoryStatus.normal => theme.colorScheme.secondary,
    };

    final icon = switch (status) {
      LabHistoryStatus.warning => Icons.priority_high_outlined,
      LabHistoryStatus.improve => Icons.trending_up,
      LabHistoryStatus.normal => Icons.check_circle_outline,
    };

    final iconWidget = animation == null
        ? Icon(icon, size: 16, color: color)
        : AnimatedBuilder(
            animation: animation!,
            builder: (context, child) {
              final scale = active ? 1 + ((animation!.value) * 0.08) : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Icon(icon, size: 16, color: color),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 8),
          Text(
            'AI Generated Insight',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCountPill extends StatelessWidget {
  const _AnimatedCountPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: count.toDouble()),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Text(
                '${value.round()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FadeSlideSwitcher extends StatelessWidget {
  const _FadeSlideSwitcher({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: widget),
        );
      },
      child: visible ? child : const SizedBox.shrink(),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.borderRadius,
    required this.gradient,
    required this.shadowColor,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Gradient gradient;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: gradient,
            border: Border.all(
              color: shadowColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SmartBadge extends StatelessWidget {
  const _SmartBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [background, foreground.withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: foreground.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: foreground),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowPill extends StatelessWidget {
  const _FlowPill({
    required this.index,
    required this.label,
    required this.color,
  });

  final int index;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$index',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foregroundColor ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foregroundColor ?? theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;

        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          Get.snackbar(
            'profile_open_link_failed_title'.tr,
            'profile_open_link_failed_message'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}

List<Widget> _buildSourceLinks(
  BuildContext context,
  List<LabAnalysisSource>? sources,
) {
  const defaultSources = [
    LabAnalysisSource(label: 'WHO', url: 'https://www.who.int/'),
    LabAnalysisSource(label: 'CDC', url: 'https://www.cdc.gov/'),
  ];

  final effectiveSources = (sources != null && sources.isNotEmpty)
      ? sources
      : defaultSources;

  return effectiveSources
      .map((source) => _SourceLink(label: source.label, url: source.url))
      .toList();
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LabHistoryStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    late final String label;
    late final Color color;
    switch (status) {
      case LabHistoryStatus.warning:
        label = 'history_status_warning'.tr;
        color = theme.colorScheme.error;
        break;
      case LabHistoryStatus.improve:
        label = 'history_status_improve'.tr;
        color = theme.colorScheme.primary;
        break;
      case LabHistoryStatus.normal:
        label = 'history_status_normal'.tr;
        color = theme.colorScheme.secondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _androidNavIcons = <IconData>[
    Icons.home_outlined,
    Icons.history_outlined,
    Icons.person_outline,
  ];

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
          // appBar: AdaptiveAppBar(title: title),
          bottomNavigationBar: AdaptiveBottomNavigationBar(
            selectedIndex: currentIndex,
            onTap: controller.onTabChanged,
            items: [
              AdaptiveNavigationDestination(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'nav_home'.tr,
              ),
              AdaptiveNavigationDestination(
                icon: Icons.history_outlined,
                selectedIcon: Icons.history,
                label: 'nav_history'.tr,
              ),
              AdaptiveNavigationDestination(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
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
        bottomNavigationBar: AnimatedBottomNavigationBar(
          icons: _androidNavIcons,
          activeIndex: currentIndex,
          onTap: controller.onTabChanged,
          gapLocation: GapLocation.end,
          backgroundColor: theme.colorScheme.surface,
          activeColor: theme.colorScheme.primary,
          inactiveColor: theme.colorScheme.onSurfaceVariant,
          splashColor: theme.colorScheme.primaryContainer,
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
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
                        child: Icon(
                          Icons.history_edu_outlined,
                          color: theme.colorScheme.primary,
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
                              ),
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
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (histories.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'history_empty_title'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'history_empty_subtitle'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...histories.map(
                  (history) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryRecordCard(
                      history: history,
                      onTap: () => controller.openHistoryDetail(history),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({required this.history, required this.onTap});

  final LabHistoryItem history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      history.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: history.status),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(history.date, style: theme.textTheme.bodySmall),
              ),
              const SizedBox(height: 8),
              Text(
                history.note,
                style: theme.textTheme.bodyMedium?.copyWith(
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
                      'profile_subscription_free_plan'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'profile_subscription_description'.tr,
                      style: theme.textTheme.bodyMedium,
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
                      icon: Icons.privacy_tip_outlined,
                      title: 'profile_privacy_policy'.tr,
                      onTap: controller.openPrivacyPolicy,
                    ),
                    const Divider(height: 1),
                    _ProfileActionTile(
                      icon: Icons.article_outlined,
                      title: 'profile_terms_conditions'.tr,
                      onTap: controller.openTermsAndConditions,
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
                        onPressed: isDeleting ? null : controller.deleteAccount,
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
              const SizedBox(height: 12),
              _ProfileSectionCard(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.upgradeToPremium,
                        child: Text('profile_upgrade_button'.tr),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: controller.restorePurchases,
                        child: Text('profile_restore_button'.tr),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: controller.signOut,
                        child: Text('profile_sign_out_button'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Obx(() {
            final selected = controller.selectedLanguageCode.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text('profile_language_english'.tr),
                  trailing: selected == 'en' ? const Icon(Icons.check) : null,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await controller.changeLanguage('en');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text('profile_language_indonesian'.tr),
                  trailing: selected == 'id' ? const Icon(Icons.check) : null,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await controller.changeLanguage('id');
                  },
                ),
                ListTile(
                  title: Text('profile_close'.tr, textAlign: TextAlign.center),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            );
          }),
        );
      },
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

class _HomeMainContent extends StatelessWidget {
  const _HomeMainContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Obx(() {
          final theme = Theme.of(context);
          final imageBytes = controller.selectedLabImageBytes.value;
          final fileName = controller.selectedLabImageName.value;
          final isPdf = controller.isSelectedFilePdf;
          final isCompressed = controller.isSelectedLabFileCompressed.value;
          final fileSizeLabel = controller.selectedFileSizeLabel;
          final originalSizeLabel = controller.selectedOriginalFileSizeLabel;
          final pending = controller.pendingAnalysis.value;
          final isPreparingDocument = controller.isPreparingDocument.value;
          final isAnalyzing = controller.isAnalyzingLabImage.value;
          final isSaving = controller.isSavingAnalysis.value;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'home_title'.tr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('home_subtitle'.tr, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home_start_analysis_title'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'home_start_analysis_subtitle'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: controller.pickLabImageFromCamera,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text('home_take_photo_button'.tr),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: controller.pickLabImageFromGallery,
                              icon: const Icon(Icons.upload_file_outlined),
                              label: Text('home_pick_gallery_button'.tr),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.pickLabPdfDocument,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text('home_pick_pdf_button'.tr),
                        ),
                      ),
                      if (isPreparingDocument) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                      if (imageBytes != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          'home_selected_document'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!isPdf)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              imageBytes,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.colorScheme.surfaceContainerHighest,
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
                        Row(
                          children: [
                            Icon(
                              Icons.straighten_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'home_file_size_label'.trParams({
                                'size': fileSizeLabel,
                              }),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (isCompressed) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.compress_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'home_file_compressed_note'.trParams({
                                    'before': originalSizeLabel,
                                    'after': fileSizeLabel,
                                  }),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: (isAnalyzing || isPreparingDocument)
                                ? null
                                : controller.analyzeSelectedLabImage,
                            icon: const Icon(Icons.psychology_alt_outlined),
                            label: Text(
                              isPreparingDocument
                                  ? 'home_preparing_document_short'.tr
                                  : isAnalyzing
                                  ? 'home_analyzing_button'.tr
                                  : 'home_analyze_button'.tr,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (pending != null) ...[
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
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
                                pending.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _StatusChip(status: pending.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pending.summary,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (pending.signals.isNotEmpty) ...[
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
                            children: pending.signals
                                .map(
                                  (signal) => Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      _formatSignal(signal),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'home_analysis_recommendation_label'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pending.recommendation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (pending.nextSteps.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'home_analysis_next_steps_label'.tr,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...pending.nextSteps.map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $step',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : controller.saveAnalyzedResult,
                            child: Text(
                              isSaving
                                  ? 'home_saving_analysis_button'.tr
                                  : 'home_save_analysis_button'.tr,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  'home_disclaimer'.tr,
                  style: theme.textTheme.bodySmall,
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

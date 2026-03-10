import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

enum InfoDetailType { about, support, marketing }

class InfoDetailView extends GetView<HomeController> {
  const InfoDetailView({super.key, required this.type});

  final InfoDetailType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _InfoDetailContent.fromType(type, controller);

    return Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _InfoHeroCard(content: content),
          const SizedBox(height: 18),
          Text(
            'info_section_highlights'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...content.highlights.map(
            (highlight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InfoHighlightCard(highlight: highlight),
            ),
          ),
          if (content.note != null) ...[
            const SizedBox(height: 6),
            Text(
              'info_section_additional'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _InfoNoteCard(note: content.note!),
          ],
          if (content.ctaLabel != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: content.onCtaTap,
                icon: Icon(content.ctaIcon ?? Icons.support_agent_outlined),
                label: Text(content.ctaLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoHeroCard extends StatelessWidget {
  const _InfoHeroCard({required this.content});

  final _InfoDetailContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                content.heroIcon,
                color: theme.colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content.subtitle,
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

class _InfoHighlightCard extends StatelessWidget {
  const _InfoHighlightCard({required this.highlight});

  final _InfoHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                highlight.icon,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    highlight.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    highlight.description,
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

class _InfoNoteCard extends StatelessWidget {
  const _InfoNoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                note,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoDetailContent {
  const _InfoDetailContent({
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    required this.highlights,
    this.note,
    this.ctaLabel,
    this.ctaIcon,
    this.onCtaTap,
  });

  final String title;
  final String subtitle;
  final IconData heroIcon;
  final List<_InfoHighlight> highlights;
  final String? note;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCtaTap;

  static _InfoDetailContent fromType(
    InfoDetailType type,
    HomeController controller,
  ) {
    switch (type) {
      case InfoDetailType.support:
        return _InfoDetailContent(
          title: 'info_support_title'.tr,
          subtitle: 'info_support_subtitle'.tr,
          heroIcon: Icons.support_agent_outlined,
          highlights: [
            _InfoHighlight(
              icon: Icons.mail_outline,
              title: 'info_support_point_1_title'.tr,
              description: 'info_support_point_1_desc'.tr,
            ),
            _InfoHighlight(
              icon: Icons.schedule_outlined,
              title: 'info_support_point_2_title'.tr,
              description: 'info_support_point_2_desc'.tr,
            ),
            _InfoHighlight(
              icon: Icons.verified_user_outlined,
              title: 'info_support_point_3_title'.tr,
              description: 'info_support_point_3_desc'.tr,
            ),
          ],
          ctaLabel: 'info_support_cta'.tr,
          ctaIcon: Icons.outgoing_mail,
          onCtaTap: () => controller.contactSupport(
            subject: 'info_support_email_subject'.tr,
          ),
        );
      case InfoDetailType.marketing:
        return _InfoDetailContent(
          title: 'info_marketing_title'.tr,
          subtitle: 'info_marketing_subtitle'.tr,
          heroIcon: Icons.campaign_outlined,
          highlights: [
            _InfoHighlight(
              icon: Icons.chat_bubble_outline,
              title: 'info_marketing_point_1_title'.tr,
              description: 'info_marketing_point_1_desc'.tr,
            ),
            _InfoHighlight(
              icon: Icons.palette_outlined,
              title: 'info_marketing_point_2_title'.tr,
              description: 'info_marketing_point_2_desc'.tr,
            ),
            _InfoHighlight(
              icon: Icons.health_and_safety_outlined,
              title: 'info_marketing_point_3_title'.tr,
              description: 'info_marketing_point_3_desc'.tr,
            ),
          ],
          note: 'info_marketing_note'.tr,
          ctaLabel: 'info_marketing_cta'.tr,
          ctaIcon: Icons.attach_email_outlined,
          onCtaTap: () => controller.contactSupport(
            subject: 'info_marketing_email_subject'.tr,
          ),
        );
      case InfoDetailType.about:
        return _InfoDetailContent(
          title: 'info_about_title'.tr,
          subtitle: 'info_about_subtitle'.tr,
          heroIcon: Icons.bolt_outlined,
          highlights: [
            _InfoHighlight(
              icon: Icons.document_scanner_outlined,
              title: 'info_about_point_1_title'.tr,
              description: 'info_about_point_1_desc'.tr,
            ),
            _InfoHighlight(
              icon: Icons.show_chart_outlined,
              title: 'info_about_point_2_title'.tr,
              description: 'info_about_point_2_desc'.tr,
            ),
            _InfoHighlight(
              icon: Icons.lock_outlined,
              title: 'info_about_point_3_title'.tr,
              description: 'info_about_point_3_desc'.tr,
            ),
          ],
        );
    }
  }
}

class _InfoHighlight {
  const _InfoHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

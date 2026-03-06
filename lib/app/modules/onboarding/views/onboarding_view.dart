import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageDecoration = PageDecoration(
      titleTextStyle:
          theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ) ??
          const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      bodyTextStyle: theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16),
      titlePadding: const EdgeInsets.only(top: 8, bottom: 12),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 8),
      contentMargin: const EdgeInsets.symmetric(horizontal: 20),
      imagePadding: const EdgeInsets.only(top: 24),
      pageColor: theme.scaffoldBackgroundColor,
    );

    return IntroductionScreen(
      globalBackgroundColor: theme.scaffoldBackgroundColor,
      showSkipButton: true,
      skip: Text('onboarding_skip'.tr),
      next: const Icon(Icons.arrow_forward),
      done: Text('onboarding_done'.tr),
      onSkip: controller.goToHomePreview,
      onDone: controller.goToHome,
      dotsDecorator: DotsDecorator(
        size: const Size.square(8),
        activeSize: const Size(24, 8),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: theme.colorScheme.outlineVariant,
        activeColor: theme.colorScheme.primary,
      ),
      pages: [
        PageViewModel(
          title: 'onboarding_welcome_title'.tr,
          body: 'onboarding_welcome_body'.tr,
          image: _OnboardingIcon(
            icon: Icons.health_and_safety_outlined,
            color: theme.colorScheme.primary,
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: 'onboarding_features_title'.tr,
          bodyWidget: _FeatureChecklist(theme: theme),
          image: _OnboardingIcon(
            icon: Icons.auto_awesome_outlined,
            color: theme.colorScheme.primary,
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: 'onboarding_privacy_title'.tr,
          bodyWidget: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Text(
              'onboarding_privacy_body'.tr,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          image: _OnboardingIcon(
            icon: Icons.lock_outline,
            color: theme.colorScheme.primary,
          ),
          decoration: pageDecoration,
        ),
      ],
    );
  }
}

class _OnboardingIcon extends StatelessWidget {
  const _OnboardingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 96, color: color);
  }
}

class _FeatureChecklist extends StatelessWidget {
  const _FeatureChecklist({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeatureItem(
          icon: Icons.document_scanner_outlined,
          text: 'onboarding_feature_1'.tr,
        ),
        _FeatureItem(
          icon: Icons.quiz_outlined,
          text: 'onboarding_feature_2'.tr,
        ),
        _FeatureItem(
          icon: Icons.show_chart_outlined,
          text: 'onboarding_feature_3'.tr,
        ),
        _FeatureItem(icon: Icons.spa_outlined, text: 'onboarding_feature_4'.tr),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

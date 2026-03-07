import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pageController;
  int _currentIndex = 0;

  OnboardingController get _controller => Get.find<OnboardingController>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _onNextPressed() async {
    if (_currentIndex >= _slides.length - 1) {
      await _controller.goToHome();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onPreviousPressed() async {
    if (_currentIndex <= 0) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstPage = _currentIndex == 0;
    final isLastPage = _currentIndex == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _OnboardingBackgroundSlide(
                imagePath: slide.imagePath,
                title: slide.title.tr,
                body: slide.bodyBuilder(context),
                bottomContentPadding: index == 1 ? 116 : 92,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                  ),
                  child: TextButton(
                    onPressed: _controller.goToHomePreview,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'onboarding_skip'.tr,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.32),
                    ),
                  ),
                  child: _TopDotsIndicator(
                    activeIndex: _currentIndex,
                    count: _slides.length,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 18,
            child: isFirstPage
                ? SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _onNextPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('onboarding_next'.tr),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onPreviousPressed,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainer,
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            foregroundColor: theme.colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('onboarding_previous'.tr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _onNextPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isLastPage
                                ? 'onboarding_done'.tr
                                : 'onboarding_next'.tr,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<_OnboardingSlideData> get _slides => [
    _OnboardingSlideData(
      imagePath: 'assets/images/img-onboarding-1.png',
      title: 'onboarding_welcome_title',
      bodyBuilder: (context) {
        final theme = Theme.of(context);
        return Text(
          'onboarding_welcome_body'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        );
      },
    ),
    _OnboardingSlideData(
      imagePath: 'assets/images/img-onboarding-2.png',
      title: 'onboarding_features_title',
      bodyBuilder: (_) => const _OverlayFeatureChecklist(),
    ),
    _OnboardingSlideData(
      imagePath: 'assets/images/img-onboarding-3.png',
      title: 'onboarding_privacy_title',
      bodyBuilder: (context) {
        final theme = Theme.of(context);
        return Text(
          'onboarding_privacy_body'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        );
      },
    ),
  ];
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.imagePath,
    required this.title,
    required this.bodyBuilder,
  });

  final String imagePath;
  final String title;
  final Widget Function(BuildContext context) bodyBuilder;
}

class _OnboardingBackgroundSlide extends StatelessWidget {
  const _OnboardingBackgroundSlide({
    required this.imagePath,
    required this.title,
    required this.body,
    required this.bottomContentPadding,
  });

  final String imagePath;
  final String title;
  final Widget body;
  final double bottomContentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.colorScheme.surfaceContainer,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 42,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomContentPadding),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.zero,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: SingleChildScrollView(child: body)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverlayFeatureChecklist extends StatelessWidget {
  const _OverlayFeatureChecklist();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OverlayFeatureItem(
          icon: Icons.document_scanner_outlined,
          text: 'onboarding_feature_1'.tr,
          iconBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
          iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        _OverlayFeatureItem(
          icon: Icons.quiz_outlined,
          text: 'onboarding_feature_2'.tr,
          iconBackgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          iconColor: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        _OverlayFeatureItem(
          icon: Icons.show_chart_outlined,
          text: 'onboarding_feature_3'.tr,
          iconBackgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          iconColor: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
        _OverlayFeatureItem(
          icon: Icons.spa_outlined,
          text: 'onboarding_feature_4'.tr,
          isLast: true,
          iconBackgroundColor: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.78),
          iconColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

class _OverlayFeatureItem extends StatelessWidget {
  const _OverlayFeatureItem({
    required this.icon,
    required this.text,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.isLast = false,
  });

  final IconData icon;
  final String text;
  final Color iconBackgroundColor;
  final Color iconColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopDotsIndicator extends StatelessWidget {
  const _TopDotsIndicator({required this.activeIndex, required this.count});

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(right: index == count - 1 ? 0 : 6),
          width: isActive ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

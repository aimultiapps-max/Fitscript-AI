import 'dart:math' as math;

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
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

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
                // Give the features screen extra bottom padding so the list
                // never gets hidden behind the navigation buttons.
                bottomContentPadding: MediaQuery.of(context).padding.bottom,
                activeIndex: _currentIndex,
                slideCount: _slides.length,
                isTablet: isTablet,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Obx(() {
              final selectedLanguage = _controller.selectedLanguageCode.value;
              return Row(
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
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'profile_language'.tr,
                    onSelected: (value) {
                      _controller.changeLanguage(value);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'en',
                        child: Row(
                          children: [
                            const Icon(Icons.language),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('profile_language_english'.tr),
                            ),
                            if (selectedLanguage == 'en')
                              Icon(
                                Icons.check,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'id',
                        child: Row(
                          children: [
                            const Icon(Icons.language),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('profile_language_indonesian'.tr),
                            ),
                            if (selectedLanguage == 'id')
                              Icon(
                                Icons.check,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
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
                      child: Icon(
                        Icons.language,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          Positioned(
            left: isTablet ? null : 16,
            right: isTablet ? null : 16,
            bottom: MediaQuery.of(context).padding.bottom,
            child: isTablet
                ? Center(
                    child: SizedBox(
                      width: 600,
                      child: isFirstPage
                          ? SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _onNextPressed,
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                                      backgroundColor:
                                          theme.colorScheme.surfaceContainer,
                                      side: BorderSide(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                      foregroundColor:
                                          theme.colorScheme.onSurface,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: Text('onboarding_previous'.tr),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _onNextPressed,
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
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
                  )
                : isFirstPage
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
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        );
      },
    ),
    _OnboardingSlideData(
      imagePath: 'assets/images/img-onboarding-2.png',
      title: 'onboarding_features_title',
      bodyBuilder: (context) {
        final theme = Theme.of(context);
        return Text(
          'onboarding_features_body'.tr,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        );
      },
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
            height: 1.4,
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
    required this.activeIndex,
    required this.slideCount,
    required this.isTablet,
  });

  final String imagePath;
  final String title;
  final Widget body;
  final double bottomContentPadding;
  final int activeIndex;
  final int slideCount;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Allow the slide to scroll when vertical space is tight (e.g., iPad
        // split-screen, large font sizes, or small devices).
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                SizedBox(
                  height: constraints.maxHeight * (isTablet ? 0.42 : 0.6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imagePath,
                        fit: isTablet ? BoxFit.contain : BoxFit.cover,
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
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: Container(
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
                            activeIndex: activeIndex,
                            count: slideCount,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: constraints.maxHeight * (isTablet ? 0.58 : 0.4),
                  child: Center(
                    child: Container(
                      width: isTablet
                          ? math.min(constraints.maxWidth * 0.9, 600)
                          : double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        bottomContentPadding,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: isTablet
                            ? BorderRadius.circular(16)
                            : BorderRadius.zero,
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(
                              alpha: 0.08,
                            ),
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
                ),
              ],
            ),
          ),
        );
      },
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

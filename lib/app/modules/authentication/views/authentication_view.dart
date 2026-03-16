import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/authentication_controller.dart';

class AuthenticationView extends GetView<AuthenticationController> {
  const AuthenticationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdaptiveScaffold(
      body: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/img-auth-backaground.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.medium,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.24),
                    Colors.black.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Obx(() {
                final isGoogleLoading = controller.isConnectingGoogle.value;
                final isAppleLoading = controller.isConnectingApple.value;
                final isGuestLoading = controller.isContinuingGuest.value;
                final isBusy = controller.isBusy;
                final selectedLanguage = controller.selectedLanguageCode.value;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: 12,
                      right: 12,
                      child: PopupMenuButton<String>(
                        tooltip: 'profile_language'.tr,
                        onSelected: (value) {
                          controller.changeLanguage(value);
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
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                controller.selectedLanguageLabel,
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.92,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 48,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'auth_title'.tr,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'auth_subtitle'.tr,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : controller.connectWithGoogle,
                                  icon: const Icon(Icons.g_mobiledata),
                                  label: Text(
                                    isGoogleLoading
                                        ? 'profile_connecting'.tr
                                        : 'profile_connect_google'.tr,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : controller.connectWithApple,
                                  icon: const Icon(Icons.apple),
                                  label: Text(
                                    isAppleLoading
                                        ? 'profile_connecting'.tr
                                        : 'profile_connect_apple'.tr,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: isBusy
                                      ? null
                                      : controller.confirmContinueAsGuest,
                                  child: Text(
                                    isGuestLoading
                                        ? 'profile_connecting'.tr
                                        : 'auth_continue_as_guest'.tr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 8,
                      child: Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.35,
                          ),
                          children: [
                            TextSpan(text: 'auth_acknowledgement_prefix'.tr),
                            TextSpan(
                              text: 'auth_usage_guide_title'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = controller.openUsageGuide,
                            ),
                            const TextSpan(text: ', '),
                            TextSpan(
                              text: 'legal_privacy_title'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = controller.openPrivacyPolicy,
                            ),
                            const TextSpan(text: ', '),
                            TextSpan(
                              text: 'Terms of Use (EULA)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = controller.openEULA,
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

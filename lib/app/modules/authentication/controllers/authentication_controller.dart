import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/account_auth_service.dart';
import '../../home/views/legal_document_view.dart';
import '../../../routes/app_pages.dart';

class AuthenticationController extends GetxController {
  AuthenticationController({AccountAuthService? accountAuthService})
    : _accountAuthService = accountAuthService ?? AccountAuthService();

  static const String _skipGuestConfirmKey =
      'auth_skip_guest_confirmation_dialog';
  static const String _localGuestModeKey = 'local_guest_mode';

  final AccountAuthService _accountAuthService;

  final isConnectingGoogle = false.obs;
  final isConnectingApple = false.obs;
  final isContinuingGuest = false.obs;
  final selectedLanguageCode = 'en'.obs;

  String get selectedLanguageLabel => selectedLanguageCode.value == 'id'
      ? 'profile_language_indonesian'.tr
      : 'profile_language_english'.tr;

  @override
  void onInit() {
    super.onInit();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language_code') ?? 'en';
    selectedLanguageCode.value = code == 'id' ? 'id' : 'en';
  }

  Future<void> changeLanguage(String code) async {
    final normalized = code == 'id' ? 'id' : 'en';
    if (selectedLanguageCode.value == normalized) return;

    selectedLanguageCode.value = normalized;
    final locale = normalized == 'id'
        ? const Locale('id', 'ID')
        : const Locale('en', 'US');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', normalized);
    Get.updateLocale(locale);
  }

  void openUsageGuide() {
    final isIndonesian = selectedLanguageCode.value == 'id';
    Get.to<void>(
      () => LegalDocumentView(
        title: 'auth_usage_guide_title'.tr,
        assetPath: isIndonesian
            ? 'assets/jsons/usage_guide_fitscript_ai.md'
            : 'assets/jsons/usage_guide_fitscript_ai_en.md',
      ),
    );
  }

  void openPrivacyPolicy() {
    final isIndonesian = selectedLanguageCode.value == 'id';
    Get.to<void>(
      () => LegalDocumentView(
        title: 'legal_privacy_title'.tr,
        assetPath: isIndonesian
            ? 'assets/jsons/privacy_policy_fitscript_ai_id.md'
            : 'assets/jsons/privacy_policy_fitscript_ai.md',
      ),
    );
  }

  void openEULA() {
    final isIndonesian = selectedLanguageCode.value == 'id';
    Get.to<void>(
      () => LegalDocumentView(
        title: 'Terms of Use (EULA)',
        assetPath: isIndonesian
            ? 'assets/jsons/terms_and_conditions_fitscript_ai_id.md'
            : 'assets/jsons/terms_and_conditions_fitscript_ai.md',
      ),
    );
  }

  bool get isBusy =>
      isConnectingGoogle.value ||
      isConnectingApple.value ||
      isContinuingGuest.value;

  Future<void> confirmContinueAsGuest() async {
    if (isBusy) return;

    final prefs = await SharedPreferences.getInstance();
    final skipConfirm = prefs.getBool(_skipGuestConfirmKey) ?? false;
    if (skipConfirm) {
      await continueAsGuest();
      return;
    }

    final theme = Get.theme;
    var dontShowAgain = false;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        title: Text('auth_guest_confirm_title'.tr),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('auth_guest_confirm_message'.tr),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: dontShowAgain,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() => dontShowAgain = value ?? false);
                  },
                  title: Text(
                    'auth_guest_dont_show_again'.tr,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text('profile_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('auth_continue_as_guest'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed == true) {
      await prefs.setBool(_skipGuestConfirmKey, dontShowAgain);
      await continueAsGuest();
    }
  }

  Future<void> continueAsGuest() async {
    if (isBusy) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localGuestModeKey, true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      Get.offAllNamed(Routes.HOME);
      return;
    }

    if (currentUser == null) {
      Get.offAllNamed(Routes.HOME);
      return;
    }

    isContinuingGuest.value = true;
    try {
      await FirebaseAuth.instance.signInAnonymously();
      Get.offAllNamed(Routes.HOME);
    } on FirebaseAuthException catch (error) {
      _showAuthError(error);
    } catch (_) {
      _showSnackbar(
        'auth_sign_in_failed_title'.tr,
        'profile_auth_error_generic'.tr,
      );
    } finally {
      isContinuingGuest.value = false;
    }
  }

  Future<void> connectWithGoogle() async {
    if (isBusy) return;

    isConnectingGoogle.value = true;
    try {
      final result = await _accountAuthService.connectWithGoogle();
      if (result.status == LinkAccountStatus.cancelled) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_localGuestModeKey, false);
      Get.offAllNamed(Routes.HOME);
    } on FirebaseAuthException catch (error) {
      _showAuthError(error);
    } catch (_) {
      _showSnackbar(
        'profile_link_google_failed_title'.tr,
        'profile_link_google_failed_message'.tr,
      );
    } finally {
      isConnectingGoogle.value = false;
    }
  }

  Future<void> connectWithApple() async {
    if (isBusy) return;

    isConnectingApple.value = true;
    try {
      final result = await _accountAuthService.connectWithApple();
      if (result.status == LinkAccountStatus.cancelled) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_localGuestModeKey, false);
      Get.offAllNamed(Routes.HOME);
    } on FirebaseAuthException catch (error) {
      _showAuthError(error, includeErrorCode: true);
    } catch (_) {
      _showSnackbar(
        'profile_link_apple_failed_title'.tr,
        'profile_link_apple_failed_message'.tr,
      );
    } finally {
      isConnectingApple.value = false;
    }
  }

  void _showAuthError(
    FirebaseAuthException error, {
    bool includeErrorCode = false,
  }) {
    final message = switch (error.code) {
      'account-exists-with-different-credential' =>
        'profile_auth_error_different_credential'.tr,
      'invalid-credential' => 'profile_auth_error_invalid_credential'.tr,
      'operation-not-allowed' => 'profile_auth_error_apple_setup'.tr,
      'apple_not_available' => 'profile_auth_error_apple_not_available'.tr,
      'missing-or-invalid-nonce' => 'profile_auth_error_apple_setup'.tr,
      'malformed-or-expired-credential' =>
        'profile_auth_error_invalid_credential'.tr,
      'apple_missing_identity_token' => 'profile_auth_error_apple_setup'.tr,
      'apple_invalid_response' ||
      'apple_not_handled' ||
      'apple_not_interactive' ||
      'apple_failed' ||
      'apple_unknown' => 'profile_auth_error_apple_invalid'.tr,
      _ => 'profile_auth_error_generic'.tr,
    };

    final displayMessage = includeErrorCode
        ? '$message (${error.code})'
        : message;

    _showSnackbar('auth_sign_in_failed_title'.tr, displayMessage);
  }

  void _showSnackbar(String title, String message) {
    final theme = Get.theme;
    Get.snackbar(
      title,
      message,
      snackStyle: SnackStyle.FLOATING,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      borderRadius: 16,
      duration: const Duration(milliseconds: 2600),
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
          Icons.error_outline,
          size: 18,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

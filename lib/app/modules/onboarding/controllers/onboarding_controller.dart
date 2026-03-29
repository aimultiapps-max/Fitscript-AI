import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk_platform_interface.dart'
    show EventName;

import '../../../core/services/tiktok_business_service.dart';
import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  static const _onboardingCompletedKey = 'onboarding_completed';
  final selectedLanguageCode = 'en'.obs;

  String get selectedLanguageLabel => selectedLanguageCode.value == 'id'
      ? 'profile_language_indonesian'.tr
      : 'profile_language_english'.tr;

  @override
  void onInit() {
    super.onInit();
    _loadLanguagePreference();
  }

  @override
  void onReady() {
    super.onReady();
    _redirectIfAlreadyCompleted();
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

  Future<void> _redirectIfAlreadyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
    final localGuestMode = prefs.getBool('local_guest_mode') ?? false;
    if (!isCompleted) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    final route = (currentUser == null && !localGuestMode)
        ? Routes.AUTH
        : Routes.HOME;
    if (Get.currentRoute == route) return;
    Get.offAllNamed(route);
  }

  Future<void> _markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  Future<void> goToHome() async {
    await _markOnboardingCompleted();

    try {
      final tiktokService = Get.find<TikTokBusinessService>();
      await tiktokService.trackEvent(eventName: EventName.CompleteTutorial);
    } catch (error) {
      debugPrint('TikTok CompleteTutorial tracking failed: $error');
    }

    final prefs = await SharedPreferences.getInstance();
    final localGuestMode = prefs.getBool('local_guest_mode') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;
    Get.offAllNamed(
      (currentUser == null && !localGuestMode) ? Routes.AUTH : Routes.HOME,
    );
  }

  Future<void> goToHomePreview() async {
    await _markOnboardingCompleted();

    try {
      final tiktokService = Get.find<TikTokBusinessService>();
      await tiktokService.trackEvent(eventName: EventName.CompleteTutorial);
    } catch (error) {
      debugPrint('TikTok CompleteTutorial tracking failed: $error');
    }

    final prefs = await SharedPreferences.getInstance();
    final localGuestMode = prefs.getBool('local_guest_mode') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;
    Get.offAllNamed(
      (currentUser == null && !localGuestMode) ? Routes.AUTH : Routes.HOME,
    );
  }
}

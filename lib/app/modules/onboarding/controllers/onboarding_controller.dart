import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  static const _onboardingCompletedKey = 'onboarding_completed';

  @override
  void onReady() {
    super.onReady();
    _redirectIfAlreadyCompleted();
  }

  Future<void> _redirectIfAlreadyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
    if (!isCompleted) return;
    if (Get.currentRoute == Routes.HOME) return;
    Get.offAllNamed(Routes.HOME);
  }

  Future<void> _markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  Future<void> goToHome() async {
    await _markOnboardingCompleted();
    Get.offAllNamed(Routes.HOME);
  }

  Future<void> goToHomePreview() async {
    await _markOnboardingCompleted();
    Get.offAllNamed(Routes.HOME);
  }
}

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  static const _onboardingCompletedKey = 'onboarding_completed';

  Future<void> goToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    Get.offAllNamed(Routes.HOME);
  }

  void goToHomePreview() => Get.toNamed(Routes.HOME);
}

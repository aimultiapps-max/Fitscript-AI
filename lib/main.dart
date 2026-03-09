import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:fitscript_ai/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:get/get.dart';

import 'app/core/themes/app_theme.dart';
import 'app/core/translations/app_translations.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _activateFirebaseAppCheck();
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final localGuestMode = prefs.getBool('local_guest_mode') ?? false;
  final languageCode = prefs.getString('app_language_code') ?? 'en';
  final initialLocale = languageCode == 'id'
      ? const Locale('id', 'ID')
      : const Locale('en', 'US');

  final currentUser = FirebaseAuth.instance.currentUser;
  final initialRoute = !onboardingCompleted
      ? Routes.ONBOARDING
      : ((currentUser == null && !localGuestMode) ? Routes.AUTH : Routes.HOME);

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "FitScript AI",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    ),
  );
}

Future<void> _activateFirebaseAppCheck() async {
  const appCheckDebug = bool.fromEnvironment('APP_CHECK_DEBUG');
  final useDebugProvider = kDebugMode || appCheckDebug;

  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: useDebugProvider
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: useDebugProvider
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    if (useDebugProvider && kDebugMode) {
      final debugToken = await FirebaseAppCheck.instance.getToken(true);
      debugPrint('Firebase App Check debug token: $debugToken');
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Firebase App Check activation failed: $error');
    }
  }
}

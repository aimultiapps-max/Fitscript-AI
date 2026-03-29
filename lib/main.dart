import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:fitscript_ai/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:get/get.dart';

import 'app/core/themes/app_theme.dart';
import 'app/core/services/app_update_service.dart';
import 'app/core/services/tiktok_business_service.dart';
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
  final themeModeString = prefs.getString('app_theme_mode') ?? 'system';
  final initialThemeMode = switch (themeModeString) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  final initialLocale = languageCode == 'id'
      ? const Locale('id', 'ID')
      : const Locale('en', 'US');

  final currentUser = FirebaseAuth.instance.currentUser;
  final initialRoute = !onboardingCompleted
      ? Routes.ONBOARDING
      : ((currentUser == null && !localGuestMode) ? Routes.AUTH : Routes.HOME);

  final appUpdateService = Get.put(AppUpdateService(), permanent: true);
  final tiktokBusinessService = Get.put(
    TikTokBusinessService(),
    permanent: true,
  );

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 8),
      minimumFetchInterval: const Duration(minutes: 15),
    ),
  );

  await remoteConfig.setDefaults({
    'tiktok_access_token': 'TTr1s3gRZk9ZvQLzgYxkrwBG5HbydJc8',
    'tiktok_app_id': '6760217641',
    'tiktok_tt_app_id': '7622726290068078600',
  });

  try {
    await remoteConfig.fetchAndActivate();
  } catch (error) {
    debugPrint('Firebase Remote Config fetch failed: $error');
  }

  final tiktokAccessToken = remoteConfig.getString('tiktok_access_token');
  final tiktokAppId = remoteConfig.getString('tiktok_app_id');
  final tiktokTtAppId = remoteConfig.getString('tiktok_tt_app_id');

  if (tiktokAccessToken.isNotEmpty &&
      tiktokAppId.isNotEmpty &&
      tiktokTtAppId.isNotEmpty) {
    try {
      await tiktokBusinessService.init(
        accessToken: tiktokAccessToken,
        appId: tiktokAppId,
        ttAppId: tiktokTtAppId,
        openDebug: kDebugMode,
        enableAutoIapTrack: true,
        disableAutoEnhancedDataPostbackEvents: false,
      );
      debugPrint('TikTokBusinessSDK initialized successfully');
    } catch (error) {
      debugPrint('TikTokBusinessSDK init failed: $error');
    }
  } else {
    debugPrint(
      'TikTokBusinessSDK skipped init because Remote Config keys are missing',
    );
  }

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "FitScript AI",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: initialThemeMode,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    appUpdateService.checkForUpdateIfNeeded();
  });
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

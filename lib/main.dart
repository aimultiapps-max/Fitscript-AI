import 'package:firebase_core/firebase_core.dart';
import 'package:fitscript_ai/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:get/get.dart';

import 'app/core/themes/app_theme.dart';
import 'app/core/translations/app_translations.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final languageCode = prefs.getString('app_language_code') ?? 'en';
  final initialLocale = languageCode == 'id'
      ? const Locale('id', 'ID')
      : const Locale('en', 'US');

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

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
      initialRoute: onboardingCompleted ? Routes.HOME : Routes.ONBOARDING,
      getPages: AppPages.routes,
    ),
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppStoreVersionInfo {
  const AppStoreVersionInfo({
    required this.version,
    required this.appStoreUrl,
    this.releaseNotes,
    this.trackName,
  });

  final String version;
  final String appStoreUrl;
  final String? releaseNotes;
  final String? trackName;
}

class AppUpdateService extends GetxService {
  static const String _lastPromptAtKey = 'app_update_last_prompt_at';
  static const String _lastPromptVersionKey = 'app_update_last_prompt_version';

  Future<void> checkForUpdateIfNeeded({
    Duration minInterval = const Duration(days: 1),
    bool forceDialog = false,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;

    final storeInfo = await _fetchAppStoreInfo();
    if (storeInfo == null) return;

    final currentInfo = await PackageInfo.fromPlatform();
    final comparison = _compareVersions(storeInfo.version, currentInfo.version);
    if (comparison <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final lastPromptAt = prefs.getInt(_lastPromptAtKey);
    final lastPromptVersion = prefs.getString(_lastPromptVersionKey);
    final now = DateTime.now();

    if (!forceDialog && lastPromptAt != null) {
      final lastPromptDate = DateTime.fromMillisecondsSinceEpoch(lastPromptAt);
      final isSameVersion = lastPromptVersion == storeInfo.version;
      final withinCooldown = now.difference(lastPromptDate) < minInterval;
      if (isSameVersion && withinCooldown) return;
    }

    await prefs.setInt(_lastPromptAtKey, now.millisecondsSinceEpoch);
    await prefs.setString(_lastPromptVersionKey, storeInfo.version);

    _showUpdateDialog(
      storeInfo,
      currentVersion: currentInfo.version,
      forceDialog: forceDialog,
    );
  }

  Future<AppStoreVersionInfo?> _fetchAppStoreInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final bundleId = packageInfo.packageName;
      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$bundleId',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final result = results.first as Map<String, dynamic>;
      final version = result['version'] as String?;
      final appStoreUrl = result['trackViewUrl'] as String?;
      if (version == null || appStoreUrl == null) return null;

      return AppStoreVersionInfo(
        version: version,
        appStoreUrl: appStoreUrl,
        releaseNotes: result['releaseNotes'] as String?,
        trackName: result['trackName'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  int _compareVersions(String a, String b) {
    final aParts = _parseVersionParts(a);
    final bParts = _parseVersionParts(b);
    final length = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;

    for (var i = 0; i < length; i++) {
      final aValue = i < aParts.length ? aParts[i] : 0;
      final bValue = i < bParts.length ? bParts[i] : 0;
      if (aValue != bValue) return aValue.compareTo(bValue);
    }

    return 0;
  }

  List<int> _parseVersionParts(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }

  Future<void> _showUpdateDialog(
    AppStoreVersionInfo storeInfo, {
    required String currentVersion,
    required bool forceDialog,
  }) async {
    if (!Get.isRegistered<AppUpdateService>()) {
      Get.put(this, permanent: true);
    }

    final theme = Get.theme;
    final title = 'update_available_title'.trParams({
      'name': storeInfo.trackName ?? 'FitScript AI',
    });
    final message = 'update_available_message'.trParams({
      'current': currentVersion,
      'latest': storeInfo.version,
    });

    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          if (!forceDialog)
            TextButton(
              onPressed: () => Get.back<void>(),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              child: Text('update_later_button'.tr),
            ),
          FilledButton(
            onPressed: () async {
              await _openStoreUrl(storeInfo.appStoreUrl);
              if (!forceDialog) {
                Get.back<void>();
              }
            },
            child: Text('update_now_button'.tr),
          ),
        ],
      ),
      barrierDismissible: !forceDialog,
    );
  }

  Future<void> _openStoreUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      Get.snackbar(
        'update_failed_title'.tr,
        'update_failed_message'.tr,
        snackStyle: SnackStyle.FLOATING,
      );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk_platform_interface.dart'
    show EventName;

class TikTokBusinessService extends GetxService {
  TikTokBusinessService({TiktokBusinessSdk? tiktokBusinessSdk})
    : _sdk = tiktokBusinessSdk ?? TiktokBusinessSdk();

  final TiktokBusinessSdk _sdk;

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> init({
    required String accessToken,
    required String appId,
    required String ttAppId,
    bool openDebug = false,
    bool enableAutoIapTrack = true,
    bool disableAutoEnhancedDataPostbackEvents = false,
  }) async {
    try {
      await _sdk.initTiktokBusinessSdk(
        accessToken: accessToken,
        appId: appId,
        ttAppId: ttAppId,
        openDebug: openDebug,
        enableAutoIapTrack: enableAutoIapTrack,
        disableAutoEnhancedDataPostbackEvents:
            disableAutoEnhancedDataPostbackEvents,
      );
      _initialized = true;
    } catch (error, stackTrace) {
      _initialized = false;
      debugPrint('TikTokBusinessService init error: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> setIdentify({
    required String externalId,
    String? externalUserName,
    String? phoneNumber,
    String? email,
  }) async {
    if (!_initialized) {
      throw StateError(
        'TikTokBusinessService not initialized. Call init() first.',
      );
    }

    return _sdk.setIdentify(
      externalId: externalId,
      externalUserName: externalUserName,
      phoneNumber: phoneNumber,
      email: email,
    );
  }

  Future<void> logout() async {
    if (!_initialized) {
      throw StateError(
        'TikTokBusinessService not initialized. Call init() first.',
      );
    }

    return _sdk.logout();
  }

  Future<void> trackEvent({
    required EventName eventName,
    String? eventId,
  }) async {
    if (!_initialized) {
      throw StateError(
        'TikTokBusinessService not initialized. Call init() first.',
      );
    }

    return _sdk.trackTTEvent(event: eventName, eventId: eventId);
  }
}

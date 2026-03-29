import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tiktok_business_sdk/tiktok_business_sdk_platform_interface.dart'
    show EventName;

import '../../../core/services/account_auth_service.dart';
import '../../../core/services/lab_analysis_service.dart';
import '../../../core/services/tiktok_business_service.dart';
import '../../../routes/app_pages.dart';
import '../views/legal_document_view.dart';
import '../views/premium_upgrade_view.dart';
import '../views/info_detail_view.dart';

enum LabHistoryStatus { normal, warning, improve }

class BiomarkerTrendPoint {
  const BiomarkerTrendPoint({
    required this.score,
    required this.dateLabel,
    required this.analyzedAt,
  });

  final double score;
  final String dateLabel;
  final DateTime analyzedAt;
}

class BiomarkerTrendData {
  const BiomarkerTrendData({
    required this.signalKey,
    required this.label,
    required this.points,
  });

  final String signalKey;
  final String label;
  final List<BiomarkerTrendPoint> points;

  List<double> get scores => points.map((point) => point.score).toList();

  int get sampleCount => points.length;

  double get delta {
    if (scores.length < 2) return 0;
    return scores.last - scores.first;
  }

  int get directionCode {
    final value = delta;
    if (value > 0.05) return 1;
    if (value < -0.05) return -1;
    return 0;
  }
}

class BiomarkerTrendSummary {
  const BiomarkerTrendSummary({
    required this.label,
    required this.directionCode,
    required this.sampleCount,
  });

  final String label;
  final int directionCode;
  final int sampleCount;
}

class LabHistoryItem {
  const LabHistoryItem({
    required this.id,
    required this.analyzedAt,
    required this.date,
    required this.title,
    required this.summary,
    required this.recommendation,
    required this.signals,
    required this.nextSteps,
    required this.sources,
    required this.status,
  });

  final String id;
  final DateTime analyzedAt;
  final String date;
  final String title;
  final String summary;
  final String recommendation;
  final List<String> signals;
  final List<String> nextSteps;
  final List<LabAnalysisSource> sources;
  final LabHistoryStatus status;

  String get note => summary;
}

class PendingLabAnalysis {
  const PendingLabAnalysis({
    required this.title,
    required this.summary,
    required this.recommendation,
    required this.signals,
    required this.nextSteps,
    required this.sources,
    required this.status,
  });

  final String title;
  final String summary;
  final String recommendation;
  final List<String> signals;
  final List<String> nextSteps;
  final List<LabAnalysisSource> sources;
  final LabHistoryStatus status;
}

class HomeController extends GetxController {
  HomeController({
    AccountAuthService? accountAuthService,
    LabAnalysisService? labAnalysisService,
    ImagePicker? imagePicker,
  }) : _accountAuthService = accountAuthService ?? AccountAuthService(),
       _labAnalysisService = labAnalysisService ?? LabAnalysisService(),
       _imagePicker = imagePicker ?? ImagePicker();

  final selectedTabIndex = 0.obs;
  final reminderEnabled = true.obs;
  final isLinkingGoogle = false.obs;
  final isLinkingApple = false.obs;
  final isDeletingAccount = false.obs;
  final selectedLanguageCode = 'en'.obs;
  final isAnalyzingLabImage = false.obs;
  final isPreparingDocument = false.obs;
  final isSavingAnalysis = false.obs;
  final isCurrentAnalysisSaved = false.obs;
  final isHistoryLoading = false.obs;
  final maxAnalysisFreeTrial = 2.obs;
  final selectedThemeMode = ThemeMode.system.obs;
  final maxSaveAnalysisResultFreeTrial = 5.obs;
  final usedAnalysisFreeTrial = 0.obs;
  final usedSaveAnalysisResultFreeTrial = 0.obs;
  final isPremiumUser = false.obs;
  final analysisHistories = <LabHistoryItem>[].obs;
  final selectedLabImageBytes = Rxn<Uint8List>();
  final selectedLabImageName = RxnString();
  final selectedLabOriginalSizeBytes = RxnInt();
  final selectedLabFinalSizeBytes = RxnInt();
  final isSelectedLabFileCompressed = false.obs;
  final pendingAnalysis = Rxn<PendingLabAnalysis>();
  final currentUser = Rxn<User>();
  final AccountAuthService _accountAuthService;
  final LabAnalysisService _labAnalysisService;
  final ImagePicker _imagePicker;
  static const int _maxDocumentBytes = 500 * 1024;
  static const String _trialUsageAnalysisDeviceKey =
      'trial_usage_analysis_device';
  static const String _trialUsageSaveDeviceKey = 'trial_usage_save_device';
  static const String _localGuestModeKey = 'local_guest_mode';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _localGuestHistoryKey = 'local_guest_analysis_history_v1';
  static const String _aiAnalysisConsentKey = 'ai_analysis_consent';
  static const String _supportEmail = 'support@fitscript.ai';
  bool _isMigratingLocalGuestHistory = false;

  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _analysisHistorySubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _subscriptionStatusSubscription;

  Map<String, int> get trialUsage => <String, int>{
    'profile_trial_lab_result_analysis'.tr: analysisTrialRemaining,
    'profile_trial_save_analysis_result'.tr: saveTrialRemaining,
  };

  int get analysisTrialRemaining {
    final remaining = maxAnalysisFreeTrial.value - usedAnalysisFreeTrial.value;
    return remaining > 0 ? remaining : 0;
  }

  int get saveTrialRemaining {
    final remaining =
        maxSaveAnalysisResultFreeTrial.value -
        usedSaveAnalysisResultFreeTrial.value;
    return remaining > 0 ? remaining : 0;
  }

  bool get canAnalyzeWithTrial =>
      isPremiumUser.value || analysisTrialRemaining > 0;

  bool get canSaveWithTrial => isPremiumUser.value || saveTrialRemaining > 0;

  String get userName {
    final user = currentUser.value;
    if (user == null) return 'profile_user_default'.tr;
    if ((user.displayName ?? '').trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    return user.email ?? 'profile_user_default'.tr;
  }

  String get userEmail {
    final user = currentUser.value;
    return user?.email ?? 'profile_user_not_connected'.tr;
  }

  bool get isAnonymousUser => currentUser.value?.isAnonymous ?? true;

  String get guestSessionTypeLabel {
    final user = currentUser.value;
    if (user == null) return 'profile_guest_session_local'.tr;
    return 'profile_guest_session_firebase'.tr;
  }

  int get totalHistories => analysisHistories.length;

  int get warningCount => analysisHistories
      .where((item) => item.status == LabHistoryStatus.warning)
      .length;

  int get improveCount => analysisHistories
      .where((item) => item.status == LabHistoryStatus.improve)
      .length;

  List<LabHistoryItem> get trendHistories {
    final source = analysisHistories.toList(growable: false);
    source.sort((a, b) => a.analyzedAt.compareTo(b.analyzedAt));
    return source;
  }

  List<double> get trendScores => trendHistories
      .map(
        (item) => switch (item.status) {
          LabHistoryStatus.warning => 1.0,
          LabHistoryStatus.normal => 2.0,
          LabHistoryStatus.improve => 3.0,
        },
      )
      .toList(growable: false);

  List<BiomarkerTrendData> get biomarkerTrends {
    final buckets = <String, List<BiomarkerTrendPoint>>{};

    for (final history in trendHistories) {
      final score = switch (history.status) {
        LabHistoryStatus.warning => 1.0,
        LabHistoryStatus.normal => 2.0,
        LabHistoryStatus.improve => 3.0,
      };

      final normalizedSignals = history.signals
          .map(_normalizeSignalKey)
          .where((signal) => signal.isNotEmpty)
          .toSet();
      if (normalizedSignals.isEmpty) {
        continue;
      }

      for (final signal in normalizedSignals) {
        buckets
            .putIfAbsent(signal, () => <BiomarkerTrendPoint>[])
            .add(
              BiomarkerTrendPoint(
                score: score,
                dateLabel: history.date,
                analyzedAt: history.analyzedAt,
              ),
            );
      }
    }

    final trends = buckets.entries
        .where((entry) => entry.value.length >= 2)
        .map(
          (entry) => BiomarkerTrendData(
            signalKey: entry.key,
            label: _formatSignalLabel(entry.key),
            points: List<BiomarkerTrendPoint>.unmodifiable(entry.value),
          ),
        )
        .toList(growable: false);

    trends.sort((a, b) {
      final bySampleCount = b.sampleCount.compareTo(a.sampleCount);
      if (bySampleCount != 0) return bySampleCount;
      return b.delta.abs().compareTo(a.delta.abs());
    });

    return trends;
  }

  BiomarkerTrendData? get primaryBiomarkerTrend {
    final trends = biomarkerTrends;
    if (trends.isEmpty) return null;
    return trends.first;
  }

  List<String> get secondaryBiomarkerTrendLabels {
    final trends = biomarkerTrends;
    if (trends.length <= 1) return const <String>[];
    return trends.skip(1).take(3).map((trend) => trend.label).toList();
  }

  List<BiomarkerTrendSummary> get topBiomarkerTrendSummaries {
    final trends = biomarkerTrends;
    if (trends.isEmpty) return const <BiomarkerTrendSummary>[];
    return trends
        .take(3)
        .map(
          (trend) => BiomarkerTrendSummary(
            label: trend.label,
            directionCode: trend.directionCode,
            sampleCount: trend.sampleCount,
          ),
        )
        .toList(growable: false);
  }

  List<double> get chartTrendScores =>
      primaryBiomarkerTrend?.scores ?? trendScores;

  String get chartTrendStartDateLabel {
    final primary = primaryBiomarkerTrend;
    if (primary != null && primary.points.isNotEmpty) {
      return primary.points.first.dateLabel;
    }
    final histories = trendHistories;
    if (histories.isNotEmpty) {
      return histories.first.date;
    }
    return '-';
  }

  String get chartTrendEndDateLabel {
    final primary = primaryBiomarkerTrend;
    if (primary != null && primary.points.isNotEmpty) {
      return primary.points.last.dateLabel;
    }
    final histories = trendHistories;
    if (histories.isNotEmpty) {
      return histories.last.date;
    }
    return '-';
  }

  bool get canShowTrendAnalysis => chartTrendScores.length >= 2;

  double get trendDelta {
    final biomarkerDelta = primaryBiomarkerTrend?.delta;
    if (biomarkerDelta != null) return biomarkerDelta;

    final scores = chartTrendScores;
    if (scores.length < 2) return 0;
    return scores.last - scores.first;
  }

  String _normalizeSignalKey(String raw) {
    final lowered = raw.toLowerCase().trim();
    if (lowered.isEmpty) return '';
    return lowered
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _formatSignalLabel(String key) {
    final cleaned = key.trim().replaceAll(RegExp(r'[_\-]+'), ' ');
    if (cleaned.isEmpty) return key;
    return cleaned
        .split(RegExp(r'\s+'))
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void onInit() {
    super.onInit();
    _loadLanguagePreference();
    _loadThemePreference();
    _loadFreeTrialLimits();
    _syncAuthUserState(FirebaseAuth.instance.currentUser);
    _authSubscription = FirebaseAuth.instance.userChanges().listen(
      _syncAuthUserState,
    );
  }

  @override
  void onClose() {
    _analysisHistorySubscription?.cancel();
    _subscriptionStatusSubscription?.cancel();
    _authSubscription.cancel();
    super.onClose();
  }

  void _bindSubscriptionStatusStream(String? uid) {
    _subscriptionStatusSubscription?.cancel();

    if (uid == null || uid.isEmpty) {
      isPremiumUser.value = false;
      return;
    }

    _subscriptionStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('subscription')
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) {
              isPremiumUser.value = false;
              return;
            }

            final data = snapshot.data() ?? const <String, dynamic>{};
            final isPremium = data['isPremium'] == true;
            final status = (data['status'] ?? '').toString().toLowerCase();
            isPremiumUser.value =
                isPremium || status == 'active' || status == 'trialing';
          },
          onError: (_) {
            isPremiumUser.value = false;
          },
        );
  }

  void _syncAuthUserState(User? user) {
    currentUser.value = user;
    unawaited(_maybeMigrateLocalGuestHistoryToCloud(user));
    _loadTrialUsageForUser(user?.uid);
    _bindAnalysisHistoryStream(user?.uid);
    _bindSubscriptionStatusStream(user?.uid);
  }

  Future<void> _maybeMigrateLocalGuestHistoryToCloud(User? user) async {
    if (_isMigratingLocalGuestHistory) return;
    if (user == null || user.isAnonymous) return;

    final prefs = await SharedPreferences.getInstance();
    final isLocalGuest = prefs.getBool(_localGuestModeKey) ?? false;
    if (!isLocalGuest) return;

    final rawList =
        prefs.getStringList(_localGuestHistoryKey) ?? const <String>[];
    if (rawList.isEmpty) {
      await prefs.setBool(_localGuestModeKey, false);
      return;
    }

    final localEntries = <Map<String, dynamic>>[];
    for (final entry in rawList) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          localEntries.add(decoded);
        }
      } catch (_) {}
    }

    if (localEntries.isEmpty) {
      await prefs.setBool(_localGuestModeKey, false);
      await prefs.remove(_localGuestHistoryKey);
      return;
    }

    _isMigratingLocalGuestHistory = true;
    try {
      final historyCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('analysis_history');

      WriteBatch batch = FirebaseFirestore.instance.batch();
      var opCount = 0;

      for (final item in localEntries) {
        final localId = (item['id'] ?? '').toString().trim();
        final docId = localId.isNotEmpty
            ? localId
            : 'migrated_${DateTime.now().millisecondsSinceEpoch}_$opCount';

        final createdAtMillis = (item['createdAtMillis'] as num?)?.toInt();
        final createdAtTimestamp = createdAtMillis != null
            ? Timestamp.fromMillisecondsSinceEpoch(createdAtMillis)
            : FieldValue.serverTimestamp();

        batch.set(historyCollection.doc(docId), {
          'title': item['title'],
          'summary': item['summary'],
          'recommendation': item['recommendation'],
          'signals': item['signals'] ?? const <String>[],
          'nextSteps': item['nextSteps'] ?? const <String>[],
          'status': item['status'] ?? 'normal',
          'imageName': item['imageName'],
          'fileName': item['fileName'],
          'contentType': item['contentType'],
          'originalFileSizeBytes': item['originalFileSizeBytes'],
          'finalFileSizeBytes': item['finalFileSizeBytes'],
          'isCompressed': item['isCompressed'],
          'source': 'migrated_local_guest',
          'createdAt': createdAtTimestamp,
          'analyzedAt': createdAtTimestamp,
        }, SetOptions(merge: true));

        opCount++;
        if (opCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          opCount = 0;
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }

      await prefs.setBool(_localGuestModeKey, false);
      await prefs.remove(_localGuestHistoryKey);
    } catch (_) {
      // keep local history untouched to retry on next auth sync
    } finally {
      _isMigratingLocalGuestHistory = false;
    }
  }

  Future<void> _resetOnboardingCompletionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
  }

  void _bindAnalysisHistoryStream(String? uid) {
    _analysisHistorySubscription?.cancel();

    if (uid == null || uid.isEmpty) {
      isHistoryLoading.value = true;
      _loadLocalGuestHistories();
      return;
    }

    isHistoryLoading.value = true;
    _analysisHistorySubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('analysis_history')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .map((doc) => _mapHistoryDocument(doc.id, doc.data()))
                .toList();
            analysisHistories.assignAll(items);
            isHistoryLoading.value = false;
          },
          onError: (_) {
            analysisHistories.assignAll(const <LabHistoryItem>[]);
            isHistoryLoading.value = false;
          },
        );
  }

  Future<bool> _isLocalGuestModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_localGuestModeKey) ?? false;
  }

  Future<void> _loadLocalGuestHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final isLocalGuest = prefs.getBool(_localGuestModeKey) ?? false;

    if (!isLocalGuest) {
      analysisHistories.assignAll(const <LabHistoryItem>[]);
      isHistoryLoading.value = false;
      return;
    }

    final rawList =
        prefs.getStringList(_localGuestHistoryKey) ?? const <String>[];

    final entries = <Map<String, dynamic>>[];
    for (final entry in rawList) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          entries.add(decoded);
        }
      } catch (_) {}
    }

    entries.sort((a, b) {
      final aTime = (a['createdAtMillis'] as num?)?.toInt() ?? 0;
      final bTime = (b['createdAtMillis'] as num?)?.toInt() ?? 0;
      return bTime.compareTo(aTime);
    });

    final items = entries
        .map(
          (entry) => _mapHistoryDocument((entry['id'] ?? '').toString(), entry),
        )
        .toList();

    analysisHistories.assignAll(items);
    isHistoryLoading.value = false;
  }

  Future<bool> _saveLocalGuestHistory(PendingLabAnalysis analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_localGuestHistoryKey) ?? <String>[];

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final id = 'local_$nowMillis';
    final record = <String, dynamic>{
      'id': id,
      'title': analysis.title,
      'summary': analysis.summary,
      'recommendation': analysis.recommendation,
      'signals': analysis.signals,
      'nextSteps': analysis.nextSteps,
      'sources': analysis.sources
          .map((source) => {'label': source.label, 'url': source.url})
          .toList(),
      'status': switch (analysis.status) {
        LabHistoryStatus.warning => 'warning',
        LabHistoryStatus.improve => 'improve',
        LabHistoryStatus.normal => 'normal',
      },
      'imageName': selectedLabImageName.value,
      'fileName': selectedLabImageName.value,
      'contentType': _selectedContentType,
      'originalFileSizeBytes': selectedLabOriginalSizeBytes.value,
      'finalFileSizeBytes': selectedLabFinalSizeBytes.value,
      'isCompressed': isSelectedLabFileCompressed.value,
      'source': 'home_capture_upload_local_guest',
      'createdAtMillis': nowMillis,
      'createdAt': DateTime.fromMillisecondsSinceEpoch(
        nowMillis,
      ).toIso8601String(),
      'analyzedAt': DateTime.fromMillisecondsSinceEpoch(
        nowMillis,
      ).toIso8601String(),
    };

    rawList.add(jsonEncode(record));
    final saved = await prefs.setStringList(_localGuestHistoryKey, rawList);
    if (saved) {
      await _loadLocalGuestHistories();
    }
    return saved;
  }

  Future<bool> _deleteLocalGuestHistory(String historyId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_localGuestHistoryKey) ?? <String>[];

    final filtered = rawList.where((entry) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          return (decoded['id'] ?? '').toString() != historyId;
        }
      } catch (_) {}
      return true;
    }).toList();

    if (filtered.length == rawList.length) {
      return false;
    }

    final saved = await prefs.setStringList(_localGuestHistoryKey, filtered);
    if (saved) {
      await _loadLocalGuestHistories();
    }
    return saved;
  }

  LabHistoryItem _mapHistoryDocument(String docId, Map<String, dynamic> data) {
    final title =
        (data['title'] ?? data['testName'] ?? data['analysisTitle'] ?? '')
            .toString()
            .trim();
    final summary =
        (data['summary'] ??
                data['analysisSummary'] ??
                data['note'] ??
                data['resultSummary'] ??
                '')
            .toString()
            .trim();
    final recommendation = (data['recommendation'] ?? data['advice'] ?? '')
        .toString()
        .trim();
    final signals = _parseStringList(data['signals']);
    final nextSteps = _parseStringList(data['nextSteps'] ?? data['next_steps']);
    final sources = _parseSources(data['sources']);

    final statusRaw =
        (data['status'] ?? data['riskLevel'] ?? data['severity'] ?? '')
            .toString()
            .toLowerCase()
            .trim();

    final status = switch (statusRaw) {
      'warning' ||
      'high' ||
      'abnormal' ||
      'attention' => LabHistoryStatus.warning,
      'improve' ||
      'improving' ||
      'better' ||
      'progress' => LabHistoryStatus.improve,
      _ => LabHistoryStatus.normal,
    };

    final date = _extractHistoryDate(data);

    return LabHistoryItem(
      id: docId,
      analyzedAt: date,
      date: _formatDate(date),
      title: title.isNotEmpty ? title : 'history_unknown_title'.tr,
      summary: summary.isNotEmpty ? summary : 'history_unknown_note'.tr,
      recommendation: recommendation,
      signals: signals,
      nextSteps: nextSteps,
      sources: sources,
      status: status,
    );
  }

  List<String> _parseStringList(dynamic raw) {
    if (raw is Iterable) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      final value = raw.trim();
      if (value.isEmpty) return const <String>[];
      return <String>[value];
    }
    return const <String>[];
  }

  List<LabAnalysisSource> _parseSources(dynamic raw) {
    if (raw is Iterable) {
      return raw
          .whereType<Map>()
          .map(
            (item) => LabAnalysisSource(
              label: (item['label'] ?? item['name'] ?? '').toString().trim(),
              url: (item['url'] ?? item['link'] ?? '').toString().trim(),
            ),
          )
          .where((source) => source.label.isNotEmpty && source.url.isNotEmpty)
          .toList();
    }
    return const <LabAnalysisSource>[];
  }

  DateTime _extractHistoryDate(Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['createdAt'],
      data['analyzedAt'],
      data['timestamp'],
      data['date'],
    ];

    for (final raw in candidates) {
      if (raw == null) continue;
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(raw);
        } catch (_) {}
      }
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }

    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    final monthNamesEn = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthNamesId = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final months = selectedLanguageCode.value == 'id'
        ? monthNamesId
        : monthNamesEn;
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();
    return '$day $month $year';
  }

  void onTabChanged(int index) {
    selectedTabIndex.value = index;
  }

  void toggleReminder(bool value) {
    reminderEnabled.value = value;
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeModeKey) ?? 'system';

    final mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    selectedThemeMode.value = mode;
    Get.changeThemeMode(mode);
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    selectedThemeMode.value = mode;
    Get.changeThemeMode(mode);

    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_themeModeKey, value);
  }

  String get selectedThemeModeLabel {
    return switch (selectedThemeMode.value) {
      ThemeMode.light => 'profile_theme_light'.tr,
      ThemeMode.dark => 'profile_theme_dark'.tr,
      _ => 'profile_theme_system'.tr,
    };
  }

  String get selectedLanguageLabel => selectedLanguageCode.value == 'id'
      ? 'profile_language_indonesian'.tr
      : 'profile_language_english'.tr;

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

    final languageName = normalized == 'id'
        ? 'profile_language_indonesian'.tr
        : 'profile_language_english'.tr;
    _showAppSnackbar(
      'profile_language_changed'.tr,
      'profile_language_changed_message'.trParams({'language': languageName}),
    );
  }

  void _showAppSnackbar(
    String title,
    String message, {
    SnackPosition position = SnackPosition.BOTTOM,
    IconData icon = Icons.info_outline,
  }) {
    final theme = Get.theme;

    Get.snackbar(
      title,
      message,
      snackStyle: SnackStyle.FLOATING,
      snackPosition: position,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      borderRadius: 14,
      duration: const Duration(milliseconds: 2400),
      isDismissible: true,
      shouldIconPulse: false,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      colorText: theme.colorScheme.onSurface,
      icon: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      titleText: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      ),
      messageText: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.14),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Future<bool> _ensureAiAnalysisConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final hasConsent = prefs.getBool(_aiAnalysisConsentKey) ?? false;
    if (hasConsent) return true;

    final theme = Get.theme;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        title: Text('ai_analysis_consent_title'.tr),
        content: Text('ai_analysis_consent_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text('ai_analysis_consent_decline'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('ai_analysis_consent_accept'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed != true) return false;

    await prefs.setBool(_aiAnalysisConsentKey, true);
    _showAppSnackbar(
      'ai_analysis_consent_saved_title'.tr,
      'ai_analysis_consent_saved_message'.tr,
    );
    return true;
  }

  Future<void> manageAiAnalysisConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final hasConsent = prefs.getBool(_aiAnalysisConsentKey) ?? false;

    final theme = Get.theme;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        title: Text('ai_analysis_consent_manage_title'.tr),
        content: Text(
          hasConsent
              ? 'ai_analysis_consent_manage_message_granted'.tr
              : 'ai_analysis_consent_manage_message_not_granted'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text('ai_analysis_consent_decline'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              hasConsent
                  ? 'ai_analysis_consent_manage_revoke'.tr
                  : 'ai_analysis_consent_manage_grant'.tr,
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed != true) return;

    if (hasConsent) {
      await prefs.setBool(_aiAnalysisConsentKey, false);
      _showAppSnackbar(
        'ai_analysis_consent_revoked_title'.tr,
        'ai_analysis_consent_revoked_message'.tr,
      );
      return;
    }

    await _ensureAiAnalysisConsent();
  }

  Future<void> _loadFreeTrialLimits() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(minutes: 30),
        ),
      );
      await remoteConfig.setDefaults({
        'max_analysis_free_trial': 2,
        'max_save_analysis_result_free_trial': 5,
      });
      await remoteConfig.fetchAndActivate();

      final analysisLimit = remoteConfig.getInt('max_analysis_free_trial');
      final saveLimit = remoteConfig.getInt(
        'max_save_analysis_result_free_trial',
      );

      if (analysisLimit > 0) {
        maxAnalysisFreeTrial.value = analysisLimit;
      }
      if (saveLimit > 0) {
        maxSaveAnalysisResultFreeTrial.value = saveLimit;
      }
    } catch (_) {}
  }

  String _legacyTrialUsageKey(String metric, String? uid) {
    final owner = (uid ?? 'guest').trim();
    return 'trial_usage_${metric}_$owner';
  }

  Future<void> _loadTrialUsageForUser(String? uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final deviceAnalysis = prefs.getInt(_trialUsageAnalysisDeviceKey) ?? 0;
      final deviceSave = prefs.getInt(_trialUsageSaveDeviceKey) ?? 0;

      final legacyAnalysisByUid =
          prefs.getInt(_legacyTrialUsageKey('analysis', uid)) ?? 0;
      final legacyAnalysisGuest =
          prefs.getInt(_legacyTrialUsageKey('analysis', null)) ?? 0;
      final mergedAnalysis = [
        deviceAnalysis,
        legacyAnalysisByUid,
        legacyAnalysisGuest,
      ].reduce((a, b) => a > b ? a : b);

      final legacySaveByUid =
          prefs.getInt(_legacyTrialUsageKey('save', uid)) ?? 0;
      final legacySaveGuest =
          prefs.getInt(_legacyTrialUsageKey('save', null)) ?? 0;
      final mergedSave = [
        deviceSave,
        legacySaveByUid,
        legacySaveGuest,
      ].reduce((a, b) => a > b ? a : b);

      await prefs.setInt(_trialUsageAnalysisDeviceKey, mergedAnalysis);
      await prefs.setInt(_trialUsageSaveDeviceKey, mergedSave);

      var finalAnalysis = mergedAnalysis;
      var finalSave = mergedSave;

      if (uid != null && uid.trim().isNotEmpty) {
        final cloudUsage = await _loadTrialUsageFromCloud(uid);
        finalAnalysis = [
          finalAnalysis,
          cloudUsage.analysis,
        ].reduce((a, b) => a > b ? a : b);
        finalSave = [
          finalSave,
          cloudUsage.save,
        ].reduce((a, b) => a > b ? a : b);

        await prefs.setInt(_trialUsageAnalysisDeviceKey, finalAnalysis);
        await prefs.setInt(_trialUsageSaveDeviceKey, finalSave);

        await _saveTrialUsageToCloud(
          uid: uid,
          analysis: finalAnalysis,
          save: finalSave,
        );
      }

      usedAnalysisFreeTrial.value = finalAnalysis;
      usedSaveAnalysisResultFreeTrial.value = finalSave;
    } catch (_) {
      usedAnalysisFreeTrial.value = 0;
      usedSaveAnalysisResultFreeTrial.value = 0;
    }
  }

  Future<({int analysis, int save})> _loadTrialUsageFromCloud(
    String uid,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('trial_usage')
          .get();
      final data = doc.data();
      final analysis = (data?['analysisUsed'] as num?)?.toInt() ?? 0;
      final save = (data?['saveUsed'] as num?)?.toInt() ?? 0;
      return (analysis: analysis, save: save);
    } catch (_) {
      return (analysis: 0, save: 0);
    }
  }

  Future<void> _saveTrialUsageToCloud({
    required String uid,
    required int analysis,
    required int save,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('trial_usage')
        .set({
          'analysisUsed': analysis,
          'saveUsed': save,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _increaseTrialUsage({required String metric}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = metric == 'analysis'
        ? _trialUsageAnalysisDeviceKey
        : _trialUsageSaveDeviceKey;
    final current = prefs.getInt(key) ?? 0;
    final next = current + 1;
    await prefs.setInt(key, next);

    if (metric == 'analysis') {
      usedAnalysisFreeTrial.value = next;
    } else if (metric == 'save') {
      usedSaveAnalysisResultFreeTrial.value = next;
    }

    final user = currentUser.value;
    if (user != null && !user.isAnonymous) {
      try {
        await _saveTrialUsageToCloud(
          uid: user.uid,
          analysis: usedAnalysisFreeTrial.value,
          save: usedSaveAnalysisResultFreeTrial.value,
        );
      } catch (_) {}
    }
  }

  Future<void> pickLabImageFromCamera() async {
    if (isPreparingDocument.value) {
      _showPreparingInProgressMessage();
      return;
    }
    await _pickLabImage(ImageSource.camera);
  }

  Future<void> pickLabImageFromGallery() async {
    if (isPreparingDocument.value) {
      _showPreparingInProgressMessage();
      return;
    }
    await _pickLabImage(ImageSource.gallery);
  }

  Future<void> pickLabPdfDocument() async {
    if (isPreparingDocument.value) {
      _showPreparingInProgressMessage();
      return;
    }
    try {
      final picked = await _pickPdfPlatformFile();
      if (picked == null) return;
      if (!_isPdfFileName(picked.name)) {
        _showPdfOnlyMessage();
        return;
      }

      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showAppSnackbar(
          'home_pick_failed_title'.tr,
          'home_pick_failed_message'.tr,
          icon: Icons.error_outline,
        );
        return;
      }

      final prepared = await _preparePickedDocument(
        fileName: picked.name,
        bytes: bytes,
      );
      if (prepared == null) return;

      selectedLabImageBytes.value = prepared.bytes;
      selectedLabImageName.value = prepared.fileName;
      selectedLabOriginalSizeBytes.value = prepared.originalSizeBytes;
      selectedLabFinalSizeBytes.value = prepared.finalSizeBytes;
      isSelectedLabFileCompressed.value = prepared.isCompressed;
      pendingAnalysis.value = null;
      isCurrentAnalysisSaved.value = false;
    } catch (_) {
      _showAppSnackbar(
        'home_pick_failed_title'.tr,
        'home_pick_failed_message'.tr,
        icon: Icons.error_outline,
      );
    }
  }

  Future<PlatformFile?> _pickPdfPlatformFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      return result.files.first;
    } on MissingPluginException {
      try {
        final fallback = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
        if (fallback == null || fallback.files.isEmpty) return null;
        return fallback.files.first;
      } on MissingPluginException {
        _showFilePickerUnavailableMessage();
        return null;
      }
    }
  }

  Future<void> _pickLabImage(ImageSource source) async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (xFile == null) return;

      final bytes = await xFile.readAsBytes();
      final prepared = await _preparePickedDocument(
        fileName: xFile.name,
        bytes: bytes,
      );
      if (prepared == null) return;

      selectedLabImageBytes.value = prepared.bytes;
      selectedLabImageName.value = prepared.fileName;
      selectedLabOriginalSizeBytes.value = prepared.originalSizeBytes;
      selectedLabFinalSizeBytes.value = prepared.finalSizeBytes;
      isSelectedLabFileCompressed.value = prepared.isCompressed;
      pendingAnalysis.value = null;
      isCurrentAnalysisSaved.value = false;
    } catch (_) {
      _showAppSnackbar(
        'home_pick_failed_title'.tr,
        'home_pick_failed_message'.tr,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> analyzeSelectedLabImage() async {
    if (selectedLabImageBytes.value == null) {
      _showAppSnackbar(
        'home_no_document_title'.tr,
        'home_no_document_message'.tr,
        icon: Icons.upload_file_outlined,
      );
      return;
    }
    if (isPreparingDocument.value) return;
    if (isAnalyzingLabImage.value) return;
    if (!canAnalyzeWithTrial) {
      _showAppSnackbar(
        'home_trial_analysis_limit_title'.tr,
        'home_trial_analysis_limit_message'.trParams({
          'max': '${maxAnalysisFreeTrial.value}',
        }),
        icon: Icons.lock_outline,
      );
      return;
    }

    final consented = await _ensureAiAnalysisConsent();
    if (!consented) return;

    isAnalyzingLabImage.value = true;
    try {
      final output = await _labAnalysisService.analyzeLabImage(
        fileName: selectedLabImageName.value ?? 'lab_upload.jpg',
        bytes: selectedLabImageBytes.value!,
        languageCode: selectedLanguageCode.value,
      );

      final status = switch (output.severity) {
        LabAnalysisSeverity.warning => LabHistoryStatus.warning,
        LabAnalysisSeverity.improve => LabHistoryStatus.improve,
        LabAnalysisSeverity.normal => LabHistoryStatus.normal,
      };

      pendingAnalysis.value = PendingLabAnalysis(
        title: output.title,
        summary: output.summary,
        recommendation: output.recommendation,
        signals: output.signals,
        nextSteps: output.nextSteps,
        sources: output.sources,
        status: status,
      );
      isCurrentAnalysisSaved.value = false;
      await _increaseTrialUsage(metric: 'analysis');
    } catch (_) {
      _showAppSnackbar(
        'home_analyze_failed_title'.tr,
        'home_analyze_failed_message'.tr,
        icon: Icons.error_outline,
      );
    } finally {
      isAnalyzingLabImage.value = false;
    }
  }

  Future<bool> saveAnalyzedResult() async {
    final user = currentUser.value;
    final isLocalGuest = user == null && await _isLocalGuestModeEnabled();
    if (user == null && !isLocalGuest) {
      _showAppSnackbar(
        'home_save_failed_title'.tr,
        'home_save_failed_no_user'.tr,
        icon: Icons.error_outline,
      );
      return false;
    }
    final analysis = pendingAnalysis.value;
    if (analysis == null) return false;
    if (isCurrentAnalysisSaved.value) return false;
    if (isSavingAnalysis.value) return false;
    if (!canSaveWithTrial) {
      _showAppSnackbar(
        'home_trial_save_limit_title'.tr,
        'home_trial_save_limit_message'.trParams({
          'max': '${maxSaveAnalysisResultFreeTrial.value}',
        }),
        icon: Icons.lock_outline,
      );
      return false;
    }

    isSavingAnalysis.value = true;
    try {
      if (isLocalGuest) {
        final isSavedLocal = await _saveLocalGuestHistory(analysis);
        if (!isSavedLocal) {
          _showAppSnackbar(
            'home_save_failed_title'.tr,
            'home_save_failed_message'.tr,
            icon: Icons.error_outline,
          );
          return false;
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('analysis_history')
            .add({
              'title': analysis.title,
              'summary': analysis.summary,
              'recommendation': analysis.recommendation,
              'signals': analysis.signals,
              'nextSteps': analysis.nextSteps,
              'sources': analysis.sources
                  .map((source) => {'label': source.label, 'url': source.url})
                  .toList(),
              'status': switch (analysis.status) {
                LabHistoryStatus.warning => 'warning',
                LabHistoryStatus.improve => 'improve',
                LabHistoryStatus.normal => 'normal',
              },
              'imageName': selectedLabImageName.value,
              'fileName': selectedLabImageName.value,
              'contentType': _selectedContentType,
              'originalFileSizeBytes': selectedLabOriginalSizeBytes.value,
              'finalFileSizeBytes': selectedLabFinalSizeBytes.value,
              'isCompressed': isSelectedLabFileCompressed.value,
              'source': 'home_capture_upload',
              'createdAt': FieldValue.serverTimestamp(),
              'analyzedAt': FieldValue.serverTimestamp(),
            });
      }

      isCurrentAnalysisSaved.value = true;
      await _increaseTrialUsage(metric: 'save');
      return true;
    } catch (_) {
      _showAppSnackbar(
        'home_save_failed_title'.tr,
        'home_save_failed_message'.tr,
        icon: Icons.error_outline,
      );
      return false;
    } finally {
      isSavingAnalysis.value = false;
    }
  }

  Future<bool> deleteHistoryItem(LabHistoryItem history) async {
    final user = currentUser.value;
    final isLocalGuest = user == null && await _isLocalGuestModeEnabled();
    if (user == null && !isLocalGuest) {
      _showAppSnackbar(
        'history_delete_failed_title'.tr,
        'home_save_failed_no_user'.tr,
        icon: Icons.error_outline,
      );
      return false;
    }

    if (history.id.trim().isEmpty) {
      _showAppSnackbar(
        'history_delete_failed_title'.tr,
        'history_delete_failed_message'.tr,
        icon: Icons.error_outline,
      );
      return false;
    }

    try {
      if (isLocalGuest) {
        final isDeletedLocal = await _deleteLocalGuestHistory(history.id);
        if (!isDeletedLocal) {
          _showAppSnackbar(
            'history_delete_failed_title'.tr,
            'history_delete_failed_message'.tr,
            icon: Icons.error_outline,
          );
          return false;
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('analysis_history')
            .doc(history.id)
            .delete();
      }
      return true;
    } catch (_) {
      _showAppSnackbar(
        'history_delete_failed_title'.tr,
        'history_delete_failed_message'.tr,
        icon: Icons.error_outline,
      );
      return false;
    }
  }

  Future<void> exportHistoryToPdf(LabHistoryItem history) async {
    if (!isPremiumUser.value) {
      _showAppSnackbar(
        'history_export_premium_title'.tr,
        'history_export_premium_message'.tr,
        icon: Icons.lock_outline,
      );
      upgradeToPremium();
      return;
    }

    try {
      final statusLabel = switch (history.status) {
        LabHistoryStatus.warning => 'history_status_warning'.tr,
        LabHistoryStatus.improve => 'history_status_improve'.tr,
        LabHistoryStatus.normal => 'history_status_normal'.tr,
      };

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 1, color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 36,
                        height: 36,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'FS',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        'FitScript AI',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${'history_date_label'.tr}: ${history.date}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            // Title & Status
            pw.Text(
              history.title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: statusLabel.toLowerCase().contains('normal')
                    ? PdfColors.green100
                    : statusLabel.toLowerCase().contains('warning')
                    ? PdfColors.orange100
                    : PdfColors.blue100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                '${'history_status_label'.tr}: $statusLabel',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.blueGrey800,
                ),
              ),
            ),
            pw.SizedBox(height: 18),
            // Findings Section
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'home_analysis_findings_label'.tr,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  history.signals.isEmpty
                      ? pw.Text(
                          '-',
                          style: pw.TextStyle(color: PdfColors.grey600),
                        )
                      : pw.Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: history.signals
                              .map(
                                (signal) => pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  margin: const pw.EdgeInsets.only(bottom: 2),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.blue50,
                                    borderRadius: pw.BorderRadius.circular(6),
                                  ),
                                  child: pw.Text(
                                    signal.trim(),
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      color: PdfColors.blueGrey800,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            // Recommendation Section
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'home_analysis_recommendation_label'.tr,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    history.recommendation.isEmpty
                        ? '-'
                        : history.recommendation,
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            // Next Steps Section
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'home_analysis_next_steps_label'.tr,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  if (history.nextSteps.isEmpty)
                    pw.Text('-', style: pw.TextStyle(color: PdfColors.grey600))
                  else
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: history.nextSteps
                          .map(
                            (step) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 2),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '• ',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: PdfColors.blueGrey800,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      step,
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        color: PdfColors.blueGrey800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by FitScript AI',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  '© ${DateTime.now().year} FitScript',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
      );

      final fileSafeTitle = history.title
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final fileName =
          'fitscript_${fileSafeTitle.isEmpty ? 'report' : fileSafeTitle}.pdf';

      await Printing.sharePdf(bytes: await doc.save(), filename: fileName);

      _showAppSnackbar(
        'history_export_success_title'.tr,
        'history_export_success_message'.tr,
        icon: Icons.picture_as_pdf_outlined,
      );
    } catch (_) {
      _showAppSnackbar(
        'history_export_failed_title'.tr,
        'history_export_failed_message'.tr,
        icon: Icons.error_outline,
      );
    }
  }

  void openPrivacyPolicy() async {
    final hasAccepted = await _hasAcceptedConsent('privacy_policy');
    final isIndonesian = selectedLanguageCode.value == 'id';

    Get.to<bool>(
      () => LegalDocumentView(
        title: 'legal_privacy_title'.tr,
        assetPath: isIndonesian
            ? 'assets/jsons/privacy_policy_fitscript_ai_id.md'
            : 'assets/jsons/privacy_policy_fitscript_ai.md',
        showAgreementAction: !hasAccepted,
        agreementButtonLabel: 'legal_agree_button'.tr,
      ),
    )?.then((accepted) async {
      if (accepted == true) {
        await _saveConsent(
          docId: 'privacy_policy',
          successTitle: 'consent_saved_title'.tr,
          successMessage: 'consent_saved_privacy'.tr,
        );
      }
    });
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

  void openAboutAppInfo() {
    Get.to<void>(() => const InfoDetailView(type: InfoDetailType.about));
  }

  void openSupportInformation() {
    Get.to<void>(() => const InfoDetailView(type: InfoDetailType.support));
  }

  void openMarketingInformation() {
    Get.to<void>(() => const InfoDetailView(type: InfoDetailType.marketing));
  }

  void openEULA() async {
    final url = (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
        ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
        : 'https://fitscript-ai.web.app/terms';

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      _showAppSnackbar(
        'profile_open_link_failed_title'.tr,
        'profile_open_link_failed_message'.tr,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> contactSupport({String? subject}) async {
    final normalizedSubject = subject?.trim();
    final queryParameters = <String, String>{};
    if (normalizedSubject != null && normalizedSubject.isNotEmpty) {
      queryParameters['subject'] = normalizedSubject;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final launched = await launchUrl(uri);
    if (!launched) {
      Get.snackbar(
        'profile_support_unavailable_title'.tr,
        'profile_support_unavailable_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<bool> _hasAcceptedConsent(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('consents')
          .doc(docId)
          .get();

      return (doc.data()?['accepted'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveConsent({
    required String docId,
    required String successTitle,
    required String successMessage,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAppSnackbar(
        'consent_failed_title'.tr,
        'consent_failed_no_session'.tr,
        icon: Icons.error_outline,
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('consents')
          .doc(docId)
          .set({
            'accepted': true,
            'acceptedAt': FieldValue.serverTimestamp(),
            'documentVersion': '2026-03-06',
            'app': 'FitScript AI: Cek Hasil Lab',
          }, SetOptions(merge: true));

      _showAppSnackbar(successTitle, successMessage, icon: Icons.check_rounded);
    } catch (_) {
      _showAppSnackbar(
        'consent_failed_title'.tr,
        'consent_failed_server'.tr,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> signOut() async {
    final isGuest = isAnonymousUser;
    final theme = Get.theme;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        title: Text(
          isGuest
              ? 'profile_guest_exit_confirm_title'.tr
              : 'profile_sign_out_confirm_title'.tr,
        ),
        content: Text(
          isGuest
              ? 'profile_guest_exit_confirm_message'.tr
              : 'profile_sign_out_confirm_message'.tr,
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
            child: Text(
              isGuest
                  ? 'profile_guest_exit_button'.tr
                  : 'profile_sign_out_button'.tr,
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (isGuest) {
        await prefs.setBool(_localGuestModeKey, false);
        Get.offAllNamed(Routes.AUTH);
        return;
      }

      await _accountAuthService.signOutToAnonymous();
      await prefs.setBool(_localGuestModeKey, false);
      Get.offAllNamed(Routes.AUTH);
    } catch (_) {
      _showAppSnackbar(
        'profile_sign_out_failed_title'.tr,
        'profile_sign_out_failed_message'.tr,
        icon: Icons.error_outline,
      );
    }
  }

  void upgradeToPremium() {
    Get.to<void>(() => const PremiumUpgradeView());
  }

  void restorePurchases() {
    Get.to<void>(() => const PremiumUpgradeView(autoRestoreOnOpen: true));
  }

  Future<void> manageSubscription() async {
    if (kIsWeb) {
      _showAppSnackbar(
        'profile_open_link_failed_title'.tr,
        'profile_open_link_failed_message'.tr,
      );
      return;
    }

    try {
      // Lacak klik Manage Subscription sebagai event Subscription
      try {
        final tiktokService = Get.find<TikTokBusinessService>();
        await tiktokService.trackEvent(eventName: EventName.Subscribe);
      } catch (trackingError) {
        debugPrint('TikTok manageSubscription tracking failed: $trackingError');
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      final url = _subscriptionManagementUrl(packageName);
      final uri = Uri.parse(url);

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showAppSnackbar(
          'profile_open_link_failed_title'.tr,
          'profile_open_link_failed_message'.tr,
        );
      }
    } catch (_) {
      _showAppSnackbar(
        'profile_open_link_failed_title'.tr,
        'profile_open_link_failed_message'.tr,
      );
    }
  }

  String _subscriptionManagementUrl(String packageName) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'https://apps.apple.com/account/subscriptions';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://play.google.com/store/account/subscriptions?package=$packageName';
    }

    return 'https://play.google.com/store/account/subscriptions';
  }

  Future<void> deleteAccount() async {
    if (isDeletingAccount.value) return;

    final theme = Get.theme;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        title: Text('profile_delete_title'.tr),
        content: Text('profile_delete_message'.tr),
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
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text('profile_delete_button'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed != true) return;

    isDeletingAccount.value = true;
    try {
      final result = await _accountAuthService
          .deleteAccountAndContinueAnonymous();

      switch (result.status) {
        case DeleteAccountStatus.deleted:
          await _resetOnboardingCompletionFlag();
          _showAppSnackbar(
            'profile_delete_success_title'.tr,
            'profile_delete_success_message'.tr,
            icon: Icons.check_rounded,
          );
          Get.offAllNamed(Routes.ONBOARDING);
          return;
        case DeleteAccountStatus.requiresRecentLogin:
          _showAppSnackbar(
            'profile_delete_recent_login_title'.tr,
            'profile_delete_recent_login_message'.tr,
            icon: Icons.lock_clock_outlined,
          );
          return;
        case DeleteAccountStatus.cancelled:
          _showAppSnackbar(
            'profile_delete_cancelled_title'.tr,
            'profile_delete_cancelled_message'.tr,
            icon: Icons.info_outline,
          );
          return;
        case DeleteAccountStatus.failed:
          final detail = (result.errorCode ?? '').trim();
          _showAppSnackbar(
            'profile_delete_failed_title'.tr,
            detail.isNotEmpty
                ? 'profile_delete_failed_message_with_code'.trParams({
                    'code': detail,
                  })
                : 'profile_delete_failed_message'.tr,
            icon: Icons.error_outline,
          );
          return;
      }
    } catch (_) {
      _showAppSnackbar(
        'profile_delete_failed_title'.tr,
        'profile_delete_error_message'.tr,
        icon: Icons.error_outline,
      );
    } finally {
      isDeletingAccount.value = false;
    }
  }

  Future<void> linkWithGoogle() async {
    if (isLinkingGoogle.value || isLinkingApple.value) return;

    isLinkingGoogle.value = true;
    try {
      final result = await _accountAuthService.connectWithGoogle();
      switch (result.status) {
        case LinkAccountStatus.linked:
          _syncAuthUserState(FirebaseAuth.instance.currentUser);
          _showAppSnackbar(
            'profile_link_success_title'.tr,
            'profile_link_success_message'.trParams({
              'provider': result.providerName,
            }),
            icon: Icons.verified_user_outlined,
          );
          break;
        case LinkAccountStatus.signedInExisting:
          _syncAuthUserState(FirebaseAuth.instance.currentUser);
          _showAppSnackbar(
            'profile_login_success_title'.tr,
            'profile_login_success_message'.trParams({
              'provider': result.providerName,
            }),
            icon: Icons.login,
          );
          break;
        case LinkAccountStatus.cancelled:
          break;
      }
    } on FirebaseAuthException catch (error) {
      _showAuthError(error, fallbackTitle: 'profile_link_google_failed_title');
    } catch (_) {
      _showAppSnackbar(
        'profile_link_google_failed_title'.tr,
        'profile_link_google_failed_message'.tr,
        icon: Icons.error_outline,
      );
    } finally {
      isLinkingGoogle.value = false;
    }
  }

  Future<void> linkWithApple() async {
    if (isLinkingGoogle.value || isLinkingApple.value) return;

    isLinkingApple.value = true;
    try {
      final result = await _accountAuthService.connectWithApple();
      switch (result.status) {
        case LinkAccountStatus.linked:
          _syncAuthUserState(FirebaseAuth.instance.currentUser);
          _showAppSnackbar(
            'profile_link_success_title'.tr,
            'profile_link_success_message'.trParams({
              'provider': result.providerName,
            }),
            icon: Icons.verified_user_outlined,
          );
          break;
        case LinkAccountStatus.signedInExisting:
          _syncAuthUserState(FirebaseAuth.instance.currentUser);
          _showAppSnackbar(
            'profile_login_success_title'.tr,
            'profile_login_success_message'.trParams({
              'provider': result.providerName,
            }),
            icon: Icons.login,
          );
          break;
        case LinkAccountStatus.cancelled:
          break;
      }
    } on FirebaseAuthException catch (error) {
      _showAuthError(
        error,
        fallbackTitle: 'profile_link_apple_failed_title',
        includeErrorCode: true,
      );
    } catch (_) {
      _showAppSnackbar(
        'profile_link_apple_failed_title'.tr,
        'profile_link_apple_failed_message'.tr,
        icon: Icons.error_outline,
      );
    } finally {
      isLinkingApple.value = false;
    }
  }

  void _showAuthError(
    FirebaseAuthException error, {
    required String fallbackTitle,
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

    _showAppSnackbar(
      fallbackTitle.tr,
      displayMessage,
      icon: Icons.error_outline,
    );
  }

  void startLabUpload() {
    pickLabImageFromGallery();
  }

  bool get isSelectedFilePdf {
    final name = selectedLabImageName.value?.toLowerCase().trim();
    if (name == null || name.isEmpty) return false;
    return name.endsWith('.pdf');
  }

  String get _selectedContentType =>
      isSelectedFilePdf ? 'application/pdf' : 'image/*';

  String get selectedFileSizeLabel {
    final size = selectedLabFinalSizeBytes.value;
    if (size == null || size <= 0) return '-';
    final kb = size / 1024;
    return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
  }

  String get selectedOriginalFileSizeLabel {
    final size = selectedLabOriginalSizeBytes.value;
    if (size == null || size <= 0) return '-';
    final kb = size / 1024;
    return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
  }

  void openSampleInsight() {
    _showAppSnackbar(
      'home_sample_insight_title'.tr,
      'home_sample_insight_message'.tr,
      icon: Icons.lightbulb_outline,
    );
  }

  Future<_PreparedDocument?> _preparePickedDocument({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.length <= _maxDocumentBytes) {
      return _PreparedDocument(
        fileName: fileName,
        bytes: bytes,
        originalSizeBytes: bytes.length,
        finalSizeBytes: bytes.length,
        isCompressed: false,
      );
    }

    if (_isPdfFileName(fileName)) {
      _showTooLargeFileMessage();
      return null;
    }

    isPreparingDocument.value = true;
    try {
      final compressedBytes = await _compressImageTo500Kb(bytes);
      if (compressedBytes == null ||
          compressedBytes.length > _maxDocumentBytes) {
        _showTooLargeFileMessage();
        return null;
      }

      return _PreparedDocument(
        fileName: _toJpgFileName(fileName),
        bytes: compressedBytes,
        originalSizeBytes: bytes.length,
        finalSizeBytes: compressedBytes.length,
        isCompressed: true,
      );
    } finally {
      isPreparingDocument.value = false;
    }
  }

  Future<Uint8List?> _compressImageTo500Kb(Uint8List sourceBytes) async {
    const qualityLevels = <int>[90, 80, 70, 60, 50, 40, 30, 20, 15, 10];
    const minSizes = <int>[0, 2200, 1800, 1400, 1100, 900, 700];

    Uint8List? bestAttempt;

    for (final minSize in minSizes) {
      for (final quality in qualityLevels) {
        final compressed = minSize == 0
            ? await FlutterImageCompress.compressWithList(
                sourceBytes,
                quality: quality,
                format: CompressFormat.jpeg,
                keepExif: false,
              )
            : await FlutterImageCompress.compressWithList(
                sourceBytes,
                quality: quality,
                format: CompressFormat.jpeg,
                minWidth: minSize,
                minHeight: minSize,
                keepExif: false,
              );

        if (compressed.isEmpty) continue;

        final candidate = Uint8List.fromList(compressed);
        bestAttempt = candidate;

        if (candidate.length <= _maxDocumentBytes) {
          return candidate;
        }
      }
    }

    return bestAttempt;
  }

  bool _isPdfFileName(String fileName) {
    return fileName.toLowerCase().trim().endsWith('.pdf');
  }

  String _toJpgFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    return '$baseName.jpg';
  }

  void _showTooLargeFileMessage() {
    _showAppSnackbar(
      'home_file_too_large_title'.tr,
      'home_file_too_large_message'.tr,
      icon: Icons.warning_amber_outlined,
    );
  }

  void _showPdfOnlyMessage() {
    _showAppSnackbar(
      'home_pdf_only_title'.tr,
      'home_pdf_only_message'.tr,
      icon: Icons.picture_as_pdf_outlined,
    );
  }

  void _showFilePickerUnavailableMessage() {
    _showAppSnackbar(
      'home_picker_unavailable_title'.tr,
      'home_picker_unavailable_message'.tr,
      icon: Icons.extension_off_outlined,
    );
  }

  void _showPreparingInProgressMessage() {
    _showAppSnackbar(
      'home_preparing_wait_title'.tr,
      'home_preparing_wait_message'.tr,
      icon: Icons.hourglass_top_outlined,
    );
  }
}

class _PreparedDocument {
  const _PreparedDocument({
    required this.fileName,
    required this.bytes,
    required this.originalSizeBytes,
    required this.finalSizeBytes,
    required this.isCompressed,
  });

  final String fileName;
  final Uint8List bytes;
  final int originalSizeBytes;
  final int finalSizeBytes;
  final bool isCompressed;
}

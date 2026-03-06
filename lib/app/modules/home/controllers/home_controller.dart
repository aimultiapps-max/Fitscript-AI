import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/account_auth_service.dart';
import '../../../core/services/lab_analysis_service.dart';
import '../../../routes/app_pages.dart';
import '../views/legal_document_view.dart';

enum LabHistoryStatus { normal, warning, improve }

class LabHistoryItem {
  const LabHistoryItem({
    required this.date,
    required this.title,
    required this.note,
    required this.status,
  });

  final String date;
  final String title;
  final String note;
  final LabHistoryStatus status;
}

class PendingLabAnalysis {
  const PendingLabAnalysis({
    required this.title,
    required this.summary,
    required this.recommendation,
    required this.signals,
    required this.nextSteps,
    required this.status,
  });

  final String title;
  final String summary;
  final String recommendation;
  final List<String> signals;
  final List<String> nextSteps;
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
  final isHistoryLoading = false.obs;
  final analysisHistories = <LabHistoryItem>[].obs;
  final selectedLabImageBytes = Rxn<Uint8List>();
  final selectedLabImageName = RxnString();
  final selectedLabOriginalSizeBytes = RxnInt();
  final selectedLabFinalSizeBytes = RxnInt();
  final isSelectedLabFileCompressed = false.obs;
  final pendingAnalysis = Rxn<PendingLabAnalysis>();
  final currentUser = Rxn<User>();
  final selectedThemeMode = ThemeMode.system.obs;
  final AccountAuthService _accountAuthService;
  final LabAnalysisService _labAnalysisService;
  final ImagePicker _imagePicker;
  static const int _maxDocumentBytes = 500 * 1024;

  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _analysisHistorySubscription;

  Map<String, int> get trialUsage => <String, int>{
    'profile_trial_lab_result_analysis'.tr: 5,
    'profile_trial_save_analysis_result'.tr: 5,
  };

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

  int get totalHistories => analysisHistories.length;

  int get warningCount => analysisHistories
      .where((item) => item.status == LabHistoryStatus.warning)
      .length;

  int get improveCount => analysisHistories
      .where((item) => item.status == LabHistoryStatus.improve)
      .length;

  @override
  void onInit() {
    super.onInit();
    _loadLanguagePreference();
    currentUser.value = FirebaseAuth.instance.currentUser;
    _bindAnalysisHistoryStream(currentUser.value?.uid);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      currentUser.value = user;
      _bindAnalysisHistoryStream(user?.uid);
    });
  }

  @override
  void onClose() {
    _analysisHistorySubscription?.cancel();
    _authSubscription.cancel();
    super.onClose();
  }

  void _bindAnalysisHistoryStream(String? uid) {
    _analysisHistorySubscription?.cancel();

    if (uid == null || uid.isEmpty) {
      analysisHistories.assignAll(const <LabHistoryItem>[]);
      isHistoryLoading.value = false;
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
                .map((doc) => _mapHistoryDocument(doc.data()))
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

  LabHistoryItem _mapHistoryDocument(Map<String, dynamic> data) {
    final title =
        (data['title'] ?? data['testName'] ?? data['analysisTitle'] ?? '')
            .toString()
            .trim();
    final note =
        (data['summary'] ??
                data['analysisSummary'] ??
                data['note'] ??
                data['resultSummary'] ??
                '')
            .toString()
            .trim();

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
      date: _formatDate(date),
      title: title.isNotEmpty ? title : 'history_unknown_title'.tr,
      note: note.isNotEmpty ? note : 'history_unknown_note'.tr,
      status: status,
    );
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

  void changeThemeMode(ThemeMode mode) {
    selectedThemeMode.value = mode;
    Get.changeThemeMode(mode);
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
    Get.snackbar(
      'profile_language_changed'.tr,
      'profile_language_changed_message'.trParams({'language': languageName}),
      snackPosition: SnackPosition.BOTTOM,
    );
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
        Get.snackbar(
          'home_pick_failed_title'.tr,
          'home_pick_failed_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
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
    } catch (_) {
      Get.snackbar(
        'home_pick_failed_title'.tr,
        'home_pick_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
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
    } catch (_) {
      Get.snackbar(
        'home_pick_failed_title'.tr,
        'home_pick_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> analyzeSelectedLabImage() async {
    if (selectedLabImageBytes.value == null) {
      Get.snackbar(
        'home_no_document_title'.tr,
        'home_no_document_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (isPreparingDocument.value) return;
    if (isAnalyzingLabImage.value) return;

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
        status: status,
      );
    } catch (_) {
      Get.snackbar(
        'home_analyze_failed_title'.tr,
        'home_analyze_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isAnalyzingLabImage.value = false;
    }
  }

  Future<void> saveAnalyzedResult() async {
    final user = currentUser.value;
    if (user == null) {
      Get.snackbar(
        'home_save_failed_title'.tr,
        'home_save_failed_no_user'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final analysis = pendingAnalysis.value;
    if (analysis == null) return;
    if (isSavingAnalysis.value) return;

    isSavingAnalysis.value = true;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('analysis_history')
          .add({
            'title': analysis.title,
            'summary': analysis.summary,
            'recommendation': analysis.recommendation,
            'signals': analysis.signals,
            'nextSteps': analysis.nextSteps,
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

      Get.snackbar(
        'home_saved_title'.tr,
        'home_saved_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'home_save_failed_title'.tr,
        'home_save_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSavingAnalysis.value = false;
    }
  }

  void openHistoryDetail(LabHistoryItem history) {
    Get.snackbar(
      'history_snackbar_title'.tr,
      'history_snackbar_message'.trParams({'title': history.title}),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openPrivacyPolicy() async {
    final hasAccepted = await _hasAcceptedConsent('privacy_policy');

    Get.to<bool>(
      () => LegalDocumentView(
        title: 'legal_privacy_title'.tr,
        assetPath: 'assets/jsons/privacy_policy_fitscript_ai.md',
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

  void openTermsAndConditions() async {
    final hasAccepted = await _hasAcceptedConsent('terms_and_conditions');

    Get.to<bool>(
      () => LegalDocumentView(
        title: 'legal_terms_title'.tr,
        assetPath: 'assets/jsons/terms_and_conditions_fitscript_ai.md',
        showAgreementAction: !hasAccepted,
        agreementButtonLabel: 'legal_agree_button'.tr,
      ),
    )?.then((accepted) async {
      if (accepted == true) {
        await _saveConsent(
          docId: 'terms_and_conditions',
          successTitle: 'consent_saved_title'.tr,
          successMessage: 'consent_saved_terms'.tr,
        );
      }
    });
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
      Get.snackbar(
        'consent_failed_title'.tr,
        'consent_failed_no_session'.tr,
        snackPosition: SnackPosition.BOTTOM,
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

      Get.snackbar(
        successTitle,
        successMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'consent_failed_title'.tr,
        'consent_failed_server'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _accountAuthService.signOutToAnonymous();
      Get.offAllNamed(Routes.ONBOARDING);
    } catch (_) {
      Get.snackbar(
        'profile_sign_out_failed_title'.tr,
        'profile_sign_out_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void upgradeToPremium() {
    Get.snackbar(
      'profile_upgrade_info_title'.tr,
      'profile_upgrade_info_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void restorePurchases() {
    Get.snackbar(
      'profile_restore_info_title'.tr,
      'profile_restore_info_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> deleteAccount() async {
    if (isDeletingAccount.value) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('profile_delete_title'.tr),
        content: Text('profile_delete_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('profile_cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
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
          Get.snackbar(
            'profile_delete_success_title'.tr,
            'profile_delete_success_message'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAllNamed(Routes.ONBOARDING);
          return;
        case DeleteAccountStatus.requiresRecentLogin:
          Get.snackbar(
            'profile_delete_recent_login_title'.tr,
            'profile_delete_recent_login_message'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        case DeleteAccountStatus.cancelled:
          Get.snackbar(
            'profile_delete_cancelled_title'.tr,
            'profile_delete_cancelled_message'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        case DeleteAccountStatus.failed:
          final detail = (result.errorCode ?? '').trim();
          Get.snackbar(
            'profile_delete_failed_title'.tr,
            detail.isNotEmpty
                ? 'profile_delete_failed_message_with_code'.trParams({
                    'code': detail,
                  })
                : 'profile_delete_failed_message'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
      }
    } catch (_) {
      Get.snackbar(
        'profile_delete_failed_title'.tr,
        'profile_delete_error_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
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
          Get.snackbar(
            'profile_link_success_title'.tr,
            'profile_link_success_message'.trParams({
              'provider': result.providerName,
            }),
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        case LinkAccountStatus.signedInExisting:
          Get.snackbar(
            'profile_login_success_title'.tr,
            'profile_login_success_message'.trParams({
              'provider': result.providerName,
            }),
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        case LinkAccountStatus.cancelled:
          break;
      }
    } on FirebaseAuthException catch (error) {
      _showAuthError(error, fallbackTitle: 'profile_link_google_failed_title');
    } catch (_) {
      Get.snackbar(
        'profile_link_google_failed_title'.tr,
        'profile_link_google_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
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
          Get.snackbar(
            'profile_link_success_title'.tr,
            'profile_link_success_message'.trParams({
              'provider': result.providerName,
            }),
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        case LinkAccountStatus.signedInExisting:
          Get.snackbar(
            'profile_login_success_title'.tr,
            'profile_login_success_message'.trParams({
              'provider': result.providerName,
            }),
            snackPosition: SnackPosition.BOTTOM,
          );
          break;
        case LinkAccountStatus.cancelled:
          break;
      }
    } on FirebaseAuthException catch (error) {
      _showAuthError(error, fallbackTitle: 'profile_link_apple_failed_title');
    } catch (_) {
      Get.snackbar(
        'profile_link_apple_failed_title'.tr,
        'profile_link_apple_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLinkingApple.value = false;
    }
  }

  void _showAuthError(
    FirebaseAuthException error, {
    required String fallbackTitle,
  }) {
    final message = switch (error.code) {
      'account-exists-with-different-credential' =>
        'profile_auth_error_different_credential'.tr,
      'invalid-credential' => 'profile_auth_error_invalid_credential'.tr,
      _ => 'profile_auth_error_generic'.tr,
    };

    Get.snackbar(
      fallbackTitle.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
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
    Get.snackbar(
      'home_sample_insight_title'.tr,
      'home_sample_insight_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
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
    Get.snackbar(
      'home_file_too_large_title'.tr,
      'home_file_too_large_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showPdfOnlyMessage() {
    Get.snackbar(
      'home_pdf_only_title'.tr,
      'home_pdf_only_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showFilePickerUnavailableMessage() {
    Get.snackbar(
      'home_picker_unavailable_title'.tr,
      'home_picker_unavailable_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showPreparingInProgressMessage() {
    Get.snackbar(
      'home_preparing_wait_title'.tr,
      'home_preparing_wait_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
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

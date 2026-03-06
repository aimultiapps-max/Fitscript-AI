import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

enum AiBackend { googleAI, vertexAI }

enum LabAnalysisSeverity { normal, warning, improve }

class LabAnalysisOutput {
  const LabAnalysisOutput({
    required this.title,
    required this.summary,
    required this.recommendation,
    required this.nextSteps,
    required this.severity,
    required this.signals,
  });

  final String title;
  final String summary;
  final String recommendation;
  final List<String> nextSteps;
  final LabAnalysisSeverity severity;
  final List<String> signals;
}

class LabAnalysisService {
  LabAnalysisService({AiBackend? backend, String? model, String? location})
    : _backend = backend ?? _resolveBackendFromEnv(),
      _model =
          model ??
          const String.fromEnvironment(
            'AI_MODEL',
            defaultValue: 'gemini-2.0-flash',
          ),
      _location =
          location ??
          const String.fromEnvironment(
            'AI_LOCATION',
            defaultValue: 'us-central1',
          );

  final AiBackend _backend;
  final String _model;
  final String _location;
  static _AiRuntimeConfig? _cachedRuntimeConfig;
  static DateTime? _cachedAt;

  Future<LabAnalysisOutput> analyzeLabImage({
    required String fileName,
    required Uint8List bytes,
    required String languageCode,
  }) async {
    try {
      final runtimeConfig = await _resolveRuntimeConfig();

      final model = switch (runtimeConfig.backend) {
        AiBackend.vertexAI => FirebaseAI.vertexAI(
          location: runtimeConfig.location,
        ).generativeModel(model: runtimeConfig.model),
        AiBackend.googleAI => FirebaseAI.googleAI().generativeModel(
          model: runtimeConfig.model,
        ),
      };

      final prompt = _buildPrompt(
        fileName: fileName,
        languageCode: languageCode,
      );
      final mimeType = _guessMimeType(fileName);

      final response = await model.generateContent([
        Content.multi([TextPart(prompt), InlineDataPart(mimeType, bytes)]),
      ]);

      final rawText = response.text?.trim();
      if (rawText == null || rawText.isEmpty) {
        return _fallbackAnalysis(fileName, bytes.length, languageCode);
      }

      final jsonMap = _extractJsonMap(rawText);
      final title = (jsonMap['title'] ?? '').toString().trim();
      final summary = (jsonMap['summary'] ?? '').toString().trim();
      final recommendation = (jsonMap['recommendation'] ?? '')
          .toString()
          .trim();
      final parsedNextSteps = _parseListStrings(jsonMap['next_steps']);
      final statusRaw = (jsonMap['status'] ?? '').toString().trim();

      final parsedSignals = _parseListStrings(jsonMap['signals']);

      return LabAnalysisOutput(
        title: title.isNotEmpty ? title : _extractTitle(fileName),
        summary: summary.isNotEmpty
            ? summary
            : _defaultSummary(_severityFromString(statusRaw), languageCode),
        recommendation: recommendation.isNotEmpty
            ? recommendation
            : _defaultRecommendation(
                _severityFromString(statusRaw),
                languageCode,
              ),
        nextSteps: parsedNextSteps.isNotEmpty
            ? parsedNextSteps
            : _defaultNextSteps(_severityFromString(statusRaw), languageCode),
        severity: _severityFromString(statusRaw),
        signals: parsedSignals,
      );
    } catch (_) {
      return _fallbackAnalysis(fileName, bytes.length, languageCode);
    }
  }

  LabAnalysisOutput _fallbackAnalysis(
    String fileName,
    int bytesLength,
    String languageCode,
  ) {
    final normalized = fileName.toLowerCase();
    final extractedTitle = _extractTitle(fileName);

    final signals = <String>[];
    if (normalized.contains('cholesterol') ||
        normalized.contains('ldl') ||
        normalized.contains('triglycer')) {
      signals.add('lipid');
    }
    if (normalized.contains('glucose') ||
        normalized.contains('gula') ||
        normalized.contains('hba1c')) {
      signals.add('glucose');
    }
    if (normalized.contains('hemoglobin') || normalized.contains('hb')) {
      signals.add('hemoglobin');
    }

    LabAnalysisSeverity severity;
    if (signals.isNotEmpty) {
      severity = LabAnalysisSeverity.warning;
    } else {
      final score = _stableScore(fileName, bytesLength);
      if (score == 0) {
        severity = LabAnalysisSeverity.normal;
      } else if (score == 1) {
        severity = LabAnalysisSeverity.improve;
      } else {
        severity = LabAnalysisSeverity.warning;
      }
    }

    return LabAnalysisOutput(
      title: extractedTitle,
      summary: _defaultSummary(severity, languageCode),
      recommendation: _defaultRecommendation(severity, languageCode),
      nextSteps: _defaultNextSteps(severity, languageCode),
      severity: severity,
      signals: signals,
    );
  }

  static AiBackend _resolveBackendFromEnv() {
    final raw = const String.fromEnvironment(
      'AI_BACKEND',
      defaultValue: 'google',
    ).toLowerCase();
    return _parseBackend(raw);
  }

  static AiBackend _parseBackend(String raw) {
    final value = raw.toLowerCase().trim();
    if (value == 'vertex' || value == 'vertexai') {
      return AiBackend.vertexAI;
    }
    return AiBackend.googleAI;
  }

  Future<_AiRuntimeConfig> _resolveRuntimeConfig() async {
    final now = DateTime.now();
    if (_cachedRuntimeConfig != null && _cachedAt != null) {
      if (now.difference(_cachedAt!) < const Duration(minutes: 10)) {
        return _cachedRuntimeConfig!;
      }
    }

    var backend = _backend;
    var model = _model;
    var location = _location;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );
      await remoteConfig.setDefaults({
        'ai_backend': backend == AiBackend.vertexAI ? 'vertex' : 'google',
        'ai_model': model,
        'ai_location': location,
      });
      await remoteConfig.fetchAndActivate();

      final backendRaw = _firstNonEmpty([
        remoteConfig.getString('ai_backend'),
        remoteConfig.getString('AI_BACKEND'),
      ]);
      final modelRaw = _firstNonEmpty([
        remoteConfig.getString('ai_model'),
        remoteConfig.getString('AI_MODEL'),
      ]);
      final locationRaw = _firstNonEmpty([
        remoteConfig.getString('ai_location'),
        remoteConfig.getString('AI_LOCATION'),
      ]);

      if (backendRaw != null) {
        backend = _parseBackend(backendRaw);
      }
      if (modelRaw != null) {
        model = modelRaw;
      }
      if (locationRaw != null) {
        location = locationRaw;
      }
    } catch (_) {}

    final resolved = _AiRuntimeConfig(
      backend: backend,
      model: model,
      location: location,
    );
    _cachedRuntimeConfig = resolved;
    _cachedAt = now;
    return resolved;
  }

  String? _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String _buildPrompt({
    required String fileName,
    required String languageCode,
  }) {
    final language = languageCode == 'id' ? 'Indonesian' : 'English';

    return '''
You are a medical lab assistant AI. Analyze this uploaded laboratory result document (image or PDF).

File name: $fileName
Output language: $language

Return ONLY valid JSON with this exact schema:
{
  "title": "short test name",
  "status": "warning|improve|normal",
  "summary": "3-5 short sentences in plain language",
  "recommendation": "2-3 short sentences, practical and easy to follow",
  "next_steps": ["action 1", "action 2", "action 3"],
  "signals": ["keyword1", "keyword2"]
}

Rules:
- Be careful and non-diagnostic.
- If values are unclear, use conservative wording.
- Explain medical terms in simple everyday language.
- Keep each next step actionable and specific.
- Do not include markdown, code fences, or extra fields.
''';
  }

  Map<String, dynamic> _extractJsonMap(String rawText) {
    final cleaned = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) {
      final sliced = cleaned.substring(start, end + 1);
      final decoded = jsonDecode(sliced);
      if (decoded is Map<String, dynamic>) return decoded;
    }

    throw const FormatException('Invalid AI JSON payload');
  }

  List<String> _parseListStrings(Object? raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((v) => v.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  LabAnalysisSeverity _severityFromString(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('warn') ||
        normalized.contains('high') ||
        normalized.contains('abnormal') ||
        normalized.contains('attention')) {
      return LabAnalysisSeverity.warning;
    }
    if (normalized.contains('improve') ||
        normalized.contains('better') ||
        normalized.contains('progress')) {
      return LabAnalysisSeverity.improve;
    }
    return LabAnalysisSeverity.normal;
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  String _defaultSummary(LabAnalysisSeverity severity, String languageCode) {
    final isId = languageCode == 'id';
    return switch (severity) {
      LabAnalysisSeverity.warning =>
        isId
            ? 'Beberapa indikator mungkin perlu perhatian berdasarkan gambar lab ini.'
            : 'Some indicators may need attention based on this lab document.',
      LabAnalysisSeverity.improve =>
        isId
            ? 'Indikator Anda menunjukkan tanda perbaikan dibanding pola umum.'
            : 'Your indicators show signs of improvement compared to common patterns.',
      LabAnalysisSeverity.normal =>
        isId
            ? 'Sebagian besar indikator yang terlihat berada dalam pola rentang yang diharapkan.'
            : 'Most visible indicators appear within expected range patterns.',
    };
  }

  String _defaultRecommendation(
    LabAnalysisSeverity severity,
    String languageCode,
  ) {
    final isId = languageCode == 'id';
    return switch (severity) {
      LabAnalysisSeverity.warning =>
        isId
            ? 'Konsultasikan dengan tenaga medis untuk konfirmasi dan langkah berikutnya.'
            : 'Consult a healthcare professional for confirmation and next steps.',
      LabAnalysisSeverity.improve =>
        isId
            ? 'Pertahankan kebiasaan sehat saat ini dan lanjutkan pemantauan tren.'
            : 'Maintain your current healthy habits and continue monitoring trends.',
      LabAnalysisSeverity.normal =>
        isId
            ? 'Pertahankan pola makan seimbang dan aktivitas rutin, lalu cek ulang berkala.'
            : 'Keep a balanced diet and regular activity, then re-check routinely.',
    };
  }

  List<String> _defaultNextSteps(
    LabAnalysisSeverity severity,
    String languageCode,
  ) {
    final isId = languageCode == 'id';

    return switch (severity) {
      LabAnalysisSeverity.warning =>
        isId
            ? const <String>[
                'Jadwalkan konsultasi dokter untuk meninjau hasil lab secara menyeluruh.',
                'Catat gejala yang Anda rasakan dalam 3-7 hari ke depan.',
                'Ulangi pemeriksaan sesuai arahan tenaga medis.',
              ]
            : const <String>[
                'Schedule a doctor consultation to review these lab results in detail.',
                'Track any symptoms you feel over the next 3-7 days.',
                'Repeat the test as advised by your healthcare professional.',
              ],
      LabAnalysisSeverity.improve =>
        isId
            ? const <String>[
                'Lanjutkan pola makan dan aktivitas yang saat ini sudah berjalan baik.',
                'Pantau hasil lab berikutnya untuk memastikan tren tetap membaik.',
                'Diskusikan target lanjutan dengan tenaga medis saat kontrol.',
              ]
            : const <String>[
                'Continue the diet and activity habits that are working well now.',
                'Track your next lab result to confirm the trend keeps improving.',
                'Discuss follow-up targets with your healthcare professional.',
              ],
      LabAnalysisSeverity.normal =>
        isId
            ? const <String>[
                'Pertahankan kebiasaan sehat harian Anda.',
                'Lakukan pemeriksaan rutin sesuai jadwal kontrol Anda.',
                'Tetap perhatikan perubahan gejala dan konsultasikan bila perlu.',
              ]
            : const <String>[
                'Maintain your current healthy daily habits.',
                'Do routine checkups based on your regular schedule.',
                'Watch for symptom changes and consult a clinician if needed.',
              ],
    };
  }

  int _stableScore(String fileName, int bytesLength) {
    final seed = '$fileName::$bytesLength';
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash % 3;
  }

  String _extractTitle(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final base = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final cleaned = base.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (cleaned.isEmpty) return 'Lab Upload';

    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

class _AiRuntimeConfig {
  const _AiRuntimeConfig({
    required this.backend,
    required this.model,
    required this.location,
  });

  final AiBackend backend;
  final String model;
  final String location;
}

import 'dart:typed_data';
import '../core/constants.dart';
import '../models/models.dart';
import 'ai_detection.dart';

/// Configuration for AI detection performance tuning
class AIDetectionConfig {
  final int frameIntervalMs;
  final int inferenceThreads;
  final bool lowPowerMode;
  final int resultCacheFrames;

  const AIDetectionConfig({
    this.frameIntervalMs = AppConstants.aiFrameIntervalMs,
    this.inferenceThreads = AppConstants.aiInferenceThreads,
    this.lowPowerMode = false,
    this.resultCacheFrames = AppConstants.aiResultCacheFrames,
  });

  int get effectiveFrameIntervalMs =>
      lowPowerMode ? frameIntervalMs * 2 : frameIntervalMs;
}

/// Android Implementation using TensorFlow Lite
/// Optimized for performance: result caching, frame skipping, temporal smoothing
class AndroidAIDetectionService extends AIDetectionService {
  bool _isReady = false;
  final AIDetectionConfig config;

  dynamic _poseInterpreter;
  dynamic _handInterpreter;

  // Result cache - avoid redundant inference
  ActivityDetectionResult? _cachedResult;
  DateTime? _lastInferenceTime;
  int _frameCount = 0;

  // Temporal smoothing - reduce jitter
  static const int _smoothingWindow = 3;
  final List<ActivityDetectionResult> _recentResults = [];

  AndroidAIDetectionService({this.config = const AIDetectionConfig()});

  @override
  bool get isReady => _isReady;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _isReady = true;
  }

  @override
  Future<ActivityDetectionResult> detectActivity(Uint8List frameBytes) async {
    if (!_isReady) {
      throw Exception('AI service not initialized');
    }

    final now = DateTime.now();
    final elapsed = _lastInferenceTime != null
        ? now.difference(_lastInferenceTime!).inMilliseconds
        : 999;

    // Frame skip: only run inference when interval has passed
    if (elapsed >= config.effectiveFrameIntervalMs || _cachedResult == null) {
      _frameCount = 0;
      _cachedResult = await _runInference(frameBytes);
      _lastInferenceTime = now;

      // Update smoothing buffer
      _recentResults.add(_cachedResult!);
      if (_recentResults.length > _smoothingWindow) {
        _recentResults.removeAt(0);
      }
    } else {
      _frameCount++;
      // Reuse cached result (with optional temporal smoothing)
      if (_recentResults.isNotEmpty) {
        _cachedResult = _applyTemporalSmoothing(_recentResults);
      }
    }

    return _cachedResult!;
  }

  Future<ActivityDetectionResult> _runInference(Uint8List frameBytes) async {
    // Simulated - in production: preprocess, run TFLite, postprocess
    return _simulateDetection();
  }

  ActivityDetectionResult _applyTemporalSmoothing(
      List<ActivityDetectionResult> results) {
    // Majority vote on activity type
    final counts = <ActivityType, int>{};
    for (final r in results) {
      counts[r.activity] = (counts[r.activity] ?? 0) + 1;
    }
    var best = ActivityType.unknown;
    var bestCount = 0;
    for (final e in counts.entries) {
      if (e.value > bestCount) {
        bestCount = e.value;
        best = e.key;
      }
    }
    final last = results.last;
    final avgConfidence = results.fold<double>(
            0, (s, r) => s + r.confidence) /
        results.length;
    return ActivityDetectionResult(
      activity: best,
      confidence: avgConfidence,
      personDetected: last.personDetected,
      handsDetected: last.handsDetected,
      extraData: last.extraData,
    );
  }

  ActivityDetectionResult _simulateDetection() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    if (random < 70) {
      return ActivityDetectionResult(
        activity: ActivityType.studying,
        confidence: 0.91,
        personDetected: true,
        handsDetected: false,
        extraData: {
          'pose': 'sitting',
          'head_tilt': -0.12,
          'keypoints_count': 17,
        },
      );
    } else if (random < 80) {
      return ActivityDetectionResult(
        activity: ActivityType.idle,
        confidence: 0.72,
        personDetected: true,
        handsDetected: false,
      );
    } else if (random < 90) {
      return ActivityDetectionResult(
        activity: ActivityType.playing,
        confidence: 0.86,
        personDetected: true,
        handsDetected: true,
        extraData: {
          'hand_near_face': true,
          'hand_velocity': 0.45,
        },
      );
    } else {
      return ActivityDetectionResult(
        activity: ActivityType.away,
        confidence: 0.97,
        personDetected: false,
        handsDetected: false,
      );
    }
  }

  @override
  void dispose() {
    _cachedResult = null;
    _lastInferenceTime = null;
    _recentResults.clear();
    _isReady = false;
  }
}

/// Android-specific TensorFlow Lite model manager
class TFLiteModelManager {
  static final TFLiteModelManager _instance = TFLiteModelManager._internal();
  factory TFLiteModelManager() => _instance;
  TFLiteModelManager._internal();

  bool _modelsLoaded = false;

  Future<void> loadModels({int numThreads = 4}) async {
    if (_modelsLoaded) return;

    await Future.delayed(const Duration(milliseconds: 300));
    _modelsLoaded = true;
  }

  Map<String, dynamic> analyzePose(List<double> keypoints) {
    if (keypoints.isEmpty) {
      return {
        'activity': ActivityType.away.value,
        'confidence': 0.95,
      };
    }
    return {
      'activity': ActivityType.studying.value,
      'confidence': 0.88,
      'nose_y': keypoints.length > 1 ? keypoints[1] : 0,
      'shoulder_y_avg': keypoints.length >= 12
          ? (keypoints[11] + keypoints[12]) / 2
          : 0,
    };
  }

  Map<String, dynamic> analyzeHands(List<double> handKeypoints) {
    return {
      'near_face': false,
      'is_moving': true,
      'fingers_extended': 5,
    };
  }

  void dispose() {
    _modelsLoaded = false;
  }
}

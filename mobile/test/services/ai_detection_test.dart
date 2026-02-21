import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework_guardian/models/models.dart';
import 'package:homework_guardian/services/ai_detection.dart';
import 'package:homework_guardian/services/android_ai_detection.dart';

void main() {
  group('ActivityDetectionResult', () {
    test('needsServerAnalysis when confidence < 0.9', () {
      final r = ActivityDetectionResult(
        activity: ActivityType.studying,
        confidence: 0.85,
        personDetected: true,
        handsDetected: false,
      );
      expect(r.needsServerAnalysis, true);
    });

    test('needsServerAnalysis when confidence >= 0.9', () {
      final r = ActivityDetectionResult(
        activity: ActivityType.studying,
        confidence: 0.92,
        personDetected: true,
        handsDetected: false,
      );
      expect(r.needsServerAnalysis, false);
    });
  });

  group('AndroidAIDetectionService', () {
    late AndroidAIDetectionService service;

    setUp(() async {
      service = AndroidAIDetectionService();
      await service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes and is ready', () {
      expect(service.isReady, true);
    });

    test('detectActivity returns valid result', () async {
      final bytes = Uint8List.fromList(List.filled(100, 0));
      final result = await service.detectActivity(bytes);
      expect(result.activity, isNotNull);
      expect(result.confidence, greaterThanOrEqualTo(0));
      expect(result.confidence, lessThanOrEqualTo(1));
    });

    test('detectActivity throws when not initialized', () async {
      final notInitialized = AndroidAIDetectionService();
      final bytes = Uint8List.fromList(List.filled(100, 0));
      expect(notInitialized.detectActivity(bytes), throwsException);
    });
  });

  group('TFLiteModelManager', () {
    test('analyzePose handles empty keypoints', () {
      final manager = TFLiteModelManager();
      final result = manager.analyzePose([]);
      expect(result['activity'], 'away');
      expect(result['confidence'], 0.95);
    });

    test('analyzePose handles valid keypoints', () {
      final manager = TFLiteModelManager();
      final keypoints = List.filled(17 * 3, 0.5);
      final result = manager.analyzePose(keypoints);
      expect(result['activity'], 'studying');
      expect(result['confidence'], 0.88);
    });

    test('analyzeHands returns expected structure', () {
      final manager = TFLiteModelManager();
      final result = manager.analyzeHands([]);
      expect(result['near_face'], false);
      expect(result['is_moving'], true);
    });
  });
}

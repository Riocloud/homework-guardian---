import 'package:flutter_test/flutter_test.dart';
import 'package:homework_guardian/core/constants.dart';

void main() {
  group('AppConstants', () {
    test('defaultServerUrl is valid', () {
      expect(AppConstants.defaultServerUrl, contains('http'));
    });

    test('AI performance constants are positive', () {
      expect(AppConstants.aiFrameIntervalMs, greaterThan(0));
      expect(AppConstants.aiInferenceThreads, greaterThan(0));
      expect(AppConstants.aiResultCacheFrames, greaterThan(0));
    });

    test('alert thresholds are reasonable', () {
      expect(AppConstants.defaultLeaveThresholdMinutes, inInclusiveRange(1, 60));
      expect(AppConstants.defaultPlayThresholdMinutes, inInclusiveRange(1, 30));
    });
  });
}

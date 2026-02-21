import 'package:flutter_test/flutter_test.dart';
import 'package:homework_guardian/services/settings_service.dart';

void main() {
  group('SettingsService', () {
    late SettingsService service;

    setUp(() {
      service = SettingsService();
    });

    test('default child name is 小明', () {
      expect(service.childName, '小明');
    });

    test('default pushNotifications is true', () {
      expect(service.pushNotifications, true);
    });

    test('default autoSync is true', () {
      expect(service.autoSync, true);
    });

    test('default AI config has valid values', () {
      expect(service.aiFrameIntervalMs, greaterThan(0));
      expect(service.aiInferenceThreads, greaterThan(0));
    });

    test('toAlertConfig creates valid config', () {
      final config = service.toAlertConfig();
      expect(config.childId, service.childId);
      expect(config.email, service.emailAddress);
      expect(config.leaveThresholdMinutes, service.leaveThresholdMinutes);
    });
  });
}

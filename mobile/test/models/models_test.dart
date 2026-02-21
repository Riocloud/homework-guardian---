import 'package:flutter_test/flutter_test.dart';
import 'package:homework_guardian/models/models.dart';

void main() {
  group('ActivityType', () {
    test('value returns correct string', () {
      expect(ActivityType.studying.value, 'studying');
      expect(ActivityType.away.value, 'away');
      expect(ActivityType.playing.value, 'playing');
    });

    test('displayName returns Chinese label', () {
      expect(ActivityType.studying.displayName, '学习中');
      expect(ActivityType.away.displayName, '离开');
    });

    test('fromString parses correctly', () {
      expect(ActivityTypeExtension.fromString('studying'), ActivityType.studying);
      expect(ActivityTypeExtension.fromString('unknown'), ActivityType.unknown);
    });
  });

  group('ActivityRecord', () {
    test('toJson and fromJson roundtrip', () {
      final record = ActivityRecord(
        sessionId: 's1',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        activity: ActivityType.studying,
        confidence: 0.9,
        durationSeconds: 60,
        tags: ['tag1'],
        uploaded: true,
      );
      final json = record.toJson();
      final restored = ActivityRecord.fromJson(json);
      expect(restored.sessionId, record.sessionId);
      expect(restored.activity, record.activity);
      expect(restored.confidence, record.confidence);
      expect(restored.uploaded, record.uploaded);
    });
  });

  group('MonitoringSession', () {
    test('totalDurationSeconds calculates correctly', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final session = MonitoringSession(
        id: 's1',
        childId: 'c1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        isActive: false,
      );
      expect(session.totalDurationSeconds, 1800);
    });

    test('studyDurationSeconds sums studying activities', () {
      final session = MonitoringSession(
        id: 's1',
        childId: 'c1',
        startTime: DateTime.now(),
        activities: [
          ActivityRecord(
            sessionId: 's1',
            timestamp: DateTime.now(),
            activity: ActivityType.studying,
            confidence: 0.9,
            durationSeconds: 60,
          ),
          ActivityRecord(
            sessionId: 's1',
            timestamp: DateTime.now(),
            activity: ActivityType.away,
            confidence: 0.9,
            durationSeconds: 30,
          ),
        ],
      );
      expect(session.studyDurationSeconds, 60);
    });

    test('focusScore calculates from study/total ratio', () {
      final session = MonitoringSession(
        id: 's1',
        childId: 'c1',
        startTime: DateTime.now(),
        activities: [
          ActivityRecord(
            sessionId: 's1',
            timestamp: DateTime.now(),
            activity: ActivityType.studying,
            confidence: 0.9,
            durationSeconds: 50,
          ),
          ActivityRecord(
            sessionId: 's1',
            timestamp: DateTime.now(),
            activity: ActivityType.away,
            confidence: 0.9,
            durationSeconds: 50,
          ),
        ],
      );
      expect(session.focusScore, closeTo(50.0, 0.1));
    });
  });

  group('AlertConfig', () {
    test('toJson and fromJson roundtrip', () {
      final config = AlertConfig(
        childId: 'c1',
        email: 'test@example.com',
        leaveThresholdMinutes: 20,
        playWhileWorkThresholdMinutes: 10,
        enableEmail: false,
        enableSound: true,
      );
      final json = config.toJson();
      final restored = AlertConfig.fromJson(json);
      expect(restored.childId, config.childId);
      expect(restored.email, config.email);
      expect(restored.leaveThresholdMinutes, 20);
      expect(restored.enableEmail, false);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:homework_guardian/services/upload_service.dart';
import 'package:homework_guardian/models/models.dart';

void main() {
  group('SyncResult', () {
    test('creates with success true', () {
      final result = SyncResult(
        success: true,
        message: '全部同步成功',
        uploadedCount: 5,
        failedCount: 0,
      );
      expect(result.success, true);
      expect(result.uploadedCount, 5);
      expect(result.failedCount, 0);
    });

    test('creates with partial failure', () {
      final result = SyncResult(
        success: false,
        message: '部分失败',
        uploadedCount: 3,
        failedCount: 2,
      );
      expect(result.success, false);
      expect(result.uploadedCount, 3);
      expect(result.failedCount, 2);
    });

    test('success is false when failedCount > 0', () {
      final result = SyncResult(
        success: false,
        message: '部分失败',
        uploadedCount: 10,
        failedCount: 1,
      );
      expect(result.success, false);
    });
  });

  group('ActivityRecord toJson for upload', () {
    test('toJson produces valid structure for API', () {
      final record = ActivityRecord(
        sessionId: 's1',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        activity: ActivityType.studying,
        confidence: 0.92,
        durationSeconds: 120,
        tags: ['focused'],
        uploaded: false,
      );
      final json = record.toJson();

      expect(json['session_id'], 's1');
      expect(json['activity'], 'studying');
      expect(json['confidence'], 0.92);
      expect(json['duration_seconds'], 120);
      expect(json['uploaded'], false);
    });
  });
}

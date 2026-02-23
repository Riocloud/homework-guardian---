import 'package:flutter_test/flutter_test.dart';
import 'package:homework_guardian/core/app_state.dart';

void main() {
  group('AppState', () {
    late AppState state;

    setUp(() {
      state = AppState();
    });

    test('initial isMonitoring is false', () {
      expect(state.isMonitoring, false);
    });

    test('initial currentStatus is 等待开始', () {
      expect(state.currentStatus, '等待开始');
    });

    test('initial studyMinutes is 0', () {
      expect(state.studyMinutes, 0);
    });

    test('initial focusScore is 0', () {
      expect(state.focusScore, 0);
    });

    test('initial isSyncing is false', () {
      expect(state.isSyncing, false);
    });

    test('initial syncProgress is 0', () {
      expect(state.syncProgress, 0);
    });

    test('initial todayActivities is empty', () {
      expect(state.todayActivities, isEmpty);
    });

    test('initial currentSession is null', () {
      expect(state.currentSession, isNull);
    });
  });
}

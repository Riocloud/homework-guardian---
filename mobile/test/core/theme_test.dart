import 'package:flutter_test/flutter_test.dart';
import 'package:homework_guardian/core/theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme uses Material 3', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, true);
    });

    test('darkTheme uses Material 3', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, true);
    });

    test('getStatusColor returns correct colors', () {
      expect(AppTheme.getStatusColor('学习中'), AppTheme.studyingColor);
      expect(AppTheme.getStatusColor('studying'), AppTheme.studyingColor);
      expect(AppTheme.getStatusColor('离开'), AppTheme.awayColor);
      expect(AppTheme.getStatusColor('away'), AppTheme.awayColor);
      expect(AppTheme.getStatusColor('unknown'), AppTheme.idleColor);
    });
  });
}

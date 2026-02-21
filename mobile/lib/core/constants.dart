// App Constants
class AppConstants {
  // API
  static const String defaultServerUrl = 'http://192.168.1.100:8000';
  
  // Alert thresholds
  static const int defaultLeaveThresholdMinutes = 15;
  static const int defaultPlayThresholdMinutes = 5;
  
  // Video settings
  static const int defaultVideoWidth = 1280;
  static const int defaultFps = 15;
  
  // Sync settings
  static const int syncIntervalMinutes = 5;
  
  // Storage
  static const int maxRetryAttempts = 3;
  static const int dataRetentionDays = 30;
}

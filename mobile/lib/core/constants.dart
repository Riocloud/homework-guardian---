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

  // AI detection performance
  static const int aiFrameIntervalMs = 500; // Run detection every 500ms
  static const int aiInferenceThreads = 4;
  static const int aiResultCacheFrames = 3; // Reuse result for N skipped frames

  // Storage
  static const int maxRetryAttempts = 3;
  static const int dataRetentionDays = 30;
}

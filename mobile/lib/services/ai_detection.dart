import 'dart:typed_data';
import '../models/models.dart';

/// Abstract interface for AI detection
/// Implemented differently on iOS (CoreML) and Android (TFLite)
abstract class AIDetectionService {
  /// Initialize the AI model
  Future<void> initialize();
  
  /// Check if model is loaded
  bool get isReady;
  
  /// Detect activity from camera frame
  /// Returns detected activity type and confidence
  Future<ActivityDetectionResult> detectActivity(Uint8List frameBytes);
  
  /// Release resources
  void dispose();
}

/// Result of activity detection
class ActivityDetectionResult {
  final ActivityType activity;
  final double confidence;
  final bool personDetected;
  final bool handsDetected;
  final Map<String, dynamic> extraData;
  
  ActivityDetectionResult({
    required this.activity,
    required this.confidence,
    required this.personDetected,
    required this.handsDetected,
    this.extraData = const {},
  });
  
  bool get needsServerAnalysis => confidence < 0.9;
}

/// Platform-specific factory
class AIDetectionFactory {
  static AIDetectionService create() {
    // Platform detection will be done at runtime
    // For now, return the platform-specific implementation
    throw UnimplementedError('Use AIDetectionFactory.create() with platform check');
  }
}

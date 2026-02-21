import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'ai_detection.dart';
import 'video_service.dart';
import 'api_client.dart';

/// Core monitoring session manager
/// Manages the entire monitoring workflow
class SessionManager {
  final AIDetectionService _aiService;
  final VideoService _videoService;
  final ApiClient _apiClient;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  MonitoringSession? _currentSession;
  Timer? _activityTimer;
  Timer? _uploadTimer;
  
  // Activity tracking
  final List<ActivityRecord> _pendingActivities = [];
  ActivityType _currentActivity = ActivityType.unknown;
  DateTime? _activityStartTime;
  
  // Configuration
  AlertConfig? _alertConfig;
  bool _isMonitoring = false;
  
  // Callbacks
  Function(ActivityType, double)? onActivityDetected;
  Function(String)? onAlertTriggered;
  Function(MonitoringSession)? onSessionUpdated;
  
  SessionManager({
    required AIDetectionService aiService,
    required VideoService videoService,
    required ApiClient apiClient,
  })  : _aiService = aiService,
        _videoService = videoService,
        _apiClient = apiClient;
  
  bool get isMonitoring => _isMonitoring;
  MonitoringSession? get currentSession => _currentSession;
  
  /// Initialize the session manager
  Future<void> initialize() async {
    // Initialize AI service
    await _aiService.initialize();
    
    // Get available cameras
    _cameras = await availableCameras();
    
    // Initialize camera
    if (_cameras != null && _cameras!.isNotEmpty) {
      await _initializeCamera(_cameras!.first);
    }
  }
  
  Future<void> _initializeCamera(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium, // 640x480 for AI processing
      enableAudio: false,
    );
    
    await _cameraController!.initialize();
  }
  
  /// Start a new monitoring session
  Future<void> startSession({
    required String childId,
    AlertConfig? config,
  }) async {
    if (_isMonitoring) return;
    
    _alertConfig = config;
    
    // Create new session
    _currentSession = MonitoringSession(
      id: const Uuid().v4(),
      childId: childId,
      startTime: DateTime.now(),
      isActive: true,
    );
    
    _isMonitoring = true;
    _pendingActivities.clear();
    
    // Start activity detection loop
    _startActivityDetection();
    
    // Start periodic upload
    _startPeriodicUpload();
    
    onSessionUpdated?.call(_currentSession!);
  }
  
  /// Stop the current session
  Future<void> stopSession() async {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    
    // Stop timers
    _activityTimer?.cancel();
    _uploadTimer?.cancel();
    
    // Final upload
    await _uploadPendingActivities();
    
    // Update session
    if (_currentSession != null) {
      _currentSession = MonitoringSession(
        id: _currentSession!.id,
        childId: _currentSession!.childId,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        isActive: false,
        activities: _currentSession!.activities,
      );
      
      onSessionUpdated?.call(_currentSession!);
    }
  }
  
  void _startActivityDetection() {
    // Run detection every 1 second
    _activityTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _detectAndRecordActivity();
    });
  }
  
  void _startPeriodicUpload() {
    // Upload pending data every 30 seconds
    _uploadTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _uploadPendingActivities();
    });
  }
  
  Future<void> _detectAndRecordActivity() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      // Capture frame
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      
      // Run AI detection
      final result = await _aiService.detectActivity(bytes);
      
      // Notify callback
      onActivityDetected?.call(result.activity, result.confidence);
      
      // Check if state changed
      if (result.activity != _currentActivity) {
        // Record previous activity
        if (_currentActivity != ActivityType.unknown && _activityStartTime != null) {
          final duration = DateTime.now().difference(_activityStartTime!).inSeconds;
          _recordActivity(_currentActivity, duration, result.confidence);
        }
        
        // Start new activity
        _currentActivity = result.activity;
        _activityStartTime = DateTime.now();
      }
      
      // Check for alerts
      _checkAlerts(result);
      
    } catch (e) {
      print('Error detecting activity: $e');
    }
  }
  
  void _recordActivity(ActivityType activity, int durationSeconds, double confidence) {
    if (_currentSession == null) return;
    
    final record = ActivityRecord(
      sessionId: _currentSession!.id,
      timestamp: _activityStartTime ?? DateTime.now(),
      activity: activity,
      confidence: confidence,
      durationSeconds: durationSeconds,
      uploaded: false,
    );
    
    _pendingActivities.add(record);
    
    // Update session
    final activities = List<ActivityRecord>.from(_currentSession!.activities)
      ..add(record);
    
    _currentSession = MonitoringSession(
      id: _currentSession!.id,
      childId: _currentSession!.childId,
      startTime: _currentSession!.startTime,
      endTime: _currentSession!.endTime,
      isActive: _currentSession!.isActive,
      activities: activities,
    );
    
    onSessionUpdated?.call(_currentSession!);
  }
  
  void _checkAlerts(ActivityDetectionResult result) {
    if (_alertConfig == null) return;
    
    // Check leave alert
    if (result.activity == ActivityType.away && !result.personDetected) {
      // This would trigger after threshold
      onAlertTriggered?.call('away_detected');
    }
    
    // Check play alert
    if (result.activity == ActivityType.playing && result.handsDetected) {
      onAlertTriggered?.call('playing_detected');
    }
  }
  
  Future<void> _uploadPendingActivities() async {
    if (_pendingActivities.isEmpty) return;
    
    // Upload metadata
    for (final record in _pendingActivities) {
      await _apiClient.uploadMetadata(record);
    }
    
    // Clear pending
    _pendingActivities.clear();
  }
  
  /// Switch camera
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    final currentIndex = _cameras!.indexOf(_cameraController!.description);
    final nextIndex = (currentIndex + 1) % _cameras!.length;
    
    await _cameraController?.dispose();
    await _initializeCamera(_cameras![nextIndex]);
  }
  
  /// Dispose resources
  void dispose() {
    stopSession();
    _cameraController?.dispose();
    _aiService.dispose();
  }
}

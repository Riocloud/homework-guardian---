import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/upload_service.dart';
import '../core/constants.dart';

/// App State Management using ChangeNotifier
class AppState extends ChangeNotifier {
  // Services
  final DatabaseService _database = DatabaseService();
  late final UploadService _uploadService;
  final NotificationService _notificationService = NotificationService();
  
  // State
  bool _isInitialized = false;
  bool _isMonitoring = false;
  MonitoringSession? _currentSession;
  List<ActivityRecord> _todayActivities = [];
  String _currentStatus = '等待开始';
  int _studyMinutes = 0;
  int _focusScore = 0;
  int _pendingCount = 0;
  bool _isSyncing = false;
  double _syncProgress = 0;
  String _syncStatus = '';
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isMonitoring => _isMonitoring;
  MonitoringSession? get currentSession => _currentSession;
  String get currentStatus => _currentStatus;
  int get studyMinutes => _studyMinutes;
  int get focusScore => _focusScore;
  int get pendingCount => _pendingCount;
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get syncStatus => _syncStatus;
  List<ActivityRecord> get todayActivities => _todayActivities;
  
  // Initialize
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize notification service
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
      
      // Initialize upload service
      _uploadService = UploadService(
        baseUrl: AppConstants.defaultServerUrl,
        database: _database,
      );
      _uploadService.onProgress = _onSyncProgress;
      
      // Load pending count
      _pendingCount = await _uploadService.getPendingCount();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }
  
  // Monitoring
  Future<void> startMonitoring({required String childId, AlertConfig? config}) async {
    if (_isMonitoring) return;
    
    try {
      _isMonitoring = true;
      _currentStatus = '学习中';
      _currentSession = MonitoringSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        childId: childId,
        startTime: DateTime.now(),
        isActive: true,
      );
      
      // Save to database
      await _database.upsertSession(_currentSession!);
      
      // Show notification
      await _notificationService.showSessionStarted(childId);
      
      notifyListeners();
      
      // Start simulation (replace with real monitoring)
      _startMonitoringSimulation();
    } catch (e) {
      debugPrint('Start monitoring error: $e');
      _isMonitoring = false;
    }
  }
  
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;
    
    try {
      _isMonitoring = false;
      _currentStatus = '已停止';
      
      if (_currentSession != null) {
        _currentSession = MonitoringSession(
          id: _currentSession!.id,
          childId: _currentSession!.childId,
          startTime: _currentSession!.startTime,
          endTime: DateTime.now(),
          isActive: false,
          activities: _todayActivities,
        );
        
        await _database.upsertSession(_currentSession!);
        
        // Show notification
        await _notificationService.showSessionEnded(
          _currentSession!.childId,
          _studyMinutes,
          _focusScore.toDouble(),
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Stop monitoring error: $e');
    }
  }
  
  // Sync
  Future<void> syncData() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    _syncProgress = 0;
    _syncStatus = '正在同步...';
    notifyListeners();
    
    try {
      final result = await _uploadService.syncAll();
      
      _syncStatus = result.success ? '同步完成' : '部分失败';
      _pendingCount = result.failedCount;
      
      if (result.uploadedCount > 0) {
        await _notificationService.showUploadComplete(result.uploadedCount);
      }
    } catch (e) {
      _syncStatus = '同步失败';
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  // Private
  void _onSyncProgress(double progress, String status) {
    _syncProgress = progress;
    _syncStatus = status;
    notifyListeners();
  }
  
  void _startMonitoringSimulation() {
    // Simulate real-time updates
    Future.delayed(const Duration(seconds: 2), () {
      if (_isMonitoring) {
        _studyMinutes = 5;
        _focusScore = 88;
        notifyListeners();
      }
    });
  }
}

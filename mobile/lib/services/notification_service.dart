import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notification Service - Local Push Notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Request permissions
  Future<bool> requestPermissions() async {
    // Android 13+ requires specific permission
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      if (granted != true) return false;
    }

    // iOS permissions
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != true) return false;
    }

    return true;
  }

  /// Show notification
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'homework_guardian_channel',
      'HomeworkGuardian',
      channelDescription: '学习监控提醒',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Notification types
  static const int _idSessionStart = 1;
  static const int _idSessionEnd = 2;
  static const int _idLeaveAlert = 10;
  static const int _idPlayAlert = 11;
  static const int _idUploadComplete = 20;

  /// Show session started notification
  Future<void> showSessionStarted(String childName) async {
    await show(
      id: _idSessionStart,
      title: '🟢 监控开始',
      body: '已开始监控 $childName 的学习情况',
      payload: 'session_start',
    );
  }

  /// Show session ended notification
  Future<void> showSessionEnded(String childName, int durationMinutes, double focusScore) async {
    await show(
      id: _idSessionEnd,
      title: '🔴 监控结束',
      body: '$childName 本次学习 $durationMinutes 分钟，专注度 ${focusScore.toStringAsFixed(0)}%',
      payload: 'session_end',
    );
  }

  /// Show leave alert (child away too long)
  Future<void> showLeaveAlert(String childName, int minutes) async {
    await show(
      id: _idLeaveAlert,
      title: '⚠️ 离开提醒',
      body: '$childName 已离开 ${minutes}分钟了，请关注！',
      payload: 'leave_alert',
    );
  }

  /// Show playing alert (child playing while working)
  Future<void> showPlayingAlert(String childName, int minutes) async {
    await show(
      id: _idPlayAlert,
      title: '📱 玩耍提醒',
      body: '检测到 $childName 边玩边学超过 ${minutes}分钟',
      payload: 'play_alert',
    );
  }

  /// Show upload complete notification
  Future<void> showUploadComplete(int count) async {
    await show(
      id: _idUploadComplete,
      title: '☁️ 数据同步',
      body: '已成功上传 $count 条记录到服务器',
      payload: 'upload_complete',
    );
  }

  /// Cancel notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Handle different notification types
    switch (payload) {
      case 'leave_alert':
      case 'play_alert':
        // Navigate to alert screen
        break;
      case 'session_end':
        // Navigate to report screen
        break;
      case 'upload_complete':
        // Navigate to sync status
        break;
    }
  }
}

/// Scheduled Notification Service
class ScheduledNotificationService {
  static final ScheduledNotificationService _instance = ScheduledNotificationService._internal();
  factory ScheduledNotificationService() => _instance;
  ScheduledNotificationService._internal();

  final NotificationService _notificationService = NotificationService();

  /// Schedule daily report notification
  Future<void> scheduleDailyReport({
    required int hour,
    required int minute,
  }) async {
    // Using flutter_local_notifications zonedSchedule
    // For now, simplified implementation
  }

  /// Cancel scheduled notifications
  Future<void> cancelScheduled() async {
    // Implementation for canceling scheduled notifications
  }
}

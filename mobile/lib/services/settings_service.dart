import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';
import '../core/constants.dart';

/// Settings service - manages app settings with persistence
class SettingsService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // Settings cache
  String? _childName;
  String? _childId;
  String? _serverUrl;
  bool? _pushNotifications;
  bool? _emailAlerts;
  String? _emailAddress;
  int? _leaveThresholdMinutes;
  int? _playThresholdMinutes;
  bool? _autoSync;
  int? _syncIntervalMinutes;
  // AI performance settings
  int? _aiFrameIntervalMs;
  int? _aiInferenceThreads;
  bool? _aiLowPowerMode;

  String get childName => _childName ?? '小明';
  String get childId => _childId ?? 'default';
  String get serverUrl => _serverUrl ?? AppConstants.defaultServerUrl;
  bool get pushNotifications => _pushNotifications ?? true;
  bool get emailAlerts => _emailAlerts ?? true;
  String get emailAddress => _emailAddress ?? '';
  int get leaveThresholdMinutes => _leaveThresholdMinutes ?? AppConstants.defaultLeaveThresholdMinutes;
  int get playThresholdMinutes => _playThresholdMinutes ?? AppConstants.defaultPlayThresholdMinutes;
  bool get autoSync => _autoSync ?? true;
  int get syncIntervalMinutes => _syncIntervalMinutes ?? AppConstants.syncIntervalMinutes;
  int get aiFrameIntervalMs => _aiFrameIntervalMs ?? AppConstants.aiFrameIntervalMs;
  int get aiInferenceThreads => _aiInferenceThreads ?? AppConstants.aiInferenceThreads;
  bool get aiLowPowerMode => _aiLowPowerMode ?? false;

  Future<void> load() async {
    _childName = await _db.getSetting('child_name') ?? '小明';
    _childId = await _db.getSetting('child_id') ?? 'default';
    _serverUrl = await _db.getSetting('server_url') ?? AppConstants.defaultServerUrl;
    _pushNotifications = (await _db.getSetting('push_notifications')) != 'false';
    _emailAlerts = (await _db.getSetting('email_alerts')) != 'false';
    _emailAddress = await _db.getSetting('email_address') ?? '';
    _leaveThresholdMinutes = int.tryParse(await _db.getSetting('leave_threshold') ?? '') ?? AppConstants.defaultLeaveThresholdMinutes;
    _playThresholdMinutes = int.tryParse(await _db.getSetting('play_threshold') ?? '') ?? AppConstants.defaultPlayThresholdMinutes;
    _autoSync = (await _db.getSetting('auto_sync')) != 'false';
    _syncIntervalMinutes = int.tryParse(await _db.getSetting('sync_interval') ?? '') ?? AppConstants.syncIntervalMinutes;
    _aiFrameIntervalMs = int.tryParse(await _db.getSetting('ai_frame_interval_ms') ?? '') ?? AppConstants.aiFrameIntervalMs;
    _aiInferenceThreads = int.tryParse(await _db.getSetting('ai_inference_threads') ?? '') ?? AppConstants.aiInferenceThreads;
    _aiLowPowerMode = (await _db.getSetting('ai_low_power_mode')) == 'true';
    notifyListeners();
  }

  Future<void> setChildName(String value) async {
    _childName = value;
    await _db.setSetting('child_name', value);
    notifyListeners();
  }

  Future<void> setServerUrl(String value) async {
    _serverUrl = value;
    await _db.setSetting('server_url', value);
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    await _db.setSetting('push_notifications', value.toString());
    notifyListeners();
  }

  Future<void> setEmailAlerts(bool value) async {
    _emailAlerts = value;
    await _db.setSetting('email_alerts', value.toString());
    notifyListeners();
  }

  Future<void> setEmailAddress(String value) async {
    _emailAddress = value;
    await _db.setSetting('email_address', value);
    notifyListeners();
  }

  Future<void> setLeaveThresholdMinutes(int value) async {
    _leaveThresholdMinutes = value;
    await _db.setSetting('leave_threshold', value.toString());
    notifyListeners();
  }

  Future<void> setPlayThresholdMinutes(int value) async {
    _playThresholdMinutes = value;
    await _db.setSetting('play_threshold', value.toString());
    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _db.setSetting('auto_sync', value.toString());
    notifyListeners();
  }

  Future<void> setSyncIntervalMinutes(int value) async {
    _syncIntervalMinutes = value;
    await _db.setSetting('sync_interval', value.toString());
    notifyListeners();
  }

  Future<void> setAiFrameIntervalMs(int value) async {
    _aiFrameIntervalMs = value;
    await _db.setSetting('ai_frame_interval_ms', value.toString());
    notifyListeners();
  }

  Future<void> setAiInferenceThreads(int value) async {
    _aiInferenceThreads = value;
    await _db.setSetting('ai_inference_threads', value.toString());
    notifyListeners();
  }

  Future<void> setAiLowPowerMode(bool value) async {
    _aiLowPowerMode = value;
    await _db.setSetting('ai_low_power_mode', value.toString());
    notifyListeners();
  }

  AlertConfig toAlertConfig() => AlertConfig(
    childId: childId,
    email: emailAddress,
    leaveThresholdMinutes: leaveThresholdMinutes,
    playWhileWorkThresholdMinutes: playThresholdMinutes,
    enableEmail: emailAlerts,
    enableSound: pushNotifications,
  );
}

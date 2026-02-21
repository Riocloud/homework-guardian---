/// Activity types detected by AI
enum ActivityType {
  studying,
  away,
  playing,
  idle,
  unknown,
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.studying:
        return '学习中';
      case ActivityType.away:
        return '离开';
      case ActivityType.playing:
        return '玩耍中';
      case ActivityType.idle:
        return '空闲';
      case ActivityType.unknown:
        return '未知';
    }
  }

  String get value {
    switch (this) {
      case ActivityType.studying:
        return 'studying';
      case ActivityType.away:
        return 'away';
      case ActivityType.playing:
        return 'playing';
      case ActivityType.idle:
        return 'idle';
      case ActivityType.unknown:
        return 'unknown';
    }
  }

  static ActivityType fromString(String value) {
    switch (value) {
      case 'studying':
        return ActivityType.studying;
      case 'away':
        return ActivityType.away;
      case 'playing':
        return ActivityType.playing;
      case 'idle':
        return ActivityType.idle;
      default:
        return ActivityType.unknown;
    }
  }
}

/// Activity record from local detection
class ActivityRecord {
  final String sessionId;
  final DateTime timestamp;
  final ActivityType activity;
  final double confidence;
  final int durationSeconds;
  final List<String> tags;
  final bool uploaded;

  ActivityRecord({
    required this.sessionId,
    required this.timestamp,
    required this.activity,
    required this.confidence,
    required this.durationSeconds,
    this.tags = const [],
    this.uploaded = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'timestamp': timestamp.toIso8601String(),
      'activity': activity.value,
      'confidence': confidence,
      'duration_seconds': durationSeconds,
      'tags': tags,
      'uploaded': uploaded,
    };
  }

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      sessionId: json['session_id'],
      timestamp: DateTime.parse(json['timestamp']),
      activity: ActivityTypeExtension.fromString(json['activity']),
      confidence: json['confidence'],
      durationSeconds: json['duration_seconds'],
      tags: List<String>.from(json['tags'] ?? []),
      uploaded: json['uploaded'] ?? false,
    );
  }

  ActivityRecord copyWith({
    String? sessionId,
    DateTime? timestamp,
    ActivityType? activity,
    double? confidence,
    int? durationSeconds,
    List<String>? tags,
    bool? uploaded,
  }) {
    return ActivityRecord(
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      activity: activity ?? this.activity,
      confidence: confidence ?? this.confidence,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      tags: tags ?? this.tags,
      uploaded: uploaded ?? this.uploaded,
    );
  }
}

/// Monitoring session
class MonitoringSession {
  final String id;
  final String childId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final List<ActivityRecord> activities;

  MonitoringSession({
    required this.id,
    required this.childId,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    this.activities = const [],
  });

  int get totalDurationSeconds {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds;
  }

  int get studyDurationSeconds {
    return activities
        .where((a) => a.activity == ActivityType.studying)
        .fold(0, (sum, a) => sum + a.durationSeconds);
  }

  double get focusScore {
    if (activities.isEmpty) return 0;
    final studyTime = studyDurationSeconds;
    return (studyTime / totalDurationSeconds * 100).clamp(0, 100);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_id': childId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_active': isActive,
      'activities': activities.map((a) => a.toJson()).toList(),
    };
  }
}

/// Alert configuration
class AlertConfig {
  final String childId;
  final String email;
  final int leaveThresholdMinutes;
  final int playWhileWorkThresholdMinutes;
  final bool enableEmail;
  final bool enableSound;

  AlertConfig({
    required this.childId,
    required this.email,
    this.leaveThresholdMinutes = 15,
    this.playWhileWorkThresholdMinutes = 5,
    this.enableEmail = true,
    this.enableSound = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'child_id': childId,
      'email': email,
      'leave_threshold_minutes': leaveThresholdMinutes,
      'play_while_work_threshold_minutes': playWhileWorkThresholdMinutes,
      'enable_email': enableEmail,
      'enable_sound': enableSound,
    };
  }

  factory AlertConfig.fromJson(Map<String, dynamic> json) {
    return AlertConfig(
      childId: json['child_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      leaveThresholdMinutes: json['leave_threshold_minutes'] as int? ?? 15,
      playWhileWorkThresholdMinutes: json['play_while_work_threshold_minutes'] as int? ?? 5,
      enableEmail: json['enable_email'] as bool? ?? true,
      enableSound: json['enable_sound'] as bool? ?? true,
    );
  }

  AlertConfig copyWith({
    String? childId,
    String? email,
    int? leaveThresholdMinutes,
    int? playWhileWorkThresholdMinutes,
    bool? enableEmail,
    bool? enableSound,
  }) {
    return AlertConfig(
      childId: childId ?? this.childId,
      email: email ?? this.email,
      leaveThresholdMinutes: leaveThresholdMinutes ?? this.leaveThresholdMinutes,
      playWhileWorkThresholdMinutes: playWhileWorkThresholdMinutes ?? this.playWhileWorkThresholdMinutes,
      enableEmail: enableEmail ?? this.enableEmail,
      enableSound: enableSound ?? this.enableSound,
    );
  }
}

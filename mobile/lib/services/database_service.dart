import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// Local database service using SQLite
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'homework_guardian.db';
  static const int _dbVersion = 1;

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Activities table
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        activity TEXT NOT NULL,
        confidence REAL NOT NULL,
        duration_seconds INTEGER NOT NULL,
        tags TEXT,
        uploaded INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT UNIQUE NOT NULL,
        child_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        is_active INTEGER DEFAULT 1,
        total_study_time INTEGER DEFAULT 0,
        focus_score REAL DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Videos table
    await db.execute('''
      CREATE TABLE videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        duration_seconds INTEGER,
        file_size INTEGER,
        uploaded INTEGER DEFAULT 0,
        upload_attempts INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_activities_session ON activities(session_id)');
    await db.execute('CREATE INDEX idx_activities_uploaded ON activities(uploaded)');
    await db.execute('CREATE INDEX idx_videos_session ON videos(session_id)');
    await db.execute('CREATE INDEX idx_videos_uploaded ON videos(uploaded)');
  }

  /// Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here
  }

  // ==================== Activities ====================

  /// Insert activity record
  Future<int> insertActivity(ActivityRecord record) async {
    final db = await database;
    return await db.insert('activities', {
      'session_id': record.sessionId,
      'timestamp': record.timestamp.toIso8601String(),
      'activity': record.activity.value,
      'confidence': record.confidence,
      'duration_seconds': record.durationSeconds,
      'tags': record.tags.join(','),
      'uploaded': record.uploaded ? 1 : 0,
    });
  }

  /// Get activities by session
  Future<List<ActivityRecord>> getActivitiesBySession(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'activities',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => ActivityRecord(
      sessionId: map['session_id'],
      timestamp: DateTime.parse(map['timestamp']),
      activity: ActivityTypeExtension.fromString(map['activity']),
      confidence: map['confidence'],
      durationSeconds: map['duration_seconds'],
      tags: (map['tags'] as String?)?.split(',') ?? [],
      uploaded: map['uploaded'] == 1,
    )).toList();
  }

  /// Get pending uploads (not uploaded)
  Future<List<ActivityRecord>> getPendingActivities() async {
    final db = await database;
    final maps = await db.query(
      'activities',
      where: 'uploaded = 0',
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => ActivityRecord(
      sessionId: map['session_id'],
      timestamp: DateTime.parse(map['timestamp']),
      activity: ActivityTypeExtension.fromString(map['activity']),
      confidence: map['confidence'],
      durationSeconds: map['duration_seconds'],
      tags: (map['tags'] as String?)?.split(',') ?? [],
      uploaded: false,
    )).toList();
  }

  /// Mark activities as uploaded
  Future<void> markActivitiesUploaded(List<int> ids) async {
    final db = await database;
    await db.update(
      'activities',
      {'uploaded': 1},
      where: 'id IN (${ids.join(',')})',
    );
  }

  // ==================== Sessions ====================

  /// Insert or update session
  Future<void> upsertSession(MonitoringSession session) async {
    final db = await database;
    await db.insert(
      'sessions',
      {
        'session_id': session.id,
        'child_id': session.childId,
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime?.toIso8601String(),
        'is_active': session.isActive ? 1 : 0,
        'total_study_time': session.totalDurationSeconds,
        'focus_score': session.focusScore,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get active session
  Future<MonitoringSession?> getActiveSession() async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'is_active = 1',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    final activities = await getActivitiesBySession(map['session_id']);

    return MonitoringSession(
      id: map['session_id'],
      childId: map['child_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      isActive: map['is_active'] == 1,
      activities: activities,
    );
  }

  /// Get session history
  Future<List<MonitoringSession>> getSessionHistory({int limit = 30}) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'is_active = 0',
      orderBy: 'start_time DESC',
      limit: limit,
    );

    return maps.map((map) => MonitoringSession(
      id: map['session_id'],
      childId: map['child_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      isActive: false,
      activities: [],
    )).toList();
  }

  // ==================== Videos ====================

  /// Insert video record
  Future<int> insertVideo(VideoRecord record) async {
    final db = await database;
    return await db.insert('videos', {
      'session_id': record.sessionId,
      'file_path': record.filePath,
      'duration_seconds': record.durationSeconds,
      'file_size': record.fileSize,
      'uploaded': record.uploaded ? 1 : 0,
    });
  }

  /// Get pending videos
  Future<List<VideoRecord>> getPendingVideos({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'videos',
      where: 'uploaded = 0 AND upload_attempts < 3',
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return maps.map((map) => VideoRecord(
      id: map['id'],
      sessionId: map['session_id'],
      filePath: map['file_path'],
      durationSeconds: map['duration_seconds'],
      fileSize: map['file_size'],
      uploaded: map['uploaded'] == 1,
      uploadAttempts: map['upload_attempts'],
    )).toList();
  }

  /// Mark video as uploaded
  Future<void> markVideoUploaded(int id) async {
    final db = await database;
    await db.update(
      'videos',
      {'uploaded': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Increment upload attempts
  Future<void> incrementVideoAttempts(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE videos SET upload_attempts = upload_attempts + 1 WHERE id = ?',
      [id],
    );
  }

  // ==================== Settings ====================

  /// Get setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return maps.isNotEmpty ? maps.first['value'] : null;
  }

  /// Set setting
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value, 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get alert config
  Future<AlertConfig?> getAlertConfig() async {
    final jsonStr = await getSetting('alert_config');
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AlertConfig.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Save alert config
  Future<void> saveAlertConfig(AlertConfig config) async {
    await setSetting('alert_config', jsonEncode(config.toJson()));
  }

  // ==================== Utility ====================

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics({String? childId}) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (childId != null) {
      whereClause = 'WHERE child_id = ?';
      whereArgs = [childId];
    }

    // Total study time
    final studyResult = await db.rawQuery(
      'SELECT SUM(total_study_time) as total FROM sessions $whereClause',
      whereArgs,
    );

    // Session count
    final sessionResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sessions $whereClause',
      whereArgs,
    );

    // Activities count
    final activityResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM activities',
    );

    return {
      'total_study_time': studyResult.first['total'] ?? 0,
      'session_count': sessionResult.first['count'] ?? 0,
      'activity_count': activityResult.first['count'] ?? 0,
    };
  }

  /// Clear old data
  Future<void> clearOldData({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    await db.delete(
      'activities',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
    
    await db.delete(
      'sessions',
      where: 'start_time < ? AND is_active = 0',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

/// Video record model for database
class VideoRecord {
  final int? id;
  final String sessionId;
  final String filePath;
  final int? durationSeconds;
  final int? fileSize;
  final bool uploaded;
  final int uploadAttempts;

  VideoRecord({
    this.id,
    required this.sessionId,
    required this.filePath,
    this.durationSeconds,
    this.fileSize,
    this.uploaded = false,
    this.uploadAttempts = 0,
  });
}

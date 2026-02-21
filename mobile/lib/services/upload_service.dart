import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import 'database_service.dart';

/// Enhanced Upload Service with background upload and progress tracking
class UploadService {
  final Dio _dio;
  final DatabaseService _database;
  
  final String baseUrl;
  
  bool _isUploading = false;
  final List<_UploadTask> _queue = [];
  CancelToken? _currentCancelToken;
  
  // Progress callback
  Function(double progress, String status)? onProgress;
  
  UploadService({
    required this.baseUrl,
    required DatabaseService database,
  }) : _database = database,
       _dio = Dio(BaseOptions(
         baseUrl: baseUrl,
         connectTimeout: const Duration(seconds: 30),
         receiveTimeout: const Duration(minutes: 10),
       ));

  /// Check if currently uploading
  bool get isUploading => _isUploading;

  /// Upload activity record
  Future<bool> uploadActivity(ActivityRecord record) async {
    try {
      final response = await _dio.post(
        '/api/v1/upload/metadata',
        data: record.toJson(),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Upload failed: $e');
      return false;
    }
  }

  /// Upload video file with progress
  Future<_UploadResult> uploadVideo(
    VideoRecord video, {
    Function(double progress)? onProgress,
  }) async {
    final file = File(video.filePath);
    
    if (!await file.exists()) {
      return _UploadResult(success: false, error: 'File not found');
    }

    final cancelToken = CancelToken();
    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(
        video.filePath,
        filename: 'video_${video.id}.mp4',
      ),
      'session_id': video.sessionId,
      'duration_seconds': video.durationSeconds,
    });

    try {
      final response = await _dio.post(
        '/api/v1/upload/video',
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          final progress = sent / total;
          onProgress?.call(progress);
        },
      );

      if (response.statusCode == 200) {
        return _UploadResult(success: true);
      } else {
        return _UploadResult(success: false, error: 'Server error');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return _UploadResult(success: false, error: 'Cancelled');
      }
      return _UploadResult(success: false, error: e.message);
    } catch (e) {
      return _UploadResult(success: false, error: e.toString());
    }
  }

  /// Queue video for upload
  Future<void> queueVideo(VideoRecord video) async {
    // Save to database first
    await _database.insertVideo(video);
    _queue.add(_UploadTask(video: video, type: _UploadType.video));
    
    // Try to process queue
    if (!_isUploading) {
      _processQueue();
    }
  }

  /// Sync all pending data
  Future<SyncResult> syncAll() async {
    if (_isUploading) {
      return SyncResult(
        success: false,
        message: 'Already syncing',
        uploadedCount: 0,
        failedCount: 0,
      );
    }

    _isUploading = true;
    int uploadedCount = 0;
    int failedCount = 0;

    try {
      // 1. Upload pending activities
      onProgress?.call(0.1, '正在上传活动记录...');
      final pendingActivities = await _database.getPendingActivities();
      
      for (final activity in pendingActivities) {
        final success = await uploadActivity(activity);
        if (success) {
          uploadedCount++;
        } else {
          failedCount++;
        }
      }

      // 2. Upload pending videos
      onProgress?.call(0.5, '正在上传视频片段...');
      final pendingVideos = await _database.getPendingVideos(limit: 5);
      
      for (final video in pendingVideos) {
        final result = await uploadVideo(video, onProgress: (p) {
          onProgress?.call(0.5 + p * 0.4, '上传视频: ${(p * 100).toStringAsFixed(0)}%');
        });
        
        if (result.success) {
          await _database.markVideoUploaded(video.id!);
          uploadedCount++;
        } else {
          await _database.incrementVideoAttempts(video.id!);
          failedCount++;
        }
      }

      onProgress?.call(1.0, '同步完成');

      return SyncResult(
        success: failedCount == 0,
        message: failedCount == 0 ? '全部同步成功' : '部分失败',
        uploadedCount: uploadedCount,
        failedCount: failedCount,
      );

    } finally {
      _isUploading = false;
    }
  }

  /// Process upload queue
  Future<void> _processQueue() async {
    if (_isUploading || _queue.isEmpty) return;

    _isUploading = true;

    while (_queue.isNotEmpty) {
      final task = _queue.first;
      
      try {
        if (task.type == _UploadType.video) {
          final result = await uploadVideo(task.video);
          if (result.success) {
            await _database.markVideoUploaded(task.video.id!);
          } else {
            await _database.incrementVideoAttempts(task.video.id!);
          }
        }
      } catch (e) {
        print('Upload error: $e');
      }

      _queue.removeAt(0);
    }

    _isUploading = false;
  }

  /// Cancel current upload
  void cancel() {
    _currentCancelToken?.cancel('User cancelled');
    _queue.clear();
    _isUploading = false;
  }

  /// Get pending upload count
  Future<int> getPendingCount() async {
    final activities = await _database.getPendingActivities();
    final videos = await _database.getPendingVideos(limit: 100);
    return activities.length + videos.length;
  }
}

/// Background Upload Service (for continuous uploads)
class BackgroundUploadService {
  final UploadService _uploadService;
  Timer? _periodicTimer;
  bool _isRunning = false;
  
  // Upload every 5 minutes when app is active
  static const Duration _uploadInterval = Duration(minutes: 5);
  
  BackgroundUploadService({required UploadService uploadService})
      : _uploadService = uploadService;

  /// Start background upload
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // Upload immediately
    _uploadService.syncAll();
    
    // Schedule periodic uploads
    _periodicTimer = Timer.periodic(_uploadInterval, (_) {
      _uploadService.syncAll();
    });
  }

  /// Stop background upload
  void stop() {
    _isRunning = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Force immediate sync
  Future<SyncResult> forceSync() async {
    return await _uploadService.syncAll();
  }
}

/// Download Service - For downloading models, etc.
class DownloadService {
  final Dio _dio;
  
  DownloadService({String? baseUrl}) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl ?? '',
    connectTimeout: const Duration(seconds: 30),
  ));

  /// Download file with progress
  Future<String?> downloadFile(
    String url,
    String filename, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$filename';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress?.call(received / total);
          }
        },
      );

      return savePath;
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  /// Download AI models
  Future<bool> downloadModels({
    Function(double progress)? onProgress,
  }) async {
    // Placeholder for model download logic
    // In production, download TFLite/CoreML models from server
    return true;
  }
}

// ==================== Helper Classes ====================

enum _UploadType { activity, video }

class _UploadTask {
  final VideoRecord? video;
  final ActivityRecord? activity;
  final _UploadType type;

  _UploadTask({this.video, this.activity, required this.type});
}

class _UploadResult {
  final bool success;
  final String? error;

  _UploadResult({required this.success, this.error});
}

class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.uploadedCount,
    required this.failedCount,
  });
}

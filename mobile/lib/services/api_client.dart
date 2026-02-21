import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/models.dart';

/// API Client for server communication
class ApiClient {
  late final Dio _dio;
  final String baseUrl;
  
  ApiClient({required this.baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[API] $obj'),
    ));
  }
  
  // ==================== Upload Endpoints ====================
  
  /// Upload metadata from mobile device
  Future<ApiResponse> uploadMetadata(ActivityRecord record) async {
    try {
      final response = await _dio.post(
        '/api/v1/upload/metadata',
        data: record.toJson(),
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Upload video segment for server analysis
  Future<ApiResponse> uploadVideo(
    String videoPath, {
    required String sessionId,
    String? timestamp,
  }) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(videoPath),
        'session_id': sessionId,
        'timestamp': timestamp ?? DateTime.now().toIso8601String(),
      });
      
      final response = await _dio.post(
        '/api/v1/upload/video',
        data: formData,
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  // ==================== Analysis Endpoints ====================
  
  /// Get session analysis
  Future<ApiResponse> getSessionAnalysis(String sessionId) async {
    try {
      final response = await _dio.get('/api/v1/analysis/session/$sessionId');
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Analyze time segment
  Future<ApiResponse> analyzeSegment({
    required String sessionId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/analysis/segment',
        data: {
          'session_id': sessionId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
        },
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  // ==================== Alert Endpoints ====================
  
  /// Set alert configuration
  Future<ApiResponse> setAlertConfig(AlertConfig config) async {
    try {
      final response = await _dio.post(
        '/api/v1/alert/config',
        data: config.toJson(),
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Get alert status
  Future<ApiResponse> getAlertStatus(String sessionId) async {
    try {
      final response = await _dio.get('/api/v1/alert/status/$sessionId');
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  // ==================== Report Endpoints ====================
  
  /// Get daily report
  Future<ApiResponse> getDailyReport(String childId, {String? date}) async {
    try {
      final response = await _dio.get(
        '/api/v1/report/daily/$childId',
        queryParameters: date != null ? {'date': date} : null,
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Get weekly report
  Future<ApiResponse> getWeeklyReport(String childId) async {
    try {
      final response = await _dio.get('/api/v1/report/weekly/$childId');
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
  
  // ==================== Email Endpoints ====================
  
  /// Test email
  Future<ApiResponse> testEmail(String recipient) async {
    try {
      final response = await _dio.post(
        '/api/v1/email/test',
        data: {'recipient': recipient},
      );
      return ApiResponse.success(response.data);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}

/// API Response wrapper
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  
  ApiResponse._({
    required this.success,
    this.data,
    this.error,
  });
  
  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(success: true, data: data);
  }
  
  factory ApiResponse.error(String error) {
    return ApiResponse._(success: false, error: error);
  }
}

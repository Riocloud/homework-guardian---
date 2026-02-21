import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Video compression and processing service
class VideoService {
  /// Compress video for upload
  /// Reduces file size while maintaining AI analysis quality
  Future<VideoCompressionResult> compressVideo(
    String inputPath, {
    int maxDurationSeconds = 60,
    int maxWidth = 1280,
    int fps = 15,
  }) async {
    final outputDir = await getTemporaryDirectory();
    final outputPath = '${outputDir.path}/compressed_${const Uuid().v4()}.mp4';
    
    // FFmpeg command to compress video
    // - Reduce resolution to maxWidth
    // - Reduce FPS to 15 (enough for activity analysis)
    // - Use H.264 codec for compatibility
    // - CRF 28 for good quality/size balance
    final command = '-i $inputPath '
        '-t $maxDurationSeconds '
        '-vf "scale=$maxWidth:-2:flags=lanczos,fps=$fps" '
        '-c:v libx264 '
        '-crf 28 '
        '-preset fast '
        '-c:a aac '
        '-b:a 64k '
        '-movflags +faststart '
        '$outputPath';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      final inputFile = File(inputPath);
      final outputFile = File(outputPath);
      
      return VideoCompressionResult(
        success: true,
        outputPath: outputPath,
        originalSize: await inputFile.length(),
        compressedSize: await outputFile.length(),
      );
    } else {
      return VideoCompressionResult(
        success: false,
        error: 'FFmpeg compression failed',
      );
    }
  }
  
  /// Extract keyframes from video for analysis
  Future<List<String>> extractKeyframes(
    String inputPath, {
    int frameInterval = 30,
  }) async {
    final outputDir = await getTemporaryDirectory();
    final framesDir = '${outputDir.path}/frames_${const Uuid().v4()}';
    await Directory(framesDir).create();
    
    // Extract frames at interval
    final command = '-i $inputPath '
        '-vf "select=not(mod(n\\,$frameInterval))" '
        '-vsync vfr '
        '$framesDir/frame_%04d.jpg';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (ReturnCode.isSuccess(returnCode)) {
      final dir = Directory(framesDir);
      final files = dir.listSync().map((f) => f.path).toList();
      files.sort();
      return files;
    }
    
    return [];
  }
  
  /// Record screen for specific duration
  Future<String?> startRecording({
    required String outputPath,
    int durationSeconds = 60,
  }) async {
    // This would integrate with platform-specific screen recording
    // For now, return the output path
    return outputPath;
  }
}

/// Result of video compression
class VideoCompressionResult {
  final bool success;
  final String? outputPath;
  final int? originalSize;
  final int? compressedSize;
  final String? error;
  
  VideoCompressionResult({
    required this.success,
    this.outputPath,
    this.originalSize,
    this.compressedSize,
    this.error,
  });
  
  double get compressionRatio {
    if (originalSize == null || compressedSize == null) return 0;
    return 1 - (compressedSize! / originalSize!);
  }
  
  String get compressionPercent => '${(compressionRatio * 100).toStringAsFixed(1)}%';
}

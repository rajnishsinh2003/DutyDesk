import 'dart:typed_data';

/// DEPRECATED: The pixel-based face matcher (ZNCC, HOG, skin-pixel heuristics,
/// oval crop masks) has been completely replaced with deep facial embeddings.
///
/// See:
/// - `FaceEmbeddingService` (lib/core/services/face_embedding_service.dart)
/// - `FaceConfig` (lib/core/config/face_config.dart)
@Deprecated('Use FaceEmbeddingService for ML Kit face detection and MobileFaceNet embeddings.')
class FaceValidationResult {
  final bool isValid;
  final String message;
  final String? suggestion;
  final double faceScore;
  final double angleScore;
  final Uint8List? processedBytes;

  const FaceValidationResult({
    required this.isValid,
    required this.message,
    this.suggestion,
    this.faceScore = 0.0,
    this.angleScore = 0.0,
    this.processedBytes,
  });
}

@Deprecated('Use FaceEmbeddingService for deep cosine similarity.')
class FaceComparisonResult {
  final bool isMatch;
  final double similarityScore;
  final String statusMessage;
  final String? failureReason;
  final Uint8List? liveFaceCrop;

  const FaceComparisonResult({
    required this.isMatch,
    required this.similarityScore,
    required this.statusMessage,
    this.failureReason,
    this.liveFaceCrop,
  });
}

@Deprecated('Use FaceEmbeddingService instead.')
class FaceValidationService {
  @Deprecated('Use FaceEmbeddingService.detectFace instead.')
  static Future<FaceValidationResult> validateAndProcess({
    required Uint8List imageBytes,
    required int angleIndex,
  }) async {
    return const FaceValidationResult(
      isValid: false,
      message: 'FaceValidationService is deprecated. Use FaceEmbeddingService.',
    );
  }

  @Deprecated('Use FaceEmbeddingService.cosineSimilarity instead.')
  static Future<FaceComparisonResult> compareFaces({
    required Uint8List liveFrameBytes,
    required Uint8List referencePhotoBytes,
    double matchThreshold = 65.0,
  }) async {
    return const FaceComparisonResult(
      isMatch: false,
      similarityScore: 0.0,
      statusMessage: 'FaceValidationService is deprecated. Use FaceEmbeddingService.',
    );
  }
}

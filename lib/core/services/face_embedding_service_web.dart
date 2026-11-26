import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../config/face_config.dart';

/// Result of ML Kit face detection and quality validation on an image (Web stub).
class DetectedFaceInfo {
  final bool isValid;
  final String? errorMessage;
  final dynamic mlKitFace;
  final img.Image? decodedImage;
  final double yaw;
  final double pitch;
  final double roll;
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;
  final double faceWidthRatio;
  final double laplacianVariance;
  final double brightness;

  const DetectedFaceInfo({
    required this.isValid,
    this.errorMessage,
    this.mlKitFace,
    this.decodedImage,
    this.yaw = 0.0,
    this.pitch = 0.0,
    this.roll = 0.0,
    this.leftEyeOpenProb,
    this.rightEyeOpenProb,
    this.faceWidthRatio = 0.0,
    this.laplacianVariance = 0.0,
    this.brightness = 0.0,
  });
}

/// Web-compatible stub for FaceEmbeddingService.
///
/// Deep biometric face recognition with Google ML Kit & TFLite requires
/// native mobile hardware (Android / iOS). This stub allows Flutter Web
/// admin dashboards and portals to compile and run cleanly without native FFI dependencies.
class FaceEmbeddingService {
  static Future<void> initialize() async {
    debugPrint('FaceEmbeddingService: Web stub initialized.');
  }

  static void dispose() {}

  static Future<DetectedFaceInfo> detectFace(
    Uint8List imageBytes, {
    bool isFrontCapture = false,
  }) async {
    return const DetectedFaceInfo(
      isValid: false,
      errorMessage: 'Biometric face verification requires an Android or iOS device camera with ML Kit support.',
    );
  }

  static Float32List cropAndAlign({
    required img.Image image,
    required Rect boundingBox,
  }) {
    return Float32List(0);
  }

  static Future<List<double>> embed(Float32List normalizedPixels) async {
    throw UnsupportedError(
      'TFLite inference is supported natively on Android and iOS devices only.',
    );
  }

  /// Pure Dart Cosine Similarity calculation (compiles and runs everywhere, including Web).
  static double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    if (vectorA.length != vectorB.length) return 0.0;

    double dotProduct = 0.0;
    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
    }

    return dotProduct.clamp(-1.0, 1.0);
  }
}

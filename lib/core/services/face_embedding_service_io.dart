import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../config/face_config.dart';

/// Result of ML Kit face detection and quality validation on an image.
class DetectedFaceInfo {
  final bool isValid;
  final String? errorMessage;
  final Face? mlKitFace;
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

/// Service for deep biometric face detection, quality analysis,
/// alignment, and 192-d / 512-d ArcFace / MobileFaceNet embedding generation.
/// (Native Android / iOS implementation using Google ML Kit and TFLite).
class FaceEmbeddingService {
  static FaceDetector? _faceDetector;
  static Interpreter? _interpreter;
  static bool _isModelLoaded = false;

  /// Initializes the ML Kit Face Detector and loads the TFLite MobileFaceNet model.
  static Future<void> initialize() async {
    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true, // Eye open probability
        enableTracking: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    if (!_isModelLoaded) {
      try {
        _interpreter = await Interpreter.fromAsset(FaceConfig.modelAssetPath);
        _isModelLoaded = true;
        debugPrint('FaceEmbeddingService: MobileFaceNet TFLite interpreter initialized successfully.');
      } catch (e) {
        debugPrint('FaceEmbeddingService: Warning - Could not load ${FaceConfig.modelAssetPath}: $e');
      }
    }
  }

  /// Disposes ML Kit detector and TFLite interpreter resources.
  static void dispose() {
    _faceDetector?.close();
    _faceDetector = null;
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }

  // ─────────────────────────────────────────────────────────────
  // 1. FACE DETECTION & QUALITY VALIDATION (ML Kit)
  // ─────────────────────────────────────────────────────────────

  /// Runs Google ML Kit face detection on a raw image buffer.
  /// Handles EXIF rotation normalization and performs strict quality checks:
  /// - Exactly one face in frame
  /// - Minimum face size ratio
  /// - Blur (Laplacian variance)
  /// - Over/under-exposure brightness
  /// - Pitch and roll orientation limits
  static Future<DetectedFaceInfo> detectFace(
    Uint8List imageBytes, {
    bool isFrontCapture = false,
  }) async {
    await initialize();

    var decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return const DetectedFaceInfo(
        isValid: false,
        errorMessage: 'Unable to decode camera frame.',
      );
    }

    // Always bake orientation so portrait phone selfies are decoded upright
    decoded = img.bakeOrientation(decoded);

    // Save temporary normalized JPEG for ML Kit InputImage
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_face_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(decoded, quality: 90));

    final inputImage = InputImage.fromFile(tempFile);
    List<Face> faces = [];
    try {
      faces = await _faceDetector!.processImage(inputImage);
    } catch (e) {
      debugPrint('ML Kit detection error: $e');
    } finally {
      try {
        await tempFile.delete();
      } catch (_) {}
    }

    if (faces.isEmpty) {
      return DetectedFaceInfo(
        isValid: false,
        errorMessage: 'No face detected in frame. Please center your face inside the oval guide.',
        decodedImage: decoded,
      );
    }

    if (faces.length > 1) {
      return DetectedFaceInfo(
        isValid: false,
        errorMessage: 'Multiple faces detected (${faces.length}). Ensure only one person is in front of the camera.',
        decodedImage: decoded,
      );
    }

    final face = faces.first;
    final w = decoded.width.toDouble();
    final h = decoded.height.toDouble();

    // Head Euler angles
    double rawYaw = face.headEulerAngleY ?? 0.0;
    if (FaceConfig.invertYawSign) rawYaw = -rawYaw;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

    // Face size ratio
    final faceWidthRatio = face.boundingBox.width / w;
    if (faceWidthRatio < FaceConfig.minFaceWidthRatio) {
      return DetectedFaceInfo(
        isValid: false,
        errorMessage: 'Face is too far from camera. Please move closer.',
        decodedImage: decoded,
        mlKitFace: face,
        yaw: rawYaw,
        pitch: pitch,
        roll: roll,
        faceWidthRatio: faceWidthRatio,
      );
    }

    // Pitch & roll limits
    if (pitch.abs() > FaceConfig.maxPitch) {
      final dir = pitch > 0 ? 'up' : 'down';
      return DetectedFaceInfo(
        isValid: false,
        errorMessage: 'Head is tilted too far $dir. Please hold your phone at eye level.',
        decodedImage: decoded,
        mlKitFace: face,
        yaw: rawYaw,
        pitch: pitch,
        roll: roll,
        faceWidthRatio: faceWidthRatio,
      );
    }

    if (roll.abs() > FaceConfig.maxRoll) {
      return DetectedFaceInfo(
        isValid: false,
        errorMessage: 'Head is tilted sideways. Keep your head straight.',
        decodedImage: decoded,
        mlKitFace: face,
        yaw: rawYaw,
        pitch: pitch,
        roll: roll,
        faceWidthRatio: faceWidthRatio,
      );
    }

    // Brightness check
    final brightness = _calculateBrightness(decoded, face.boundingBox);
    if (brightness < FaceConfig.minBrightness) {
      return DetectedFaceInfo(
        isValid: false,
        errorMessage: 'Lighting is too dark. Move to a well-lit area.',
        decodedImage: decoded,
        mlKitFace: face,
        yaw: rawYaw,
        pitch: pitch,
        roll: roll,
        brightness: brightness,
        faceWidthRatio: faceWidthRatio,
      );
    }
    if (brightness > FaceConfig.maxBrightness) {
      return DetectedFaceInfo(
        isValid: false,
        errorMessage: 'Image is overexposed. Reduce direct harsh light on your face.',
        decodedImage: decoded,
        mlKitFace: face,
        yaw: rawYaw,
        pitch: pitch,
        roll: roll,
        brightness: brightness,
        faceWidthRatio: faceWidthRatio,
      );
    }

    // Blur / sharpness check
    final laplacianVar = _computeLaplacianVariance(decoded, face.boundingBox);
    if (laplacianVar < FaceConfig.minLaplacianVariance) {
      return DetectedFaceInfo(
        isValid: false,
        errorMessage: 'Image is blurry. Please hold steady and clean your camera lens.',
        decodedImage: decoded,
        mlKitFace: face,
        yaw: rawYaw,
        pitch: pitch,
        roll: roll,
        laplacianVariance: laplacianVar,
        brightness: brightness,
        faceWidthRatio: faceWidthRatio,
      );
    }

    // Eye-open check on front capture
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    if (isFrontCapture && leftEye != null && rightEye != null) {
      if (leftEye < FaceConfig.minEyeOpenProbability || rightEye < FaceConfig.minEyeOpenProbability) {
        return DetectedFaceInfo(
          isValid: false,
          errorMessage: 'Eyes appear closed or blinking. Please look directly at the camera with eyes open.',
          decodedImage: decoded,
          mlKitFace: face,
          yaw: rawYaw,
          pitch: pitch,
          roll: roll,
          leftEyeOpenProb: leftEye,
          rightEyeOpenProb: rightEye,
          laplacianVariance: laplacianVar,
          brightness: brightness,
          faceWidthRatio: faceWidthRatio,
        );
      }
    }

    return DetectedFaceInfo(
      isValid: true,
      mlKitFace: face,
      decodedImage: decoded,
      yaw: rawYaw,
      pitch: pitch,
      roll: roll,
      leftEyeOpenProb: leftEye,
      rightEyeOpenProb: rightEye,
      faceWidthRatio: faceWidthRatio,
      laplacianVariance: laplacianVar,
      brightness: brightness,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. CROP, ALIGN & PREPROCESSING (112x112 Float Tensor)
  // ─────────────────────────────────────────────────────────────

  /// Crops the face bounding box with ~20% margin, aligns square,
  /// resizes to 112x112, and normalizes to [-1.0, 1.0] ((pixel - 127.5) / 128.0).
  /// Pure photographic crop with NO artificial white oval mask.
  static Float32List cropAndAlign({
    required img.Image image,
    required Rect boundingBox,
  }) {
    final imgW = image.width;
    final imgH = image.height;

    final boxW = boundingBox.width;
    final boxH = boundingBox.height;

    // Expand bounding box by 20% margin for hair, chin, and temples
    final margin = max(boxW, boxH) * 0.20;
    final squareSize = max(boxW, boxH) + margin * 2;

    final centerX = boundingBox.center.dx;
    final centerY = boundingBox.center.dy;

    final left = max(0, (centerX - squareSize / 2).toInt());
    final top = max(0, (centerY - squareSize / 2).toInt());
    final width = min(imgW - left, squareSize.toInt());
    final height = min(imgH - top, squareSize.toInt());

    final cropped = img.copyCrop(
      image,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    final resized = img.copyResize(
      cropped,
      width: FaceConfig.inputImageSize,
      height: FaceConfig.inputImageSize,
    );

    // Normalize to float tensor ((pixel - 127.5) / 128.0)
    final Float32List inputTensor = Float32List(1 * FaceConfig.inputImageSize * FaceConfig.inputImageSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < FaceConfig.inputImageSize; y++) {
      for (int x = 0; x < FaceConfig.inputImageSize; x++) {
        final pixel = resized.getPixel(x, y);
        inputTensor[pixelIndex++] = (pixel.r - 127.5) / 128.0;
        inputTensor[pixelIndex++] = (pixel.g - 127.5) / 128.0;
        inputTensor[pixelIndex++] = (pixel.b - 127.5) / 128.0;
      }
    }

    return inputTensor;
  }

  // ─────────────────────────────────────────────────────────────
  // 3. TFLITE EMBEDDING INFERENCE & L2 NORMALIZATION
  // ─────────────────────────────────────────────────────────────

  /// Runs MobileFaceNet on the preprocessed 112x112 input tensor
  /// and returns an L2-normalized 192-d or 128-d embedding vector.
  static Future<List<double>> embed(Float32List normalizedPixels) async {
    await initialize();

    if (_interpreter == null) {
      throw Exception(
        'TFLite Interpreter is not loaded. Ensure ${FaceConfig.modelAssetPath} exists in assets.',
      );
    }

    // Input shape: [1, 112, 112, 3]
    final input = normalizedPixels.reshape([
      1,
      FaceConfig.inputImageSize,
      FaceConfig.inputImageSize,
      3,
    ]);

    // Output shape: [1, embeddingDimension]
    final output = List.generate(
      1,
      (_) => List<double>.filled(FaceConfig.embeddingDimension, 0.0),
    );

    _interpreter!.run(input, output);

    // L2-Normalize embedding vector
    final rawVector = output[0];
    double normSq = 0.0;
    for (final v in rawVector) {
      normSq += v * v;
    }

    final norm = sqrt(normSq);
    if (norm < 1e-6) return rawVector;

    return rawVector.map((v) => v / norm).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // 4. COSINE SIMILARITY CALCULATION
  // ─────────────────────────────────────────────────────────────

  /// Computes Cosine Similarity between two L2-normalized embedding vectors.
  /// Result is in range [-1.0, 1.0].
  /// Typical ranges for MobileFaceNet / ArcFace:
  ///   Same person: 0.60 – 0.95
  ///   Different person: 0.05 – 0.38
  static double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    if (vectorA.length != vectorB.length) return 0.0;

    double dotProduct = 0.0;
    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
    }

    return dotProduct.clamp(-1.0, 1.0);
  }

  // ─────────────────────────────────────────────────────────────
  // 5. HELPER METRICS (Brightness & Laplacian Variance)
  // ─────────────────────────────────────────────────────────────

  static double _calculateBrightness(img.Image image, Rect box) {
    final x1 = max(0, box.left.toInt());
    final y1 = max(0, box.top.toInt());
    final x2 = min(image.width, box.right.toInt());
    final y2 = min(image.height, box.bottom.toInt());

    double sum = 0.0;
    int count = 0;

    for (int y = y1; y < y2; y += 4) {
      for (int x = x1; x < x2; x += 4) {
        final p = image.getPixel(x, y);
        sum += (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
        count++;
      }
    }
    return count > 0 ? (sum / count) : 128.0;
  }

  static double _computeLaplacianVariance(img.Image image, Rect box) {
    final x1 = max(1, box.left.toInt());
    final y1 = max(1, box.top.toInt());
    final x2 = min(image.width - 1, box.right.toInt());
    final y2 = min(image.height - 1, box.bottom.toInt());

    final deltas = <double>[];
    double sum = 0.0;

    for (int y = y1; y < y2; y += 2) {
      for (int x = x1; x < x2; x += 2) {
        final p = _getLum(image, x, y);
        final pL = _getLum(image, x - 1, y);
        final pR = _getLum(image, x + 1, y);
        final pU = _getLum(image, x, y - 1);
        final pD = _getLum(image, x, y + 1);

        // Standard 4-neighbor discrete Laplacian kernel
        final lap = (pL + pR + pU + pD) - 4 * p;
        deltas.add(lap);
        sum += lap;
      }
    }

    final n = deltas.length;
    if (n < 50) return 100.0;

    final mean = sum / n;
    double variance = 0.0;
    for (int i = 0; i < n; i++) {
      final diff = deltas[i] - mean;
      variance += diff * diff;
    }

    return variance / n;
  }

  static double _getLum(img.Image image, int x, int y) {
    final p = image.getPixel(x, y);
    return 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
  }
}

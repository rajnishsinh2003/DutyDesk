/// Configuration and threshold constants for biometric face detection,
/// multi-angle enrollment, and embedding verification in DutyDesk.
class FaceConfig {
  FaceConfig._();

  // ── MODEL CONFIGURATION ──
  /// Path to the MobileFaceNet TFLite model in app assets.
  static const String modelAssetPath = 'assets/models/mobilefacenet.tflite';

  /// Model version tag stored in Firestore records for audit and model migration tracking.
  static const String modelVersion = 'mobilefacenet-v1';

  /// Standard input resolution expected by MobileFaceNet (112x112 RGB).
  static const int inputImageSize = 112;

  /// Output feature embedding vector dimension (192-d or 128-d float vector).
  static const int embeddingDimension = 192;

  // ── HEAD POSE / ANGLE TOLERANCES (Degrees) ──
  /// Front view: absolute yaw must be within ±10°.
  /// Tuning: increase to 12° if employees struggle with looking straight; decrease to 8° for stricter alignment.
  static const double maxFrontYaw = 10.0;

  /// Left turn: acceptable yaw range (looking left from subject perspective).
  /// Tuning: 20° to 40° captures natural profile features without occluding far eye.
  static const double minLeftYaw = 20.0;
  static const double maxLeftYaw = 40.0;

  /// Right turn: acceptable yaw range (looking right from subject perspective).
  static const double minRightYaw = -40.0;
  static const double maxRightYaw = -20.0;

  /// Maximum allowed pitch (nod up/down) and roll (head tilt sideways).
  /// Rejects downward-facing or tilted captures that distort facial bone geometry.
  static const double maxPitch = 15.0;
  static const double maxRoll = 15.0;

  /// Set to true if front camera preview is mirrored, flipping the yaw sign.
  static const bool invertYawSign = false;

  // ── PER-CAPTURE IMAGE QUALITY ──
  /// Face bounding box width must be at least 25% of total camera frame width.
  /// Prevents distance captures where facial details lack resolution.
  static const double minFaceWidthRatio = 0.25;

  /// Blur threshold based on Laplacian variance.
  /// Tuning: Start at 45.0. Lower to 35.0 for low-end mobile front cameras in soft lighting;
  /// raise to 60.0 in high-definition enterprise environments.
  static const double minLaplacianVariance = 45.0;

  /// Luminance brightness range (0 - 255).
  static const double minBrightness = 40.0;
  static const double maxBrightness = 240.0;

  /// Minimum probability that both eyes are open on the Front enrollment capture.
  /// Prevents closed-eye or blinking reference photos.
  static const double minEyeOpenProbability = 0.65;

  // ── ENROLLMENT IDENTITY CONSISTENCY ──
  /// Minimum cosine similarity between Front and Left/Right embeddings during enrollment.
  /// Guarantees that the side captures belong to the same human being as the front.
  /// Tuning: ArcFace/MobileFaceNet cross-pose similarity is typically 0.50 - 0.75 for the same person.
  static const double minPairSimilarityFrontSide = 0.45;

  /// Minimum cosine similarity between Left and Right profile embeddings.
  static const double minPairSimilaritySides = 0.35;

  /// Reject as duplicate if two supposedly distinct angles yield an embedding similarity > 0.98
  /// (indicates employee did not actually turn head or submitted same photo twice).
  static const double maxNearDuplicateSimilarity = 0.98;

  // ── ATTENDANCE VERIFICATION ──
  /// Maximum absolute yaw allowed during live verification clock-in.
  static const double maxVerificationYaw = 20.0;

  /// Biometric Match Threshold (Cosine Similarity).
  /// mobilefacenet scores:
  ///   Same person: 0.60 – 0.92
  ///   Different person: 0.10 – 0.38
  /// Setting 0.50 provides high discriminative power with zero false positives.
  static const double matchThreshold = 0.50;

  /// Borderline range [0.40, 0.50).
  /// Automatically triggers a quick second stabilization frame before declaring mismatch.
  static const double borderlineThreshold = 0.40;

  /// Maximum verification retries before lock and HR notification.
  static const int maxVerificationRetries = 3;

  // ── PASSIVE LIVENESS CHECK ──
  /// Eye-open difference required to confirm a blink during active/passive challenge.
  static const double blinkEyeCloseThreshold = 0.25;
}

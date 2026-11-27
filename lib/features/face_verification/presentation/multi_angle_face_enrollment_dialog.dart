import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/face_config.dart';
import '../../../core/services/face_embedding_service.dart';

/// A guided 3-angle biometric face enrollment dialog compliant with India DPDP Act.
///
/// Features:
/// 1. Biometric Consent Screen (DPDP compliance: purpose, retention, deletion rights)
/// 2. Camera-only capture (no gallery/file picker fallback to prevent spoofing)
/// 3. Google ML Kit real head Euler angle verification (Yaw/Pitch/Roll)
/// 4. Face quality gate (Laplacian blur, brightness, minimum size, eye-openness)
/// 5. MobileFaceNet deep feature embedding generation (192-d L2 normalized)
/// 6. Cross-angle identity verification (Front vs Left/Right consistency check)
/// 7. Near-duplicate angle rejection (> 0.98 similarity)
/// 8. Embeddings saved to Cloud Firestore (zero raw image uploads to Supabase)
/// 9. Delete Biometric Data action
class MultiAngleFaceEnrollmentDialog extends StatefulWidget {
  final String staffDocId;
  final String staffName;
  final String? resourceId;

  const MultiAngleFaceEnrollmentDialog({
    super.key,
    required this.staffDocId,
    required this.staffName,
    this.resourceId,
    // Kept as optional parameters for backward compatibility with existing callers
    String? existingFrontUrl,
    String? existingLeftUrl,
    String? existingRightUrl,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String staffDocId,
    required String staffName,
    String? resourceId,
    String? existingFrontUrl,
    String? existingLeftUrl,
    String? existingRightUrl,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiAngleFaceEnrollmentDialog(
        staffDocId: staffDocId,
        staffName: staffName,
        resourceId: resourceId,
      ),
    );
  }

  @override
  State<MultiAngleFaceEnrollmentDialog> createState() =>
      _MultiAngleFaceEnrollmentDialogState();
}

class _MultiAngleFaceEnrollmentDialogState
    extends State<MultiAngleFaceEnrollmentDialog>
    with SingleTickerProviderStateMixin {
  // ── Flow State ──
  // Step -1: Consent screen, 0: Front, 1: Left, 2: Right, 3: Saving
  bool _consentGiven = false;
  int _currentAngleIndex = 0;

  final List<String> _angleLabels = [
    'Front Face (Look Straight)',
    'Left Profile (Turn Head Left ~30°)',
    'Right Profile (Turn Head Right ~30°)',
  ];

  final List<String> _angleInstructions = [
    'Look straight into the camera lens with eyes wide open.',
    'Turn your head slowly about 30° to your LEFT (keep phone steady).',
    'Turn your head slowly about 30° to your RIGHT (keep phone steady).',
  ];

  final List<IconData> _angleIcons = [
    Icons.face_rounded,
    Icons.turn_left_rounded,
    Icons.turn_right_rounded,
  ];

  // Captured raw frames & computed embeddings for [front, left, right]
  final List<Uint8List?> _capturedBytes = [null, null, null];
  final List<List<double>?> _embeddings = [null, null, null];
  final List<double?> _capturedYaws = [null, null, null];

  // Camera state
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitializing = true;
  bool _isCapturing = false;
  bool _isValidating = false;
  String? _validationStatusText;
  String? _successMessage;
  bool _isSaving = false;
  double _saveProgress = 0.0;
  String? _saveStatusText;
  String? _errorMessage;

  // Sweep animation
  late AnimationController _sweepCtrl;
  late Animation<double> _sweepAnim;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _sweepAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _sweepCtrl, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras != null && _availableCameras!.isNotEmpty) {
        final frontIndex = _availableCameras!.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        _selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;
        await _setupCameraController(_availableCameras![_selectedCameraIndex]);
      } else {
        if (mounted) setState(() => _isCameraInitializing = false);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _isCameraInitializing = false);
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    final old = _cameraController;
    if (old != null) await old.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Setup camera error: $e');
      if (mounted) setState(() => _isCameraInitializing = false);
    }
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras == null || _availableCameras!.length < 2) return;
    final next = (_selectedCameraIndex + 1) % _availableCameras!.length;
    _selectedCameraIndex = next;
    setState(() => _isCameraInitializing = true);
    await _setupCameraController(_availableCameras![next]);
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // POSE VALIDATION PER ANGLE
  // ─────────────────────────────────────────────────────────────
  String? _validateAnglePose(int angleIndex, double yaw) {
    switch (angleIndex) {
      case 0: // Front: within +/- maxFrontYaw (10°)
        if (yaw.abs() > FaceConfig.maxFrontYaw) {
          final dir = yaw > 0 ? 'left' : 'right';
          return 'Face is turned $dir (${yaw.toStringAsFixed(1)}°). Please look straight at the camera (tolerance: ±${FaceConfig.maxFrontYaw.toInt()}°).';
        }
        return null;

      case 1: // Left profile: yaw should be +20° to +40°
        if (yaw < FaceConfig.minLeftYaw) {
          return 'Please turn head further to your LEFT. Current: ${yaw.toStringAsFixed(1)}° (Required: ${FaceConfig.minLeftYaw.toInt()}° to ${FaceConfig.maxLeftYaw.toInt()}°).';
        }
        if (yaw > FaceConfig.maxLeftYaw) {
          return 'Turned too far left (${yaw.toStringAsFixed(1)}°). Slightly turn back towards center (Max: ${FaceConfig.maxLeftYaw.toInt()}°).';
        }
        return null;

      case 2: // Right profile: yaw should be -20° to -40°
        if (yaw > FaceConfig.maxRightYaw) {
          return 'Please turn head further to your RIGHT. Current: ${yaw.toStringAsFixed(1)}° (Required: ${FaceConfig.minRightYaw.toInt()}° to ${FaceConfig.maxRightYaw.toInt()}°).';
        }
        if (yaw < FaceConfig.minRightYaw) {
          return 'Turned too far right (${yaw.toStringAsFixed(1)}°). Slightly turn back towards center (Min: ${FaceConfig.minRightYaw.toInt()}°).';
        }
        return null;

      default:
        return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CAPTURE & EMBEDDING EXTRACTION
  // ─────────────────────────────────────────────────────────────
  Future<void> _captureCurrentAngle() async {
    if (_isCapturing || _isValidating) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _errorMessage = 'Camera is not ready. Please wait or check camera permissions.');
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
      _successMessage = null;
      _validationStatusText = 'Capturing frame...';
    });
    HapticFeedback.mediumImpact();

    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();

      setState(() {
        _isValidating = true;
        _validationStatusText = 'Analyzing face geometry & pose with ML Kit...';
      });

      // 1. Detect face and run strict quality & pose checks
      final faceInfo = await FaceEmbeddingService.detectFace(
        bytes,
        isFrontCapture: _currentAngleIndex == 0,
      );

      if (!faceInfo.isValid) {
        setState(() {
          _isValidating = false;
          _errorMessage = faceInfo.errorMessage ?? 'Face quality check failed.';
        });
        HapticFeedback.heavyImpact();
        return;
      }

      // 2. Validate angle yaw with real headEulerAngleY
      final poseError = _validateAnglePose(_currentAngleIndex, faceInfo.yaw);
      if (poseError != null) {
        setState(() {
          _isValidating = false;
          _errorMessage = poseError;
        });
        HapticFeedback.heavyImpact();
        return;
      }

      // 3. Crop & Align (112x112 normalized tensor)
      setState(() {
        _validationStatusText = 'Generating deep biometric embedding...';
      });

      final normalizedTensor = FaceEmbeddingService.cropAndAlign(
        image: faceInfo.decodedImage!,
        boundingBox: faceInfo.mlKitFace!.boundingBox,
      );

      // 4. Extract MobileFaceNet embedding vector
      final embedding = await FaceEmbeddingService.embed(normalizedTensor);

      if (!mounted) return;

      setState(() {
        _capturedBytes[_currentAngleIndex] = bytes;
        _embeddings[_currentAngleIndex] = embedding;
        _capturedYaws[_currentAngleIndex] = faceInfo.yaw;
        _successMessage =
            '${_angleLabels[_currentAngleIndex]} verified! (Yaw: ${faceInfo.yaw.toStringAsFixed(1)}°)';
        _errorMessage = null;
        _isValidating = false;

        // Auto-advance to next angle
        if (_currentAngleIndex < 2) {
          _currentAngleIndex++;
        }
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Enrollment capture error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Capture/Detection failed: $e';
          _isValidating = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CROSS-ANGLE IDENTITY & INTEGRITY VALIDATION
  // ─────────────────────────────────────────────────────────────
  String? _validateEnrollmentConsistency() {
    final frontEmb = _embeddings[0];
    final leftEmb = _embeddings[1];
    final rightEmb = _embeddings[2];

    if (frontEmb == null || leftEmb == null || rightEmb == null) {
      return 'Please complete capture for all 3 angles.';
    }

    // Pair similarities
    final simFrontLeft = FaceEmbeddingService.cosineSimilarity(frontEmb, leftEmb);
    final simFrontRight = FaceEmbeddingService.cosineSimilarity(frontEmb, rightEmb);
    final simLeftRight = FaceEmbeddingService.cosineSimilarity(leftEmb, rightEmb);

    // Consistency check: same person across poses
    if (simFrontLeft < FaceConfig.minPairSimilarityFrontSide) {
      return 'Left profile does not match front view (Similarity: ${(simFrontLeft * 100).toStringAsFixed(1)}% < ${FaceConfig.minPairSimilarityFrontSide * 100}%). Ensure the same person is turning.';
    }

    if (simFrontRight < FaceConfig.minPairSimilarityFrontSide) {
      return 'Right profile does not match front view (Similarity: ${(simFrontRight * 100).toStringAsFixed(1)}% < ${FaceConfig.minPairSimilarityFrontSide * 100}%). Ensure the same person is turning.';
    }

    if (simLeftRight < FaceConfig.minPairSimilaritySides) {
      return 'Left and right profiles have low consistency (${(simLeftRight * 100).toStringAsFixed(1)}%). Please retake side angles.';
    }

    // Near-duplicate check (> 0.98 similarity indicates lack of head movement)
    if (simFrontLeft > FaceConfig.maxNearDuplicateSimilarity) {
      return 'Left profile appears identical to front face. Please turn your head a full 30° to the left.';
    }

    if (simFrontRight > FaceConfig.maxNearDuplicateSimilarity) {
      return 'Right profile appears identical to front face. Please turn your head a full 30° to the right.';
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE EMBEDDINGS TO FIRESTORE (NO SUPABASE UPLOAD)
  // ─────────────────────────────────────────────────────────────
  Future<void> _saveBiometricEnrollment() async {
    final consistencyError = _validateEnrollmentConsistency();
    if (consistencyError != null) {
      setState(() => _errorMessage = consistencyError);
      return;
    }

    setState(() {
      _isSaving = true;
      _saveProgress = 0.20;
      _saveStatusText = 'Validating biometric templates...';
      _errorMessage = null;
    });

    try {
      final embeddingsData = {
        'front': _embeddings[0]!,
        'left': _embeddings[1]!,
        'right': _embeddings[2]!,
      };

      setState(() {
        _saveProgress = 0.60;
        _saveStatusText = 'Storing encrypted feature vectors in Cloud Firestore...';
      });

      final payload = {
        'isFaceEnrolled': true,
        'faceEmbeddings': embeddingsData,
        'faceModelVersion': FaceConfig.modelVersion,
        'faceEnrolledAt': FieldValue.serverTimestamp(),
        'faceEnrolledBy': widget.staffDocId,
        'biometricConsentTimestamp': FieldValue.serverTimestamp(),
        'biometricConsentVersion': 'DPDP-2023-V1',
        // Clean legacy URL fields to complete migration away from Supabase
        'faceFrontUrl': FieldValue.delete(),
        'faceLeftUrl': FieldValue.delete(),
        'faceRightUrl': FieldValue.delete(),
        'facePhotoUrl': FieldValue.delete(),
        'faceAngleUrls': FieldValue.delete(),
      };

      // 1. Write to invigilators/{id}
      await FirebaseFirestore.instance
          .collection('invigilators')
          .doc(widget.staffDocId)
          .set(payload, SetOptions(merge: true));

      setState(() {
        _saveProgress = 0.85;
        _saveStatusText = 'Updating staff credentials...';
      });

      // 2. Also update users/{id} if doc exists
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.staffDocId)
            .get();
        if (userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.staffDocId)
              .set(payload, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Non-critical: user doc update skipped: $e');
      }

      setState(() {
        _saveProgress = 1.0;
        _saveStatusText = 'Biometric Enrollment Complete!';
      });
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Firestore save error: $e');
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save biometric data: $e';
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE BIOMETRIC DATA (RIGHT TO ERASURE UNDER DPDP ACT)
  // ─────────────────────────────────────────────────────────────
  Future<void> _deleteFaceData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Biometric Data?'),
        content: const Text(
          'Under the Digital Personal Data Protection Act, this will permanently erase your face embeddings from DutyDesk. You will need to re-enroll before taking any exam duties.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _saveStatusText = 'Erasing biometric data...';
    });

    try {
      final deletePayload = {
        'isFaceEnrolled': false,
        'faceEmbeddings': FieldValue.delete(),
        'faceModelVersion': FieldValue.delete(),
        'faceEnrolledAt': FieldValue.delete(),
        'faceFrontUrl': FieldValue.delete(),
        'faceLeftUrl': FieldValue.delete(),
        'faceRightUrl': FieldValue.delete(),
        'facePhotoUrl': FieldValue.delete(),
        'faceAngleUrls': FieldValue.delete(),
        'biometricDeletedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('invigilators')
          .doc(widget.staffDocId)
          .set(deletePayload, SetOptions(merge: true));

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.staffDocId)
            .get();
        if (userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.staffDocId)
              .set(deletePayload, SetOptions(merge: true));
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Biometric face data erased successfully.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Could not erase data: $e';
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF007A87);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_consentGiven) {
      return _buildConsentScreen(brandColor, isDark);
    }

    return _buildEnrollmentScreen(brandColor, isDark);
  }

  // ─────────────────────────────────────────────────────────────
  // CONSENT SCREEN (INDIA DPDP ACT 2023 COMPLIANCE)
  // ─────────────────────────────────────────────────────────────
  Widget _buildConsentScreen(Color brandColor, bool isDark) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.security_rounded, color: brandColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometric Data Consent',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'DPDP Act (India) Biometric Protection Notice',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notice of Purpose & Data Handling:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Purpose: Facial feature vectors are processed solely to verify your presence at assigned exam centers and prevent proxy invigilation.\n'
                    '• Privacy First: Raw face photos are NOT stored on remote servers. Only mathematical embeddings (192 numbers) are encrypted in Cloud Firestore.\n'
                    '• Retention & Erasure: You have the right to withdraw consent and delete your biometric data at any time from your profile.',
                    style: TextStyle(fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('I Consent & Proceed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _consentGiven = true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MAIN ENROLLMENT SCREEN
  // ─────────────────────────────────────────────────────────────
  Widget _buildEnrollmentScreen(Color brandColor, bool isDark) {
    final allAnglesCaptured = _embeddings.every((e) => e != null);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            // ── Header Banner ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF007A87), Color(0xFF005B66)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3-Angle Face Enrollment (TFLite)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${widget.staffName} ${widget.resourceId != null ? "• ID: ${widget.resourceId}" : ""}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                    tooltip: 'Delete Biometric Data',
                    onPressed: _isSaving ? null : _deleteFaceData,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Angle Selection Tabs ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: List.generate(3, (idx) {
                  final isCurrent = _currentAngleIndex == idx;
                  final isCaptured = _embeddings[idx] != null;
                  final color = isCaptured
                      ? const Color(0xFF10B981)
                      : (isCurrent ? brandColor : Colors.grey.shade400);

                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _currentAngleIndex = idx),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? brandColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent ? brandColor : Colors.grey.withValues(alpha: 0.25),
                            width: isCurrent ? 1.8 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isCaptured ? Icons.check_circle_rounded : _angleIcons[idx],
                              size: 18,
                              color: color,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              idx == 0 ? 'Front' : (idx == 1 ? 'Left ~30°' : 'Right ~30°'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                color: isCurrent ? brandColor : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Viewport Area ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Column(
                  children: [
                    // Guidance Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: brandColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(_angleIcons[_currentAngleIndex], size: 18, color: brandColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _angleInstructions[_currentAngleIndex],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF005B66),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Camera / Preview Box
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _embeddings[_currentAngleIndex] != null
                              ? const Color(0xFF10B981)
                              : brandColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Frozen Snapshot or Live Camera Feed
                          if (_capturedBytes[_currentAngleIndex] != null)
                            Image.memory(
                              _capturedBytes[_currentAngleIndex]!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          else if (_cameraController != null &&
                              _cameraController!.value.isInitialized)
                            Center(
                              child: CameraPreview(_cameraController!),
                            )
                          else if (_isCameraInitializing)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: brandColor),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Initializing Camera...',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Center(
                              child: Text(
                                'Camera unavailable. Please check permissions.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),

                          // 2. Oval Biometric Guide
                          IgnorePointer(
                            child: Container(
                              width: 170,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: const BorderRadius.all(Radius.elliptical(85, 110)),
                                border: Border.all(
                                  color: _embeddings[_currentAngleIndex] != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF22D3EE),
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),

                          // 3. Scan Ray
                          if (_capturedBytes[_currentAngleIndex] == null &&
                              !_isValidating &&
                              _cameraController != null &&
                              _cameraController!.value.isInitialized)
                            AnimatedBuilder(
                              animation: _sweepAnim,
                              builder: (context, _) => Positioned(
                                top: 250 * _sweepAnim.value,
                                left: 30,
                                right: 30,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22D3EE),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF22D3EE).withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // 4. Camera Switch Button
                          if (_availableCameras != null &&
                              _availableCameras!.length > 1 &&
                              !_isValidating &&
                              _capturedBytes[_currentAngleIndex] == null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filledTonal(
                                icon: const Icon(Icons.flip_camera_ios, size: 18),
                                onPressed: _toggleCamera,
                              ),
                            ),

                          // 5. Yaw Watermark
                          if (_capturedYaws[_currentAngleIndex] != null)
                            Positioned(
                              bottom: 8,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Yaw: ${_capturedYaws[_currentAngleIndex]!.toStringAsFixed(1)}°',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // 6. Validation Overlay
                          if (_isValidating)
                            Container(
                              color: Colors.black.withValues(alpha: 0.80),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: Color(0xFF22D3EE)),
                                  const SizedBox(height: 12),
                                  Text(
                                    _validationStatusText ?? 'Analyzing biometric frame...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Capture / Retake Buttons
                    Row(
                      children: [
                        if (_capturedBytes[_currentAngleIndex] != null) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retake Angle'),
                              onPressed: (_isValidating || _isCapturing)
                                  ? null
                                  : () => setState(() {
                                        _capturedBytes[_currentAngleIndex] = null;
                                        _embeddings[_currentAngleIndex] = null;
                                        _capturedYaws[_currentAngleIndex] = null;
                                        _errorMessage = null;
                                        _successMessage = null;
                                      }),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: _isValidating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _capturedBytes[_currentAngleIndex] != null
                                        ? Icons.arrow_forward_rounded
                                        : Icons.camera_alt_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _isValidating
                                  ? 'Processing...'
                                  : (_capturedBytes[_currentAngleIndex] != null
                                      ? (_currentAngleIndex < 2 ? 'Next Angle' : 'Review & Save')
                                      : 'Capture Angle ${_currentAngleIndex + 1}/3'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: (_isCapturing || _isValidating)
                                ? null
                                : () {
                                    if (_capturedBytes[_currentAngleIndex] != null) {
                                      if (_currentAngleIndex < 2) {
                                        setState(() => _currentAngleIndex++);
                                      }
                                    } else {
                                      _captureCurrentAngle();
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Error Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF87171), width: 1.2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Success Banner
                    if (_successMessage != null && _errorMessage == null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF065F46),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── 3-Angle Thumbnail Preview Strip ──
                    Row(
                      children: List.generate(3, (i) {
                        final b = _capturedBytes[i];
                        final isSel = _currentAngleIndex == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _currentAngleIndex = i),
                            child: Container(
                              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                              height: 60,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel
                                      ? brandColor
                                      : (b != null ? const Color(0xFF10B981) : Colors.grey.shade400),
                                  width: isSel ? 2.0 : 1.0,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: b != null
                                  ? Stack(
                                      children: [
                                        Image.memory(b, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.camera_alt_outlined, size: 16, color: Colors.grey.shade500),
                                          Text(
                                            i == 0 ? 'Front' : (i == 1 ? 'Left' : 'Right'),
                                            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),

                    if (_isSaving) ...[
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          LinearProgressIndicator(value: _saveProgress, color: brandColor),
                          const SizedBox(height: 6),
                          Text(
                            _saveStatusText ?? 'Saving biometric data...',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandColor),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer: Save to Firestore ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_done_rounded),
                  label: const Text(
                    'Save Face Embeddings to Firestore',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allAnglesCaptured ? const Color(0xFF10B981) : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (allAnglesCaptured && !_isSaving) ? _saveBiometricEnrollment : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

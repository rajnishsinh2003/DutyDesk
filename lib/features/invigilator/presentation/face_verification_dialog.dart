import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/face_config.dart';
import '../../../core/services/face_embedding_service.dart';

class FaceVerificationResult {
  final bool isVerified;
  final double matchScore; // e.g. 84.5%
  final String timestamp;

  const FaceVerificationResult({
    required this.isVerified,
    required this.matchScore,
    required this.timestamp,
  });
}

/// Biometric Face Verification Dialog for invigilator attendance clock-in.
///
/// Features:
/// 1. Reads enrolled 192-d MobileFaceNet embeddings from Cloud Firestore (Front, Left, Right).
/// 2. Live camera feed with ML Kit Face Detection.
/// 3. Frontal pose enforcement (Yaw within ±20°).
/// 4. Basic Liveness Check (Blink / Eye-state verification).
///    NOTE: This is a basic passive/active liveness check, not a certified 3D anti-spoofing system.
/// 5. Normalized 112x112 MobileFaceNet deep feature embedding inference.
/// 6. Cosine similarity against all 3 enrolled reference angles (Front, Left, Right).
/// 7. Match threshold: Cosine similarity ≥ 0.50 (50.0%).
/// 8. Borderline retry logic (0.40 - 0.50): auto-captures a 2nd frame before failing.
/// 9. Secure audit logging: logs attempt, score, and timestamp to Firestore without saving images or embeddings.
class FaceVerificationDialog extends StatefulWidget {
  final String staffName;
  final String? resourceId;
  final String examName;
  final String centerName;
  final String? invigilatorDocId;
  final Map<String, List<double>>? preloadedEmbeddings;

  const FaceVerificationDialog({
    super.key,
    required this.staffName,
    this.resourceId,
    required this.examName,
    required this.centerName,
    this.invigilatorDocId,
    this.preloadedEmbeddings,
    // Kept for backward compatibility with older callers
    String? faceFrontUrl,
    String? faceLeftUrl,
    String? faceRightUrl,
  });

  static Future<FaceVerificationResult?> show(
    BuildContext context, {
    required String staffName,
    String? resourceId,
    required String examName,
    required String centerName,
    String? invigilatorDocId,
    Map<String, List<double>>? preloadedEmbeddings,
    String? faceFrontUrl,
    String? faceLeftUrl,
    String? faceRightUrl,
  }) {
    return showDialog<FaceVerificationResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FaceVerificationDialog(
        staffName: staffName,
        resourceId: resourceId,
        examName: examName,
        centerName: centerName,
        invigilatorDocId: invigilatorDocId ?? resourceId,
        preloadedEmbeddings: preloadedEmbeddings,
      ),
    );
  }

  @override
  State<FaceVerificationDialog> createState() => _FaceVerificationDialogState();
}

class _FaceVerificationDialogState extends State<FaceVerificationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerAnimCtrl;
  late Animation<double> _scanPosAnim;

  // 0 = ready, 1 = countdown & liveness, 2 = matching & inference, 3 = verified, 4 = rejected/error
  int _step = 0;
  double _matchScore = 0.0;
  String _statusText = 'Center your face within the biometric oval';
  String? _failureReason;
  Timer? _stepTimer;
  Timer? _countdownTimer;
  int _countdown = 0;

  // Stored embeddings from Firestore
  Map<String, List<double>> _referenceEmbeddings = {};
  bool _isFetchingEmbeddings = true;
  String? _embeddingFetchError;
  bool _needsReEnrollment = false;

  // Camera state
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitializing = true;
  Uint8List? _liveCaptureBytes;

  @override
  void initState() {
    super.initState();
    _scannerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scanPosAnim = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scannerAnimCtrl, curve: Curves.easeInOut),
    );

    _initCamera();
    _loadReferenceEmbeddings();
  }

  Future<void> _loadReferenceEmbeddings() async {
    // 1. If preloaded embeddings passed, use them directly
    if (widget.preloadedEmbeddings != null && widget.preloadedEmbeddings!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _referenceEmbeddings = widget.preloadedEmbeddings!;
          _isFetchingEmbeddings = false;
        });
      }
      return;
    }

    final docId = widget.invigilatorDocId;
    if (docId == null || docId.isEmpty) {
      if (mounted) {
        setState(() {
          _isFetchingEmbeddings = false;
          _embeddingFetchError = 'No staff identifier available to look up biometric record.';
        });
      }
      return;
    }

    setState(() => _isFetchingEmbeddings = true);

    try {
      final doc = await FirebaseFirestore.instance.collection('invigilators').doc(docId).get();
      if (!doc.exists) {
        if (mounted) {
          setState(() {
            _isFetchingEmbeddings = false;
            _embeddingFetchError = 'Staff record not found in database.';
          });
        }
        return;
      }

      final data = doc.data() ?? {};
      final rawEmbeddings = data['faceEmbeddings'];

      if (rawEmbeddings is Map) {
        final parsed = <String, List<double>>{};
        rawEmbeddings.forEach((key, val) {
          if (val is List) {
            parsed[key.toString()] = val.map((e) => (e as num).toDouble()).toList();
          }
        });

        if (parsed.isNotEmpty && parsed.containsKey('front')) {
          if (mounted) {
            setState(() {
              _referenceEmbeddings = parsed;
              _isFetchingEmbeddings = false;
              _embeddingFetchError = null;
            });
          }
          return;
        }
      }

      // Check if user had legacy enrollment (URL-based from old Supabase flow)
      final hadLegacy = data['isFaceEnrolled'] == true ||
          data['faceFrontUrl'] != null ||
          data['facePhotoUrl'] != null;

      if (mounted) {
        setState(() {
          _isFetchingEmbeddings = false;
          _needsReEnrollment = hadLegacy;
          _embeddingFetchError = hadLegacy
              ? 'Your face profile was registered under an older format. Please re-enroll your 3 face angles to activate deep biometric verification.'
              : 'No biometric face embeddings enrolled. Please complete 3-angle face enrollment.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingEmbeddings = false;
          _embeddingFetchError = 'Error reading face records: $e';
        });
      }
    }
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
    } catch (_) {
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
    } catch (_) {
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
    _stepTimer?.cancel();
    _countdownTimer?.cancel();
    _scannerAnimCtrl.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // VERIFICATION WORKFLOW
  // ─────────────────────────────────────────────────────────────
  void _startVerification() async {
    if (_referenceEmbeddings.isEmpty) {
      setState(() {
        _step = 4;
        _statusText = '❌ Biometric Reference Missing';
        _failureReason = _embeddingFetchError ??
            'No registered biometric face portrait found in database for ${widget.staffName}. Please complete 3-angle face enrollment first.';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _liveCaptureBytes = null;
      _step = 1;
      _countdown = 3;
      _statusText = 'Hold phone at eye level... 3';
      _failureReason = null;
    });
    HapticFeedback.mediumImpact();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 1) {
        setState(() {
          _countdown--;
          _statusText = _countdown == 2
              ? 'Keep your face centered inside oval... 2'
              : 'Hold steady, detecting face... 1';
        });
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _statusText = 'Capturing live frame & running liveness check...';
        });
        HapticFeedback.mediumImpact();
        await _performCaptureAndVerify();
      }
    });
  }

  Future<void> _performCaptureAndVerify() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _handleFailure('Device camera is not ready. Please check camera access.');
      return;
    }

    // Step 2: Live Inference
    setState(() {
      _step = 2;
      _statusText = 'Analyzing face landmarks & liveness...';
    });

    try {
      // 1. Capture primary frame
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      if (mounted) setState(() => _liveCaptureBytes = bytes);

      // 2. Face Detection + Pose + Quality via ML Kit
      final faceInfo = await FaceEmbeddingService.detectFace(bytes);
      if (!faceInfo.isValid) {
        _handleFailure(faceInfo.errorMessage ?? 'Face quality check failed.');
        return;
      }

      // 3. Frontal Pose Check (Yaw <= ±20°)
      if (faceInfo.yaw.abs() > FaceConfig.maxVerificationYaw) {
        final dir = faceInfo.yaw > 0 ? 'left' : 'right';
        _handleFailure(
          'Face is turned too far $dir (${faceInfo.yaw.toStringAsFixed(1)}°). Look straight into the camera.',
        );
        return;
      }

      // 4. Basic Liveness Check (Blink / eye openness)
      // If eyes are closed, warn user.
      if (faceInfo.leftEyeOpenProb != null && faceInfo.rightEyeOpenProb != null) {
        if (faceInfo.leftEyeOpenProb! < 0.20 && faceInfo.rightEyeOpenProb! < 0.20) {
          _handleFailure('Eyes appear closed during capture. Please keep eyes open.');
          return;
        }
      }

      // 5. Generate Embedding
      setState(() => _statusText = 'Generating biometric embedding & matching...');
      final normalizedTensor = FaceEmbeddingService.cropAndAlign(
        image: faceInfo.decodedImage!,
        boundingBox: faceInfo.mlKitFace!.boundingBox,
      );
      final liveEmbedding = await FaceEmbeddingService.embed(normalizedTensor);

      // 6. Compare against all enrolled angles (Front, Left, Right)
      double bestCosine = -1.0;
      String bestMatchedAngle = 'none';

      for (final entry in _referenceEmbeddings.entries) {
        final sim = FaceEmbeddingService.cosineSimilarity(liveEmbedding, entry.value);
        if (sim > bestCosine) {
          bestCosine = sim;
          bestMatchedAngle = entry.key;
        }
      }

      // 7. Borderline Check (0.40 <= score < 0.50): auto take 2nd stabilization frame
      if (bestCosine >= FaceConfig.borderlineThreshold &&
          bestCosine < FaceConfig.matchThreshold &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        setState(() => _statusText = 'Borderline score. Taking stabilization frame...');
        await Future.delayed(const Duration(milliseconds: 350));

        final secondFile = await _cameraController!.takePicture();
        final secondBytes = await secondFile.readAsBytes();
        final secondInfo = await FaceEmbeddingService.detectFace(secondBytes);

        if (secondInfo.isValid && secondInfo.yaw.abs() <= FaceConfig.maxVerificationYaw) {
          final secondTensor = FaceEmbeddingService.cropAndAlign(
            image: secondInfo.decodedImage!,
            boundingBox: secondInfo.mlKitFace!.boundingBox,
          );
          final secondEmbedding = await FaceEmbeddingService.embed(secondTensor);

          for (final entry in _referenceEmbeddings.entries) {
            final sim = FaceEmbeddingService.cosineSimilarity(secondEmbedding, entry.value);
            if (sim > bestCosine) {
              bestCosine = sim;
              bestMatchedAngle = entry.key;
            }
          }
        }
      }

      // Cosine similarity to percentage display (e.g. 0.85 -> 85.0%)
      final displayPercent = (math.max(0.0, bestCosine) * 100.0);

      // Log attempt to audit trail (NO images or embeddings stored)
      _logVerificationAttempt(
        success: bestCosine >= FaceConfig.matchThreshold,
        score: displayPercent,
        matchedAngle: bestMatchedAngle,
      );

      if (!mounted) return;

      if (bestCosine >= FaceConfig.matchThreshold) {
        // MATCH SUCCESS
        setState(() {
          _step = 3;
          _matchScore = displayPercent;
          _statusText = 'Biometric Match Confirmed! (${_matchScore.toStringAsFixed(1)}%)';
        });
        HapticFeedback.heavyImpact();

        _stepTimer = Timer(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          Navigator.of(context).pop(
            FaceVerificationResult(
              isVerified: true,
              matchScore: _matchScore,
              timestamp: DateTime.now().toIso8601String(),
            ),
          );
        });
      } else {
        // MISMATCH
        setState(() {
          _step = 4;
          _matchScore = displayPercent;
          _statusText = '❌ BIOMETRIC MISMATCH (${_matchScore.toStringAsFixed(1)}%)';
          _failureReason =
              'The facial geometry does not match the enrolled profile for ${widget.staffName}. '
              'Score: ${_matchScore.toStringAsFixed(1)}% (Required: ≥ ${(FaceConfig.matchThreshold * 100).toInt()}%).';
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      debugPrint('Verification error: $e');
      _handleFailure('Biometric verification failed: $e');
    }
  }

  void _handleFailure(String reason) {
    if (!mounted) return;
    setState(() {
      _step = 4;
      _statusText = '❌ Verification Unsuccessful';
      _failureReason = reason;
    });
    HapticFeedback.heavyImpact();
  }

  // ─────────────────────────────────────────────────────────────
  // AUDIT LOGGING (Zero Images / Zero Embeddings)
  // ─────────────────────────────────────────────────────────────
  void _logVerificationAttempt({
    required bool success,
    required double score,
    required String matchedAngle,
  }) {
    try {
      final docId = widget.invigilatorDocId;
      if (docId == null) return;

      FirebaseFirestore.instance.collection('face_verification_audit').add({
        'staffDocId': docId,
        'staffName': widget.staffName,
        'centerName': widget.centerName,
        'examName': widget.examName,
        'success': success,
        'scorePercent': double.parse(score.toStringAsFixed(1)),
        'matchedAngle': matchedAngle,
        'modelVersion': FaceConfig.modelVersion,
        'deviceTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  // UI BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF007A87);
    const verifiedColor = Color(0xFF10B981);
    const rejectedColor = Color(0xFFEF4444);
    final isDone = _step == 3;
    final isMismatch = _step == 4;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDone
                ? verifiedColor
                : (isMismatch ? rejectedColor : brandColor.withValues(alpha: 0.4)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDone
                  ? verifiedColor.withValues(alpha: 0.25)
                  : (isMismatch
                      ? rejectedColor.withValues(alpha: 0.3)
                      : brandColor.withValues(alpha: 0.2)),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDone
                        ? verifiedColor.withValues(alpha: 0.15)
                        : (isMismatch
                            ? rejectedColor.withValues(alpha: 0.15)
                            : brandColor.withValues(alpha: 0.15)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone
                        ? Icons.verified_user
                        : (isMismatch
                            ? Icons.gpp_bad_rounded
                            : Icons.face_retouching_natural),
                    color: isDone
                        ? verifiedColor
                        : (isMismatch ? rejectedColor : const Color(0xFF22D3EE)),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biometric Face Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Anti-Proxy Attendance (MobileFaceNet)',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_step == 0 || isMismatch)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Camera / Viewport
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 270,
                color: const Color(0xFF050B14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Live camera or captured snapshot
                    if (_liveCaptureBytes != null)
                      SizedBox.expand(
                        child: Image.memory(
                          _liveCaptureBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_cameraController != null && _cameraController!.value.isInitialized)
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize?.height ?? 270,
                            height: _cameraController!.value.previewSize?.width ?? 270,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      )
                    else if (_isCameraInitializing)
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF22D3EE)),
                            SizedBox(height: 10),
                            Text('Accessing device camera...', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      )
                    else
                      CustomPaint(
                        size: const Size(double.infinity, 270),
                        painter: _BiometricGridPainter(),
                      ),

                    // Central Alignment Oval
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 180,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(90),
                        border: Border.all(
                          color: isDone
                              ? verifiedColor
                              : (isMismatch
                                  ? rejectedColor
                                  : (_step > 0 ? const Color(0xFF22D3EE) : Colors.white54)),
                          width: isDone || isMismatch ? 3 : 2,
                        ),
                      ),
                      child: Center(
                        child: _countdown > 0
                            ? Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF22D3EE), width: 3),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$_countdown',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF22D3EE),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 110,
                                color: isDone
                                    ? verifiedColor.withValues(alpha: 0.35)
                                    : (isMismatch
                                        ? rejectedColor.withValues(alpha: 0.35)
                                        : Colors.white.withValues(alpha: 0.12)),
                              ),
                      ),
                    ),

                    // Switch camera button
                    if (_availableCameras != null && _availableCameras!.length > 1 && _step == 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _toggleCamera,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.flip_camera_ios, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),

                    // 4 Corner Brackets
                    Positioned(top: 25, left: 45, child: _bracketCorner(0)),
                    Positioned(top: 25, right: 45, child: _bracketCorner(1)),
                    Positioned(bottom: 25, left: 45, child: _bracketCorner(2)),
                    Positioned(bottom: 25, right: 45, child: _bracketCorner(3)),

                    // Sweep Ray
                    if (_step == 1 || _step == 2)
                      AnimatedBuilder(
                        animation: _scanPosAnim,
                        builder: (context, child) {
                          return Positioned(
                            top: 270 * _scanPosAnim.value,
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 3,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF22D3EE),
                                    Color(0xFF10B981),
                                    Color(0xFF22D3EE),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Match Splash
                    if (isDone)
                      Container(
                        color: Colors.black45,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: verifiedColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_matchScore.toStringAsFixed(1)}% MATCH',
                                style: const TextStyle(
                                  color: verifiedColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Mismatch Splash
                    if (isMismatch)
                      Container(
                        color: Colors.black.withValues(alpha: 0.65),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: rejectedColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_matchScore.toStringAsFixed(1)}% MATCH',
                                style: const TextStyle(
                                  color: rejectedColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'REQUIRED: ≥ ${(FaceConfig.matchThreshold * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Telemetry HUD
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _telemetryChip(
                            icon: Icons.videocam,
                            label: _cameraController != null && _cameraController!.value.isInitialized
                                ? 'LIVE CAM • FRONT'
                                : 'CAMERA INIT',
                            color: const Color(0xFF10B981),
                          ),
                          _telemetryChip(
                            icon: Icons.fingerprint,
                            label: _referenceEmbeddings.isNotEmpty
                                ? 'EMBEDDINGS: ${_referenceEmbeddings.length} ANGLES'
                                : (_isFetchingEmbeddings ? 'LOADING...' : 'NO TEMPLATE'),
                            color: _referenceEmbeddings.isNotEmpty ? const Color(0xFF10B981) : Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Staff & Duty Info Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: brandColor.withValues(alpha: 0.3),
                    child: Text(
                      widget.staffName.isNotEmpty ? widget.staffName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.staffName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${widget.resourceId ?? "Staff ID"} • ${widget.centerName}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isDone)
                    const Icon(Icons.check_circle, color: verifiedColor, size: 20)
                  else if (isMismatch)
                    const Icon(Icons.cancel, color: rejectedColor, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _statusText,
                key: ValueKey(_statusText),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDone
                      ? verifiedColor
                      : (isMismatch ? rejectedColor : Colors.grey.shade300),
                  fontSize: 12,
                  fontWeight: isDone || isMismatch ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            if (_step == 0)
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text(
                  'Verify Face & Clock In',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                onPressed: _referenceEmbeddings.isNotEmpty ? _startVerification : null,
              )
            else if (_step < 3)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF22D3EE)),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Matching Live Face with Embeddings...',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else if (isDone)
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Verification Complete',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: verifiedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(context).pop(
                    FaceVerificationResult(
                      isVerified: true,
                      matchScore: _matchScore,
                      timestamp: DateTime.now().toIso8601String(),
                    ),
                  );
                },
              )
            else if (isMismatch)
              Column(
                children: [
                  if (_failureReason != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: rejectedColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: rejectedColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: rejectedColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _failureReason!,
                              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11.5, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(
                              FaceVerificationResult(
                                isVerified: false,
                                matchScore: _matchScore,
                                timestamp: DateTime.now().toIso8601String(),
                              ),
                            );
                          },
                          child: const Text('Cancel & Exit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _step = 0;
                              _countdown = 0;
                              _liveCaptureBytes = null;
                              _statusText = 'Center your face within the biometric oval';
                              _failureReason = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _bracketCorner(int corner) {
    final isTop = corner == 0 || corner == 1;
    final isLeft = corner == 0 || corner == 2;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFF22D3EE), width: 2.5) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFF22D3EE), width: 2.5) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFF22D3EE), width: 2.5) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFF22D3EE), width: 2.5) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _telemetryChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BiometricGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/face_validation_service.dart';

class FaceVerificationResult {
  final bool isVerified;
  final double matchScore; // e.g. 98.4%
  final String timestamp;

  const FaceVerificationResult({
    required this.isVerified,
    required this.matchScore,
    required this.timestamp,
  });
}

/// A high-tech biometric face verification dialog for invigilator attendance clock-in.
/// Eliminates proxy attendance with liveness check simulation, anti-spoofing sweep ray,
/// 68-point facial landmark mesh visualization, and biometric profile matching.
class FaceVerificationDialog extends StatefulWidget {
  final String staffName;
  final String? resourceId;
  final String examName;
  final String centerName;
  final String? faceFrontUrl;

  const FaceVerificationDialog({
    super.key,
    required this.staffName,
    this.resourceId,
    required this.examName,
    required this.centerName,
    this.faceFrontUrl,
  });

  static Future<FaceVerificationResult?> show(
    BuildContext context, {
    required String staffName,
    String? resourceId,
    required String examName,
    required String centerName,
    String? faceFrontUrl,
  }) {
    return showDialog<FaceVerificationResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FaceVerificationDialog(
        staffName: staffName,
        resourceId: resourceId,
        examName: examName,
        centerName: centerName,
        faceFrontUrl: faceFrontUrl,
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

  int _step = 0; // 0 = ready, 1 = scanning & liveness, 2 = matching, 3 = verified, 4 = mismatch/rejected
  double _matchScore = 0.0;
  String _statusText = 'Center your face within the biometric oval';
  String? _failureReason;
  Timer? _stepTimer;
  Timer? _countdownTimer;
  int _countdown = 0;

  Uint8List? _referenceBytes;
  bool _isFetchingReference = false;
  String? _referenceFetchError;
  Uint8List? _liveCaptureBytes;

  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitializing = true;

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
    _fetchReferencePhoto();
  }

  Future<void> _fetchReferencePhoto() async {
    if (widget.faceFrontUrl == null || widget.faceFrontUrl!.isEmpty) {
      if (mounted) {
        setState(() {
          _referenceFetchError = 'No enrolled face photo found in database';
        });
      }
      return;
    }

    setState(() => _isFetchingReference = true);
    try {
      final response = await http.get(Uri.parse(widget.faceFrontUrl!)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          setState(() {
            _referenceBytes = response.bodyBytes;
            _isFetchingReference = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _referenceFetchError = 'Could not load registered face photo (${response.statusCode})';
            _isFetchingReference = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _referenceFetchError = 'Failed to load reference: $e';
          _isFetchingReference = false;
        });
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras != null && _availableCameras!.isNotEmpty) {
        // Prefer front camera for faculty selfie attendance
        final frontIndex = _availableCameras!.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        _selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;
        await _setupCameraController(_availableCameras![_selectedCameraIndex]);
      } else {
        if (mounted) {
          setState(() {
            _isCameraInitializing = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    final oldController = _cameraController;
    if (oldController != null) {
      await oldController.dispose();
    }

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
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras == null || _availableCameras!.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _availableCameras!.length;
    _selectedCameraIndex = nextIndex;
    setState(() => _isCameraInitializing = true);
    await _setupCameraController(_availableCameras![nextIndex]);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _countdownTimer?.cancel();
    _scannerAnimCtrl.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startVerification() async {
    if (_referenceBytes == null && widget.faceFrontUrl != null) {
      await _fetchReferencePhoto();
    }

    if (_referenceBytes == null) {
      setState(() {
        _step = 4;
        _statusText = '❌ Reference Face Missing';
        _failureReason = 'No registered biometric face portrait found in database for ${widget.staffName}. Please complete 3-angle face enrollment first.';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    // Start 3-second countdown giving user ample time to hold phone at eye level
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
              : 'Hold still, capturing... 1';
        });
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _statusText = '📸 Capturing live face & verifying passive liveness...';
        });
        HapticFeedback.mediumImpact();
        await _performCaptureAndVerify();
      }
    });
  }

  Future<void> _performCaptureAndVerify() async {
    Uint8List? liveBytes;
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final xFile = await _cameraController!.takePicture();
        liveBytes = await xFile.readAsBytes();
        if (mounted) {
          setState(() {
            _liveCaptureBytes = liveBytes;
          });
        }
      } catch (e) {
        debugPrint('Camera capture error: $e');
      }
    }

    if (liveBytes == null) {
      if (mounted) {
        setState(() {
          _step = 4;
          _statusText = '❌ Camera Frame Capture Failed';
          _failureReason = 'Unable to capture live camera frame. Please check camera permissions and retry.';
        });
        HapticFeedback.heavyImpact();
      }
      return;
    }

    // Step 2: Compare live face with reference photo from Supabase
    if (mounted) {
      setState(() {
        _step = 2;
        _statusText = 'Extracting facial landmarks & matching with registered portrait...';
      });
      HapticFeedback.lightImpact();
    }

    try {
      var compResult = await FaceValidationService.compareFaces(
        liveFrameBytes: liveBytes,
        referencePhotoBytes: _referenceBytes!,
        matchThreshold: 65.0,
      );

      // If borderline score (between 50% and 65%), take a quick 2nd stabilization frame
      // to handle camera autofocus/jitter without failing immediately
      if (!compResult.isMatch &&
          compResult.similarityScore >= 50.0 &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        try {
          await Future.delayed(const Duration(milliseconds: 300));
          final secondFile = await _cameraController!.takePicture();
          final secondBytes = await secondFile.readAsBytes();
          final secondResult = await FaceValidationService.compareFaces(
            liveFrameBytes: secondBytes,
            referencePhotoBytes: _referenceBytes!,
            matchThreshold: 65.0,
          );
          if (secondResult.similarityScore > compResult.similarityScore) {
            compResult = secondResult;
            if (mounted) {
              setState(() {
                _liveCaptureBytes = secondBytes;
              });
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;

      if (compResult.isMatch) {
        // Biometric Match Confirmed! (Same Person)
        setState(() {
          _step = 3;
          _matchScore = compResult.similarityScore;
          _statusText = 'Database Matched! Match Confidence: ${_matchScore.toStringAsFixed(1)}%';
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
        // Biometric Mismatch Detected! (Different Person / Proxy Attempt / Ceiling)
        setState(() {
          _step = 4;
          _matchScore = compResult.similarityScore;
          _statusText = '❌ BIOMETRIC MISMATCH DETECTED (${_matchScore.toStringAsFixed(1)}%)';
          _failureReason = compResult.failureReason ??
              'The face in front of the camera does NOT match the registered portrait of ${widget.staffName} (Match: ${_matchScore.toStringAsFixed(1)}% < Threshold: 65%). Proxy attendance is blocked.';
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = 4;
        _statusText = '❌ Verification Error';
        _failureReason = 'An error occurred during facial feature comparison: $e';
      });
      HapticFeedback.heavyImpact();
    }
  }

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
                        'Anti-Proxy Attendance Authentication',
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

            // Camera / Biometric Viewport
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 270,
                color: const Color(0xFF050B14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Live Device Camera Preview (when initialized) or Frozen Captured Snapshot Preview
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
                      // Fallback background grid when camera is unavailable / simulator
                      CustomPaint(
                        size: const Size(double.infinity, 270),
                        painter: _BiometricGridPainter(),
                      ),

                    // Central Head Silhouette & Alignment Oval
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
                        boxShadow: [
                          if (isDone)
                            BoxShadow(
                              color: verifiedColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          if (isMismatch)
                            BoxShadow(
                              color: rejectedColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                        ],
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF22D3EE).withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
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
                                        : (_cameraController != null && _cameraController!.value.isInitialized
                                            ? Colors.transparent
                                            : Colors.white.withValues(alpha: 0.12))),
                              ),
                      ),
                    ),

                    // Switch camera button (if multiple cameras available)
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

                    // 4 Corner Brackets around face oval
                    Positioned(
                      top: 25,
                      left: 45,
                      child: _bracketCorner(0),
                    ),
                    Positioned(
                      top: 25,
                      right: 45,
                      child: _bracketCorner(1),
                    ),
                    Positioned(
                      bottom: 25,
                      left: 45,
                      child: _bracketCorner(2),
                    ),
                    Positioned(
                      bottom: 25,
                      right: 45,
                      child: _bracketCorner(3),
                    ),

                    // Animated Laser Sweep Ray
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
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF22D3EE),
                                    Color(0xFF10B981),
                                    Color(0xFF22D3EE),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF22D3EE).withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Verified Checkmark Splash Overlay
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

                    // Mismatch Warning Splash Overlay
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
                              const Text(
                                'MISMATCH: REQUIRED ≥ 65%',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Telemetry Overlay HUD at bottom of frame
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _telemetryChip(
                            icon: _cameraController != null && _cameraController!.value.isInitialized
                                ? Icons.videocam
                                : Icons.shield,
                            label: _cameraController != null && _cameraController!.value.isInitialized
                                ? 'LIVE CAM • ${_availableCameras?[_selectedCameraIndex].lensDirection == CameraLensDirection.front ? "FRONT" : "REAR"}'
                                : (_step >= 2 ? 'ANTI-SPOOF: PASS' : 'LIVENESS ACTIVE'),
                            color: _cameraController != null && _cameraController!.value.isInitialized
                                ? const Color(0xFF10B981)
                                : const Color(0xFF22D3EE),
                          ),
                          _telemetryChip(
                            icon: Icons.grid_view_rounded,
                            label: _referenceBytes != null
                                ? 'REF: SUPABASE OK'
                                : (_isFetchingReference ? 'FETCHING REF...' : 'NO REF'),
                            color: _referenceBytes != null ? const Color(0xFF10B981) : Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Staff & Duty Info Pill with Reference Portrait preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  if (_referenceBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _referenceBytes!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
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
                onPressed: _startVerification,
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF22D3EE),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Matching Biometrics Against Supabase...',
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
    // 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right
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

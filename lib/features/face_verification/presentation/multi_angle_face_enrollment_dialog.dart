import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/supabase_face_storage_service.dart';
import '../../../core/services/face_validation_service.dart';

/// A guided 3-angle biometric face enrollment dialog.
/// Captures: Front View, Slight Left, and Slight Right.
/// Uploads photos directly to Supabase Storage and links to Firebase Firestore.
class MultiAngleFaceEnrollmentDialog extends StatefulWidget {
  final String staffDocId;
  final String staffName;
  final String? resourceId;
  final String? existingFrontUrl;
  final String? existingLeftUrl;
  final String? existingRightUrl;

  const MultiAngleFaceEnrollmentDialog({
    super.key,
    required this.staffDocId,
    required this.staffName,
    this.resourceId,
    this.existingFrontUrl,
    this.existingLeftUrl,
    this.existingRightUrl,
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
        existingFrontUrl: existingFrontUrl,
        existingLeftUrl: existingLeftUrl,
        existingRightUrl: existingRightUrl,
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
  // ── Step management ──
  // 0: Angle 1 (Front), 1: Angle 2 (Left), 2: Angle 3 (Right), 3: Review & Upload
  int _currentAngleIndex = 0;

  final List<String> _angleLabels = [
    'Front Face (Look Straight)',
    'Left Profile (Turn Head Left)',
    'Right Profile (Turn Head Right)',
  ];

  final List<String> _angleInstructions = [
    'Center your face inside the oval and look straight at the camera.',
    'Slowly turn your face approximately 30° to your LEFT.',
    'Slowly turn your face approximately 30° to your RIGHT.',
  ];

  final List<IconData> _angleIcons = [
    Icons.face_rounded,
    Icons.turn_left_rounded,
    Icons.turn_right_rounded,
  ];

  // Captured image bytes for each angle: [front, left, right]
  final List<Uint8List?> _capturedBytes = [null, null, null];

  // Camera state
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitializing = true;
  bool _isCapturing = false;
  bool _isValidating = false;
  String? _validationStatusText;
  String? _successMessage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadStatusText;
  String? _errorMessage;

  // Visual scan sweep animation
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

  // ── Capture Action ──
  Future<void> _captureCurrentAngle() async {
    if (_isCapturing || _isValidating) return;
    setState(() {
      _isCapturing = true;
      _errorMessage = null;
      _successMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      Uint8List? bytes;

      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        bytes = await xFile.readAsBytes();
      } else {
        // Fallback: FilePicker if camera is unavailable
        final result = await FilePicker.pickFiles(
          type: FileType.image,
        );
        if (result.isNotEmpty) {
          bytes = await result.first.readAsBytes();
        }
      }

      if (bytes != null) {
        setState(() {
          _isValidating = true;
          _validationStatusText = 'Validating angle & removing background...';
        });

        final validation = await FaceValidationService.validateAndProcess(
          imageBytes: bytes,
          angleIndex: _currentAngleIndex,
        );

        if (!mounted) return;

        if (validation.isValid && validation.processedBytes != null) {
          setState(() {
            _capturedBytes[_currentAngleIndex] = validation.processedBytes!;
            _successMessage = validation.message;
            _errorMessage = null;
            _isValidating = false;
            if (_currentAngleIndex < 2) {
              _currentAngleIndex++;
            }
          });
          HapticFeedback.lightImpact();
        } else {
          setState(() {
            _isValidating = false;
            _errorMessage = validation.message +
                (validation.suggestion != null ? '\n💡 ${validation.suggestion}' : '');
          });
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Capture failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isValidating = false;
        });
      }
    }
  }

  Future<void> _pickFromFile(int angleIndex) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (result.isNotEmpty) {
        final rawBytes = await result.first.readAsBytes();
        setState(() {
          _isValidating = true;
          _validationStatusText = 'Validating selected image...';
          _errorMessage = null;
          _successMessage = null;
        });

        final validation = await FaceValidationService.validateAndProcess(
          imageBytes: rawBytes,
          angleIndex: angleIndex,
        );

        if (!mounted) return;

        if (validation.isValid && validation.processedBytes != null) {
          setState(() {
            _capturedBytes[angleIndex] = validation.processedBytes!;
            _successMessage = validation.message;
            _errorMessage = null;
            _isValidating = false;
          });
          HapticFeedback.lightImpact();
        } else {
          setState(() {
            _isValidating = false;
            _errorMessage = validation.message +
                (validation.suggestion != null ? '\n💡 ${validation.suggestion}' : '');
          });
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'File selection error: $e');
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  // ── Upload to Supabase & Firebase ──
  Future<void> _uploadAllAngles() async {
    if (_capturedBytes.any((b) => b == null)) {
      setState(() => _errorMessage = 'Please capture all 3 face angles before saving.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.05;
      _uploadStatusText = 'Connecting to Supabase Storage...';
      _errorMessage = null;
    });

    try {
      // 1. Upload Front Angle
      setState(() {
        _uploadProgress = 0.25;
        _uploadStatusText = 'Uploading Front Face to Supabase...';
      });
      final frontUrl = await SupabaseFaceStorageService.uploadFaceImage(
        invigilatorId: widget.staffDocId,
        angleName: 'front',
        imageBytes: _capturedBytes[0]!,
      );

      // 2. Upload Left Angle
      setState(() {
        _uploadProgress = 0.55;
        _uploadStatusText = 'Uploading Left Profile to Supabase...';
      });
      final leftUrl = await SupabaseFaceStorageService.uploadFaceImage(
        invigilatorId: widget.staffDocId,
        angleName: 'left',
        imageBytes: _capturedBytes[1]!,
      );

      // 3. Upload Right Angle
      setState(() {
        _uploadProgress = 0.80;
        _uploadStatusText = 'Uploading Right Profile to Supabase...';
      });
      final rightUrl = await SupabaseFaceStorageService.uploadFaceImage(
        invigilatorId: widget.staffDocId,
        angleName: 'right',
        imageBytes: _capturedBytes[2]!,
      );

      // 4. Synchronize into Firebase Firestore
      setState(() {
        _uploadProgress = 0.95;
        _uploadStatusText = 'Syncing biometric references with Firebase...';
      });
      await SupabaseFaceStorageService.saveEnrollmentToFirebase(
        invigilatorDocId: widget.staffDocId,
        frontUrl: frontUrl,
        leftUrl: leftUrl,
        rightUrl: rightUrl,
      );

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatusText = 'Biometric Enrollment Complete!';
      });
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF007A87);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAnglesCaptured = _capturedBytes.every((b) => b != null);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: brandColor.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
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
                          'Biometric Face ID Enrollment',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _isUploading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Angle Progress Tabs (Front, Left, Right) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: List.generate(3, (idx) {
                  final isCurrent = _currentAngleIndex == idx;
                  final isCaptured = _capturedBytes[idx] != null;
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
                              idx == 0 ? 'Front' : (idx == 1 ? 'Left' : 'Right'),
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

            // ── Main Viewport Area ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Column(
                  children: [
                    // Instructions pill
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
                        border: Border.all(color: brandColor.withValues(alpha: 0.5), width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Live Camera Feed or Frozen Captured Photo
                          if (_capturedBytes[_currentAngleIndex] != null)
                            Image.memory(
                              _capturedBytes[_currentAngleIndex]!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          else if (_cameraController != null &&
                              _cameraController!.value.isInitialized)
                            Transform.scale(
                              scale: 1.0,
                              child: Center(
                                child: CameraPreview(_cameraController!),
                              ),
                            )
                          else if (_isCameraInitializing)
                            const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: brandColor),
                                  SizedBox(height: 10),
                                  Text('Initializing Camera...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40),
                                  const SizedBox(height: 8),
                                  const Text('Camera unavailable', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.upload_file, size: 16),
                                    label: const Text('Pick Image File'),
                                    onPressed: () => _pickFromFile(_currentAngleIndex),
                                  ),
                                ],
                              ),
                            ),

                          // 2. Oval Biometric Face Alignment Guide
                          IgnorePointer(
                            child: Container(
                              width: 170,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: const BorderRadius.all(Radius.elliptical(85, 110)),
                                border: Border.all(
                                  color: _capturedBytes[_currentAngleIndex] != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF007A87),
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),

                          // 2b. Angle Direction Guidance Badge inside Oval
                          if (_capturedBytes[_currentAngleIndex] == null && !_isValidating)
                            Positioned(
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _currentAngleIndex == 0
                                        ? const Color(0xFF007A87)
                                        : const Color(0xFFF59E0B),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_currentAngleIndex == 1) ...[
                                      const Icon(Icons.arrow_back_rounded, color: Color(0xFFF59E0B), size: 14),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      _currentAngleIndex == 0
                                          ? 'LOOK STRAIGHT AHEAD'
                                          : (_currentAngleIndex == 1
                                              ? 'TURN HEAD ~30° LEFT'
                                              : 'TURN HEAD ~30° RIGHT'),
                                      style: TextStyle(
                                        color: _currentAngleIndex == 0 ? Colors.white : const Color(0xFFFDE68A),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (_currentAngleIndex == 2) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded, color: Color(0xFFF59E0B), size: 14),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                          // 3. Sweep scan ray if camera live
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
                                    color: brandColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: brandColor.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // 4. Camera Switch Button (Top Right)
                          if (_availableCameras != null && _availableCameras!.length > 1 && !_isValidating)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filledTonal(
                                icon: const Icon(Icons.flip_camera_ios, size: 18),
                                onPressed: _toggleCamera,
                              ),
                            ),

                          // 5. Angle Watermark Badge
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
                                _angleLabels[_currentAngleIndex],
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          // 6. Validation Analysis Overlay
                          if (_isValidating)
                            Container(
                              color: Colors.black.withValues(alpha: 0.75),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: Color(0xFF10B981)),
                                  const SizedBox(height: 12),
                                  Text(
                                    _validationStatusText ?? 'Validating face position & angle...',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Detecting angle & isolating face background...',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Capture / Retake Button Bar
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
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Icon(
                                    _capturedBytes[_currentAngleIndex] != null
                                        ? Icons.arrow_forward_rounded
                                        : Icons.camera_alt_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _isValidating
                                  ? 'Validating Face...'
                                  : (_capturedBytes[_currentAngleIndex] != null
                                      ? (_currentAngleIndex < 2 ? 'Next Angle' : 'Review All')
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
                    const SizedBox(height: 16),

                    // Validation Success / Guidance Feedback Banners
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
                                style: const TextStyle(color: Color(0xFF065F46), fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

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
                                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── 3-Angle Thumbnail Strip ──
                    Row(
                      children: List.generate(3, (i) {
                        final b = _capturedBytes[i];
                        final isSel = _currentAngleIndex == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _currentAngleIndex = i),
                            child: Container(
                              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? brandColor : (b != null ? const Color(0xFF10B981) : Colors.grey.shade400),
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
                                            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_a_photo_outlined, size: 16, color: Colors.grey.shade500),
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

                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          LinearProgressIndicator(value: _uploadProgress, color: brandColor),
                          const SizedBox(height: 6),
                          Text(
                            _uploadStatusText ?? 'Processing...',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandColor),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer Action Bar: Save to Supabase ──
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
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text(
                    'Upload & Save 3 Angles to Supabase',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allAnglesCaptured ? const Color(0xFF10B981) : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (allAnglesCaptured && !_isUploading) ? _uploadAllAngles : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


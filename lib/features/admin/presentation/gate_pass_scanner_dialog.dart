import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../providers/invigilator_provider.dart';

/// Entrance gate QR code and ID badge scanner for Center Superintendents & Observers.
class GatePassScannerDialog extends ConsumerStatefulWidget {
  final String? activeCenterName;

  const GatePassScannerDialog({super.key, this.activeCenterName});

  static Future<void> show(BuildContext context, {String? activeCenterName}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GatePassScannerDialog(activeCenterName: activeCenterName),
    );
  }

  @override
  ConsumerState<GatePassScannerDialog> createState() => _GatePassScannerDialogState();
}

class _GatePassScannerDialogState extends ConsumerState<GatePassScannerDialog>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  bool _isCameraReady = false;

  late AnimationController _sweepCtrl;
  late Animation<double> _sweepAnim;

  final TextEditingController _manualInputCtrl = TextEditingController();
  ExamDuty? _scannedDuty;
  Invigilator? _scannedInvigilator;
  bool _isCenterMatch = true;
  String? _scanMessage;

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
        // Prefer rear camera for gate barcode/QR scanning
        final backIndex = _availableCameras!.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        final desc = _availableCameras![backIndex != -1 ? backIndex : 0];

        final controller = CameraController(
          desc,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await controller.initialize();
        if (mounted) {
          setState(() {
            _cameraController = controller;
            _isCameraReady = true;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isCameraReady = false);
    }
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _cameraController?.dispose();
    _manualInputCtrl.dispose();
    super.dispose();
  }

  void _processScannedPayload(String payload) {
    HapticFeedback.mediumImpact();
    final allDuties = ref.read(globalDutyProvider);
    final allInvs = ref.read(invigilatorProvider);

    // Payload can be: "DUTYDESK|<dutyId>|<resourceId>|<center>|<date>|<shift>" or just a Resource ID / Duty ID
    String query = payload.trim();
    if (query.startsWith('DUTYDESK|')) {
      final parts = query.split('|');
      if (parts.length >= 3) {
        query = parts[1]; // dutyId
      }
    }

    ExamDuty? matchedDuty;
    Invigilator? matchedInv;

    // Search by duty ID first
    try {
      matchedDuty = allDuties.firstWhere((d) => d.id.toLowerCase() == query.toLowerCase());
    } catch (_) {}

    // Search by resource ID if duty wasn't found directly
    if (matchedDuty == null) {
      try {
        matchedInv = allInvs.firstWhere((i) => i.resourceId.toLowerCase() == query.toLowerCase());
        matchedDuty = allDuties.firstWhere((d) => d.invigilatorId == matchedInv?.id);
      } catch (_) {}
    } else {
      try {
        matchedInv = allInvs.firstWhere((i) => i.id == matchedDuty?.invigilatorId);
      } catch (_) {}
    }

    if (matchedDuty != null && matchedInv != null) {
      final centerMatches = widget.activeCenterName == null ||
          widget.activeCenterName!.trim().isEmpty ||
          matchedDuty.centerName.toLowerCase() == widget.activeCenterName!.toLowerCase();

      setState(() {
        _scannedDuty = matchedDuty;
        _scannedInvigilator = matchedInv;
        _isCenterMatch = centerMatches;
        _scanMessage = centerMatches
            ? 'VERIFIED: Authorized for Gate Entry'
            : 'CENTER MISMATCH: Assigned to ${matchedDuty?.centerName}';
      });
    } else {
      setState(() {
        _scannedDuty = null;
        _scannedInvigilator = null;
        _scanMessage = 'No active duty schedule found matching "$query"';
      });
    }
  }

  Future<void> _admitStaff() async {
    if (_scannedDuty == null || _scannedInvigilator == null) return;
    HapticFeedback.heavyImpact();

    // Mark duty as reached/admitted at gate
    final notifier = ref.read(dutyProvider.notifier);
    await notifier.updateDutyStatus(_scannedDuty!.id, 'accepted');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_scannedInvigilator!.name} admitted and gate attendance logged!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF007A87);
    const verifiedColor = Color(0xFF10B981);
    const errorColor = Color(0xFFEF4444);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: brandColor.withValues(alpha: 0.25), blurRadius: 30, spreadRadius: 2),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF007A87),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gate Pass & QR Scanner',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            widget.activeCenterName != null
                                ? 'Active Gate: ${widget.activeCenterName}'
                                : 'All-Center Security Checkpoint',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // Viewport / Reticle Box
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 220,
                        color: const Color(0xFF050B14),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Live rear camera
                            if (_isCameraReady && _cameraController != null)
                              SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _cameraController!.value.previewSize?.height ?? 220,
                                    height: _cameraController!.value.previewSize?.width ?? 220,
                                    child: CameraPreview(_cameraController!),
                                  ),
                                ),
                              )
                            else
                              const Center(
                                child: Icon(Icons.qr_code_2, size: 80, color: Colors.white12),
                              ),

                            // Targeting Reticle Outline
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF22D3EE), width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),

                            // Animated Laser Beam
                            AnimatedBuilder(
                              animation: _sweepAnim,
                              builder: (context, child) {
                                return Positioned(
                                  top: 30 + 160 * _sweepAnim.value,
                                  left: 40,
                                  right: 40,
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
                                );
                              },
                            ),

                            // Status caption
                            Positioned(
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Align Faculty Gate Pass QR in Frame',
                                  style: TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Manual Search / Simulation Field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualInputCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter Resource ID / Duty ID...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                              prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF22D3EE)),
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onSubmitted: _processScannedPayload,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _processScannedPayload(_manualInputCtrl.text),
                          child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),

                    // Scanned Verification Result Card
                    if (_scannedDuty != null && _scannedInvigilator != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isCenterMatch
                              ? verifiedColor.withValues(alpha: 0.1)
                              : errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isCenterMatch ? verifiedColor : errorColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isCenterMatch ? Icons.verified : Icons.warning_amber_rounded,
                                  color: _isCenterMatch ? verifiedColor : errorColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _scanMessage ?? '',
                                    style: TextStyle(
                                      color: _isCenterMatch ? verifiedColor : errorColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 16),
                            Text(
                              _scannedInvigilator!.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Resource ID: ${_scannedInvigilator!.resourceId} • ${_scannedDuty!.examName}',
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                            ),
                            Text(
                              'Shift ${_scannedDuty!.shift} • Reporting: ${_scannedDuty!.reportingTime}',
                              style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            if (_isCenterMatch)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Admit Staff & Confirm Gate Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: verifiedColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _admitStaff,
                              ),
                          ],
                        ),
                      ),
                    ] else if (_scanMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: errorColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _scanMessage!,
                          style: const TextStyle(color: errorColor, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

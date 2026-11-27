import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
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
  late final MobileScannerController _scannerController;
  late AnimationController _sweepCtrl;
  late Animation<double> _sweepAnim;

  final TextEditingController _manualInputCtrl = TextEditingController();
  ExamDuty? _scannedDuty;
  Invigilator? _scannedInvigilator;
  bool _isCenterMatch = true;
  String? _scanMessage;
  bool _isAdmitting = false;
  bool _isScanning = false;
  String? _lastScannedPayload;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _sweepAnim = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _sweepCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _scannerController.dispose();
    _manualInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _processScannedPayload(String payload) async {
    final clean = payload.trim();
    if (clean.isEmpty || _isScanning) return;
    if (_lastScannedPayload == clean && _scannedDuty != null) return;

    _isScanning = true;
    _lastScannedPayload = clean;
    HapticFeedback.mediumImpact();

    final allDuties = ref.read(globalDutyProvider);
    final allInvs = ref.read(invigilatorProvider);

    // Payload format: "DUTYDESK|<dutyId>|<resourceId>|<center>|<date>|<shift>" or raw ID
    String query = clean;
    String? expectedResourceId;
    if (query.startsWith('DUTYDESK|')) {
      final parts = query.split('|');
      if (parts.length >= 2) {
        query = parts[1].trim(); // dutyId
      }
      if (parts.length >= 3) {
        expectedResourceId = parts[2].trim();
      }
    }

    ExamDuty? matchedDuty;
    Invigilator? matchedInv;

    // 1. Search by duty ID in global duties
    try {
      matchedDuty = allDuties.firstWhere((d) => d.id.toLowerCase() == query.toLowerCase());
    } catch (_) {}

    // 2. Direct Firestore fallback if duty not cached yet
    if (matchedDuty == null && query.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('duties').doc(query).get();
        if (doc.exists && doc.data() != null) {
          matchedDuty = ExamDuty.fromFirestore(doc.id, doc.data()!);
        }
      } catch (_) {}
    }

    // 3. Search by resource ID if duty wasn't matched directly
    if (matchedDuty == null && (expectedResourceId != null || query.isNotEmpty)) {
      final targetResId = expectedResourceId ?? query;
      try {
        matchedInv = allInvs.firstWhere((i) => i.resourceId.toLowerCase() == targetResId.toLowerCase());
        matchedDuty = allDuties.firstWhere((d) => d.invigilatorId == matchedInv?.id);
      } catch (_) {}

      // Fallback Firestore query for duties by invigilator
      if (matchedDuty == null && matchedInv != null) {
        try {
          final querySnap = await FirebaseFirestore.instance
              .collection('duties')
              .where('invigilatorId', isEqualTo: matchedInv.id)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            matchedDuty = ExamDuty.fromFirestore(querySnap.docs.first.id, querySnap.docs.first.data());
          }
        } catch (_) {}
      }
    }

    // 4. Resolve invigilator details
    if (matchedDuty != null) {
      try {
        matchedInv = allInvs.firstWhere((i) => i.id == matchedDuty!.invigilatorId);
      } catch (_) {}

      if (matchedInv == null) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(matchedDuty.invigilatorId).get();
          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data()!;
            matchedInv = Invigilator(
              id: userDoc.id,
              name: data['name'] ?? 'Invigilator',
              resourceId: data['resourceId'] ?? expectedResourceId ?? '',
              mobile: data['phone'] ?? data['mobile'] ?? '',
              mockDutyCount: 0,
            );
          }
        } catch (_) {}
      }
    }

    if (matchedDuty != null && matchedInv != null) {
      final centerMatches = widget.activeCenterName == null ||
          widget.activeCenterName!.trim().isEmpty ||
          matchedDuty.centerName.toLowerCase() == widget.activeCenterName!.toLowerCase();

      if (mounted) {
        setState(() {
          _scannedDuty = matchedDuty;
          _scannedInvigilator = matchedInv;
          _isCenterMatch = centerMatches;
          _scanMessage = centerMatches
              ? 'VERIFIED: Authorized for Gate Entry'
              : 'CENTER MISMATCH: Assigned to ${matchedDuty?.centerName}';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _scannedDuty = null;
          _scannedInvigilator = null;
          _scanMessage = 'No active duty schedule found matching "$query"';
        });
      }
    }

    // Small delay before allowing next scan
    await Future.delayed(const Duration(milliseconds: 800));
    _isScanning = false;
  }

  Future<void> _admitStaff() async {
    if (_scannedDuty == null || _scannedInvigilator == null || _isAdmitting) return;
    setState(() => _isAdmitting = true);
    HapticFeedback.heavyImpact();

    try {
      final now = DateTime.now();
      final timeStr = DateFormat('hh:mm a').format(now);
      final dateStr = DateFormat('yyyy-MM-dd').format(now);

      // 1. Mark duty accepted & reached at gate
      await FirebaseFirestore.instance.collection('duties').doc(_scannedDuty!.id).update({
        'status': 'accepted',
        'isReached': true,
        'reachedAt': FieldValue.serverTimestamp(),
        'reachedTime': timeStr,
        'reachedDate': dateStr,
        'reachedPerformance': 'Excellent',
        'reachedMessage': 'Admitted and gate verified by Center Superintendent',
      });

      // 2. Update local state
      ref.read(dutyProvider.notifier).updateDutyStatus(_scannedDuty!.id, 'accepted');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_scannedInvigilator!.name} admitted and gate attendance logged!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error admitting staff: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep subscriptions alive
    ref.watch(globalDutyProvider);
    ref.watch(invigilatorProvider);

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      icon: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                      tooltip: 'Toggle Flashlight',
                      onPressed: () => _scannerController.toggleTorch(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white, size: 20),
                      tooltip: 'Switch Camera',
                      onPressed: () => _scannerController.switchCamera(),
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
                    // Viewport / Reticle Box with live MobileScanner
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 220,
                        color: const Color(0xFF050B14),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Live MobileScanner Engine
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: (BarcodeCapture capture) {
                                for (final barcode in capture.barcodes) {
                                  final raw = barcode.rawValue;
                                  if (raw != null && raw.isNotEmpty) {
                                    _processScannedPayload(raw);
                                    break;
                                  }
                                }
                              },
                              errorBuilder: (context, error) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.no_photography_outlined, color: Colors.white38, size: 36),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Camera unavailable (${error.errorCode.name}). Use manual input below.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_scannedInvigilator!.faceFrontUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        _scannedInvigilator!.faceFrontUrl!,
                                        width: 54,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 54,
                                          height: 64,
                                          color: Colors.white12,
                                          child: const Icon(Icons.person, color: Colors.white54, size: 30),
                                        ),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _scannedInvigilator!.name,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                          if (_scannedInvigilator!.isFaceEnrolled)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.green.shade400, width: 0.8),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.verified, size: 10, color: Color(0xFF10B981)),
                                                  SizedBox(width: 3),
                                                  Text('Face Verified', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Resource ID: ${_scannedInvigilator!.resourceId} • ${_scannedDuty!.examName}',
                                        style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Center: ${_scannedDuty!.centerName}',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Shift ${_scannedDuty!.shift} • Reporting: ${_scannedDuty!.reportingTime} • Exam: ${_scannedDuty!.dutyStartTime} - ${_scannedDuty!.dutyEndTime}',
                              style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            if (_isCenterMatch)
                              ElevatedButton.icon(
                                icon: _isAdmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline, size: 18),
                                label: Text(
                                  _isAdmitting ? 'Logging Entry...' : 'Admit Staff & Confirm Gate Entry',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: verifiedColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(42),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _isAdmitting ? null : _admitStaff,
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

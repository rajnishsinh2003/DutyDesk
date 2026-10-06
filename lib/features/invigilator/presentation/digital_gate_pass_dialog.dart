import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/duty_provider.dart';
import '../../admin/providers/invigilator_provider.dart';

/// A secure digital Gate Pass & QR Duty Badge for invigilators to present at examination center gates.
class DigitalGatePassDialog extends StatelessWidget {
  final ExamDuty duty;
  final Invigilator invigilator;

  const DigitalGatePassDialog({
    super.key,
    required this.duty,
    required this.invigilator,
  });

  static Future<void> show(
    BuildContext context, {
    required ExamDuty duty,
    required Invigilator invigilator,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => DigitalGatePassDialog(
        duty: duty,
        invigilator: invigilator,
      ),
    );
  }

  String _buildQrPayload() {
    return 'DUTYDESK|${duty.id}|${invigilator.resourceId}|${duty.centerName}|${duty.date}|Shift${duty.shift}';
  }

  String _generateSecurityHash() {
    final raw = '${duty.id}_${invigilator.resourceId}_${duty.date}_DUTYDESK_SECURE';
    return raw.hashCode.toRadixString(16).toUpperCase().padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF007A87);
    final secHash = _generateSecurityHash();
    final qrPayload = _buildQrPayload();

    // Generate QR Code data structure
    final qrCode = QrCode.fromData(
      data: qrPayload,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: brandColor.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Security Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF007A87),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DutyDesk Examination Commission',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'OFFICIAL DIGITAL GATE PASS & BADGE',
                          style: TextStyle(color: Colors.white70, fontSize: 9.5, letterSpacing: 0.8),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Faculty Identity Row
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007A87), Color(0xFF22D3EE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            invigilator.name.isNotEmpty ? invigilator.name[0].toUpperCase() : 'S',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invigilator.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Resource ID: ${invigilator.resourceId}',
                              style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Mobile: ${invigilator.mobile}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 26),

                  // QR Code Container with Corner Reticles
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: CustomPaint(
                            painter: QrCodePainter(qrImage, color: const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SECURITY TOKEN: #$secHash',
                          style: const TextStyle(
                            color: Color(0xFF007A87),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duty Specs Matrix
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Center / Venue', duty.centerName, Icons.location_city_outlined),
                        const Divider(color: Colors.white10, height: 14),
                        _buildInfoRow('Exam Name', duty.examName, Icons.assignment_outlined),
                        const Divider(color: Colors.white10, height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow('Date', duty.date, Icons.calendar_today_outlined)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInfoRow('Shift', 'Shift ${duty.shift}', Icons.schedule)),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow('Report Time', duty.reportingTime, Icons.alarm_on)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildInfoRow(
                                'Status',
                                duty.status.toUpperCase(),
                                Icons.verified_user_outlined,
                                valueColor: duty.status.toLowerCase() == 'accepted'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Anti-counterfeit disclaimer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF22D3EE)),
                      const SizedBox(width: 6),
                      Text(
                        'Issued by Center Supdt • Valid on ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Share / Action button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share / Save Gate Pass', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final summary = 'DutyDesk Gate Pass\n'
                          'Staff: ${invigilator.name} (${invigilator.resourceId})\n'
                          'Exam: ${duty.examName}\n'
                          'Center: ${duty.centerName}\n'
                          'Date: ${duty.date} (Shift ${duty.shift})\n'
                          'Reporting: ${duty.reportingTime}\n'
                          'Token: #$secHash';
                      SharePlus.instance.share(ShareParams(text: summary, subject: 'DutyDesk Gate Pass'));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF22D3EE)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter that renders a QrImage on canvas.
class QrCodePainter extends CustomPainter {
  final QrImage qrImage;
  final Color color;

  QrCodePainter(this.qrImage, {this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final moduleCount = qrImage.moduleCount;
    final moduleSize = size.width / moduleCount;

    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          final rect = Rect.fromLTWH(
            x * moduleSize,
            y * moduleSize,
            moduleSize + 0.1, // Slight overlap prevents sub-pixel gaps
            moduleSize + 0.1,
          );
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

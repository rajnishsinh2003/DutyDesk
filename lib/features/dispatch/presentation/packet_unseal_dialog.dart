import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/question_paper_packet_model.dart';
import '../providers/question_paper_provider.dart';

class PacketUnsealDialog extends ConsumerStatefulWidget {
  final QuestionPaperPacket packet;

  const PacketUnsealDialog({super.key, required this.packet});

  static Future<void> show(BuildContext context, QuestionPaperPacket packet) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PacketUnsealDialog(packet: packet),
    );
  }

  @override
  ConsumerState<PacketUnsealDialog> createState() => _PacketUnsealDialogState();
}

class _PacketUnsealDialogState extends ConsumerState<PacketUnsealDialog> {
  final _formKey = GlobalKey<FormState>();

  final _w1NameCtrl = TextEditingController(text: 'Aditi Sharma');
  final _w1RollCtrl = TextEditingController(text: '23CS102');
  final _w2NameCtrl = TextEditingController(text: 'Rohan Gupta');
  final _w2RollCtrl = TextEditingController(text: '23CS118');
  final _invigilatorNameCtrl = TextEditingController(text: 'Prof. Ananya Roy');

  bool _isSealInspected = false;
  bool _isBookletCountConfirmed = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.packet.assignedInvigilatorName != null) {
      _invigilatorNameCtrl.text = widget.packet.assignedInvigilatorName!;
    }
    // Periodic refresh for time-lock countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _w1NameCtrl.dispose();
    _w1RollCtrl.dispose();
    _w2NameCtrl.dispose();
    _w2RollCtrl.dispose();
    _invigilatorNameCtrl.dispose();
    super.dispose();
  }

  void _submitUnseal() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isSealInspected || !_isBookletCountConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify all security checkboxes before unsealing.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    final witnesses = [
      StudentWitness(
        name: _w1NameCtrl.text.trim(),
        rollNumber: _w1RollCtrl.text.trim(),
        witnessedAt: DateTime.now(),
      ),
      StudentWitness(
        name: _w2NameCtrl.text.trim(),
        rollNumber: _w2RollCtrl.text.trim(),
        witnessedAt: DateTime.now(),
      ),
    ];

    final success = await ref.read(questionPaperProvider.notifier).unsealPacket(
      packetId: widget.packet.id,
      unsealedByName: _invigilatorNameCtrl.text.trim(),
      witnesses: witnesses,
      forceOverride: !widget.packet.isWithinUnsealWindow, // allows supervisor override if tested
    );

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Packet ${widget.packet.packetCode} successfully unsealed!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final p = widget.packet;

    final isLocked = now.isBefore(p.unlockWindowStart);
    final isWindowOpen = p.isWithinUnsealWindow;

    final timeFormat = DateFormat('hh:mm a');

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unseal Question Papers',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${p.packetCode} • ${p.roomName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time-Lock Status Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isWindowOpen
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : (isLocked
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isWindowOpen
                                ? const Color(0xFF10B981)
                                : (isLocked ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isWindowOpen
                                  ? Icons.lock_clock
                                  : (isLocked ? Icons.lock_rounded : Icons.timer_off_outlined),
                              color: isWindowOpen
                                  ? const Color(0xFF10B981)
                                  : (isLocked ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isWindowOpen
                                        ? '🟢 UNSEAL WINDOW ACTIVE'
                                        : (isLocked ? '🔒 TIME-LOCKED (SECURE)' : '⚠️ UNSEAL WINDOW EXPIRED'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isWindowOpen
                                          ? const Color(0xFF10B981)
                                          : (isLocked ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Authorized window: ${timeFormat.format(p.unlockWindowStart)} - ${timeFormat.format(p.unlockWindowEnd)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  if (isLocked)
                                    Text(
                                      'Opens in ${p.unlockWindowStart.difference(now).inMinutes}m ${p.unlockWindowStart.difference(now).inSeconds % 60}s',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Packet Details Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(label: 'Subject', value: '${p.subjectCode} - ${p.subjectName}'),
                            const SizedBox(height: 6),
                            _InfoRow(label: 'Booklets Enclosed', value: '${p.bookletCount} copies'),
                            const SizedBox(height: 6),
                            _InfoRow(label: 'Hologram Seal #', value: p.securitySealNumber),
                            const SizedBox(height: 6),
                            _InfoRow(label: 'Center & Room', value: '${p.centerName} (${p.roomName})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Unsealing Invigilator
                      TextFormField(
                        controller: _invigilatorNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Invigilator in Charge',
                          prefixIcon: Icon(Icons.person_pin_rounded, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 18),

                      // Student Witnesses (Statutory Requirement)
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 18, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          const Text(
                            'Mandatory Student Witnesses (2)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('STATUTORY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Witness 1
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _w1NameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Witness 1 Name',
                                prefixIcon: Icon(Icons.person_outline, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _w1RollCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Witness 2
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _w2NameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Witness 2 Name',
                                prefixIcon: Icon(Icons.person_outline, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _w2RollCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Checkboxes
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isSealInspected,
                        onChanged: (val) => setState(() => _isSealInspected = val ?? false),
                        title: const Text(
                          'I have shown the sealed envelope to student witnesses and verified that the tamper-evident hologram seal is undamaged.',
                          style: TextStyle(fontSize: 12),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isBookletCountConfirmed,
                        onChanged: (val) => setState(() => _isBookletCountConfirmed = val ?? false),
                        title: Text(
                          'I confirm that exactly ${p.bookletCount} question paper booklets are enclosed and match this subject/session.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(isLocked ? 'Override & Unseal' : 'Verify & Unseal Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWindowOpen
                          ? const Color(0xFF10B981)
                          : (isLocked ? const Color(0xFFEF4444) : const Color(0xFF2563EB)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitUnseal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

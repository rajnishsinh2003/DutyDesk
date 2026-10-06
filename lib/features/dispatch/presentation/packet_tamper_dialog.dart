import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_paper_packet_model.dart';
import '../providers/question_paper_provider.dart';

class PacketTamperDialog extends ConsumerStatefulWidget {
  final QuestionPaperPacket packet;

  const PacketTamperDialog({super.key, required this.packet});

  static Future<void> show(BuildContext context, QuestionPaperPacket packet) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PacketTamperDialog(packet: packet),
    );
  }

  @override
  ConsumerState<PacketTamperDialog> createState() => _PacketTamperDialogState();
}

class _PacketTamperDialogState extends ConsumerState<PacketTamperDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reporterCtrl = TextEditingController(text: 'Invigilator / Flying Squad');
  final _remarksCtrl = TextEditingController();
  String _tamperCategory = 'Broken / Peeled Tamper Hologram';

  @override
  void dispose() {
    _reporterCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.heavyImpact();

    final fullRemarks = '[$_tamperCategory] ${_remarksCtrl.text.trim()}';

    await ref.read(questionPaperProvider.notifier).reportTamper(
      packetId: widget.packet.id,
      reporterName: _reporterCtrl.text.trim(),
      remarks: fullRemarks,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 CRITICAL INCIDENT LOGGED! Alert sent to Control Room & COE.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.packet;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
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
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Tamper / Seal Breach',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                        ),
                        Text(
                          '${p.packetCode} • Seal #${p.securitySealNumber}',
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Filing this report will lock this packet, alert the University COE / Live Control Room, and auto-generate an exam incident report.',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        initialValue: _tamperCategory,
                        decoration: const InputDecoration(
                          labelText: 'Violation Category',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Broken / Peeled Tamper Hologram',
                            child: Text('Broken / Peeled Tamper Hologram'),
                          ),
                          DropdownMenuItem(
                            value: 'Torn or Cut Outer Envelope',
                            child: Text('Torn or Cut Outer Envelope'),
                          ),
                          DropdownMenuItem(
                            value: 'Barcode / Seal Mismatch',
                            child: Text('Barcode / Seal Mismatch'),
                          ),
                          DropdownMenuItem(
                            value: 'Booklet Count Shortage',
                            child: Text('Booklet Count Shortage'),
                          ),
                          DropdownMenuItem(
                            value: 'Wrong Subject Packet Delivered',
                            child: Text('Wrong Subject Packet Delivered'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _tamperCategory = val!),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _reporterCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reported By (Official)',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _remarksCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Detailed Observations & Evidence',
                          hintText: 'Describe physical damage, witness remarks, or custody gap...',
                          prefixIcon: Icon(Icons.description_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Please provide detailed observations' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
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
                    icon: const Icon(Icons.report_problem_rounded, size: 18),
                    label: const Text('Submit Security Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitReport,
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

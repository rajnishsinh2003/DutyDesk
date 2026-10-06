import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_paper_packet_model.dart';
import '../providers/question_paper_provider.dart';
import '../../admin/providers/invigilator_provider.dart';

enum HandoverType {
  strongroomCheckout,
  invigilatorReceive,
}

class PacketHandoverDialog extends ConsumerStatefulWidget {
  final QuestionPaperPacket packet;
  final HandoverType handoverType;

  const PacketHandoverDialog({
    super.key,
    required this.packet,
    required this.handoverType,
  });

  static Future<void> show(
    BuildContext context, {
    required QuestionPaperPacket packet,
    required HandoverType handoverType,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PacketHandoverDialog(
        packet: packet,
        handoverType: handoverType,
      ),
    );
  }

  @override
  ConsumerState<PacketHandoverDialog> createState() => _PacketHandoverDialogState();
}

class _PacketHandoverDialogState extends ConsumerState<PacketHandoverDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  final _notesCtrl = TextEditingController();
  String? _selectedInvigilatorId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.handoverType == HandoverType.strongroomCheckout
          ? (widget.packet.custodianName ?? 'Dr. Ramesh Sharma')
          : (widget.packet.assignedInvigilatorName ?? 'Prof. Ananya Roy'),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final notifier = ref.read(questionPaperProvider.notifier);

    if (widget.handoverType == HandoverType.strongroomCheckout) {
      await notifier.dispatchFromStrongroom(
        packetId: widget.packet.id,
        custodianName: _nameCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      await notifier.handoverToInvigilator(
        packetId: widget.packet.id,
        invigilatorId: _selectedInvigilatorId ?? widget.packet.assignedInvigilatorId ?? 'INV-01',
        invigilatorName: _nameCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Chain of custody updated for ${widget.packet.packetCode}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invs = ref.watch(invigilatorProvider);
    final p = widget.packet;

    final isCheckout = widget.handoverType == HandoverType.strongroomCheckout;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
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
                      color: (isCheckout ? const Color(0xFFF59E0B) : const Color(0xFF2563EB)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCheckout ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
                      color: isCheckout ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCheckout ? 'Strongroom Vault Checkout' : 'Invigilator Handover Receipt',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${p.packetCode} • ${p.subjectCode}',
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
                      // Packet summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Seal Number:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(p.securitySealNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Destination:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('${p.centerName} (${p.roomName})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      if (!isCheckout && invs.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: widget.packet.assignedInvigilatorId,
                          decoration: const InputDecoration(
                            labelText: 'Select Assigned Invigilator',
                            prefixIcon: Icon(Icons.person_search_rounded, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: invs.map((inv) {
                            return DropdownMenuItem(
                              value: inv.id,
                              child: Text('${inv.name} (${inv.resourceId})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final matched = invs.firstWhere((i) => i.id == val);
                            setState(() {
                              _selectedInvigilatorId = val;
                              _nameCtrl.text = matched.name;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: isCheckout ? 'Custodian Name' : 'Receiver / Invigilator Name',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Handover Remarks / Lockbox Number',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
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
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(isCheckout ? 'Confirm Vault Release' : 'Confirm Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCheckout ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submit,
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

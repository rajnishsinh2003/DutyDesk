import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/answer_sheet_bundle_model.dart';
import '../providers/answer_sheet_provider.dart';

enum BundleHandoverType {
  superintendentReceive,
  evaluationDispatch,
}

class BundleHandoverDialog extends ConsumerStatefulWidget {
  final AnswerSheetBundle bundle;
  final BundleHandoverType handoverType;

  const BundleHandoverDialog({
    super.key,
    required this.bundle,
    required this.handoverType,
  });

  static Future<void> show(
    BuildContext context, {
    required AnswerSheetBundle bundle,
    required BundleHandoverType handoverType,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BundleHandoverDialog(
        bundle: bundle,
        handoverType: handoverType,
      ),
    );
  }

  @override
  ConsumerState<BundleHandoverDialog> createState() => _BundleHandoverDialogState();
}

class _BundleHandoverDialogState extends ConsumerState<BundleHandoverDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _primaryCtrl;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _primaryCtrl = TextEditingController(
      text: widget.handoverType == BundleHandoverType.superintendentReceive
          ? (widget.bundle.superintendentName ?? 'Dr. Ramesh Sharma')
          : 'TRK-SPEEDPOST-992410',
    );
  }

  @override
  void dispose() {
    _primaryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final notifier = ref.read(answerSheetProvider.notifier);

    if (widget.handoverType == BundleHandoverType.superintendentReceive) {
      await notifier.handoverToSuperintendent(
        bundleId: widget.bundle.id,
        superintendentName: _primaryCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      await notifier.dispatchToEvaluationCamp(
        bundleId: widget.bundle.id,
        courierTrackingNo: _primaryCtrl.text.trim(),
        authorizedBy: widget.bundle.superintendentName ?? 'Center Superintendent',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Bundle custody updated for ${widget.bundle.bundleCode}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final b = widget.bundle;
    final isReceive = widget.handoverType == BundleHandoverType.superintendentReceive;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          children: [
            // Top Bar
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
                      color: (isReceive ? const Color(0xFF2563EB) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isReceive ? Icons.assignment_turned_in_rounded : Icons.local_shipping_rounded,
                      color: isReceive ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReceive ? 'Control Room Bundle Receipt' : 'Evaluation Camp Dispatch',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${b.bundleCode} • ${b.collectedScriptCount} Scripts',
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
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Seal Number:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(b.securitySealNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Room Invigilator:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('${b.invigilatorName} (${b.roomName})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Enclosed Scripts:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('${b.collectedScriptCount} copies', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _primaryCtrl,
                        decoration: InputDecoration(
                          labelText: isReceive ? 'Receiving Superintendent Name' : 'Courier / Consignment Tracking No',
                          prefixIcon: Icon(isReceive ? Icons.person_pin_rounded : Icons.local_shipping_outlined, size: 20),
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
                          labelText: 'Custody Handover Remarks',
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
                    label: Text(isReceive ? 'Acknowledge Receipt' : 'Confirm Dispatch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReceive ? const Color(0xFF2563EB) : const Color(0xFF10B981),
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

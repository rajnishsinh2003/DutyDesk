import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/answer_sheet_bundle_model.dart';
import '../providers/answer_sheet_provider.dart';

class BundleReconciliationDialog extends ConsumerStatefulWidget {
  final AnswerSheetBundle bundle;

  const BundleReconciliationDialog({super.key, required this.bundle});

  static Future<void> show(BuildContext context, AnswerSheetBundle bundle) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BundleReconciliationDialog(bundle: bundle),
    );
  }

  @override
  ConsumerState<BundleReconciliationDialog> createState() => _BundleReconciliationDialogState();
}

class _BundleReconciliationDialogState extends ConsumerState<BundleReconciliationDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _sealNumberCtrl;
  late TextEditingController _presentCtrl;
  late TextEditingController _absentCtrl;
  late TextEditingController _collectedCtrl;
  late TextEditingController _blankCtrl;
  late TextEditingController _absentRollsCtrl;
  late TextEditingController _invigilatorNameCtrl;

  @override
  void initState() {
    super.initState();
    final b = widget.bundle;
    _sealNumberCtrl = TextEditingController(text: b.securitySealNumber.startsWith('PENDING') ? 'SEAL-WAX-884105' : b.securitySealNumber);
    _presentCtrl = TextEditingController(text: b.presentCount > 0 ? '${b.presentCount}' : '${b.registeredCandidates - 2}');
    _absentCtrl = TextEditingController(text: b.absentCount > 0 ? '${b.absentCount}' : '2');
    _collectedCtrl = TextEditingController(text: b.collectedScriptCount > 0 ? '${b.collectedScriptCount}' : '${b.registeredCandidates - 2}');
    _blankCtrl = TextEditingController(text: '${b.unusedBlankSheetsReturned > 0 ? b.unusedBlankSheetsReturned : 2}');
    _absentRollsCtrl = TextEditingController(text: b.absentRollNumbers.isNotEmpty ? b.absentRollNumbers.join(', ') : '23CS105, 23CS119');
    _invigilatorNameCtrl = TextEditingController(text: b.invigilatorName);
  }

  @override
  void dispose() {
    _sealNumberCtrl.dispose();
    _presentCtrl.dispose();
    _absentCtrl.dispose();
    _collectedCtrl.dispose();
    _blankCtrl.dispose();
    _absentRollsCtrl.dispose();
    _invigilatorNameCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.heavyImpact();

    final present = int.tryParse(_presentCtrl.text.trim()) ?? 0;
    final absent = int.tryParse(_absentCtrl.text.trim()) ?? 0;
    final collected = int.tryParse(_collectedCtrl.text.trim()) ?? 0;
    final blank = int.tryParse(_blankCtrl.text.trim()) ?? 0;

    final rawRolls = _absentRollsCtrl.text.split(',');
    final rolls = rawRolls.map((r) => r.trim()).where((r) => r.isNotEmpty).toList();

    await ref.read(answerSheetProvider.notifier).reconcileAndSeal(
      bundleId: widget.bundle.id,
      securitySealNumber: _sealNumberCtrl.text.trim(),
      presentCount: present,
      absentCount: absent,
      collectedScriptCount: collected,
      blankSheetsReturned: blank,
      absentRollNumbers: rolls,
      invigilatorName: _invigilatorNameCtrl.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📦 Bundle ${widget.bundle.bundleCode} reconciled and sealed!'),
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

    final present = int.tryParse(_presentCtrl.text.trim()) ?? 0;
    final absent = int.tryParse(_absentCtrl.text.trim()) ?? 0;
    final collected = int.tryParse(_collectedCtrl.text.trim()) ?? 0;

    final isBalanced = (present + absent == b.registeredCandidates) && (present == collected);
    final difference = collected - (b.registeredCandidates - absent);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Answer Script Reconciliation & Sealing',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${b.bundleCode} • ${b.roomName}',
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
                      // Reconciliation Math Status Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isBalanced
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isBalanced ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                              color: isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBalanced ? '✅ 100% RECONCILED (ZERO GAP)' : '⚠️ DISCREPANCY DETECTED ($difference scripts)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Allotted: ${b.registeredCandidates} | Present: $present | Absent: $absent | Collected: $collected',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Bundle Header Details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${b.subjectCode} - ${b.subjectName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Allotted: ${b.registeredCandidates} Candidates', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Numbers Inputs
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _presentCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Present Count',
                                prefixIcon: Icon(Icons.people_alt_outlined, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _absentCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Absent Count',
                                prefixIcon: Icon(Icons.person_off_outlined, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _collectedCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Scripts Collected',
                                prefixIcon: Icon(Icons.description_outlined, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _blankCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Blank Returned',
                                prefixIcon: Icon(Icons.assignment_return_outlined, size: 18),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Absentee Roll Numbers
                      TextFormField(
                        controller: _absentRollsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Absentee Roll Numbers (Comma-Separated)',
                          hintText: 'e.g., 23CS105, 23CS119',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tamper Wax / Cloth Seal Barcode
                      TextFormField(
                        controller: _sealNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cloth Bag / Plastic Tamper Seal #',
                          prefixIcon: Icon(Icons.qr_code_rounded, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Seal number is mandatory' : null,
                      ),
                      const SizedBox(height: 14),

                      // Invigilator Signature
                      TextFormField(
                        controller: _invigilatorNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Certifying Invigilator Name',
                          prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                    icon: const Icon(Icons.lock_rounded, size: 18),
                    label: Text(isBalanced ? 'Confirm & Seal Bundle' : 'Log with Mismatch Flag'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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

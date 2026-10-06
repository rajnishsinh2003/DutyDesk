import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/seating_plan_model.dart';
import '../services/seating_generator_engine.dart';
import '../providers/seating_plan_provider.dart';

class SeatingPlanEditorDialog extends ConsumerStatefulWidget {
  final SeatingPlan? existingPlan;

  const SeatingPlanEditorDialog({super.key, this.existingPlan});

  static Future<void> show(BuildContext context, {SeatingPlan? existingPlan}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SeatingPlanEditorDialog(existingPlan: existingPlan),
    );
  }

  @override
  ConsumerState<SeatingPlanEditorDialog> createState() => _SeatingPlanEditorDialogState();
}

class _SeatingPlanEditorDialogState extends ConsumerState<SeatingPlanEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _examNameCtrl;
  late TextEditingController _roomNameCtrl;
  late TextEditingController _centerNameCtrl;
  late TextEditingController _dateCtrl;
  String _selectedShift = 'Shift 1 (09:00 AM - 12:00 PM)';
  AntiCheatingStrategy _selectedStrategy = AntiCheatingStrategy.alternatingBranches;

  int _rows = 5;
  int _cols = 6;
  int _bufferSeats = 2;
  int _cseCount = 14;
  int _eceCount = 12;
  int _meCount = 6;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlan;
    _examNameCtrl = TextEditingController(text: p?.examName ?? 'End-Term Examinations 2026');
    _roomNameCtrl = TextEditingController(text: p?.roomName ?? 'Hall 101');
    _centerNameCtrl = TextEditingController(text: p?.centerName ?? 'Main Academic Block');
    _dateCtrl = TextEditingController(text: p?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    if (p != null) {
      _selectedShift = p.sessionOrShift;
      _selectedStrategy = p.strategy;
      _rows = p.rows;
      _cols = p.columns;
      _bufferSeats = p.bufferCount;
    }
  }

  @override
  void dispose() {
    _examNameCtrl.dispose();
    _roomNameCtrl.dispose();
    _centerNameCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _generateAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final candidates = SeatingGeneratorEngine.generateSampleCandidates(
      cseCount: _cseCount,
      eceCount: _eceCount,
      meCount: _meCount,
    );

    final newPlan = SeatingGeneratorEngine.generatePlan(
      examName: _examNameCtrl.text.trim(),
      sessionOrShift: _selectedShift,
      date: _dateCtrl.text.trim(),
      centerName: _centerNameCtrl.text.trim(),
      roomName: _roomNameCtrl.text.trim(),
      rows: _rows,
      columns: _cols,
      strategy: _selectedStrategy,
      candidates: candidates,
      bufferSeatCount: _bufferSeats,
    );

    await ref.read(seatingPlanProvider.notifier).savePlan(newPlan);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Seating plan generated for ${_roomNameCtrl.text}!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCapacity = _rows * _cols;
    final totalStudents = _cseCount + _eceCount + _meCount;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
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
                      Icons.grid_on_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingPlan == null ? 'Generate Seating Plan' : 'Edit Seating Plan',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Configure hall dimensions & anti-cheating distribution',
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

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exam & Room Info
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _examNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Exam Title',
                                prefixIcon: Icon(Icons.school_outlined, size: 20),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _roomNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Room / Hall',
                                prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _centerNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Exam Center',
                                prefixIcon: Icon(Icons.apartment_outlined, size: 20),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _dateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Date (YYYY-MM-DD)',
                                prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Shift dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedShift,
                        decoration: const InputDecoration(
                          labelText: 'Session / Shift',
                          prefixIcon: Icon(Icons.schedule_outlined, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Shift 1 (09:00 AM - 12:00 PM)',
                            child: Text('Shift 1 (09:00 AM - 12:00 PM)'),
                          ),
                          DropdownMenuItem(
                            value: 'Shift 2 (02:00 PM - 05:00 PM)',
                            child: Text('Shift 2 (02:00 PM - 05:00 PM)'),
                          ),
                          DropdownMenuItem(
                            value: 'Shift 3 (06:00 PM - 08:30 PM)',
                            child: Text('Shift 3 (06:00 PM - 08:30 PM)'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedShift = v!),
                      ),
                      const SizedBox(height: 20),

                      // Hall Grid Dimensions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Room Grid Dimensions',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Capacity: $totalCapacity Desks',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Rows: $_rows', style: const TextStyle(fontSize: 12)),
                                      Slider(
                                        value: _rows.toDouble(),
                                        min: 3,
                                        max: 10,
                                        divisions: 7,
                                        activeColor: const Color(0xFF2563EB),
                                        onChanged: (v) => setState(() => _rows = v.round()),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Columns: $_cols', style: const TextStyle(fontSize: 12)),
                                      Slider(
                                        value: _cols.toDouble(),
                                        min: 3,
                                        max: 10,
                                        divisions: 7,
                                        activeColor: const Color(0xFF2563EB),
                                        onChanged: (v) => setState(() => _cols = v.round()),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Anti-Cheating Strategy Selector
                      const Text(
                        'Anti-Cheating Strategy',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      ...AntiCheatingStrategy.values.map((strat) {
                        final selected = _selectedStrategy == strat;
                        final label = switch (strat) {
                          AntiCheatingStrategy.alternatingBranches =>
                            'Alternating Branches (Interleaves CSE, ECE, ME across desks)',
                          AntiCheatingStrategy.checkerboard =>
                            'Checkerboard Spacing (50% density — leaves alternate desks empty)',
                          AntiCheatingStrategy.consecutiveRolls =>
                            'Consecutive Rolls (Sequential standard placement)',
                        };

                        return InkWell(
                          onTap: () => setState(() => _selectedStrategy = strat),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? const Color(0xFF2563EB) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: selected ? const Color(0xFF2563EB) : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Buffer Seats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Buffer / Emergency Desks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                'Reserved for latecomers or disabled students',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: _bufferSeats > 0 ? () => setState(() => _bufferSeats--) : null,
                              ),
                              Text('$_bufferSeats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: _bufferSeats < 8 ? () => setState(() => _bufferSeats++) : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Candidate Pool Distribution
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Candidate Student Pool', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('Total: $totalStudents Candidates', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _BranchCounter(label: 'CSE', count: _cseCount, onChanged: (v) => setState(() => _cseCount = v)),
                                const SizedBox(width: 8),
                                _BranchCounter(label: 'ECE', count: _eceCount, onChanged: (v) => setState(() => _eceCount = v)),
                                const SizedBox(width: 8),
                                _BranchCounter(label: 'ME', count: _meCount, onChanged: (v) => setState(() => _meCount = v)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Buttons
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
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Generate Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _generateAndSave,
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

class _BranchCounter extends StatelessWidget {
  final String label;
  final int count;
  final ValueChanged<int> onChanged;

  const _BranchCounter({
    required this.label,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            Row(
              children: [
                InkWell(
                  onTap: count > 0 ? () => onChanged(count - 2) : null,
                  child: const Icon(Icons.remove, size: 14),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                InkWell(
                  onTap: () => onChanged(count + 2),
                  child: const Icon(Icons.add, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

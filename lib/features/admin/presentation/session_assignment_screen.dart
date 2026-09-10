import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/exam_session_provider.dart';
import '../providers/invigilator_provider.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../providers/duty_settings_provider.dart';

class SessionAssignmentScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionAssignmentScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionAssignmentScreen> createState() => _SessionAssignmentScreenState();
}

class _SessionAssignmentScreenState extends ConsumerState<SessionAssignmentScreen> {
  final List<String> _selectedInvigilatorIds = [];
  final List<String> _selectedDates = [DateFormat('yyyy-MM-dd').format(DateTime.now())];
  String _selectedShift = '1';
  String _selectedLunch = 'No';
  String _selectedRole = 'inv';
  String _reportingTime = '05:00 AM';
  String _excellentUntil = '06:20 AM';
  String _goodUntil = '06:30 AM';
  String? _timingValidationError;

  bool _isAllocating = false;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid phone number for this staff'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _runAutoAssignAlgorithm(
    List<Invigilator> invs,
    List<ExamDuty> globalDuties,
    List<String> dates,
    String shift,
    int targetCount,
  ) {
    final activeInvs = invs.where((i) => i.isActive).toList();

    final scoredInvs = activeInvs.map((inv) {
      int score = inv.mockDutyCount;

      final activeDutiesCount = globalDuties.where((d) => 
        d.invigilatorId == inv.id && 
        d.status.toLowerCase() != 'rejected'
      ).length;
      score += activeDutiesCount;

      bool hasConflict = false;
      for (final dt in dates) {
        if (inv.unavailableDates.contains(dt)) {
          score += 100;
          hasConflict = true;
        }
        if (globalDuties.any((d) =>
            d.invigilatorId == inv.id &&
            d.date == dt &&
            d.shift == shift &&
            d.status.toLowerCase() != 'rejected')) {
          score += 100;
          hasConflict = true;
        }
      }

      return {
        'id': inv.id,
        'score': score,
        'hasConflict': hasConflict,
      };
    }).toList();

    scoredInvs.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));

    final bestIds = scoredInvs
        .where((item) => !(item['hasConflict'] as bool))
        .take(targetCount)
        .map((item) => item['id'] as String)
        .toList();

    if (bestIds.length < targetCount) {
      final remainingNeeded = targetCount - bestIds.length;
      final extraIds = scoredInvs
          .where((item) => !bestIds.contains(item['id'] as String))
          .take(remainingNeeded)
          .map((item) => item['id'] as String)
          .toList();
      bestIds.addAll(extraIds);
    }

    setState(() {
      _selectedInvigilatorIds.clear();
      _selectedInvigilatorIds.addAll(bestIds);
    });
  }

  void _showAssignStaffModal(ExamSession session, List<Invigilator> invigilators, List<ExamDuty> globalDuties) {
    final s = S.of(context)!;
    _selectedInvigilatorIds.clear();
    _selectedShift = '1';
    _selectedDates.clear();
    _selectedDates.add(DateFormat('yyyy-MM-dd').format(DateTime.now()));

    final initialSettings = ref.read(dutySettingsProvider);
    _selectedLunch = initialSettings.allowLunch ? 'Yes' : 'No';
    _selectedRole = 'inv';
    _reportingTime = '05:00 AM';
    _excellentUntil = '06:20 AM';
    _goodUntil = '06:30 AM';
    _timingValidationError = null;

    String staffSearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final activeInvs = invigilators.where((i) => i.isActive).toList();
          final dutySettings = ref.watch(dutySettingsProvider);

          // Filter staff by dynamic search query (Name, Mobile, Resource ID)
          final filteredStaff = activeInvs.where((inv) {
            if (staffSearchQuery.isEmpty) return true;
            final q = staffSearchQuery.toLowerCase();
            return inv.name.toLowerCase().contains(q) ||
                inv.mobile.toLowerCase().contains(q) ||
                inv.resourceId.toLowerCase().contains(q);
          }).toList();

          final currentRateFormatted = dutySettings.getAmountFormattedForShift(_selectedShift);
          final currentRateAmount = dutySettings.getAmountForShift(_selectedShift);
          final totalRemuneration = _selectedInvigilatorIds.length * _selectedDates.length * currentRateAmount;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title + Auto-recommend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.selectInvigilators,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF007A87)),
                        label: Text(s.recommendedStaff, style: const TextStyle(color: Color(0xFF007A87), fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _runAutoAssignAlgorithm(invigilators, globalDuties, _selectedDates, _selectedShift, 2);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // MULTI-DATE SELECTION SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${s.date} (${_selectedDates.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: Text(s.chooseDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            final dtStr = DateFormat('yyyy-MM-dd').format(picked);
                            if (!_selectedDates.contains(dtStr)) {
                              setModalState(() {
                                _selectedDates.add(dtStr);
                                _selectedDates.sort();
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedDates.map((dt) {
                      DateTime parsed = DateTime.tryParse(dt) ?? DateTime.now();
                      final formatted = DateFormat('dd MMM yyyy').format(parsed);
                      return Chip(
                        label: Text(formatted, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        deleteIcon: _selectedDates.length > 1 ? const Icon(Icons.close, size: 14) : null,
                        onDeleted: _selectedDates.length > 1
                            ? () {
                                setModalState(() {
                                  _selectedDates.remove(dt);
                                });
                              }
                            : null,
                        backgroundColor: const Color(0xFF007A87).withValues(alpha: 0.1),
                        side: const BorderSide(color: Color(0xFF007A87), width: 0.8),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // STEP 1 — SELECT SHIFT (Prominent Shift Cards with Dynamic Rates)
                  Text(
                    '1. ${s.selectShift.toUpperCase()}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007A87), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildShiftCard(
                          shift: '1',
                          title: s.shift1,
                          rate: dutySettings.getAmountFormattedForShift('1'),
                          isSelected: _selectedShift == '1',
                          onTap: () => setModalState(() => _selectedShift = '1'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildShiftCard(
                          shift: '2',
                          title: s.shift2,
                          rate: dutySettings.getAmountFormattedForShift('2'),
                          isSelected: _selectedShift == '2',
                          onTap: () => setModalState(() => _selectedShift = '2'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildShiftCard(
                          shift: '3',
                          title: s.shift3,
                          rate: dutySettings.getAmountFormattedForShift('3'),
                          isSelected: _selectedShift == '3',
                          onTap: () => setModalState(() => _selectedShift = '3'),
                        ),
                      ),
                    ],
                  ),

                  // Optional Lunch Setting (If enabled in Admin Settings)
                  if (dutySettings.allowLunch) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.lunchProvision, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(value: 'Yes', label: Text(s.yes, style: const TextStyle(fontSize: 11))),
                            ButtonSegment(value: 'No', label: Text(s.no, style: const TextStyle(fontSize: 11))),
                          ],
                          selected: {_selectedLunch},
                          onSelectionChanged: (val) => setModalState(() => _selectedLunch = val.first),
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Optional Role Selection (If enabled in Admin Settings)
                  if (dutySettings.allowRole) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'inv', label: Text('Invigilator', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: 'ls', label: Text('Lab Staff', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: 'mtoe', label: Text('MTOE', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (val) => setModalState(() => _selectedRole = val.first),
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ARRIVAL TIMING CONFIGURATION SECTION
                  Text(
                    'ARRIVAL TIMING',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007A87), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure arrival evaluation thresholds for this duty',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimingPickerField(
                          label: 'Reporting',
                          value: _reportingTime,
                          icon: Icons.login_rounded,
                          color: const Color(0xFF007A87),
                          onTap: () async {
                            final picked = await _pickTime(context, _reportingTime);
                            if (picked != null) {
                              setModalState(() {
                                _reportingTime = picked;
                                _validateTimingOrder();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildTimingPickerField(
                          label: 'Excellent Until',
                          value: _excellentUntil,
                          icon: Icons.star_rounded,
                          color: Colors.green,
                          onTap: () async {
                            final picked = await _pickTime(context, _excellentUntil);
                            if (picked != null) {
                              setModalState(() {
                                _excellentUntil = picked;
                                _validateTimingOrder();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildTimingPickerField(
                          label: 'Good Until',
                          value: _goodUntil,
                          icon: Icons.thumb_up_alt_rounded,
                          color: Colors.orange,
                          onTap: () async {
                            final picked = await _pickTime(context, _goodUntil);
                            if (picked != null) {
                              setModalState(() {
                                _goodUntil = picked;
                                _validateTimingOrder();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_timingValidationError != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _timingValidationError!,
                              style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // STEP 2 — SELECT INVIGILATORS (Multi-Selection with Real-Time Search)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2. ${s.selectInvigilators.toUpperCase()}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007A87), letterSpacing: 0.5),
                      ),
                      Text(
                        s.selectedCount(_selectedInvigilatorIds.length),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // SEARCH STAFF INPUT (Dynamic Search by Name, Mobile, Resource ID)
                  TextField(
                    decoration: InputDecoration(
                      hintText: '${s.searchStaff}...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF007A87), size: 20),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        staffSearchQuery = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // STAFF LIST (Checkboxes without individual shift selectors)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: filteredStaff.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                s.noResultsFound,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredStaff.length,
                            itemBuilder: (context, idx) {
                              final inv = filteredStaff[idx];
                              final isSelected = _selectedInvigilatorIds.contains(inv.id);

                              // Count total active duties
                              final staffActiveDutyCount = globalDuties.where((d) =>
                                  d.invigilatorId == inv.id &&
                                  d.status.toLowerCase() != 'rejected').length;

                              // Check conflict across any selected dates for the SELECTED SHIFT
                              final conflictedDates = <String>[];
                              for (final dt in _selectedDates) {
                                final isUnavailable = inv.unavailableDates.contains(dt);
                                final isBusyOnShift = globalDuties.any((d) =>
                                    d.invigilatorId == inv.id &&
                                    d.date == dt &&
                                    d.shift == _selectedShift &&
                                    d.status.toLowerCase() != 'rejected');
                                if (isUnavailable || isBusyOnShift) {
                                  conflictedDates.add(dt);
                                }
                              }

                              String warningText = '';
                              if (conflictedDates.isNotEmpty) {
                                warningText = ' • ⚠️ ${conflictedDates.length} (${s.shift} $_selectedShift)';
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                                elevation: isSelected ? 1 : 0,
                                color: isSelected ? const Color(0xFF007A87).withValues(alpha: 0.06) : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF007A87).withValues(alpha: 0.4) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  dense: true,
                                  activeColor: const Color(0xFF007A87),
                                  title: Text(
                                    inv.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${s.resourceId}: ${inv.resourceId} • ${inv.mobile} • ${s.totalDuties}: ${inv.mockDutyCount + staffActiveDutyCount}$warningText',
                                    style: TextStyle(
                                      color: conflictedDates.isNotEmpty ? Colors.red.shade700 : Colors.grey.shade700,
                                      fontSize: 11,
                                      fontWeight: conflictedDates.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        _selectedInvigilatorIds.add(inv.id);
                                      } else {
                                        _selectedInvigilatorIds.remove(inv.id);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  // ALLOCATION SUMMARY BANNER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A87).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.shift} $_selectedShift ($currentRateFormatted) • ${_selectedInvigilatorIds.length} ${s.staff}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${_selectedDates.length} ${s.date}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        Text(
                          'Total: ₹$totalRemuneration',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // PROCEED BUTTON (Triggers Conflict Check & Confirmation Dialog)
                  ElevatedButton(
                    onPressed: _isAllocating || _selectedInvigilatorIds.isEmpty || _timingValidationError != null
                        ? null
                        : () async {
                            // 1. Pre-allocation conflict validator
                            final conflictList = <Map<String, String>>[];
                            for (final invId in _selectedInvigilatorIds) {
                              final inv = invigilators.firstWhere((i) => i.id == invId);

                              for (final dt in _selectedDates) {
                                if (inv.unavailableDates.contains(dt)) {
                                  conflictList.add({
                                    'staff': inv.name,
                                    'date': dt,
                                    'reason': s.unavailable,
                                  });
                                }
                                final existing = globalDuties.where((d) =>
                                    d.invigilatorId == invId &&
                                    d.date == dt &&
                                    d.shift == _selectedShift &&
                                    d.status.toLowerCase() != 'rejected').toList();
                                if (existing.isNotEmpty) {
                                  conflictList.add({
                                    'staff': inv.name,
                                    'date': dt,
                                    'reason': '${s.assignedDuty} (${existing.first.examName})',
                                  });
                                }
                              }
                            }

                            // If conflicts exist, show override dialog
                            if (conflictList.isNotEmpty) {
                              final proceed = await _showConflictWarningDialog(context, conflictList);
                              if (proceed != true || !context.mounted) return;
                            }

                            // 2. Final Confirmation Dialog
                            final selectedStaffList = invigilators
                                .where((i) => _selectedInvigilatorIds.contains(i.id))
                                .toList();

                            final confirmed = await _showConfirmationDialog(
                              context: context,
                              session: session,
                              dates: _selectedDates,
                              shift: _selectedShift,
                              rateFormatted: currentRateFormatted,
                              totalAmount: totalRemuneration,
                              selectedStaff: selectedStaffList,
                            );

                            if (confirmed != true) return;

                            // 3. Execute Duty Allocation
                            setModalState(() => _isAllocating = true);
                            try {
                              await ref.read(dutyProvider.notifier).bulkAllocateMultiDateDuties(
                                    dates: _selectedDates,
                                    invigilatorIds: _selectedInvigilatorIds,
                                    examName: session.examName,
                                    centerName: session.centerName,
                                    role: dutySettings.allowRole ? _selectedRole : 'inv',
                                    shift: _selectedShift,
                                    payment: currentRateFormatted,
                                    lunch: _selectedLunch,
                                    sessionId: session.id,
                                    reportingTime: _reportingTime,
                                    excellentUntil: _excellentUntil,
                                    goodUntil: _goodUntil,
                                  );

                              setModalState(() => _isAllocating = false);
                              if (context.mounted) {
                                _selectedInvigilatorIds.clear();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(s.dutyAllocatedSuccess),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => _isAllocating = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${s.error}: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF007A87),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isAllocating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            '${s.assign} (${_selectedInvigilatorIds.length} ${s.staff})',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShiftCard({
    required String shift,
    required String title,
    required String rate,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007A87).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF007A87) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 16,
                  color: isSelected ? const Color(0xFF007A87) : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF007A87) : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              rate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF007A87) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingPickerField({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final parsed = DateFormat('hh:mm a').parse(timeStr.trim());
      return parsed.hour * 60 + parsed.minute;
    } catch (_) {
      return 0;
    }
  }

  void _validateTimingOrder() {
    final repMin = _parseTimeToMinutes(_reportingTime);
    final excMin = _parseTimeToMinutes(_excellentUntil);
    final goodMin = _parseTimeToMinutes(_goodUntil);

    if (repMin >= excMin || excMin >= goodMin) {
      _timingValidationError = 'Invalid order: Reporting Time < Excellent Until < Good Until';
    } else {
      _timingValidationError = null;
    }
  }

  Future<String?> _pickTime(BuildContext context, String currentValue) async {
    TimeOfDay initial;
    try {
      final parsed = DateFormat('hh:mm a').parse(currentValue.trim());
      initial = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      initial = const TimeOfDay(hour: 5, minute: 0);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF007A87),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return null;

    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required ExamSession session,
    required List<String> dates,
    required String shift,
    required String rateFormatted,
    required int totalAmount,
    required List<Invigilator> selectedStaff,
  }) {
    final s = S.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.assignment_turned_in, color: Color(0xFF007A87), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.confirmAssignment,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exam & Center Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A87).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.book, size: 16, color: Color(0xFF007A87)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              session.examName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${s.center}: ${session.centerName}',
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Shift & Dates Info
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.selectShift, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('${s.shift} $shift', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF007A87))),
                            Text('$rateFormatted / ${s.staff}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('${dates.length} ${s.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              dates.map((d) => DateFormat('dd MMM').format(DateTime.tryParse(d) ?? DateTime.now())).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selected Invigilators List
                Text(
                  '${s.selectedInvigilators} (${selectedStaff.length}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: selectedStaff.length,
                      separatorBuilder: (ctx, idx) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, i) {
                        final staff = selectedStaff[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFF007A87).withValues(alpha: 0.1),
                                child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF007A87))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('${s.resourceId}: ${staff.resourceId} • ${staff.mobile}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Text('${s.shift} $shift', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF007A87))),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Total Remuneration Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.totalRemuneration, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
                          Text('${selectedStaff.length} ${s.staff} × ${dates.length} ${s.date} × $rateFormatted',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                        ],
                      ),
                      Text(
                        'Total: ₹$totalAmount',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Arrival Timing Info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Arrival Timing', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('Reporting: $_reportingTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Excellent Until: $_excellentUntil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                      Text('Good Until: $_goodUntil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A87),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.confirmAssignment, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConflictWarningDialog(BuildContext context, List<Map<String, String>> conflicts) {
    final s = S.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(s.conflictDetected, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${conflicts.length} conflict(s):',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: conflicts.length,
                  itemBuilder: (context, i) {
                    final c = conflicts[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s.staff}: ${c['staff']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${s.date}: ${c['date']} • ${c['reason']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text('${s.overrideAction}?', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.overrideAction),
          ),
        ],
      ),
    );
  }

  void _showReassignModal(ExamDuty duty, List<Invigilator> activeInvs) {
    final s = S.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.swapDuty,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${duty.examName} • ${duty.date}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activeInvs.length,
                itemBuilder: (context, index) {
                  final inv = activeInvs[index];
                  if (inv.id == duty.invigilatorId) return const SizedBox.shrink();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF007A87).withValues(alpha: 0.1),
                      child: Text(
                        inv.name.isNotEmpty ? inv.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF007A87), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s.mobile}: ${inv.mobile} • ${s.resourceId}: ${inv.resourceId}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ref.read(dutyProvider.notifier).reassignDuty(duty.id, inv.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${s.dutySwapped} -> ${inv.name}!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A87), foregroundColor: Colors.white),
                      child: Text(s.assign),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final sessions = ref.watch(examSessionProvider);
    final invigilators = ref.watch(invigilatorProvider);
    final activeInvs = invigilators.where((i) => i.isActive).toList();
    final globalDuties = ref.watch(globalDutyProvider);
    final dutySettings = ref.watch(dutySettingsProvider);

    final session = sessions.firstWhere(
      (sessionItem) => sessionItem.id == widget.sessionId,
      orElse: () => ExamSession(id: '', examName: 'Unknown Exam', date: '', centerId: '', centerName: ''),
    );

    final sessionDuties = globalDuties.where((d) => d.sessionId == session.id || (session.id.isNotEmpty && d.examName == session.examName)).toList();
    final acceptedDuties = sessionDuties.where((d) => d.status.toLowerCase() == 'accepted').toList();
    final pendingDuties = sessionDuties.where((d) => d.status.toLowerCase() == 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(session.examName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignStaffModal(session, invigilators, globalDuties),
        icon: const Icon(Icons.group_add),
        backgroundColor: const Color(0xFF007A87),
        foregroundColor: Colors.white,
        label: Text(s.assignDuty),
      ),
      body: session.id.isEmpty
          ? Center(child: Text(s.noDataFound))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HERO HEADER CARD
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A87),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007A87).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.examName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.business, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text('${s.center}: ${session.centerName}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatBubble(s.totalDuties, '${sessionDuties.length}'),
                            const SizedBox(width: 8),
                            _buildStatBubble(s.accepted, '${acceptedDuties.length}'),
                            const SizedBox(width: 8),
                            _buildStatBubble(s.pending, '${pendingDuties.length}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ACTIVE / PENDING ASSIGNMENTS
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${s.assignedDuty} (${sessionDuties.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${acceptedDuties.length} ${s.accepted}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (sessionDuties.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(s.noDutiesAssigned, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                            const SizedBox(height: 8),
                            Text(s.assignDuty, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessionDuties.length,
                      itemBuilder: (context, index) {
                        final duty = sessionDuties[index];
                        return _buildDutyRow(duty, invigilators, activeInvs, s, dutySettings);
                      },
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildStatBubble(String label, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDutyRow(ExamDuty duty, List<Invigilator> invs, List<Invigilator> activeInvs, S s, DutySettings dutySettings, {bool isCompleted = false}) {
    final inv = invs.firstWhere(
      (i) => i.id == duty.invigilatorId,
      orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '', mobile: '', mockDutyCount: 0),
    );

    final statusLabel = duty.status.toLowerCase() == 'accepted'
        ? s.accepted
        : (duty.status.toLowerCase() == 'rejected' ? s.rejected : s.pending);

    final statusBgColor = isCompleted
        ? Colors.grey.shade200
        : (duty.status == 'accepted'
            ? Colors.green.withValues(alpha: 0.12)
            : (duty.status == 'rejected' ? Colors.red.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12)));

    final statusTextColor = isCompleted
        ? Colors.grey
        : (duty.status == 'accepted'
            ? Colors.green.shade700
            : (duty.status == 'rejected' ? Colors.red.shade700 : Colors.orange.shade800));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      color: isCompleted ? Colors.grey.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP HEADER ROW: Avatar + Staff Name + Action Buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusBgColor,
                  child: Text(
                    inv.name.isNotEmpty
                        ? inv.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCompleted ? s.completed.toUpperCase() : statusLabel.toUpperCase(),
                              style: TextStyle(
                                color: statusTextColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (dutySettings.allowRole) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007A87).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                duty.role.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF007A87),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (duty.status == 'pending' && !isCompleted)
                      IconButton(
                        icon: const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                        tooltip: s.sendReminder,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () {
                          ref.read(dutyProvider.notifier).sendManualReminder(duty.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${s.reminderSent} (${inv.name})'), backgroundColor: Colors.orange),
                          );
                        },
                      ),
                    if (dutySettings.allowDutySwap)
                      IconButton(
                        icon: const Icon(Icons.swap_horiz, color: Color(0xFF007A87), size: 21),
                        tooltip: s.swapDuty,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        onPressed: () => _showReassignModal(duty, activeInvs),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 21),
                      tooltip: s.delete,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () {
                        ref.read(dutyProvider.notifier).deleteDuty(duty.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.itemDeleted), backgroundColor: Colors.red),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            const SizedBox(height: 10),

            // 2. FULL-WIDTH STRUCTURED DETAILS SECTION
            // Row 1: Date & Shift
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF007A87)),
                      const SizedBox(width: 6),
                      Text(
                        '${s.date}: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        duty.date,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade900),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Color(0xFF007A87)),
                      const SizedBox(width: 6),
                      Text(
                        '${s.shift}: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        duty.shift,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: Arrival Timing Configuration
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF007A87).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: Color(0xFF007A87)),
                  const SizedBox(width: 4),
                  Text(
                    'Report: ${duty.reportingTime}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '★ ${duty.excellentUntil}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '👍 ${duty.goodUntil}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Row 3: Remuneration & Resource ID
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '${s.remuneration}: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        duty.payment,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        '${s.resourceId}: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Expanded(
                        child: Text(
                          inv.resourceId.isNotEmpty ? inv.resourceId : '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Row 3: Mobile (Click to Call)
            if (inv.mobile.isNotEmpty) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _makePhoneCall(inv.mobile),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        '${s.mobile}: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        inv.mobile,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.green),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.call, size: 12, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ],

            // Row 4: Reached Status (if reached)
            if (duty.isReached) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${s.reached} (${duty.reachedTime ?? "-"})',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

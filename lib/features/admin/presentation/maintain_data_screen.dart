import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/daily_record_provider.dart';
import '../services/daily_report_service.dart';
import '../providers/center_provider.dart';
import '../providers/invigilator_provider.dart';
import '../providers/exam_session_provider.dart';
import '../../../core/utils/month_filter_utils.dart';


Future<void> _handleExportOption(
    BuildContext context, 
    List<dynamic> filtered, 
    List<dynamic> all, 
    Future<void> Function(List<dynamic>) exportAction) async {
  
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Export Options'),
      content: Text(
        'Filtered records: ${filtered.length}\nTotal records: ${all.length}\n\nWhich data do you want to export?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'filtered'),
          child: const Text('Filtered Data'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'all'),
          child: const Text('Entire Data'),
        ),
      ],
    ),
  );

  if (result == 'filtered') {
    await exportAction(filtered);
  } else if (result == 'all') {
    await exportAction(all);
  }
}

class MaintainDataScreen extends ConsumerStatefulWidget {
  const MaintainDataScreen({super.key});

  @override
  ConsumerState<MaintainDataScreen> createState() => _MaintainDataScreenState();
}

class _MaintainDataScreenState extends ConsumerState<MaintainDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: screenBgColor,
      appBar: AppBar(
        title: Text('Maintain Data', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: screenBgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Global Search',
            onPressed: () => context.go('/admin_dashboard/global_search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF007A87),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF007A87),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Security Guard'),
            Tab(text: 'Exam Staff'),
            Tab(text: 'Jammer'),
            Tab(text: 'POD'),
            Tab(text: 'Work'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SecurityGuardTab(),
          ExamStaffTab(),
          JammerTab(),
          PodTab(),
          WorkTab(),
        ],
      ),
    );
  }
}

// --- Security Guard Tab ---
class SecurityGuardTab extends ConsumerStatefulWidget {
  const SecurityGuardTab({super.key});
  @override
  ConsumerState<SecurityGuardTab> createState() => _SecurityGuardTabState();
}

class _SecurityGuardTabState extends ConsumerState<SecurityGuardTab> {
  String _searchQuery = '';
  int _selectedMonth = getCurrentMonth();

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddSecurityGuardDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyRecordProvider);
    // First filter by month, then by search query
    final monthFiltered = state.guardRecords.where((r) => matchesMonth(r.date, _selectedMonth)).toList();
    final records = monthFiltered.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.name.toLowerCase().contains(q) || 
             r.date.toLowerCase().contains(q) || 
             r.center.toLowerCase().contains(q) ||
             r.gender.toLowerCase().contains(q) ||
             r.duty.toLowerCase().contains(q) ||
             r.totalShifts.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MonthFilterDropdown(
                  selectedMonth: _selectedMonth,
                  onChanged: (val) => setState(() => _selectedMonth = val),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${records.length} records',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: 'Search (Name, Date, Center, Duty, Gender)', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(
                    context,
                    records,
                    monthFiltered,
                    (dataList) async {
                      await DailyReportService.exportPdf(
                        title: 'Security Guard',
                        headers: ['DATE', 'SECURITY GUARD NAME', 'CENTER', 'GENDER', 'DUTY TYPE', 'TOTAL SHIFTS', 'PAYMENT'],
                        data: dataList.map((r) => <String>[r.date, r.name, r.center, r.gender, r.duty, r.totalShifts, r.payment]).toList(),
                      );
                    }
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade900),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(context, records, monthFiltered, (dataList) async {
                    await DailyReportService.exportExcel(
                      title: 'Security Guard',
                      headers: ['DATE', 'SECURITY GUARD NAME', 'CENTER', 'GENDER', 'DUTY TYPE', 'TOTAL SHIFTS', 'PAYMENT'],
                      data: dataList.map((r) => <String>[r.date, r.name, r.center, r.gender, r.duty, r.totalShifts, r.payment]).toList(),
                    );
                  });},
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
              ),
              const Spacer(),
              ElevatedButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('SECURITY GUARD NAME')),
                  DataColumn(label: Text('CENTER')),
                  DataColumn(label: Text('GENDER')),
                  DataColumn(label: Text('DUTY TYPE')),
                  DataColumn(label: Text('TOTAL SHIFTS')),
                  DataColumn(label: Text('PAYMENT')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: records.map((r) => DataRow(cells: [
                  DataCell(Text(r.date)),
                  DataCell(Text(r.name)),
                  DataCell(Text(r.center)),
                  DataCell(Text(r.gender)),
                  DataCell(Text(r.duty)),
                  DataCell(Text(r.totalShifts)),
                  DataCell(Text(r.payment)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => showDialog(context: context, builder: (_) => AddSecurityGuardDialog(existingRecord: r))),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(dailyRecordProvider.notifier).deleteRecord(r.id)),
                    ],
                  )),
                ])).toList(),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddSecurityGuardDialog extends ConsumerStatefulWidget {
  final SecurityGuardRecord? existingRecord;
  const AddSecurityGuardDialog({super.key, this.existingRecord});
  @override
  ConsumerState<AddSecurityGuardDialog> createState() => _AddSecurityGuardDialogState();
}

class _AddSecurityGuardDialogState extends ConsumerState<AddSecurityGuardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController(text: DateFormat('dd-MMM').format(DateTime.now()));
  String _name = '';
  String _gender = 'Male';
  String _center = '';
  String _duty = 'Exam';
  String _totalShifts = '1 Shift';
  String _payment = '₹500';

  void _updatePayment() {
    _payment = '₹550';
  }

  @override
  void initState() {
  super.initState();

  if (widget.existingRecord != null) {
      _dateCtrl.text = widget.existingRecord!.date;
      _name = widget.existingRecord!.name;
      _gender = widget.existingRecord!.gender;
      _center = widget.existingRecord!.center;
      _duty = widget.existingRecord!.duty;
      _totalShifts = widget.existingRecord!.totalShifts;
      _payment = widget.existingRecord!.payment;
    } else {
    _updatePayment();
  }
}

  @override
  Widget build(BuildContext context) {
    final state = ref.read(dailyRecordProvider);
    final centerList = ref.watch(centerProvider);
    final guardNames = state.guardRecords.map((e) => e.name).toSet().toList();
    final centerNames = centerList.map((c) => c.name).where((name) => name.isNotEmpty).toList();

    return AlertDialog(
      title: const Text('Add Security Guard Record'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date Selection',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                validator: (v) => v == null || v.isEmpty ? 'Date is required' : null,
                onTap: () async {
                  DateTime initial;
                  try {
                    initial = DateFormat('dd-MMM').parse(_dateCtrl.text);
                    initial = DateTime(DateTime.now().year, initial.month, initial.day);
                  } catch (_) {
                    initial = DateTime.now();
                  }
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateCtrl.text = DateFormat('dd-MMM').format(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              SearchableDropdownField(
                label: 'Guard Name',
                value: _name,
                options: guardNames,
                allowAddNew: true,
                validator: (v) => v == null || v.isEmpty ? 'Guard name is required' : null,
                onSelected: (val) {
                  setState(() {
                    _name = val;
                    final prevRecords = state.guardRecords.where((r) => r.name.toLowerCase() == val.toLowerCase());
                    if (prevRecords.isNotEmpty) {
                      final r = prevRecords.last;
                      _center = r.center;
                      _gender = r.gender.isNotEmpty ? r.gender : 'Male';
                      _duty = r.duty.isNotEmpty ? r.duty : 'Exam';
                      _totalShifts = r.totalShifts.isNotEmpty ? r.totalShifts : '1 Shift';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _gender = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              SearchableDropdownField(
                label: 'Center Name',
                value: _center,
                options: centerNames,
                allowAddNew: true,
                validator: (v) => v == null || v.isEmpty ? 'Center is required' : null,
                onSelected: (val) {
                  setState(() {
                    _center = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _duty,
                decoration: const InputDecoration(labelText: 'Duty Type'),
                items: const [
                  DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _duty = val;
                      _updatePayment();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _totalShifts,
                decoration: const InputDecoration(labelText: 'Total Shifts'),
                items: const [
                  DropdownMenuItem(value: '1 Shift', child: Text('1 Shift')),
                  DropdownMenuItem(value: '2 Shifts', child: Text('2 Shifts')),
                  DropdownMenuItem(value: '3 Shifts', child: Text('3 Shifts')),
                  DropdownMenuItem(value: '4 Shifts', child: Text('4 Shifts')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _totalShifts = val;
                      _updatePayment();
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: TextEditingController(text: _payment),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Payment',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              try {
                final isNewCenter = !centerNames.any((n) => n.toLowerCase() == _center.toLowerCase());
                if (isNewCenter && _center.trim().isNotEmpty) {
                  await ref.read(centerProvider.notifier).addCenter(_center.trim(), 'Auto-added', 0);
                }

                if (widget.existingRecord == null) {
                  await ref.read(dailyRecordProvider.notifier).addSecurityGuard(
                    SecurityGuardRecord(
                      id: '',
                      date: _dateCtrl.text,
                      name: _name,
                      center: _center,
                      gender: _gender,
                      duty: _duty,
                      totalShifts: _totalShifts,
                      payment: _payment,
                    ),
                  );
                } else {
                  await ref.read(dailyRecordProvider.notifier).updateSecurityGuard(
                    widget.existingRecord!.id,
                    SecurityGuardRecord(
                      id: widget.existingRecord!.id,
                      date: _dateCtrl.text,
                      name: _name,
                      center: _center,
                      gender: _gender,
                      duty: _duty,
                      totalShifts: _totalShifts,
                      payment: _payment,
                    ),
                  );
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Security Guard record saved successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save record: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- Exam Staff Tab ---
class ExamStaffTab extends ConsumerStatefulWidget {
  const ExamStaffTab({super.key});
  @override
  ConsumerState<ExamStaffTab> createState() => _ExamStaffTabState();
}

class _ExamStaffTabState extends ConsumerState<ExamStaffTab> {
  String _searchQuery = '';
  int _selectedMonth = getCurrentMonth();

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddExamStaffDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyRecordProvider);
    // First filter by month, then by search query
    final monthFiltered = state.examStaffRecords.where((r) => matchesMonth(r.date, _selectedMonth)).toList();
    final records = monthFiltered.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.esName.toLowerCase().contains(q) || 
             r.date.toLowerCase().contains(q) || 
             r.centerName.toLowerCase().contains(q) ||
             r.duty.toLowerCase().contains(q) ||
             r.examName.toLowerCase().contains(q) ||
             r.totalShifts.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MonthFilterDropdown(
                  selectedMonth: _selectedMonth,
                  onChanged: (val) => setState(() => _selectedMonth = val),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${records.length} records',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: 'Search (Name, Date, Center, Duty, Exam)', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(
                    context,
                    records,
                    monthFiltered,
                    (dataList) async {
                      await DailyReportService.exportPdf(
                        title: 'Exam Staff',
                        headers: ['DATE', 'CENTER NAME', 'ES NAME', 'DUTY', 'EXAM NAME', 'TOTAL SHIFTS', 'PAYMENT'],
                        data: dataList.map((r) => <String>[r.date, r.centerName, r.esName, r.duty, r.examName, r.totalShifts, r.payment]).toList(),
                      );
                    }
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade900),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(context, records, monthFiltered, (dataList) async {
                    await DailyReportService.exportExcel(
                      title: 'Exam Staff',
                      headers: ['DATE', 'CENTER NAME', 'ES NAME', 'DUTY', 'EXAM NAME', 'TOTAL SHIFTS', 'PAYMENT'],
                      data: dataList.map((r) => <String>[r.date, r.centerName, r.esName, r.duty, r.examName, r.totalShifts, r.payment]).toList(),
                    );
                  });},
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
              ),
              const Spacer(),
              ElevatedButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('CENTER NAME')),
                  DataColumn(label: Text('ES NAME')),
                  DataColumn(label: Text('DUTY')),
                  DataColumn(label: Text('EXAM NAME')),
                  DataColumn(label: Text('TOTAL SHIFTS')),
                  DataColumn(label: Text('PAYMENT')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: records.map((r) => DataRow(cells: [
                  DataCell(Text(r.date)),
                  DataCell(Text(r.centerName)),
                  DataCell(Text(r.esName)),
                  DataCell(Text(r.duty)),
                  DataCell(Text(r.examName)),
                  DataCell(Text(r.totalShifts)),
                  DataCell(Text(r.payment)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => showDialog(context: context, builder: (_) => AddExamStaffDialog(existingRecord: r))),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(dailyRecordProvider.notifier).deleteRecord(r.id)),
                    ],
                  )),
                ])).toList(),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddExamStaffDialog extends ConsumerStatefulWidget {
  final ExamStaffRecord? existingRecord;
  const AddExamStaffDialog({super.key, this.existingRecord});
  @override
  ConsumerState<AddExamStaffDialog> createState() => _AddExamStaffDialogState();
}

class _AddExamStaffDialogState extends ConsumerState<AddExamStaffDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateCtrl = TextEditingController(text: DateFormat('dd-MMM').format(DateTime.now()));
  String _esName = '';
  String _centerName = '';
  String _duty = 'Exam';
  String _examName = '';
  String _totalShifts = '1 Shift';
  String _payment = '';

  // Helper to calculate payment based on total shifts
    String _calculatePayment(String duty, String shifts) {
      // Mock duty always ₹400 regardless of shifts
      if (duty == 'Mock') return '₹400';

      // Extract numeric shift count
      final shiftMatch = RegExp(r'(\d+)').firstMatch(shifts);
      final shiftCount = shiftMatch != null ? int.parse(shiftMatch.group(1)!) : 1;

      switch (shiftCount) {
        case 1:
          return '₹400';
        case 2:
          return '₹600';
        case 3:
          return '₹800';
        case 4:
          return '₹800';
        default:
          return '₹400';
      }
    }

    // Update payment when duty or totalShifts change
    void _updatePayment() {
      setState(() {
        _payment = _calculatePayment(_duty, _totalShifts);
      });
    }

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _dateCtrl.text = widget.existingRecord!.date;
      _esName = widget.existingRecord!.esName;
      _centerName = widget.existingRecord!.centerName;
      _duty = widget.existingRecord!.duty;
      _examName = widget.existingRecord!.examName;
      _totalShifts = widget.existingRecord!.totalShifts;
    }
    // Initial payment calculation based on default duty and shifts
    _payment = _calculatePayment(_duty, _totalShifts);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.read(dailyRecordProvider);
    final invigilatorList = ref.watch(invigilatorProvider);
    final centerList = ref.watch(centerProvider);
    final sessionList = ref.watch(examSessionProvider);

    final staffNames = {
      ...state.examStaffRecords.map((e) => e.esName),
      ...invigilatorList.map((i) => i.name)
    }.where((name) => name.isNotEmpty).toList();

    final centerNames = centerList.map((c) => c.name).where((name) => name.isNotEmpty).toList();

    final examNames = <String>{
      ...state.examStaffRecords.map((e) => e.examName),
      ...state.jammerRecords.map((j) => j.examName),
      ...sessionList.map((s) => s.examName)
    }.where((name) => name.isNotEmpty).toList();

    return AlertDialog(
      title: const Text('Add Exam Staff Record'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date Selection',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                validator: (v) => v == null || v.isEmpty ? 'Date is required' : null,
                onTap: () async {
                  DateTime initial;
                  try {
                    initial = DateFormat('dd-MMM').parse(_dateCtrl.text);
                    initial = DateTime(DateTime.now().year, initial.month, initial.day);
                  } catch (_) {
                    initial = DateTime.now();
                  }
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateCtrl.text = DateFormat('dd-MMM').format(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              SearchableDropdownField(
                label: 'Staff Name',
                value: _esName,
                options: staffNames,
                allowAddNew: true,
                validator: (v) => v == null || v.isEmpty ? 'Staff name is required' : null,
                onSelected: (val) {
                  setState(() {
                    _esName = val;
                    final prevRecords = state.examStaffRecords.where((r) => r.esName.toLowerCase() == val.toLowerCase());
                    if (prevRecords.isNotEmpty) {
                      final r = prevRecords.last;
                      _centerName = r.centerName;
                      _duty = r.duty;
                      _examName = r.examName;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              SearchableDropdownField(
                label: 'Center Name',
                value: _centerName,
                options: centerNames,
                allowAddNew: true,
                validator: (v) => v == null || v.isEmpty ? 'Center is required' : null,
                onSelected: (val) {
                  setState(() {
                    _centerName = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _duty,
                decoration: const InputDecoration(labelText: 'Duty Type'),
                items: const [
                  DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                  DropdownMenuItem(value: 'Mock', child: Text('Mock')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _duty = val;
                    });
                    _updatePayment();
                  }
                },
              ),
              const SizedBox(height: 12),
              SearchableDropdownField(
                label: 'Exam Name',
                value: _examName,
                options: examNames,
                allowAddNew: true,
                validator: (v) => v == null || v.isEmpty ? 'Exam name is required' : null,
                onSelected: (val) {
                  setState(() {
                    _examName = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _totalShifts,
                decoration: const InputDecoration(labelText: 'Total Shifts'),
                items: const [
                  DropdownMenuItem(value: '1 Shift', child: Text('1 Shift')),
                  DropdownMenuItem(value: '2 Shifts', child: Text('2 Shifts')),
                  DropdownMenuItem(value: '3 Shifts', child: Text('3 Shifts')),
                  DropdownMenuItem(value: '4 Shifts', child: Text('4 Shifts')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _totalShifts = val;
                    });
                    _updatePayment();
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              try {
                final isNewCenter = !centerNames.any((n) => n.toLowerCase() == _centerName.toLowerCase());
                if (isNewCenter && _centerName.trim().isNotEmpty) {
                  await ref.read(centerProvider.notifier).addCenter(_centerName.trim(), 'Auto-added', 0);
                }

                if (widget.existingRecord == null) {
                  await ref.read(dailyRecordProvider.notifier).addExamStaff(
                    ExamStaffRecord(
                      id: '',
                      date: _dateCtrl.text,
                      centerName: _centerName,
                      esName: _esName,
                      duty: _duty,
                      examName: _examName,
                      totalShifts: _totalShifts,
                      payment: _payment,
                    ),
                  );
                } else {
                  await ref.read(dailyRecordProvider.notifier).updateExamStaff(
                    widget.existingRecord!.id,
                    ExamStaffRecord(
                      id: widget.existingRecord!.id,
                      date: _dateCtrl.text,
                      centerName: _centerName,
                      esName: _esName,
                      duty: _duty,
                      examName: _examName,
                      totalShifts: _totalShifts,
                      payment: _payment,
                    ),
                  );
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exam Staff record saved successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save record: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- Jammer Tab ---
class JammerTab extends ConsumerStatefulWidget {
  const JammerTab({super.key});
  @override
  ConsumerState<JammerTab> createState() => _JammerTabState();
}

class _JammerTabState extends ConsumerState<JammerTab> {
  String _searchQuery = '';
  int _selectedMonth = getCurrentMonth();

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddJammerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyRecordProvider);
    // First filter by month, then by search query
    final monthFiltered = state.jammerRecords.where((r) => matchesMonth(r.date, _selectedMonth)).toList();
    final records = monthFiltered.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.name.toLowerCase().contains(q) || 
             r.date.toLowerCase().contains(q) || 
             r.center.toLowerCase().contains(q) ||
             r.duty.toLowerCase().contains(q) ||
             r.examName.toLowerCase().contains(q) ||
             r.totalShifts.toLowerCase().contains(q) ||
             r.payment.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MonthFilterDropdown(
                  selectedMonth: _selectedMonth,
                  onChanged: (val) => setState(() => _selectedMonth = val),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${records.length} records',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: 'Search (Name, Date, Center, Duty, Exam)', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(
                    context,
                    records,
                    monthFiltered,
                    (dataList) async {
                      await DailyReportService.exportPdf(
                        title: 'Jammer',
                        headers: ['DATE', 'JAMMER PERSON NAME', 'CENTER', 'DUTY TYPE', 'EXAM NAME', 'TOTAL SHIFTS', 'PAYMENT'],
                        data: dataList.map((r) => <String>[r.date, r.name, r.center, r.duty, r.examName, r.totalShifts, r.payment]).toList(),
                      );
                    }
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade900),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(context, records, monthFiltered, (dataList) async {
                    await DailyReportService.exportExcel(
                      title: 'Jammer',
                      headers: ['DATE', 'JAMMER PERSON NAME', 'CENTER', 'DUTY TYPE', 'EXAM NAME', 'TOTAL SHIFTS', 'PAYMENT'],
                      data: dataList.map((r) => <String>[r.date, r.name, r.center, r.duty, r.examName, r.totalShifts, r.payment]).toList(),
                    );
                  });},
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
              ),
              const Spacer(),
              ElevatedButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('JAMMER PERSON NAME')),
                  DataColumn(label: Text('CENTER')),
                  DataColumn(label: Text('DUTY TYPE')),
                  DataColumn(label: Text('EXAM NAME')),
                  DataColumn(label: Text('TOTAL SHIFTS')),
                  DataColumn(label: Text('PAYMENT')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: records.map((r) => DataRow(cells: [
                  DataCell(Text(r.date)),
                  DataCell(Text(r.name)),
                  DataCell(Text(r.center)),
                  DataCell(Text(r.duty)),
                  DataCell(Text(r.examName)),
                  DataCell(Text(r.totalShifts)),
                  DataCell(Text(r.payment)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => showDialog(context: context, builder: (_) => AddJammerDialog(existingRecord: r))),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(dailyRecordProvider.notifier).deleteRecord(r.id)),
                    ],
                  )),
                ])).toList(),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddJammerDialog extends ConsumerStatefulWidget {
  final JammerRecord? existingRecord;
  const AddJammerDialog({super.key, this.existingRecord});
  @override
  ConsumerState<AddJammerDialog> createState() => _AddJammerDialogState();
}

class _AddJammerDialogState extends ConsumerState<AddJammerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController(text: DateFormat('dd-MMM').format(DateTime.now()));
  String _name = '';
  String _center = '';
  String _duty = 'Exam';
  String _examName = '';
  String _payment = '₹500';

  void _updatePayment() {
    _payment = _duty == 'Mock' ? '₹150' : '₹500';
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _dateCtrl.text = widget.existingRecord!.date;
      _name = widget.existingRecord!.name;
      _center = widget.existingRecord!.center;
      _duty = widget.existingRecord!.duty;
      _examName = widget.existingRecord!.examName;
      _payment = widget.existingRecord!.payment;
    } else {
      _updatePayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.read(dailyRecordProvider);
    final centerList = ref.watch(centerProvider);
    final sessionList = ref.watch(examSessionProvider);

    final jammerNames = state.jammerRecords.map((e) => e.name).toSet().toList();
    final centerNames = centerList.map((c) => c.name).where((name) => name.isNotEmpty).toList();
    final examNames = <String>{
      ...state.examStaffRecords.map((e) => e.examName),
      ...state.jammerRecords.map((j) => j.examName),
      ...sessionList.map((s) => s.examName)
    }.where((name) => name.isNotEmpty).toList();

    return AlertDialog(
      title: const Text('Add Jammer Record'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date Selection',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                validator: (v) => v == null || v.isEmpty ? 'Date is required' : null,
                onTap: () async {
                  DateTime initial;
                  try {
                    initial = DateFormat('dd-MMM').parse(_dateCtrl.text);
                    initial = DateTime(DateTime.now().year, initial.month, initial.day);
                  } catch (_) {
                    initial = DateTime.now();
                  }
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _dateCtrl.text = DateFormat('dd-MMM').format(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              SearchableDropdownField(
                label: 'Jammer Person Name',
                value: _name,
                options: jammerNames,
                allowAddNew: true,
                validator: (v) => v == null || v.isEmpty ? 'Jammer name is required' : null,
                onSelected: (val) {
                  setState(() {
                    _name = val;
                    final prevRecords = state.jammerRecords.where((r) => r.name.toLowerCase() == val.toLowerCase());
                    if (prevRecords.isNotEmpty) {
                      final r = prevRecords.last;
                      _center = r.center;
                      _duty = r.duty;
                      _examName = r.examName;
                      _updatePayment();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              SearchableDropdownField(
                label: 'Center Name',
                value: _center,
                options: centerNames,
                allowAddNew: true,
                validator: (v) => v == null || v.isEmpty ? 'Center name is required' : null,
                onSelected: (val) {
                  setState(() {
                    _center = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _duty,
                decoration: const InputDecoration(labelText: 'Duty Type'),
                items: const [
                  DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                  DropdownMenuItem(value: 'Mock', child: Text('Mock')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _duty = val;
                      _updatePayment();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              SearchableDropdownField(
                label: 'Exam Name',
                value: _examName,
                options: examNames,
                allowAddNew: true,
                validator: (v) => v == null || v.isEmpty ? 'Exam name is required' : null,
                onSelected: (val) {
                  setState(() {
                    _examName = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: TextEditingController(text: _payment),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Payment',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              try {
                final isNewCenter = !centerNames.any((n) => n.toLowerCase() == _center.toLowerCase());
                if (isNewCenter && _center.trim().isNotEmpty) {
                  await ref.read(centerProvider.notifier).addCenter(_center.trim(), 'Auto-added', 0);
                }

                if (widget.existingRecord == null) {
                  await ref.read(dailyRecordProvider.notifier).addJammer(
                    JammerRecord(
                      id: '',
                      date: _dateCtrl.text,
                      name: _name,
                      center: _center,
                      duty: _duty,
                      examName: _examName,
                      totalShifts: '',
                      payment: _payment,
                    ),
                  );
                } else {
                  await ref.read(dailyRecordProvider.notifier).updateJammer(
                    widget.existingRecord!.id,
                    JammerRecord(
                      id: widget.existingRecord!.id,
                      date: _dateCtrl.text,
                      name: _name,
                      center: _center,
                      duty: _duty,
                      examName: _examName,
                      totalShifts: '',
                      payment: _payment,
                    ),
                  );
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jammer record saved successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save record: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- POD Tab ---
class PodTab extends ConsumerStatefulWidget {
  const PodTab({super.key});
  @override
  ConsumerState<PodTab> createState() => _PodTabState();
}

class _PodTabState extends ConsumerState<PodTab> {
  String _searchQuery = '';
  int _selectedMonth = getCurrentMonth();

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPodDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyRecordProvider);
    // First filter by month, then by search query
    final monthFiltered = state.podRecords.where((r) => matchesMonth(r.date, _selectedMonth)).toList();
    final records = monthFiltered.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.date.toLowerCase().contains(q) || 
             r.center.toLowerCase().contains(q) ||
             r.examName.toLowerCase().contains(q) ||
             r.type.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MonthFilterDropdown(
                  selectedMonth: _selectedMonth,
                  onChanged: (val) => setState(() => _selectedMonth = val),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${records.length} records',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: 'Search (Date, Center, Type, Exam)', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(
                    context,
                    records,
                    monthFiltered,
                    (dataList) async {
                      await DailyReportService.exportPdf(
                        title: 'POD',
                        headers: ['DATE', 'TYPE', 'TOTAL POD', 'CENTER', 'EXAM NAME'],
                        data: dataList.map((r) => <String>[r.date, r.type, r.totalPod, r.center, r.examName]).toList(),
                      );
                    }
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade900),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(context, records, monthFiltered, (dataList) async {
                    await DailyReportService.exportExcel(
                      title: 'POD',
                      headers: ['DATE', 'TYPE', 'TOTAL POD', 'CENTER', 'EXAM NAME'],
                      data: dataList.map((r) => <String>[r.date, r.type, r.totalPod, r.center, r.examName]).toList(),
                    );
                  });},
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
              ),
              const Spacer(),
              ElevatedButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('TOTAL POD')),
                  DataColumn(label: Text('CENTER')),
                  DataColumn(label: Text('EXAM NAME')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: records.map((r) => DataRow(cells: [
                  DataCell(Text(r.date)),
                  DataCell(Text(r.type)),
                  DataCell(Text(r.totalPod)),
                  DataCell(Text(r.center)),
                  DataCell(Text(r.examName)),
                  DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(dailyRecordProvider.notifier).deleteRecord(r.id))),
                ])).toList(),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPodDialog extends ConsumerStatefulWidget {
  const AddPodDialog({super.key});
  @override
  ConsumerState<AddPodDialog> createState() => _AddPodDialogState();
}

class _AddPodDialogState extends ConsumerState<AddPodDialog> {
  final _dateCtrl = TextEditingController(text: DateFormat('dd-MMM').format(DateTime.now()));
  final _typeCtrl = TextEditingController();
  final _totalPodCtrl = TextEditingController();
  final _centerCtrl = TextEditingController();
  final _examCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add POD Record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _dateCtrl, decoration: const InputDecoration(labelText: 'Date (e.g. 01-Jun)')),
            TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Type')),
            TextField(controller: _totalPodCtrl, decoration: const InputDecoration(labelText: 'Total POD')),
            TextField(controller: _centerCtrl, decoration: const InputDecoration(labelText: 'Center')),
            TextField(controller: _examCtrl, decoration: const InputDecoration(labelText: 'Exam Name')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            ref.read(dailyRecordProvider.notifier).addPod(
              PodRecord(id: '', date: _dateCtrl.text, type: _typeCtrl.text, totalPod: _totalPodCtrl.text, center: _centerCtrl.text, examName: _examCtrl.text),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- Work Tab ---
class WorkTab extends ConsumerStatefulWidget {
  const WorkTab({super.key});
  @override
  ConsumerState<WorkTab> createState() => _WorkTabState();
}

class _WorkTabState extends ConsumerState<WorkTab> {
  String _searchQuery = '';
  int _selectedMonth = getCurrentMonth();

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddWorkDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyRecordProvider);
    // First filter by month, then by search query
    final monthFiltered = state.workRecords.where((r) => matchesMonth(r.date, _selectedMonth)).toList();
    final records = monthFiltered.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.date.toLowerCase().contains(q) || 
             r.work.toLowerCase().contains(q) ||
             r.type.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MonthFilterDropdown(
                  selectedMonth: _selectedMonth,
                  onChanged: (val) => setState(() => _selectedMonth = val),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${records.length} records',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(labelText: 'Search (Date, Work, Type)', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(
                    context,
                    records,
                    monthFiltered,
                    (dataList) async {
                      await DailyReportService.exportPdf(
                        title: 'Work',
                        headers: ['DATE', 'WORK', 'TYPE'],
                        data: dataList.map((r) => <String>[r.date, r.work, r.type]).toList(),
                      );
                    }
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade900),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await _handleExportOption(context, records, monthFiltered, (dataList) async {
                    await DailyReportService.exportExcel(
                      title: 'Work',
                      headers: ['DATE', 'WORK', 'TYPE'],
                      data: dataList.map((r) => <String>[r.date, r.work, r.type]).toList(),
                    );
                  });},
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
              ),
              const Spacer(),
              ElevatedButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('WORK')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: records.map((r) => DataRow(cells: [
                  DataCell(Text(r.date)),
                  DataCell(Text(r.work)),
                  DataCell(Text(r.type)),
                  DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(dailyRecordProvider.notifier).deleteRecord(r.id))),
                ])).toList(),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddWorkDialog extends ConsumerStatefulWidget {
  const AddWorkDialog({super.key});
  @override
  ConsumerState<AddWorkDialog> createState() => _AddWorkDialogState();
}

class _AddWorkDialogState extends ConsumerState<AddWorkDialog> {
  final _dateCtrl = TextEditingController(text: DateFormat('dd-MMM').format(DateTime.now()));
  final _workCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Work Record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _dateCtrl, decoration: const InputDecoration(labelText: 'Date (e.g. 01-Jun)')),
            TextField(controller: _workCtrl, decoration: const InputDecoration(labelText: 'Work')),
            TextField(controller: _typeCtrl, decoration: const InputDecoration(labelText: 'Type')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            ref.read(dailyRecordProvider.notifier).addWork(
              WorkRecord(id: '', date: _dateCtrl.text, work: _workCtrl.text, type: _typeCtrl.text),
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class SearchableDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool allowAddNew;
  final String? Function(String?)? validator;

  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.allowAddNew = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(text: value),
      readOnly: true,
      validator: validator,
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return SearchSelectorDialog(
              title: label,
              options: options,
              allowAddNew: allowAddNew,
              initialValue: value,
              onSelected: onSelected,
            );
          },
        );
      },
    );
  }
}

class SearchSelectorDialog extends StatefulWidget {
  final String title;
  final List<String> options;
  final bool allowAddNew;
  final String initialValue;
  final ValueChanged<String> onSelected;

  const SearchSelectorDialog({
    super.key,
    required this.title,
    required this.options,
    required this.allowAddNew,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<SearchSelectorDialog> createState() => _SearchSelectorDialogState();
}

class _SearchSelectorDialogState extends State<SearchSelectorDialog> {
  late List<String> _filteredOptions;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final sortedOptions = List<String>.from(widget.options)..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _filteredOptions = sortedOptions;
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final query = _searchCtrl.text.toLowerCase();
    final sortedOptions = List<String>.from(widget.options)..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    setState(() {
      _filteredOptions = sortedOptions
          .where((opt) => opt.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAddBtn = widget.allowAddNew &&
        _searchCtrl.text.isNotEmpty &&
        !widget.options.any((o) => o.toLowerCase() == _searchCtrl.text.trim().toLowerCase());

    return AlertDialog(
      title: Text('Select ${widget.title}'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredOptions.length + (showAddBtn ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _filteredOptions.length) {
                      final opt = _filteredOptions[index];
                      final isSelected = opt.toLowerCase() == widget.initialValue.toLowerCase();
                      return ListTile(
                        title: Text(
                          opt,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF007A87) : null,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF007A87)) : null,
                        dense: true,
                        onTap: () {
                          widget.onSelected(opt);
                          Navigator.pop(context);
                        },
                      );
                    } else {
                      final query = _searchCtrl.text.trim();
                      return ListTile(
                        leading: const Icon(Icons.add, color: Color(0xFF007A87)),
                        title: Text('Add "$query"', style: const TextStyle(color: Color(0xFF007A87), fontWeight: FontWeight.bold)),
                        dense: true,
                        onTap: () {
                          widget.onSelected(query);
                          Navigator.pop(context);
                        },
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

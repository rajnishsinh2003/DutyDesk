import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../providers/invigilator_provider.dart';
import '../providers/center_provider.dart';

class AdminPayrollScreen extends ConsumerStatefulWidget {
  const AdminPayrollScreen({super.key});

  @override
  ConsumerState<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends ConsumerState<AdminPayrollScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  String _paymentStatusFilter = 'all'; // 'all', 'pending', 'approved', 'paid'
  String? _selectedCenterFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPaymentStatusDialog(ExamDuty duty) {
    final s = S.of(context)!;
    String currentStatus = duty.paymentStatus;
    final refController = TextEditingController(text: duty.paymentReference ?? '');
    final remarksController = TextEditingController(text: duty.paymentRemarks ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${s.update} ${s.status}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.assignedDuty}: ${duty.examName} (${duty.date})', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text('${s.remuneration}: ${duty.payment}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF007A87))),
              const SizedBox(height: 16),
              Text('${s.status}:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusOption('pending', s.pending, Colors.orange, currentStatus, (st) => setDialogState(() => currentStatus = st)),
                  const SizedBox(width: 8),
                  _buildStatusOption('approved', s.approved, Colors.blue, currentStatus, (st) => setDialogState(() => currentStatus = st)),
                  const SizedBox(width: 8),
                  _buildStatusOption('paid', s.paid, Colors.green, currentStatus, (st) => setDialogState(() => currentStatus = st)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: refController,
                decoration: InputDecoration(
                  labelText: s.paymentReference,
                  hintText: 'e.g. UPI-9837492837',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksController,
                decoration: InputDecoration(
                  labelText: s.paymentRemarks,
                  hintText: 'e.g. Bank Transfer',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A87), foregroundColor: Colors.white),
              onPressed: () async {
                await ref.read(dutyProvider.notifier).updateDutyPaymentStatus(
                      duty.id,
                      currentStatus,
                      paymentReference: refController.text.trim(),
                      paymentRemarks: remarksController.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String value, String label, Color color, String current, ValueChanged<String> onSelect) {
    final isSelected = current == value;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 1.5 : 0.8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPayrollPdf(List<ExamDuty> duties, List<Invigilator> invs) async {
    final pdf = pw.Document();
    final monthStr = DateFormat('MMMM yyyy').format(_selectedMonth);

    // Compute totals
    int totalAmount = 0;
    for (final d in duties) {
      totalAmount += d.parsedPaymentAmount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DutyDesk Remuneration Statement', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Month: $monthStr', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Total Duties: ${duties.length}  |  Total Remuneration: Rs. $totalAmount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Staff Name', 'Res ID', 'Center', 'Shift', 'Amount', 'Payment Status'],
              data: duties.map((d) {
                final staff = invs.firstWhere((i) => i.id == d.invigilatorId, orElse: () => Invigilator(id: '', name: 'Staff', resourceId: '-', mobile: '', mockDutyCount: 0));
                return [
                  d.date,
                  staff.name,
                  staff.resourceId,
                  d.centerName,
                  'Shift ${d.shift}',
                  d.payment,
                  d.paymentStatus.toUpperCase(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final duties = ref.watch(globalDutyProvider);
    final invs = ref.watch(invigilatorProvider);
    final centers = ref.watch(centerProvider);

    final monthPrefix = DateFormat('yyyy-MM').format(_selectedMonth);
    final monthDuties = duties.where((d) => d.date.startsWith(monthPrefix)).toList();

    // Compute financial aggregates for the selected month
    int totalRemuneration = 0;
    int approvedRemuneration = 0;
    int paidRemuneration = 0;
    int pendingRemuneration = 0;

    for (final d in monthDuties) {
      final amount = d.parsedPaymentAmount;
      totalRemuneration += amount;
      if (d.paymentStatus == 'paid') {
        paidRemuneration += amount;
      } else if (d.paymentStatus == 'approved') {
        approvedRemuneration += amount;
      } else {
        pendingRemuneration += amount;
      }
    }

    // Filter duties for the detailed list
    final filteredDuties = monthDuties.where((d) {
      if (_paymentStatusFilter != 'all' && d.paymentStatus != _paymentStatusFilter) return false;
      if (_selectedCenterFilter != null && _selectedCenterFilter!.isNotEmpty && d.centerName != _selectedCenterFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final staff = invs.firstWhere((i) => i.id == d.invigilatorId, orElse: () => Invigilator(id: '', name: '', resourceId: '', mobile: '', mockDutyCount: 0));
        if (!staff.name.toLowerCase().contains(q) && !staff.resourceId.toLowerCase().contains(q) && !d.examName.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Staff-wise aggregation
    final Map<String, List<ExamDuty>> staffDutyMap = {};
    for (final d in monthDuties) {
      staffDutyMap.putIfAbsent(d.invigilatorId, () => []).add(d);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.payrollSalary, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: s.exportStatement,
            onPressed: () => _exportPayrollPdf(monthDuties, invs),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF007A87),
          tabs: [
            Tab(text: s.detailedPayments),
            Tab(text: s.staffSummary),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF007A87).withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF007A87)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),

          // Summary KPI Cards (4 Cards)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: _buildKpiCard(s.totalRemuneration, '₹$totalRemuneration', const Color(0xFF007A87))),
                const SizedBox(width: 8),
                Expanded(child: _buildKpiCard(s.approved, '₹$approvedRemuneration', Colors.blue.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _buildKpiCard(s.paid, '₹$paidRemuneration', Colors.green.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _buildKpiCard(s.pending, '₹$pendingRemuneration', Colors.orange.shade800)),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '${s.search}...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _selectedCenterFilter,
                  underline: const SizedBox(),
                  hint: Text('${s.all} ${s.centers}', style: const TextStyle(fontSize: 12)),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text('${s.all} ${s.centers}', style: const TextStyle(fontSize: 12))),
                    ...centers.map((c) => DropdownMenuItem<String?>(value: c.name, child: Text(c.name, style: const TextStyle(fontSize: 12)))),
                  ],
                  onChanged: (val) => setState(() => _selectedCenterFilter = val),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _paymentStatusFilter,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('${s.all} ${s.status}', style: const TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'pending', child: Text(s.pending, style: const TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'approved', child: Text(s.approved, style: const TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'paid', child: Text(s.paid, style: const TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentStatusFilter = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Detailed Duty Payments List
                _buildDetailedDutyList(filteredDuties, invs, s),

                // TAB 2: Staff-Wise Summary List
                _buildStaffSummaryList(staffDutyMap, invs, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDetailedDutyList(List<ExamDuty> duties, List<Invigilator> invs, S s) {
    if (duties.isEmpty) {
      return Center(child: Text(s.noDataFound));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: duties.length,
      itemBuilder: (context, index) {
        final duty = duties[index];
        final staff = invs.firstWhere(
          (i) => i.id == duty.invigilatorId,
          orElse: () => Invigilator(id: '', name: 'Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
        );

        Color badgeColor = Colors.orange;
        String statusText = s.pending;
        if (duty.paymentStatus == 'paid') {
          badgeColor = Colors.green;
          statusText = s.paid;
        } else if (duty.paymentStatus == 'approved') {
          badgeColor = Colors.blue;
          statusText = s.approved;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(duty.payment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF007A87))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${s.resourceId}: ${staff.resourceId} • ${duty.examName} (${duty.date})', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${s.shift} ${duty.shift} • ${duty.centerName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badgeColor, width: 0.8),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                            ),
                          ),
                        ],
                      ),
                      if (duty.paymentReference != null && duty.paymentReference!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${s.paymentReference}: ${duty.paymentReference}', style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Color(0xFF007A87)),
                  tooltip: s.update,
                  onPressed: () => _showPaymentStatusDialog(duty),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffSummaryList(Map<String, List<ExamDuty>> staffDutyMap, List<Invigilator> invs, S s) {
    if (staffDutyMap.isEmpty) {
      return Center(child: Text(s.noDataFound));
    }

    final staffIds = staffDutyMap.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: staffIds.length,
      itemBuilder: (context, index) {
        final staffId = staffIds[index];
        final staffDuties = staffDutyMap[staffId] ?? [];
        final staff = invs.firstWhere(
          (i) => i.id == staffId,
          orElse: () => Invigilator(id: '', name: 'Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
        );

        int totalEarned = 0;
        int paid = 0;
        int pending = 0;
        int completedCount = 0;

        for (final d in staffDuties) {
          final amt = d.parsedPaymentAmount;
          totalEarned += amt;
          if (d.paymentStatus == 'paid') {
            paid += amt;
          } else {
            pending += amt;
          }
          if (d.isReached) completedCount++;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('${s.resourceId}: ${staff.resourceId} • ${s.totalDuties}: ${staffDuties.length} ($completedCount ${s.completed})', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Text('₹$totalEarned', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF007A87))),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${s.paid}: ₹$paid', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('${s.pending}: ₹$pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                    if (pending > 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007A87),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          final pendingDutyIds = staffDuties.where((d) => d.paymentStatus != 'paid').map((d) => d.id).toList();
                          await ref.read(dutyProvider.notifier).bulkUpdatePaymentStatus(pendingDutyIds, 'paid');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${s.paid}: ${staff.name}!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        child: Text(s.markPaid, style: const TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

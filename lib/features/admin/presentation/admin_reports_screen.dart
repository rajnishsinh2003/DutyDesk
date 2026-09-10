import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/invigilator_provider.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../services/report_service.dart';
import '../../../core/services/location_service.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  final String? initialStatusFilter;

  const AdminReportsScreen({super.key, this.initialStatusFilter});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  // Filters
  String _statusFilter = 'all';
  String _searchQuery = '';
  String _shiftFilter = 'all';
  String _centerFilter = 'all';
  String _reachedFilter = 'all'; // 'all', 'reached', 'not_reached'
  DateTimeRange? _selectedDateRange;

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _statusFilter = widget.initialStatusFilter!;
    }
  }

  String _buildFilterDescription(S s) {
    final parts = <String>[];
    if (_statusFilter != 'all') parts.add('${s.status}: ${_statusFilter.toUpperCase()}');
    if (_shiftFilter != 'all') parts.add('${s.shift}: $_shiftFilter');
    if (_centerFilter != 'all') parts.add('${s.center}: $_centerFilter');
    if (_reachedFilter != 'all') parts.add('${s.arrival}: ${_reachedFilter.toUpperCase()}');
    if (_selectedDateRange != null) {
      parts.add('${s.date}: ${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}');
    }
    if (_searchQuery.isNotEmpty) parts.add('${s.search}: "$_searchQuery"');
    return parts.isEmpty ? s.allAllocations : parts.join(' | ');
  }

  void _showExportModal(List<ExamDuty> filteredDuties, List<Invigilator> invigilators) {
    final s = S.of(context)!;
    final filterDesc = _buildFilterDescription(s);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.generateReport, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${s.exportingRecords(filteredDuties.length)}\nFilter: $filterDesc',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(s.exportPdf),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isExporting = true);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ReportService.exportPdf(
                    duties: filteredDuties,
                    invigilators: invigilators,
                    filterDescription: filterDesc,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(s.pdfError(e.toString())), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isExporting = false);
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart_outlined),
              label: Text(s.exportExcel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isExporting = true);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ReportService.exportExcel(
                    duties: filteredDuties,
                    invigilators: invigilators,
                    filterDescription: filterDesc,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(s.excelError(e.toString())), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isExporting = false);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final allDuties = ref.watch(globalDutyProvider);
    final invigilators = ref.watch(invigilatorProvider);

    final centers = allDuties.map((d) => d.centerName).toSet().toList();

    // Filtering logic
    final filteredDuties = allDuties.where((duty) {
      final inv = invigilators.firstWhere(
        (i) => i.id == duty.invigilatorId,
        orElse: () => Invigilator(id: '', name: '', resourceId: '', mobile: '', mockDutyCount: 0),
      );

      // Status
      if (_statusFilter != 'all' && duty.status.toLowerCase() != _statusFilter.toLowerCase()) {
        return false;
      }

      // Shift
      if (_shiftFilter != 'all' && duty.shift != _shiftFilter) {
        return false;
      }

      // Center
      if (_centerFilter != 'all' && duty.centerName != _centerFilter) {
        return false;
      }

      // Reached
      if (_reachedFilter == 'reached' && !duty.isReached) {
        return false;
      }
      if (_reachedFilter == 'not_reached' && duty.isReached) {
        return false;
      }

      // Date Range
      if (_selectedDateRange != null) {
        try {
          final dt = DateTime.parse(duty.date);
          final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
          if (dt.isBefore(start) || dt.isAfter(end)) {
            return false;
          }
        } catch (_) {}
      }

      // General search query (Name, Exam, Mobile, Center, Resource ID)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchExam = duty.examName.toLowerCase().contains(q);
        final matchCenter = duty.centerName.toLowerCase().contains(q);
        final matchName = inv.name.toLowerCase().contains(q);
        final matchMobile = inv.mobile.toLowerCase().contains(q);
        final matchResource = inv.resourceId.toLowerCase().contains(q);
        if (!matchExam && !matchCenter && !matchName && !matchMobile && !matchResource) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.reports),
        actions: [
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: const Icon(Icons.share_outlined, color: Color(0xFF007A87)),
                  tooltip: s.exportPdf,
                  onPressed: () => _showExportModal(filteredDuties, invigilators),
                ),
        ],
      ),
      body: Column(
        children: [
          // FILTERS ACCORDION / CONTAINER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar (Name, Exam, Resource ID, Mobile)
                TextField(
                  decoration: InputDecoration(
                    hintText: '${s.search}...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF007A87)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 10),

                // Date Picker Chip + Quick Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date Range Filter Button
                      ActionChip(
                        avatar: Icon(
                          Icons.date_range,
                          size: 16,
                          color: _selectedDateRange != null ? Colors.white : const Color(0xFF007A87),
                        ),
                        label: Text(
                          _selectedDateRange == null
                              ? s.dateRange
                              : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedDateRange != null ? Colors.white : null,
                          ),
                        ),
                        backgroundColor: _selectedDateRange != null ? const Color(0xFF007A87) : null,
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: _selectedDateRange,
                          );
                          if (picked != null) {
                            setState(() => _selectedDateRange = picked);
                          }
                        },
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: s.clear,
                          onPressed: () => setState(() => _selectedDateRange = null),
                        ),
                      ],
                      const SizedBox(width: 8),

                      // Shift Filter
                      DropdownButton<String>(
                        value: _shiftFilter,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('${s.all} ${s.shift}', style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '1', child: Text(s.shift1Amount(400), style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '2', child: Text(s.shift2Amount(600), style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '3', child: Text(s.shift3Amount(800), style: const TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => setState(() => _shiftFilter = val!),
                      ),
                      const SizedBox(width: 8),

                      // Status Filter
                      DropdownButton<String>(
                        value: _statusFilter,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('${s.all} ${s.status}', style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'accepted', child: Text(s.accepted, style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'pending', child: Text(s.pending, style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'rejected', child: Text(s.rejected, style: const TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => setState(() => _statusFilter = val!),
                      ),
                      const SizedBox(width: 8),

                      // Center Filter
                      DropdownButton<String>(
                        value: _centerFilter,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('${s.all} ${s.centers}', style: const TextStyle(fontSize: 12))),
                          ...centers.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))),
                        ],
                        onChanged: (val) => setState(() => _centerFilter = val!),
                      ),
                      const SizedBox(width: 8),

                      // Arrival Filter
                      DropdownButton<String>(
                        value: _reachedFilter,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('${s.all} ${s.arrival}', style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'reached', child: Text(s.reached, style: const TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'not_reached', child: Text(s.pending, style: const TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => setState(() => _reachedFilter = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // RESULTS HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredDuties.length} ${s.totalDuties}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  _buildFilterDescription(s),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ALLOCATION RECORDS LIST
          Expanded(
            child: filteredDuties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(s.noReportsFound, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: filteredDuties.length,
                    itemBuilder: (context, index) {
                      final duty = filteredDuties[index];
                      final inv = invigilators.firstWhere(
                        (i) => i.id == duty.invigilatorId,
                        orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
                      );

                      final statusLabel = duty.status.toLowerCase() == 'accepted'
                          ? s.accepted
                          : (duty.status.toLowerCase() == 'rejected' ? s.rejected : s.pending);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      inv.name, // COMPLETE FULL NAME
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  _buildStatusBadge(duty.status, statusLabel),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('${s.resourceId}: ${inv.resourceId}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  Text('${s.mobile}: ${inv.mobile}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${s.exams}: ${duty.examName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${s.date}: ${duty.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${s.center}: ${duty.centerName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                                  Text('${s.shift} ${duty.shift} • ${duty.payment}', style: const TextStyle(fontSize: 12, color: Color(0xFF007A87), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (duty.isReached) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade300, width: 0.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${s.arrival}: ${duty.reachedTime ?? "-"} (${duty.reachedPerformance ?? s.onTime})',
                                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          if (duty.resolvedMapsUrl != null)
                                            GestureDetector(
                                              onTap: () => LocationService.openMapLocation(
                                                duty.resolvedMapsUrl!,
                                                latitude: duty.reachedLatitude,
                                                longitude: duty.reachedLongitude,
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.map_outlined, size: 13, color: Color(0xFF007A87)),
                                                  SizedBox(width: 3),
                                                  Text('Map', style: TextStyle(color: Color(0xFF007A87), fontSize: 11, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (duty.reachedLocation != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'GPS: ${duty.reachedLocation}',
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, String label) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

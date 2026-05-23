import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/invigilator_provider.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../services/report_service.dart';

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
  String _resourceIdQuery = '';
  String? _dateFilter; // 'YYYY-MM-DD'

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      _statusFilter = widget.initialStatusFilter!;
    }
  }

  String _getRoleDisplayName(String roleCode) {
    switch (roleCode.toLowerCase()) {
      case 'inv': return 'Invigilator';
      case 'ls': return 'Lab Staff';
      case 'mtoe': return 'MTOE';
      default: return roleCode.toUpperCase();
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String examName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Allocation'),
        content: Text('Delete duty allocation for "$examName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(dutyProvider.notifier).deleteDuty(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Duty deleted.'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _buildFilterDescription() {
    final parts = <String>[];
    if (_statusFilter != 'all') parts.add('Status: ${_statusFilter.toUpperCase()}');
    if (_shiftFilter != 'all') parts.add('Shift: $_shiftFilter');
    if (_centerFilter != 'all') parts.add('Center: $_centerFilter');
    if (_dateFilter != null) parts.add('Date: $_dateFilter');
    if (_resourceIdQuery.isNotEmpty) parts.add('Resource ID: $_resourceIdQuery');
    if (_searchQuery.isNotEmpty) parts.add('Search: "$_searchQuery"');
    return parts.isEmpty ? 'All Duties' : parts.join(' | ');
  }

  void _showExportModal(List filteredDuties, List invigilators) {
    final filterDesc = _buildFilterDescription();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Export Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Exporting ${filteredDuties.length} record(s)\nFilter: $filterDesc',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            // PDF Button
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export as PDF'),
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
                    duties: filteredDuties.cast(),
                    invigilators: invigilators.cast(),
                    filterDescription: filterDesc,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('PDF Error: $e'), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isExporting = false);
                }
              },
            ),
            const SizedBox(height: 12),
            // Excel Button
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Export as Excel'),
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
                    duties: filteredDuties.cast(),
                    invigilators: invigilators.cast(),
                    filterDescription: filterDesc,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Excel Error: $e'), backgroundColor: Colors.red),
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

  void _showAdvancedFilters(List<String> centerNames) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _shiftFilter = 'all';
                          _centerFilter = 'all';
                          _dateFilter = null;
                          _resourceIdQuery = '';
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
                  title: Text(_dateFilter ?? 'Filter by Date', style: TextStyle(color: _dateFilter != null ? Colors.black : Colors.grey)),
                  trailing: _dateFilter != null
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { setModalState(() {}); setState(() => _dateFilter = null); })
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      setModalState(() {});
                      setState(() => _dateFilter = formatted);
                    }
                  },
                ),
                const Divider(),

                // Center dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Center',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _centerFilter,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Centers')),
                    ...centerNames.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (val) {
                    setModalState(() {});
                    setState(() => _centerFilter = val!);
                  },
                ),
                const SizedBox(height: 12),

                // Shift dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Shift',
                    prefixIcon: Icon(Icons.schedule),
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _shiftFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Shifts')),
                    DropdownMenuItem(value: '1', child: Text('Shift 1')),
                    DropdownMenuItem(value: '2', child: Text('Shift 2')),
                    DropdownMenuItem(value: '3', child: Text('Shift 3')),
                  ],
                  onChanged: (val) {
                    setModalState(() {});
                    setState(() => _shiftFilter = val!);
                  },
                ),
                const SizedBox(height: 12),

                // Resource ID
                TextFormField(
                  initialValue: _resourceIdQuery,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Resource ID',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() => _resourceIdQuery = val.trim());
                  },
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duties = ref.watch(globalDutyProvider);
    final invigilators = ref.watch(invigilatorProvider);

    // Collect unique center names for filter
    final centerNames = duties.map((d) => d.centerName).toSet().toList()..sort();

    // Apply all filters
    final filteredDuties = duties.where((duty) {
      final inv = invigilators.firstWhere(
        (i) => i.id == duty.invigilatorId,
        orElse: () => Invigilator(id: '', name: 'Unknown', resourceId: '', mobile: '', mockDutyCount: 0),
      );

      final matchesStatus = _statusFilter == 'all' || duty.status.toLowerCase() == _statusFilter;
      final matchesShift = _shiftFilter == 'all' || duty.shift == _shiftFilter;
      final matchesCenter = _centerFilter == 'all' || duty.centerName == _centerFilter;
      final matchesDate = _dateFilter == null || duty.date.contains(_dateFilter!);
      final matchesResourceId = _resourceIdQuery.isEmpty ||
          inv.resourceId.toLowerCase().contains(_resourceIdQuery.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          duty.examName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          duty.centerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          inv.name.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesShift && matchesCenter && matchesDate &&
             matchesResourceId && matchesSearch;
    }).toList();

    final totalCount = duties.length;
    final acceptedCount = duties.where((d) => d.status.toLowerCase() == 'accepted').length;
    final pendingCount = duties.where((d) => d.status.toLowerCase() == 'pending').length;
    final rejectedCount = duties.where((d) => d.status.toLowerCase() == 'rejected').length;

    // Count active filters
    final activeFilterCount = [
      _statusFilter != 'all',
      _shiftFilter != 'all',
      _centerFilter != 'all',
      _dateFilter != null,
      _resourceIdQuery.isNotEmpty,
    ].where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty Reports & Summary'),
        actions: [
          // Advanced filters button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Advanced Filters',
                onPressed: () => _showAdvancedFilters(centerNames),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('$activeFilterCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          // Export button
          _isExporting
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Export Report',
                  onPressed: () => _showExportModal(filteredDuties, invigilators),
                ),
        ],
      ),
      body: Column(
        children: [
          // Stats Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Total', totalCount.toString(), Colors.blue),
                _buildMiniStat('Accepted', acceptedCount.toString(), Colors.green),
                _buildMiniStat('Pending', pendingCount.toString(), Colors.orange),
                _buildMiniStat('Rejected', rejectedCount.toString(), Colors.red),
              ],
            ),
          ),

          // Search & Status Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: 'Exam, center, or invigilator name…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        initialValue: _statusFilter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Duties')),
                          DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (val) { if (val != null) setState(() => _statusFilter = val); },
                      ),
                    ),
                    if (activeFilterCount > 0) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('$activeFilterCount filter${activeFilterCount > 1 ? 's' : ''}'),
                        deleteIcon: const Icon(Icons.clear, size: 14),
                        onDeleted: () => setState(() {
                          _shiftFilter = 'all';
                          _centerFilter = 'all';
                          _dateFilter = null;
                          _resourceIdQuery = '';
                        }),
                        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: Color(0xFF2563EB), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredDuties.length} result${filteredDuties.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: filteredDuties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No records match your filters.',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() {
                            _statusFilter = 'all'; _shiftFilter = 'all';
                            _centerFilter = 'all'; _dateFilter = null;
                            _resourceIdQuery = ''; _searchQuery = '';
                          }),
                          child: const Text('Clear all filters'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDuties.length,
                    itemBuilder: (context, index) {
                      final duty = filteredDuties[index];
                      final inv = invigilators.firstWhere(
                        (i) => i.id == duty.invigilatorId,
                        orElse: () => Invigilator(id: '', name: 'Unknown', resourceId: '', mobile: '', mockDutyCount: 0),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row: Exam Name + Status badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(duty.examName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusTag(status: duty.status),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(context, ref, duty.id, duty.examName),
                                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Info grid
                              _InfoRow(Icons.person, 'Invigilator', '${inv.name} · ${inv.resourceId}'),
                              const SizedBox(height: 4),
                              _InfoRow(Icons.business, 'Center', duty.centerName),
                              const SizedBox(height: 4),
                              _InfoRow(Icons.calendar_today, 'Date', duty.date),
                              const Divider(height: 16),
                              // Detailed row
                              Row(
                                children: [
                                  Expanded(child: _InfoRow(Icons.badge_outlined, 'Role', _getRoleDisplayName(duty.role))),
                                  Expanded(child: _InfoRow(Icons.schedule_outlined, 'Shift', duty.shift)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(child: _InfoRow(Icons.currency_rupee, 'Payment', duty.payment)),
                                  Expanded(child: _InfoRow(Icons.restaurant_outlined, 'Lunch', duty.lunch)),
                                ],
                              ),
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

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;
  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

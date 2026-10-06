import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/incident_model.dart';
import '../providers/incident_provider.dart';
import '../services/incident_report_service.dart';
import '../../auth/auth_provider.dart';

class AdminIncidentsScreen extends ConsumerStatefulWidget {
  const AdminIncidentsScreen({super.key});

  @override
  ConsumerState<AdminIncidentsScreen> createState() => _AdminIncidentsScreenState();
}

class _AdminIncidentsScreenState extends ConsumerState<AdminIncidentsScreen> {
  String _statusFilter = 'all'; // 'all', 'open', 'investigating', 'resolved'
  String _severityFilter = 'all'; // 'all', 'critical', 'high', 'medium', 'low'
  final String _typeFilter = 'all'; // 'all', 'malpractice', 'technical', 'medical', 'room_change', 'security'
  String _searchQuery = '';

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available'), backgroundColor: Colors.orange),
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

  void _showResolveDialog(IncidentReport inc) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Resolve Incident', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Incident: "${inc.title}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${inc.centerName} • Room ${inc.room}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 14),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resolution Action / Notes *',
                hintText: 'Describe how the incident was handled and resolved...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final notes = notesCtrl.text.trim();
              if (notes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter resolution notes'), backgroundColor: Colors.orange),
                );
                return;
              }
              final adminName = ref.read(authProvider).userName ?? 'Admin';
              await ref.read(incidentProvider.notifier).updateIncidentStatus(
                    inc.id,
                    'resolved',
                    resolutionNotes: notes,
                    resolvedBy: adminName,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incident marked as Resolved!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetailModal(IncidentReport inc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Severity & Status Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: inc.severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: inc.severityColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: inc.severityColor),
                        const SizedBox(width: 4),
                        Text(
                          inc.severity.toUpperCase(),
                          style: TextStyle(color: inc.severityColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: inc.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: inc.statusColor, width: 1),
                    ),
                    child: Text(
                      inc.status.toUpperCase(),
                      style: TextStyle(color: inc.statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title & Type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: inc.severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(inc.typeIcon, color: inc.severityColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inc.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          inc.typeDisplayName,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),

              // Meta details (Exam, Center, Room, Timestamp)
              _buildDetailRow(Icons.book, 'Exam', inc.examName),
              _buildDetailRow(Icons.business, 'Center & Room', '${inc.centerName} • Room: ${inc.room.isNotEmpty ? inc.room : "N/A"}'),
              _buildDetailRow(Icons.access_time, 'Reported At', DateFormat('dd MMM yyyy, hh:mm a').format(inc.createdAt)),
              const Divider(),

              // Reporter Info Card with Call button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF007A87),
                      child: Text(
                        inc.reporterName.isNotEmpty ? inc.reporterName[0].toUpperCase() : 'S',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inc.reporterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${inc.reporterRole} • ${inc.reporterMobile}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (inc.reporterMobile.isNotEmpty)
                      IconButton.filled(
                        icon: const Icon(Icons.phone, size: 18),
                        style: IconButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _makePhoneCall(inc.reporterMobile),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description Section
              const Text('Incident Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Text(
                  inc.description,
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // Evidence Attachment Note (if any)
              if (inc.evidenceAttachment != null && inc.evidenceAttachment!.isNotEmpty) ...[
                const Text('Evidence & Attachment Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          inc.evidenceAttachment!,
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Resolution Details (if resolved)
              if (inc.status == 'resolved') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 18),
                          SizedBox(width: 6),
                          Text('Resolution Summary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(inc.resolutionNotes ?? 'Resolved without notes', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        'Resolved by ${inc.resolvedBy ?? "Admin"} on ${inc.resolvedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(inc.resolvedAt!) : "-"}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              Row(
                children: [
                  if (inc.status == 'open') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Investigate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref.read(incidentProvider.notifier).updateIncidentStatus(inc.id, 'investigating');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (inc.status != 'resolved') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Resolve Incident'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showResolveDialog(inc);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Incident',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Incident Report'),
                          content: const Text('Are you sure you want to permanently delete this incident record?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(incidentProvider.notifier).deleteIncident(inc.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentProvider);

    // Compute live metric counts
    final totalCount = incidents.length;
    final openCount = incidents.where((i) => i.status == 'open').length;
    final investigatingCount = incidents.where((i) => i.status == 'investigating').length;
    final resolvedCount = incidents.where((i) => i.status == 'resolved').length;
    final criticalCount = incidents.where((i) => i.severity == 'critical' && i.status != 'resolved').length;

    // Apply Filters
    final filtered = incidents.where((inc) {
      if (_statusFilter != 'all' && inc.status != _statusFilter) return false;
      if (_severityFilter != 'all' && inc.severity != _severityFilter) return false;
      if (_typeFilter != 'all' && inc.incidentType != _typeFilter) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = inc.title.toLowerCase().contains(q) ||
            inc.description.toLowerCase().contains(q) ||
            inc.reporterName.toLowerCase().contains(q) ||
            inc.centerName.toLowerCase().contains(q) ||
            inc.room.toLowerCase().contains(q) ||
            inc.examName.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: () async {
              try {
                await IncidentReportService.exportPdf(
                  incidents: filtered,
                  filterDescription: 'Status: $_statusFilter, Severity: $_severityFilter',
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Export Excel',
            onPressed: () async {
              try {
                await IncidentReportService.exportExcel(
                  incidents: filtered,
                  filterDescription: 'Status: $_statusFilter, Severity: $_severityFilter',
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Critical Banner Alert (if any active critical incidents)
            if (criticalCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$criticalCount CRITICAL INCIDENT${criticalCount > 1 ? "S" : ""} ACTIVE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Requires immediate administrative or security intervention.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF991B1B),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          _severityFilter = 'critical';
                          _statusFilter = 'open';
                        });
                      },
                      child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. Summary Metric Cards
            Row(
              children: [
                Expanded(child: _buildMetricCard('Total', '$totalCount', const Color(0xFF007A87), Icons.format_list_bulleted)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Open', '$openCount', Colors.red, Icons.error_outline)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('In Review', '$investigatingCount', Colors.blue, Icons.pending_actions)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard('Resolved', '$resolvedCount', Colors.green, Icons.check_circle_outline)),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Search Field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search incidents (Title, Staff, Center, Room, Exam)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 12),

            // 4. Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('All ($totalCount)', 'all'),
                  _buildStatusChip('Open ($openCount)', 'open', color: Colors.red),
                  _buildStatusChip('In Review ($investigatingCount)', 'investigating', color: Colors.blue),
                  _buildStatusChip('Resolved ($resolvedCount)', 'resolved', color: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 5. Severity Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Severity: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 4),
                  _buildSeverityChip('All', 'all'),
                  _buildSeverityChip('Critical', 'critical', color: const Color(0xFFDC2626)),
                  _buildSeverityChip('High', 'high', color: const Color(0xFFEA580C)),
                  _buildSeverityChip('Medium', 'medium', color: const Color(0xFFD97706)),
                  _buildSeverityChip('Low', 'low', color: const Color(0xFF0284C7)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Incidents List
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.verified_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No incident records matching current filters', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, idx) {
                  final inc = filtered[idx];
                  return _buildIncidentCard(inc);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, {Color? color}) {
    final isSelected = _statusFilter == value;
    final chipColor = color ?? const Color(0xFF007A87);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: chipColor,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        onSelected: (selected) {
          if (selected) setState(() => _statusFilter = value);
        },
      ),
    );
  }

  Widget _buildSeverityChip(String label, String value, {Color? color}) {
    final isSelected = _severityFilter == value;
    final chipColor = color ?? const Color(0xFF007A87);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: chipColor,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        onSelected: (selected) {
          if (selected) setState(() => _severityFilter = value);
        },
      ),
    );
  }

  Widget _buildIncidentCard(IncidentReport inc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: inc.severityColor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showIncidentDetailModal(inc),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Type & Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(inc.typeIcon, size: 18, color: inc.severityColor),
                      const SizedBox(width: 6),
                      Text(
                        inc.typeDisplayName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: inc.severityColor),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: inc.severityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: inc.severityColor, width: 0.8),
                        ),
                        child: Text(
                          inc.severity.toUpperCase(),
                          style: TextStyle(color: inc.severityColor, fontWeight: FontWeight.bold, fontSize: 9.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: inc.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: inc.statusColor, width: 0.8),
                        ),
                        child: Text(
                          inc.status.toUpperCase(),
                          style: TextStyle(color: inc.statusColor, fontWeight: FontWeight.bold, fontSize: 9.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),

              // Title
              Text(
                inc.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),

              // Description preview
              Text(
                inc.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 10),

              // Location & Reporter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${inc.centerName} (Rm ${inc.room})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(inc.createdAt),
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Bottom Reporter info
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reported by: ${inc.reporterName} (${inc.reporterRole})',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                  ),
                  const Text('View details →', style: TextStyle(fontSize: 11, color: Color(0xFF007A87), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

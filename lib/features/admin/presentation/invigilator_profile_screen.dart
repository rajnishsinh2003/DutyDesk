import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/invigilator_provider.dart';
import '../../invigilator/providers/duty_provider.dart';

class InvigilatorProfileScreen extends ConsumerWidget {
  final String invigilatorId;

  const InvigilatorProfileScreen({super.key, required this.invigilatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final invs = ref.watch(invigilatorProvider);
    final allDuties = ref.watch(globalDutyProvider);

    final inv = invs.firstWhere(
      (i) => i.id == invigilatorId,
      orElse: () => Invigilator(
        id: '',
        name: 'Unknown Staff',
        resourceId: '-',
        mobile: '',
        mockDutyCount: 0,
        isActive: false,
      ),
    );

    final staffDuties = allDuties.where((d) => d.invigilatorId == invigilatorId).toList();
    final totalAssigned = staffDuties.length;
    final acceptedCount = staffDuties.where((d) => d.status.toLowerCase() == 'accepted').length;
    final rejectedCount = staffDuties.where((d) => d.status.toLowerCase() == 'rejected').length;
    final pendingCount = staffDuties.where((d) => d.status.toLowerCase() == 'pending').length;

    // Calculate Acceptance Rate: (Accepted / Total Responses)
    final totalResponded = acceptedCount + rejectedCount;
    final acceptanceRate = totalResponded == 0 ? 0.0 : (acceptedCount / totalResponded) * 100;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.invigilatorProfile),
        elevation: 0,
      ),
      body: inv.id.isEmpty
          ? Center(child: Text(s.noDataFound))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. STUNNING HERO PROFILE HEADER CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar block
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: inv.isActive ? Colors.blue.shade100 : Colors.red.shade100,
                          backgroundImage: inv.photoUrl != null && inv.photoUrl!.isNotEmpty
                              ? NetworkImage(inv.photoUrl!)
                              : null,
                          child: inv.photoUrl == null || inv.photoUrl!.isEmpty
                              ? Text(
                                  inv.name.isNotEmpty ? inv.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: inv.isActive ? Colors.blue.shade800 : Colors.red.shade800,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          inv.name,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.resourceId}: ${inv.resourceId}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        // Active/Block Status Badge + Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: inv.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: inv.isActive ? Colors.green : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                inv.isActive ? s.active.toUpperCase() : s.blocked.toUpperCase(),
                                style: TextStyle(
                                  color: inv.isActive ? Colors.green : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Quick details rows
                        _buildProfileDetailRow(Icons.phone, s.mobile, inv.mobile, context),
                        _buildProfileDetailRow(Icons.email, s.email, inv.email ?? s.noDataAvailable, context),
                        _buildProfileDetailRow(Icons.home, s.address, inv.address ?? s.noDataAvailable, context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. DYNAMIC ACCEPTANCE RATE & STATISTICS PANEL
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.performance,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Circular Indicator for Acceptance Rate
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        height: 90,
                                        child: CircularProgressIndicator(
                                          value: acceptanceRate / 100,
                                          strokeWidth: 8,
                                          backgroundColor: Colors.grey.shade200,
                                          color: acceptanceRate > 75
                                              ? Colors.green
                                              : (acceptanceRate > 40 ? Colors.orange : Colors.red),
                                        ),
                                      ),
                                      Text(
                                        '${acceptanceRate.toStringAsFixed(0)}%',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.attendanceRate,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Mini stats columns
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  _buildStatCounter(s.totalDutiesAssigned, totalAssigned.toString(), Colors.blue),
                                  const SizedBox(height: 8),
                                  _buildStatCounter(s.accepted, acceptedCount.toString(), Colors.green),
                                  const SizedBox(height: 8),
                                  _buildStatCounter(s.rejected, rejectedCount.toString(), Colors.red),
                                  const SizedBox(height: 8),
                                  _buildStatCounter(s.pending, pendingCount.toString(), Colors.orange),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. COMPLETE ASSIGNMENT HISTORY LIST
                  Text(
                    '${s.dutyHistory} (${staffDuties.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (staffDuties.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(s.noDutiesAssigned, style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: staffDuties.length,
                      itemBuilder: (context, index) {
                        final d = staffDuties[index];
                        final statusLabel = d.status.toLowerCase() == 'accepted'
                            ? s.accepted
                            : (d.status.toLowerCase() == 'rejected' ? s.rejected : s.pending);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            title: Text(d.examName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text('${d.date} · ${s.shift} ${d.shift}', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.business, size: 12, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(d.centerName, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(d.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _getStatusColor(d.status), width: 0.8),
                              ),
                              child: Text(
                                statusLabel.toUpperCase(),
                                style: TextStyle(color: _getStatusColor(d.status), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  
                  // Toggle active/inactive button
                  ElevatedButton(
                    onPressed: () {
                      ref.read(invigilatorProvider.notifier).toggleInvigilatorActiveStatus(inv.id, !inv.isActive);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(inv.isActive ? '${inv.name} (${s.blocked})' : '${inv.name} (${s.active})'),
                          backgroundColor: inv.isActive ? Colors.red : Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inv.isActive ? Colors.red.shade700 : Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      inv.isActive ? '${s.blocked} ${s.staff}' : '${s.active} ${s.staff}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCounter(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_provider.dart';
import '../../admin/providers/invigilator_provider.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../../admin/providers/center_provider.dart';
import '../../incidents/providers/incident_provider.dart';
import '../../notifications/providers/notification_provider.dart';

/// Dedicated Auditor / Observer Dashboard
///
/// Provides a read-only, compliance-focused view of the examination system.
/// Features:
/// - Real-time KPI overview (duty stats, incidents, attendance)
/// - Audit trail log with timestamped system events
/// - Read-only duty roster with compliance flags
/// - Incident review panel
/// - Center compliance scorecard
class AuditorDashboardScreen extends ConsumerStatefulWidget {
  const AuditorDashboardScreen({super.key});

  @override
  ConsumerState<AuditorDashboardScreen> createState() => _AuditorDashboardScreenState();
}

class _AuditorDashboardScreenState extends ConsumerState<AuditorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final duties = ref.watch(globalDutyProvider);
    final invs = ref.watch(invigilatorProvider);
    final centers = ref.watch(centerProvider);
    final incidents = ref.watch(incidentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    const brandColor = Color(0xFF6366F1); // Indigo for auditor
    const auditGold = Color(0xFFEAB308);

    // KPI calculations
    final totalDuties = duties.length;
    final acceptedDuties = duties.where((d) => d.status == 'accepted').length;
    final rejectedDuties = duties.where((d) => d.status == 'rejected').length;
    final pendingDuties = duties.where((d) => d.status == 'pending').length;
    final clockedIn = duties.where((d) => d.isReached).length;
    final openIncidents = incidents.where((i) => i.status == 'open').length;
    final complianceRate = totalDuties > 0
        ? ((acceptedDuties / totalDuties) * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Auditor Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              auth.userName ?? 'NTA Observer',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Read-Only Badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: auditGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: auditGold, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility, size: 12, color: auditGold),
                SizedBox(width: 4),
                Text('READ-ONLY', style: TextStyle(color: auditGold, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'Audit Trail'),
            Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Roster'),
            Tab(icon: Icon(Icons.report_problem_outlined, size: 18), text: 'Incidents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // TAB 1: Overview
          _buildOverviewTab(
            textColor: textColor,
            cardBg: cardBg,
            brandColor: brandColor,
            totalDuties: totalDuties,
            acceptedDuties: acceptedDuties,
            rejectedDuties: rejectedDuties,
            pendingDuties: pendingDuties,
            clockedIn: clockedIn,
            openIncidents: openIncidents,
            complianceRate: complianceRate,
            totalInvs: invs.length,
            totalCenters: centers.length,
          ),
          // TAB 2: Audit Trail
          _buildAuditTrailTab(textColor: textColor, cardBg: cardBg, brandColor: brandColor),
          // TAB 3: Read-Only Roster
          _buildRosterTab(duties: duties, invs: invs, textColor: textColor, cardBg: cardBg),
          // TAB 4: Incidents Review
          _buildIncidentsTab(incidents: incidents, textColor: textColor, cardBg: cardBg),
        ],
      ),
    );
  }

  Widget _buildOverviewTab({
    required Color textColor,
    required Color cardBg,
    required Color brandColor,
    required int totalDuties,
    required int acceptedDuties,
    required int rejectedDuties,
    required int pendingDuties,
    required int clockedIn,
    required int openIncidents,
    required String complianceRate,
    required int totalInvs,
    required int totalCenters,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compliance Scorecard
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: brandColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                const Text('COMPLIANCE SCORECARD', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text('$complianceRate%', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800)),
                const Text('Duty Acceptance Rate', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _miniStat('Centers', totalCenters.toString(), Icons.location_city),
                    _miniStat('Faculty', totalInvs.toString(), Icons.people),
                    _miniStat('Clocked In', clockedIn.toString(), Icons.login),
                    _miniStat('Incidents', openIncidents.toString(), Icons.warning_amber),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPI Grid
          Text('Examination Duty Statistics', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _kpiCard('Total Duties', totalDuties.toString(), Icons.assignment, const Color(0xFF6366F1), cardBg, textColor),
              _kpiCard('Accepted', acceptedDuties.toString(), Icons.check_circle, const Color(0xFF10B981), cardBg, textColor),
              _kpiCard('Pending', pendingDuties.toString(), Icons.hourglass_empty, const Color(0xFFF59E0B), cardBg, textColor),
              _kpiCard('Rejected', rejectedDuties.toString(), Icons.cancel, const Color(0xFFEF4444), cardBg, textColor),
            ],
          ),
          const SizedBox(height: 20),

          // Center Compliance Summary
          Text('Center-Wise Compliance', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._buildCenterComplianceCards(cardBg, textColor),
        ],
      ),
    );
  }

  List<Widget> _buildCenterComplianceCards(Color cardBg, Color textColor) {
    final duties = ref.watch(globalDutyProvider);
    final centers = ref.watch(centerProvider);

    if (centers.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text('No centers configured', style: TextStyle(color: textColor.withValues(alpha: 0.5)))),
        ),
      ];
    }

    return centers.map((center) {
      final centerDuties = duties.where((d) => d.centerName == center.name).toList();
      final total = centerDuties.length;
      final accepted = centerDuties.where((d) => d.status == 'accepted').length;
      final reached = centerDuties.where((d) => d.isReached).length;
      final rate = total > 0 ? ((accepted / total) * 100).toStringAsFixed(0) : '0';

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_city, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(center.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$total duties • $reached clocked in', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: int.parse(rate) >= 80
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$rate%',
                style: TextStyle(
                  color: int.parse(rate) >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildAuditTrailTab({
    required Color textColor,
    required Color cardBg,
    required Color brandColor,
  }) {
    final notifications = ref.watch(notificationProvider);
    // Use notifications as audit trail events (they already contain all system actions)
    final auditEvents = notifications.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: brandColor.withValues(alpha: 0.05),
          child: Row(
            children: [
              Icon(Icons.history, color: brandColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${auditEvents.length} System Events Logged',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('LIVE', style: TextStyle(color: brandColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Event List
        Expanded(
          child: auditEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_note, size: 48, color: textColor.withValues(alpha: 0.2)),
                      const SizedBox(height: 8),
                      Text('No audit events yet', style: TextStyle(color: textColor.withValues(alpha: 0.4))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: auditEvents.length,
                  itemBuilder: (context, idx) {
                    final event = auditEvents[idx];
                    final typeColor = _getAuditEventColor(event.type);
                    final typeIcon = _getAuditEventIcon(event.type);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(typeIcon, color: typeColor, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMM, HH:mm').format(event.timestamp),
                                      style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.message,
                                  style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event.type.toUpperCase().replaceAll('_', ' '),
                                    style: TextStyle(color: typeColor, fontSize: 8.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRosterTab({
    required List<ExamDuty> duties,
    required List<Invigilator> invs,
    required Color textColor,
    required Color cardBg,
  }) {
    final sortedDuties = duties.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return sortedDuties.isEmpty
        ? Center(child: Text('No duty records', style: TextStyle(color: textColor.withValues(alpha: 0.4))))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedDuties.length,
            itemBuilder: (context, idx) {
              final duty = sortedDuties[idx];
              final inv = invs.firstWhere(
                (i) => i.id == duty.invigilatorId,
                orElse: () => Invigilator(id: '', name: 'Unassigned', resourceId: '-', mobile: '', mockDutyCount: 0),
              );

              final statusColor = duty.status == 'accepted'
                  ? const Color(0xFF10B981)
                  : duty.status == 'rejected'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            duty.examName,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            duty.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 13, color: textColor.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(inv.name, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 11)),
                        const SizedBox(width: 12),
                        Icon(Icons.badge_outlined, size: 13, color: textColor.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(inv.resourceId, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: textColor.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Text('${duty.date} • Shift ${duty.shift}', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11)),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on_outlined, size: 12, color: textColor.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(duty.centerName, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    if (duty.isReached) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.login, size: 10, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'Clocked In: ${duty.reachedTime} • Performance: ${duty.reachedPerformance}',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (duty.isStandbyReplacement) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 10, color: Color(0xFFF59E0B)),
                            SizedBox(width: 4),
                            Text('STANDBY REPLACEMENT', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
  }

  Widget _buildIncidentsTab({
    required List incidents,
    required Color textColor,
    required Color cardBg,
  }) {
    if (incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text('No incidents reported', style: TextStyle(color: textColor.withValues(alpha: 0.4))),
            const SizedBox(height: 4),
            Text('All clear ✅', style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: incidents.length,
      itemBuilder: (context, idx) {
        final incident = incidents[idx];
        final severityColor = incident.severity == 'critical'
            ? const Color(0xFFEF4444)
            : incident.severity == 'high'
                ? const Color(0xFFF59E0B)
                : const Color(0xFF6366F1);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: severityColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.report_problem, size: 16, color: severityColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      incident.description,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: incident.status == 'open'
                          ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                          : const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      incident.status.toUpperCase(),
                      style: TextStyle(
                        color: incident.status == 'open' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Severity: ${incident.severity.toUpperCase()} • ${incident.centerName} • ${incident.roomName}',
                style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 10),
              ),
              Text(
                'Reported by: ${incident.reportedByName} • ${DateFormat('dd MMM, HH:mm').format(incident.reportedAt)}',
                style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widgets
  Widget _miniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9)),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color, Color cardBg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 22)),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getAuditEventColor(String type) {
    switch (type) {
      case 'duty_assigned': return const Color(0xFF6366F1);
      case 'duty_accepted': return const Color(0xFF10B981);
      case 'duty_rejected': return const Color(0xFFEF4444);
      case 'duty_reassigned': return const Color(0xFFF59E0B);
      case 'duty_reminder': return const Color(0xFF0891B2);
      case 'geofence_alert': return const Color(0xFFDC2626);
      case 'standby_dispatch':
      case 'standby_dispatched': return const Color(0xFFEAB308);
      case 'standby_failed': return const Color(0xFFEF4444);
      default: return const Color(0xFF6366F1);
    }
  }

  IconData _getAuditEventIcon(String type) {
    switch (type) {
      case 'duty_assigned': return Icons.assignment_turned_in;
      case 'duty_accepted': return Icons.check_circle;
      case 'duty_rejected': return Icons.cancel;
      case 'duty_reassigned': return Icons.swap_horiz;
      case 'duty_reminder': return Icons.alarm;
      case 'geofence_alert': return Icons.location_off;
      case 'standby_dispatch':
      case 'standby_dispatched': return Icons.bolt;
      case 'standby_failed': return Icons.error_outline;
      default: return Icons.info_outline;
    }
  }
}

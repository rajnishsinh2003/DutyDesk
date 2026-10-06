import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../admin/providers/invigilator_provider.dart';
import '../../admin/providers/center_provider.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../../incidents/providers/incident_provider.dart';

/// Unified Role-Based Dashboard for specialized examination roles:
/// - COE (Controller of Examinations)
/// - Flying Squad / Vigilance Inspector
/// - Dean / Principal
class RoleBasedDashboardScreen extends ConsumerStatefulWidget {
  final String role; // 'coe', 'flying_squad', 'dean'

  const RoleBasedDashboardScreen({super.key, required this.role});

  @override
  ConsumerState<RoleBasedDashboardScreen> createState() => _RoleBasedDashboardScreenState();
}

class _RoleBasedDashboardScreenState extends ConsumerState<RoleBasedDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final duties = ref.watch(dutyProvider);
    final invs = ref.watch(invigilatorProvider);
    final centers = ref.watch(centerProvider);
    final incidents = ref.watch(incidentProvider);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayDuties = duties.where((d) => d.date == todayStr && d.status.toLowerCase() != 'rejected').toList();
    final todayReached = todayDuties.where((d) => d.isReached).length;
    final openIncidents = incidents.where((i) => i.status == 'open').length;

    final config = _getRoleConfig();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            Text(config.subtitle, style: TextStyle(fontSize: 11, color: subtitleColor)),
          ],
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: config.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: config.accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(config.icon, size: 14, color: config.accentColor),
                const SizedBox(width: 4),
                Text(config.badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: config.accentColor)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ROLE WELCOME BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [config.accentColor.withValues(alpha: 0.15), config.accentColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: config.accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: config.accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(config.icon, color: config.accentColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(config.welcomeMessage, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: config.accentColor)),
                          const SizedBox(height: 2),
                          Text(config.description, style: TextStyle(fontSize: 11.5, color: subtitleColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // UNIVERSAL KPI ROW
              Row(
                children: [
                  Expanded(child: _kpiCard('Today\'s Duties', '${todayDuties.length}', Icons.assignment_rounded, const Color(0xFF007A87), isDark)),
                  const SizedBox(width: 10),
                  Expanded(child: _kpiCard('Staff Present', '$todayReached', Icons.check_circle_rounded, const Color(0xFF059669), isDark)),
                  const SizedBox(width: 10),
                  Expanded(child: _kpiCard('Open Incidents', '$openIncidents', Icons.report_problem_rounded, openIncidents > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669), isDark)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _kpiCard('Total Staff', '${invs.length}', Icons.people_alt_rounded, const Color(0xFF6366F1), isDark)),
                  const SizedBox(width: 10),
                  Expanded(child: _kpiCard('Exam Centers', '${centers.length}', Icons.location_city_rounded, const Color(0xFFB45309), isDark)),
                  const SizedBox(width: 10),
                  Expanded(child: _kpiCard('Total Duties', '${duties.length}', Icons.bar_chart_rounded, const Color(0xFF0284C7), isDark)),
                ],
              ),
              const SizedBox(height: 24),

              // ROLE-SPECIFIC SECTIONS
              ..._buildRoleSpecificSections(
                todayDuties: todayDuties,
                invs: invs,
                incidents: incidents,
                config: config,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoleSpecificSections({
    required List<ExamDuty> todayDuties,
    required List<Invigilator> invs,
    required List<dynamic> incidents,
    required _RoleConfig config,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
  }) {
    switch (widget.role) {
      case 'coe':
        return _buildCOESections(todayDuties, invs, cardBg, borderColor, textColor, subtitleColor, isDark);
      case 'flying_squad':
        return _buildFlyingSquadSections(todayDuties, invs, incidents, cardBg, borderColor, textColor, subtitleColor, isDark);
      case 'dean':
        return _buildDeanSections(todayDuties, invs, cardBg, borderColor, textColor, subtitleColor, isDark);
      default:
        return [];
    }
  }

  // ---------------------------------------------------------------
  // COE SECTIONS
  // ---------------------------------------------------------------
  List<Widget> _buildCOESections(List<ExamDuty> todayDuties, List<Invigilator> invs, Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    final noShowDuties = todayDuties.where((d) => !d.isReached && d.status.toLowerCase() == 'accepted').toList();
    return [
      _sectionHeader('Executive Compliance Overview', Icons.gavel_rounded, const Color(0xFF7C3AED), textColor),
      const SizedBox(height: 10),
      _infoCard(
        'Staff Attendance Rate',
        todayDuties.isEmpty ? 'N/A' : '${((todayDuties.where((d) => d.isReached).length / todayDuties.length) * 100).toStringAsFixed(1)}%',
        'Staff arrival vs. assigned count for today\'s examination sessions.',
        Icons.trending_up_rounded,
        const Color(0xFF059669),
        cardBg, borderColor, textColor, subtitleColor, isDark,
      ),
      const SizedBox(height: 10),
      _infoCard(
        'No-Show Alerts',
        '${noShowDuties.length} staff pending',
        noShowDuties.isEmpty ? 'All assigned staff have checked in. Operations running smoothly.' : 'Accepted duties not yet clocked in. Standby promotion engine may activate.',
        Icons.warning_amber_rounded,
        noShowDuties.isEmpty ? const Color(0xFF059669) : const Color(0xFFDC2626),
        cardBg, borderColor, textColor, subtitleColor, isDark,
      ),
      const SizedBox(height: 10),
      _actionTile('View All Reports & Analytics', Icons.bar_chart_rounded, const Color(0xFF6366F1), () => context.push('/admin_dashboard/reports'), cardBg, borderColor, textColor),
      _actionTile('Question Paper Dispatch Tracker', Icons.markunread_mailbox_rounded, const Color(0xFF0D9488), () => context.push('/admin_dashboard/paper_dispatch'), cardBg, borderColor, textColor),
      _actionTile('Answer Sheet Reconciliation', Icons.inventory_2_rounded, const Color(0xFF10B981), () => context.push('/admin_dashboard/answer_sheets'), cardBg, borderColor, textColor),
      _actionTile('Audit Trail & Activity Log', Icons.history_rounded, const Color(0xFF7C3AED), () => context.push('/admin_dashboard/audit_trail'), cardBg, borderColor, textColor),
      const SizedBox(height: 24),
    ];
  }

  // ---------------------------------------------------------------
  // FLYING SQUAD SECTIONS
  // ---------------------------------------------------------------
  List<Widget> _buildFlyingSquadSections(List<ExamDuty> todayDuties, List<Invigilator> invs, List<dynamic> incidents, Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    return [
      _sectionHeader('Vigilance Inspection Checklist', Icons.verified_user_rounded, const Color(0xFFDC2626), textColor),
      const SizedBox(height: 10),
      _checklistCard([
        'Verify invigilator presence and face-match at each exam hall',
        'Inspect question paper seal integrity before scheduled unseal time',
        'Confirm CCTV recording is active in all rooms',
        'Check student ID verification at entry gates',
        'Inspect washroom areas for potential malpractice materials',
        'Verify mobile phone collection points are functioning',
        'Confirm jammer devices are active and covering exam halls',
        'Check seating arrangement matches official plan',
        'Inspect answer sheet bundle sealing process post-exam',
        'Document any irregularities with photographic evidence',
      ], cardBg, borderColor, textColor, subtitleColor, isDark),
      const SizedBox(height: 20),

      _sectionHeader('Quick Actions — Vigilance', Icons.flash_on_rounded, const Color(0xFFEF4444), textColor),
      const SizedBox(height: 10),
      _actionTile('File Incident Report', Icons.report_problem_rounded, const Color(0xFFDC2626), () => context.push('/admin_dashboard/incidents'), cardBg, borderColor, textColor),
      _actionTile('View Live Control Room', Icons.monitor_rounded, const Color(0xFF0891B2), () => context.push('/admin_dashboard/maintain_home'), cardBg, borderColor, textColor),
      _actionTile('Gate Pass QR Scanner', Icons.qr_code_scanner_rounded, const Color(0xFF0284C7), () => context.push('/admin_dashboard'), cardBg, borderColor, textColor),
      const SizedBox(height: 24),
    ];
  }

  // ---------------------------------------------------------------
  // DEAN SECTIONS
  // ---------------------------------------------------------------
  List<Widget> _buildDeanSections(List<ExamDuty> todayDuties, List<Invigilator> invs, Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    final acceptedPct = todayDuties.isEmpty ? 0.0 : todayDuties.where((d) => d.status.toLowerCase() == 'accepted' || d.isReached).length / todayDuties.length * 100;
    return [
      _sectionHeader('Institutional Overview', Icons.school_rounded, const Color(0xFF1E40AF), textColor),
      const SizedBox(height: 10),
      _infoCard(
        'Duty Acceptance Rate',
        '${acceptedPct.toStringAsFixed(1)}%',
        'Percentage of assigned staff who have accepted / arrived for today\'s duties.',
        Icons.pie_chart_rounded,
        const Color(0xFF059669),
        cardBg, borderColor, textColor, subtitleColor, isDark,
      ),
      const SizedBox(height: 10),
      _infoCard(
        'Examination Status',
        todayDuties.isEmpty ? 'No Exams Today' : '${todayDuties.length} Sessions Active',
        todayDuties.isEmpty ? 'No examination sessions are scheduled for today.' : 'Active examination sessions require ${todayDuties.length} invigilators across all centers.',
        Icons.event_note_rounded,
        todayDuties.isEmpty ? const Color(0xFF64748B) : const Color(0xFF007A87),
        cardBg, borderColor, textColor, subtitleColor, isDark,
      ),
      const SizedBox(height: 20),

      _sectionHeader('Executive Links', Icons.link_rounded, const Color(0xFF6366F1), textColor),
      const SizedBox(height: 10),
      _actionTile('Full Reports & Exports', Icons.bar_chart_rounded, const Color(0xFF6366F1), () => context.push('/admin_dashboard/reports'), cardBg, borderColor, textColor),
      _actionTile('Staff Directory', Icons.people_alt_rounded, const Color(0xFF0284C7), () => context.push('/admin_dashboard/manage_invigilators'), cardBg, borderColor, textColor),
      _actionTile('Incident Register', Icons.report_problem_rounded, const Color(0xFFDC2626), () => context.push('/admin_dashboard/incidents'), cardBg, borderColor, textColor),
      const SizedBox(height: 24),
    ];
  }

  // ---------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------
  Widget _sectionHeader(String title, IconData icon, Color color, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String metric, String desc, IconData icon, Color color, Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(metric, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 11.5, color: subtitleColor, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, Color color, VoidCallback onTap, Color cardBg, Color borderColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor))),
                Icon(Icons.chevron_right_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checklistCard(List<String> items, Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                  ),
                  child: Center(child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(entry.value, style: TextStyle(fontSize: 12.5, color: textColor, height: 1.3))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  _RoleConfig _getRoleConfig() {
    switch (widget.role) {
      case 'coe':
        return _RoleConfig(
          title: 'Controller of Examinations',
          subtitle: 'Executive compliance & oversight portal',
          badge: 'COE',
          icon: Icons.gavel_rounded,
          accentColor: const Color(0xFF7C3AED),
          welcomeMessage: 'Controller of Examinations Portal',
          description: 'Full compliance oversight, dispatch tracking, script reconciliation, and institutional reporting.',
        );
      case 'flying_squad':
        return _RoleConfig(
          title: 'Flying Squad Inspector',
          subtitle: 'Vigilance & surprise inspection module',
          badge: 'VIGILANCE',
          icon: Icons.verified_user_rounded,
          accentColor: const Color(0xFFDC2626),
          welcomeMessage: 'Vigilance Inspection Console',
          description: 'On-ground surprise inspection checklist, real-time incident filing, and malpractice detection tools.',
        );
      case 'dean':
        return _RoleConfig(
          title: 'Dean / Principal View',
          subtitle: 'Institutional executive summary',
          badge: 'DEAN',
          icon: Icons.school_rounded,
          accentColor: const Color(0xFF1E40AF),
          welcomeMessage: 'Dean / Principal Executive View',
          description: 'High-level institutional overview of examination operations, staff compliance, and incident status.',
        );
      default:
        return _RoleConfig(
          title: 'Dashboard',
          subtitle: 'Overview',
          badge: 'USER',
          icon: Icons.dashboard_rounded,
          accentColor: const Color(0xFF007A87),
          welcomeMessage: 'Welcome',
          description: 'General dashboard view.',
        );
    }
  }
}

class _RoleConfig {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accentColor;
  final String welcomeMessage;
  final String description;

  _RoleConfig({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.welcomeMessage,
    required this.description,
  });
}

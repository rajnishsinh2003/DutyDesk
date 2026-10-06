import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/audit_event_model.dart';
import '../providers/audit_trail_provider.dart';

class AuditTrailScreen extends ConsumerStatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  ConsumerState<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends ConsumerState<AuditTrailScreen> {
  String _searchQuery = '';
  String _categoryFilter = 'all';
  String _roleFilter = 'all';
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final allEvents = ref.watch(auditTrailProvider);

    // Apply filters
    List<AuditEvent> filtered = allEvents;
    if (_categoryFilter != 'all') {
      filtered = filtered.where((e) => e.category == _categoryFilter).toList();
    }
    if (_roleFilter != 'all') {
      filtered = filtered.where((e) => e.actorRole.toLowerCase() == _roleFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) =>
          e.action.toLowerCase().contains(q) ||
          e.actorName.toLowerCase().contains(q) ||
          (e.details ?? '').toLowerCase().contains(q) ||
          e.categoryEnum.displayName.toLowerCase().contains(q) ||
          (e.targetEntityType ?? '').toLowerCase().contains(q)).toList();
    }

    // Group by date
    final groupedByDate = <String, List<AuditEvent>>{};
    for (final event in filtered) {
      final dayKey = DateFormat('yyyy-MM-dd').format(event.timestamp);
      groupedByDate.putIfAbsent(dayKey, () => []).add(event);
    }
    final sortedDays = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audit Trail & Activity Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            Text('${filtered.length} events tracked', style: TextStyle(fontSize: 11, color: subtitleColor)),
          ],
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded, color: const Color(0xFF007A87)),
            tooltip: 'Toggle Filters',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search actions, actors, details...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF007A87), width: 1.5)),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // FILTER CHIPS (collapsible)
            if (_showFilters) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtitleColor)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All', _categoryFilter, (v) => setState(() => _categoryFilter = v)),
                          ...AuditCategory.values.map((c) =>
                            _buildFilterChip(c.name, c.displayName, _categoryFilter, (v) => setState(() => _categoryFilter = v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Actor Role', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtitleColor)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All Roles', _roleFilter, (v) => setState(() => _roleFilter = v)),
                          _buildFilterChip('admin', 'Admin', _roleFilter, (v) => setState(() => _roleFilter = v)),
                          _buildFilterChip('invigilator', 'Invigilator', _roleFilter, (v) => setState(() => _roleFilter = v)),
                          _buildFilterChip('finance', 'Finance', _roleFilter, (v) => setState(() => _roleFilter = v)),
                          _buildFilterChip('auditor', 'Auditor', _roleFilter, (v) => setState(() => _roleFilter = v)),
                          _buildFilterChip('system', 'System', _roleFilter, (v) => setState(() => _roleFilter = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ],

            // CATEGORY STATISTICS BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildStatPill('Total', '${allEvents.length}', const Color(0xFF6366F1), isDark),
                    _buildStatPill('Today', '${allEvents.where((e) => DateFormat('yyyy-MM-dd').format(e.timestamp) == DateFormat('yyyy-MM-dd').format(DateTime.now())).length}', const Color(0xFF059669), isDark),
                    _buildStatPill('Duties', '${allEvents.where((e) => e.category == 'dutyManagement').length}', const Color(0xFF0284C7), isDark),
                    _buildStatPill('Payroll', '${allEvents.where((e) => e.category == 'payroll').length}', const Color(0xFFD97706), isDark),
                    _buildStatPill('Incidents', '${allEvents.where((e) => e.category == 'incidentAction').length}', const Color(0xFFDC2626), isDark),
                    _buildStatPill('Auth', '${allEvents.where((e) => e.category == 'authentication').length}', const Color(0xFF7C3AED), isDark),
                  ],
                ),
              ),
            ),

            // TIMELINE LIST
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No audit events found', style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('System actions will appear here automatically', style: TextStyle(color: subtitleColor, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sortedDays.length,
                      itemBuilder: (context, dayIndex) {
                        final dayKey = sortedDays[dayIndex];
                        final dayEvents = groupedByDate[dayKey]!;
                        final isToday = dayKey == DateFormat('yyyy-MM-dd').format(DateTime.now());
                        final isYesterday = dayKey == DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
                        final dayLabel = isToday ? 'Today' : (isYesterday ? 'Yesterday' : DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(dayKey)));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DAY HEADER
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? const Color(0xFF007A87).withValues(alpha: 0.12)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      dayLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isToday ? const Color(0xFF007A87) : subtitleColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('(${dayEvents.length})', style: TextStyle(fontSize: 11, color: subtitleColor)),
                                  Expanded(child: Divider(indent: 10, color: borderColor)),
                                ],
                              ),
                            ),

                            // EVENT CARDS IN TIMELINE
                            ...dayEvents.map((event) => _buildEventCard(event, cardBg, borderColor, textColor, subtitleColor, isDark)),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(AuditEvent event, Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDark) {
    final cat = event.categoryEnum;
    final catColor = _getCategoryColor(cat);
    final timeStr = DateFormat('hh:mm a').format(event.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIMELINE SPINE
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: catColor.withValues(alpha: 0.4)),
                ),
                child: Icon(_getCategoryIcon(cat), size: 15, color: catColor),
              ),
              Container(width: 2, height: 24, color: borderColor),
            ],
          ),
          const SizedBox(width: 12),

          // CARD BODY
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ROW 1: Action + Time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.action,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(timeStr, style: TextStyle(fontSize: 10.5, color: subtitleColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ROW 2: Actor + Category badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _badge(event.actorName, const Color(0xFF007A87), isDark),
                      _badge(event.actorRole.toUpperCase(), _getRoleColor(event.actorRole), isDark),
                      _badge(cat.displayName, catColor, isDark),
                    ],
                  ),

                  // ROW 3: Details (if present)
                  if (event.details != null && event.details!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.details!,
                        style: TextStyle(fontSize: 11, color: subtitleColor, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  // ROW 4: Target entity
                  if (event.targetEntityType != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.link_rounded, size: 12, color: subtitleColor),
                        const SizedBox(width: 4),
                        Text(
                          '${event.targetEntityType} ${event.targetEntityId != null ? "(${event.targetEntityId!.length > 12 ? '${event.targetEntityId!.substring(0, 12)}...' : event.targetEntityId})" : ""}',
                          style: TextStyle(fontSize: 10.5, color: subtitleColor, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildFilterChip(String value, String label, String currentValue, void Function(String) onSelect) {
    final isSelected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF007A87) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String count, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Color _getCategoryColor(AuditCategory cat) {
    switch (cat) {
      case AuditCategory.dutyManagement:
        return const Color(0xFF047857);
      case AuditCategory.staffManagement:
        return const Color(0xFF0284C7);
      case AuditCategory.centerManagement:
        return const Color(0xFFB45309);
      case AuditCategory.payroll:
        return const Color(0xFFD97706);
      case AuditCategory.swapApproval:
        return const Color(0xFF6366F1);
      case AuditCategory.incidentAction:
        return const Color(0xFFDC2626);
      case AuditCategory.settingsChange:
        return const Color(0xFF007A87);
      case AuditCategory.bulkImport:
        return const Color(0xFF0284C7);
      case AuditCategory.standbyPromotion:
        return const Color(0xFFF59E0B);
      case AuditCategory.paperDispatch:
        return const Color(0xFF0D9488);
      case AuditCategory.answerSheets:
        return const Color(0xFF10B981);
      case AuditCategory.seatingPlan:
        return const Color(0xFF6366F1);
      case AuditCategory.authentication:
        return const Color(0xFF7C3AED);
      case AuditCategory.systemEvent:
        return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(AuditCategory cat) {
    switch (cat) {
      case AuditCategory.dutyManagement:
        return Icons.assignment_rounded;
      case AuditCategory.staffManagement:
        return Icons.people_alt_rounded;
      case AuditCategory.centerManagement:
        return Icons.location_city_rounded;
      case AuditCategory.payroll:
        return Icons.account_balance_wallet_rounded;
      case AuditCategory.swapApproval:
        return Icons.swap_horiz_rounded;
      case AuditCategory.incidentAction:
        return Icons.report_problem_rounded;
      case AuditCategory.settingsChange:
        return Icons.tune_rounded;
      case AuditCategory.bulkImport:
        return Icons.upload_file_rounded;
      case AuditCategory.standbyPromotion:
        return Icons.supervisor_account_rounded;
      case AuditCategory.paperDispatch:
        return Icons.markunread_mailbox_rounded;
      case AuditCategory.answerSheets:
        return Icons.inventory_2_rounded;
      case AuditCategory.seatingPlan:
        return Icons.grid_on_rounded;
      case AuditCategory.authentication:
        return Icons.lock_rounded;
      case AuditCategory.systemEvent:
        return Icons.info_outline_rounded;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF007A87);
      case 'invigilator':
        return const Color(0xFF047857);
      case 'finance':
        return const Color(0xFF059669);
      case 'auditor':
        return const Color(0xFFD97706);
      case 'system':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

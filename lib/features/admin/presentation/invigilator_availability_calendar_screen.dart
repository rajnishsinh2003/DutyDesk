import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../providers/invigilator_provider.dart';
import '../../invigilator/providers/duty_provider.dart';

class InvigilatorAvailabilityCalendarScreen extends ConsumerStatefulWidget {
  const InvigilatorAvailabilityCalendarScreen({super.key});

  @override
  ConsumerState<InvigilatorAvailabilityCalendarScreen> createState() =>
      _InvigilatorAvailabilityCalendarScreenState();
}

class _InvigilatorAvailabilityCalendarScreenState
    extends ConsumerState<InvigilatorAvailabilityCalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final invs = ref.watch(invigilatorProvider);
    final duties = ref.watch(globalDutyProvider);

    final friendlyDateStr = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);

    // Analyze status for each invigilator on _selectedDate
    final invStatuses = invs.map((inv) {
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Check if marked unavailable in their profile
      final isMarkedUnavailable = inv.unavailableDates.contains(dateKey);
      
      // Check if already assigned to a duty on this date
      final assignedDuties = duties.where((d) => 
        d.invigilatorId == inv.id && 
        d.date == dateKey && 
        d.status.toLowerCase() != 'rejected'
      ).toList();

      String statusKey;
      String statusText;
      String detail = '';
      Color color;
      IconData icon;

      if (!inv.isActive) {
        statusKey = 'blocked';
        statusText = s.blocked;
        detail = s.unavailable;
        color = Colors.grey;
        icon = Icons.block;
      } else if (isMarkedUnavailable) {
        statusKey = 'unavailable';
        statusText = s.unavailable;
        detail = s.unavailable;
        color = Colors.red;
        icon = Icons.event_busy;
      } else if (assignedDuties.isNotEmpty) {
        statusKey = 'busy';
        statusText = s.assignedDuty;
        final shifts = assignedDuties.map((d) => '${s.shift} ${d.shift}').join(', ');
        detail = '${assignedDuties.first.examName} ($shifts)';
        color = Colors.amber.shade800;
        icon = Icons.assignment_turned_in;
      } else {
        statusKey = 'available';
        statusText = s.available;
        detail = s.available;
        color = Colors.green;
        icon = Icons.check_circle;
      }

      return {
        'invigilator': inv,
        'statusKey': statusKey,
        'status': statusText,
        'detail': detail,
        'color': color,
        'icon': icon,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.availabilityCalendar),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. DATE SELECTOR BANNER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.date.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friendlyDateStr,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(s.chooseDate),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          
          // 2. QUICK STATS SUMMARY BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryBadge(s.available, invStatuses.where((st) => st['statusKey'] == 'available').length, Colors.green),
                _buildSummaryBadge(s.assignedDuty, invStatuses.where((st) => st['statusKey'] == 'busy').length, Colors.amber.shade800),
                _buildSummaryBadge(s.unavailable, invStatuses.where((st) => st['statusKey'] == 'unavailable').length, Colors.red),
                _buildSummaryBadge(s.blocked, invStatuses.where((st) => st['statusKey'] == 'blocked').length, Colors.grey),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. STAFF LIST WITH DETAILS
          Expanded(
            child: invStatuses.isEmpty
                ? Center(child: Text(s.noInvigilatorsFound))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: invStatuses.length,
                    itemBuilder: (context, index) {
                      final item = invStatuses[index];
                      final inv = item['invigilator'] as Invigilator;
                      final statusKey = item['statusKey'] as String;
                      final status = item['status'] as String;
                      final detail = item['detail'] as String;
                      final color = item['color'] as Color;
                      final icon = item['icon'] as IconData;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          title: Text(
                            inv.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              detail,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusKey == 'available' ? Colors.grey.shade600 : color,
                                fontWeight: statusKey == 'available' ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildSummaryBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

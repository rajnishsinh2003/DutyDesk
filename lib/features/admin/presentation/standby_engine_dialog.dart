import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/standby_promotion_service.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../providers/invigilator_provider.dart';

/// Standby Pool & Auto-Promotion Console Dialog
class StandbyEngineDialog extends ConsumerStatefulWidget {
  const StandbyEngineDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const StandbyEngineDialog(),
    );
  }

  @override
  ConsumerState<StandbyEngineDialog> createState() => _StandbyEngineDialogState();
}

class _StandbyEngineDialogState extends ConsumerState<StandbyEngineDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final engineState = ref.watch(standbyEngineProvider);
    final engineNotifier = ref.read(standbyEngineProvider.notifier);
    final invs = ref.watch(invigilatorProvider);
    final duties = ref.watch(globalDutyProvider);

    // Active duties that are potential no-shows (accepted, not reached)
    final pendingClockInDuties = duties.where((d) => d.status == 'accepted' && !d.isReached).toList();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.supervised_user_circle_rounded,
                      color: Color(0xFFF59E0B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Standby & Auto-Promotion',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Automated no-show replacement engine',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Engine Status Badge & Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: engineState.isMonitoring
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: engineState.isMonitoring
                            ? const Color(0xFF10B981)
                            : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: engineState.isMonitoring
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          engineState.isMonitoring ? 'LIVE' : 'OFF',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: engineState.isMonitoring
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: engineState.isMonitoring,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      if (val) {
                        engineNotifier.startMonitoring(graceMinutes: engineState.noShowGraceMinutes);
                      } else {
                        engineNotifier.stopMonitoring();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Metrics Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  _MetricItem(
                    label: 'Standby Pool',
                    value: invs.length.toString(),
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  _MetricItem(
                    label: 'Auto-Promotions',
                    value: engineState.totalAutoPromotions.toString(),
                    icon: Icons.auto_mode_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _MetricItem(
                    label: 'Grace Window',
                    value: '${engineState.noShowGraceMinutes}m',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFFF59E0B),
                  ),
                  _MetricItem(
                    label: 'At-Risk Duties',
                    value: pendingClockInDuties.length.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),

            // Grace Setting Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'No-Show Grace Period:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  ...[15, 30, 45, 60].map((mins) {
                    final selected = engineState.noShowGraceMinutes == mins;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          engineNotifier.setGracePeriod(mins);
                          if (engineState.isMonitoring) {
                            engineNotifier.startMonitoring(graceMinutes: mins);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF2563EB)
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${mins}m',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Promotion Log (${engineState.promotionLog.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Emergency Dispatch (${pendingClockInDuties.length})'),
                    ],
                  ),
                ),
              ],
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Promotion Log
                  _PromotionLogTab(
                    logs: engineState.promotionLog,
                    isDark: isDark,
                  ),

                  // TAB 2: Emergency Manual Promotion
                  _EmergencyDispatchTab(
                    duties: pendingClockInDuties,
                    invs: invs,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PromotionLogTab extends StatelessWidget {
  final List<StandbyPromotionEvent> logs;
  final bool isDark;

  const _PromotionLogTab({
    required this.logs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 48,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Auto-Promotions Yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'When staff fail to clock in after the grace period,\nthe engine will automatically dispatch standby replacements.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final timeFormat = DateFormat('dd MMM, hh:mm a');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final ev = logs[idx];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'REPLACED • ${ev.reason.name.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeFormat.format(ev.timestamp),
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original: ${ev.originalInvigilatorName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Standby: ${ev.promotedInvigilatorName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${ev.examName} • ${ev.centerName} • Shift ${ev.shift}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmergencyDispatchTab extends ConsumerWidget {
  final List<ExamDuty> duties;
  final List<Invigilator> invs;
  final bool isDark;

  const _EmergencyDispatchTab({
    required this.duties,
    required this.invs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (duties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
            const SizedBox(height: 12),
            const Text(
              'All Staff Clocked In',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'No active duties are currently un-clocked-in.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: duties.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final duty = duties[idx];
        final inv = invs.firstWhere(
          (i) => i.id == duty.invigilatorId,
          orElse: () => Invigilator(id: '', name: 'Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${duty.examName} • Shift ${duty.shift}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    Text(
                      'Center: ${duty.centerName} • Reporting: ${duty.reportingTime}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Dispatch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  HapticFeedback.heavyImpact();
                  await ref.read(standbyEngineProvider.notifier).promoteStandbyForDuty(
                    dutyId: duty.id,
                    reason: StandbyPromotionReason.emergencyVacancy,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚡ Emergency standby dispatched for ${inv.name}!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

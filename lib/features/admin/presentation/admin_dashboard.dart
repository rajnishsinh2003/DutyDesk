import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
import '../providers/invigilator_provider.dart';
import '../providers/center_provider.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../../invigilator/providers/swap_provider.dart';
import '../services/report_service.dart';
import 'duty_settings_dialog.dart';
import '../../../core/services/location_service.dart';
import '../../notifications/providers/notification_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isExporting = false;

  void _showExportModal(List<ExamDuty> duties, List<Invigilator> invs) {
    final s = S.of(context)!;
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
              s.exportingRecords(duties.length),
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
                try {
                  await ReportService.exportPdf(
                    duties: duties,
                    invigilators: invs,
                    filterDescription: _selectedDateRange == null
                        ? s.allAllocations
                        : '${s.date}: ${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.pdfError(e.toString())), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (context.mounted) setState(() => _isExporting = false);
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
                try {
                  await ReportService.exportExcel(
                    duties: duties,
                    invigilators: invs,
                    filterDescription: _selectedDateRange == null
                        ? s.allAllocations
                        : '${s.date}: ${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.excelError(e.toString())), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (context.mounted) setState(() => _isExporting = false);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showConflictResolverModal(String staffName, List<ExamDuty> conflictDuties) {
    final s = S.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.conflictDetected}: $staffName',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.conflictDetected,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...conflictDuties.map((d) {
              return Card(
                color: Colors.red.withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.redAccent, width: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.examName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('${d.centerName} • ${s.shift} ${d.shift} • ${d.date}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: s.delete,
                        onPressed: () {
                          ref.read(dutyProvider.notifier).deleteDuty(d.id);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showTodayArrivalDetailsModal(BuildContext context, List<ExamDuty> todayDuties, List<Invigilator> invs) {
    final s = S.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_searching_rounded, color: Color(0xFF007A87), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        s.todaysDuties,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A87).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(color: Color(0xFF007A87), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                s.geofenceVerification,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Divider(height: 20),
              Expanded(
                child: todayDuties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(s.noDutiesAssigned, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: todayDuties.length,
                        itemBuilder: (context, index) {
                          final duty = todayDuties[index];
                          final inv = invs.firstWhere(
                            (i) => i.id == duty.invigilatorId,
                            orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '-', mobile: '-', mockDutyCount: 0),
                          );

                          Color perfColor;
                          switch ((duty.reachedPerformance ?? '').toLowerCase()) {
                            case 'excellent': perfColor = const Color(0xFF047857); break;
                            case 'good': perfColor = const Color(0xFFB45309); break;
                            default: perfColor = const Color(0xFFB91C1C);
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 1,
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
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (duty.isReached)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: perfColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: perfColor, width: 0.8),
                                          ),
                                          child: Text(
                                            '✓ ${duty.reachedPerformance?.toUpperCase() ?? s.reached.toUpperCase()}',
                                            style: TextStyle(color: perfColor, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange, width: 0.8),
                                          ),
                                          child: Text(
                                            '⏳ ${s.pending.toUpperCase()}',
                                            style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${s.resourceId}: ${inv.resourceId} • ${s.mobile}: ${inv.mobile}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${s.exams}: ${duty.examName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      Text('${s.shift} ${duty.shift}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF007A87))),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('${s.center}: ${duty.centerName}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                  if (duty.isReached) ...[
                                    const Divider(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: perfColor.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time_filled, size: 14, color: perfColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${s.arrival}: ${duty.reachedTime ?? "-"}',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: perfColor),
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
                                                      Icon(Icons.map_outlined, size: 14, color: Color(0xFF007A87)),
                                                      SizedBox(width: 3),
                                                      Text('Map', style: TextStyle(color: Color(0xFF007A87), fontSize: 11, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (duty.reachedLocation != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'GPS: ${duty.reachedLocation}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
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
        ),
      ),
    );
  }

  void _showSettingsDropdown(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: [
        PopupMenuItem<String>(
          value: 'duty_settings',
          child: ListTile(
            leading: const Icon(Icons.tune_rounded, color: Color(0xFF007A87)),
            title: Text(s.dutySettings),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'language',
          child: ListTile(
            leading: const Icon(Icons.translate_rounded, color: Color(0xFF007A87)),
            title: Text(s.language),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(s.logout, style: const TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value == 'duty_settings' && context.mounted) {
        DutySettingsDialog.show(context);
      } else if (value == 'language' && context.mounted) {
        context.push('/settings/language');
      } else if (value == 'logout' && context.mounted) {
        _showLogoutDialog(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final invs = ref.watch(invigilatorProvider);
    final centers = ref.watch(centerProvider);
    final duties = ref.watch(globalDutyProvider);
    final swapRequests = ref.watch(swapProvider);

    final pendingSwaps = swapRequests.where((sw) => sw.status == 'pending').toList();

    // 1. Filter duties by Date Range if selected
    final filteredDuties = _selectedDateRange == null
        ? duties
        : duties.where((d) {
            try {
              final dt = DateTime.parse(d.date);
              return dt.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                  dt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
            } catch (_) {
              return true;
            }
          }).toList();

    final activeCount = filteredDuties.where((d) => d.status.toLowerCase() == 'accepted').length;
    final pendingCount = filteredDuties.where((d) => d.status.toLowerCase() == 'pending').length;

    // Today's Exam Duties & Arrival Statistics
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayDuties = duties.where((d) => d.date == todayStr && d.status.toLowerCase() != 'rejected').toList();
    final todayReached = todayDuties.where((d) => d.isReached).length;
    final todayNotReached = todayDuties.length - todayReached;
    final todayExcellent = todayDuties.where((d) => d.isReached && (d.reachedPerformance ?? '').toLowerCase() == 'excellent').length;
    final todayGood = todayDuties.where((d) => d.isReached && (d.reachedPerformance ?? '').toLowerCase() == 'good').length;
    final todayNeedsImp = todayDuties.where((d) => d.isReached && (d.reachedPerformance ?? '').toLowerCase() == 'needs improvement').length;

    // 2. Conflict Detector: Same INV assigned on same Date AND same Shift
    final conflictsMap = <String, List<ExamDuty>>{};
    for (final d in duties) {
      if (d.status.toLowerCase() != 'rejected') {
        final key = '${d.invigilatorId}_${d.date}_${d.shift}';
        if (!conflictsMap.containsKey(key)) {
          conflictsMap[key] = [];
        }
        conflictsMap[key]!.add(d);
      }
    }
    final activeConflicts = conflictsMap.entries.where((entry) => entry.value.length > 1).toList();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: screenBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER ROW (Greeting + Avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s.welcome,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '👋',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.adminDashboard,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // In-App Notification Center Icon with Live Badge
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF007A87), size: 26),
                            tooltip: s.notifications,
                            onPressed: () {
                              context.push('/notifications');
                            },
                          ),
                          Consumer(
                            builder: (context, refConsumer, _) {
                              final unreadCount = refConsumer.watch(unreadNotificationCountProvider);
                              if (unreadCount == 0) return const SizedBox.shrink();
                              return Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      _isExporting
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.download_rounded, color: Color(0xFF007A87), size: 26),
                              tooltip: s.exportStatement,
                              onPressed: () => _showExportModal(filteredDuties, invs),
                            ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _showSettingsDropdown(context, ref),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF007A87),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'AD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // GLOBAL SEARCH BAR
              GestureDetector(
                onTap: () => context.go('/admin_dashboard/global_search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: subtitleColor),
                      const SizedBox(width: 12),
                      Text(
                        '${s.search}...',
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SYSTEM OVERVIEW BANNER
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -40,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1B4965).withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -40,
                        bottom: -50,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF007A87).withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.statsAtGlance.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF8E9AAF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'DutyDesk\n${s.liveExamControlRoom}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildBannerStat(invs.length.toString(), s.invigilators),
                                _buildVerticalDivider(),
                                _buildBannerStat(activeCount.toString(), s.accepted),
                                _buildVerticalDivider(),
                                _buildBannerStat(centers.length.toString(), s.centers),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // DUTY CONFLICT DETECTOR PANEL
              if (activeConflicts.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '${s.conflictDetected} (${activeConflicts.length})',
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.conflictDetected,
                        style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeConflicts.length,
                        itemBuilder: (context, idx) {
                          final conflictList = activeConflicts[idx].value;
                          final invId = activeConflicts[idx].key.split('_')[0];
                          final inv = invs.firstWhere(
                            (i) => i.id == invId,
                            orElse: () => Invigilator(id: '', name: 'Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                                      Text(
                                        '${conflictList.first.date} • ${s.shift} ${conflictList.first.shift} (${conflictList.length} exams)',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  onPressed: () => _showConflictResolverModal(inv.name, conflictList),
                                  child: Text(s.overrideAction, style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // PENDING SWAP REQUESTS
              if (pendingSwaps.isNotEmpty) ...[
                Text(
                  '${s.swapRequests} (${pendingSwaps.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingSwaps.length,
                  itemBuilder: (context, index) {
                    final req = pendingSwaps[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22252A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s.swapRequests,
                                style: TextStyle(color: Colors.blue[400], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                req.date,
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              children: [
                                TextSpan(text: req.requestingInvigilatorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const TextSpan(text: ' -> '),
                                TextSpan(text: req.examName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                const TextSpan(text: ' -> '),
                                TextSpan(text: req.targetInvigilatorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onPressed: () => ref.read(swapProvider.notifier).rejectSwapRequest(req.id),
                                child: Text(s.reject, style: const TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onPressed: () {
                                  ref.read(swapProvider.notifier).approveSwapRequest(req.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.swapApproved), backgroundColor: Colors.green),
                                  );
                                },
                                child: Text(s.approve, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // STATS AT A GLANCE (WITH DATE RANGE FILTER)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.statsAtGlance,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDateRange = null),
                          child: Text(
                            '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)} (${s.clear})',
                            style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.date_range, color: Color(0xFF2563EB)),
                        tooltip: s.dateRange,
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: _selectedDateRange,
                          );
                          if (range != null) {
                            setState(() => _selectedDateRange = range);
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: () => context.go('/admin_dashboard/reports'),
                        child: Text(
                          s.reports,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TODAY'S EXAM DUTIES & ARRIVAL STATISTICS
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.25), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.alarm_on_rounded, color: Color(0xFF007A87), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              s.todaysDuties,
                              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A87).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(DateTime.now()),
                            style: const TextStyle(color: Color(0xFF007A87), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildArrivalStatBox(
                            s.assignedDuty,
                            '${todayDuties.length}',
                            const Color(0xFF1D4ED8),
                            const Color(0xFFEFF6FF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildArrivalStatBox(
                            s.reached,
                            '$todayReached',
                            const Color(0xFF047857),
                            const Color(0xFFECFDF5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildArrivalStatBox(
                            s.pending,
                            '$todayNotReached',
                            const Color(0xFFB45309),
                            const Color(0xFFFFFBEB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPerformancePill('${s.onTime}: $todayExcellent', const Color(0xFF047857), const Color(0xFFECFDF5)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildPerformancePill('${s.slightlyLate}: $todayGood', const Color(0xFFB45309), const Color(0xFFFFFBEB)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildPerformancePill('${s.late}: $todayNeedsImp', const Color(0xFFB91C1C), const Color(0xFFFEF2F2)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/admin_dashboard/control_room'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007A87),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007A87).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.desktop_windows, size: 16, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.liveExamControlRoom,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showTodayArrivalDetailsModal(context, todayDuties, invs),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007A87).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.location_searching, size: 18, color: Color(0xFF007A87)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2x2 Stats Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _StatCard(
                    title: s.invigilators,
                    count: invs.length.toString(),
                    icon: Icons.people_alt_rounded,
                    bgColor: const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFFBFDBFE),
                    tintColor: const Color(0xFF1D4ED8),
                    onTap: () => context.go('/admin_dashboard/manage_invigilators'),
                  ),
                  _StatCard(
                    title: s.accepted,
                    count: activeCount.toString(),
                    icon: Icons.checklist_rtl_rounded,
                    bgColor: const Color(0xFFECFDF5),
                    borderColor: const Color(0xFFA7F3D0),
                    tintColor: const Color(0xFF047857),
                    onTap: () => context.go('/admin_dashboard/reports?filter=accepted'),
                  ),
                  _StatCard(
                    title: s.pending,
                    count: pendingCount.toString(),
                    icon: Icons.hourglass_empty_rounded,
                    bgColor: const Color(0xFFFFFBEB),
                    borderColor: const Color(0xFFFDE68A),
                    tintColor: const Color(0xFFB45309),
                    onTap: () => context.go('/admin_dashboard/reports?filter=pending'),
                  ),
                  _StatCard(
                    title: s.centers,
                    count: centers.length.toString(),
                    icon: Icons.business_rounded,
                    bgColor: const Color(0xFFF5F3FF),
                    borderColor: const Color(0xFFDDD6FE),
                    tintColor: const Color(0xFF6D28D9),
                    onTap: () => context.go('/admin_dashboard/manage_centers'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // QUICK ACTIONS
              Text(
                s.quickActions,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _ActionCard(
                    title: s.liveExamControlRoom,
                    subtitle: s.liveMonitoring,
                    icon: Icons.desktop_windows,
                    iconColor: const Color(0xFF007A87),
                    onTap: () => context.push('/admin_dashboard/control_room'),
                  ),
                  _ActionCard(
                    title: s.payrollSalary,
                    subtitle: s.remuneration,
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF059669),
                    onTap: () => context.push('/admin_dashboard/payroll'),
                  ),
                  _ActionCard(
                    title: s.invigilatorDirectory,
                    subtitle: s.invigilators,
                    icon: Icons.people_outline_rounded,
                    iconColor: const Color(0xFF1D4ED8),
                    onTap: () => context.go('/admin_dashboard/manage_invigilators'),
                  ),
                  _ActionCard(
                    title: s.assignDuty,
                    subtitle: s.shift,
                    icon: Icons.assignment_rounded,
                    iconColor: const Color(0xFF047857),
                    onTap: () => context.go('/admin_dashboard/allocate_duty'),
                  ),
                  _ActionCard(
                    title: s.dutySettings,
                    subtitle: s.settings,
                    icon: Icons.tune_rounded,
                    iconColor: const Color(0xFF007A87),
                    onTap: () => DutySettingsDialog.show(context),
                  ),
                  _ActionCard(
                    title: s.language,
                    subtitle: 'English / हिन्दी / ગુજરાતી',
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF0284C7),
                    onTap: () => context.push('/settings/language'),
                  ),
                  _ActionCard(
                    title: s.centers,
                    subtitle: s.centers,
                    icon: Icons.location_city_rounded,
                    iconColor: const Color(0xFFB45309),
                    onTap: () => context.go('/admin_dashboard/manage_centers'),
                  ),
                  _ActionCard(
                    title: s.reports,
                    subtitle: s.exportStatement,
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF6D28D9),
                    onTap: () => context.go('/admin_dashboard/reports'),
                  ),
                  _ActionCard(
                    title: s.maintainData,
                    subtitle: s.securityGuardRecords,
                    icon: Icons.edit_document,
                    iconColor: const Color(0xFFEAB308),
                    onTap: () => context.go('/admin_dashboard/maintain_data'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // RECENT ACTIVITY
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.dutyAllocations,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/admin_dashboard/reports'),
                    child: Text(
                      s.reports,
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (duties.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      s.noDutiesAssigned,
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ),
                )
              else ...[
                for (final duty in duties.take(4)) ...[
                  Builder(builder: (context) {
                    final matchedInv = invs.firstWhere(
                      (i) => i.id == duty.invigilatorId,
                      orElse: () => Invigilator(id: '', name: 'Staff', resourceId: '', mobile: '', mockDutyCount: 0),
                    );
                    final isReached = duty.isReached;
                    final isAccepted = duty.status.toLowerCase() == 'accepted';
                    final isRejected = duty.status.toLowerCase() == 'rejected';

                    final badgeText = isReached
                        ? s.reached.toUpperCase()
                        : (isAccepted ? s.accepted.toUpperCase() : (isRejected ? s.rejected.toUpperCase() : s.pending.toUpperCase()));
                    final badgeColor = isReached
                        ? const Color(0xFF0D9488)
                        : (isAccepted ? const Color(0xFF047857) : (isRejected ? Colors.red : const Color(0xFFB45309)));
                    final badgeBg = isReached
                        ? const Color(0xFFCCFBF1)
                        : (isAccepted ? const Color(0xFFECFDF5) : (isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _ActivityItem(
                        title: '${duty.examName} — ${matchedInv.name}',
                        timestamp: '${duty.date} • ${s.shift} ${duty.shift} • ${duty.centerName}',
                        icon: isReached ? Icons.location_pin : (isAccepted ? Icons.check_circle_rounded : Icons.assignment_turned_in_rounded),
                        iconColor: badgeColor,
                        badgeText: badgeText,
                        badgeColor: badgeColor,
                        badgeBgColor: badgeBg,
                      ),
                    );
                  }),
                ],
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, s.home, Icons.home_rounded, true, () {}),
            _buildNavItem(context, s.invigilators, Icons.people_outline_rounded, false, () {
              context.go('/admin_dashboard/manage_invigilators');
            }),
            _buildNavItem(context, s.dutyAllocation, Icons.assignment_outlined, false, () {
              context.go('/admin_dashboard/allocate_duty');
            }),
            Stack(
              alignment: Alignment.center,
              children: [
                _buildNavItem(context, s.reports, Icons.analytics_outlined, false, () {
                  context.go('/admin_dashboard/reports');
                }),
                if (pendingSwaps.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 14,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '${pendingSwaps.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            _buildNavItem(context, s.maintainData, Icons.admin_panel_settings_outlined, false, () {
              context.go('/admin_dashboard/maintain_data');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalStatBox(String label, String count, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancePill(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 0.8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBannerStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E9AAF),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.logout),
        content: Text(s.confirmLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: Text(s.logout),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color tintColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.tintColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: tintColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tintColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    color: tintColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: tintColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String timestamp;
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBgColor;

  const _ActivityItem({
    required this.title,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

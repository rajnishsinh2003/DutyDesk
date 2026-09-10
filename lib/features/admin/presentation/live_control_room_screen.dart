import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../../invigilator/providers/duty_provider.dart';
import '../providers/center_provider.dart';
import '../providers/invigilator_provider.dart';
import '../providers/duty_settings_provider.dart';
import '../../../core/services/location_service.dart';

class LiveControlRoomScreen extends ConsumerStatefulWidget {
  const LiveControlRoomScreen({super.key});

  @override
  ConsumerState<LiveControlRoomScreen> createState() => _LiveControlRoomScreenState();
}

class _LiveControlRoomScreenState extends ConsumerState<LiveControlRoomScreen> {
  String _selectedStatusFilter = 'all'; // 'all', 'reached', 'pending', 'late', 'absent', 'outside_geofence'
  String? _selectedCenterFilter;
  String? _selectedShiftFilter;
  String _searchQuery = '';
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid phone number available for this staff'), backgroundColor: Colors.orange),
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

  void _showReassignModal(ExamDuty duty, List<Invigilator> activeInvs) {
    final s = S.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.emergencyReplacement,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
            ),
            const SizedBox(height: 8),
            Text(
              '${duty.examName} • ${duty.centerName}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: activeInvs.length,
                itemBuilder: (context, index) {
                  final inv = activeInvs[index];
                  if (inv.id == duty.invigilatorId) return const SizedBox.shrink();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${s.resourceId}: ${inv.resourceId} • ${inv.mobile}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A87), foregroundColor: Colors.white),
                        onPressed: () async {
                          await ref.read(dutyProvider.notifier).reassignDuty(duty.id, inv.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${s.dutySwapped} -> ${inv.name}!'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        child: Text(s.assign),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final globalDuties = ref.watch(globalDutyProvider);
    final invs = ref.watch(invigilatorProvider);
    final centers = ref.watch(centerProvider);
    final dutySettings = ref.watch(dutySettingsProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(_now);

    // Filter duties for TODAY only
    final todayDuties = globalDuties.where((d) => d.date == todayStr).toList();

    // Compute live metrics
    final totalDutiesCount = todayDuties.length;
    final reachedCount = todayDuties.where((d) => d.isReached).length;
    final pendingCount = todayDuties.where((d) => !d.isReached && d.status.toLowerCase() != 'rejected').length;
    final lateCount = todayDuties.where((d) => d.isReached && (d.reachedPerformance == 'Needs Improvement' || d.reachedPerformance == 'Good')).length;
    final absentCount = todayDuties.where((d) => d.status.toLowerCase() == 'rejected' || (!d.isReached && _isDutyPastReportingTime(d.goodUntil))).length;

    // Filter duties based on UI filters
    final filteredDuties = todayDuties.where((d) {
      if (_selectedCenterFilter != null && _selectedCenterFilter!.isNotEmpty && d.centerName != _selectedCenterFilter) {
        return false;
      }
      if (_selectedShiftFilter != null && _selectedShiftFilter!.isNotEmpty && d.shift != _selectedShiftFilter) {
        return false;
      }

      if (_selectedStatusFilter == 'reached' && !d.isReached) return false;
      if (_selectedStatusFilter == 'pending' && (d.isReached || d.status.toLowerCase() == 'rejected')) return false;
      if (_selectedStatusFilter == 'late' && (!d.isReached || d.reachedPerformance == 'Excellent')) return false;
      if (_selectedStatusFilter == 'absent' && !(d.status.toLowerCase() == 'rejected' || (!d.isReached && _isDutyPastReportingTime(d.goodUntil)))) return false;
      if (_selectedStatusFilter == 'outside_geofence' && !(d.isReached && (d.isGeofenceVerified == false || d.geofenceStatus == 'outside' || d.geofenceStatus == 'manual_requested'))) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final staff = invs.firstWhere((i) => i.id == d.invigilatorId, orElse: () => Invigilator(id: '', name: '', resourceId: '', mobile: '', mockDutyCount: 0));
        final match = staff.name.toLowerCase().contains(q) ||
            staff.mobile.toLowerCase().contains(q) ||
            staff.resourceId.toLowerCase().contains(q) ||
            d.centerName.toLowerCase().contains(q) ||
            d.examName.toLowerCase().contains(q);
        if (!match) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.liveExamControlRoom, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.refresh,
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. LIVE TIME & STATUS HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007A87), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007A87).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.liveMonitoring.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(_now),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      DateFormat('hh:mm:ss a').format(_now),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. SUMMARY METRICS CARDS (5 Metrics)
            Row(
              children: [
                Expanded(child: _buildMetricCard(s.todaysDuties, '$totalDutiesCount', const Color(0xFF007A87), Icons.assignment)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard(s.reachedCount, '$reachedCount', Colors.green.shade700, Icons.check_circle_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard(s.pendingCount, '$pendingCount', Colors.orange.shade700, Icons.pending_actions)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMetricCard(s.lateCount, '$lateCount', Colors.deepOrange, Icons.alarm_off)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard(s.absentCount, '$absentCount', Colors.red.shade700, Icons.error_outline)),
              ],
            ),
            const SizedBox(height: 20),

            // 3. CENTER-WISE LIVE STATUS (Health Status Bars)
            Text(
              s.centerHealth.toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007A87), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            if (centers.isEmpty)
              Text(s.noCentersFound, style: const TextStyle(color: Colors.grey, fontSize: 12))
            else
              _buildCenterHealthSection(centers, todayDuties, s),
            const SizedBox(height: 20),

            // 4. SEARCH & FILTER CONTROLS
            Text(
              s.quickActions.toUpperCase(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007A87), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: '${s.search}...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF007A87), size: 20),
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
            const SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('${s.all} (${todayDuties.length})', 'all'),
                  _buildFilterChip('${s.reachedCount} ($reachedCount)', 'reached'),
                  _buildFilterChip('${s.pendingCount} ($pendingCount)', 'pending'),
                  _buildFilterChip('${s.lateCount} ($lateCount)', 'late'),
                  _buildFilterChip('${s.absentCount} ($absentCount)', 'absent'),
                  _buildFilterChip(s.outsideGeofenceFilter, 'outside_geofence'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. LIVE DUTY CARDS LIST
            if (filteredDuties.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(s.noResultsFound, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDuties.length,
                itemBuilder: (context, i) {
                  final duty = filteredDuties[i];
                  final staff = invs.firstWhere(
                    (item) => item.id == duty.invigilatorId,
                    orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
                  );
                  final activeInvs = invs.where((item) => item.isActive).toList();

                  return _buildLiveDutyCard(duty, staff, activeInvs, s, dutySettings);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Uses goodUntil as the final threshold — if current time is past goodUntil, duty is considered absent.
  bool _isDutyPastReportingTime(String goodUntil) {
    try {
      final now = DateTime.now();
      final format = DateFormat('hh:mm a');
      final goodDateTime = format.parse(goodUntil);
      final currentMinutes = now.hour * 60 + now.minute;
      final goodMinutes = goodDateTime.hour * 60 + goodDateTime.minute;
      return currentMinutes > goodMinutes;
    } catch (_) {
      return false;
    }
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterHealthSection(List<ExamCenter> centers, List<ExamDuty> todayDuties, S s) {
    return Column(
      children: centers.map((center) {
        final centerDuties = todayDuties.where((d) => d.centerName.toLowerCase() == center.name.toLowerCase()).toList();
        if (centerDuties.isEmpty) return const SizedBox.shrink();

        final centerTotal = centerDuties.length;
        final centerReached = centerDuties.where((d) => d.isReached).length;
        final percentage = centerTotal > 0 ? (centerReached / centerTotal) : 0.0;

        Color healthColor = Colors.green;
        String statusEmoji = '🟢';
        if (percentage < 0.7) {
          healthColor = Colors.red;
          statusEmoji = '🔴';
        } else if (percentage < 1.0) {
          healthColor = Colors.orange;
          statusEmoji = '🟡';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: healthColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      center.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        s.staffReachedCount(centerReached, centerTotal),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: healthColor),
                      ),
                      const SizedBox(width: 6),
                      Text(statusEmoji, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: const Color(0xFF007A87),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        onSelected: (selected) {
          if (selected) setState(() => _selectedStatusFilter = value);
        },
      ),
    );
  }

  Widget _buildLiveDutyCard(ExamDuty duty, Invigilator staff, List<Invigilator> activeInvs, S s, DutySettings dutySettings) {
    Color cardBorder = Colors.grey.shade300;
    Widget statusBadge;

    if (duty.isReached) {
      cardBorder = Colors.green.shade400;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade400, width: 0.8),
        ),
        child: Text(
          '${s.reached.toUpperCase()} • ${duty.reachedTime ?? "-"}',
          style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 10.5),
        ),
      );
    } else if (duty.status.toLowerCase() == 'rejected') {
      cardBorder = Colors.red.shade400;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade400, width: 0.8),
        ),
        child: Text('${s.rejected.toUpperCase()} / ${s.replacement.toUpperCase()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10.5)),
      );
    } else {
      cardBorder = Colors.orange.shade300;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade400, width: 0.8),
        ),
        child: Text(s.pending.toUpperCase(), style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 10.5)),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Staff Name + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF007A87).withValues(alpha: 0.1),
                        child: Text(
                          staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF007A87)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${s.resourceId}: ${staff.resourceId} • ${s.shift} ${duty.shift}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                statusBadge,
              ],
            ),
            const Divider(height: 18),

            // Exam & Center Info
            Row(
              children: [
                const Icon(Icons.book, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text('${duty.examName} • ${duty.centerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${s.reportingTime}: ${duty.reportingTime}  ★${duty.excellentUntil}  👍${duty.goodUntil}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                if (duty.reachedPerformance != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: duty.reachedPerformance == 'Excellent' ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      duty.reachedPerformance!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: duty.reachedPerformance == 'Excellent' ? Colors.green.shade800 : Colors.deepOrange,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Geofence & Location Row (if reached)
            if (duty.isReached) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      duty.isGeofenceVerified == true ? Icons.radar : Icons.warning_amber_rounded,
                      size: 16,
                      color: duty.isGeofenceVerified == true ? Colors.teal : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        duty.distanceFromCenter != null
                            ? (duty.isGeofenceVerified == true
                                ? '${s.geofenceVerified} (${s.distanceMeters(duty.distanceFromCenter! < 1000 ? duty.distanceFromCenter!.toStringAsFixed(0) : (duty.distanceFromCenter! / 1000).toStringAsFixed(1))})'
                                : '${s.outsideGeofence} (${(duty.distanceFromCenter! / 1000).toStringAsFixed(1)}km)')
                            : (duty.reachedLocation ?? s.arrivalRecorded),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: duty.isGeofenceVerified == true ? Colors.teal.shade800 : Colors.deepOrange,
                        ),
                      ),
                    ),
                    if (duty.resolvedMapsUrl != null)
                      InkWell(
                        onTap: () => LocationService.openMapLocation(
                          duty.resolvedMapsUrl!,
                          latitude: duty.reachedLatitude,
                          longitude: duty.reachedLongitude,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.map, size: 18, color: Color(0xFF007A87)),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Action Buttons (Call Staff, Reassign Replacement)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (staff.mobile.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phone, size: 14, color: Colors.green),
                    label: Text(s.callStaff, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Colors.green, width: 0.8),
                    ),
                    onPressed: () => _makePhoneCall(staff.mobile),
                  ),
                if (dutySettings.allowDutySwap && (!duty.isReached || duty.status.toLowerCase() == 'rejected')) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.swap_horiz, size: 14),
                    label: Text(s.reassign, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showReassignModal(duty, activeInvs),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

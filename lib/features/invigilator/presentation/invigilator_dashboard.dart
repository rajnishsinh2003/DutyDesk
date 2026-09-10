import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
import '../providers/duty_provider.dart';
import '../../admin/providers/invigilator_provider.dart';
import '../../admin/providers/duty_settings_provider.dart';
import '../providers/swap_provider.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/services/location_service.dart';

import '../../admin/providers/center_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../../core/services/offline_sync_service.dart';

class InvigilatorDashboardScreen extends ConsumerStatefulWidget {
  const InvigilatorDashboardScreen({super.key});

  @override
  ConsumerState<InvigilatorDashboardScreen> createState() => _InvigilatorDashboardScreenState();
}

class _InvigilatorDashboardScreenState extends ConsumerState<InvigilatorDashboardScreen> {
  int _currentTab = 0;
  DateTime _calendarMonth = DateTime.now();
  LocationStatusResult? _locationStatus;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authProvider);
      if (auth.userId == null) {
        ref.read(authProvider.notifier).restoreSession();
      }
      // Auto-sync any offline arrivals when dashboard opens
      final synced = await OfflineSyncService.syncPendingArrivals();
      if (synced > 0 && mounted) {
        final s = S.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s != null ? s.arrivalSyncedSuccessfully : '✓ Synced $synced offline arrival(s) to server successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _checkLocationStatus() async {
    final status = await LocationService.checkLocationStatus();
    if (mounted) {
      setState(() => _locationStatus = status);
    }
  }

  Future<void> _showLocationMandatoryDialog(BuildContext context, LocationResult locRes) async {
    final isServiceDisabled = locRes.errorMessage?.contains('disabled') ?? false;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Location is Mandatory',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DutyDesk requires active GPS location verification to mark duty attendance. Arrival cannot be recorded without location.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade300, width: 0.8),
              ),
              child: Text(
                locRes.errorMessage ?? 'Please enable GPS and grant high-accuracy location permission to record your arrival.',
                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: Icon(isServiceDisabled ? Icons.gps_fixed : Icons.settings, size: 18),
            label: Text(isServiceDisabled ? 'Turn On GPS' : 'Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007A87),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isServiceDisabled) {
                await LocationService.openLocationSettings();
              } else {
                await LocationService.openAppSettings();
              }
              _checkLocationStatus();
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _showOutsideGeofenceDialog({
    required BuildContext context,
    required String centerName,
    required GeofenceResult geofence,
  }) {
    final s = S.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.radar, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.outsideCenter,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.outsideGeofenceWarning} ($centerName).',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${s.distanceFromCenter}:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(geofence.formattedDistance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${s.allowedArrivalRadius}:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${geofence.allowedRadiusMeters} m', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.outsideGeofenceWarning,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Try again
            child: Text(s.tryAgain),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true), // Request manual verification
            child: Text(s.requestManualVerification, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReachedResultModal(BuildContext context, DutyArrivalResult result) {
    final s = S.of(context)!;
    Color themeColor;
    IconData statusIcon;

    String perfLabel = s.onTime;
    String perfMessage = s.youReachedOnTime;
    switch (result.performance.toLowerCase()) {
      case 'excellent':
        themeColor = const Color(0xFF15803D);
        statusIcon = Icons.stars_rounded;
        perfLabel = s.onTime;
        perfMessage = s.youReachedOnTime;
        break;
      case 'good':
        themeColor = const Color(0xFFB45309);
        statusIcon = Icons.alarm_on_rounded;
        perfLabel = s.slightlyLate;
        perfMessage = s.youReachedSlightlyLate;
        break;
      case 'needs improvement':
      default:
        themeColor = const Color(0xFFB91C1C);
        statusIcon = Icons.warning_amber_rounded;
        perfLabel = s.late;
        perfMessage = s.reachInProperTime;
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: themeColor, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              perfLabel,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              perfMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${s.date}:', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(result.reachedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${s.arrivalTime}:', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(result.reachedTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (result.distanceFromCenter != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${s.distanceFromCenter}:', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        Text(
                          result.distanceFromCenter! < 1000
                              ? s.distanceMeters(result.distanceFromCenter!.toStringAsFixed(0))
                              : '${(result.distanceFromCenter! / 1000).toStringAsFixed(2)} km',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: result.isGeofenceVerified == true ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (result.isOfflineSaved) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.waitingForInternet,
                              style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (result.locationString != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.gps}:', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.locationString!,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF007A87)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final duties = ref.watch(dutyProvider);
    final auth = ref.watch(authProvider);
    final invs = ref.watch(invigilatorProvider);
    final dutySettings = ref.watch(dutySettingsProvider);
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);

    final matchingInvs = invs.where((i) => i.id == auth.userId).toList();
    final currentInv = matchingInvs.isNotEmpty
        ? matchingInvs.first
        : Invigilator(
            id: auth.userId ?? '',
            name: (auth.userName != null && auth.userName!.isNotEmpty) ? auth.userName! : 'Invigilator',
            resourceId: '-',
            mobile: '',
            mockDutyCount: 0,
            isActive: true,
          );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;

    if (auth.userId == null && invs.isEmpty) {
      return Scaffold(
        backgroundColor: screenBgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF007A87)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: screenBgColor,
      appBar: AppBar(
        title: Text(_getTabTitle(s), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // In-App Notification Center Icon with Live Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: s.notifications,
                onPressed: () {
                  context.push('/notifications');
                },
              ),
              if (unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadNotifications',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.translate_rounded),
            tooltip: s.language,
            onPressed: () => context.push('/settings/language'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: s.logout,
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: _buildTabContent(currentInv, duties, invs, dutySettings, s),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(0, s.myDuties, Icons.assignment_outlined, Icons.assignment),
            _buildBottomNavItem(1, s.calendar, Icons.calendar_month_outlined, Icons.calendar_month),
            _buildBottomNavItem(2, s.pastDuties, Icons.history_outlined, Icons.history),
            _buildBottomNavItem(3, s.myProfile, Icons.person_outline_rounded, Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  String _getTabTitle(S s) {
    switch (_currentTab) {
      case 0: return s.myDuties;
      case 1: return s.calendar;
      case 2: return s.pastDuties;
      case 3: return s.myProfile;
      default: return 'DutyDesk';
    }
  }

  Widget _buildBottomNavItem(int index, String label, IconData outlineIcon, IconData filledIcon) {
    final isActive = _currentTab == index;
    final activeColor = const Color(0xFF007A87);
    final inactiveColor = const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? filledIcon : outlineIcon,
            size: 24,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Invigilator inv, List<ExamDuty> duties, List<Invigilator> allInvs, DutySettings dutySettings, S s) {
    switch (_currentTab) {
      case 0: return _buildDutiesTab(duties, allInvs, inv, dutySettings, s);
      case 1: return _buildCalendarTab(duties, inv, s);
      case 2: return _buildHistoryTab(duties, inv, s);
      case 3: return _buildProfileTab(inv, duties, s);
      default: return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. TAB: DUTIES (ACTIVE / PENDING / REACHED TRACKING)
  // ---------------------------------------------------------------------------
  Widget _buildDutiesTab(List<ExamDuty> duties, List<Invigilator> allInvs, Invigilator currentInv, DutySettings dutySettings, S s) {
    final activeDuties = duties.where((d) => d.status.toLowerCase() != 'rejected').toList();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Calculate total amount
    int totalDutyAmount = 0;
    for (final d in activeDuties) {
      totalDutyAmount += d.parsedPaymentAmount;
    }

    // Filter today's duty
    final todaysDutyList = activeDuties.where((d) => d.date == todayStr).toList();
    final otherUpcomingDuties = activeDuties.where((d) => d.date != todayStr).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SUMMARY HERO CARD (Total Duties & Total Amount)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007A87), Color(0xFF005B66)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007A87).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.welcome}, ${currentInv.name}', // COMPLETE STAFF NAME
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${s.resourceId}: ${currentInv.resourceId}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(s.staff.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.totalDuties, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('${activeDuties.length}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.totalRemuneration, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('₹$totalDutyAmount', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // LOCATION STATUS MANDATORY BANNER (If location/GPS is not active)
          if (_locationStatus != null && !_locationStatus!.isReady) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade400, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded, color: Colors.amber, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Access Required',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active GPS location is mandatory to record duty attendance. Tap to enable.',
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await LocationService.requestLocationAccess();
                      _checkLocationStatus();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.amber.shade200,
                      foregroundColor: Colors.amber.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('ENABLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. TODAY'S DUTY SECTION (With REACHED Button & Arrival Evaluation)
          if (todaysDutyList.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.today, color: Color(0xFF007A87), size: 20),
                const SizedBox(width: 8),
                Text(
                  s.todaysDuties,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...todaysDutyList.map((d) => _buildTodayDutyCard(d, allInvs, dutySettings, s)),
            const SizedBox(height: 24),
          ],

          // 3. UPCOMING / ALL ASSIGNED DUTIES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                todaysDutyList.isNotEmpty ? s.upcomingDuties : s.assignedDuty,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${activeDuties.length} ${s.dutyDetails}',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (activeDuties.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(s.noDutiesAssigned, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            ...otherUpcomingDuties.map((d) => _buildStandardDutyCard(d, allInvs, dutySettings, s)),
        ],
      ),
    );
  }

  Widget _buildTodayDutyCard(ExamDuty duty, List<Invigilator> allInvs, DutySettings dutySettings, S s) {
    final isReached = duty.isReached;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF007A87), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    duty.examName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusBadge(duty.status, s),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, '${s.date}: ${duty.date} (${s.today})'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.location_on_outlined, '${s.center}: ${duty.centerName}'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.access_time, '${s.reportingTime}: ${duty.reportingTime}'),
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 2),
                Icon(Icons.star_rounded, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text('Excellent Until: ${duty.excellentUntil}', style: TextStyle(fontSize: 13, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Icon(Icons.thumb_up_alt_rounded, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text('Good Until: ${duty.goodUntil}', style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${s.shift} ${duty.shift}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${s.remuneration}: ${duty.payment}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF007A87))),
              ],
            ),
            if (dutySettings.allowRole) ...[
              const SizedBox(height: 6),
              Text('${s.invigilator}: ${duty.role.toUpperCase()}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
            if (dutySettings.allowLunch) ...[
              const SizedBox(height: 6),
              Text('${s.lunchProvision}: ${duty.lunch == "Yes" ? s.yes : s.no}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 18),

            // REACHED BUTTON OR REACHED STATUS
            if (!isReached)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.location_pin, size: 20),
                  label: Text(s.reached, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A87),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    // 1. Mandatory Location Check before proceeding
                    final loc = await LocationService.getCurrentLocation();
                    if (!loc.success || loc.latitude == null || loc.longitude == null) {
                      if (!mounted) return;
                      await _showLocationMandatoryDialog(context, loc);
                      return;
                    }

                    // Match center to check geofence
                    final centers = ref.read(centerProvider);
                    ExamCenter? matchedCenter;
                    try {
                      matchedCenter = centers.firstWhere(
                        (c) => c.name.toLowerCase().trim() == duty.centerName.toLowerCase().trim(),
                      );
                    } catch (_) {
                      matchedCenter = centers.isNotEmpty ? centers.first : null;
                    }

                    // Pre-check geofence if center coordinates are available
                    bool isManualOverride = false;
                    if (matchedCenter != null && matchedCenter.latitude != null && matchedCenter.longitude != null) {
                      final geofence = LocationService.verifyGeofence(
                        staffLat: loc.latitude!,
                        staffLng: loc.longitude!,
                        centerLat: matchedCenter.latitude,
                        centerLng: matchedCenter.longitude,
                        allowedRadiusMeters: matchedCenter.allowedRadiusMeters,
                      );

                      if (!geofence.isVerified) {
                        if (!mounted) return;
                        final requestManual = await _showOutsideGeofenceDialog(
                          context: context,
                          centerName: matchedCenter.name,
                          geofence: geofence,
                        );

                        if (requestManual != true) {
                          return; // User clicked "Try Again"
                        }
                        isManualOverride = true;
                      }
                    }

                    final result = await ref.read(dutyProvider.notifier).recordDutyReached(
                          dutyId: duty.id,
                          invigilatorId: duty.invigilatorId,
                          reportingTime: duty.reportingTime,
                          excellentUntil: duty.excellentUntil,
                          goodUntil: duty.goodUntil,
                          centerLat: matchedCenter?.latitude,
                          centerLng: matchedCenter?.longitude,
                          allowedRadiusMeters: matchedCenter?.allowedRadiusMeters ?? 200,
                          isManualOverride: isManualOverride,
                        );

                    if (result.success && mounted) {
                      // Trigger spoken TTS feedback if voice enabled
                      if (dutySettings.voiceFeedbackEnabled) {
                        String ttsMsg;
                        if (result.performance.toLowerCase() == 'excellent') {
                          ttsMsg = s.youReachedOnTime;
                        } else if (result.performance.toLowerCase() == 'good') {
                          ttsMsg = s.youReachedSlightlyLate;
                        } else {
                          ttsMsg = s.reachInProperTime;
                        }
                        TtsService.speakArrivalEvaluation(
                          result.performance,
                          result.message,
                          localizedText: ttsMsg,
                          langCode: Localizations.localeOf(context).languageCode,
                        );
                      }
                      // Show Popup Result modal
                      _showReachedResultModal(context, result);
                    } else if (result.error != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${s.error}: ${result.error}'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade400, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${s.status}: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(s.reached, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  duty.reachedPerformance ?? s.onTime,
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (duty.isGeofenceVerified == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(s.geofenceVerified, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                ),
                              ] else if (duty.geofenceStatus == 'manual_requested' || duty.geofenceStatus == 'outside') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade800,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(s.outsideGeofence, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${s.arrivalTime}: ${duty.reachedTime ?? "-"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (duty.distanceFromCenter != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${s.distanceFromCenter}: ${duty.distanceFromCenter! < 1000 ? s.distanceMeters(duty.distanceFromCenter!.toStringAsFixed(0)) : "${(duty.distanceFromCenter! / 1000).toStringAsFixed(2)}km"}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: duty.isGeofenceVerified == true ? Colors.green.shade800 : Colors.deepOrange,
                              ),
                            ),
                          ],
                          if (duty.reachedLocation != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Color(0xFF007A87)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    duty.reachedLocation!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF007A87)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (duty.resolvedMapsUrl != null)
                      IconButton(
                        icon: const Icon(Icons.map_outlined, color: Color(0xFF007A87)),
                        tooltip: 'Google Maps',
                        onPressed: () => LocationService.openMapLocation(
                          duty.resolvedMapsUrl!,
                          latitude: duty.reachedLatitude,
                          longitude: duty.reachedLongitude,
                        ),
                      ),
                  ],
                ),
              ),

            if (duty.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.read(dutyProvider.notifier).updateDutyStatus(duty.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.reject),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref.read(dutyProvider.notifier).updateDutyStatus(duty.id, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.accept),
                    ),
                  ),
                ],
              ),
            ],

            // Duty Swap Button: only shown if Admin has enabled Swap Permission
            if (duty.status == 'accepted' && dutySettings.allowDutySwap) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: Text(s.swapDuty, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showSwapRequestModal(duty, allInvs, s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A87),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStandardDutyCard(ExamDuty duty, List<Invigilator> allInvs, DutySettings dutySettings, S s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    duty.examName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildStatusBadge(duty.status, s),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.calendar_today, '${s.date}: ${duty.date}'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.location_on_outlined, '${s.center}: ${duty.centerName}'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${s.shift} ${duty.shift}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${s.remuneration}: ${duty.payment}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF007A87))),
                if (dutySettings.allowLunch)
                  Text('${s.lunchProvision}: ${duty.lunch == "Yes" ? s.yes : s.no}', style: const TextStyle(fontSize: 13)),
              ],
            ),
            if (dutySettings.allowRole) ...[
              const SizedBox(height: 6),
              Text('${s.invigilator}: ${duty.role.toUpperCase()}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
            if (duty.isReached) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text('${s.arrival}: ${duty.reachedTime} (${duty.reachedPerformance ?? s.onTime})',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
            if (duty.status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.read(dutyProvider.notifier).updateDutyStatus(duty.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.reject),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref.read(dutyProvider.notifier).updateDutyStatus(duty.id, 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.accept),
                    ),
                  ),
                ],
              ),
            ] else if (duty.status == 'accepted' && dutySettings.allowDutySwap) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: Text(s.swapDuty, style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showSwapRequestModal(duty, allInvs, s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A87),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSwapRequestModal(ExamDuty duty, List<Invigilator> allInvs, S s) {
    String? selectedTargetInvId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final otherInvs = allInvs.where((i) => i.id != duty.invigilatorId && i.isActive).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.swapDuty, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${duty.examName} • ${duty.date}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: s.selectInvigilators, prefixIcon: const Icon(Icons.person)),
                  initialValue: selectedTargetInvId,
                  items: otherInvs.map((inv) => DropdownMenuItem(value: inv.id, child: Text(inv.name))).toList(),
                  onChanged: (val) => setModalState(() => selectedTargetInvId = val),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: selectedTargetInvId == null
                      ? null
                      : () async {
                          final targetInv = otherInvs.firstWhere((i) => i.id == selectedTargetInvId);
                          try {
                            await ref.read(swapProvider.notifier).createSwapRequest(
                                  requestingDutyId: duty.id,
                                  examName: duty.examName,
                                  date: duty.date,
                                  targetInvigilatorId: targetInv.id,
                                  targetInvigilatorName: targetInv.name,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(s.swapRequestSent),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${s.error}: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A87),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(s.save, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. TAB: AVAILABILITY & DUTY CALENDAR
  // ---------------------------------------------------------------------------
  Widget _buildCalendarTab(List<ExamDuty> duties, Invigilator inv, S s) {
    final monthDuties = duties.where((d) {
      try {
        final dt = DateTime.parse(d.date);
        return dt.year == _calendarMonth.year && dt.month == _calendarMonth.month;
      } catch (_) {
        return false;
      }
    }).toList();

    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() {
                          _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
                        }),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_calendarMonth),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() {
                          _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Weekday Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text('Mon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      Text('Tue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      Text('Wed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      Text('Thu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      Text('Fri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      Text('Sat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                      Text('Sun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: daysInMonth + (firstDayWeekday - 1),
                    itemBuilder: (context, index) {
                      if (index < firstDayWeekday - 1) return const SizedBox.shrink();
                      final day = index - (firstDayWeekday - 1) + 1;
                      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_calendarMonth.year, _calendarMonth.month, day));
                      final dayDuties = monthDuties.where((d) => d.date == dateStr).toList();
                      final hasDuty = dayDuties.isNotEmpty;
                      final isUnavailable = inv.unavailableDates.contains(dateStr);

                      Color bgColor = Colors.transparent;
                      Color borderColor = Colors.grey.withValues(alpha: 0.2);
                      Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

                      if (hasDuty) {
                        bgColor = const Color(0xFF007A87);
                        borderColor = const Color(0xFF007A87);
                        textColor = Colors.white;
                      } else if (isUnavailable) {
                        bgColor = Colors.red.withValues(alpha: 0.12);
                        borderColor = Colors.redAccent;
                        textColor = Colors.red.shade700;
                      }

                      return InkWell(
                        onTap: () {
                          if (hasDuty) {
                            _showDateDutyDetails(context, dateStr, dayDuties, s);
                          } else {
                            _showAvailabilityToggleDialog(context, inv, dateStr, isUnavailable, s);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor, width: hasDuty || isUnavailable ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontWeight: hasDuty || isUnavailable ? FontWeight.bold : FontWeight.normal,
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                              if (hasDuty)
                                const Icon(Icons.assignment, size: 9, color: Colors.white)
                              else if (isUnavailable)
                                Text(s.unavailable.toUpperCase(), style: const TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // LEGEND CARD
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.calendar, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF007A87), borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Text(s.assignedDuty, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 14),
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Text(s.unavailable, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 14),
                      Container(width: 12, height: 12, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Text(s.available, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 ${s.clickDateToToggle}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateDutyDetails(BuildContext context, String dateStr, List<ExamDuty> dayDuties, S s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.event_available, color: Color(0xFF007A87)),
            const SizedBox(width: 8),
            Text('${s.dutyDetails}: $dateStr', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: dayDuties.map((d) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF007A87).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.examName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${s.shift} ${d.shift} • ${d.payment} • ${d.centerName}', style: const TextStyle(fontSize: 11)),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
        ],
      ),
    );
  }

  void _showAvailabilityToggleDialog(BuildContext context, Invigilator inv, String dateStr, bool currentlyUnavailable, S s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(currentlyUnavailable ? '${s.available}?' : '${s.unavailable}?'),
        content: Text(
          currentlyUnavailable
              ? '$dateStr: ${s.available}'
              : '$dateStr: ${s.unavailable}',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyUnavailable ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(invigilatorProvider.notifier).toggleUnavailableDate(inv.id, dateStr);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(currentlyUnavailable ? '${s.available}: $dateStr' : '${s.unavailable}: $dateStr'),
                    backgroundColor: currentlyUnavailable ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
            child: Text(currentlyUnavailable ? s.available : s.unavailable),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TAB: DUTY HISTORY
  // ---------------------------------------------------------------------------
  Widget _buildHistoryTab(List<ExamDuty> duties, Invigilator inv, S s) {
    if (duties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(s.noDutiesAssigned, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: duties.length,
      itemBuilder: (context, index) {
        final duty = duties[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(duty.examName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.date}: ${duty.date} • ${s.shift}: ${duty.shift} • ${duty.payment}'),
                  Text('${s.center}: ${duty.centerName} • ${s.status}: ${duty.status.toUpperCase()}'),
                  if (duty.isReached)
                    Text('${s.arrival}: ${duty.reachedTime} (${duty.reachedPerformance ?? s.onTime})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
              onPressed: () => _exportSingleDutyPdf(duty, inv),
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportSingleDutyPdf(ExamDuty duty, Invigilator inv) async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('DutyDesk Assignment Letter', style: pw.TextStyle(font: boldFont, fontSize: 20)),
              pw.SizedBox(height: 16),
              pw.Text('Staff Details', style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.Bullet(text: 'Full Name: ${inv.name}'),
              pw.Bullet(text: 'Resource ID: ${inv.resourceId}'),
              pw.Bullet(text: 'Mobile: ${inv.mobile}'),
              pw.SizedBox(height: 16),
              pw.Text('Duty Details', style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.Bullet(text: 'Exam: ${duty.examName}'),
              pw.Bullet(text: 'Date: ${duty.date}'),
              pw.Bullet(text: 'Center: ${duty.centerName}'),
              pw.Bullet(text: 'Shift: ${duty.shift}'),
              pw.Bullet(text: 'Remuneration: ${duty.payment}'),
              if (duty.isReached)
                pw.Bullet(text: 'Arrival Time: ${duty.reachedTime} (${duty.reachedPerformance})'),
            ],
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      log('Failed to print PDF: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. TAB: STAFF PROFILE (READ-ONLY AS REQUIRED)
  // ---------------------------------------------------------------------------
  Widget _buildProfileTab(Invigilator inv, List<ExamDuty> duties, S s) {
    final activeDuties = duties.where((d) => d.status.toLowerCase() == 'accepted').length;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDarkMode ? const Color(0xFF1E293B) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
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
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF007A87).withValues(alpha: 0.12),
                  child: Text(
                    inv.name.isNotEmpty
                        ? inv.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF007A87)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  inv.name, // COMPLETE FULL NAME
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.resourceId}: ${inv.resourceId}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: inv.isActive ? Colors.green.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    inv.isActive ? s.active.toUpperCase() : s.inactive.toUpperCase(),
                    style: TextStyle(
                      color: inv.isActive ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Language Setting Tile
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: Color(0xFF007A87)),
              title: Text(s.language, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('English / हिन्दी / ગુજરાતી'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/language'),
            ),
          ),
          const SizedBox(height: 16),

          // Read-Only Personal Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
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
                  s.myProfile,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildReadOnlyRow(Icons.person, s.fullName, inv.name),
                const Divider(height: 20),
                _buildReadOnlyRow(Icons.badge, s.resourceId, inv.resourceId),
                const Divider(height: 20),
                _buildReadOnlyRow(Icons.phone, s.mobile, inv.mobile),
                const Divider(height: 20),
                _buildReadOnlyRow(Icons.email, s.email, inv.email ?? '-'),
                const Divider(height: 20),
                _buildReadOnlyRow(Icons.home, s.location, inv.address ?? '-'),
                const Divider(height: 20),
                _buildReadOnlyRow(Icons.assignment_turned_in, s.accepted, '$activeDuties ${s.dutyDetails}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF007A87)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SMALL WIDGET HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildStatusBadge(String status, S s) {
    Color color;
    String label = status;
    switch (status.toLowerCase()) {
      case 'accepted': 
        color = Colors.green; 
        label = s.accepted;
        break;
      case 'rejected': 
        color = Colors.red; 
        label = s.rejected;
        break;
      default: 
        color = Colors.orange;
        label = s.pending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
      ],
    );
  }
}

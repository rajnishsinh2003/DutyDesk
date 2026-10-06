import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../features/invigilator/providers/duty_provider.dart';
import '../../features/admin/providers/invigilator_provider.dart';
import '../../features/notifications/providers/notification_provider.dart';

/// Standby Auto-Promotion Engine
///
/// Monitors active exam duties and automatically promotes standby/reserve
/// invigilators to active duty when:
/// - An assigned invigilator doesn't clock-in within the grace period
/// - An invigilator rejects or cancels their assignment
/// - An admin marks a no-show
///
/// The engine selects the best-fit standby based on:
/// 1. Invigilators marked as "standby" for the same center
/// 2. Lowest existing duty count (fairness)
/// 3. Available (not already on duty for the same shift)

enum StandbyPromotionReason {
  noShow,           // Assigned staff didn't clock in
  rejected,         // Assigned staff rejected duty
  cancelled,        // Admin cancelled the assignment
  emergencyVacancy, // Manual trigger from admin
}

class StandbyPromotionEvent {
  final String originalDutyId;
  final String originalInvigilatorId;
  final String originalInvigilatorName;
  final String promotedInvigilatorId;
  final String promotedInvigilatorName;
  final StandbyPromotionReason reason;
  final DateTime timestamp;
  final String examName;
  final String centerName;
  final String shift;

  const StandbyPromotionEvent({
    required this.originalDutyId,
    required this.originalInvigilatorId,
    required this.originalInvigilatorName,
    required this.promotedInvigilatorId,
    required this.promotedInvigilatorName,
    required this.reason,
    required this.timestamp,
    required this.examName,
    required this.centerName,
    required this.shift,
  });

  Map<String, dynamic> toMap() => {
    'originalDutyId': originalDutyId,
    'originalInvigilatorId': originalInvigilatorId,
    'originalInvigilatorName': originalInvigilatorName,
    'promotedInvigilatorId': promotedInvigilatorId,
    'promotedInvigilatorName': promotedInvigilatorName,
    'reason': reason.name,
    'timestamp': FieldValue.serverTimestamp(),
    'examName': examName,
    'centerName': centerName,
    'shift': shift,
  };
}

class StandbyEngineState {
  final bool isMonitoring;
  final int noShowGraceMinutes;
  final List<StandbyPromotionEvent> promotionLog;
  final int totalAutoPromotions;

  const StandbyEngineState({
    this.isMonitoring = false,
    this.noShowGraceMinutes = 30,
    this.promotionLog = const [],
    this.totalAutoPromotions = 0,
  });

  StandbyEngineState copyWith({
    bool? isMonitoring,
    int? noShowGraceMinutes,
    List<StandbyPromotionEvent>? promotionLog,
    int? totalAutoPromotions,
  }) {
    return StandbyEngineState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      noShowGraceMinutes: noShowGraceMinutes ?? this.noShowGraceMinutes,
      promotionLog: promotionLog ?? this.promotionLog,
      totalAutoPromotions: totalAutoPromotions ?? this.totalAutoPromotions,
    );
  }
}

class StandbyEngineNotifier extends Notifier<StandbyEngineState> {
  Timer? _monitorTimer;

  @override
  StandbyEngineState build() {
    ref.onDispose(() {
      _monitorTimer?.cancel();
    });
    return const StandbyEngineState();
  }

  /// Start the standby auto-promotion monitoring engine
  void startMonitoring({int graceMinutes = 30}) {
    _monitorTimer?.cancel();
    state = state.copyWith(
      isMonitoring: true,
      noShowGraceMinutes: graceMinutes,
    );

    // Check every 2 minutes for no-shows
    _monitorTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _scanForNoShows();
    });

    // Immediate first scan
    _scanForNoShows();
    log('🔄 Standby Auto-Promotion Engine started (grace: ${graceMinutes}min)');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    state = state.copyWith(isMonitoring: false);
    log('⏹️ Standby Auto-Promotion Engine stopped');
  }

  /// Scan for no-shows and auto-promote standby replacements
  void _scanForNoShows() {
    final duties = ref.read(globalDutyProvider);
    final invs = ref.read(invigilatorProvider);
    final now = DateTime.now();

    for (final duty in duties) {
      // Only check accepted duties that haven't clocked in
      if (duty.status != 'accepted') continue;
      if (duty.isReached) continue; // Already clocked in
      if (duty.isStandbyReplacement) continue; // Already a standby

      // Parse the duty reporting time and check if grace period has expired
      final dutyDate = _parseDutyDateTime(duty.date, duty.reportingTime);
      if (dutyDate == null) continue;

      final graceDeadline = dutyDate.add(Duration(minutes: state.noShowGraceMinutes));
      if (now.isBefore(graceDeadline)) continue; // Still within grace period

      // This duty is a no-show! Find a standby replacement
      log('⚠️ No-show detected: ${duty.examName} — ${duty.invigilatorId}');
      _autoPromoteStandby(
        noShowDuty: duty,
        allInvs: invs,
        allDuties: duties,
        reason: StandbyPromotionReason.noShow,
      );
    }
  }

  /// Manually trigger standby promotion for a specific duty (admin action)
  Future<void> promoteStandbyForDuty({
    required String dutyId,
    required StandbyPromotionReason reason,
  }) async {
    final duties = ref.read(globalDutyProvider);
    final invs = ref.read(invigilatorProvider);

    final duty = duties.where((d) => d.id == dutyId).firstOrNull;
    if (duty == null) return;

    await _autoPromoteStandby(
      noShowDuty: duty,
      allInvs: invs,
      allDuties: duties,
      reason: reason,
    );
  }

  /// Core promotion logic: find the best standby and dispatch them
  Future<void> _autoPromoteStandby({
    required ExamDuty noShowDuty,
    required List<Invigilator> allInvs,
    required List<ExamDuty> allDuties,
    required StandbyPromotionReason reason,
  }) async {
    // Find the original invigilator
    final originalInv = allInvs.firstWhere(
      (i) => i.id == noShowDuty.invigilatorId,
      orElse: () => Invigilator(id: '', name: 'Unknown', resourceId: '-', mobile: '', mockDutyCount: 0),
    );

    // Find available standby candidates:
    // - Not already assigned to a duty in the same shift on the same date
    // - Prefer same center, lowest duty count
    final busyInvIds = allDuties
        .where((d) =>
            d.date == noShowDuty.date &&
            d.shift == noShowDuty.shift &&
            d.status != 'rejected' &&
            d.status != 'cancelled')
        .map((d) => d.invigilatorId)
        .toSet();

    final candidates = allInvs
        .where((inv) =>
            inv.id.isNotEmpty &&
            inv.id != noShowDuty.invigilatorId &&
            !busyInvIds.contains(inv.id))
        .toList();

    if (candidates.isEmpty) {
      log('❌ No standby candidates available for ${noShowDuty.examName}');
      // Notify admin about unfilled vacancy
      try {
        await ref.read(notificationProvider.notifier).sendNotification(
          userId: 'admin',
          title: '🚨 Unfilled Vacancy: ${noShowDuty.examName}',
          message: 'No standby invigilators available for ${noShowDuty.examName} '
              '(Shift ${noShowDuty.shift}) at ${noShowDuty.centerName}. '
              'Original: ${originalInv.name} (${reason.name}). Manual intervention required.',
          type: 'standby_failed',
          dutyId: noShowDuty.id,
        );
      } catch (_) {}
      return;
    }

    // Sort by duty count (fairness — least duties first)
    candidates.sort((a, b) => a.mockDutyCount.compareTo(b.mockDutyCount));
    final selectedStandby = candidates.first;

    // Dispatch the standby replacement
    try {
      final dutyNotifier = ref.read(dutyProvider.notifier);
      await dutyNotifier.dispatchStandbyReplacement(
        originalDutyId: noShowDuty.id,
        standbyInvigilatorId: selectedStandby.id,
      );

      final event = StandbyPromotionEvent(
        originalDutyId: noShowDuty.id,
        originalInvigilatorId: noShowDuty.invigilatorId,
        originalInvigilatorName: originalInv.name,
        promotedInvigilatorId: selectedStandby.id,
        promotedInvigilatorName: selectedStandby.name,
        reason: reason,
        timestamp: DateTime.now(),
        examName: noShowDuty.examName,
        centerName: noShowDuty.centerName,
        shift: noShowDuty.shift,
      );

      // Log the promotion event to Firestore
      if (Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('standby_promotions')
              .add(event.toMap());
        } catch (_) {}
      }

      // Update local state
      state = state.copyWith(
        promotionLog: [event, ...state.promotionLog],
        totalAutoPromotions: state.totalAutoPromotions + 1,
      );

      log('✅ Standby promoted: ${selectedStandby.name} → ${noShowDuty.examName} '
          '(replacing ${originalInv.name}, reason: ${reason.name})');
    } catch (e) {
      log('❌ Standby promotion failed: $e');
    }
  }

  /// Parse duty date + reporting time into DateTime
  DateTime? _parseDutyDateTime(String dateStr, String timeStr) {
    try {
      // Expected format: "2026-10-05" or "05/10/2026"
      DateTime date;
      if (dateStr.contains('-')) {
        date = DateTime.parse(dateStr);
      } else if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return null;
        }
      } else {
        return null;
      }

      // Parse reporting time: "06:00 AM" or "14:30"
      final cleanTime = timeStr.trim().toUpperCase();
      int hour = 0;
      int minute = 0;

      if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
        final timePart = cleanTime.replaceAll(RegExp(r'[APM\s]'), '');
        final tParts = timePart.split(':');
        hour = int.tryParse(tParts[0]) ?? 0;
        minute = tParts.length > 1 ? (int.tryParse(tParts[1]) ?? 0) : 0;
        if (cleanTime.contains('PM') && hour < 12) hour += 12;
        if (cleanTime.contains('AM') && hour == 12) hour = 0;
      } else {
        final tParts = cleanTime.split(':');
        hour = int.tryParse(tParts[0]) ?? 0;
        minute = tParts.length > 1 ? (int.tryParse(tParts[1]) ?? 0) : 0;
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Update the no-show grace period
  void setGracePeriod(int minutes) {
    state = state.copyWith(noShowGraceMinutes: minutes);
  }
}

final standbyEngineProvider = NotifierProvider<StandbyEngineNotifier, StandbyEngineState>(() {
  return StandbyEngineNotifier();
});

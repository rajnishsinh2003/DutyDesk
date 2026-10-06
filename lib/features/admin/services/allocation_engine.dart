import 'dart:math' as math;
import '../providers/invigilator_provider.dart';
import '../providers/center_provider.dart';
import '../../invigilator/providers/duty_provider.dart';

/// Configurable weights for the multi-factor intelligent allocation engine.
class AllocationWeights {
  final double workload;
  final double distance;
  final double punctuality;
  final double rotation;

  const AllocationWeights({
    this.workload = 0.35,
    this.distance = 0.25,
    this.punctuality = 0.25,
    this.rotation = 0.15,
  });

  AllocationWeights copyWith({
    double? workload,
    double? distance,
    double? punctuality,
    double? rotation,
  }) {
    return AllocationWeights(
      workload: workload ?? this.workload,
      distance: distance ?? this.distance,
      punctuality: punctuality ?? this.punctuality,
      rotation: rotation ?? this.rotation,
    );
  }

  /// Normalized weights so their sum equals 1.0.
  AllocationWeights normalized() {
    final sum = workload + distance + punctuality + rotation;
    if (sum <= 0) return const AllocationWeights();
    return AllocationWeights(
      workload: workload / sum,
      distance: distance / sum,
      punctuality: punctuality / sum,
      rotation: rotation / sum,
    );
  }
}

/// Represents a detected allocation conflict or rule infraction.
class AllocationConflict {
  final String type; // 'leave', 'shift_overlap', 'daily_overload', 'standby_clash'
  final String title;
  final String description;
  final bool isHardBlock;
  final String date;
  final String? shift;

  const AllocationConflict({
    required this.type,
    required this.title,
    required this.description,
    required this.isHardBlock,
    required this.date,
    this.shift,
  });
}

/// A candidate invigilator evaluated with individual factor scores,
/// composite score, and detected conflicts.
class ScoredCandidate {
  final Invigilator invigilator;
  final double totalScore; // 0 to 100
  final double workloadScore; // 0 to 100
  final double distanceScore; // 0 to 100
  final double punctualityScore; // 0 to 100
  final double rotationScore; // 0 to 100
  final double? distanceKm;
  final int currentDutyCount;
  final List<AllocationConflict> conflicts;

  const ScoredCandidate({
    required this.invigilator,
    required this.totalScore,
    required this.workloadScore,
    required this.distanceScore,
    required this.punctualityScore,
    required this.rotationScore,
    this.distanceKm,
    required this.currentDutyCount,
    required this.conflicts,
  });

  bool get isEligible => conflicts.every((c) => !c.isHardBlock);

  String get tier {
    if (totalScore >= 85) return 'Best Match';
    if (totalScore >= 70) return 'Strong Match';
    if (totalScore >= 50) return 'Fair Match';
    return 'Low Match';
  }
}

/// Comprehensive fairness & distribution audit of the invigilator roster.
class FairnessReport {
  final double currentGini;
  final double currentFairnessScore; // 0 to 100%
  final double projectedGini;
  final double projectedFairnessScore; // 0 to 100%
  final double fairnessDelta;
  final int totalStaffCount;
  final int minDuties;
  final int maxDuties;
  final double averageDuties;
  final double standardDeviation;

  const FairnessReport({
    required this.currentGini,
    required this.currentFairnessScore,
    required this.projectedGini,
    required this.projectedFairnessScore,
    required this.fairnessDelta,
    required this.totalStaffCount,
    required this.minDuties,
    required this.maxDuties,
    required this.averageDuties,
    required this.standardDeviation,
  });

  String get currentFairnessLabel {
    if (currentFairnessScore >= 85) return 'Exceptional Balance';
    if (currentFairnessScore >= 70) return 'Well Balanced';
    if (currentFairnessScore >= 50) return 'Moderate Variance';
    return 'High Disparity';
  }

  String get projectedFairnessLabel {
    if (projectedFairnessScore >= 85) return 'Exceptional Balance';
    if (projectedFairnessScore >= 70) return 'Well Balanced';
    if (projectedFairnessScore >= 50) return 'Moderate Variance';
    return 'High Disparity';
  }
}

/// Output package of the intelligent allocation algorithm.
class AllocationPlan {
  final List<ScoredCandidate> rankedCandidates;
  final List<ScoredCandidate> selectedCandidates;
  final FairnessReport fairnessReport;
  final AllocationWeights weightsUsed;
  final int targetCount;

  const AllocationPlan({
    required this.rankedCandidates,
    required this.selectedCandidates,
    required this.fairnessReport,
    required this.weightsUsed,
    required this.targetCount,
  });
}

/// Core engine providing multi-factor allocation scoring, conflict detection,
/// distance calculations, and roster fairness analytics.
class AllocationEngine {
  /// Calculate straight-line distance in kilometers using the Haversine formula.
  static double calculateHaversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Determine or simulate realistic staff coordinates relative to the center if not yet registered.
  static double resolveDistanceKm(Invigilator inv, ExamCenter? center) {
    if (center != null &&
        center.latitude != null &&
        center.longitude != null &&
        inv.latitude != null &&
        inv.longitude != null) {
      return calculateHaversineDistanceKm(
        inv.latitude!,
        inv.longitude!,
        center.latitude!,
        center.longitude!,
      );
    }

    // Deterministic fallback based on hash of resource ID/name to provide realistic 1.5 - 18 km spread
    final seed = (inv.resourceId.hashCode ^ (center?.id.hashCode ?? 0)).abs();
    final pseudoKm = 1.5 + (seed % 165) / 10.0; // 1.5 km to 18.0 km
    return double.parse(pseudoKm.toStringAsFixed(1));
  }

  /// Score distance: 0 km -> 100, 5 km -> 85, 10 km -> 70, 20 km -> 40, >= 30 km -> 10
  static double calculateDistanceScore(double distanceKm) {
    if (distanceKm <= 0) return 100.0;
    final score = 100.0 - (distanceKm * 3.0);
    return score.clamp(10.0, 100.0);
  }

  /// Score workload: Fewer duties -> higher score (rewarding balancing).
  static double calculateWorkloadScore(int staffDuties, int minDuties, int maxDuties) {
    if (maxDuties == minDuties) return 100.0;
    final ratio = (staffDuties - minDuties) / (maxDuties - minDuties);
    final score = (1.0 - ratio) * 100.0;
    return score.clamp(0.0, 100.0);
  }

  /// Score punctuality and reliability from past duty performance.
  static double calculatePunctualityScore(List<ExamDuty> staffPastDuties) {
    if (staffPastDuties.isEmpty) return 85.0; // Default baseline for new staff

    double scoreSum = 0.0;
    int count = 0;

    for (final duty in staffPastDuties) {
      if (duty.status.toLowerCase() == 'rejected') {
        scoreSum += 15.0;
        count++;
        continue;
      }

      final perf = duty.reachedPerformance?.toLowerCase();
      if (perf == 'excellent') {
        scoreSum += 100.0;
        count++;
      } else if (perf == 'good') {
        scoreSum += 75.0;
        count++;
      } else if (perf == 'needs improvement' || perf == 'needs_improvement') {
        scoreSum += 35.0;
        count++;
      } else if (duty.isReached) {
        scoreSum += 80.0;
        count++;
      }
    }

    if (count == 0) return 85.0;
    return (scoreSum / count).clamp(0.0, 100.0);
  }

  /// Score rotation / recency factor: Promotes rest between duties.
  static double calculateRotationScore(DateTime? lastAssignedDate, DateTime targetDate) {
    if (lastAssignedDate == null) return 100.0;

    final diffDays = targetDate.difference(lastAssignedDate).inDays.abs();
    if (diffDays >= 7) return 100.0;
    if (diffDays >= 4) return 85.0;
    if (diffDays >= 2) return 65.0;
    if (diffDays == 1) return 35.0;
    return 10.0; // Same day assignment
  }

  /// Check conflicts across selected dates and shift for a specific staff member.
  static List<AllocationConflict> detectConflicts({
    required Invigilator inv,
    required List<String> dates,
    required String shift,
    required List<ExamDuty> globalDuties,
  }) {
    final conflicts = <AllocationConflict>[];

    for (final dt in dates) {
      // 1. Leave / Unavailable check (Hard Block)
      if (inv.unavailableDates.contains(dt)) {
        conflicts.add(AllocationConflict(
          type: 'leave',
          title: 'Marked Unavailable',
          description: 'Staff marked unavailable or requested leave on $dt.',
          isHardBlock: true,
          date: dt,
        ));
      }

      // 2. Same date and shift overlap (Hard Block)
      final sameShiftClash = globalDuties.where((d) =>
          d.invigilatorId == inv.id &&
          d.date == dt &&
          d.shift == shift &&
          d.status.toLowerCase() != 'rejected').toList();

      if (sameShiftClash.isNotEmpty) {
        final existingExam = sameShiftClash.first.examName;
        conflicts.add(AllocationConflict(
          type: 'shift_overlap',
          title: 'Shift $shift Already Assigned',
          description: 'Already assigned on $dt in Shift $shift ($existingExam).',
          isHardBlock: true,
          date: dt,
          shift: shift,
        ));
      }

      // 3. Daily Shift Overload (> 1 duty on the same day)
      final sameDayDuties = globalDuties.where((d) =>
          d.invigilatorId == inv.id &&
          d.date == dt &&
          d.status.toLowerCase() != 'rejected').length;

      if (sameDayDuties >= 2) {
        conflicts.add(AllocationConflict(
          type: 'daily_overload',
          title: 'Daily Duty Cap Reached',
          description: 'Staff already has $sameDayDuties duties on $dt (Fatigue guard).',
          isHardBlock: true,
          date: dt,
        ));
      } else if (sameDayDuties == 1) {
        conflicts.add(AllocationConflict(
          type: 'daily_overload',
          title: 'Back-to-Back Shift Warning',
          description: 'Staff already has 1 duty on $dt. Assigning another creates a double shift.',
          isHardBlock: false, // Soft warning
          date: dt,
        ));
      }

      // 4. Standby Clash
      if (inv.isStandby && inv.standbyForDate == dt) {
        conflicts.add(AllocationConflict(
          type: 'standby_clash',
          title: 'Designated Standby',
          description: 'Staff is currently designated as reserve standby for $dt.',
          isHardBlock: false,
          date: dt,
        ));
      }
    }

    return conflicts;
  }

  /// Compute Gini Coefficient and Fairness Score (0 to 100%) for a distribution of duty counts.
  static double computeGini(List<int> dutyCounts) {
    if (dutyCounts.isEmpty) return 0.0;
    final n = dutyCounts.length;
    final sorted = List<int>.from(dutyCounts)..sort();

    final sum = sorted.fold<int>(0, (prev, element) => prev + element);
    if (sum == 0) return 0.0; // Perfectly equal zero duties

    double weightedSum = 0;
    for (int i = 0; i < n; i++) {
      weightedSum += (i + 1) * sorted[i];
    }

    final gini = (2 * weightedSum) / (n * sum) - (n + 1) / n;
    return gini.clamp(0.0, 1.0);
  }

  /// Generate a complete Fairness Audit Report before and after simulated duty assignments.
  static FairnessReport generateFairnessReport({
    required List<int> currentDuties,
    required List<int> projectedDuties,
  }) {
    final currentGini = computeGini(currentDuties);
    final projectedGini = computeGini(projectedDuties);

    final currentFairness = ((1.0 - currentGini) * 100.0).clamp(0.0, 100.0);
    final projectedFairness = ((1.0 - projectedGini) * 100.0).clamp(0.0, 100.0);
    final delta = projectedFairness - currentFairness;

    final n = currentDuties.length;
    final minD = currentDuties.isEmpty ? 0 : currentDuties.reduce(math.min);
    final maxD = currentDuties.isEmpty ? 0 : currentDuties.reduce(math.max);
    final sum = currentDuties.fold<int>(0, (p, e) => p + e);
    final avg = n == 0 ? 0.0 : sum / n;

    double varianceSum = 0.0;
    for (final d in currentDuties) {
      varianceSum += math.pow(d - avg, 2);
    }
    final stdDev = n == 0 ? 0.0 : math.sqrt(varianceSum / n);

    return FairnessReport(
      currentGini: currentGini,
      currentFairnessScore: double.parse(currentFairness.toStringAsFixed(1)),
      projectedGini: projectedGini,
      projectedFairnessScore: double.parse(projectedFairness.toStringAsFixed(1)),
      fairnessDelta: double.parse(delta.toStringAsFixed(1)),
      totalStaffCount: n,
      minDuties: minD,
      maxDuties: maxD,
      averageDuties: double.parse(avg.toStringAsFixed(1)),
      standardDeviation: double.parse(stdDev.toStringAsFixed(1)),
    );
  }

  /// Execute the intelligent allocation algorithm and return a complete ranked plan.
  static AllocationPlan generatePlan({
    required List<Invigilator> activeStaff,
    required List<ExamDuty> globalDuties,
    required List<String> dates,
    required String shift,
    required ExamCenter? center,
    required int targetCount,
    AllocationWeights weights = const AllocationWeights(),
  }) {
    final normWeights = weights.normalized();
    final targetDate = dates.isNotEmpty
        ? (DateTime.tryParse(dates.first) ?? DateTime.now())
        : DateTime.now();

    // 1. Gather duty counts for all active staff
    final staffDutyCounts = <String, int>{};
    for (final staff in activeStaff) {
      final activeDuties = globalDuties.where((d) =>
          d.invigilatorId == staff.id &&
          d.status.toLowerCase() != 'rejected').length;
      staffDutyCounts[staff.id] = staff.mockDutyCount + activeDuties;
    }

    final countsList = staffDutyCounts.values.toList();
    final minDuties = countsList.isEmpty ? 0 : countsList.reduce(math.min);
    final maxDuties = countsList.isEmpty ? 0 : countsList.reduce(math.max);

    // 2. Score each candidate
    final scoredCandidates = <ScoredCandidate>[];

    for (final staff in activeStaff) {
      final duties = staffDutyCounts[staff.id] ?? 0;
      final distanceKm = resolveDistanceKm(staff, center);

      // Factor scores
      final workloadScore = calculateWorkloadScore(duties, minDuties, maxDuties);
      final distanceScore = calculateDistanceScore(distanceKm);

      final staffDutiesList = globalDuties
          .where((d) => d.invigilatorId == staff.id)
          .toList();
      final punctualityScore = calculatePunctualityScore(staffDutiesList);

      final rotationScore = calculateRotationScore(
        staff.lastMockAssignedDate,
        targetDate,
      );

      // Conflicts
      final conflicts = detectConflicts(
        inv: staff,
        dates: dates,
        shift: shift,
        globalDuties: globalDuties,
      );

      final hasHardBlock = conflicts.any((c) => c.isHardBlock);

      // Composite multi-factor score
      double composite = (normWeights.workload * workloadScore) +
          (normWeights.distance * distanceScore) +
          (normWeights.punctuality * punctualityScore) +
          (normWeights.rotation * rotationScore);

      // Penalize candidates with conflicts so they sort to the bottom
      if (hasHardBlock) {
        composite -= 100.0;
      }

      scoredCandidates.add(ScoredCandidate(
        invigilator: staff,
        totalScore: double.parse(composite.clamp(0.0, 100.0).toStringAsFixed(1)),
        workloadScore: double.parse(workloadScore.toStringAsFixed(1)),
        distanceScore: double.parse(distanceScore.toStringAsFixed(1)),
        punctualityScore: double.parse(punctualityScore.toStringAsFixed(1)),
        rotationScore: double.parse(rotationScore.toStringAsFixed(1)),
        distanceKm: distanceKm,
        currentDutyCount: duties,
        conflicts: conflicts,
      ));
    }

    // 3. Sort: Eligible first, sorted by highest totalScore descending
    scoredCandidates.sort((a, b) {
      if (a.isEligible && !b.isEligible) return -1;
      if (!a.isEligible && b.isEligible) return 1;
      return b.totalScore.compareTo(a.totalScore);
    });

    // 4. Select top targetCount eligible candidates
    final eligibleCandidates = scoredCandidates.where((c) => c.isEligible).toList();
    final selected = eligibleCandidates.take(targetCount).toList();

    // If not enough eligible, fill with best remaining
    if (selected.length < targetCount) {
      final remainingNeeded = targetCount - selected.length;
      final ineligibleRemainders = scoredCandidates
          .where((c) => !selected.contains(c))
          .take(remainingNeeded);
      selected.addAll(ineligibleRemainders);
    }

    // 5. Compute simulated projected duties to calculate fairness delta
    final projectedDuties = Map<String, int>.from(staffDutyCounts);
    final dutiesPerCandidate = dates.length; // +1 duty per selected date
    for (final sel in selected) {
      projectedDuties[sel.invigilator.id] =
          (projectedDuties[sel.invigilator.id] ?? 0) + dutiesPerCandidate;
    }

    final fairnessReport = generateFairnessReport(
      currentDuties: countsList,
      projectedDuties: projectedDuties.values.toList(),
    );

    return AllocationPlan(
      rankedCandidates: scoredCandidates,
      selectedCandidates: selected,
      fairnessReport: fairnessReport,
      weightsUsed: normWeights,
      targetCount: targetCount,
    );
  }
}

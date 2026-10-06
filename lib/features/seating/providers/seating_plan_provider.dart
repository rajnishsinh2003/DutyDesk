import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/seating_plan_model.dart';
import '../services/seating_generator_engine.dart';

class SeatingPlanNotifier extends Notifier<List<SeatingPlan>> {
  StreamSubscription? _subscription;

  @override
  List<SeatingPlan> build() {
    _initFirestoreListener();
    return _generateInitialPlans();
  }

  void _initFirestoreListener() {
    if (Firebase.apps.isEmpty) return;

    _subscription?.cancel();
    try {
      _subscription = FirebaseFirestore.instance
          .collection('seating_plans')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          state = snapshot.docs
              .map((doc) => SeatingPlan.fromFirestore(doc.id, doc.data()))
              .toList();
        }
      }, onError: (err) {
        log('Firestore seating_plans listener error: $err');
      });
    } catch (e) {
      log('Firestore seating_plans init error: $e');
    }

    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  /// Initial demo plans so users immediately have interactive data to explore
  List<SeatingPlan> _generateInitialPlans() {
    final candidates = SeatingGeneratorEngine.generateSampleCandidates(
      cseCount: 16,
      eceCount: 14,
      meCount: 10,
    );

    final plan1 = SeatingGeneratorEngine.generatePlan(
      examName: 'Mid-Semester Examinations 2026',
      sessionOrShift: 'Shift 1 (09:00 AM - 12:00 PM)',
      date: '2026-10-06',
      centerName: 'Main Campus, Building A',
      roomName: 'Hall 101 (Main Auditorium)',
      rows: 5,
      columns: 6,
      strategy: AntiCheatingStrategy.alternatingBranches,
      candidates: candidates,
      bufferSeatCount: 3,
    );

    final plan2 = SeatingGeneratorEngine.generatePlan(
      examName: 'CS302 - Data Structures & Algorithms',
      sessionOrShift: 'Shift 2 (02:00 PM - 05:00 PM)',
      date: '2026-10-07',
      centerName: 'North Wing, Science Block',
      roomName: 'Room 204',
      rows: 4,
      columns: 5,
      strategy: AntiCheatingStrategy.checkerboard,
      candidates: candidates.take(15).toList(),
      bufferSeatCount: 2,
    );

    return [plan1, plan2];
  }

  /// Save or update a seating plan to Firestore + local state
  Future<void> savePlan(SeatingPlan plan) async {
    // Optimistic local update
    final index = state.indexWhere((p) => p.id == plan.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) plan else state[i],
      ];
    } else {
      state = [plan, ...state];
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('seating_plans')
            .doc(plan.id)
            .set(plan.toMap());
        log('✅ Seating plan saved to Firestore: ${plan.id}');
      } catch (e) {
        log('Error saving seating plan to Firestore: $e');
      }
    }
  }

  /// Delete a plan
  Future<void> deletePlan(String planId) async {
    state = state.where((p) => p.id != planId).toList();

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('seating_plans')
            .doc(planId)
            .delete();
        log('🗑️ Seating plan deleted: $planId');
      } catch (e) {
        log('Error deleting seating plan: $e');
      }
    }
  }

  /// Update an individual seat in a plan (e.g. mark buffer, block desk, edit student)
  Future<void> updateSeat(String planId, StudentSeat updatedSeat) async {
    final planIdx = state.indexWhere((p) => p.id == planId);
    if (planIdx < 0) return;

    final currentPlan = state[planIdx];
    final updatedSeats = currentPlan.seats.map((seat) {
      if (seat.row == updatedSeat.row && seat.col == updatedSeat.col) {
        return updatedSeat;
      }
      return seat;
    }).toList();

    final newPlan = currentPlan.copyWith(seats: updatedSeats);
    await savePlan(newPlan);
  }

  /// Swap two student seats (e.g. for anti-cheating separation or student request)
  Future<void> swapSeats({
    required String planId,
    required int r1,
    required int c1,
    required int r2,
    required int c2,
  }) async {
    final planIdx = state.indexWhere((p) => p.id == planId);
    if (planIdx < 0) return;

    final plan = state[planIdx];
    final seat1Idx = plan.seats.indexWhere((s) => s.row == r1 && s.col == c1);
    final seat2Idx = plan.seats.indexWhere((s) => s.row == r2 && s.col == c2);

    if (seat1Idx < 0 || seat2Idx < 0) return;

    final seat1 = plan.seats[seat1Idx];
    final seat2 = plan.seats[seat2Idx];

    // Swap content while preserving desk coordinates
    final newSeat1 = seat1.copyWith(
      studentRoll: seat2.studentRoll,
      studentName: seat2.studentName,
      branchOrSubject: seat2.branchOrSubject,
      status: seat2.status,
    );

    final newSeat2 = seat2.copyWith(
      studentRoll: seat1.studentRoll,
      studentName: seat1.studentName,
      branchOrSubject: seat1.branchOrSubject,
      status: seat1.status,
    );

    final updatedSeats = List<StudentSeat>.from(plan.seats);
    updatedSeats[seat1Idx] = newSeat1;
    updatedSeats[seat2Idx] = newSeat2;

    final newPlan = plan.copyWith(seats: updatedSeats);
    await savePlan(newPlan);
  }
}

final seatingPlanProvider =
    NotifierProvider<SeatingPlanNotifier, List<SeatingPlan>>(() {
  return SeatingPlanNotifier();
});

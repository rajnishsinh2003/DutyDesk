import 'package:flutter_test/flutter_test.dart';
import 'package:duty_desk/features/seating/models/seating_plan_model.dart';
import 'package:duty_desk/features/seating/services/seating_generator_engine.dart';

void main() {
  group('SeatingGeneratorEngine', () {
    test('generateSampleCandidates produces expected counts and roll formats', () {
      final candidates = SeatingGeneratorEngine.generateSampleCandidates(
        cseCount: 5,
        eceCount: 4,
        meCount: 3,
      );

      expect(candidates.length, 12);
      expect(candidates.where((c) => c.branch == 'CSE').length, 5);
      expect(candidates.where((c) => c.branch == 'ECE').length, 4);
      expect(candidates.where((c) => c.branch == 'ME').length, 3);
      expect(candidates.first.rollNumber, '23CSE101');
      expect(candidates.last.rollNumber, '23ME303');
    });

    test('alternatingBranches allocates without duplicate roll numbers and respects buffer seats', () {
      final candidates = SeatingGeneratorEngine.generateSampleCandidates(
        cseCount: 6,
        eceCount: 6,
        meCount: 6,
      );

      final plan = SeatingGeneratorEngine.generatePlan(
        examName: 'Midterm 2026',
        sessionOrShift: 'Shift 1',
        date: '2026-12-01',
        centerName: 'Block A',
        roomName: 'Room 101',
        rows: 4,
        columns: 5,
        strategy: AntiCheatingStrategy.alternatingBranches,
        candidates: candidates,
        bufferSeatCount: 2,
      );

      expect(plan.totalCapacity, 20);
      expect(plan.bufferCount, 2);
      expect(plan.allocatedCount, 18);
      expect(plan.vacantCount, 0);
      expect(plan.occupancyRate, closeTo(90.0, 0.01));

      final allocatedRolls = plan.seats
          .where((s) => s.status == SeatStatus.allocated)
          .map((s) => s.studentRoll)
          .toList();
      expect(allocatedRolls.toSet().length, allocatedRolls.length);
    });

    test('checkerboard leaves alternate diagonal desks vacant', () {
      final candidates = SeatingGeneratorEngine.generateSampleCandidates(
        cseCount: 10,
        eceCount: 0,
        meCount: 0,
      );

      final plan = SeatingGeneratorEngine.generatePlan(
        examName: 'Endsem 2026',
        sessionOrShift: 'Shift 2',
        date: '2026-12-02',
        centerName: 'Block B',
        roomName: 'Hall 2',
        rows: 4,
        columns: 4,
        strategy: AntiCheatingStrategy.checkerboard,
        candidates: candidates,
        bufferSeatCount: 0,
      );

      for (final seat in plan.seats) {
        if ((seat.row + seat.col) % 2 == 1) {
          expect(seat.status, SeatStatus.vacant);
        }
      }
      expect(plan.allocatedCount, 8);
    });

    test('consecutiveRolls fills seats sequentially and leaves extra seats vacant', () {
      final candidates = SeatingGeneratorEngine.generateSampleCandidates(
        cseCount: 4,
        eceCount: 0,
        meCount: 0,
      );

      final plan = SeatingGeneratorEngine.generatePlan(
        examName: 'Quiz 1',
        sessionOrShift: 'Shift 1',
        date: '2026-12-03',
        centerName: 'Main',
        roomName: 'R1',
        rows: 3,
        columns: 3,
        strategy: AntiCheatingStrategy.consecutiveRolls,
        candidates: candidates,
        bufferSeatCount: 1,
      );

      expect(plan.allocatedCount, 4);
      expect(plan.bufferCount, 1);
      expect(plan.vacantCount, 4);
      expect(plan.seats.first.studentRoll, '23CSE101');
    });

    test('StudentSeat toMap and fromMap roundtrip preserves fields', () {
      const seat = StudentSeat(
        row: 1,
        col: 2,
        deskLabel: 'R2-C3',
        studentRoll: '23CSE105',
        studentName: 'Test Student',
        branchOrSubject: 'CSE',
        status: SeatStatus.allocated,
        isSpecialNeed: true,
      );

      final restored = StudentSeat.fromMap(seat.toMap());
      expect(restored.row, 1);
      expect(restored.col, 2);
      expect(restored.deskLabel, 'R2-C3');
      expect(restored.studentRoll, '23CSE105');
      expect(restored.status, SeatStatus.allocated);
      expect(restored.isSpecialNeed, isTrue);
    });
  });
}

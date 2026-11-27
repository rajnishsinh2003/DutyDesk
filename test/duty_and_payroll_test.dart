import 'package:flutter_test/flutter_test.dart';
import 'package:duty_desk/features/invigilator/providers/duty_provider.dart';

void main() {
  group('Payroll & Shift Helpers', () {
    test('getAutoPaymentForShift returns expected shift rates', () {
      expect(getAutoPaymentForShift('1'), '₹400');
      expect(getAutoPaymentForShift('Shift 1'), '₹400');
      expect(getAutoPaymentForShift('2'), '₹600');
      expect(getAutoPaymentForShift('Shift 2'), '₹600');
      expect(getAutoPaymentForShift('3'), '₹800');
      expect(getAutoPaymentForShift('unknown'), '₹400');
    });
  });

  group('ExamDuty Pure Logic', () {
    ExamDuty makeDuty({
      String payment = '₹400',
      String date = '2026-12-01',
      String dutyEndTime = '01:00 PM',
      String? reachedMapsUrl,
      double? reachedLatitude,
      double? reachedLongitude,
    }) {
      return ExamDuty(
        id: 'd1',
        date: date,
        examName: 'Final Exam',
        centerName: 'Center A',
        invigilatorId: 'inv1',
        status: 'accepted',
        payment: payment,
        lunch: 'Included',
        role: 'Invigilator',
        shift: '1',
        dutyEndTime: dutyEndTime,
        reachedMapsUrl: reachedMapsUrl,
        reachedLatitude: reachedLatitude,
        reachedLongitude: reachedLongitude,
      );
    }

    test('parsedPaymentAmount extracts numeric value or falls back to 400', () {
      expect(makeDuty(payment: '₹600').parsedPaymentAmount, 600);
      expect(makeDuty(payment: '₹1,250').parsedPaymentAmount, 1250);
      expect(makeDuty(payment: 'N/A').parsedPaymentAmount, 400);
    });

    test('resolvedMapsUrl prefers explicit URL and falls back to coordinates', () {
      expect(
        makeDuty(reachedMapsUrl: 'https://maps.example.com/1').resolvedMapsUrl,
        'https://maps.example.com/1',
      );
      expect(
        makeDuty(reachedLatitude: 23.0225, reachedLongitude: 72.5714).resolvedMapsUrl,
        'https://www.google.com/maps/search/?api=1&query=23.0225,72.5714',
      );
      expect(makeDuty().resolvedMapsUrl, isNull);
    });

    test('parsedEndDateTime parses yyyy-MM-dd and dd-MM-yyyy dates', () {
      final iso = makeDuty(date: '2026-12-15', dutyEndTime: '02:30 PM').parsedEndDateTime;
      expect(iso, isNotNull);
      expect(iso!.year, 2026);
      expect(iso.month, 12);
      expect(iso.day, 15);
      expect(iso.hour, 14);
      expect(iso.minute, 30);

      final dmy = makeDuty(date: '15-12-2026', dutyEndTime: '09:15 AM').parsedEndDateTime;
      expect(dmy, isNotNull);
      expect(dmy!.year, 2026);
      expect(dmy.month, 12);
      expect(dmy.day, 15);
      expect(dmy.hour, 9);
      expect(dmy.minute, 15);
    });
  });
}

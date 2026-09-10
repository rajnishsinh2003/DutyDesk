import 'dart:io';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';

import '../../invigilator/providers/duty_provider.dart';
import '../providers/invigilator_provider.dart';

class ReportService {
  static Future<void> exportPdf({
    required List<ExamDuty> duties,
    required List<Invigilator> invigilators,
    required String filterDescription,
  }) async {
    try {
      if (duties.isEmpty) {
        throw Exception('No records available to export.');
      }

      final pdf = pw.Document();

      final baseFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      // Build rows
      final rows = duties.map((duty) {
        final inv = invigilators.firstWhere(
          (i) => i.id == duty.invigilatorId,
          orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
        );
        final arrivalStr = duty.isReached
            ? '${duty.reachedTime ?? "-"}'
                ' (${duty.reachedPerformance ?? "Reached"})'
                '${duty.reachedLocation != null ? "\nGPS: ${duty.reachedLocation}" : ""}'
            : 'Not Reached';

        return [
          duty.date,
          duty.examName,
          'Shift ${duty.shift}',
          inv.name, // COMPLETE FULL NAME
          inv.resourceId,
          duty.centerName,
          duty.reportingTime,
          duty.payment,
          duty.status.toUpperCase(),
          arrivalStr,
        ];
      }).toList();

      final headers = [
        'Date', 'Exam', 'Shift', 'Staff Name', 'Resource No.',
        'Room / Center', 'Reporting Time', 'Amount', 'Status', 'Arrival & GPS Info',
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DutyDesk — Date-Wise Duty Allocation & Attendance Report',
                  style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Filter: $filterDescription   |   Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(font: baseFont, fontSize: 8.5, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 14),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2), // Date
                    1: const pw.FlexColumnWidth(2.0), // Exam
                    2: const pw.FlexColumnWidth(1.0), // Shift
                    3: const pw.FlexColumnWidth(2.0), // Staff Name
                    4: const pw.FlexColumnWidth(1.3), // Resource No
                    5: const pw.FlexColumnWidth(1.8), // Room / Center
                    6: const pw.FlexColumnWidth(1.2), // Reporting Time
                    7: const pw.FlexColumnWidth(1.0), // Amount
                    8: const pw.FlexColumnWidth(1.1), // Status
                    9: const pw.FlexColumnWidth(1.8), // Arrival Info
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                      children: headers.map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Text(h,
                          style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white),
                        ),
                      )).toList(),
                    ),
                    // Data Rows
                    ...rows.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      final bgColor = i.isEven ? PdfColors.grey50 : PdfColors.white;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: bgColor),
                        children: row.map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                          child: pw.Text(cell,
                            style: pw.TextStyle(font: baseFont, fontSize: 7.5),
                          ),
                        )).toList(),
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Records: ${duties.length}',
                      style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.blueGrey700),
                    ),
                    pw.Text(
                      'DutyDesk Staff Management System',
                      style: pw.TextStyle(font: baseFont, fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/DutyAllocationReport_$timestamp.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'DutyDesk Date-Wise Allocation Report',
          text: 'DutyDesk Allocation Report — $filterDescription',
        ),
      );
    } catch (e) {
      log('PDF generation failed: $e');
      rethrow;
    }
  }

  static Future<void> exportExcel({
    required List<ExamDuty> duties,
    required List<Invigilator> invigilators,
    required String filterDescription,
  }) async {
    try {
      if (duties.isEmpty) {
        throw Exception('No records available to export.');
      }

      final excel = Excel.createExcel();
      final sheet = excel['Allocation Report'];

      // Header row
      final headers = [
        'Date',
        'Exam Name',
        'Shift',
        'Staff Full Name',
        'Resource Number',
        'Mobile Number',
        'Room / Center',
        'Reporting Time',
        'Excellent Until',
        'Good Until',
        'Duty Amount',
        'Lunch Provided',
        'Duty Status',
        'Arrival Status',
        'Reached Time',
        'Arrival Performance',
        'GPS Location',
        'Google Maps Link',
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Data rows
      for (final duty in duties) {
        final inv = invigilators.firstWhere(
          (i) => i.id == duty.invigilatorId,
          orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '-', mobile: '-', mockDutyCount: 0),
        );

        sheet.appendRow([
          TextCellValue(duty.date),
          TextCellValue(duty.examName),
          TextCellValue('Shift ${duty.shift}'),
          TextCellValue(inv.name), // COMPLETE FULL NAME
          TextCellValue(inv.resourceId),
          TextCellValue(inv.mobile),
          TextCellValue(duty.centerName),
          TextCellValue(duty.reportingTime),
          TextCellValue(duty.excellentUntil),
          TextCellValue(duty.goodUntil),
          TextCellValue(duty.payment),
          TextCellValue(duty.lunch),
          TextCellValue(duty.status.toUpperCase()),
          TextCellValue(duty.isReached ? 'REACHED' : 'NOT REACHED'),
          TextCellValue(duty.reachedTime ?? '-'),
          TextCellValue(duty.reachedPerformance ?? '-'),
          TextCellValue(duty.reachedLocation ?? '-'),
          TextCellValue(duty.reachedMapsUrl ?? '-'),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel encoding returned null bytes.');

      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/DutyAllocationReport_$timestamp.xlsx');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          subject: 'DutyDesk Excel Report',
          text: 'DutyDesk Date-Wise Allocation Report — $filterDescription',
        ),
      );
    } catch (e) {
      log('Excel generation failed: $e');
      rethrow;
    }
  }
}

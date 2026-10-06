import 'dart:io';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import '../models/incident_model.dart';

class IncidentReportService {
  /// Export incident log to landscape PDF
  static Future<void> exportPdf({
    required List<IncidentReport> incidents,
    required String filterDescription,
  }) async {
    try {
      if (incidents.isEmpty) {
        throw Exception('No incident records to export.');
      }

      final pdf = pw.Document();
      final baseFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      final rows = incidents.map((inc) {
        final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(inc.createdAt);
        final resolutionStr = inc.status == 'resolved'
            ? '${inc.resolutionNotes ?? "Resolved"}\n(${DateFormat('dd-MM-yyyy HH:mm').format(inc.resolvedAt ?? inc.createdAt)})'
            : '-';

        return [
          formattedDate,
          inc.typeDisplayName,
          inc.severity.toUpperCase(),
          '${inc.centerName}\nRoom: ${inc.room.isNotEmpty ? inc.room : "N/A"}',
          '${inc.reporterName}\n(${inc.reporterRole})',
          '${inc.title}\n${inc.description}',
          inc.status.toUpperCase(),
          resolutionStr,
        ];
      }).toList();

      final headers = [
        'Reported At',
        'Type',
        'Severity',
        'Center / Room',
        'Reporter',
        'Incident Details',
        'Status',
        'Resolution',
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
                  'DutyDesk — Examination Center Incident & Irregularity Log',
                  style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Filter: $filterDescription   |   Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}   |   Total Incidents: ${incidents.length}',
                  style: pw.TextStyle(font: baseFont, fontSize: 8.5, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2), // Date
                    1: const pw.FlexColumnWidth(1.4), // Type
                    2: const pw.FlexColumnWidth(1.0), // Severity
                    3: const pw.FlexColumnWidth(1.6), // Center / Room
                    4: const pw.FlexColumnWidth(1.4), // Reporter
                    5: const pw.FlexColumnWidth(2.6), // Description
                    6: const pw.FlexColumnWidth(1.0), // Status
                    7: const pw.FlexColumnWidth(1.8), // Resolution
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                      children: headers.map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white),
                        ),
                      )).toList(),
                    ),
                    ...rows.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      final bgColor = i.isEven ? PdfColors.grey50 : PdfColors.white;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: bgColor),
                        children: row.map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                          child: pw.Text(
                            cell,
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
                      'DutyDesk Secure Exam Control Room',
                      style: pw.TextStyle(font: baseFont, fontSize: 8, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Official Examination Incident Report',
                      style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.blueGrey800),
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
      final file = File('${dir.path}/IncidentLogReport_$timestamp.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'DutyDesk Incident Log Report',
          text: 'DutyDesk Incident Log Report — $filterDescription',
        ),
      );
    } catch (e) {
      log('Incident PDF export failed: $e');
      rethrow;
    }
  }

  /// Export incident log to Excel (.xlsx)
  static Future<void> exportExcel({
    required List<IncidentReport> incidents,
    required String filterDescription,
  }) async {
    try {
      if (incidents.isEmpty) {
        throw Exception('No incident records to export.');
      }

      final excel = Excel.createExcel();
      final sheet = excel['Incidents'];

      final headers = [
        'Reported At',
        'Exam Name',
        'Center Name',
        'Room',
        'Incident Type',
        'Severity Level',
        'Title',
        'Description',
        'Reporter Name',
        'Reporter Role',
        'Reporter Contact',
        'Status',
        'Resolution Notes',
        'Resolved By',
        'Resolved At',
      ];

      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      for (final inc in incidents) {
        sheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(inc.createdAt)),
          TextCellValue(inc.examName),
          TextCellValue(inc.centerName),
          TextCellValue(inc.room),
          TextCellValue(inc.typeDisplayName),
          TextCellValue(inc.severity.toUpperCase()),
          TextCellValue(inc.title),
          TextCellValue(inc.description),
          TextCellValue(inc.reporterName),
          TextCellValue(inc.reporterRole),
          TextCellValue(inc.reporterMobile),
          TextCellValue(inc.status.toUpperCase()),
          TextCellValue(inc.resolutionNotes ?? '-'),
          TextCellValue(inc.resolvedBy ?? '-'),
          TextCellValue(inc.resolvedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(inc.resolvedAt!) : '-'),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel encoding failed.');

      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/IncidentLogReport_$timestamp.xlsx');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          subject: 'DutyDesk Incident Log Excel Export',
          text: 'DutyDesk Incident Log — $filterDescription',
        ),
      );
    } catch (e) {
      log('Incident Excel export failed: $e');
      rethrow;
    }
  }
}

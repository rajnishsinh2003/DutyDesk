import 'dart:io';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
      final pdf = pw.Document();

      // Use built-in PDF fonts (no asset download needed)
      final baseFont = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      // Build rows
      final rows = duties.map((duty) {
        final inv = invigilators.firstWhere(
          (i) => i.id == duty.invigilatorId,
          orElse: () => Invigilator(id: '', name: 'Unknown', resourceId: '-', mobile: '', mockDutyCount: 0),
        );
        return [
          duty.examName,
          duty.date,
          duty.centerName,
          inv.name,
          inv.resourceId,
          duty.role.toUpperCase(),
          'Shift ${duty.shift}',
          duty.payment,
          duty.lunch,
          duty.status.toUpperCase(),
        ];
      }).toList();

      final headers = [
        'Exam', 'Date', 'Center', 'Name', 'Resource ID',
        'Role', 'Shift', 'Payment', 'Lunch', 'Status',
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DutyDesk — Duty Report',
                  style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.blueGrey900),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Filter: $filterDescription   |   Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.2),
                    1: const pw.FlexColumnWidth(1.4),
                    2: const pw.FlexColumnWidth(1.6),
                    3: const pw.FlexColumnWidth(1.8),
                    4: const pw.FlexColumnWidth(1.4),
                    5: const pw.FlexColumnWidth(1.2),
                    6: const pw.FlexColumnWidth(1.0),
                    7: const pw.FlexColumnWidth(1.2),
                    8: const pw.FlexColumnWidth(1.0),
                    9: const pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                      children: headers.map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
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
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: pw.Text(cell,
                            style: pw.TextStyle(font: baseFont, fontSize: 7.5),
                          ),
                        )).toList(),
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Total Records: ${duties.length}',
                  style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.blueGrey700),
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/DutyReport_$timestamp.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'DutyDesk Report',
          text: 'DutyDesk Duty Report — $filterDescription',
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
      final excel = Excel.createExcel();
      final sheet = excel['DutyReport'];

      // Header row styling
      final headers = [
        'Exam Name', 'Date', 'Center', 'Invigilator Name',
        'Resource ID', 'Role', 'Shift', 'Payment', 'Lunch', 'Status',
      ];

      final headerStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        horizontalAlign: HorizontalAlign.Center,
      );

      // Write headers
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Write data rows
      for (var rIdx = 0; rIdx < duties.length; rIdx++) {
        final duty = duties[rIdx];
        final inv = invigilators.firstWhere(
          (i) => i.id == duty.invigilatorId,
          orElse: () => Invigilator(id: '', name: 'Unknown', resourceId: '-', mobile: '', mockDutyCount: 0),
        );

        final rowData = [
          duty.examName, duty.date, duty.centerName, inv.name,
          inv.resourceId, duty.role.toUpperCase(),
          'Shift ${duty.shift}', duty.payment, duty.lunch, duty.status.toUpperCase(),
        ];

        final rowBg = rIdx.isEven
            ? ExcelColor.fromHexString('#F0F4F8')
            : ExcelColor.fromHexString('#FFFFFF');

        for (var cIdx = 0; cIdx < rowData.length; cIdx++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: cIdx, rowIndex: rIdx + 1));
          cell.value = TextCellValue(rowData[cIdx]);
          cell.cellStyle = CellStyle(backgroundColorHex: rowBg);
        }
      }

      // Auto-width approximation
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      // Summary row
      final summaryRowIdx = duties.length + 2;
      final summaryCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIdx));
      summaryCell.value = TextCellValue('Total: ${duties.length} records | Filter: $filterDescription | Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}');
      summaryCell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#1E3A5F'),
      );

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Excel save returned null');

      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/DutyReport_$timestamp.xlsx');
      await file.writeAsBytes(fileBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          subject: 'DutyDesk Excel Report',
          text: 'DutyDesk Duty Report — $filterDescription',
        ),
      );
    } catch (e) {
      log('Excel generation failed: $e');
      rethrow;
    }
  }
}

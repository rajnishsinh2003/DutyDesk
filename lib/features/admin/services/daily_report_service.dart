import 'dart:io';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';

class DailyReportService {
  static Future<void> exportPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    try {
      if (data.isEmpty) {
        throw Exception('No records available to export.');
      }

      final pdf = pw.Document();

      final baseFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      final generatedAt = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DutyDesk — $title Report',
                style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blueGrey900),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated: $generatedAt   |   Total Records: ${data.length}',
                style: pw.TextStyle(font: baseFont, fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Divider(color: PdfColors.blueGrey200, thickness: 0.5),
              pw.SizedBox(height: 4),
            ],
          ),
          footer: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'DutyDesk — Confidential',
                style: pw.TextStyle(font: baseFont, fontSize: 7, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(font: baseFont, fontSize: 7, color: PdfColors.grey500),
              ),
            ],
          ),
          // Key fix: TableHelper.fromTextArray is a DIRECT child of MultiPage
          // so it can auto-paginate large datasets without hanging.
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              cellStyle: pw.TextStyle(font: baseFont, fontSize: 7.5),
              oddCellStyle: pw.TextStyle(font: baseFont, fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              cellAlignments: {
                for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
              },
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final safeTitle = title.replaceAll(' ', '');
      final file = File('${dir.path}/${safeTitle}_Report_$timestamp.pdf');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: '$title Report',
          text: 'DutyDesk $title Report',
        ),
      );
    } catch (e) {
      log('PDF generation failed: $e');
      rethrow;
    }
  }

  static Future<void> exportExcel({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    try {
      if (data.isEmpty) {
        throw Exception('No records available to export.');
      }

      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Report');
      final sheet = excel['Report'];

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
      for (var rIdx = 0; rIdx < data.length; rIdx++) {
        final rowData = data[rIdx];
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

      final summaryRowIdx = data.length + 2;
      final summaryCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIdx));
      summaryCell.value = TextCellValue('Total: ${data.length} records | Generated: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}');
      summaryCell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#1E3A5F'),
      );

      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Excel save returned null');

      final dir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final safeTitle = title.replaceAll(' ', '');
      final file = File('${dir.path}/${safeTitle}_Report_$timestamp.xlsx');
      await file.writeAsBytes(fileBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          subject: '$title Excel Report',
          text: 'DutyDesk $title Report',
        ),
      );
    } catch (e) {
      log('Excel generation failed: $e');
      rethrow;
    }
  }
}

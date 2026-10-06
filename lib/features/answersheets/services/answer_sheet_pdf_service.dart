import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/answer_sheet_bundle_model.dart';

class AnswerSheetPdfService {
  /// Generate and print official Bundle Docket Slip (Form B) to affix to the cloth envelope
  static Future<void> printBundleDocket(AnswerSheetBundle bundle) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo900,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'DUTYDESK EXAMINATION CONTROL BOARD',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ANSWER SCRIPT BUNDLE DOCKET (FORM B)',
                        style: pw.TextStyle(
                          color: PdfColors.amber,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'AFFIX FIRMLY TO THE SEALED CLOTH / PLASTIC ENVELOPE',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // Key identifiers
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BUNDLE CODE: ${bundle.bundleCode}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                        pw.Text('EXAM: ${bundle.examName}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('SUBJECT: ${bundle.subjectCode} - ${bundle.subjectName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('SEAL NO: ${bundle.securitySealNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.red900)),
                        pw.Text('DATE: ${bundle.date} (${bundle.shift})', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('ROOM: ${bundle.roomName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),

                // Center
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: PdfColors.grey200,
                  child: pw.Text(
                    'CENTER: ${bundle.centerName.toUpperCase()}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 14),

                // Script Reconciliation Table
                pw.Text('SCRIPT RECONCILIATION SUMMARY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        _buildTableHeader('Category'),
                        _buildTableHeader('Count (Numbers)'),
                        _buildTableHeader('Status Verification'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableCell('1. Candidates Allotted (Registered)'),
                        _buildTableCell('${bundle.registeredCandidates}', isBold: true),
                        _buildTableCell('Master Seating Roster'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableCell('2. Candidates Present (Scripts Collected)'),
                        _buildTableCell('${bundle.collectedScriptCount}', isBold: true),
                        _buildTableCell('Enclosed in this bundle'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableCell('3. Candidates Absent'),
                        _buildTableCell('${bundle.absentCount}', isBold: true),
                        _buildTableCell(bundle.absentCount > 0 ? 'Verified against Hall attendance' : 'NIL'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _buildTableCell('4. Blank Answer Sheets Returned'),
                        _buildTableCell('${bundle.unusedBlankSheetsReturned}', isBold: true),
                        _buildTableCell('Returned to Control Room'),
                      ],
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildTableCell('Reconciliation Check (Present + Absent)', isBold: true),
                        _buildTableCell(
                          '${bundle.presentCount + bundle.absentCount} / ${bundle.registeredCandidates}',
                          isBold: true,
                        ),
                        _buildTableCell(
                          bundle.isBalanced ? 'BALANCED OK (100% MATCH)' : 'MISMATCH DETECTED',
                          isBold: true,
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Absentee Roll Numbers Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey600),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ABSENTEE ROLL NUMBERS (${bundle.absentRollNumbers.length}):',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red900),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        bundle.absentRollNumbers.isEmpty
                            ? 'NONE (All candidates present)'
                            : bundle.absentRollNumbers.join(', '),
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Statutory Certification
                pw.Text(
                  'STATUTORY CERTIFICATION BY ROOM INVIGILATOR:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'I hereby certify that the examination for the above subject was conducted strictly in accordance with statutory guidelines. The number of scripts enclosed in this envelope (${bundle.collectedScriptCount}) exactly matches the present candidates. The absent candidates were cross-verified on the attendance sheet and marked in red.',
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.SizedBox(height: 36),

                // Signatures row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 180, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('Signature of Room Invigilator', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.Text('Name: ${bundle.invigilatorName}', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.Text('Staff ID: ${bundle.invigilatorId}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(width: 180, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text('Center Superintendent Seal & Sign', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.Text(bundle.superintendentName ?? 'Center Superintendent', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.Text('Received Date: ___________________', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),

                // Barcode indicator
                pw.Center(
                  child: pw.Text(
                    '* * * ${bundle.bundleCode} * * *',
                    style: pw.TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Docket_Slip_${bundle.bundleCode}.pdf',
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }
}

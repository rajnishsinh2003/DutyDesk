import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/room_model.dart';
import '../../admin/providers/center_provider.dart';

class CenterReadinessPdfService {
  static Future<void> generateAndPrintCertificate({
    required ExamCenter center,
    required ExamCenterReadiness report,
    required List<ExamRoom> rooms,
  }) async {
    final pdf = pw.Document();

    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final totalCapacity = rooms.fold<int>(0, (sum, r) => sum + r.capacity);
    final totalComputers = rooms.fold<int>(0, (sum, r) => sum + r.computerCount);
    final totalInvigilators = rooms.fold<int>(0, (sum, r) => sum + r.invigilatorRequired);

    final checklistItems = [
      {'title': 'Power Backup (Generator / Online UPS)', 'ready': report.powerBackupReady, 'desc': 'Uninterrupted power supply tested under full load.'},
      {'title': 'CCTV Surveillance & Digital Video Recording', 'ready': report.cctvOperational, 'desc': 'All exam halls & corridors covered with DVR recording active.'},
      {'title': 'Mobile Signal Jammers Operational', 'ready': report.jammersOperational, 'desc': 'Frequency suppression tested within exam perimeter.'},
      {'title': 'Strong Room & Confidential Storage Secured', 'ready': report.strongRoomSecured, 'desc': 'Double-lock custody room verified and guarded.'},
      {'title': 'Drinking Water & Restroom Sanitation', 'ready': report.waterSanitationReady, 'desc': 'Purified water stations and hygienic restrooms confirmed.'},
      {'title': 'Standard Time Clocks Synchronized', 'ready': report.clockSyncVerified, 'desc': 'All room wall clocks synchronized to Indian Standard Time (IST).'},
      {'title': 'First Aid & Emergency Medical Support', 'ready': report.firstAidReady, 'desc': 'Medical kit and nursing assistant stationed at center.'},
      {'title': 'Security & Frisking Booths at Entrance', 'ready': report.securityFriskingReady, 'desc': 'Separate gender booths with hand-held metal detectors (HHMD).'},
      {'title': 'Room Seating Plan & Roll Numbers Pasted', 'ready': report.seatingPlanPasted, 'desc': 'Seating lists displayed at main gate and room entrance doors.'},
      {'title': 'Computer Systems & LAN Network Tested (CBT)', 'ready': report.computersTested, 'desc': 'Exam terminals, browser lockdown, and local servers verified.'},
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#007A87'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DutyDesk Examination Authority',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 18, font: boldFont),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'OFFICIAL CENTER READINESS & COMPLIANCE CERTIFICATE',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: report.isFullyCompliant ? PdfColor.fromHex('#10B981') : PdfColor.fromHex('#F59E0B'),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        report.isFullyCompliant ? '100% COMPLIANT' : '${report.completionPercentage.toInt()}% VERIFIED',
                        style: pw.TextStyle(color: PdfColors.white, font: boldFont, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Center & Exam Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Center: ${center.name}', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                        pw.SizedBox(height: 2),
                        pw.Text('Location: ${center.location}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text('Audit Date: ${report.examDate.isNotEmpty ? report.examDate : DateFormat('yyyy-MM-dd').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Exam: ${report.examName}', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                        pw.SizedBox(height: 2),
                        pw.Text('Inspector: ${report.inspectorName}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 2),
                        pw.Text('Rooms: ${rooms.length} | Seats: $totalCapacity | PCs: $totalComputers | Staff: $totalInvigilators', style: pw.TextStyle(fontSize: 10, font: boldFont, color: PdfColor.fromHex('#007A87'))),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Checklist Section Title
              pw.Text('Mandatory Exam-Day Infrastructure Audit Items', style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColor.fromHex('#0F172A'))),
              pw.SizedBox(height: 6),

              // Checklist Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8),
                  1: const pw.FlexColumnWidth(3.5),
                  2: const pw.FlexColumnWidth(4.5),
                  3: const pw.FlexColumnWidth(1.6),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('#', style: pw.TextStyle(font: boldFont, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Compliance Parameter', style: pw.TextStyle(font: boldFont, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Audit Specification', style: pw.TextStyle(font: boldFont, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Audit Status', style: pw.TextStyle(font: boldFont, fontSize: 9))),
                    ],
                  ),
                  ...checklistItems.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final item = entry.value;
                    final isReady = item['ready'] as bool;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['title'] as String, style: pw.TextStyle(font: boldFont, fontSize: 8.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item['desc'] as String, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            isReady ? 'PASSED / READY' : 'PENDING',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8.5,
                              color: isReady ? PdfColor.fromHex('#059669') : PdfColor.fromHex('#DC2626'),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),

              // General Remarks (if any)
              if (report.generalRemarks != null && report.generalRemarks!.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8FAFC'),
                    border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Auditor Remarks / Action Plan:', style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      pw.SizedBox(height: 2),
                      pw.Text(report.generalRemarks!, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],

              // Signatures
              pw.Spacer(),
              pw.Divider(color: PdfColor.fromHex('#CBD5E1')),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('_________________________________', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Center Superintendent / Principal', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                      pw.Text(center.name, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('_________________________________', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('Chief Examination Observer / Auditor', style: pw.TextStyle(font: boldFont, fontSize: 10)),
                      pw.Text('DutyDesk Central Exam Commission', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Readiness_Certificate_${center.name.replaceAll(' ', '_')}.pdf',
    );
  }
}

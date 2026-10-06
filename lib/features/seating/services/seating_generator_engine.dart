import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/seating_plan_model.dart';

class StudentCandidate {
  final String rollNumber;
  final String name;
  final String branch;

  const StudentCandidate({
    required this.rollNumber,
    required this.name,
    required this.branch,
  });
}

class SeatingGeneratorEngine {
  /// Generate a sample pool of student candidates for demonstration & quick testing
  static List<StudentCandidate> generateSampleCandidates({
    int cseCount = 20,
    int eceCount = 18,
    int meCount = 12,
  }) {
    final list = <StudentCandidate>[];

    final cseNames = [
      'Aarav Sharma', 'Aditi Verma', 'Akash Patel', 'Ananya Gupta', 'Aryan Singh',
      'Diya Nair', 'Ishaan Kumar', 'Kavya Joshi', 'Manish Reddy', 'Neha Choudhary',
      'Pooja Mishra', 'Rahul Iyer', 'Riya Sen', 'Rohan Das', 'Saanvi Rao',
      'Sahil Malhotra', 'Shreya Pillai', 'Tanvi Desai', 'Varun Bhat', 'Yash Mehra'
    ];

    final eceNames = [
      'Abhishek Roy', 'Bhavna Menon', 'Chetan Shah', 'Devika Pillai', 'Gaurav Kulkarni',
      'Harshita Jain', 'Kunal Tiwari', 'Meera Kapoor', 'Nikhil Bajaj', 'Pallavi Sen',
      'Pranav Saxena', 'Priyanka Bose', 'Rishabh Dixit', 'Sneha Nambiar', 'Siddharth Varma',
      'Tarun Ghosh', 'Urvashi Som', 'Vikas Pandey'
    ];

    final meNames = [
      'Aditya Thakur', 'Deepak Chauhan', 'Karan Singhania', 'Mayank Agarwal', 'Mohit Rawat',
      'Naveen Dubey', 'Parth Trivedi', 'Rajesh Yadav', 'Sachin Shinde', 'Sumit Negi',
      'Utkarsh Dixit', 'Vivek Rana'
    ];

    for (int i = 0; i < cseCount; i++) {
      final name = i < cseNames.length ? cseNames[i] : 'CSE Student ${i + 1}';
      final roll = '23CSE${(101 + i).toString().padLeft(3, '0')}';
      list.add(StudentCandidate(rollNumber: roll, name: name, branch: 'CSE'));
    }

    for (int i = 0; i < eceCount; i++) {
      final name = i < eceNames.length ? eceNames[i] : 'ECE Student ${i + 1}';
      final roll = '23ECE${(201 + i).toString().padLeft(3, '0')}';
      list.add(StudentCandidate(rollNumber: roll, name: name, branch: 'ECE'));
    }

    for (int i = 0; i < meCount; i++) {
      final name = i < meNames.length ? meNames[i] : 'ME Student ${i + 1}';
      final roll = '23ME${(301 + i).toString().padLeft(3, '0')}';
      list.add(StudentCandidate(rollNumber: roll, name: name, branch: 'ME'));
    }

    return list;
  }

  /// Automatically generate a SeatingPlan grid according to the chosen anti-cheating strategy
  static SeatingPlan generatePlan({
    required String examName,
    required String sessionOrShift,
    required String date,
    required String centerName,
    required String roomName,
    required int rows,
    required int columns,
    required AntiCheatingStrategy strategy,
    required List<StudentCandidate> candidates,
    int bufferSeatCount = 2,
  }) {
    final List<StudentSeat> seats = [];

    // Separate candidates by branch
    final Map<String, List<StudentCandidate>> branchBuckets = {};
    for (final c in candidates) {
      branchBuckets.putIfAbsent(c.branch, () => []).add(c);
    }
    final branchKeys = branchBuckets.keys.toList();

    // Determine buffer seats (placed at the last row, or corners)
    final Set<String> bufferDeskCoords = {};
    int buffersPlaced = 0;
    for (int r = rows - 1; r >= 0 && buffersPlaced < bufferSeatCount; r--) {
      for (int c = columns - 1; c >= 0 && buffersPlaced < bufferSeatCount; c--) {
        bufferDeskCoords.add('$r-$c');
        buffersPlaced++;
      }
    }

    // Pointers for each branch bucket
    final Map<String, int> bucketPointers = {for (var k in branchKeys) k: 0};

    // Strategy 1: Alternating Branches (Column-by-column alternating branch)
    if (strategy == AntiCheatingStrategy.alternatingBranches && branchKeys.isNotEmpty) {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < columns; c++) {
          final deskLabel = 'R${r + 1}-C${c + 1}';
          final coordKey = '$r-$c';

          if (bufferDeskCoords.contains(coordKey)) {
            seats.add(StudentSeat(
              row: r,
              col: c,
              deskLabel: deskLabel,
              status: SeatStatus.buffer,
            ));
            continue;
          }

          // Pick branch by column & row offset to create a checkerboard pattern across branches
          final branchIndex = (c + (r % 2)) % branchKeys.length;
          final targetBranch = branchKeys[branchIndex];
          final ptr = bucketPointers[targetBranch] ?? 0;
          final bucket = branchBuckets[targetBranch] ?? [];

          if (ptr < bucket.length) {
            final student = bucket[ptr];
            bucketPointers[targetBranch] = ptr + 1;
            seats.add(StudentSeat(
              row: r,
              col: c,
              deskLabel: deskLabel,
              studentRoll: student.rollNumber,
              studentName: student.name,
              branchOrSubject: student.branch,
              status: SeatStatus.allocated,
            ));
          } else {
            // If primary branch exhausted, try any other available candidate
            StudentCandidate? fallbackCandidate;
            for (final k in branchKeys) {
              final p = bucketPointers[k] ?? 0;
              final b = branchBuckets[k] ?? [];
              if (p < b.length) {
                fallbackCandidate = b[p];
                bucketPointers[k] = p + 1;
                break;
              }
            }

            if (fallbackCandidate != null) {
              seats.add(StudentSeat(
                row: r,
                col: c,
                deskLabel: deskLabel,
                studentRoll: fallbackCandidate.rollNumber,
                studentName: fallbackCandidate.name,
                branchOrSubject: fallbackCandidate.branch,
                status: SeatStatus.allocated,
              ));
            } else {
              seats.add(StudentSeat(
                row: r,
                col: c,
                deskLabel: deskLabel,
                status: SeatStatus.vacant,
              ));
            }
          }
        }
      }
    }
    // Strategy 2: Checkerboard spacing (50% vacant seats)
    else if (strategy == AntiCheatingStrategy.checkerboard) {
      int candIdx = 0;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < columns; c++) {
          final deskLabel = 'R${r + 1}-C${c + 1}';
          final coordKey = '$r-$c';

          if (bufferDeskCoords.contains(coordKey)) {
            seats.add(StudentSeat(
              row: r,
              col: c,
              deskLabel: deskLabel,
              status: SeatStatus.buffer,
            ));
            continue;
          }

          // In checkerboard, only even (row + col) seats get a student
          final isSeatActive = (r + c) % 2 == 0;
          if (isSeatActive && candIdx < candidates.length) {
            final student = candidates[candIdx++];
            seats.add(StudentSeat(
              row: r,
              col: c,
              deskLabel: deskLabel,
              studentRoll: student.rollNumber,
              studentName: student.name,
              branchOrSubject: student.branch,
              status: SeatStatus.allocated,
            ));
          } else {
            seats.add(StudentSeat(
              row: r,
              col: c,
              deskLabel: deskLabel,
              status: SeatStatus.vacant,
            ));
          }
        }
      }
    }
    // Strategy 3: Standard Consecutive Sequential
    else {
      int candIdx = 0;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < columns; c++) {
          final deskLabel = 'R${r + 1}-C${c + 1}';
          final coordKey = '$r-$c';

          if (bufferDeskCoords.contains(coordKey)) {
            seats.add(StudentSeat(
              row: r,
              col: c,
              deskLabel: deskLabel,
              status: SeatStatus.buffer,
            ));
            continue;
          }

          if (candIdx < candidates.length) {
            final student = candidates[candIdx++];
            seats.add(StudentSeat(
              row: r,
              col: c,
              deskLabel: deskLabel,
              studentRoll: student.rollNumber,
              studentName: student.name,
              branchOrSubject: student.branch,
              status: SeatStatus.allocated,
            ));
          } else {
            seats.add(StudentSeat(
              row: r,
              col: c,
              deskLabel: deskLabel,
              status: SeatStatus.vacant,
            ));
          }
        }
      }
    }

    return SeatingPlan(
      id: 'PLAN_${DateTime.now().millisecondsSinceEpoch}',
      examName: examName,
      sessionOrShift: sessionOrShift,
      date: date,
      centerName: centerName,
      roomName: roomName,
      rows: rows,
      columns: columns,
      strategy: strategy,
      seats: seats,
      createdAt: DateTime.now(),
    );
  }

  /// Export Seating Plan as a high-resolution, printable PDF Door Chart
  static Future<void> printOrSharePdf(SeatingPlan plan) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo900,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DUTYDESK EXAMINATION CONTROL - SEATING NOTICE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${plan.examName} • Date: ${plan.date} • ${plan.sessionOrShift}',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ROOM: ${plan.roomName.toUpperCase()}',
                          style: pw.TextStyle(
                            color: PdfColors.amber,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          plan.centerName,
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Summary Bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: PdfColors.grey200,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Capacity: ${plan.totalCapacity}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Allocated: ${plan.allocatedCount}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Vacant: ${plan.vacantCount}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Buffer Desks: ${plan.bufferCount}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Strategy: ${plan.strategy.name}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Visual Desk Grid
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  children: [
                    for (int r = 0; r < plan.rows; r++)
                      pw.TableRow(
                        children: [
                          for (int c = 0; c < plan.columns; c++)
                            _buildPdfDeskCell(plan.seats.firstWhere(
                              (s) => s.row == r && s.col == c,
                              orElse: () => StudentSeat(row: r, col: c, deskLabel: 'R${r+1}-C${c+1}'),
                            )),
                        ],
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invigilator Sign: _____________________', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Generated by DutyDesk Seating Engine on ${DateTime.now().toLocal().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Seating_Plan_${plan.roomName}_${plan.date}.pdf',
    );
  }

  static pw.Widget _buildPdfDeskCell(StudentSeat seat) {
    PdfColor bgColor = PdfColors.white;
    if (seat.status == SeatStatus.buffer) bgColor = PdfColors.orange100;
    if (seat.status == SeatStatus.vacant) bgColor = PdfColors.grey100;
    if (seat.status == SeatStatus.blocked) bgColor = PdfColors.red100;

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      color: bgColor,
      height: 48,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            seat.deskLabel,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
          ),
          if (seat.status == SeatStatus.allocated && seat.studentRoll != null) ...[
            pw.Text(
              seat.studentRoll!,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              seat.branchOrSubject ?? '',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey800),
            ),
          ] else ...[
            pw.Text(
              seat.status.name.toUpperCase(),
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  /// Export plan to CSV format for Excel/attendance rosters
  static String exportToCsv(SeatingPlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('Desk,Roll Number,Student Name,Branch/Subject,Status,Room,Exam,Date,Shift');

    for (final s in plan.seats) {
      buffer.writeln(
        '${s.deskLabel},'
        '${s.studentRoll ?? ""},'
        '"${s.studentName ?? ""}",'
        '${s.branchOrSubject ?? ""},'
        '${s.status.name},'
        '"${plan.roomName}",'
        '"${plan.examName}",'
        '${plan.date},'
        '"${plan.sessionOrShift}"'
      );
    }

    return buffer.toString();
  }
}

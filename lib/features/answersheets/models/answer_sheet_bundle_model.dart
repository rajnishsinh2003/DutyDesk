import 'package:cloud_firestore/cloud_firestore.dart';

enum BundleStatus {
  draft,                    // Being reconciled in exam hall
  reconciledAndSealed,      // Counts verified and cloth bag sealed
  handedToSuperintendent,   // Received at Center Control Room
  dispatchedToEvaluation,   // Handed to university courier / evaluation camp
  countMismatch,            // Discrepancy: missing or excess scripts detected
}

class BundleCustodyEvent {
  final String stage;
  final String actorName;
  final String actorRole;
  final DateTime timestamp;
  final String? notes;

  const BundleCustodyEvent({
    required this.stage,
    required this.actorName,
    required this.actorRole,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'stage': stage,
    'actorName': actorName,
    'actorRole': actorRole,
    'timestamp': Timestamp.fromDate(timestamp),
    'notes': notes,
  };

  factory BundleCustodyEvent.fromMap(Map<String, dynamic> map) {
    DateTime time = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    }
    return BundleCustodyEvent(
      stage: map['stage'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      actorRole: map['actorRole'] as String? ?? '',
      timestamp: time,
      notes: map['notes'] as String?,
    );
  }
}

class AnswerSheetBundle {
  final String id;
  final String bundleCode;            // e.g. "ANS-2026-CS301-B01"
  final String securitySealNumber;    // Tamper-evident bag / wax seal #
  final String examName;
  final String subjectCode;
  final String subjectName;
  final String centerName;
  final String roomName;
  final String date;                  // YYYY-MM-DD
  final String shift;                 // Shift 1, Shift 2
  final int registeredCandidates;     // Total candidates allotted (e.g. 30)
  final int presentCount;             // Candidates present (e.g. 28)
  final int absentCount;              // Candidates absent (e.g. 2)
  final int collectedScriptCount;     // Physical answer sheets collected (e.g. 28)
  final int unusedBlankSheetsReturned;// Blank answer sheets returned to control room
  final List<String> absentRollNumbers; // e.g. ["23CS105", "23CS119"]
  final BundleStatus status;
  final String invigilatorId;
  final String invigilatorName;
  final String? superintendentName;
  final String? courierConsignmentNumber;
  final List<BundleCustodyEvent> custodyLog;
  final String? discrepancyRemarks;
  final DateTime createdAt;

  const AnswerSheetBundle({
    required this.id,
    required this.bundleCode,
    required this.securitySealNumber,
    required this.examName,
    required this.subjectCode,
    required this.subjectName,
    required this.centerName,
    required this.roomName,
    required this.date,
    required this.shift,
    required this.registeredCandidates,
    required this.presentCount,
    required this.absentCount,
    required this.collectedScriptCount,
    required this.unusedBlankSheetsReturned,
    this.absentRollNumbers = const [],
    this.status = BundleStatus.draft,
    required this.invigilatorId,
    required this.invigilatorName,
    this.superintendentName,
    this.courierConsignmentNumber,
    this.custodyLog = const [],
    this.discrepancyRemarks,
    required this.createdAt,
  });

  /// Check reconciliation: Total registered must equal present + absent,
  /// and present must match collected scripts.
  bool get isBalanced =>
      (presentCount + absentCount == registeredCandidates) &&
      (presentCount == collectedScriptCount);

  int get balanceDiscrepancy =>
      collectedScriptCount - (registeredCandidates - absentCount);

  AnswerSheetBundle copyWith({
    String? id,
    String? bundleCode,
    String? securitySealNumber,
    String? examName,
    String? subjectCode,
    String? subjectName,
    String? centerName,
    String? roomName,
    String? date,
    String? shift,
    int? registeredCandidates,
    int? presentCount,
    int? absentCount,
    int? collectedScriptCount,
    int? unusedBlankSheetsReturned,
    List<String>? absentRollNumbers,
    BundleStatus? status,
    String? invigilatorId,
    String? invigilatorName,
    String? superintendentName,
    String? courierConsignmentNumber,
    List<BundleCustodyEvent>? custodyLog,
    String? discrepancyRemarks,
    DateTime? createdAt,
  }) {
    return AnswerSheetBundle(
      id: id ?? this.id,
      bundleCode: bundleCode ?? this.bundleCode,
      securitySealNumber: securitySealNumber ?? this.securitySealNumber,
      examName: examName ?? this.examName,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      centerName: centerName ?? this.centerName,
      roomName: roomName ?? this.roomName,
      date: date ?? this.date,
      shift: shift ?? this.shift,
      registeredCandidates: registeredCandidates ?? this.registeredCandidates,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      collectedScriptCount: collectedScriptCount ?? this.collectedScriptCount,
      unusedBlankSheetsReturned: unusedBlankSheetsReturned ?? this.unusedBlankSheetsReturned,
      absentRollNumbers: absentRollNumbers ?? this.absentRollNumbers,
      status: status ?? this.status,
      invigilatorId: invigilatorId ?? this.invigilatorId,
      invigilatorName: invigilatorName ?? this.invigilatorName,
      superintendentName: superintendentName ?? this.superintendentName,
      courierConsignmentNumber: courierConsignmentNumber ?? this.courierConsignmentNumber,
      custodyLog: custodyLog ?? this.custodyLog,
      discrepancyRemarks: discrepancyRemarks ?? this.discrepancyRemarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'bundleCode': bundleCode,
    'securitySealNumber': securitySealNumber,
    'examName': examName,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'centerName': centerName,
    'roomName': roomName,
    'date': date,
    'shift': shift,
    'registeredCandidates': registeredCandidates,
    'presentCount': presentCount,
    'absentCount': absentCount,
    'collectedScriptCount': collectedScriptCount,
    'unusedBlankSheetsReturned': unusedBlankSheetsReturned,
    'absentRollNumbers': absentRollNumbers,
    'status': status.name,
    'invigilatorId': invigilatorId,
    'invigilatorName': invigilatorName,
    'superintendentName': superintendentName,
    'courierConsignmentNumber': courierConsignmentNumber,
    'custodyLog': custodyLog.map((c) => c.toMap()).toList(),
    'discrepancyRemarks': discrepancyRemarks,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory AnswerSheetBundle.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }

    final rawCustody = (data['custodyLog'] as List<dynamic>? ?? []);
    final custodyList = rawCustody
        .map((c) => BundleCustodyEvent.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList();

    final rawAbsentees = (data['absentRollNumbers'] as List<dynamic>? ?? []);
    final absentList = rawAbsentees.map((e) => e.toString()).toList();

    return AnswerSheetBundle(
      id: id,
      bundleCode: data['bundleCode'] as String? ?? 'ANS-001',
      securitySealNumber: data['securitySealNumber'] as String? ?? 'SEAL-000',
      examName: data['examName'] as String? ?? 'Semester Examination',
      subjectCode: data['subjectCode'] as String? ?? 'CS301',
      subjectName: data['subjectName'] as String? ?? 'Data Structures',
      centerName: data['centerName'] as String? ?? 'Main Center',
      roomName: data['roomName'] as String? ?? 'Hall 101',
      date: data['date'] as String? ?? '',
      shift: data['shift'] as String? ?? 'Shift 1',
      registeredCandidates: data['registeredCandidates'] as int? ?? 30,
      presentCount: data['presentCount'] as int? ?? 28,
      absentCount: data['absentCount'] as int? ?? 2,
      collectedScriptCount: data['collectedScriptCount'] as int? ?? 28,
      unusedBlankSheetsReturned: data['unusedBlankSheetsReturned'] as int? ?? 2,
      absentRollNumbers: absentList,
      status: BundleStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => BundleStatus.draft,
      ),
      invigilatorId: data['invigilatorId'] as String? ?? 'INV-01',
      invigilatorName: data['invigilatorName'] as String? ?? 'Invigilator',
      superintendentName: data['superintendentName'] as String?,
      courierConsignmentNumber: data['courierConsignmentNumber'] as String?,
      custodyLog: custodyList,
      discrepancyRemarks: data['discrepancyRemarks'] as String?,
      createdAt: created,
    );
  }
}

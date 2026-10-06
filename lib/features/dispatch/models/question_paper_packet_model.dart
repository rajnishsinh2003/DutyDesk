import 'package:cloud_firestore/cloud_firestore.dart';

enum PacketStatus {
  inStrongroom,             // Stored securely in vault/safe
  dispatchedFromStrongroom, // Released by Custodian / Center Superintendent
  receivedByInvigilator,    // Acknowledged and received by room invigilator
  sealVerified,             // Physical seal checked & verified by invigilator + witnesses
  opened,                   // Packet opened at authorized time-lock window
  tampered,                 // Security alert: seal broken, packet damaged, or count mismatch
}

class StudentWitness {
  final String name;
  final String rollNumber;
  final DateTime witnessedAt;

  const StudentWitness({
    required this.name,
    required this.rollNumber,
    required this.witnessedAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'rollNumber': rollNumber,
    'witnessedAt': Timestamp.fromDate(witnessedAt),
  };

  factory StudentWitness.fromMap(Map<String, dynamic> map) {
    DateTime time = DateTime.now();
    if (map['witnessedAt'] is Timestamp) {
      time = (map['witnessedAt'] as Timestamp).toDate();
    }
    return StudentWitness(
      name: map['name'] as String? ?? '',
      rollNumber: map['rollNumber'] as String? ?? '',
      witnessedAt: time,
    );
  }
}

class CustodyEvent {
  final String stage;
  final String actorName;
  final String actorRole;
  final DateTime timestamp;
  final String? notes;

  const CustodyEvent({
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

  factory CustodyEvent.fromMap(Map<String, dynamic> map) {
    DateTime time = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      time = (map['timestamp'] as Timestamp).toDate();
    }
    return CustodyEvent(
      stage: map['stage'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      actorRole: map['actorRole'] as String? ?? '',
      timestamp: time,
      notes: map['notes'] as String?,
    );
  }
}

class QuestionPaperPacket {
  final String id;
  final String packetCode;        // e.g., "QP-2026-CS301-B01"
  final String securitySealNumber;// Tamper-evident hologram bag barcode
  final String examName;
  final String subjectCode;
  final String subjectName;
  final String centerName;
  final String roomName;
  final String date;              // YYYY-MM-DD
  final String shift;             // Shift 1, Shift 2
  final int bookletCount;         // Number of question papers enclosed (e.g. 30)
  final DateTime unlockWindowStart; // Earliest allowed time to unseal (e.g. 09:15 AM)
  final DateTime unlockWindowEnd;   // Latest allowed unseal time (e.g. 09:35 AM)
  final PacketStatus status;
  final String? custodianId;
  final String? custodianName;
  final String? assignedInvigilatorId;
  final String? assignedInvigilatorName;
  final List<StudentWitness> witnesses;
  final List<CustodyEvent> custodyLog;
  final DateTime? openedAt;
  final String? tamperRemarks;
  final DateTime createdAt;

  const QuestionPaperPacket({
    required this.id,
    required this.packetCode,
    required this.securitySealNumber,
    required this.examName,
    required this.subjectCode,
    required this.subjectName,
    required this.centerName,
    required this.roomName,
    required this.date,
    required this.shift,
    required this.bookletCount,
    required this.unlockWindowStart,
    required this.unlockWindowEnd,
    this.status = PacketStatus.inStrongroom,
    this.custodianId,
    this.custodianName,
    this.assignedInvigilatorId,
    this.assignedInvigilatorName,
    this.witnesses = const [],
    this.custodyLog = const [],
    this.openedAt,
    this.tamperRemarks,
    required this.createdAt,
  });

  bool get isTimeLocked => DateTime.now().isBefore(unlockWindowStart);
  bool get isWithinUnsealWindow {
    final now = DateTime.now();
    return now.isAfter(unlockWindowStart) && now.isBefore(unlockWindowEnd);
  }
  bool get isPastUnsealWindow => DateTime.now().isAfter(unlockWindowEnd);

  QuestionPaperPacket copyWith({
    String? id,
    String? packetCode,
    String? securitySealNumber,
    String? examName,
    String? subjectCode,
    String? subjectName,
    String? centerName,
    String? roomName,
    String? date,
    String? shift,
    int? bookletCount,
    DateTime? unlockWindowStart,
    DateTime? unlockWindowEnd,
    PacketStatus? status,
    String? custodianId,
    String? custodianName,
    String? assignedInvigilatorId,
    String? assignedInvigilatorName,
    List<StudentWitness>? witnesses,
    List<CustodyEvent>? custodyLog,
    DateTime? openedAt,
    String? tamperRemarks,
    DateTime? createdAt,
  }) {
    return QuestionPaperPacket(
      id: id ?? this.id,
      packetCode: packetCode ?? this.packetCode,
      securitySealNumber: securitySealNumber ?? this.securitySealNumber,
      examName: examName ?? this.examName,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      centerName: centerName ?? this.centerName,
      roomName: roomName ?? this.roomName,
      date: date ?? this.date,
      shift: shift ?? this.shift,
      bookletCount: bookletCount ?? this.bookletCount,
      unlockWindowStart: unlockWindowStart ?? this.unlockWindowStart,
      unlockWindowEnd: unlockWindowEnd ?? this.unlockWindowEnd,
      status: status ?? this.status,
      custodianId: custodianId ?? this.custodianId,
      custodianName: custodianName ?? this.custodianName,
      assignedInvigilatorId: assignedInvigilatorId ?? this.assignedInvigilatorId,
      assignedInvigilatorName: assignedInvigilatorName ?? this.assignedInvigilatorName,
      witnesses: witnesses ?? this.witnesses,
      custodyLog: custodyLog ?? this.custodyLog,
      openedAt: openedAt ?? this.openedAt,
      tamperRemarks: tamperRemarks ?? this.tamperRemarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'packetCode': packetCode,
    'securitySealNumber': securitySealNumber,
    'examName': examName,
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'centerName': centerName,
    'roomName': roomName,
    'date': date,
    'shift': shift,
    'bookletCount': bookletCount,
    'unlockWindowStart': Timestamp.fromDate(unlockWindowStart),
    'unlockWindowEnd': Timestamp.fromDate(unlockWindowEnd),
    'status': status.name,
    'custodianId': custodianId,
    'custodianName': custodianName,
    'assignedInvigilatorId': assignedInvigilatorId,
    'assignedInvigilatorName': assignedInvigilatorName,
    'witnesses': witnesses.map((w) => w.toMap()).toList(),
    'custodyLog': custodyLog.map((c) => c.toMap()).toList(),
    'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
    'tamperRemarks': tamperRemarks,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory QuestionPaperPacket.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(minutes: 30));
    DateTime created = DateTime.now();
    DateTime? opened;

    if (data['unlockWindowStart'] is Timestamp) {
      start = (data['unlockWindowStart'] as Timestamp).toDate();
    }
    if (data['unlockWindowEnd'] is Timestamp) {
      end = (data['unlockWindowEnd'] as Timestamp).toDate();
    }
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }
    if (data['openedAt'] is Timestamp) {
      opened = (data['openedAt'] as Timestamp).toDate();
    }

    final rawWitnesses = (data['witnesses'] as List<dynamic>? ?? []);
    final witnessesList = rawWitnesses
        .map((w) => StudentWitness.fromMap(Map<String, dynamic>.from(w as Map)))
        .toList();

    final rawCustody = (data['custodyLog'] as List<dynamic>? ?? []);
    final custodyList = rawCustody
        .map((c) => CustodyEvent.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList();

    return QuestionPaperPacket(
      id: id,
      packetCode: data['packetCode'] as String? ?? 'QP-001',
      securitySealNumber: data['securitySealNumber'] as String? ?? 'SEAL-000',
      examName: data['examName'] as String? ?? 'Semester Exam',
      subjectCode: data['subjectCode'] as String? ?? 'CS101',
      subjectName: data['subjectName'] as String? ?? 'Computer Programming',
      centerName: data['centerName'] as String? ?? 'Main Center',
      roomName: data['roomName'] as String? ?? 'Hall 101',
      date: data['date'] as String? ?? '',
      shift: data['shift'] as String? ?? 'Shift 1',
      bookletCount: data['bookletCount'] as int? ?? 30,
      unlockWindowStart: start,
      unlockWindowEnd: end,
      status: PacketStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PacketStatus.inStrongroom,
      ),
      custodianId: data['custodianId'] as String?,
      custodianName: data['custodianName'] as String?,
      assignedInvigilatorId: data['assignedInvigilatorId'] as String?,
      assignedInvigilatorName: data['assignedInvigilatorName'] as String?,
      witnesses: witnessesList,
      custodyLog: custodyList,
      openedAt: opened,
      tamperRemarks: data['tamperRemarks'] as String?,
      createdAt: created,
    );
  }
}

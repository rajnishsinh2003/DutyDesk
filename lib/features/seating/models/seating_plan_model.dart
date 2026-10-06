import 'package:cloud_firestore/cloud_firestore.dart';

enum SeatStatus {
  allocated,
  vacant,
  buffer,
  blocked,
}

enum AntiCheatingStrategy {
  alternatingBranches, // Interleave CSE, ECE, ME across adjacent desks
  checkerboard,        // Leave diagonal/alternate desks empty
  consecutiveRolls,    // Standard sequential
}

class StudentSeat {
  final int row;
  final int col;
  final String deskLabel;
  final String? studentRoll;
  final String? studentName;
  final String? branchOrSubject;
  final SeatStatus status;
  final bool isSpecialNeed;

  const StudentSeat({
    required this.row,
    required this.col,
    required this.deskLabel,
    this.studentRoll,
    this.studentName,
    this.branchOrSubject,
    this.status = SeatStatus.vacant,
    this.isSpecialNeed = false,
  });

  StudentSeat copyWith({
    int? row,
    int? col,
    String? deskLabel,
    String? studentRoll,
    String? studentName,
    String? branchOrSubject,
    SeatStatus? status,
    bool? isSpecialNeed,
  }) {
    return StudentSeat(
      row: row ?? this.row,
      col: col ?? this.col,
      deskLabel: deskLabel ?? this.deskLabel,
      studentRoll: studentRoll ?? this.studentRoll,
      studentName: studentName ?? this.studentName,
      branchOrSubject: branchOrSubject ?? this.branchOrSubject,
      status: status ?? this.status,
      isSpecialNeed: isSpecialNeed ?? this.isSpecialNeed,
    );
  }

  Map<String, dynamic> toMap() => {
    'row': row,
    'col': col,
    'deskLabel': deskLabel,
    'studentRoll': studentRoll,
    'studentName': studentName,
    'branchOrSubject': branchOrSubject,
    'status': status.name,
    'isSpecialNeed': isSpecialNeed,
  };

  factory StudentSeat.fromMap(Map<String, dynamic> map) {
    return StudentSeat(
      row: map['row'] as int? ?? 0,
      col: map['col'] as int? ?? 0,
      deskLabel: map['deskLabel'] as String? ?? 'D',
      studentRoll: map['studentRoll'] as String?,
      studentName: map['studentName'] as String?,
      branchOrSubject: map['branchOrSubject'] as String?,
      status: SeatStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SeatStatus.vacant,
      ),
      isSpecialNeed: map['isSpecialNeed'] as bool? ?? false,
    );
  }
}

class SeatingPlan {
  final String id;
  final String examName;
  final String sessionOrShift;
  final String date;
  final String centerName;
  final String roomName;
  final int rows;
  final int columns;
  final AntiCheatingStrategy strategy;
  final List<StudentSeat> seats;
  final DateTime createdAt;

  const SeatingPlan({
    required this.id,
    required this.examName,
    required this.sessionOrShift,
    required this.date,
    required this.centerName,
    required this.roomName,
    required this.rows,
    required this.columns,
    this.strategy = AntiCheatingStrategy.alternatingBranches,
    required this.seats,
    required this.createdAt,
  });

  int get totalCapacity => rows * columns;
  int get allocatedCount => seats.where((s) => s.status == SeatStatus.allocated).length;
  int get bufferCount => seats.where((s) => s.status == SeatStatus.buffer).length;
  int get vacantCount => seats.where((s) => s.status == SeatStatus.vacant).length;
  int get blockedCount => seats.where((s) => s.status == SeatStatus.blocked).length;

  double get occupancyRate => totalCapacity > 0 ? (allocatedCount / totalCapacity) * 100 : 0.0;

  Map<String, dynamic> toMap() => {
    'examName': examName,
    'sessionOrShift': sessionOrShift,
    'date': date,
    'centerName': centerName,
    'roomName': roomName,
    'rows': rows,
    'columns': columns,
    'strategy': strategy.name,
    'seats': seats.map((s) => s.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory SeatingPlan.fromFirestore(String id, Map<String, dynamic> data) {
    final rawSeats = (data['seats'] as List<dynamic>? ?? []);
    final seatsList = rawSeats
        .map((s) => StudentSeat.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();

    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }

    return SeatingPlan(
      id: id,
      examName: data['examName'] as String? ?? 'Mid-Term Exam',
      sessionOrShift: data['sessionOrShift'] as String? ?? 'Shift 1',
      date: data['date'] as String? ?? '',
      centerName: data['centerName'] as String? ?? 'Main Campus',
      roomName: data['roomName'] as String? ?? 'Hall 101',
      rows: data['rows'] as int? ?? 5,
      columns: data['columns'] as int? ?? 6,
      strategy: AntiCheatingStrategy.values.firstWhere(
        (st) => st.name == data['strategy'],
        orElse: () => AntiCheatingStrategy.alternatingBranches,
      ),
      seats: seatsList,
      createdAt: created,
    );
  }

  SeatingPlan copyWith({
    String? id,
    String? examName,
    String? sessionOrShift,
    String? date,
    String? centerName,
    String? roomName,
    int? rows,
    int? columns,
    AntiCheatingStrategy? strategy,
    List<StudentSeat>? seats,
    DateTime? createdAt,
  }) {
    return SeatingPlan(
      id: id ?? this.id,
      examName: examName ?? this.examName,
      sessionOrShift: sessionOrShift ?? this.sessionOrShift,
      date: date ?? this.date,
      centerName: centerName ?? this.centerName,
      roomName: roomName ?? this.roomName,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      strategy: strategy ?? this.strategy,
      seats: seats ?? this.seats,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

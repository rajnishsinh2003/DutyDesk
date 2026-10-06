import 'package:cloud_firestore/cloud_firestore.dart';

class ExamRoom {
  final String id;
  final String centerId;
  final String buildingName;
  final String floorName;
  final String roomNumber;
  final int capacity;
  final bool hasComputers;
  final int computerCount;
  final int invigilatorRequired;
  final bool hasCctv;
  final bool hasJammer;
  final bool isAccessible;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;

  ExamRoom({
    required this.id,
    required this.centerId,
    required this.buildingName,
    required this.floorName,
    required this.roomNumber,
    required this.capacity,
    this.hasComputers = false,
    this.computerCount = 0,
    int? invigilatorRequired,
    this.hasCctv = true,
    this.hasJammer = false,
    this.isAccessible = true,
    this.isActive = true,
    this.notes,
    this.createdAt,
  }) : invigilatorRequired = invigilatorRequired ?? (capacity > 0 ? (capacity / 24).ceil() : 1);

  factory ExamRoom.fromFirestore(String id, Map<String, dynamic> data) {
    final createdTs = data['createdAt'] as Timestamp?;
    return ExamRoom(
      id: id,
      centerId: data['centerId'] ?? '',
      buildingName: data['buildingName'] ?? 'Main Block',
      floorName: data['floorName'] ?? 'Ground Floor',
      roomNumber: data['roomNumber'] ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      hasComputers: data['hasComputers'] ?? false,
      computerCount: (data['computerCount'] as num?)?.toInt() ?? 0,
      invigilatorRequired: (data['invigilatorRequired'] as num?)?.toInt(),
      hasCctv: data['hasCctv'] ?? true,
      hasJammer: data['hasJammer'] ?? false,
      isAccessible: data['isAccessible'] ?? true,
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
      createdAt: createdTs?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'centerId': centerId,
      'buildingName': buildingName,
      'floorName': floorName,
      'roomNumber': roomNumber,
      'capacity': capacity,
      'hasComputers': hasComputers,
      'computerCount': computerCount,
      'invigilatorRequired': invigilatorRequired,
      'hasCctv': hasCctv,
      'hasJammer': hasJammer,
      'isAccessible': isAccessible,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  ExamRoom copyWith({
    String? id,
    String? centerId,
    String? buildingName,
    String? floorName,
    String? roomNumber,
    int? capacity,
    bool? hasComputers,
    int? computerCount,
    int? invigilatorRequired,
    bool? hasCctv,
    bool? hasJammer,
    bool? isAccessible,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExamRoom(
      id: id ?? this.id,
      centerId: centerId ?? this.centerId,
      buildingName: buildingName ?? this.buildingName,
      floorName: floorName ?? this.floorName,
      roomNumber: roomNumber ?? this.roomNumber,
      capacity: capacity ?? this.capacity,
      hasComputers: hasComputers ?? this.hasComputers,
      computerCount: computerCount ?? this.computerCount,
      invigilatorRequired: invigilatorRequired ?? this.invigilatorRequired,
      hasCctv: hasCctv ?? this.hasCctv,
      hasJammer: hasJammer ?? this.hasJammer,
      isAccessible: isAccessible ?? this.isAccessible,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ExamCenterReadiness {
  final String id;
  final String centerId;
  final String centerName;
  final String examName;
  final String examDate;
  final String inspectorName;
  final String status; // 'compliant', 'in_progress', 'critical_attention'
  final bool powerBackupReady;
  final bool cctvOperational;
  final bool jammersOperational;
  final bool strongRoomSecured;
  final bool waterSanitationReady;
  final bool clockSyncVerified;
  final bool firstAidReady;
  final bool securityFriskingReady;
  final bool seatingPlanPasted;
  final bool computersTested;
  final String? generalRemarks;
  final DateTime? updatedAt;

  ExamCenterReadiness({
    required this.id,
    required this.centerId,
    required this.centerName,
    required this.examName,
    required this.examDate,
    required this.inspectorName,
    this.status = 'in_progress',
    this.powerBackupReady = false,
    this.cctvOperational = false,
    this.jammersOperational = false,
    this.strongRoomSecured = false,
    this.waterSanitationReady = false,
    this.clockSyncVerified = false,
    this.firstAidReady = false,
    this.securityFriskingReady = false,
    this.seatingPlanPasted = false,
    this.computersTested = false,
    this.generalRemarks,
    this.updatedAt,
  });

  int get totalChecklistItems => 10;

  int get completedItemsCount {
    int count = 0;
    if (powerBackupReady) count++;
    if (cctvOperational) count++;
    if (jammersOperational) count++;
    if (strongRoomSecured) count++;
    if (waterSanitationReady) count++;
    if (clockSyncVerified) count++;
    if (firstAidReady) count++;
    if (securityFriskingReady) count++;
    if (seatingPlanPasted) count++;
    if (computersTested) count++;
    return count;
  }

  double get completionPercentage => (completedItemsCount / totalChecklistItems) * 100;

  bool get isFullyCompliant => completedItemsCount == totalChecklistItems;

  factory ExamCenterReadiness.fromFirestore(String id, Map<String, dynamic> data) {
    final updatedTs = data['updatedAt'] as Timestamp?;
    return ExamCenterReadiness(
      id: id,
      centerId: data['centerId'] ?? '',
      centerName: data['centerName'] ?? '',
      examName: data['examName'] ?? 'Upcoming Examination',
      examDate: data['examDate'] ?? '',
      inspectorName: data['inspectorName'] ?? 'Center Superintendent',
      status: data['status'] ?? 'in_progress',
      powerBackupReady: data['powerBackupReady'] ?? false,
      cctvOperational: data['cctvOperational'] ?? false,
      jammersOperational: data['jammersOperational'] ?? false,
      strongRoomSecured: data['strongRoomSecured'] ?? false,
      waterSanitationReady: data['waterSanitationReady'] ?? false,
      clockSyncVerified: data['clockSyncVerified'] ?? false,
      firstAidReady: data['firstAidReady'] ?? false,
      securityFriskingReady: data['securityFriskingReady'] ?? false,
      seatingPlanPasted: data['seatingPlanPasted'] ?? false,
      computersTested: data['computersTested'] ?? false,
      generalRemarks: data['generalRemarks'],
      updatedAt: updatedTs?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'centerId': centerId,
      'centerName': centerName,
      'examName': examName,
      'examDate': examDate,
      'inspectorName': inspectorName,
      'status': isFullyCompliant ? 'compliant' : (completedItemsCount < 4 ? 'critical_attention' : 'in_progress'),
      'powerBackupReady': powerBackupReady,
      'cctvOperational': cctvOperational,
      'jammersOperational': jammersOperational,
      'strongRoomSecured': strongRoomSecured,
      'waterSanitationReady': waterSanitationReady,
      'clockSyncVerified': clockSyncVerified,
      'firstAidReady': firstAidReady,
      'securityFriskingReady': securityFriskingReady,
      'seatingPlanPasted': seatingPlanPasted,
      'computersTested': computersTested,
      'generalRemarks': generalRemarks,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ExamCenterReadiness copyWith({
    String? id,
    String? centerId,
    String? centerName,
    String? examName,
    String? examDate,
    String? inspectorName,
    String? status,
    bool? powerBackupReady,
    bool? cctvOperational,
    bool? jammersOperational,
    bool? strongRoomSecured,
    bool? waterSanitationReady,
    bool? clockSyncVerified,
    bool? firstAidReady,
    bool? securityFriskingReady,
    bool? seatingPlanPasted,
    bool? computersTested,
    String? generalRemarks,
    DateTime? updatedAt,
  }) {
    return ExamCenterReadiness(
      id: id ?? this.id,
      centerId: centerId ?? this.centerId,
      centerName: centerName ?? this.centerName,
      examName: examName ?? this.examName,
      examDate: examDate ?? this.examDate,
      inspectorName: inspectorName ?? this.inspectorName,
      status: status ?? this.status,
      powerBackupReady: powerBackupReady ?? this.powerBackupReady,
      cctvOperational: cctvOperational ?? this.cctvOperational,
      jammersOperational: jammersOperational ?? this.jammersOperational,
      strongRoomSecured: strongRoomSecured ?? this.strongRoomSecured,
      waterSanitationReady: waterSanitationReady ?? this.waterSanitationReady,
      clockSyncVerified: clockSyncVerified ?? this.clockSyncVerified,
      firstAidReady: firstAidReady ?? this.firstAidReady,
      securityFriskingReady: securityFriskingReady ?? this.securityFriskingReady,
      seatingPlanPasted: seatingPlanPasted ?? this.seatingPlanPasted,
      computersTested: computersTested ?? this.computersTested,
      generalRemarks: generalRemarks ?? this.generalRemarks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

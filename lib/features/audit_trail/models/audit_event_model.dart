import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories of auditable administrative actions
enum AuditCategory {
  dutyManagement,
  staffManagement,
  centerManagement,
  payroll,
  swapApproval,
  incidentAction,
  settingsChange,
  bulkImport,
  standbyPromotion,
  paperDispatch,
  answerSheets,
  seatingPlan,
  authentication,
  systemEvent,
}

extension AuditCategoryExtension on AuditCategory {
  String get displayName {
    switch (this) {
      case AuditCategory.dutyManagement:
        return 'Duty Management';
      case AuditCategory.staffManagement:
        return 'Staff Management';
      case AuditCategory.centerManagement:
        return 'Center Management';
      case AuditCategory.payroll:
        return 'Payroll & Remuneration';
      case AuditCategory.swapApproval:
        return 'Swap Approval';
      case AuditCategory.incidentAction:
        return 'Incident Action';
      case AuditCategory.settingsChange:
        return 'Settings Change';
      case AuditCategory.bulkImport:
        return 'Bulk Import';
      case AuditCategory.standbyPromotion:
        return 'Standby Promotion';
      case AuditCategory.paperDispatch:
        return 'Paper Dispatch';
      case AuditCategory.answerSheets:
        return 'Answer Sheets';
      case AuditCategory.seatingPlan:
        return 'Seating Plan';
      case AuditCategory.authentication:
        return 'Authentication';
      case AuditCategory.systemEvent:
        return 'System Event';
    }
  }

  String get iconCodePoint {
    switch (this) {
      case AuditCategory.dutyManagement:
        return '0xe065'; // assignment
      case AuditCategory.staffManagement:
        return '0xf233'; // people
      case AuditCategory.centerManagement:
        return '0xe0c9'; // location_city
      case AuditCategory.payroll:
        return '0xe0af'; // account_balance_wallet
      case AuditCategory.swapApproval:
        return '0xf18e'; // swap_horiz
      case AuditCategory.incidentAction:
        return '0xf1fb'; // report_problem
      case AuditCategory.settingsChange:
        return '0xf0ae'; // tune
      case AuditCategory.bulkImport:
        return '0xf087'; // upload_file
      case AuditCategory.standbyPromotion:
        return '0xf233'; // people
      case AuditCategory.paperDispatch:
        return '0xe18f'; // markunread_mailbox
      case AuditCategory.answerSheets:
        return '0xef92'; // inventory_2
      case AuditCategory.seatingPlan:
        return '0xe3ec'; // grid_on
      case AuditCategory.authentication:
        return '0xe897'; // lock
      case AuditCategory.systemEvent:
        return '0xe88e'; // info
    }
  }
}

/// Immutable audit trail event for compliance logging
class AuditEvent {
  final String id;
  final String action;           // Human-readable action description
  final String category;         // AuditCategory.name
  final String actorId;          // UID of who performed the action
  final String actorName;        // Display name
  final String actorRole;        // 'admin', 'invigilator', 'finance', 'auditor', 'system'
  final String? targetEntityId;  // ID of affected record (duty, invigilator, center, etc.)
  final String? targetEntityType; // 'duty', 'invigilator', 'center', 'incident', etc.
  final String? details;         // Extended details / JSON diff
  final String? ipAddress;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Flexible extra data

  const AuditEvent({
    required this.id,
    required this.action,
    required this.category,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    this.targetEntityId,
    this.targetEntityType,
    this.details,
    this.ipAddress,
    required this.timestamp,
    this.metadata,
  });

  factory AuditEvent.fromMap(String id, Map<String, dynamic> data) {
    DateTime ts = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      ts = (data['timestamp'] as Timestamp).toDate();
    }

    Map<String, dynamic>? meta;
    if (data['metadata'] is Map) {
      meta = Map<String, dynamic>.from(data['metadata'] as Map);
    }

    return AuditEvent(
      id: id,
      action: data['action'] as String? ?? '',
      category: data['category'] as String? ?? 'systemEvent',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? 'System',
      actorRole: data['actorRole'] as String? ?? 'system',
      targetEntityId: data['targetEntityId'] as String?,
      targetEntityType: data['targetEntityType'] as String?,
      details: data['details'] as String?,
      ipAddress: data['ipAddress'] as String?,
      timestamp: ts,
      metadata: meta,
    );
  }

  Map<String, dynamic> toMap() => {
    'action': action,
    'category': category,
    'actorId': actorId,
    'actorName': actorName,
    'actorRole': actorRole,
    'targetEntityId': targetEntityId,
    'targetEntityType': targetEntityType,
    'details': details,
    'ipAddress': ipAddress,
    'timestamp': Timestamp.fromDate(timestamp),
    'metadata': metadata,
  };

  AuditCategory get categoryEnum {
    try {
      return AuditCategory.values.firstWhere((c) => c.name == category);
    } catch (_) {
      return AuditCategory.systemEvent;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IncidentReport {
  final String id;
  final String? dutyId;
  final String? sessionId;
  final String examName;
  final String centerName;
  final String centerId;
  final String room;
  final String reportedBy;
  final String reporterName;
  final String reporterRole;
  final String reporterMobile;
  final String incidentType; // 'malpractice', 'technical', 'medical', 'room_change', 'security', 'other'
  final String severity;     // 'low', 'medium', 'high', 'critical'
  final String title;
  final String description;
  final String? evidenceAttachment;
  final String status;       // 'open', 'investigating', 'resolved'
  final String? resolutionNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  IncidentReport({
    required this.id,
    this.dutyId,
    this.sessionId,
    required this.examName,
    required this.centerName,
    required this.centerId,
    required this.room,
    required this.reportedBy,
    required this.reporterName,
    required this.reporterRole,
    required this.reporterMobile,
    required this.incidentType,
    required this.severity,
    required this.title,
    required this.description,
    this.evidenceAttachment,
    this.status = 'open',
    this.resolutionNotes,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  factory IncidentReport.fromFirestore(String id, Map<String, dynamic> data) {
    final Timestamp? createdTs = data['createdAt'];
    final Timestamp? resolvedTs = data['resolvedAt'];

    return IncidentReport(
      id: id,
      dutyId: data['dutyId'],
      sessionId: data['sessionId'],
      examName: data['examName'] ?? '',
      centerName: data['centerName'] ?? '',
      centerId: data['centerId'] ?? '',
      room: data['room'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      reporterName: data['reporterName'] ?? 'Staff',
      reporterRole: data['reporterRole'] ?? 'Invigilator',
      reporterMobile: data['reporterMobile'] ?? '',
      incidentType: data['incidentType'] ?? 'other',
      severity: data['severity'] ?? 'medium',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      evidenceAttachment: data['evidenceAttachment'],
      status: data['status'] ?? 'open',
      resolutionNotes: data['resolutionNotes'],
      resolvedBy: data['resolvedBy'],
      resolvedAt: resolvedTs?.toDate(),
      createdAt: createdTs?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dutyId': dutyId,
      'sessionId': sessionId,
      'examName': examName,
      'centerName': centerName,
      'centerId': centerId,
      'room': room,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'reporterRole': reporterRole,
      'reporterMobile': reporterMobile,
      'incidentType': incidentType,
      'severity': severity,
      'title': title,
      'description': description,
      'evidenceAttachment': evidenceAttachment,
      'status': status,
      'resolutionNotes': resolutionNotes,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  IncidentReport copyWith({
    String? id,
    String? dutyId,
    String? sessionId,
    String? examName,
    String? centerName,
    String? centerId,
    String? room,
    String? reportedBy,
    String? reporterName,
    String? reporterRole,
    String? reporterMobile,
    String? incidentType,
    String? severity,
    String? title,
    String? description,
    String? evidenceAttachment,
    String? status,
    String? resolutionNotes,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      dutyId: dutyId ?? this.dutyId,
      sessionId: sessionId ?? this.sessionId,
      examName: examName ?? this.examName,
      centerName: centerName ?? this.centerName,
      centerId: centerId ?? this.centerId,
      room: room ?? this.room,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterName: reporterName ?? this.reporterName,
      reporterRole: reporterRole ?? this.reporterRole,
      reporterMobile: reporterMobile ?? this.reporterMobile,
      incidentType: incidentType ?? this.incidentType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      evidenceAttachment: evidenceAttachment ?? this.evidenceAttachment,
      status: status ?? this.status,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeDisplayName {
    switch (incidentType.toLowerCase()) {
      case 'malpractice':
        return 'Malpractice / Cheating';
      case 'technical':
        return 'Technical / System Issue';
      case 'medical':
        return 'Medical / Health Emergency';
      case 'room_change':
        return 'Room / Seating Change';
      case 'security':
        return 'Security / Discipline Breach';
      default:
        return 'General Incident';
    }
  }

  IconData get typeIcon {
    switch (incidentType.toLowerCase()) {
      case 'malpractice':
        return Icons.policy_rounded;
      case 'technical':
        return Icons.hardware_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'room_change':
        return Icons.meeting_room_rounded;
      case 'security':
        return Icons.shield_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626); // Bright Red
      case 'high':
        return const Color(0xFFEA580C); // Deep Orange
      case 'medium':
        return const Color(0xFFD97706); // Amber / Yellow
      case 'low':
      default:
        return const Color(0xFF0284C7); // Sky Blue
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF16A34A); // Green
      case 'investigating':
        return const Color(0xFF2563EB); // Royal Blue
      case 'open':
      default:
        return const Color(0xFFDC2626); // Red
    }
  }
}

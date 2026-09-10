import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// --- Models ---

class SecurityGuardRecord {
  final String id;
  final String date;
  final String name;
  final String center;
  final String gender;
  final String duty;
  final String totalShifts;
  final String payment;

  SecurityGuardRecord({
    required this.id,
    required this.date,
    required this.name,
    required this.center,
    required this.gender,
    required this.duty,
    required this.totalShifts,
    required this.payment,
  });

  factory SecurityGuardRecord.fromMap(String id, Map<String, dynamic> data) {
    return SecurityGuardRecord(
      id: id,
      date: data['date'] ?? '',
      name: data['name'] ?? '',
      center: data['center'] ?? '',
      gender: data['gender'] ?? '',
      duty: data['duty'] ?? '',
      totalShifts: data['totalShifts'] ?? '',
      payment: data['payment'] ?? '₹550',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordType': 'security_guard',
      'date': date,
      'name': name,
      'center': center,
      'gender': gender,
      'duty': duty,
      'totalShifts': totalShifts,
      'payment': payment,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class ExamStaffRecord {
  final String id;
  final String date;
  final String centerName;
  final String esName;
  final String duty;
  final String examName;
  final String totalShifts;
  final String payment;

  ExamStaffRecord({
    required this.id,
    required this.date,
    required this.centerName,
    required this.esName,
    required this.duty,
    required this.examName,
    required this.totalShifts,
    required this.payment,
  });

  factory ExamStaffRecord.fromMap(String id, Map<String, dynamic> data) {
    return ExamStaffRecord(
      id: id,
      date: data['date'] ?? '',
      centerName: data['centerName'] ?? '',
      esName: data['esName'] ?? '',
      duty: data['duty'] ?? '',
      examName: data['examName'] ?? '',
      totalShifts: data['totalShifts'] ?? '',
      payment: data['payment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordType': 'exam_staff',
      'date': date,
      'centerName': centerName,
      'esName': esName,
      'duty': duty,
      'examName': examName,
      'totalShifts': totalShifts,
      'payment': payment,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class JammerRecord {
  final String id;
  final String date;
  final String name;
  final String center;
  final String duty;
  final String examName;
  final String totalShifts;
  final String payment;

  JammerRecord({
    required this.id,
    required this.date,
    required this.name,
    required this.center,
    required this.duty,
    required this.examName,
    required this.totalShifts,
    required this.payment,
  });

  factory JammerRecord.fromMap(String id, Map<String, dynamic> data) {
    return JammerRecord(
      id: id,
      date: data['date'] ?? '',
      name: data['name'] ?? '',
      center: data['center'] ?? '',
      duty: data['duty'] ?? '',
      examName: data['examName'] ?? '',
      totalShifts: data['totalShifts'] ?? '',
      payment: data['payment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordType': 'jammer',
      'date': date,
      'name': name,
      'center': center,
      'duty': duty,
      'examName': examName,
      'totalShifts': totalShifts,
      'payment': payment,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class PodRecord {
  final String id;
  final String date;
  final String type;
  final String totalPod;
  final String center;
  final String examName;

  PodRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.totalPod,
    required this.center,
    required this.examName,
  });

  factory PodRecord.fromMap(String id, Map<String, dynamic> data) {
    return PodRecord(
      id: id,
      date: data['date'] ?? '',
      type: data['type'] ?? '',
      totalPod: data['totalPod']?.toString() ?? '',
      center: data['center'] ?? '',
      examName: data['examName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordType': 'pod',
      'date': date,
      'type': type,
      'totalPod': totalPod,
      'center': center,
      'examName': examName,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class WorkRecord {
  final String id;
  final String date;
  final String work;
  final String type;

  WorkRecord({
    required this.id,
    required this.date,
    required this.work,
    required this.type,
  });

  factory WorkRecord.fromMap(String id, Map<String, dynamic> data) {
    return WorkRecord(
      id: id,
      date: data['date'] ?? '',
      work: data['work'] ?? '',
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordType': 'work',
      'date': date,
      'work': work,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

// --- State Class ---

class DailyRecordsState {
  final List<SecurityGuardRecord> guardRecords;
  final List<ExamStaffRecord> examStaffRecords;
  final List<JammerRecord> jammerRecords;
  final List<PodRecord> podRecords;
  final List<WorkRecord> workRecords;

  DailyRecordsState({
    this.guardRecords = const [],
    this.examStaffRecords = const [],
    this.jammerRecords = const [],
    this.podRecords = const [],
    this.workRecords = const [],
  });

  DailyRecordsState copyWith({
    List<SecurityGuardRecord>? guardRecords,
    List<ExamStaffRecord>? examStaffRecords,
    List<JammerRecord>? jammerRecords,
    List<PodRecord>? podRecords,
    List<WorkRecord>? workRecords,
  }) {
    return DailyRecordsState(
      guardRecords: guardRecords ?? this.guardRecords,
      examStaffRecords: examStaffRecords ?? this.examStaffRecords,
      jammerRecords: jammerRecords ?? this.jammerRecords,
      podRecords: podRecords ?? this.podRecords,
      workRecords: workRecords ?? this.workRecords,
    );
  }
}

// --- Notifier ---

class DailyRecordNotifier extends Notifier<DailyRecordsState> {
  StreamSubscription? _subscription;

  @override
  DailyRecordsState build() {
    if (Firebase.apps.isEmpty) return DailyRecordsState();

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('daily_records')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final guards = <SecurityGuardRecord>[];
      final staffs = <ExamStaffRecord>[];
      final jammers = <JammerRecord>[];
      final pods = <PodRecord>[];
      final works = <WorkRecord>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = data['recordType'] as String?;
        if (type == 'security_guard') {
          guards.add(SecurityGuardRecord.fromMap(doc.id, data));
        } else if (type == 'exam_staff') {
          staffs.add(ExamStaffRecord.fromMap(doc.id, data));
        } else if (type == 'jammer') {
          jammers.add(JammerRecord.fromMap(doc.id, data));
        } else if (type == 'pod') {
          pods.add(PodRecord.fromMap(doc.id, data));
        } else if (type == 'work') {
          works.add(WorkRecord.fromMap(doc.id, data));
        }
      }

      state = DailyRecordsState(
        guardRecords: guards,
        examStaffRecords: staffs,
        jammerRecords: jammers,
        podRecords: pods,
        workRecords: works,
      );
    }, onError: (e) {
      log('Error fetching daily records: $e');
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return DailyRecordsState();
  }

  Future<void> addSecurityGuard(SecurityGuardRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').add(record.toMap());
  }

  Future<void> addExamStaff(ExamStaffRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').add(record.toMap());
  }

  Future<void> addJammer(JammerRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').add(record.toMap());
  }

  Future<void> addPod(PodRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').add(record.toMap());
  }

  Future<void> addWork(WorkRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').add(record.toMap());
  }

  Future<void> updateSecurityGuard(String id, SecurityGuardRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').doc(id).update(record.toMap());
  }

  Future<void> updateExamStaff(String id, ExamStaffRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').doc(id).update(record.toMap());
  }

  Future<void> updateJammer(String id, JammerRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').doc(id).update(record.toMap());
  }

  Future<void> updatePod(String id, PodRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').doc(id).update(record.toMap());
  }

  Future<void> updateWork(String id, WorkRecord record) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').doc(id).update(record.toMap());
  }

  
  Future<void> deleteRecord(String id) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('daily_records').doc(id).delete();
  }
}

final dailyRecordProvider = NotifierProvider<DailyRecordNotifier, DailyRecordsState>(() {
  return DailyRecordNotifier();
});

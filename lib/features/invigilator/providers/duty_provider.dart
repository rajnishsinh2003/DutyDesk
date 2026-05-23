import 'dart:developer';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../auth/auth_provider.dart';
import '../../admin/providers/invigilator_provider.dart';
import '../../../core/services/smtp_email_service.dart';

class ExamDuty {
  final String id;
  final String date;
  final String examName;
  final String centerName;
  final String invigilatorId;
  final String status;
  final String payment;
  final String lunch;
  final String role;
  final String shift;
  final String sessionId;

  ExamDuty({
    required this.id,
    required this.date,
    required this.examName,
    required this.centerName,
    required this.invigilatorId,
    required this.status,
    required this.payment,
    required this.lunch,
    required this.role,
    required this.shift,
    this.sessionId = '',
  });

  ExamDuty copyWith({
    String? id,
    String? date,
    String? examName,
    String? centerName,
    String? invigilatorId,
    String? status,
    String? payment,
    String? lunch,
    String? role,
    String? shift,
    String? sessionId,
  }) {
    return ExamDuty(
      id: id ?? this.id,
      date: date ?? this.date,
      examName: examName ?? this.examName,
      centerName: centerName ?? this.centerName,
      invigilatorId: invigilatorId ?? this.invigilatorId,
      status: status ?? this.status,
      payment: payment ?? this.payment,
      lunch: lunch ?? this.lunch,
      role: role ?? this.role,
      shift: shift ?? this.shift,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class DutyNotifier extends Notifier<List<ExamDuty>> {
  StreamSubscription? _subscription;

  @override
  List<ExamDuty> build() {
    final authState = ref.watch(authProvider);
    final invigilatorId = authState.userId;

    if (invigilatorId == null) {
      return [];
    }

    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('duties')
        .where('invigilatorId', isEqualTo: invigilatorId)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        return ExamDuty(
          id: doc.id,
          date: data['date'] ?? '',
          examName: data['examName'] ?? '',
          centerName: data['centerName'] ?? '',
          invigilatorId: data['invigilatorId'] ?? '',
          status: data['status'] ?? 'pending',
          payment: data['payment'] ?? '₹500',
          lunch: data['lunch'] ?? 'No',
          role: data['role'] ?? 'inv',
          shift: data['shift'] ?? '1',
          sessionId: data['sessionId'] ?? '',
        );
      }).toList();
    }, onError: (error) {
      log("Firestore duties subscription error: $error");
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  String _getRoleDisplayName(String roleCode) {
    switch (roleCode) {
      case 'inv':
        return 'Invigilator';
      case 'ls':
        return 'Lab Staff';
      case 'mtoe':
        return 'MTOE';
      default:
        return roleCode.toUpperCase();
    }
  }

  Future<void> allocateDuty({
    required String date,
    required String examName,
    required String centerName,
    required String invigilatorId,
    required String role,
    required String shift,
    required String payment,
    required String lunch,
    required String sessionId,
  }) async {
    final invigilators = ref.read(invigilatorProvider);
    final inv = invigilators.firstWhere(
      (i) => i.id == invigilatorId,
      orElse: () => Invigilator(id: '', name: 'Unknown', resourceId: '', mobile: '', mockDutyCount: 0),
    );
    final email = inv.email;

    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase is not initialized');
    }

    // 1. Add the duty to Firestore first
    final dutyRef = await FirebaseFirestore.instance.collection('duties').add({
      'date': date,
      'examName': examName,
      'centerName': centerName,
      'invigilatorId': invigilatorId,
      'status': 'pending',
      'payment': payment,
      'lunch': lunch,
      'role': role,
      'shift': shift,
      'sessionId': sessionId,
      'emailStatus': 'pending',
    });

    // 2. Dispatch SMTP email directly if the email is provided
    if (email != null && email.isNotEmpty) {
      try {
        final emailBody = 'Hello ${inv.name},\n\n'
            'You have been assigned to invigilate the "$examName" exam.\n\n'
            'Assignment Details:\n'
            '- Date: $date\n'
            '- Center: $centerName\n'
            '- Assigned Role: ${_getRoleDisplayName(role)}\n'
            '- Shift: Shift $shift\n'
            '- Lunch Provided: $lunch\n'
            '- Remuneration: $payment\n\n'
            'Please log into the DutyDesk application to accept or reject this assignment.';

        await SmtpEmailService.sendEmail(
          toAddress: email,
          subject: '📅 Exam Duty Assignment: $examName',
          bodyText: emailBody,
        );

        // Update status in duty document
        await dutyRef.update({'emailStatus': 'sent'});

        // Store log in firebase email_logs collection
        await FirebaseFirestore.instance.collection('email_logs').add({
          'dutyId': dutyRef.id,
          'toAddress': email,
          'subject': '📅 Exam Duty Assignment: $examName',
          'body': emailBody,
          'status': 'sent',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Store in firebase mail collection
        await FirebaseFirestore.instance.collection('mail').add({
          'to': email,
          'message': {
            'subject': 'Exam Duty Assignment: $examName',
            'text': emailBody,
          },
          'dutyId': dutyRef.id,
          'status': 'sent',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (smtpError) {
        // Update status in duty document to failed
        await dutyRef.update({
          'emailStatus': 'failed',
          'emailError': smtpError.toString(),
        });

        // Store log in firebase email_logs collection
        await FirebaseFirestore.instance.collection('email_logs').add({
          'dutyId': dutyRef.id,
          'toAddress': email,
          'subject': '📅 Exam Duty Assignment: $examName',
          'body': 'Failed to send: $smtpError',
          'status': 'failed',
          'timestamp': FieldValue.serverTimestamp(),
          'error': smtpError.toString(),
        });

        // Store in firebase mail collection
        await FirebaseFirestore.instance.collection('mail').add({
          'to': email,
          'message': {
            'subject': '📅 Exam Duty Assignment: $examName',
            'text': 'Failed to send: $smtpError',
          },
          'dutyId': dutyRef.id,
          'status': 'failed',
          'timestamp': FieldValue.serverTimestamp(),
          'error': smtpError.toString(),
        });

        throw Exception('Duty allocated successfully, but email dispatch failed: $smtpError');
      }
    }
  }

  Future<void> updateDutyStatus(String id, String status) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('duties')
          .doc(id)
          .update({'status': status});
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteDuty(String id) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('duties').doc(id).delete();
    } catch (e) {
      // Handle error
    }
  }
}

class GlobalDutyNotifier extends Notifier<List<ExamDuty>> {
  StreamSubscription? _subscription;

  @override
  List<ExamDuty> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('duties')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        return ExamDuty(
          id: doc.id,
          date: data['date'] ?? '',
          examName: data['examName'] ?? '',
          centerName: data['centerName'] ?? '',
          invigilatorId: data['invigilatorId'] ?? '',
          status: data['status'] ?? 'pending',
          payment: data['payment'] ?? '₹500',
          lunch: data['lunch'] ?? 'No',
          role: data['role'] ?? 'inv',
          shift: data['shift'] ?? '1',
          sessionId: data['sessionId'] ?? '',
        );
      }).toList();
    }, onError: (error) {
      log("Firestore global duties subscription error: $error");
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }
}

final dutyProvider = NotifierProvider<DutyNotifier, List<ExamDuty>>(() {
  return DutyNotifier();
});

final globalDutyProvider = NotifierProvider<GlobalDutyNotifier, List<ExamDuty>>(() {
  return GlobalDutyNotifier();
});

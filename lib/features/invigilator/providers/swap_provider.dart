import 'dart:developer';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../core/services/smtp_email_service.dart';
import '../../admin/providers/invigilator_provider.dart';
import '../../admin/providers/duty_settings_provider.dart';
import '../../auth/auth_provider.dart';
import 'duty_provider.dart';

class SwapRequest {
  final String id;
  final String requestingInvigilatorId;
  final String requestingInvigilatorName;
  final String requestingDutyId;
  final String examName;
  final String date;
  final String targetInvigilatorId;
  final String targetInvigilatorName;
  final String? targetDutyId; // Optional duty of target to swap with
  final String? targetExamName;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? createdAt;

  SwapRequest({
    required this.id,
    required this.requestingInvigilatorId,
    required this.requestingInvigilatorName,
    required this.requestingDutyId,
    required this.examName,
    required this.date,
    required this.targetInvigilatorId,
    required this.targetInvigilatorName,
    this.targetDutyId,
    this.targetExamName,
    required this.status,
    this.createdAt,
  });

  SwapRequest copyWith({
    String? id,
    String? requestingInvigilatorId,
    String? requestingInvigilatorName,
    String? requestingDutyId,
    String? examName,
    String? date,
    String? targetInvigilatorId,
    String? targetInvigilatorName,
    String? targetDutyId,
    String? targetExamName,
    String? status,
    DateTime? createdAt,
  }) {
    return SwapRequest(
      id: id ?? this.id,
      requestingInvigilatorId: requestingInvigilatorId ?? this.requestingInvigilatorId,
      requestingInvigilatorName: requestingInvigilatorName ?? this.requestingInvigilatorName,
      requestingDutyId: requestingDutyId ?? this.requestingDutyId,
      examName: examName ?? this.examName,
      date: date ?? this.date,
      targetInvigilatorId: targetInvigilatorId ?? this.targetInvigilatorId,
      targetInvigilatorName: targetInvigilatorName ?? this.targetInvigilatorName,
      targetDutyId: targetDutyId ?? this.targetDutyId,
      targetExamName: targetExamName ?? this.targetExamName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SwapNotifier extends Notifier<List<SwapRequest>> {
  StreamSubscription? _subscription;

  @override
  List<SwapRequest> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('swap_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        final Timestamp? ts = data['createdAt'];
        return SwapRequest(
          id: doc.id,
          requestingInvigilatorId: data['requestingInvigilatorId'] ?? '',
          requestingInvigilatorName: data['requestingInvigilatorName'] ?? '',
          requestingDutyId: data['requestingDutyId'] ?? '',
          examName: data['examName'] ?? '',
          date: data['date'] ?? '',
          targetInvigilatorId: data['targetInvigilatorId'] ?? '',
          targetInvigilatorName: data['targetInvigilatorName'] ?? '',
          targetDutyId: data['targetDutyId'],
          targetExamName: data['targetExamName'],
          status: data['status'] ?? 'pending',
          createdAt: ts?.toDate(),
        );
      }).toList();
    }, onError: (error) {
      log("Firestore swap_requests subscription error: $error");
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  Future<void> createSwapRequest({
    required String requestingDutyId,
    required String examName,
    required String date,
    required String targetInvigilatorId,
    required String targetInvigilatorName,
    String? targetDutyId,
    String? targetExamName,
  }) async {
    final dutySettings = ref.read(dutySettingsProvider);
    if (!dutySettings.allowDutySwap) {
      throw Exception('Duty swap is currently disabled by Admin.');
    }

    if (Firebase.apps.isEmpty) return;

    final invs = ref.read(invigilatorProvider);
    final currentUserId = ref.read(dutyProvider.notifier).ref.read(authProvider).userId;

    final requestor = invs.firstWhere((i) => i.id == currentUserId,
        orElse: () => Invigilator(id: '', name: 'Invigilator', resourceId: '', mobile: '', mockDutyCount: 0));

    try {
      await FirebaseFirestore.instance.collection('swap_requests').add({
        'requestingInvigilatorId': currentUserId,
        'requestingInvigilatorName': requestor.name,
        'requestingDutyId': requestingDutyId,
        'examName': examName,
        'date': date,
        'targetInvigilatorId': targetInvigilatorId,
        'targetInvigilatorName': targetInvigilatorName,
        'targetDutyId': targetDutyId,
        'targetExamName': targetExamName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log("Error creating swap request: $e");
      rethrow;
    }
  }

  Future<void> approveSwapRequest(String id) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('swap_requests').doc(id);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final reqInvId = data['requestingInvigilatorId'] ?? '';
      final reqDutyId = data['requestingDutyId'] ?? '';
      final targetInvId = data['targetInvigilatorId'] ?? '';
      final targetDutyId = data['targetDutyId'];

      final invs = ref.read(invigilatorProvider);
      final invA = invs.firstWhere((i) => i.id == reqInvId,
          orElse: () => Invigilator(id: '', name: 'Staff A', resourceId: '', mobile: '', mockDutyCount: 0));
      final invB = invs.firstWhere((i) => i.id == targetInvId,
          orElse: () => Invigilator(id: '', name: 'Staff B', resourceId: '', mobile: '', mockDutyCount: 0));

      // Execute Firestore writes
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update Duty A: assign to Target Invigilator (B)
      final dutyARef = FirebaseFirestore.instance.collection('duties').doc(reqDutyId);
      batch.update(dutyARef, {
        'invigilatorId': targetInvId,
        'status': 'pending', // require confirmation
        'isReached': false,
        'reachedAt': null,
        'reachedTime': null,
        'reachedPerformance': null,
      });

      // 2. If target duty is specified, update Duty B: assign to Requesting Invigilator (A)
      if (targetDutyId != null && targetDutyId.toString().isNotEmpty) {
        final dutyBRef = FirebaseFirestore.instance.collection('duties').doc(targetDutyId.toString());
        batch.update(dutyBRef, {
          'invigilatorId': reqInvId,
          'status': 'pending', // require confirmation
          'isReached': false,
          'reachedAt': null,
          'reachedTime': null,
          'reachedPerformance': null,
        });
      }

      // 3. Mark request as approved
      batch.update(docRef, {'status': 'approved'});

      await batch.commit();

      // Send emails to notify both invigilators
      if (invA.email != null && invA.email!.isNotEmpty) {
        try {
          await SmtpEmailService.sendEmail(
            toAddress: invA.email!,
            subject: '✅ Duty Swap Approved',
            bodyText: 'Hello ${invA.name},\n\n'
                'Your request to swap duty has been APPROVED by the administrator.\n\n'
                'Please check your new duty assignments in the DutyDesk app.',
          );
        } catch (_) {}
      }

      if (invB.email != null && invB.email!.isNotEmpty) {
        try {
          await SmtpEmailService.sendEmail(
            toAddress: invB.email!,
            subject: 'New Swapped Duty Assignment',
            bodyText: 'Hello ${invB.name},\n\n'
                'You have been assigned to a swapped duty by the administrator.\n\n'
                'Please check your pending duty assignments in the DutyDesk app.',
          );
        } catch (_) {}
      }
    } catch (e) {
      log("Error approving swap request: $e");
    }
  }

  Future<void> rejectSwapRequest(String id) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('swap_requests').doc(id);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final reqInvId = data['requestingInvigilatorId'] ?? '';

      final invs = ref.read(invigilatorProvider);
      final invA = invs.firstWhere((i) => i.id == reqInvId,
          orElse: () => Invigilator(id: '', name: 'Staff A', resourceId: '', mobile: '', mockDutyCount: 0));

      await docRef.update({'status': 'rejected'});

      if (invA.email != null && invA.email!.isNotEmpty) {
        try {
          await SmtpEmailService.sendEmail(
            toAddress: invA.email!,
            subject: '❌ Duty Swap Rejected',
            bodyText: 'Hello ${invA.name},\n\n'
                'Your request to swap duty has been rejected by the administrator.\n\n'
                'Your original duty assignment remains active.',
          );
        } catch (_) {}
      }
    } catch (e) {
      log("Error rejecting swap request: $e");
    }
  }
}

final swapProvider = NotifierProvider<SwapNotifier, List<SwapRequest>>(() {
  return SwapNotifier();
});

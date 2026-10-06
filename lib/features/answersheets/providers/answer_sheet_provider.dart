import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/answer_sheet_bundle_model.dart';
import '../../incidents/providers/incident_provider.dart';

class AnswerSheetNotifier extends Notifier<List<AnswerSheetBundle>> {
  StreamSubscription? _subscription;

  @override
  List<AnswerSheetBundle> build() {
    _initFirestoreListener();
    return _generateInitialBundles();
  }

  void _initFirestoreListener() {
    if (Firebase.apps.isEmpty) return;

    _subscription?.cancel();
    try {
      _subscription = FirebaseFirestore.instance
          .collection('answer_sheet_bundles')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          state = snapshot.docs
              .map((doc) => AnswerSheetBundle.fromFirestore(doc.id, doc.data()))
              .toList();
        }
      }, onError: (err) {
        log('Firestore answer_sheet_bundles listener error: $err');
      });
    } catch (e) {
      log('Firestore answer_sheet_bundles init error: $e');
    }

    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  List<AnswerSheetBundle> _generateInitialBundles() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return [
      AnswerSheetBundle(
        id: 'ANS_2026_01',
        bundleCode: 'ANS-2026-CS301-B01',
        securitySealNumber: 'SEAL-WAX-884101',
        examName: 'Mid-Semester Examinations 2026',
        subjectCode: 'CS301',
        subjectName: 'Design & Analysis of Algorithms',
        centerName: 'Main Campus, Building A',
        roomName: 'Hall 101',
        date: todayStr,
        shift: 'Shift 1',
        registeredCandidates: 30,
        presentCount: 28,
        absentCount: 2,
        collectedScriptCount: 28,
        unusedBlankSheetsReturned: 2,
        absentRollNumbers: ['23CS105', '23CS119'],
        status: BundleStatus.handedToSuperintendent,
        invigilatorId: 'INV-101',
        invigilatorName: 'Prof. Ananya Roy',
        superintendentName: 'Dr. Ramesh Sharma',
        custodyLog: [
          BundleCustodyEvent(
            stage: 'Scripts Collected & Reconciled',
            actorName: 'Prof. Ananya Roy',
            actorRole: 'Room Invigilator',
            timestamp: now.subtract(const Duration(minutes: 50)),
            notes: '28 present, 2 absent (23CS105, 23CS119). Reconciled 100%.',
          ),
          BundleCustodyEvent(
            stage: 'Bundle Sealed in Cloth Envelope',
            actorName: 'Prof. Ananya Roy',
            actorRole: 'Room Invigilator',
            timestamp: now.subtract(const Duration(minutes: 40)),
            notes: 'Wax seal SEAL-WAX-884101 applied. Docket Form B pasted.',
          ),
          BundleCustodyEvent(
            stage: 'Received by Center Superintendent',
            actorName: 'Dr. Ramesh Sharma',
            actorRole: 'Center Superintendent',
            timestamp: now.subtract(const Duration(minutes: 20)),
            notes: 'Physical seal checked. Received in Control Room safe.',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AnswerSheetBundle(
        id: 'ANS_2026_02',
        bundleCode: 'ANS-2026-EC204-B02',
        securitySealNumber: 'SEAL-WAX-884102',
        examName: 'Mid-Semester Examinations 2026',
        subjectCode: 'EC204',
        subjectName: 'Digital Signal Processing',
        centerName: 'Main Campus, Building A',
        roomName: 'Room 204',
        date: todayStr,
        shift: 'Shift 1',
        registeredCandidates: 25,
        presentCount: 25,
        absentCount: 0,
        collectedScriptCount: 25,
        unusedBlankSheetsReturned: 0,
        absentRollNumbers: [],
        status: BundleStatus.reconciledAndSealed,
        invigilatorId: 'INV-102',
        invigilatorName: 'Dr. Vikram Seth',
        custodyLog: [
          BundleCustodyEvent(
            stage: 'Scripts Collected & Reconciled',
            actorName: 'Dr. Vikram Seth',
            actorRole: 'Room Invigilator',
            timestamp: now.subtract(const Duration(minutes: 25)),
            notes: '100% attendance (25/25 present).',
          ),
          BundleCustodyEvent(
            stage: 'Bundle Sealed in Cloth Envelope',
            actorName: 'Dr. Vikram Seth',
            actorRole: 'Room Invigilator',
            timestamp: now.subtract(const Duration(minutes: 10)),
            notes: 'Cloth envelope cross-stitched and sealed.',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AnswerSheetBundle(
        id: 'ANS_2026_03',
        bundleCode: 'ANS-2026-ME102-B03',
        securitySealNumber: 'PENDING-SEAL',
        examName: 'Mid-Semester Examinations 2026',
        subjectCode: 'ME102',
        subjectName: 'Thermodynamics & Heat Engines',
        centerName: 'North Wing, Science Block',
        roomName: 'Workshop Hall B',
        date: todayStr,
        shift: 'Shift 2',
        registeredCandidates: 35,
        presentCount: 0,
        absentCount: 0,
        collectedScriptCount: 0,
        unusedBlankSheetsReturned: 0,
        absentRollNumbers: [],
        status: BundleStatus.draft,
        invigilatorId: 'INV-103',
        invigilatorName: 'Mr. Arvind Verma',
        custodyLog: [
          BundleCustodyEvent(
            stage: 'Collection Docket Initiated',
            actorName: 'Mr. Arvind Verma',
            actorRole: 'Room Invigilator',
            timestamp: now.subtract(const Duration(minutes: 5)),
            notes: 'Exam in progress. Awaiting collection bell.',
          ),
        ],
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  Future<void> saveBundle(AnswerSheetBundle bundle) async {
    final index = state.indexWhere((b) => b.id == bundle.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) bundle else state[i],
      ];
    } else {
      state = [bundle, ...state];
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('answer_sheet_bundles')
            .doc(bundle.id)
            .set(bundle.toMap());
        log('✅ Answer sheet bundle saved in Firestore: ${bundle.bundleCode}');
      } catch (e) {
        log('Error saving answer sheet bundle in Firestore: $e');
      }
    }
  }

  /// 1. Reconcile counts, enter absentees, and seal bundle
  Future<void> reconcileAndSeal({
    required String bundleId,
    required String securitySealNumber,
    required int presentCount,
    required int absentCount,
    required int collectedScriptCount,
    required int blankSheetsReturned,
    required List<String> absentRollNumbers,
    required String invigilatorName,
    String? notes,
  }) async {
    final index = state.indexWhere((b) => b.id == bundleId);
    if (index < 0) return;

    final b = state[index];
    final isBalanced = (presentCount + absentCount == b.registeredCandidates) &&
        (presentCount == collectedScriptCount);

    final status = isBalanced ? BundleStatus.reconciledAndSealed : BundleStatus.countMismatch;

    final event = BundleCustodyEvent(
      stage: isBalanced ? 'Reconciled & Sealed in Envelope' : '🚨 Script Count Discrepancy Flagged',
      actorName: invigilatorName,
      actorRole: 'Room Invigilator',
      timestamp: DateTime.now(),
      notes: notes ?? 'Present: $presentCount, Absent: $absentCount, Collected: $collectedScriptCount. Seal: $securitySealNumber',
    );

    final updated = b.copyWith(
      securitySealNumber: securitySealNumber,
      presentCount: presentCount,
      absentCount: absentCount,
      collectedScriptCount: collectedScriptCount,
      unusedBlankSheetsReturned: blankSheetsReturned,
      absentRollNumbers: absentRollNumbers,
      status: status,
      custodyLog: [...b.custodyLog, event],
    );

    await saveBundle(updated);

    // If mismatch, automatically log an incident
    if (!isBalanced) {
      try {
        final diff = collectedScriptCount - (b.registeredCandidates - absentCount);
        ref.read(incidentProvider.notifier).reportIncident(
          examName: b.examName,
          centerName: b.centerName,
          centerId: b.centerName,
          room: b.roomName,
          reportedBy: invigilatorName,
          reporterName: invigilatorName,
          reporterRole: 'Invigilator',
          reporterMobile: '',
          incidentType: 'security',
          severity: 'Critical',
          title: '🚨 Script Count Discrepancy (${b.bundleCode})',
          description: '🚨 Script count mismatch in ${b.bundleCode} (${b.subjectCode}). '
              'Registered: ${b.registeredCandidates}, Present: $presentCount, Absent: $absentCount, '
              'Collected: $collectedScriptCount. Discrepancy difference: $diff scripts!',
        );
      } catch (e) {
        log('Auto incident logging failed: $e');
      }
    }
  }

  /// 2. Handover bundle to Center Superintendent
  Future<void> handoverToSuperintendent({
    required String bundleId,
    required String superintendentName,
    String? notes,
  }) async {
    final index = state.indexWhere((b) => b.id == bundleId);
    if (index < 0) return;

    final b = state[index];
    final event = BundleCustodyEvent(
      stage: 'Received by Center Superintendent',
      actorName: superintendentName,
      actorRole: 'Center Superintendent',
      timestamp: DateTime.now(),
      notes: notes ?? 'Physical seal intact. Docket Form B cross-checked.',
    );

    final updated = b.copyWith(
      status: BundleStatus.handedToSuperintendent,
      superintendentName: superintendentName,
      custodyLog: [...b.custodyLog, event],
    );

    await saveBundle(updated);
  }

  /// 3. Dispatch to University Evaluation Camp / Courier
  Future<void> dispatchToEvaluationCamp({
    required String bundleId,
    required String courierTrackingNo,
    required String authorizedBy,
    String? notes,
  }) async {
    final index = state.indexWhere((b) => b.id == bundleId);
    if (index < 0) return;

    final b = state[index];
    final event = BundleCustodyEvent(
      stage: 'Dispatched to Evaluation Camp',
      actorName: authorizedBy,
      actorRole: 'Dispatch Escort',
      timestamp: DateTime.now(),
      notes: 'Consignment / Tracking No: $courierTrackingNo. ${notes ?? ""}',
    );

    final updated = b.copyWith(
      status: BundleStatus.dispatchedToEvaluation,
      courierConsignmentNumber: courierTrackingNo,
      custodyLog: [...b.custodyLog, event],
    );

    await saveBundle(updated);
  }
}

final answerSheetProvider =
    NotifierProvider<AnswerSheetNotifier, List<AnswerSheetBundle>>(() {
  return AnswerSheetNotifier();
});

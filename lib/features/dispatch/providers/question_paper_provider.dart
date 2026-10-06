import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/question_paper_packet_model.dart';
import '../../incidents/providers/incident_provider.dart';

class QuestionPaperNotifier extends Notifier<List<QuestionPaperPacket>> {
  StreamSubscription? _subscription;

  @override
  List<QuestionPaperPacket> build() {
    _initFirestoreListener();
    return _generateInitialPackets();
  }

  void _initFirestoreListener() {
    if (Firebase.apps.isEmpty) return;

    _subscription?.cancel();
    try {
      _subscription = FirebaseFirestore.instance
          .collection('question_paper_packets')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          state = snapshot.docs
              .map((doc) => QuestionPaperPacket.fromFirestore(doc.id, doc.data()))
              .toList();
        }
      }, onError: (err) {
        log('Firestore question_paper_packets listener error: $err');
      });
    } catch (e) {
      log('Firestore question_paper_packets init error: $e');
    }

    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  /// Initial realistic sample packets
  List<QuestionPaperPacket> _generateInitialPackets() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return [
      QuestionPaperPacket(
        id: 'QP_2026_01',
        packetCode: 'QP-2026-CS301-B01',
        securitySealNumber: 'SEAL-NTA-984210',
        examName: 'Mid-Semester Examinations 2026',
        subjectCode: 'CS301',
        subjectName: 'Design & Analysis of Algorithms',
        centerName: 'Main Campus, Building A',
        roomName: 'Hall 101',
        date: todayStr,
        shift: 'Shift 1',
        bookletCount: 30,
        unlockWindowStart: now.subtract(const Duration(minutes: 10)),
        unlockWindowEnd: now.add(const Duration(minutes: 20)),
        status: PacketStatus.receivedByInvigilator,
        custodianId: 'CUST-01',
        custodianName: 'Dr. Ramesh Sharma (Superintendent)',
        assignedInvigilatorId: 'INV-101',
        assignedInvigilatorName: 'Prof. Ananya Roy',
        custodyLog: [
          CustodyEvent(
            stage: 'Strongroom Vault Checkout',
            actorName: 'Dr. Ramesh Sharma',
            actorRole: 'Strongroom In-Charge',
            timestamp: now.subtract(const Duration(minutes: 45)),
            notes: 'Physical tamper-tape intact. Dual-lock verified.',
          ),
          CustodyEvent(
            stage: 'Handover to Room Invigilator',
            actorName: 'Prof. Ananya Roy',
            actorRole: 'Room Invigilator',
            timestamp: now.subtract(const Duration(minutes: 15)),
            notes: 'Received in sealed lockbox. Verification code matched.',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      QuestionPaperPacket(
        id: 'QP_2026_02',
        packetCode: 'QP-2026-EC204-B02',
        securitySealNumber: 'SEAL-NTA-984211',
        examName: 'Mid-Semester Examinations 2026',
        subjectCode: 'EC204',
        subjectName: 'Digital Signal Processing',
        centerName: 'Main Campus, Building A',
        roomName: 'Room 204',
        date: todayStr,
        shift: 'Shift 1',
        bookletCount: 25,
        unlockWindowStart: now.subtract(const Duration(minutes: 5)),
        unlockWindowEnd: now.add(const Duration(minutes: 25)),
        status: PacketStatus.dispatchedFromStrongroom,
        custodianId: 'CUST-01',
        custodianName: 'Dr. Ramesh Sharma (Superintendent)',
        assignedInvigilatorId: 'INV-102',
        assignedInvigilatorName: 'Dr. Vikram Seth',
        custodyLog: [
          CustodyEvent(
            stage: 'Strongroom Vault Checkout',
            actorName: 'Dr. Ramesh Sharma',
            actorRole: 'Strongroom In-Charge',
            timestamp: now.subtract(const Duration(minutes: 20)),
            notes: 'Bag seal intact. Dispatched via secure corridor escort.',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      QuestionPaperPacket(
        id: 'QP_2026_03',
        packetCode: 'QP-2026-ME102-B03',
        securitySealNumber: 'SEAL-NTA-984212',
        examName: 'Mid-Semester Examinations 2026',
        subjectCode: 'ME102',
        subjectName: 'Thermodynamics & Heat Engines',
        centerName: 'North Wing, Science Block',
        roomName: 'Workshop Hall B',
        date: todayStr,
        shift: 'Shift 2',
        bookletCount: 35,
        unlockWindowStart: now.add(const Duration(hours: 2, minutes: 45)),
        unlockWindowEnd: now.add(const Duration(hours: 3, minutes: 15)),
        status: PacketStatus.inStrongroom,
        custodianId: 'CUST-02',
        custodianName: 'Mr. Arvind Verma',
        custodyLog: [
          CustodyEvent(
            stage: 'Vault Logging',
            actorName: 'Mr. Arvind Verma',
            actorRole: 'Vault Custodian',
            timestamp: now.subtract(const Duration(hours: 1)),
            notes: 'Stored in Safe #4, Shelf B.',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }

  /// Save or update a packet
  Future<void> savePacket(QuestionPaperPacket packet) async {
    final index = state.indexWhere((p) => p.id == packet.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) packet else state[i],
      ];
    } else {
      state = [packet, ...state];
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('question_paper_packets')
            .doc(packet.id)
            .set(packet.toMap());
        log('✅ Question paper packet updated in Firestore: ${packet.packetCode}');
      } catch (e) {
        log('Error updating question paper packet in Firestore: $e');
      }
    }
  }

  /// 1. Checkout & dispatch from strongroom safe
  Future<void> dispatchFromStrongroom({
    required String packetId,
    required String custodianName,
    String? notes,
  }) async {
    final index = state.indexWhere((p) => p.id == packetId);
    if (index < 0) return;

    final p = state[index];
    final event = CustodyEvent(
      stage: 'Dispatched from Strongroom',
      actorName: custodianName,
      actorRole: 'Strongroom Custodian',
      timestamp: DateTime.now(),
      notes: notes ?? 'Security seal verified intact. Vault door re-locked.',
    );

    final updated = p.copyWith(
      status: PacketStatus.dispatchedFromStrongroom,
      custodianName: custodianName,
      custodyLog: [...p.custodyLog, event],
    );

    await savePacket(updated);
  }

  /// 2. Handover & receive by room invigilator
  Future<void> handoverToInvigilator({
    required String packetId,
    required String invigilatorId,
    required String invigilatorName,
    String? notes,
  }) async {
    final index = state.indexWhere((p) => p.id == packetId);
    if (index < 0) return;

    final p = state[index];
    final event = CustodyEvent(
      stage: 'Received by Room Invigilator',
      actorName: invigilatorName,
      actorRole: 'Invigilator',
      timestamp: DateTime.now(),
      notes: notes ?? 'Handover acknowledged. Packet serial number matched.',
    );

    final updated = p.copyWith(
      status: PacketStatus.receivedByInvigilator,
      assignedInvigilatorId: invigilatorId,
      assignedInvigilatorName: invigilatorName,
      custodyLog: [...p.custodyLog, event],
    );

    await savePacket(updated);
  }

  /// 3. Verify physical tamper-evident seal
  Future<void> verifySeal({
    required String packetId,
    required String verifierName,
  }) async {
    final index = state.indexWhere((p) => p.id == packetId);
    if (index < 0) return;

    final p = state[index];
    final event = CustodyEvent(
      stage: 'Seal Integrity Verified',
      actorName: verifierName,
      actorRole: 'Invigilator',
      timestamp: DateTime.now(),
      notes: 'Hologram barcode intact. No physical puncture or tampering observed.',
    );

    final updated = p.copyWith(
      status: PacketStatus.sealVerified,
      custodyLog: [...p.custodyLog, event],
    );

    await savePacket(updated);
  }

  /// 4. Unseal packet with student witnesses
  Future<bool> unsealPacket({
    required String packetId,
    required String unsealedByName,
    required List<StudentWitness> witnesses,
    bool forceOverride = false,
  }) async {
    final index = state.indexWhere((p) => p.id == packetId);
    if (index < 0) return false;

    final p = state[index];

    // Enforce time-lock unless forced
    if (p.isTimeLocked && !forceOverride) {
      log('⚠️ Premature unseal blocked by time-lock for ${p.packetCode}');
      return false;
    }

    final now = DateTime.now();
    final event = CustodyEvent(
      stage: 'Packet Unsealed in Exam Hall',
      actorName: unsealedByName,
      actorRole: 'Invigilator',
      timestamp: now,
      notes: 'Unsealed in front of ${witnesses.length} student witnesses. '
          'Witnesses: ${witnesses.map((w) => "${w.name} (${w.rollNumber})").join(", ")}',
    );

    final updated = p.copyWith(
      status: PacketStatus.opened,
      openedAt: now,
      witnesses: witnesses,
      custodyLog: [...p.custodyLog, event],
    );

    await savePacket(updated);
    return true;
  }

  /// 5. Flag security breach / tamper
  Future<void> reportTamper({
    required String packetId,
    required String reporterName,
    required String remarks,
  }) async {
    final index = state.indexWhere((p) => p.id == packetId);
    if (index < 0) return;

    final p = state[index];
    final event = CustodyEvent(
      stage: '🚨 Security Breach / Tamper Reported',
      actorName: reporterName,
      actorRole: 'Security Monitor',
      timestamp: DateTime.now(),
      notes: remarks,
    );

    final updated = p.copyWith(
      status: PacketStatus.tampered,
      tamperRemarks: remarks,
      custodyLog: [...p.custodyLog, event],
    );

    await savePacket(updated);

    // Auto-create incident in Incident Management module
    try {
      ref.read(incidentProvider.notifier).reportIncident(
        examName: p.examName,
        centerName: p.centerName,
        centerId: p.centerName,
        room: p.roomName,
        reportedBy: reporterName,
        reporterName: reporterName,
        reporterRole: 'Invigilator',
        reporterMobile: '',
        incidentType: 'security',
        severity: 'Critical',
        title: '🚨 QP Packet Tampering / Seal Breach (${p.packetCode})',
        description: '🚨 SECURITY ALERT on Packet ${p.packetCode} (${p.subjectCode} - ${p.subjectName}). '
            'Seal: ${p.securitySealNumber}. Room: ${p.roomName}. Reason: $remarks',
      );
      log('🚨 Auto-reported security incident for tampered packet ${p.packetCode}');
    } catch (e) {
      log('Incident auto-reporting failed: $e');
    }
  }
}

final questionPaperProvider =
    NotifierProvider<QuestionPaperNotifier, List<QuestionPaperPacket>>(() {
  return QuestionPaperNotifier();
});

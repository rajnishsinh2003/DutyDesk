import 'dart:developer';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ExamSession {
  final String id;
  final String examName;
  final String date;
  final String centerId;
  final String centerName;

  ExamSession({
    required this.id,
    required this.examName,
    required this.date,
    required this.centerId,
    required this.centerName,
  });

  ExamSession copyWith({
    String? id,
    String? examName,
    String? date,
    String? centerId,
    String? centerName,
  }) {
    return ExamSession(
      id: id ?? this.id,
      examName: examName ?? this.examName,
      date: date ?? this.date,
      centerId: centerId ?? this.centerId,
      centerName: centerName ?? this.centerName,
    );
  }
}

class ExamSessionNotifier extends Notifier<List<ExamSession>> {
  StreamSubscription? _subscription;

  @override
  List<ExamSession> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    // Wrap in Future.microtask or just rely on async stream
    _subscription = FirebaseFirestore.instance
        .collection('exam_sessions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        return ExamSession(
          id: doc.id,
          examName: data['examName'] ?? '',
          date: data['date'] ?? '',
          centerId: data['centerId'] ?? '',
          centerName: data['centerName'] ?? '',
        );
      }).toList();
    }, onError: (error) {
      log("Firestore exam_sessions subscription error: $error");
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  Future<void> addSession({
    required String examName,
    required String date,
    required String centerId,
    required String centerName,
  }) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('exam_sessions').add({
        'examName': examName,
        'date': date,
        'centerId': centerId,
        'centerName': centerName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Failed to add exam session: $e');
    }
  }

  Future<void> deleteSession(String id) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('exam_sessions').doc(id).delete();
    } catch (e) {
      log('Failed to delete exam session: $e');
    }
  }
}

final examSessionProvider = NotifierProvider<ExamSessionNotifier, List<ExamSession>>(() {
  return ExamSessionNotifier();
});

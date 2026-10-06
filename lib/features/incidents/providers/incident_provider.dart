import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/incident_model.dart';
import '../../notifications/providers/notification_provider.dart';

class IncidentNotifier extends Notifier<List<IncidentReport>> {
  StreamSubscription? _subscription;

  @override
  List<IncidentReport> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('incidents')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs
          .map((doc) => IncidentReport.fromFirestore(doc.id, doc.data()))
          .toList();
    }, onError: (error) {
      log('Firestore incidents stream error: $error');
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  /// File a new incident report
  Future<String> reportIncident({
    String? dutyId,
    String? sessionId,
    required String examName,
    required String centerName,
    required String centerId,
    required String room,
    required String reportedBy,
    required String reporterName,
    required String reporterRole,
    required String reporterMobile,
    required String incidentType,
    required String severity,
    required String title,
    required String description,
    String? evidenceAttachment,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase is not initialized');
    }

    final newIncident = IncidentReport(
      id: '',
      dutyId: dutyId,
      sessionId: sessionId,
      examName: examName,
      centerName: centerName,
      centerId: centerId,
      room: room,
      reportedBy: reportedBy,
      reporterName: reporterName,
      reporterRole: reporterRole,
      reporterMobile: reporterMobile,
      incidentType: incidentType,
      severity: severity,
      title: title,
      description: description,
      evidenceAttachment: evidenceAttachment,
      status: 'open',
      createdAt: DateTime.now(),
    );

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('incidents')
          .add(newIncident.toMap());

      // Send immediate high-priority alert notification to Admin
      try {
        final alertEmoji = severity.toLowerCase() == 'critical' ? '🚨 CRITICAL' : '⚠️';
        await ref.read(notificationProvider.notifier).sendNotification(
              userId: 'admin',
              title: '$alertEmoji Incident: $title',
              message: '$reporterName reported a ${severity.toUpperCase()} incident ($incidentType) in Room $room at $centerName.',
              type: 'incident_reported',
              dutyId: dutyId,
              sessionId: sessionId,
            );
      } catch (notifErr) {
        log('Failed to send admin incident notification: $notifErr');
      }

      return docRef.id;
    } catch (e) {
      log('Error creating incident: $e');
      rethrow;
    }
  }

  /// Update incident workflow status (e.g. 'investigating', 'resolved')
  Future<void> updateIncidentStatus(
    String incidentId,
    String newStatus, {
    String? resolutionNotes,
    String? resolvedBy,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('incidents').doc(incidentId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final reporterId = data['reportedBy'] ?? '';
      final title = data['title'] ?? 'Incident';

      final updateData = <String, dynamic>{
        'status': newStatus,
      };

      if (resolutionNotes != null && resolutionNotes.isNotEmpty) {
        updateData['resolutionNotes'] = resolutionNotes;
      }
      if (resolvedBy != null && resolvedBy.isNotEmpty) {
        updateData['resolvedBy'] = resolvedBy;
      }
      if (newStatus == 'resolved') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await docRef.update(updateData);

      // Notify the reporter if resolved or moved to investigating
      if (reporterId.isNotEmpty) {
        try {
          final isResolved = newStatus == 'resolved';
          await ref.read(notificationProvider.notifier).sendNotification(
                userId: reporterId,
                title: isResolved ? '✅ Incident Resolved' : '🔍 Incident Under Investigation',
                message: isResolved
                    ? 'Your incident "$title" has been resolved. Note: ${resolutionNotes ?? "Case closed."}'
                    : 'The control room is currently investigating your incident "$title".',
                type: 'incident_status_update',
              );
        } catch (_) {}
      }
    } catch (e) {
      log('Error updating incident status: $e');
      rethrow;
    }
  }

  /// Delete or dismiss an incident record
  Future<void> deleteIncident(String incidentId) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('incidents').doc(incidentId).delete();
    } catch (e) {
      log('Error deleting incident: $e');
      rethrow;
    }
  }
}

final incidentProvider =
    NotifierProvider<IncidentNotifier, List<IncidentReport>>(() {
  return IncidentNotifier();
});

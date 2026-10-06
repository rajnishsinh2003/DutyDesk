import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audit_event_model.dart';

/// Global audit trail provider — streams all audit events from Firestore
final auditTrailProvider = NotifierProvider<AuditTrailNotifier, List<AuditEvent>>(AuditTrailNotifier.new);

class AuditTrailNotifier extends Notifier<List<AuditEvent>> {
  StreamSubscription? _subscription;

  @override
  List<AuditEvent> build() {
    if (Firebase.apps.isEmpty) return [];

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('audit_trail')
        .orderBy('timestamp', descending: true)
        .limit(500)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) => AuditEvent.fromMap(doc.id, doc.data())).toList();
    }, onError: (error) {
      log('Firestore audit_trail subscription error: $error');
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  /// Log a new audit event (immutable — cannot be edited or deleted)
  Future<void> logEvent({
    required String action,
    required AuditCategory category,
    required String actorId,
    required String actorName,
    required String actorRole,
    String? targetEntityId,
    String? targetEntityType,
    String? details,
    Map<String, dynamic>? metadata,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final event = AuditEvent(
        id: '',
        action: action,
        category: category.name,
        actorId: actorId,
        actorName: actorName,
        actorRole: actorRole,
        targetEntityId: targetEntityId,
        targetEntityType: targetEntityType,
        details: details,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await FirebaseFirestore.instance.collection('audit_trail').add(event.toMap());
    } catch (e) {
      log('Failed to log audit event: $e');
    }
  }

  /// Fetch filtered events for export
  Future<List<AuditEvent>> fetchFiltered({
    String? categoryFilter,
    String? actorFilter,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (Firebase.apps.isEmpty) return [];

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('audit_trail')
          .orderBy('timestamp', descending: true);

      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        query = query.where('category', isEqualTo: categoryFilter);
      }

      if (actorFilter != null && actorFilter.isNotEmpty) {
        query = query.where('actorId', isEqualTo: actorFilter);
      }

      if (fromDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }

      if (toDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      final snapshot = await query.limit(1000).get();
      return snapshot.docs.map((doc) => AuditEvent.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      log('Failed to fetch filtered audit events: $e');
      return state; // fallback to cached state
    }
  }
}

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Automated data archival service for DutyDesk.
///
/// Moves historical data (duties, incidents, notifications) from active
/// collections to archive collections after a configurable retention period.
/// This helps maintain Firestore performance and manage storage costs.
class DataArchivalService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Default retention period in days (90 days = ~3 months).
  static const int defaultRetentionDays = 90;

  /// Maximum batch size per archival run to avoid Firestore write limits.
  static const int maxBatchSize = 400;

  /// Run full archival workflow across all archivable collections.
  ///
  /// Returns an [ArchivalReport] with counts of archived documents.
  static Future<ArchivalReport> runFullArchival({
    int retentionDays = defaultRetentionDays,
  }) async {
    if (Firebase.apps.isEmpty) {
      return ArchivalReport.empty();
    }

    debugPrint('DataArchival: Starting full archival (retention=$retentionDays days)...');
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

    int dutiesArchived = 0;
    int notificationsArchived = 0;
    int incidentsArchived = 0;

    try {
      // 1. Archive old duties
      dutiesArchived = await _archiveDateStringCollection(
        sourceCollection: 'duties',
        archiveCollection: 'archive_duties',
        dateField: 'date', // yyyy-MM-dd string
        cutoffDate: cutoffDate,
      );

      // 2. Archive old notifications
      notificationsArchived = await _archiveTimestampCollection(
        sourceCollection: 'notifications',
        archiveCollection: 'archive_notifications',
        timestampField: 'timestamp',
        cutoffDate: cutoffDate,
      );

      // 3. Archive old incidents
      incidentsArchived = await _archiveTimestampCollection(
        sourceCollection: 'incidents',
        archiveCollection: 'archive_incidents',
        timestampField: 'reportedAt',
        cutoffDate: cutoffDate,
      );
    } catch (e) {
      log('DataArchival Error: $e');
    }

    final report = ArchivalReport(
      dutiesArchived: dutiesArchived,
      notificationsArchived: notificationsArchived,
      incidentsArchived: incidentsArchived,
      retentionDays: retentionDays,
      timestamp: DateTime.now(),
    );

    debugPrint('DataArchival: Complete. $report');

    // Log the archival run itself
    await _logArchivalRun(report);

    return report;
  }

  /// Archive documents where the date is stored as a yyyy-MM-dd string field.
  static Future<int> _archiveDateStringCollection({
    required String sourceCollection,
    required String archiveCollection,
    required String dateField,
    required DateTime cutoffDate,
  }) async {
    final cutoffStr = '${cutoffDate.year.toString().padLeft(4, '0')}-'
        '${cutoffDate.month.toString().padLeft(2, '0')}-'
        '${cutoffDate.day.toString().padLeft(2, '0')}';

    final querySnapshot = await _db
        .collection(sourceCollection)
        .where(dateField, isLessThan: cutoffStr)
        .limit(maxBatchSize)
        .get();

    if (querySnapshot.docs.isEmpty) return 0;

    int archived = 0;
    final batch = _db.batch();

    for (final doc in querySnapshot.docs) {
      // Copy to archive
      final archiveRef = _db.collection(archiveCollection).doc(doc.id);
      final data = doc.data();
      data['archivedAt'] = FieldValue.serverTimestamp();
      data['originalCollection'] = sourceCollection;
      batch.set(archiveRef, data);

      // Delete from source
      batch.delete(doc.reference);
      archived++;
    }

    await batch.commit();
    return archived;
  }

  /// Archive documents where the date is stored as a Firestore Timestamp.
  static Future<int> _archiveTimestampCollection({
    required String sourceCollection,
    required String archiveCollection,
    required String timestampField,
    required DateTime cutoffDate,
  }) async {
    final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

    final querySnapshot = await _db
        .collection(sourceCollection)
        .where(timestampField, isLessThan: cutoffTimestamp)
        .limit(maxBatchSize)
        .get();

    if (querySnapshot.docs.isEmpty) return 0;

    int archived = 0;
    final batch = _db.batch();

    for (final doc in querySnapshot.docs) {
      // Copy to archive
      final archiveRef = _db.collection(archiveCollection).doc(doc.id);
      final data = doc.data();
      data['archivedAt'] = FieldValue.serverTimestamp();
      data['originalCollection'] = sourceCollection;
      batch.set(archiveRef, data);

      // Delete from source
      batch.delete(doc.reference);
      archived++;
    }

    await batch.commit();
    return archived;
  }

  /// Restore a specific document from archive back to the active collection.
  static Future<bool> restoreFromArchive({
    required String archiveCollection,
    required String targetCollection,
    required String documentId,
  }) async {
    if (Firebase.apps.isEmpty) return false;

    try {
      final archiveDoc = await _db.collection(archiveCollection).doc(documentId).get();
      if (!archiveDoc.exists) return false;

      final data = archiveDoc.data()!;
      data.remove('archivedAt');
      data.remove('originalCollection');

      final batch = _db.batch();
      batch.set(_db.collection(targetCollection).doc(documentId), data);
      batch.delete(archiveDoc.reference);
      await batch.commit();

      return true;
    } catch (e) {
      log('DataArchival Restore Error: $e');
      return false;
    }
  }

  /// Get a summary of how much data is eligible for archival.
  static Future<ArchivalPreview> previewArchival({
    int retentionDays = defaultRetentionDays,
  }) async {
    if (Firebase.apps.isEmpty) {
      return ArchivalPreview(eligibleDuties: 0, eligibleNotifications: 0, eligibleIncidents: 0);
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    final cutoffStr = '${cutoffDate.year.toString().padLeft(4, '0')}-'
        '${cutoffDate.month.toString().padLeft(2, '0')}-'
        '${cutoffDate.day.toString().padLeft(2, '0')}';
    final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

    final dutiesCount = await _db
        .collection('duties')
        .where('date', isLessThan: cutoffStr)
        .count()
        .get();

    final notifCount = await _db
        .collection('notifications')
        .where('timestamp', isLessThan: cutoffTimestamp)
        .count()
        .get();

    final incidentCount = await _db
        .collection('incidents')
        .where('reportedAt', isLessThan: cutoffTimestamp)
        .count()
        .get();

    return ArchivalPreview(
      eligibleDuties: dutiesCount.count ?? 0,
      eligibleNotifications: notifCount.count ?? 0,
      eligibleIncidents: incidentCount.count ?? 0,
    );
  }

  /// Get the history of archival runs.
  static Future<List<Map<String, dynamic>>> getArchivalHistory({int limit = 20}) async {
    if (Firebase.apps.isEmpty) return [];

    final snapshot = await _db
        .collection('archival_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Log an archival run to Firestore for audit trail.
  static Future<void> _logArchivalRun(ArchivalReport report) async {
    try {
      await _db.collection('archival_logs').add({
        'dutiesArchived': report.dutiesArchived,
        'notificationsArchived': report.notificationsArchived,
        'incidentsArchived': report.incidentsArchived,
        'retentionDays': report.retentionDays,
        'totalArchived': report.totalArchived,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Failed to log archival run: $e');
    }
  }
}

/// Summary of an archival run.
class ArchivalReport {
  final int dutiesArchived;
  final int notificationsArchived;
  final int incidentsArchived;
  final int retentionDays;
  final DateTime timestamp;

  ArchivalReport({
    required this.dutiesArchived,
    required this.notificationsArchived,
    required this.incidentsArchived,
    required this.retentionDays,
    required this.timestamp,
  });

  factory ArchivalReport.empty() => ArchivalReport(
    dutiesArchived: 0,
    notificationsArchived: 0,
    incidentsArchived: 0,
    retentionDays: 0,
    timestamp: DateTime.now(),
  );

  int get totalArchived => dutiesArchived + notificationsArchived + incidentsArchived;

  @override
  String toString() =>
      'ArchivalReport(duties=$dutiesArchived, notifications=$notificationsArchived, incidents=$incidentsArchived, total=$totalArchived)';
}

/// Preview of data eligible for archival.
class ArchivalPreview {
  final int eligibleDuties;
  final int eligibleNotifications;
  final int eligibleIncidents;

  ArchivalPreview({
    required this.eligibleDuties,
    required this.eligibleNotifications,
    required this.eligibleIncidents,
  });

  int get total => eligibleDuties + eligibleNotifications + eligibleIncidents;
}

import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class OfflineArrivalRecord {
  final String dutyId;
  final String invigilatorId;
  final String reachedDate;
  final String reachedTime;
  final String performance;
  final String message;
  final double? latitude;
  final double? longitude;
  final String? locationString;
  final String? mapsUrl;
  final double? distanceFromCenter;
  final bool? isGeofenceVerified;
  final String? geofenceStatus;
  final String timestamp;

  OfflineArrivalRecord({
    required this.dutyId,
    required this.invigilatorId,
    required this.reachedDate,
    required this.reachedTime,
    required this.performance,
    required this.message,
    this.latitude,
    this.longitude,
    this.locationString,
    this.mapsUrl,
    this.distanceFromCenter,
    this.isGeofenceVerified,
    this.geofenceStatus,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'dutyId': dutyId,
        'invigilatorId': invigilatorId,
        'reachedDate': reachedDate,
        'reachedTime': reachedTime,
        'performance': performance,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'locationString': locationString,
        'mapsUrl': mapsUrl,
        'distanceFromCenter': distanceFromCenter,
        'isGeofenceVerified': isGeofenceVerified,
        'geofenceStatus': geofenceStatus,
        'timestamp': timestamp,
      };

  factory OfflineArrivalRecord.fromJson(Map<String, dynamic> json) => OfflineArrivalRecord(
        dutyId: json['dutyId'] ?? '',
        invigilatorId: json['invigilatorId'] ?? '',
        reachedDate: json['reachedDate'] ?? '',
        reachedTime: json['reachedTime'] ?? '',
        performance: json['performance'] ?? 'On Time',
        message: json['message'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationString: json['locationString'],
        mapsUrl: json['mapsUrl'],
        distanceFromCenter: (json['distanceFromCenter'] as num?)?.toDouble(),
        isGeofenceVerified: json['isGeofenceVerified'],
        geofenceStatus: json['geofenceStatus'],
        timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      );
}

class OfflineSyncService {
  static const String _pendingArrivalsKey = 'dutydesk_pending_arrivals_queue';

  /// Save arrival record to local cache when offline
  static Future<bool> saveOfflineArrival(OfflineArrivalRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJsonList = prefs.getStringList(_pendingArrivalsKey) ?? [];

      // Avoid duplicates
      final exists = existingJsonList.any((item) {
        try {
          final decoded = jsonDecode(item);
          return decoded['dutyId'] == record.dutyId;
        } catch (_) {
          return false;
        }
      });

      if (!exists) {
        existingJsonList.add(jsonEncode(record.toJson()));
        await prefs.setStringList(_pendingArrivalsKey, existingJsonList);
      }
      return true;
    } catch (e) {
      log('Error saving offline arrival: $e');
      return false;
    }
  }

  /// Get count of pending offline arrivals
  static Future<int> getPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingArrivalsKey) ?? [];
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  /// Synchronize all pending arrival records to Firestore
  static Future<int> syncPendingArrivals() async {
    if (Firebase.apps.isEmpty) return 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJsonList = prefs.getStringList(_pendingArrivalsKey) ?? [];
      if (existingJsonList.isEmpty) return 0;

      int syncedCount = 0;
      final remainingList = <String>[];

      for (final jsonStr in existingJsonList) {
        try {
          final record = OfflineArrivalRecord.fromJson(jsonDecode(jsonStr));
          final docRef = FirebaseFirestore.instance.collection('duties').doc(record.dutyId);

          await docRef.update({
            'isReached': true,
            'reachedAt': FieldValue.serverTimestamp(),
            'reachedTime': record.reachedTime,
            'reachedDate': record.reachedDate,
            'reachedPerformance': record.performance,
            'reachedMessage': record.message,
            'reachedLatitude': record.latitude,
            'reachedLongitude': record.longitude,
            'reachedLocation': record.locationString ?? 'Recorded Offline',
            'reachedMapsUrl': record.mapsUrl,
            'distanceFromCenter': record.distanceFromCenter,
            'isGeofenceVerified': record.isGeofenceVerified ?? true,
            'geofenceStatus': record.geofenceStatus ?? 'verified',
            'syncedAt': FieldValue.serverTimestamp(),
            'isOfflineSynced': true,
          });

          syncedCount++;
        } catch (e) {
          log('Failed to sync item: $e');
          remainingList.add(jsonStr); // Keep in queue to retry later
        }
      }

      await prefs.setStringList(_pendingArrivalsKey, remainingList);
      return syncedCount;
    } catch (e) {
      log('Error during offline sync batch: $e');
      return 0;
    }
  }
}

import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';

class RoomNotifier extends Notifier<List<ExamRoom>> {
  StreamSubscription? _subscription;

  @override
  List<ExamRoom> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('rooms')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) => ExamRoom.fromFirestore(doc.id, doc.data())).toList();
    }, onError: (error) {
      log('Firestore rooms subscription error: $error');
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  Future<void> addRoom(ExamRoom room) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('rooms').add(room.toMap());
    } catch (e) {
      log('Error adding room: $e');
      rethrow;
    }
  }

  Future<void> updateRoom(ExamRoom room) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(room.id).update(room.toMap());
    } catch (e) {
      log('Error updating room: $e');
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
    } catch (e) {
      log('Error deleting room: $e');
      rethrow;
    }
  }

  /// Quickly generate a sequence of rooms (e.g. 101 to 110)
  Future<void> bulkGenerateRooms({
    required String centerId,
    required String buildingName,
    required String floorName,
    required int startNumber,
    required int count,
    required int capacityPerRoom,
    bool hasComputers = false,
    int computerCount = 0,
    bool hasCctv = true,
    bool hasJammer = false,
    bool isAccessible = true,
  }) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < count; i++) {
        final roomNum = '${startNumber + i}';
        final docRef = FirebaseFirestore.instance.collection('rooms').doc();
        final room = ExamRoom(
          id: docRef.id,
          centerId: centerId,
          buildingName: buildingName,
          floorName: floorName,
          roomNumber: roomNum,
          capacity: capacityPerRoom,
          hasComputers: hasComputers,
          computerCount: computerCount,
          hasCctv: hasCctv,
          hasJammer: hasJammer,
          isAccessible: isAccessible,
        );
        batch.set(docRef, room.toMap());
      }
      await batch.commit();
    } catch (e) {
      log('Error bulk generating rooms: $e');
      rethrow;
    }
  }
}

final roomProvider = NotifierProvider<RoomNotifier, List<ExamRoom>>(() {
  return RoomNotifier();
});

class CenterReadinessNotifier extends Notifier<List<ExamCenterReadiness>> {
  StreamSubscription? _subscription;

  @override
  List<ExamCenterReadiness> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('center_readiness')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) => ExamCenterReadiness.fromFirestore(doc.id, doc.data())).toList();
    }, onError: (error) {
      log('Firestore center_readiness subscription error: $error');
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  Future<void> saveReadinessReport(ExamCenterReadiness report) async {
    if (Firebase.apps.isEmpty) return;
    try {
      if (report.id.isNotEmpty && report.id != 'new') {
        await FirebaseFirestore.instance.collection('center_readiness').doc(report.id).set(report.toMap(), SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance.collection('center_readiness').add(report.toMap());
      }
    } catch (e) {
      log('Error saving center readiness report: $e');
      rethrow;
    }
  }
}

final centerReadinessProvider = NotifierProvider<CenterReadinessNotifier, List<ExamCenterReadiness>>(() {
  return CenterReadinessNotifier();
});

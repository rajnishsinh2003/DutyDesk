import 'dart:developer';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class Invigilator {
  final String id;
  final String name;
  final String resourceId;
  final String mobile;
  final String? email;
  final String? address;
  final int mockDutyCount;
  final DateTime? lastMockAssignedDate;
  final bool isActive;
  final List<String> unavailableDates;
  final String? photoUrl;
  // Standby fields
  final bool isStandby;
  final String? standbyForDate; // yyyy-MM-dd
  final String? standbyForCenter;
  final double? latitude;
  final double? longitude;

  Invigilator({
    required this.id,
    required this.name,
    required this.resourceId,
    required this.mobile,
    this.email,
    this.address,
    required this.mockDutyCount,
    this.lastMockAssignedDate,
    this.isActive = true,
    this.unavailableDates = const [],
    this.photoUrl,
    this.isStandby = false,
    this.standbyForDate,
    this.standbyForCenter,
    this.latitude,
    this.longitude,
  });

  Invigilator copyWith({
    String? id,
    String? name,
    String? resourceId,
    String? mobile,
    String? email,
    String? address,
    int? mockDutyCount,
    DateTime? lastMockAssignedDate,
    bool? isActive,
    List<String>? unavailableDates,
    String? photoUrl,
    bool? isStandby,
    String? standbyForDate,
    String? standbyForCenter,
    double? latitude,
    double? longitude,
  }) {
    return Invigilator(
      id: id ?? this.id,
      name: name ?? this.name,
      resourceId: resourceId ?? this.resourceId,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      mockDutyCount: mockDutyCount ?? this.mockDutyCount,
      lastMockAssignedDate: lastMockAssignedDate ?? this.lastMockAssignedDate,
      isActive: isActive ?? this.isActive,
      unavailableDates: unavailableDates ?? this.unavailableDates,
      photoUrl: photoUrl ?? this.photoUrl,
      isStandby: isStandby ?? this.isStandby,
      standbyForDate: standbyForDate ?? this.standbyForDate,
      standbyForCenter: standbyForCenter ?? this.standbyForCenter,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class InvigilatorNotifier extends Notifier<List<Invigilator>> {
  StreamSubscription? _subscription;

  @override
  List<Invigilator> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('invigilators')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        final Timestamp? timestamp = data['lastMockAssignedDate'];
        final List<dynamic> datesRaw = data['unavailableDates'] ?? [];
        return Invigilator(
          id: doc.id,
          name: data['name'] ?? '',
          mobile: data['mobile'] ?? '',
          resourceId: data['resourceId'] ?? '',
          email: data['email'],
          address: data['address'],
          mockDutyCount: data['mockDutyCount'] ?? 0,
          lastMockAssignedDate: timestamp?.toDate(),
          isActive: data['isActive'] ?? true,
          unavailableDates: datesRaw.map((e) => e.toString()).toList(),
          photoUrl: data['photoUrl'],
          isStandby: data['isStandby'] ?? false,
          standbyForDate: data['standbyForDate'],
          standbyForCenter: data['standbyForCenter'],
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
        );
      }).toList();
    }, onError: (error) {
      log("Firestore invigilators subscription error: $error");
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  Future<void> addInvigilator(
    String name,
    String mobile,
    String resourceId,
    String email,
    String address,
  ) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('invigilators').add({
        'name': name,
        'mobile': mobile,
        'resourceId': resourceId,
        'email': email,
        'address': address,
        'mockDutyCount': 0,
        'lastMockAssignedDate': null,
        'isActive': true,
        'unavailableDates': [],
        'photoUrl': null,
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateInvigilator(
    String id,
    String name,
    String mobile,
    String resourceId,
    String email,
    String address,
  ) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('invigilators').doc(id).update({
        'name': name,
        'mobile': mobile,
        'resourceId': resourceId,
        'email': email,
        'address': address,
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleInvigilatorActiveStatus(String id, bool active) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('invigilators').doc(id).update({
        'isActive': active,
      });
    } catch (e) {
      log("Error toggling active status: $e");
    }
  }

  Future<void> updateUnavailableDates(String id, List<String> dates) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('invigilators').doc(id).update({
        'unavailableDates': dates,
      });
    } catch (e) {
      log("Error updating unavailable dates: $e");
    }
  }

  Future<void> updateProfileDetails({
    required String id,
    required String name,
    required String mobile,
    required String email,
    String? address,
    String? photoUrl,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final updates = <String, dynamic>{
        'name': name,
        'mobile': mobile,
        'email': email,
      };
      if (address != null) updates['address'] = address;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await FirebaseFirestore.instance.collection('invigilators').doc(id).update(updates);
    } catch (e) {
      log("Error updating profile details: $e");
    }
  }

  Future<void> updateMockStats(String id) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('invigilators').doc(id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        final currentCount = snapshot.data()?['mockDutyCount'] ?? 0;
        transaction.update(docRef, {
          'mockDutyCount': currentCount + 1,
          'lastMockAssignedDate': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleUnavailableDate(String id, String date) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('invigilators').doc(id);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final currentDates = List<String>.from(snapshot.data()?['unavailableDates'] ?? []);
      if (currentDates.contains(date)) {
        currentDates.remove(date);
      } else {
        currentDates.add(date);
      }

      await docRef.update({'unavailableDates': currentDates});
    } catch (e) {
      log('Error toggling unavailable date: $e');
    }
  }

  Future<void> deleteInvigilator(String id) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('invigilators').doc(id).delete();
    } catch (e) {
      // Handle error
    }
  }

  /// Tags an invigilator as standby for a specific date and optionally a center.
  Future<void> tagAsStandby(String id, String date, {String? centerName}) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('invigilators').doc(id).update({
        'isStandby': true,
        'standbyForDate': date,
        'standbyForCenter': centerName,
      });
    } catch (e) {
      log('Error tagging as standby: $e');
    }
  }

  /// Removes standby tag from an invigilator.
  Future<void> removeStandbyTag(String id) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('invigilators').doc(id).update({
        'isStandby': false,
        'standbyForDate': null,
        'standbyForCenter': null,
      });
    } catch (e) {
      log('Error removing standby tag: $e');
    }
  }
}

final invigilatorProvider =
    NotifierProvider<InvigilatorNotifier, List<Invigilator>>(() {
  return InvigilatorNotifier();
});

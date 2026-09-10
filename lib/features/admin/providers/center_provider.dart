import 'dart:developer';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ExamCenter {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final double? latitude;
  final double? longitude;
  final int allowedRadiusMeters;

  ExamCenter({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    this.latitude,
    this.longitude,
    this.allowedRadiusMeters = 200,
  });

  ExamCenter copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    double? latitude,
    double? longitude,
    int? allowedRadiusMeters,
  }) {
    return ExamCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      allowedRadiusMeters: allowedRadiusMeters ?? this.allowedRadiusMeters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'capacity': capacity,
      'latitude': latitude,
      'longitude': longitude,
      'allowedRadiusMeters': allowedRadiusMeters,
    };
  }
}

class CenterNotifier extends Notifier<List<ExamCenter>> {
  StreamSubscription? _subscription;

  @override
  List<ExamCenter> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('centers')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();
        return ExamCenter(
          id: doc.id,
          name: data['name'] ?? '',
          location: data['location'] ?? '',
          capacity: data['capacity'] ?? 0,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          allowedRadiusMeters: (data['allowedRadiusMeters'] as num?)?.toInt() ?? 200,
        );
      }).toList();
    }, onError: (error) {
      log("Firestore centers subscription error: $error");
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  Future<void> addCenter(
    String name,
    String location,
    int capacity, {
    double? latitude,
    double? longitude,
    int allowedRadiusMeters = 200,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('centers').add({
        'name': name,
        'location': location,
        'capacity': capacity,
        'latitude': latitude,
        'longitude': longitude,
        'allowedRadiusMeters': allowedRadiusMeters,
      });
    } catch (e) {
      log('Error adding center: $e');
    }
  }

  Future<void> updateCenter(
    String id,
    String name,
    String location,
    int capacity, {
    double? latitude,
    double? longitude,
    int allowedRadiusMeters = 200,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('centers').doc(id).update({
        'name': name,
        'location': location,
        'capacity': capacity,
        'latitude': latitude,
        'longitude': longitude,
        'allowedRadiusMeters': allowedRadiusMeters,
      });
    } catch (e) {
      log('Error updating center: $e');
    }
  }

  Future<void> deleteCenter(String id) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('centers').doc(id).delete();
    } catch (e) {
      log('Error deleting center: $e');
    }
  }
}

final centerProvider = NotifierProvider<CenterNotifier, List<ExamCenter>>(() {
  return CenterNotifier();
});

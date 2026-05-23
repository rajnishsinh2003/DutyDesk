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

  ExamCenter({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
  });

  ExamCenter copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
  }) {
    return ExamCenter(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'capacity': capacity,
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

  Future<void> addCenter(String name, String location, int capacity) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('centers').add({
        'name': name,
        'location': location,
        'capacity': capacity,
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateCenter(String id, String name, String location, int capacity) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('centers').doc(id).update({
        'name': name,
        'location': location,
        'capacity': capacity,
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteCenter(String id) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('centers').doc(id).delete();
    } catch (e) {
      // Handle error
    }
  }
}

final centerProvider = NotifierProvider<CenterNotifier, List<ExamCenter>>(() {
  return CenterNotifier();
});

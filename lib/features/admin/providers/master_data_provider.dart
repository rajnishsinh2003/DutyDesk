import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MasterRecord {
  final String id;
  final String name;
  final bool isActive;
  final String type; // e.g., 'es_names', 'exam_names', 'centers', etc.
  final DateTime? createdAt;

  MasterRecord({
    required this.id,
    required this.name,
    this.isActive = true,
    required this.type,
    this.createdAt,
  });

  factory MasterRecord.fromMap(String id, Map<String, dynamic> map, String type) {
    final timestamp = map['createdAt'] as Timestamp?;
    return MasterRecord(
      id: id,
      name: map['name'] ?? '',
      isActive: map['isActive'] ?? true,
      type: type,
      createdAt: timestamp?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

class MasterDataNotifier extends Notifier<AsyncValue<Map<String, List<MasterRecord>>>> {
  @override
  AsyncValue<Map<String, List<MasterRecord>>> build() {
    _loadAllMasterData();
    return const AsyncValue.loading();
  }

  Future<void> _loadAllMasterData() async {
    try {
      final types = ['centers', 'es_names', 'exam_names', 'security_guards', 'jammers', 'users'];
      Map<String, List<MasterRecord>> allData = {};

      for (String type in types) {
        final querySnapshot = await FirebaseFirestore.instance.collection('master_$type').get();
        final records = querySnapshot.docs.map((doc) => MasterRecord.fromMap(doc.id, doc.data(), type)).toList();
        allData[type] = records;
      }

      state = AsyncValue.data(allData);
    } catch (e, stack) {
      log('Error loading master data: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addRecord(String type, String name) async {
    try {
      final now = DateTime.now();
      final docRef = await FirebaseFirestore.instance.collection('master_$type').add({
        'name': name,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newRecord = MasterRecord(id: docRef.id, name: name, type: type, isActive: true, createdAt: now);

      if (state.hasValue) {
        final currentData = Map<String, List<MasterRecord>>.from(state.value!);
        final list = List<MasterRecord>.from(currentData[type] ?? []);
        list.add(newRecord);
        currentData[type] = list;
        state = AsyncValue.data(currentData);
      }
    } catch (e) {
      log('Error adding master record: $e');
      rethrow;
    }
  }

  Future<void> updateRecord(String type, String id, String newName, bool isActive) async {
    try {
      await FirebaseFirestore.instance.collection('master_$type').doc(id).update({
        'name': newName,
        'isActive': isActive,
      });

      if (state.hasValue) {
        final currentData = Map<String, List<MasterRecord>>.from(state.value!);
        final list = List<MasterRecord>.from(currentData[type] ?? []);
        final index = list.indexWhere((r) => r.id == id);
        if (index != -1) {
          list[index] = MasterRecord(id: id, name: newName, type: type, isActive: isActive);
          currentData[type] = list;
          state = AsyncValue.data(currentData);
        }
      }
    } catch (e) {
      log('Error updating master record: $e');
      rethrow;
    }
  }

  Future<void> deleteRecord(String type, String id) async {
    try {
      await FirebaseFirestore.instance.collection('master_$type').doc(id).delete();

      if (state.hasValue) {
        final currentData = Map<String, List<MasterRecord>>.from(state.value!);
        final list = List<MasterRecord>.from(currentData[type] ?? []);
        list.removeWhere((r) => r.id == id);
        currentData[type] = list;
        state = AsyncValue.data(currentData);
      }
    } catch (e) {
      log('Error deleting master record: $e');
      rethrow;
    }
  }
  
  Future<void> toggleActive(String type, String id, bool currentStatus) async {
    final record = state.value?[type]?.firstWhere((r) => r.id == id);
    if (record != null) {
      await updateRecord(type, id, record.name, !currentStatus);
    }
  }
}

final masterDataProvider = NotifierProvider<MasterDataNotifier, AsyncValue<Map<String, List<MasterRecord>>>>(() {
  return MasterDataNotifier();
});

import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../auth/auth_provider.dart';

class AppNotification {
  final String id;
  final String userId; // Specific staff ID, 'admin', or 'all'
  final String title;
  final String message;
  final String type; // 'duty_assigned', 'duty_accepted', 'duty_rejected', 'duty_reassigned', 'duty_reminder', 'geofence_alert', 'system'
  final String? dutyId;
  final String? sessionId;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.dutyId,
    this.sessionId,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    final ts = data['timestamp'] as Timestamp?;
    return AppNotification(
      id: id,
      userId: data['userId'] ?? 'all',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'system',
      dutyId: data['dutyId'],
      sessionId: data['sessionId'],
      timestamp: ts?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'dutyId': dutyId,
      'sessionId': sessionId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

class NotificationNotifier extends Notifier<List<AppNotification>> {
  StreamSubscription? _subscription;

  @override
  List<AppNotification> build() {
    if (Firebase.apps.isEmpty) return [];

    final authState = ref.watch(authProvider);
    final currentUserId = authState.userId;
    final currentRole = authState.role;

    _subscription?.cancel();

    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(100);

    _subscription = query.snapshots().listen((snapshot) {
      final all = snapshot.docs.map((doc) {
        return AppNotification.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      // Filter for current user or admin
      if (currentRole == UserRole.admin) {
        state = all.where((n) => n.userId == 'admin' || n.userId == 'all' || n.userId.isEmpty).toList();
      } else if (currentUserId != null && currentUserId.isNotEmpty) {
        state = all.where((n) => n.userId == currentUserId || n.userId == 'all').toList();
      } else {
        state = all;
      }
    }, onError: (err) {
      log('Notifications stream error: $err');
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? dutyId,
    String? sessionId,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'dutyId': dutyId,
        'sessionId': sessionId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      log('Error creating notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      log('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (Firebase.apps.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in state.where((item) => !item.isRead)) {
        final docRef = FirebaseFirestore.instance.collection('notifications').doc(n.id);
        batch.update(docRef, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      log('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      log('Error deleting notification: $e');
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, List<AppNotification>>(() {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});

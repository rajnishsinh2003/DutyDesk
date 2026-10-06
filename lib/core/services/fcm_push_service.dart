import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/providers/notification_provider.dart';

/// Top-level background message handler — must be a top-level function.
/// Called when a push notification is received while the app is terminated or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('🔔 FCM Background Message: ${message.notification?.title ?? message.data.toString()}');
}

/// Firebase Cloud Messaging (FCM) service for native push notifications.
///
/// Handles:
/// - FCM token registration & refresh
/// - Foreground, background, and terminated state message handling
/// - Topic subscription for role-based broadcasting
/// - Permission request flow (iOS/Android 13+)
class FcmPushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM — call once from main.dart after Firebase.initializeApp()
  static Future<void> initialize({WidgetRef? ref}) async {
    if (Firebase.apps.isEmpty) return;

    // 1. Request permission (required for iOS and Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      log('⚠️ FCM: Push notification permissions denied by user');
      return;
    }

    log('✅ FCM: Permission status = ${settings.authorizationStatus}');

    // 2. Get FCM token
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        log('📱 FCM Token: $token');
        await _storeFcmToken(token);
      }
    } catch (e) {
      log('FCM token error: $e');
    }

    // 3. Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      log('🔄 FCM Token refreshed: $newToken');
      await _storeFcmToken(newToken);
    });

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📬 FCM Foreground Message: ${message.notification?.title}');
      _handleForegroundMessage(message, ref: ref);
    });

    // 5. Handle notification taps (when app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('👆 FCM Message Opened: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // 6. Check if app was launched from a notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      log('🚀 FCM Initial Launch Message: ${initialMessage.notification?.title}');
      _handleNotificationTap(initialMessage);
    }

    // 7. Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    log('✅ FCM Push Notification Service initialized');
  }

  /// Subscribe to role-based FCM topics for targeted broadcast
  static Future<void> subscribeToRoleTopics({
    required String role,
    String? centerId,
  }) async {
    try {
      // All users get general topic
      await _messaging.subscribeToTopic('dutydesk_all');
      log('📢 Subscribed to topic: dutydesk_all');

      // Role-specific topics
      await _messaging.subscribeToTopic('dutydesk_$role');
      log('📢 Subscribed to topic: dutydesk_$role');

      // Center-specific topic (if applicable)
      if (centerId != null && centerId.isNotEmpty) {
        await _messaging.subscribeToTopic('center_$centerId');
        log('📢 Subscribed to topic: center_$centerId');
      }
    } catch (e) {
      log('FCM topic subscription error: $e');
    }
  }

  /// Unsubscribe from all topics on logout
  static Future<void> unsubscribeFromAllTopics() async {
    try {
      await _messaging.unsubscribeFromTopic('dutydesk_all');
      await _messaging.unsubscribeFromTopic('dutydesk_admin');
      await _messaging.unsubscribeFromTopic('dutydesk_invigilator');
      await _messaging.unsubscribeFromTopic('dutydesk_finance');
      await _messaging.unsubscribeFromTopic('dutydesk_auditor');
      log('🔕 Unsubscribed from all FCM topics');
    } catch (e) {
      log('FCM unsubscribe error: $e');
    }
  }

  /// Store the FCM device token in Firestore for server-side targeted push
  static Future<void> _storeFcmToken(String token) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log('Error storing FCM token: $e');
    }
  }

  /// Store token with user association for targeted push
  static Future<void> registerTokenForUser(String userId, String role) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'userId': userId,
        'role': role,
        'platform': defaultTargetPlatform.name,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log('Error registering FCM token for user: $e');
    }
  }

  /// Handle foreground notification — create in-app notification
  static void _handleForegroundMessage(RemoteMessage message, {WidgetRef? ref}) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null && ref != null) {
      try {
        ref.read(notificationProvider.notifier).sendNotification(
              userId: data['userId'] ?? 'all',
              title: notification.title ?? 'DutyDesk Notification',
              message: notification.body ?? '',
              type: data['type'] ?? 'push',
              dutyId: data['dutyId'],
              sessionId: data['sessionId'],
            );
      } catch (e) {
        log('Error creating in-app notification from FCM: $e');
      }
    }
  }

  /// Handle notification tap — navigate to relevant screen
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final dutyId = data['dutyId'] as String?;

    log('FCM Tap → type=$type, dutyId=$dutyId');
    // Navigation can be handled via a global navigator key or a provider
    // For now we log the intent; deep-linking can be added when needed
  }

  /// Get the current FCM token (for debugging / admin display)
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }
}

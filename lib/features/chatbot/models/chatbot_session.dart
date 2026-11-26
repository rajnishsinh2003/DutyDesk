import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotSession {
  final String id;
  final String surface; // 'landing' | 'invigilator'
  final String userType; // 'visitor' | 'invigilator'
  final String? userId;
  final String? userName;
  final String ownerUid;
  final String locale;
  final String platform;
  final bool consentGiven;
  final DateTime? startedAt;
  final DateTime? lastMessageAt;
  final int messageCount;
  final bool flagged;

  const ChatbotSession({
    required this.id,
    required this.surface,
    required this.userType,
    this.userId,
    this.userName,
    this.ownerUid = '',
    this.locale = 'en',
    this.platform = 'unknown',
    this.consentGiven = true,
    this.startedAt,
    this.lastMessageAt,
    this.messageCount = 0,
    this.flagged = false,
  });

  factory ChatbotSession.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatbotSession(
      id: id,
      surface: data['surface'] as String? ?? 'landing',
      userType: data['userType'] as String? ?? 'visitor',
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      ownerUid: data['ownerUid'] as String? ?? '',
      locale: data['locale'] as String? ?? 'en',
      platform: data['platform'] as String? ?? 'unknown',
      consentGiven: data['consentGiven'] as bool? ?? true,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      messageCount: (data['messageCount'] as num?)?.toInt() ?? 0,
      flagged: data['flagged'] as bool? ?? false,
    );
  }
}

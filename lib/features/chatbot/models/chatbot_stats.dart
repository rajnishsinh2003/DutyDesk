import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotDailyStats {
  final String date; // yyyy-MM-dd
  final int conversations;
  final int messages;
  final int answered;
  final int unanswered;
  final int thumbsUp;
  final int thumbsDown;
  final int tokens;
  final int totalLatencyMs;
  final Map<String, int> surfaces;
  final Map<String, int> languages;

  const ChatbotDailyStats({
    required this.date,
    this.conversations = 0,
    this.messages = 0,
    this.answered = 0,
    this.unanswered = 0,
    this.thumbsUp = 0,
    this.thumbsDown = 0,
    this.tokens = 0,
    this.totalLatencyMs = 0,
    this.surfaces = const {},
    this.languages = const {},
  });

  factory ChatbotDailyStats.fromFirestore(String id, Map<String, dynamic> data) {
    Map<String, int> parseIntMap(dynamic raw) {
      if (raw is! Map) return {};
      final out = <String, int>{};
      raw.forEach((k, v) {
        if (v is num) out[k.toString()] = v.toInt();
      });
      return out;
    }

    return ChatbotDailyStats(
      date: data['date'] as String? ?? id,
      conversations: (data['conversations'] as num?)?.toInt() ?? 0,
      messages: (data['messages'] as num?)?.toInt() ?? 0,
      answered: (data['answered'] as num?)?.toInt() ?? 0,
      unanswered: (data['unanswered'] as num?)?.toInt() ?? 0,
      thumbsUp: (data['thumbsUp'] as num?)?.toInt() ?? 0,
      thumbsDown: (data['thumbsDown'] as num?)?.toInt() ?? 0,
      tokens: (data['tokens'] as num?)?.toInt() ?? 0,
      totalLatencyMs: (data['totalLatencyMs'] as num?)?.toInt() ?? 0,
      surfaces: parseIntMap(data['surfaces']),
      languages: parseIntMap(data['languages']),
    );
  }
}

class ChatbotAuditEntry {
  final String id;
  final String actorUid;
  final String action;
  final String? targetId;
  final Map<String, dynamic> details;
  final DateTime? createdAt;

  const ChatbotAuditEntry({
    required this.id,
    required this.actorUid,
    required this.action,
    this.targetId,
    this.details = const {},
    this.createdAt,
  });

  factory ChatbotAuditEntry.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatbotAuditEntry(
      id: id,
      actorUid: data['actorUid'] as String? ?? '',
      action: data['action'] as String? ?? '',
      targetId: data['targetId'] as String?,
      details: data['details'] is Map
          ? Map<String, dynamic>.from(data['details'] as Map)
          : const {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

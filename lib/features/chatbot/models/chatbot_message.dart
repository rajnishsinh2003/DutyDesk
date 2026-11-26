import 'package:cloud_firestore/cloud_firestore.dart';

class ChatSource {
  final String docId;
  final String title;
  final String chunkId;
  final double score;

  const ChatSource({
    required this.docId,
    required this.title,
    required this.chunkId,
    required this.score,
  });

  factory ChatSource.fromMap(Map<String, dynamic> map) => ChatSource(
        docId: map['docId'] as String? ?? '',
        title: map['title'] as String? ?? 'Source',
        chunkId: map['chunkId'] as String? ?? '',
        score: (map['score'] as num?)?.toDouble() ?? 0.0,
      );
}

class MessageFeedback {
  final String value; // 'up' | 'down'
  final String comment;

  const MessageFeedback({required this.value, this.comment = ''});

  factory MessageFeedback.fromMap(Map<String, dynamic> map) => MessageFeedback(
        value: map['value'] as String? ?? '',
        comment: map['comment'] as String? ?? '',
      );
}

class AdminReview {
  final String status; // 'correct' | 'incorrect'
  final String correctedAnswer;
  final String reviewedBy;
  final DateTime? reviewedAt;

  const AdminReview({
    required this.status,
    this.correctedAnswer = '',
    this.reviewedBy = '',
    this.reviewedAt,
  });

  factory AdminReview.fromMap(Map<String, dynamic> map) => AdminReview(
        status: map['status'] as String? ?? '',
        correctedAnswer: map['correctedAnswer'] as String? ?? '',
        reviewedBy: map['reviewedBy'] as String? ?? '',
        reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      );
}

class ChatbotMessage {
  final String id;
  final String role; // 'user' | 'assistant' | 'admin'
  final String text;
  final DateTime? createdAt;
  final List<ChatSource> sources;
  final double confidence;
  final bool answered;
  final String? fallbackReason;
  final String? model;
  final int latencyMs;
  final int tokensIn;
  final int tokensOut;
  final MessageFeedback? feedback;
  final AdminReview? adminReview;

  const ChatbotMessage({
    required this.id,
    required this.role,
    required this.text,
    this.createdAt,
    this.sources = const [],
    this.confidence = 0,
    this.answered = true,
    this.fallbackReason,
    this.model,
    this.latencyMs = 0,
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.feedback,
    this.adminReview,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatbotMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final rawSources = data['sources'] as List?;
    final rawFeedback = data['feedback'] as Map<String, dynamic>?;
    final rawReview = data['adminReview'] as Map<String, dynamic>?;

    return ChatbotMessage(
      id: id,
      role: data['role'] as String? ?? 'user',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      sources: rawSources != null
          ? rawSources
              .whereType<Map>()
              .map((m) => ChatSource.fromMap(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      answered: data['answered'] as bool? ?? true,
      fallbackReason: data['fallbackReason'] as String?,
      model: data['model'] as String?,
      latencyMs: (data['latencyMs'] as num?)?.toInt() ?? 0,
      tokensIn: (data['tokensIn'] as num?)?.toInt() ?? 0,
      tokensOut: (data['tokensOut'] as num?)?.toInt() ?? 0,
      feedback: rawFeedback != null ? MessageFeedback.fromMap(rawFeedback) : null,
      adminReview: rawReview != null ? AdminReview.fromMap(rawReview) : null,
    );
  }
}

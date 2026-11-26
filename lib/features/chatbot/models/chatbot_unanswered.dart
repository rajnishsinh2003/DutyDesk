import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotUnanswered {
  final String id;
  final String question;
  final String normalizedQuestion;
  final String surface;
  final String locale;
  final int count;
  final DateTime? firstAskedAt;
  final DateTime? lastAskedAt;
  final List<String> sessionIds;
  final String status; // 'open' | 'resolved'
  final String? resolvedBy;
  final String? faqId;

  const ChatbotUnanswered({
    required this.id,
    required this.question,
    required this.normalizedQuestion,
    this.surface = 'landing',
    this.locale = 'en',
    this.count = 1,
    this.firstAskedAt,
    this.lastAskedAt,
    this.sessionIds = const [],
    this.status = 'open',
    this.resolvedBy,
    this.faqId,
  });

  factory ChatbotUnanswered.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatbotUnanswered(
      id: id,
      question: data['question'] as String? ?? '',
      normalizedQuestion: data['normalizedQuestion'] as String? ?? '',
      surface: data['surface'] as String? ?? 'landing',
      locale: data['locale'] as String? ?? 'en',
      count: (data['count'] as num?)?.toInt() ?? 1,
      firstAskedAt: (data['firstAskedAt'] as Timestamp?)?.toDate(),
      lastAskedAt: (data['lastAskedAt'] as Timestamp?)?.toDate(),
      sessionIds:
          (data['sessionIds'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      status: data['status'] as String? ?? 'open',
      resolvedBy: data['resolvedBy'] as String?,
      faqId: data['faqId'] as String?,
    );
  }
}

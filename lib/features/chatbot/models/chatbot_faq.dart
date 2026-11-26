import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotFaq {
  final String id;
  final String question;
  final String answer;
  final List<String> audience;
  final String language;
  final int priority;
  final bool enabled;
  final Map<String, dynamic>? createdFrom;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatbotFaq({
    required this.id,
    required this.question,
    required this.answer,
    this.audience = const ['public', 'invigilator'],
    this.language = 'en',
    this.priority = 10,
    this.enabled = true,
    this.createdFrom,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatbotFaq.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatbotFaq(
      id: id,
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      audience: (data['audience'] as List?)?.map((e) => e.toString()).toList() ??
          const ['public'],
      language: data['language'] as String? ?? 'en',
      priority: (data['priority'] as num?)?.toInt() ?? 10,
      enabled: data['enabled'] as bool? ?? true,
      createdFrom: data['createdFrom'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

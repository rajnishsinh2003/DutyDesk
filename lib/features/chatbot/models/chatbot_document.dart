import 'package:cloud_firestore/cloud_firestore.dart';

class ChatbotDocument {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> audience; // ['public', 'invigilator', 'admin']
  final String sourceType; // 'file' | 'text' | 'faq'
  final String? storagePath;
  final String? mimeType;
  final int sizeBytes;
  final String status; // 'uploaded' | 'processing' | 'ready' | 'failed'
  final String? error;
  final int chunkCount;
  final bool enabled;
  final int version;
  final String uploadedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatbotDocument({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'General',
    this.audience = const ['public'],
    this.sourceType = 'file',
    this.storagePath,
    this.mimeType,
    this.sizeBytes = 0,
    this.status = 'uploaded',
    this.error,
    this.chunkCount = 0,
    this.enabled = true,
    this.version = 1,
    this.uploadedBy = '',
    this.createdAt,
    this.updatedAt,
  });

  factory ChatbotDocument.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatbotDocument(
      id: id,
      title: data['title'] as String? ?? 'Untitled Document',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      audience: (data['audience'] as List?)?.map((e) => e.toString()).toList() ??
          const ['public'],
      sourceType: data['sourceType'] as String? ?? 'file',
      storagePath: data['storagePath'] as String?,
      mimeType: data['mimeType'] as String?,
      sizeBytes: (data['sizeBytes'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'uploaded',
      error: data['error'] as String?,
      chunkCount: (data['chunkCount'] as num?)?.toInt() ?? 0,
      enabled: data['enabled'] as bool? ?? true,
      version: (data['version'] as num?)?.toInt() ?? 1,
      uploadedBy: data['uploadedBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatbotChunk {
  final String id;
  final String docId;
  final int index;
  final String text;
  final List<String> audience;
  final bool enabled;

  const ChatbotChunk({
    required this.id,
    required this.docId,
    required this.index,
    required this.text,
    this.audience = const ['public'],
    this.enabled = true,
  });

  factory ChatbotChunk.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatbotChunk(
      id: id,
      docId: data['docId'] as String? ?? '',
      index: (data['index'] as num?)?.toInt() ?? 0,
      text: data['text'] as String? ?? '',
      audience: (data['audience'] as List?)?.map((e) => e.toString()).toList() ??
          const ['public'],
      enabled: data['enabled'] as bool? ?? true,
    );
  }
}

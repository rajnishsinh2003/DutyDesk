import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chatbot_document.dart';
import '../models/chatbot_faq.dart';
import '../models/chatbot_message.dart';
import '../models/chatbot_session.dart';
import '../models/chatbot_settings.dart';
import '../models/chatbot_stats.dart';
import '../models/chatbot_unanswered.dart';
import '../services/chatbot_api_service.dart';

/// Admin Knowledge Base documents stream
final chatbotDocumentsProvider =
    NotifierProvider<ChatbotDocumentsNotifier, List<ChatbotDocument>>(
        ChatbotDocumentsNotifier.new);

class ChatbotDocumentsNotifier extends Notifier<List<ChatbotDocument>> {
  StreamSubscription? _sub;

  @override
  List<ChatbotDocument> build() {
    if (Firebase.apps.isEmpty) return [];
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('chatbot_documents')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      state = snap.docs
          .map((d) => ChatbotDocument.fromFirestore(d.id, d.data()))
          .toList();
    }, onError: (e) => log('chatbotDocuments stream error: $e'));
    ref.onDispose(() => _sub?.cancel());
    return [];
  }

  Future<void> toggleEnabled(String docId, bool enabled) async {
    await FirebaseFirestore.instance
        .collection('chatbot_documents')
        .doc(docId)
        .update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await ChatbotApiService.logAdminAudit(
      action: enabled ? 'document_enabled' : 'document_disabled',
      targetId: docId,
    );
  }

  Future<void> updateMetadata({
    required String docId,
    required String title,
    required String description,
    required String category,
    required List<String> audience,
  }) async {
    await FirebaseFirestore.instance
        .collection('chatbot_documents')
        .doc(docId)
        .update({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'audience': audience,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await ChatbotApiService.logAdminAudit(
      action: 'document_metadata_updated',
      targetId: docId,
      details: {'title': title, 'category': category, 'audience': audience},
    );
  }
}

/// Admin FAQs stream
final chatbotFaqsProvider =
    NotifierProvider<ChatbotFaqsNotifier, List<ChatbotFaq>>(
        ChatbotFaqsNotifier.new);

class ChatbotFaqsNotifier extends Notifier<List<ChatbotFaq>> {
  StreamSubscription? _sub;

  @override
  List<ChatbotFaq> build() {
    if (Firebase.apps.isEmpty) return [];
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('chatbot_faqs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      state =
          snap.docs.map((d) => ChatbotFaq.fromFirestore(d.id, d.data())).toList();
    }, onError: (e) => log('chatbotFaqs stream error: $e'));
    ref.onDispose(() => _sub?.cancel());
    return [];
  }

  Future<void> addFaq({
    required String question,
    required String answer,
    required List<String> audience,
    String language = 'en',
    int priority = 10,
  }) async {
    final refDoc = await FirebaseFirestore.instance.collection('chatbot_faqs').add({
      'question': question.trim(),
      'answer': answer.trim(),
      'audience': audience.isEmpty ? ['public'] : audience,
      'language': language,
      'priority': priority,
      'enabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await ChatbotApiService.embedFaq(refDoc.id);
    await ChatbotApiService.logAdminAudit(
      action: 'faq_created',
      targetId: refDoc.id,
      details: {'question': question.trim()},
    );
  }

  Future<void> toggleFaq(String faqId, bool enabled) async {
    await FirebaseFirestore.instance
        .collection('chatbot_faqs')
        .doc(faqId)
        .update({'enabled': enabled, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteFaq(String faqId) async {
    await FirebaseFirestore.instance
        .collection('chatbot_faqs')
        .doc(faqId)
        .delete();
    await ChatbotApiService.logAdminAudit(
      action: 'faq_deleted',
      targetId: faqId,
    );
  }
}

/// Admin / Auditor Conversations stream
final chatbotSessionsProvider =
    NotifierProvider<ChatbotSessionsNotifier, List<ChatbotSession>>(
        ChatbotSessionsNotifier.new);

class ChatbotSessionsNotifier extends Notifier<List<ChatbotSession>> {
  StreamSubscription? _sub;

  @override
  List<ChatbotSession> build() {
    if (Firebase.apps.isEmpty) return [];
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('chatbot_sessions')
        .orderBy('lastMessageAt', descending: true)
        .limit(200)
        .snapshots()
        .listen((snap) {
      state = snap.docs
          .map((d) => ChatbotSession.fromFirestore(d.id, d.data()))
          .toList();
    }, onError: (e) => log('chatbotSessions stream error: $e'));
    ref.onDispose(() => _sub?.cancel());
    return [];
  }
}

/// Admin Unanswered Queue stream
final chatbotUnansweredProvider =
    NotifierProvider<ChatbotUnansweredNotifier, List<ChatbotUnanswered>>(
        ChatbotUnansweredNotifier.new);

class ChatbotUnansweredNotifier extends Notifier<List<ChatbotUnanswered>> {
  StreamSubscription? _sub;

  @override
  List<ChatbotUnanswered> build() {
    if (Firebase.apps.isEmpty) return [];
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('chatbot_unanswered')
        .orderBy('count', descending: true)
        .limit(200)
        .snapshots()
        .listen((snap) {
      state = snap.docs
          .map((d) => ChatbotUnanswered.fromFirestore(d.id, d.data()))
          .toList();
    }, onError: (e) => log('chatbotUnanswered stream error: $e'));
    ref.onDispose(() => _sub?.cancel());
    return [];
  }
}

/// Admin Daily Stats stream (last 30 days)
final chatbotStatsProvider =
    NotifierProvider<ChatbotStatsNotifier, List<ChatbotDailyStats>>(
        ChatbotStatsNotifier.new);

class ChatbotStatsNotifier extends Notifier<List<ChatbotDailyStats>> {
  StreamSubscription? _sub;

  @override
  List<ChatbotDailyStats> build() {
    if (Firebase.apps.isEmpty) return [];
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('chatbot_stats_daily')
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .listen((snap) {
      state = snap.docs
          .map((d) => ChatbotDailyStats.fromFirestore(d.id, d.data()))
          .toList();
    }, onError: (e) => log('chatbotStats stream error: $e'));
    ref.onDispose(() => _sub?.cancel());
    return [];
  }
}

/// Admin Audit Log stream
final chatbotAuditProvider =
    NotifierProvider<ChatbotAuditNotifier, List<ChatbotAuditEntry>>(
        ChatbotAuditNotifier.new);

class ChatbotAuditNotifier extends Notifier<List<ChatbotAuditEntry>> {
  StreamSubscription? _sub;

  @override
  List<ChatbotAuditEntry> build() {
    if (Firebase.apps.isEmpty) return [];
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('chatbot_audit')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .listen((snap) {
      state = snap.docs
          .map((d) => ChatbotAuditEntry.fromFirestore(d.id, d.data()))
          .toList();
    }, onError: (e) => log('chatbotAudit stream error: $e'));
    ref.onDispose(() => _sub?.cancel());
    return [];
  }
}

/// Helper to save settings directly to `chatbot_settings/config` + log audit.
Future<void> saveChatbotSettings(ChatbotSettings settings) async {
  await FirebaseFirestore.instance
      .collection('chatbot_settings')
      .doc('config')
      .set(settings.toMap(), SetOptions(merge: true));
  await ChatbotApiService.logAdminAudit(
    action: 'settings_updated',
    targetId: 'config',
    details: {
      'landingEnabled': settings.landingEnabled,
      'invigilatorEnabled': settings.invigilatorEnabled,
      'similarityThreshold': settings.similarityThreshold,
      'dailyTokenBudget': settings.dailyTokenBudget,
    },
  );
}

/// Helper to stream messages for a specific conversation detail view.
Stream<List<ChatbotMessage>> streamSessionMessages(String sessionId) {
  if (Firebase.apps.isEmpty) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('chatbot_sessions')
      .doc(sessionId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs
          .map((d) => ChatbotMessage.fromFirestore(d.id, d.data()))
          .toList());
}

/// Helper to fetch chunks for a specific document.
Future<List<ChatbotChunk>> fetchDocumentChunks(String docId) async {
  if (Firebase.apps.isEmpty) return [];
  final snap = await FirebaseFirestore.instance
      .collection('chatbot_chunks')
      .where('docId', isEqualTo: docId)
      .orderBy('index', descending: false)
      .get();
  return snap.docs
      .map((d) => ChatbotChunk.fromFirestore(d.id, d.data()))
      .toList();
}

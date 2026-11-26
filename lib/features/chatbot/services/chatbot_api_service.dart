import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../models/chatbot_message.dart';

class ChatAskResult {
  final String answer;
  final List<ChatSource> sources;
  final String messageId;
  final bool answered;
  final double confidence;
  final String? fallbackReason;

  const ChatAskResult({
    required this.answer,
    required this.sources,
    required this.messageId,
    required this.answered,
    required this.confidence,
    this.fallbackReason,
  });
}

class ChatbotApiService {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mihrdepkliehtlekepdc.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get _endpoint => '$supabaseUrl/functions/v1/chatbot-api';

  /// Ensures the client has a Firebase Auth user (signs in anonymously for
  /// landing visitors or invigilators who authenticate via Mobile + Resource ID).
  static Future<User?> ensureAuthUser() async {
    if (Firebase.apps.isEmpty) return null;
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser;
    final cred = await auth.signInAnonymously();
    return cred.user;
  }

  static Future<Map<String, dynamic>> _postAction(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final user = await ensureAuthUser();
    final idToken = await user?.getIdToken() ?? '';
    if (idToken.isEmpty) {
      throw StateError('Unable to obtain Firebase Auth token.');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-firebase-token': idToken,
    };
    if (supabaseAnonKey.isNotEmpty) {
      headers['apikey'] = supabaseAnonKey;
      headers['Authorization'] = 'Bearer $supabaseAnonKey';
    }

    final resp = await http.post(
      Uri.parse(_endpoint),
      headers: headers,
      body: jsonEncode(<String, dynamic>{'action': action, ...payload}),
    );

    final decoded = resp.body.isNotEmpty
        ? jsonDecode(resp.body)
        : <String, dynamic>{};
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Chatbot API error (${resp.statusCode})');
    }
    return data;
  }

  static Future<ChatAskResult> askQuestion({
    required String sessionId,
    required String message,
    required String surface,
    required String locale,
    String userType = 'visitor',
    String? userId,
    String? userName,
    String platform = 'web',
  }) async {
    final data = await _postAction('chatAsk', {
      'sessionId': sessionId,
      'message': message,
      'surface': surface,
      'locale': locale,
      'userContext': {
        'userType': userType,
        'userId': userId,
        'userName': userName,
        'platform': platform,
      },
    });

    final rawSources = (data['sources'] as List?) ?? [];
    return ChatAskResult(
      answer: data['answer'] as String? ?? '',
      sources: rawSources
          .whereType<Map>()
          .map((m) => ChatSource.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      messageId: data['messageId'] as String? ?? '',
      answered: data['answered'] as bool? ?? false,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      fallbackReason: data['fallbackReason'] as String?,
    );
  }

  static Future<void> submitFeedback({
    required String sessionId,
    required String messageId,
    required String value, // 'up' | 'down'
    String? comment,
  }) async {
    await _postAction('submitFeedback', {
      'sessionId': sessionId,
      'messageId': messageId,
      'value': value,
      'comment': comment ?? '',
    });
  }

  static Future<int> processDocument(String docId) async {
    final data = await _postAction('processDocument', {'docId': docId});
    return (data['chunkCount'] as num?)?.toInt() ?? 0;
  }

  static Future<int> reindexDocument(String docId) async {
    final data = await _postAction('reindexDocument', {'docId': docId});
    return (data['chunkCount'] as num?)?.toInt() ?? 0;
  }

  static Future<void> deleteDocument(String docId) async {
    await _postAction('deleteDocument', {'docId': docId});
  }

  static Future<void> embedFaq(String faqId) async {
    await _postAction('embedFaq', {'faqId': faqId});
  }

  static Future<String?> adminReviewMessage({
    required String sessionId,
    required String messageId,
    required String status, // 'correct' | 'incorrect'
    String? correctedAnswer,
    String? questionText,
    bool saveAsFaq = false,
    List<String> audience = const ['public', 'invigilator'],
    String language = 'en',
  }) async {
    final data = await _postAction('adminReviewMessage', {
      'sessionId': sessionId,
      'messageId': messageId,
      'status': status,
      'correctedAnswer': correctedAnswer,
      'questionText': questionText,
      'saveAsFaq': saveAsFaq,
      'audience': audience,
      'language': language,
    });
    return data['faqId'] as String?;
  }

  static Future<String?> resolveUnanswered({
    required String unansweredId,
    String? answer,
    String? linkedDocId,
    List<String> audience = const ['public', 'invigilator'],
    String language = 'en',
  }) async {
    final data = await _postAction('resolveUnanswered', {
      'unansweredId': unansweredId,
      'answer': answer,
      'linkedDocId': linkedDocId,
      'audience': audience,
      'language': language,
    });
    return data['faqId'] as String?;
  }

  static Future<void> flagSession({
    required String sessionId,
    required bool flagged,
  }) async {
    await _postAction('flagSession', {
      'sessionId': sessionId,
      'flagged': flagged,
    });
  }

  static Future<void> logAdminAudit({
    required String action,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    await _postAction('logAdminAudit', {
      'auditAction': action,
      'targetId': targetId,
      'details': details ?? {},
    });
  }
}

import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chatbot_message.dart';
import '../models/chatbot_settings.dart';
import '../services/chatbot_api_service.dart';

/// Live stream of chatbot settings from `chatbot_settings/config`.
final chatbotSettingsProvider =
    NotifierProvider<ChatbotSettingsNotifier, ChatbotSettings>(
        ChatbotSettingsNotifier.new);

class ChatbotSettingsNotifier extends Notifier<ChatbotSettings> {
  StreamSubscription? _sub;

  @override
  ChatbotSettings build() {
    if (Firebase.apps.isEmpty) return const ChatbotSettings();
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('chatbot_settings')
        .doc('config')
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        state = ChatbotSettings.fromMap(snap.data());
      }
    }, onError: (e) {
      log('chatbotSettings stream error: $e');
    });
    ref.onDispose(() => _sub?.cancel());
    return const ChatbotSettings();
  }
}

class ChatWidgetState {
  final String sessionId;
  final bool isOpen;
  final bool consentGiven;
  final bool isSending;
  final String? errorMessage;
  final List<ChatbotMessage> messages;

  const ChatWidgetState({
    this.sessionId = '',
    this.isOpen = false,
    this.consentGiven = false,
    this.isSending = false,
    this.errorMessage,
    this.messages = const [],
  });

  ChatWidgetState copyWith({
    String? sessionId,
    bool? isOpen,
    bool? consentGiven,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
    List<ChatbotMessage>? messages,
  }) {
    return ChatWidgetState(
      sessionId: sessionId ?? this.sessionId,
      isOpen: isOpen ?? this.isOpen,
      consentGiven: consentGiven ?? this.consentGiven,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      messages: messages ?? this.messages,
    );
  }
}

/// Family-like per-surface providers so landing and invigilator keep distinct sessions.
final landingChatProvider =
    NotifierProvider<ChatWidgetNotifier, ChatWidgetState>(
        () => ChatWidgetNotifier('landing'));

final invigilatorChatProvider =
    NotifierProvider<ChatWidgetNotifier, ChatWidgetState>(
        () => ChatWidgetNotifier('invigilator'));

class ChatWidgetNotifier extends Notifier<ChatWidgetState> {
  final String surface;
  StreamSubscription? _msgSub;
  static const _uuid = Uuid();

  ChatWidgetNotifier(this.surface);

  @override
  ChatWidgetState build() {
    ref.onDispose(() => _msgSub?.cancel());
    _initSession();
    return const ChatWidgetState();
  }

  Future<void> _initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chatbot_session_$surface';
      final consentKey = 'chatbot_consent_$surface';
      var sessionId = prefs.getString(key);
      if (sessionId == null || sessionId.isEmpty) {
        sessionId = '${surface}_${_uuid.v4()}';
        await prefs.setString(key, sessionId);
      }
      final consent = prefs.getBool(consentKey) ?? false;
      state = state.copyWith(sessionId: sessionId, consentGiven: consent);
      if (consent) {
        await ChatbotApiService.ensureAuthUser();
        _listenMessages(sessionId);
      }
    } catch (e) {
      log('ChatWidgetNotifier init error: $e');
    }
  }

  void _listenMessages(String sessionId) {
    if (Firebase.apps.isEmpty || sessionId.isEmpty) return;
    _msgSub?.cancel();
    _msgSub = FirebaseFirestore.instance
        .collection('chatbot_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) return;
      final list = snap.docs
          .map((d) => ChatbotMessage.fromFirestore(d.id, d.data()))
          .toList();
      state = state.copyWith(messages: list);
    }, onError: (e) {
      // Session doc may not exist yet before first message; reset sub so it re-attaches later
      log('Chat messages listener info: $e');
      _msgSub = null;
    });
  }

  void setOpen(bool open) {
    state = state.copyWith(isOpen: open, clearError: true);
  }

  Future<void> acceptConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chatbot_consent_$surface', true);
    } catch (_) {}
    state = state.copyWith(consentGiven: true);
    await ChatbotApiService.ensureAuthUser();
    if (state.sessionId.isNotEmpty) {
      _listenMessages(state.sessionId);
    }
  }

  Future<void> clearChat() async {
    _msgSub?.cancel();
    final newSessionId = '${surface}_${_uuid.v4()}';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chatbot_session_$surface', newSessionId);
    } catch (_) {}
    state = state.copyWith(
      sessionId: newSessionId,
      messages: const [],
      clearError: true,
    );
    _listenMessages(newSessionId);
  }

  Future<void> sendMessage({
    required String text,
    required String locale,
    String? userId,
    String? userName,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;
    if (Firebase.apps.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Offline: Firebase is not connected.',
      );
      return;
    }

    var sessionId = state.sessionId;
    if (sessionId.isEmpty) {
      sessionId = '${surface}_${_uuid.v4()}';
      state = state.copyWith(sessionId: sessionId);
    }

    final optimisticUserMsg = ChatbotMessage(
      id: 'local_u_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      isSending: true,
      clearError: true,
      messages: [...state.messages, optimisticUserMsg],
    );

    try {
      await ChatbotApiService.ensureAuthUser();
      final result = await ChatbotApiService.askQuestion(
        sessionId: sessionId,
        message: trimmed,
        surface: surface,
        locale: locale,
        userType: surface == 'invigilator' ? 'invigilator' : 'visitor',
        userId: userId,
        userName: userName,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );

      final assistantMsg = ChatbotMessage(
        id: result.messageId.isNotEmpty
            ? result.messageId
            : 'local_a_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        text: result.answer,
        createdAt: DateTime.now(),
        sources: result.sources,
        confidence: result.confidence,
        answered: result.answered,
        fallbackReason: result.fallbackReason,
      );
      final alreadyHasReply = result.messageId.isNotEmpty &&
          state.messages.any((m) => m.id == result.messageId);
      state = state.copyWith(
        isSending: false,
        messages: alreadyHasReply
            ? state.messages
            : [...state.messages, assistantMsg],
      );

      if (_msgSub == null) {
        _listenMessages(sessionId);
      }
    } catch (e) {
      log('sendMessage error: $e');
      state = state.copyWith(
        isSending: false,
        errorMessage: _friendlyError(e.toString()),
      );
    }
  }

  Future<void> submitFeedback({
    required String messageId,
    required String value,
    String? comment,
  }) async {
    if (state.sessionId.isEmpty) return;
    await ChatbotApiService.submitFeedback(
      sessionId: state.sessionId,
      messageId: messageId,
      value: value,
      comment: comment,
    );
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('resource-exhausted') || lower.contains('resource_exhausted')) {
      return 'Too many messages. Please wait a moment and try again.';
    }
    if (lower.contains('admin-restricted-operation') || lower.contains('operation-not-allowed')) {
      return 'Anonymous sign-in is disabled. Enable Anonymous Auth in Firebase Console → Authentication → Sign-in method.';
    }
    if (lower.contains('network') || lower.contains('unavailable') || lower.contains('socketexception')) {
      return 'You appear to be offline. Please check your internet connection.';
    }
    if (kDebugMode) {
      return 'Error: ${raw.replaceFirst('Exception: ', '')}';
    }
    final clean = raw.replaceFirst('Exception: ', '').trim();
    final short = clean.length > 160 ? '${clean.substring(0, 160)}...' : clean;
    return 'Unable to reach DutyDesk AI ($short)';
  }
}

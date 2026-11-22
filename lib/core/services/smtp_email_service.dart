import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'web_email_dispatcher.dart';

/// A secure service for sending transactional emails via Google Apps Script Web App
/// or Gmail SMTP.
class SmtpEmailService {
  // ==========================================
  // ⚙️ SMTP CONFIGURATION
  // ==========================================
  
  static const String _smtpHost = 'smtp.gmail.com'; 
  static const int _smtpPort = 465; 
  static const bool _useSsl = true;
  static const String _username = 'envirowatch.service@gmail.com'; 
  static const String _password = 'yuaiuwpkcdpmlcdt'; 
  static const String _fromName = 'DutyDesk Invigilator System';

  /// Google Apps Script Web App URL for email dispatch
  static const String _defaultWebGatewayUrl =
      'https://script.google.com/macros/s/AKfycbyZmP20s6AepuCxF81hPVhjWPDeQBWn6jvT54LOL9r9LlA-xfWwjhmnABoCyoEQ9Xl2/exec';

  /// In-memory cache for Web Gateway URL
  static String? _cachedGatewayUrl;

  // ==========================================
  // ✉️ EMAIL DISPATCH LOGIC
  // ==========================================

  /// Sends an email to the specified [toAddress].
  /// On Web: Uses high-reliability browser dispatch (native fetch / XHR).
  /// On Native: Uses HTTPS Web Gateway, falling back to direct Gmail SMTP socket.
  static Future<bool> sendEmail({
    required String toAddress,
    required String subject,
    required String bodyText,
  }) async {
    debugPrint('SMTP: Attempting to send email to $toAddress (Platform: ${kIsWeb ? "Web" : "Native"})...');
    
    // Resolve Gateway URL
    String gatewayUrl = _cachedGatewayUrl ?? _defaultWebGatewayUrl;
    if (_cachedGatewayUrl == null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('settings').doc('smtp').get();
        if (doc.exists && doc.data() != null) {
          final dbUrl = doc.data()?['webGatewayUrl'] as String? ?? 
                        doc.data()?['gatewayUrl'] as String?;
          if (dbUrl != null && dbUrl.trim().isNotEmpty) {
            gatewayUrl = dbUrl.trim();
          }
        }
      } catch (e) {
        debugPrint('SMTP: Could not read settings/smtp (using default): $e');
      }
      _cachedGatewayUrl = gatewayUrl;
    }

    // ── Web Platform Dispatch ──
    if (kIsWeb) {
      final success = await dispatchWebEmail(
        url: gatewayUrl,
        to: toAddress,
        subject: subject,
        body: bodyText,
        fromName: _fromName,
      );
      if (success) {
        debugPrint('SMTP: Web email delivered successfully!');
        return true;
      }
      // Fallback via http.post in case dispatchWebEmail failed
      return _sendViaHttpPost(
        gatewayUrl: gatewayUrl,
        toAddress: toAddress,
        subject: subject,
        bodyText: bodyText,
      );
    }

    // ── Native Platform Dispatch ──
    // Strategy 1: Fast HTTPS POST via Google Apps Script (immune to cellular port 465 blocking)
    try {
      final gatewaySuccess = await _sendViaHttpPost(
        gatewayUrl: gatewayUrl,
        toAddress: toAddress,
        subject: subject,
        bodyText: bodyText,
      );
      if (gatewaySuccess) {
        debugPrint('SMTP Native: Email sent via gateway successfully!');
        return true;
      }
    } catch (e) {
      debugPrint('SMTP Native Gateway failed ($e), falling back to direct SMTP...');
    }

    // Strategy 2: Direct Gmail SMTP socket fallback
    final smtpServer = SmtpServer(
      _smtpHost,
      port: _smtpPort,
      ssl: _useSsl,
      username: _username,
      password: _password,
    );

    final message = Message()
      ..from = Address(_username, _fromName)
      ..recipients.add(toAddress)
      ..subject = subject
      ..text = bodyText;

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('SMTP: Direct SMTP sent successfully! Report: $sendReport');
      return true;
    } on MailerException catch (e) {
      debugPrint('SMTP ERROR (MailerException): ${e.toString()}');
      for (var p in e.problems) {
        debugPrint('SMTP problem detail: ${p.code}: ${p.msg}');
      }
      rethrow;
    } catch (e) {
      debugPrint('SMTP ERROR (General): $e');
      rethrow;
    }
  }

  /// Dispatches email using standard HTTP POST with text/plain content type.
  static Future<bool> _sendViaHttpPost({
    required String gatewayUrl,
    required String toAddress,
    required String subject,
    required String bodyText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(gatewayUrl.trim()),
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({
          'to': toAddress,
          'subject': subject,
          'body': bodyText,
          'fromName': _fromName,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 400) {
        debugPrint('SMTP: Email sent successfully via HTTP POST! (${response.statusCode})');
        return true;
      } else {
        throw Exception('Gateway returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('SMTP HTTP POST Error: $e');
      rethrow;
    }
  }
}

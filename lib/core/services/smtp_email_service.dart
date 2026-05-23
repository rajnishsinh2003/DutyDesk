import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// A secure, client-side service for sending programmatic emails via SMTP directly from
/// the application (Android/iOS platforms only).
/// 
/// > [!NOTE]
/// > Because this uses raw TCP socket connections, it is only supported on mobile platforms.
/// > Attempting to use this on Flutter Web will result in socket errors due to browser restrictions.
class SmtpEmailService {
  // ==========================================
  // ⚙️ SMTP CONFIGURATION
  // ==========================================
  
  /// The SMTP server hostname.
  /// Common values:
  /// - Gmail: `smtp.gmail.com`
  /// - Outlook: `smtp.office365.com`
  /// - Yahoo: `smtp.mail.yahoo.com`
  static const String _smtpHost = 'smtp.gmail.com'; 

  /// The port your SMTP server uses.
  /// Common values:
  /// - `465` (SSL - Recommended for secure direct SMTP)
  /// - `587` (TLS / StartTLS - Often used with SSL set to false)
  static const int _smtpPort = 465; 

  /// Enable SSL connection. 
  /// Set to `true` if using port `465`. Set to `false` if using port `587` or `25`.
  static const bool _useSsl = true;

  /// Your SMTP account username (usually your full email address).
  static const String _username = 'envirowatch.service@gmail.com'; 

  /// Your SMTP account password.
  /// 
  /// > [!IMPORTANT]
  /// > If you are using **Gmail**, you CANNOT use your standard account password!
  /// > You must generate a 16-character **App Password** from your Google Account settings:
  /// > 1. Go to Google Account Settings -> Security.
  /// > 2. Enable 2-Step Verification if not already enabled.
  /// > 3. Search for "App Passwords" and create one (select App: 'Other', name: 'DutyDesk').
  /// > 4. Copy the 16-character password and paste it below.
  static const String _password = 'yuaiuwpkcdpmlcdt'; 

  /// The display name shown to recipients in their email inbox.
  static const String _fromName = 'DutyDesk Invigilator System';

  // ==========================================
  // ✉️ EMAIL DISPATCH LOGIC
  // ==========================================

  /// Sends a plain text email to the specified [toAddress].
  /// Returns `true` if successful, otherwise throws an exception with descriptive SMTP logs.
  static Future<bool> sendEmail({
    required String toAddress,
    required String subject,
    required String bodyText,
  }) async {
    debugPrint('SMTP: Attempting to send email to $toAddress...');
    
    // 1. Establish the SMTP server config
    final smtpServer = SmtpServer(
      _smtpHost,
      port: _smtpPort,
      ssl: _useSsl,
      username: _username,
      password: _password,
    );

    // 2. Prepare the transactional message
    final message = Message()
      ..from = Address(_username, _fromName)
      ..recipients.add(toAddress)
      ..subject = subject
      ..text = bodyText;

    try {
      // 3. Dispatch email
      final sendReport = await send(message, smtpServer);
      debugPrint('SMTP: Email sent successfully! Report: $sendReport');
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
}

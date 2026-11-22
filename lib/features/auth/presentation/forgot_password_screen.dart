import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../core/services/smtp_email_service.dart';

/// Forgot Password Screen — 3-Step OTP-based password (Resource ID) reset
/// for Invigilators.
///
/// Step 1: Enter registered mobile number or email
/// Step 2: Verify 6-digit OTP sent via email
/// Step 3: Set a new Resource ID (password)
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // ── Step Management ──
  int _currentStep = 0; // 0 = Enter Mobile, 1 = OTP Verify, 2 = New Password

  // ── Controllers ──
  final _mobileController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // ── State ──
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // ── OTP State ──
  String? _resolvedEmail; // The email we found and sent OTP to
  String? _resolvedInvigilatorDocId;
  String? _resolvedInvigilatorName;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  // ── Animation ──
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }


  // ─────────────────────────────────────────────────────
  // STEP 1: Look up invigilator by mobile/email/ID → send OTP
  // ─────────────────────────────────────────────────────
  Future<void> _handleSendOtp() async {
    final input = _mobileController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Please enter your registered mobile number, email, or Resource ID.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (Firebase.apps.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Firebase is not initialized. Please check your internet connection.';
        });
        return;
      }

      // Search Firestore for matching invigilator
      QuerySnapshot? snapshot;
      final cleanInput = input.trim();
      final lowerInput = cleanInput.toLowerCase();
      final digitsOnly = cleanInput.replaceAll(RegExp(r'\D'), '');

      // 1. Try mobile first
      snapshot = await FirebaseFirestore.instance
          .collection('invigilators')
          .where('mobile', isEqualTo: cleanInput)
          .limit(1)
          .get();

      // 1b. If mobile has 10 digits, match last 10 digits
      if (snapshot.docs.isEmpty && digitsOnly.isNotEmpty) {
        final last10 = digitsOnly.length >= 10
            ? digitsOnly.substring(digitsOnly.length - 10)
            : digitsOnly;
        final res = await FirebaseFirestore.instance
            .collection('invigilators')
            .where('mobile', isEqualTo: last10)
            .limit(1)
            .get();
        if (res.docs.isNotEmpty) {
          snapshot = res;
        }
      }

      // 2. Try email match
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('invigilators')
            .where('email', isEqualTo: lowerInput)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('invigilators')
            .where('email', isEqualTo: cleanInput)
            .limit(1)
            .get();
      }

      // 3. Try resourceId / Staff ID match
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('invigilators')
            .where('resourceId', isEqualTo: cleanInput)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('invigilators')
            .where('resourceId', isEqualTo: cleanInput.toUpperCase())
            .limit(1)
            .get();
      }

      String docId;
      String recipientEmail;
      String invName;
      String userMobile = '';

      if (snapshot.docs.isEmpty) {
        final isAdminIdentifier = lowerInput == 'admin' ||
            lowerInput == 'admin@dutydesk.com' ||
            lowerInput == 'admin@gmail.com' ||
            lowerInput == 'envirowatch.service@gmail.com' ||
            lowerInput == 'examadmin';

        if (isAdminIdentifier) {
          docId = 'admin-master';
          recipientEmail = 'envirowatch.service@gmail.com';
          invName = 'Chief Examination Admin';
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'No user or invigilator found with this mobile number, email, or Resource ID. Please check your details.';
          });
          return;
        }
      } else {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final email = data['email'] as String?;
        final name = data['name'] as String? ?? 'Invigilator';
        final mobile = data['mobile'] as String? ?? '';

        if (email == null || email.trim().isEmpty || !email.contains('@') || email.trim().endsWith('@dutydesk.local')) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'No registered email address found for this account. Please contact your examination administrator to update your email address in DutyDesk.';
          });
          return;
        }

        docId = doc.id;
        recipientEmail = email.trim();
        invName = name;
        userMobile = mobile;
      }

      _resolvedEmail = recipientEmail;
      _resolvedInvigilatorDocId = docId;
      _resolvedInvigilatorName = invName;

      // Generate 6-digit OTP on our end
      final otp = _generateOtp();

      // Store OTP in Firestore with 10 minute expiration
      await FirebaseFirestore.instance.collection('password_reset_otps').doc(docId).set({
        'otp': otp,
        'email': _resolvedEmail,
        'mobile': userMobile,
        'invigilatorName': invName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
        'verified': false,
        'attempts': 0,
      });

      // Dispatch OTP email
      try {
        await SmtpEmailService.sendEmail(
          toAddress: _resolvedEmail!,
          subject: 'DutyDesk — Password Reset OTP',
          bodyText: 'Dear $invName,\n\n'
              'Your one-time password (OTP) for resetting your DutyDesk credentials is:\n\n'
              '    $otp\n\n'
              'This OTP is valid for 10 minutes. Do not share it with anyone.\n\n'
              'If you did not request this, please ignore this email.\n\n'
              'Regards,\nDutyDesk Examination Management System',
        );
      } catch (e) {
        debugPrint('Email send error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to deliver OTP to ${_maskEmail(_resolvedEmail!)}. Please check your internet connection and try again.';
        });
        return;
      }

      // Start resend cooldown
      _startResendCooldown();

      // Advance to Step 2
      setState(() {
        _isLoading = false;
        _currentStep = 1;
        _successMessage = 'A 6-digit OTP has been sent to ${_maskEmail(_resolvedEmail!)}. Please check your email inbox and spam folder.';
      });
      _animController.reset();
      _animController.forward();

      // Clean notification snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'OTP sent to ${_maskEmail(_resolvedEmail!)}. Please check your email.',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF007A87),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Focus first OTP box
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong: ${e.toString()}';
      });
    }
  }

  // ─────────────────────────────────────────────────────
  // STEP 2: Verify OTP
  // ─────────────────────────────────────────────────────
  Future<void> _handleVerifyOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();

    if (enteredOtp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Read OTP document from Firestore
      final docRef = FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(_resolvedInvigilatorDocId);
      final otpDoc = await docRef.get();

      if (!otpDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'OTP has expired or is invalid. Please request a new one.';
        });
        return;
      }

      final data = otpDoc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = (data['attempts'] as int?) ?? 0;

      // Check max attempts (5)
      if (attempts >= 5) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Too many incorrect attempts. Please request a new OTP.';
        });
        return;
      }

      // Check expiration
      if (DateTime.now().isAfter(expiresAt)) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'OTP has expired. Please request a new one.';
        });
        return;
      }

      // Increment attempts
      await docRef.update({'attempts': attempts + 1});

      // Verify
      if (enteredOtp != storedOtp) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Incorrect OTP. ${4 - attempts} attempts remaining.';
        });
        return;
      }

      // Mark as verified
      await docRef.update({'verified': true});

      // Advance to Step 3
      setState(() {
        _isLoading = false;
        _currentStep = 2;
        _successMessage = 'OTP verified successfully! Set your new password.';
      });
      _animController.reset();
      _animController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed: ${e.toString()}';
      });
    }
  }

  // ─────────────────────────────────────────────────────
  // STEP 3: Set new Resource ID (password)
  // ─────────────────────────────────────────────────────
  Future<void> _handleResetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new Resource ID / Password.');
      return;
    }
    if (newPassword.length < 4) {
      setState(() => _errorMessage = 'Resource ID must be at least 4 characters long.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match. Please re-enter.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Double-check OTP was verified
      final otpDoc = await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(_resolvedInvigilatorDocId)
          .get();

      if (!otpDoc.exists || otpDoc.data()?['verified'] != true) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'OTP verification expired. Please start over.';
        });
        return;
      }

      // Update password in Firestore
      if (_resolvedInvigilatorDocId == 'admin-master') {
        await FirebaseFirestore.instance.collection('settings').doc('admin_credentials').set({
          'password': newPassword,
          'passwordUpdatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _resolvedEmail,
        }, SetOptions(merge: true));
      } else {
        // Update the resourceId in invigilators collection
        await FirebaseFirestore.instance
            .collection('invigilators')
            .doc(_resolvedInvigilatorDocId)
            .update({
          'resourceId': newPassword,
          'passwordUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Clean up the OTP document
      await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(_resolvedInvigilatorDocId)
          .delete();

      // Send confirmation email (mobile only)
      if (!kIsWeb) {
        try {
          await SmtpEmailService.sendEmail(
            toAddress: _resolvedEmail!,
            subject: 'DutyDesk — Password Reset Successful',
            bodyText: 'Dear ${_resolvedInvigilatorName ?? 'Invigilator'},\n\n'
                'Your DutyDesk login credentials have been successfully updated.\n\n'
                'You can now log in with your registered mobile number and your new Resource ID.\n\n'
                'If you did not make this change, please contact your administrator immediately.\n\n'
                'Regards,\nDutyDesk Examination Management System',
          );
        } catch (_) {
          // Email confirmation is best-effort
        }
      }

      if (!mounted) return;

      // Show success dialog then navigate back
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A87).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF007A87), size: 56),
              ),
              const SizedBox(height: 20),
              const Text(
                'Password Reset Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your credentials have been updated.\nYou can now log in with your new Resource ID.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A87),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/login');
                  },
                  child: const Text('Go to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Reset failed: ${e.toString()}';
      });
    }
  }

  // ─────────────────────────────────────────────────────
  // Resend OTP
  // ─────────────────────────────────────────────────────
  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otp = _generateOtp();

      await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(_resolvedInvigilatorDocId)
          .set({
        'otp': otp,
        'email': _resolvedEmail,
        'invigilatorName': _resolvedInvigilatorName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
        'verified': false,
        'attempts': 0,
      });

      try {
        await SmtpEmailService.sendEmail(
          toAddress: _resolvedEmail!,
          subject: 'DutyDesk — Password Reset OTP (Resent)',
          bodyText: 'Dear ${_resolvedInvigilatorName ?? 'Invigilator'},\n\n'
              'Your new one-time password (OTP) is:\n\n'
              '    $otp\n\n'
              'This OTP is valid for 10 minutes.\n\n'
              'Regards,\nDutyDesk Examination Management System',
        );
      } catch (e) {
        debugPrint('Resend email error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to resend OTP email. Please try again in a few moments.';
        });
        return;
      }

      // Clear old OTP entries
      for (final c in _otpControllers) {
        c.clear();
      }

      _startResendCooldown();

      setState(() {
        _isLoading = false;
        _successMessage = 'A new 6-digit OTP has been sent to ${_maskEmail(_resolvedEmail!)}.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'New verification OTP sent to ${_maskEmail(_resolvedEmail!)}.',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF007A87),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to resend OTP: ${e.toString()}';
      });
    }
  }

  // ─────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────
  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '***@$domain';
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double score = 0;
    if (password.length >= 4) score += 0.2;
    if (password.length >= 6) score += 0.15;
    if (password.length >= 8) score += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) score += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) score += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.2;
    return score.clamp(0, 1);
  }

  String _getStrengthLabel(double strength) {
    if (strength <= 0) return '';
    if (strength < 0.35) return 'Weak';
    if (strength < 0.65) return 'Fair';
    if (strength < 0.85) return 'Good';
    return 'Strong';
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.35) return Colors.red;
    if (strength < 0.65) return Colors.orange;
    if (strength < 0.85) return const Color(0xFF007A87);
    return Colors.green;
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final inputBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    const brandColor = Color(0xFF007A87);
    const brandGradient = LinearGradient(
      colors: [Color(0xFF007A87), Color(0xFF005B66)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glow
            Positioned(
              top: -60,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      brandColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 14,
              left: 18,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'Back to Login',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
              ),
            ),

            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // ── Icon & Title ──
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: brandColor.withValues(alpha: isDark ? 0.15 : 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 2),
                              ),
                              child: Icon(
                                _currentStep == 0
                                    ? Icons.lock_reset_rounded
                                    : _currentStep == 1
                                        ? Icons.sms_outlined
                                        : Icons.vpn_key_rounded,
                                color: brandColor,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentStep == 0
                                ? 'Forgot Password?'
                                : _currentStep == 1
                                    ? 'Verify OTP'
                                    : 'Set New Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentStep == 0
                                ? 'Enter your registered mobile number, email, or Resource ID.\nWe will generate a 6-digit OTP to verify your identity.'
                                : _currentStep == 1
                                    ? 'A 6-digit verification code has been generated for you.\nEnter the code or click "Auto-Fill & Verify" below.'
                                    : 'Create a new Resource ID / Password\nfor your DutyDesk account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                              height: 1.5,
                            ),
                          ),

                          // ── Step Progress Indicator ──
                          const SizedBox(height: 24),
                          _buildStepIndicator(brandColor, secondaryTextColor, primaryTextColor),
                          const SizedBox(height: 24),

                          // ── Success / Error Messages ──
                          if (_successMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _successMessage!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.greenAccent : Colors.green.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ── Main Card ──
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: cardBorderColor, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _currentStep == 0
                                ? _buildStep1(primaryTextColor, secondaryTextColor, inputFillColor,
                                    inputBorderColor, brandColor, brandGradient)
                                : _currentStep == 1
                                    ? _buildStep2(primaryTextColor, secondaryTextColor, inputFillColor,
                                        inputBorderColor, brandColor, brandGradient, isDark)
                                    : _buildStep3(primaryTextColor, secondaryTextColor, inputFillColor,
                                        inputBorderColor, brandColor, brandGradient, isDark),
                          ),
                          const SizedBox(height: 20),

                          // Help text
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: brandColor.withValues(alpha: isDark ? 0.12 : 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: brandColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 18, color: brandColor),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _currentStep == 0
                                        ? 'Enter your registered mobile number, email, or Resource ID to reset your credentials.'
                                        : _currentStep == 1
                                            ? 'OTP is securely generated on your end and valid for 10 minutes. Click "Auto-Fill & Verify" to proceed.'
                                            : 'Your new Resource ID will be used to log in. Keep it safe and do not share it.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : const Color(0xFF005B66),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP PROGRESS INDICATOR
  // ─────────────────────────────────────────────────────
  Widget _buildStepIndicator(Color brandColor, Color secondaryColor, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'Identity', brandColor, secondaryColor, primaryColor),
        _buildStepLine(0, brandColor, secondaryColor),
        _buildStepDot(1, 'Verify', brandColor, secondaryColor, primaryColor),
        _buildStepLine(1, brandColor, secondaryColor),
        _buildStepDot(2, 'Reset', brandColor, secondaryColor, primaryColor),
      ],
    );
  }

  Widget _buildStepDot(int step, String label, Color brandColor, Color secondaryColor, Color primaryColor) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 36 : 28,
          height: isCurrent ? 36 : 28,
          decoration: BoxDecoration(
            color: isActive ? brandColor : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? brandColor : secondaryColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: isCurrent
                ? [BoxShadow(color: brandColor.withValues(alpha: 0.3), blurRadius: 10)]
                : null,
          ),
          child: Center(
            child: isActive
                ? Icon(
                    _currentStep > step ? Icons.check_rounded : Icons.circle,
                    size: _currentStep > step ? 16 : 8,
                    color: Colors.white,
                  )
                : Text(
                    '${step + 1}',
                    style: TextStyle(fontSize: 12, color: secondaryColor, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? primaryColor : secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep, Color brandColor, Color secondaryColor) {
    final isActive = _currentStep > afterStep;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 2.5,
        decoration: BoxDecoration(
          color: isActive ? brandColor : secondaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP 1: Enter Mobile/Email
  // ─────────────────────────────────────────────────────
  Widget _buildStep1(Color primaryText, Color secondaryText, Color fillColor,
      Color borderColor, Color brandColor, LinearGradient gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Registered Mobile or Email',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. 9876543210 or name@email.com',
            hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.7), fontSize: 14),
            prefixIcon: const Icon(Icons.person_search_outlined, color: Color(0xFF007A87)),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007A87), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton('Send OTP', _handleSendOtp, gradient, brandColor),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP 2: OTP Input & Verification Card
  // ─────────────────────────────────────────────────────
  Widget _buildStep2(
    Color primaryText,
    Color secondaryText,
    Color fillColor,
    Color borderColor,
    Color brandColor,
    LinearGradient gradient,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Email Verification Info Banner ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: brandColor.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: brandColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, size: 20, color: Color(0xFF007A87)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification code sent via email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'We have sent a 6-digit OTP to ${_maskEmail(_resolvedEmail ?? '')}.\nPlease check your inbox and spam folder.',
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── 2. Manual OTP Input Field Boxes ──
        Text(
          'Enter 6-Digit OTP',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText),
        ),
        const SizedBox(height: 14),

        // OTP Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF007A87), width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  } else if (value.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                  // Auto-submit when all 6 digits entered
                  if (i == 5 && value.isNotEmpty) {
                    final allFilled = _otpControllers.every((c) => c.text.isNotEmpty);
                    if (allFilled) _handleVerifyOtp();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 18),

        // Resend OTP
        Center(
          child: _resendCooldown > 0
              ? Text(
                  'Resend OTP in ${_resendCooldown}s',
                  style: TextStyle(fontSize: 13, color: secondaryText, fontWeight: FontWeight.w600),
                )
              : TextButton.icon(
                  onPressed: _handleResendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF007A87)),
                  label: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF007A87),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 18),
        _buildPrimaryButton('Verify OTP', _handleVerifyOtp, gradient, brandColor),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // STEP 3: New Password
  // ─────────────────────────────────────────────────────
  Widget _buildStep3(Color primaryText, Color secondaryText, Color fillColor,
      Color borderColor, Color brandColor, LinearGradient gradient, bool isDark) {
    final strength = _getPasswordStrength(_newPasswordController.text);
    final strengthLabel = _getStrengthLabel(strength);
    final strengthColor = _getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Verified user info
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: brandColor.withValues(alpha: isDark ? 0.1 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: brandColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: brandColor.withValues(alpha: 0.15),
                child: Text(
                  (_resolvedInvigilatorName ?? 'I')[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007A87),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resolvedInvigilatorName ?? 'Invigilator',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryText),
                    ),
                    Text(
                      _maskEmail(_resolvedEmail ?? ''),
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_rounded, color: Color(0xFF007A87), size: 22),
            ],
          ),
        ),

        // New Password
        Text(
          'New Resource ID / Password',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Enter new Resource ID',
            hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.7), fontSize: 14),
            prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF007A87)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: secondaryText,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007A87), width: 2),
            ),
          ),
        ),

        // Password strength bar
        if (_newPasswordController.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength,
                    backgroundColor: secondaryText.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                strengthLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: strengthColor),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Confirm Password
        Text(
          'Confirm Password',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Re-enter new Resource ID',
            hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.7), fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF007A87)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: secondaryText,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007A87), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton('Reset Password', _handleResetPassword, gradient, brandColor),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // Primary Action Button
  // ─────────────────────────────────────────────────────
  Widget _buildPrimaryButton(
      String label, VoidCallback onPressed, LinearGradient gradient, Color brandColor) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
      ),
    );
  }
}

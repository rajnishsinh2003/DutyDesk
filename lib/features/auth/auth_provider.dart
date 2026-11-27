import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_api_service.dart';

// User Roles for Role-Based Access Control (RBAC)
enum UserRole { admin, invigilator, finance, auditor, none }

class AuthState {
  final bool isLoading;
  final UserRole role;
  final String? error;
  final String? userId; // Store the authenticated doc ID or UID
  final String? userName;

  AuthState({
    this.isLoading = false,
    this.role = UserRole.none,
    this.error,
    this.userId,
    this.userName,
  });

  AuthState copyWith({
    bool? isLoading,
    UserRole? role,
    String? error,
    String? userId,
    String? userName,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      role: role ?? this.role,
      error: error ?? this.error,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _initFromPreferences();

    if (Firebase.apps.isNotEmpty) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.email != null) {
          final emailLower = currentUser.email!.toLowerCase();
          if (emailLower.contains('finance')) {
            return AuthState(role: UserRole.finance, userId: currentUser.uid, userName: 'Finance Officer');
          } else if (emailLower.contains('auditor') || emailLower.contains('observer')) {
            return AuthState(role: UserRole.auditor, userId: currentUser.uid, userName: 'Observer / Auditor');
          } else {
            return AuthState(role: UserRole.admin, userId: currentUser.uid, userName: 'Admin User');
          }
        }
      } catch (e) {
        debugPrint("Error reading current auth user: $e");
      }
    }
    return AuthState();
  }

  void _initFromPreferences() async {
    await restoreSession();
  }

  Future<AuthState> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleStr = prefs.getString('role');
      final userId = prefs.getString('userId');
      final userName = prefs.getString('userName');

      if (roleStr != null && userId != null && userId.isNotEmpty) {
        UserRole role = UserRole.none;
        if (roleStr == 'admin') role = UserRole.admin;
        if (roleStr == 'invigilator') role = UserRole.invigilator;
        if (roleStr == 'finance') role = UserRole.finance;
        if (roleStr == 'auditor') role = UserRole.auditor;

        if (role != UserRole.none) {
          final newState = AuthState(
            role: role,
            userId: userId,
            userName: userName ?? _roleDisplayName(role),
          );
          state = newState;
          return newState;
        }
      }
    } catch (e) {
      debugPrint("Error restoring auth session: $e");
    }
    return state;
  }

  String _roleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Admin User';
      case UserRole.finance: return 'Finance Officer';
      case UserRole.auditor: return 'Auditor';
      case UserRole.invigilator: return 'Invigilator';
      case UserRole.none: return 'User';
    }
  }

  void setSession({
    required UserRole role,
    required String userId,
    required String userName,
  }) async {
    state = AuthState(
      role: role,
      userId: userId,
      userName: userName,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', role.name);
      await prefs.setString('userId', userId);
      await prefs.setString('userName', userName);
    } catch (e) {
      debugPrint('Failed to persist session preferences: $e');
    }
  }

  /// 1-Click Instant Demo Authentication for rapid evaluation of all 4 roles.
  /// Restricted to debug builds only.
  Future<void> loginAsDemoRole(UserRole role) async {
    if (!kDebugMode) {
      state = state.copyWith(
        isLoading: false,
        error: 'Demo login is disabled in release builds.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 300));

    String userId;
    String userName;
    String roleStr;

    switch (role) {
      case UserRole.admin:
        userId = 'admin-master';
        userName = 'Chief Examination Controller';
        roleStr = 'admin';
        break;
      case UserRole.finance:
        userId = 'finance-001';
        userName = 'Rajesh Varma (Finance Officer)';
        roleStr = 'finance';
        break;
      case UserRole.auditor:
        userId = 'auditor-001';
        userName = 'Dr. K. Sharma (NTA Chief Observer)';
        roleStr = 'auditor';
        break;
      case UserRole.invigilator:
        userId = 'demo-inv-01';
        userName = 'Prof. Anand Patel';
        roleStr = 'invigilator';
        break;
      case UserRole.none:
        state = AuthState();
        return;
    }

    state = AuthState(
      isLoading: false,
      role: role,
      userId: userId,
      userName: userName,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', roleStr);
      await prefs.setString('userId', userId);
      await prefs.setString('userName', userName);
    } catch (e) {
      debugPrint('Failed to persist demo session preferences: $e');
    }
  }

  Future<void> login(String mobile, String password, bool isAdminLogin) async {
    state = state.copyWith(isLoading: true, error: null);

    final cleanMobile = mobile.trim();
    final cleanPassword = password.trim();
    final lowerMobile = cleanMobile.toLowerCase();

    if (cleanMobile.isEmpty || cleanPassword.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Please enter both username/mobile and password.',
      );
      return;
    }

    // Determine if this should be treated as an Admin / Staff-Officer login
    final shouldTreatAsAdmin = isAdminLogin ||
        lowerMobile.contains('admin') ||
        lowerMobile.contains('finance') ||
        lowerMobile.contains('auditor') ||
        cleanMobile.contains('@');

    if (shouldTreatAsAdmin) {
      if (Firebase.apps.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Firebase is not initialized. Check internet connection.',
        );
        return;
      }

      try {
        final email = cleanMobile.contains('@') ? cleanMobile : '$cleanMobile@dutydesk.com';
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: cleanPassword,
        );

        final idTokenResult = await userCredential.user?.getIdTokenResult(true);
        final claims = idTokenResult?.claims ?? const <String, dynamic>{};

        UserRole targetRole = UserRole.admin;
        String displayName = 'Admin User';
        final emailLower = email.toLowerCase();
        if (claims['finance'] == true ||
            emailLower.contains('finance') ||
            emailLower.contains('account')) {
          targetRole = UserRole.finance;
          displayName = 'Finance Officer';
        } else if (claims['auditor'] == true ||
            emailLower.contains('auditor') ||
            emailLower.contains('observer')) {
          targetRole = UserRole.auditor;
          displayName = 'Observer / Auditor';
        } else if (claims['admin'] == true) {
          targetRole = UserRole.admin;
          displayName = 'Admin User';
        }

        state = state.copyWith(
          isLoading: false,
          role: targetRole,
          userId: userCredential.user?.uid,
          userName: displayName,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', targetRole.name);
        await prefs.setString('userId', userCredential.user?.uid ?? 'admin-user');
        await prefs.setString('userName', displayName);
      } on FirebaseAuthException catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.message ?? 'Authentication failed',
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    } else {
      // Invigilator Login: Verify server-side via auth-api & sign in with Firebase Custom Token
      if (Firebase.apps.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Firebase is not initialized. Check internet connection.',
        );
        return;
      }

      try {
        final result = await AuthApiService.loginInvigilator(
          identifier: cleanMobile,
          password: cleanPassword,
        );

        final customToken = result['customToken'] as String?;
        final userId = result['userId'] as String?;
        final userName = (result['userName'] as String?) ?? 'Invigilator';

        if (customToken == null || customToken.isEmpty || userId == null || userId.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Authentication failed. Please try again.',
          );
          return;
        }

        await FirebaseAuth.instance.signInWithCustomToken(customToken);

        state = state.copyWith(
          isLoading: false,
          role: UserRole.invigilator,
          userId: userId,
          userName: userName,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', 'invigilator');
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userName);
      } on AuthApiException catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.message,
        );
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Firebase signOut error: $e');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          if (currentUser.email!.startsWith('admin')) {
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
    } catch (_) {}
  }

  /// 1-Click Instant Demo Authentication for rapid evaluation of all 4 roles.
  Future<void> loginAsDemoRole(UserRole role) async {
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
    } catch (_) {}
  }

  Future<void> login(String mobile, String password, bool isAdminLogin) async {
    state = state.copyWith(isLoading: true, error: null);

    final cleanMobile = mobile.trim();
    final cleanPassword = password.trim();

    // Check for demo role keywords or offline test accounts
    final lowerMobile = cleanMobile.toLowerCase();
    if (lowerMobile == 'finance' || lowerMobile == 'finance@dutydesk.com') {
      await loginAsDemoRole(UserRole.finance);
      return;
    }
    if (lowerMobile == 'auditor' || lowerMobile == 'auditor@dutydesk.com' || lowerMobile == 'observer') {
      await loginAsDemoRole(UserRole.auditor);
      return;
    }
    if (lowerMobile == 'admin' && (cleanPassword == 'admin' || cleanPassword == 'admin123')) {
      await loginAsDemoRole(UserRole.admin);
      return;
    }

    if (Firebase.apps.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Firebase is not initialized. Use 1-Tap Demo Roles or check internet connection.',
      );
      return;
    }

    try {
      if (isAdminLogin) {
        // Admin Login: Authenticate using Firebase Auth
        final email = cleanMobile.contains('@') ? cleanMobile : '$cleanMobile@dutydesk.com';
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: cleanPassword,
        );
        
        UserRole targetRole = UserRole.admin;
        String displayName = 'Admin User';
        if (email.contains('finance') || email.contains('account')) {
          targetRole = UserRole.finance;
          displayName = 'Finance Officer';
        } else if (email.contains('auditor') || email.contains('observer')) {
          targetRole = UserRole.auditor;
          displayName = 'Observer / Auditor';
        }

        state = state.copyWith(
          isLoading: false,
          role: targetRole,
          userId: userCredential.user?.uid,
          userName: displayName,
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', targetRole.name);
        await prefs.setString('userId', userCredential.user!.uid);
        await prefs.setString('userName', displayName);
      } else {
        // Invigilator Login: Verify against invigilators collection in Firestore
        final querySnapshot = await FirebaseFirestore.instance
            .collection('invigilators')
            .where('mobile', isEqualTo: cleanMobile)
            .where('resourceId', isEqualTo: cleanPassword)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          final name = doc.data()['name'] ?? 'Invigilator';
          state = state.copyWith(
            isLoading: false,
            role: UserRole.invigilator,
            userId: doc.id,
            userName: name,
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('role', 'invigilator');
          await prefs.setString('userId', doc.id);
          await prefs.setString('userName', name);
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Invalid Mobile Number or Resource ID',
          );
        }
      }
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
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simulating User Roles
enum UserRole { admin, invigilator, none }

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

  Future<void> login(String mobile, String password, bool isAdminLogin) async {
    state = state.copyWith(isLoading: true, error: null);

    final cleanMobile = mobile.trim();
    final cleanPassword = password.trim();

    if (Firebase.apps.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Firebase is not initialized. Please check internet connection or configuration.',
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
        
        state = state.copyWith(
          isLoading: false,
          role: UserRole.admin,
          userId: userCredential.user?.uid,
          userName: 'Admin User',
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', 'admin');
        await prefs.setString('userId', userCredential.user!.uid);
        await prefs.setString('userName', 'Admin User');
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

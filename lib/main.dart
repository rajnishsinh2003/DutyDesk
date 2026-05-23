import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // 📱 Native Platform Configuration (Android/iOS)
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  } else {
    // 🌐 Live Firebase Web Configuration for Chrome testing!
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBuhEbX0KML2y9OE-QnzzfJB-MgWFrHNSw",
          authDomain: "exam-duty-9232f.firebaseapp.com",
          databaseURL: "https://exam-duty-9232f-default-rtdb.firebaseio.com",
          projectId: "exam-duty-9232f",
          storageBucket: "exam-duty-9232f.firebasestorage.app",
          messagingSenderId: "1025808601181",
          appId: "1:1025808601181:web:94e517f8029beeaa14bdb4",
          measurementId: "G-B1TDTMVM94",
        ),
      );
      debugPrint("Firebase Web initialized successfully on Chrome!");
    } catch (e) {
      debugPrint("Firebase Web initialization failed: $e");
    }
  }

  runApp(const ProviderScope(child: DutyDeskApp()));
}

class DutyDeskApp extends StatelessWidget {
  const DutyDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DutyDesk - Exam Invigilation Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

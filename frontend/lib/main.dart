import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/twitter_interface_page.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyB9tXQDbmNNf9GWT5j_G8AO5t45dnn6z_M",
          authDomain: "twitter-interface.firebaseapp.com",
          projectId: "twitter-interface",
          storageBucket: "twitter-interface.firebasestorage.app",
          messagingSenderId: "1027579756280",
          appId: "1:1027579756280:web:c613471ad55e190e0d450d",
          measurementId: "G-X9K7WQV7N6"
        ),
      );
    }
    // Configure StorageService for local development backend and R2 access
    StorageService.instance.setBaseUrl('http://localhost:3000');
    StorageService.instance.setR2Config('7e522f48fc9caa30e3d2f43cc80b789c', 'twitter-interface');
    StorageService.instance.setCompanyId('company456');

    runApp(const MyApp());
  } catch (e) {
    print('Firebase initialization error: $e');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Company Feed',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          surface: Color(0xFF0F172A),
          onSurface: Color(0xFFE2E8F0),
          surfaceVariant: Color(0xFF1E293B),
          outline: Color(0xFF334155),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Color(0xFFE2E8F0),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6)),
          ),
        ),
        cardColor: const Color(0xFF1E293B),
        dividerColor: const Color(0xFF334155),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
          bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
          headlineSmall: TextStyle(
            color: Color(0xFFE2E8F0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const TwitterInterfacePageFixed(
        userId: 'user123',
        companyId: 'company456',
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

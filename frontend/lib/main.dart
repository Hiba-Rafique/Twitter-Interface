import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/fortune_feed_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only if not already initialized
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
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fortune 500 Company Feed',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066CC),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1A),
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0066CC),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0066CC)),
          ),
        ),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE5E7EB),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
          bodyMedium: TextStyle(color: Color(0xFF6B7280)),
          headlineSmall: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: FortuneFeedPage(
        userId: 'user123', // Replace with actual user ID
        companyId: 'company456', // Replace with actual company ID
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

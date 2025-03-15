import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'firebase_options.dart';
import 'auth/auth_wrapper.dart';
import 'utils/theme_colors.dart';
import 'auth/auth_screen.dart';
import 'auth/signup_screen.dart';
import 'dashboard/dashboard_screen.dart';  // Import the new dashboard screen

// Initialize logger
final Logger _logger = Logger('AssetFlowApp');

void main() async {
  // Configure logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Use Flutter's developer mode logger or write to a file in production
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fix for duplicate Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If the app is already initialized, catch the error but continue
    if (e.toString().contains('duplicate-app')) {
      _logger.info('Firebase already initialized, continuing...');
    } else {
      // If it's another error, rethrow it
      _logger.severe('Firebase initialization error: $e');
      rethrow;
    }
  }
  
  // Run the app
  runApp(const AssetFlowApp());
}

/// Main application widget
class AssetFlowApp extends StatelessWidget {
  const AssetFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssetFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AssetFlowColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AssetFlowColors.primary,
          primary: AssetFlowColors.primary,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AssetFlowColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: AssetFlowColors.primary, width: 2.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AssetFlowColors.primary,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AssetFlowColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
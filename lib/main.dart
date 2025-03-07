import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'firebase_options.dart';
import 'auth/auth_wrapper.dart';
import 'utils/theme_colors.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization with safe error handling
  try {
    // First try to get the default app
    Firebase.app();
    print("Using existing Firebase app");
  } catch (e) {
    try {
      // If no app exists, initialize a new one
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Initialized new Firebase app");
    } catch (e) {
      // Handle any initialization errors
      print("Firebase initialization error: $e");
      // You can add fallback behavior here if needed
    }
  }
  
  // Enable logging
  _setupLogging();
  
  // Run the app
  runApp(const AssetFlowApp());
}

/// Setup logging configuration
void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final emoji = _getLogLevelEmoji(record.level);
    print('$emoji ${record.time} | ${record.loggerName} | ${record.level.name}: ${record.message}');
    
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });
}

/// Get emoji for log level visualization
String _getLogLevelEmoji(Level level) {
  if (level == Level.SEVERE) return '🔴';
  if (level == Level.WARNING) return '🟠';
  if (level == Level.INFO) return '🔵';
  if (level == Level.CONFIG) return '⚙️';
  if (level == Level.FINE || level == Level.FINER || level == Level.FINEST) return '🟢';
  return '📝';
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
      home: AuthWrapper(),
    );
  }
}
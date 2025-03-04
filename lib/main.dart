import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';

// Import local files
import 'Backup_firebase_options.dart';
import 'utils/logger_util.dart';
import 'start/splash_screen.dart';

// Main application entry point
void main() async {
  // Ensure Flutter binding is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging with a comprehensive and informative setup
  LoggerUtil.configureLogging();

  // Create a dedicated logger for app initialization
  final logger = Logger('AppInitialization');

  try {
    // Log the start of Firebase initialization
    logger.info('Attempting to initialize Firebase');
    
    // Initialize Firebase with platform-specific configuration
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Log successful Firebase initialization
    logger.info('Firebase initialization completed successfully');

    // Run the main application
    runApp(const AssetFlowApp());
  } catch (e, stackTrace) {
    // Log any critical errors during initialization
    logger.severe(
      'Critical error during app initialization', 
      e, 
      stackTrace
    );
    
    // Run a custom error app to show the fatal error
    runApp(ErrorApp(error: e));
  }
}

// Error display app for critical initialization failures
class ErrorApp extends StatelessWidget {
  final Object error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline, 
                color: Colors.red[800], 
                size: 100
              ),
              const SizedBox(height: 20),
              Text(
                'App Initialization Failed',
                style: TextStyle(
                  color: Colors.red[800],
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error Details: $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 16
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main application widget
class AssetFlowApp extends StatelessWidget {
  static final Logger _logger = Logger('AssetFlowApp');

  const AssetFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.info('AssetFlowApp built.');
    return MaterialApp(
      title: 'AssetFlow',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: const SplashScreen(),
    );
  }
  
  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.indigo,
      brightness: Brightness.light,
      useMaterial3: true,
      
      // Button themes - using MaterialStateProperty for proper styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(const Size(double.infinity, 55)),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
          foregroundColor: MaterialStateProperty.all(Colors.white), // Text color
          backgroundColor: MaterialStateProperty.all(Colors.indigo), // Button background
          elevation: MaterialStateProperty.all(4.0),
          alignment: Alignment.center, // Center the button content
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(const Size(double.infinity, 55)),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
          foregroundColor: MaterialStateProperty.all(Colors.indigo), // Text color
          alignment: Alignment.center, // Center the button content
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)
          ),
          side: MaterialStateProperty.all(
            const BorderSide(color: Colors.indigo, width: 1.5)
          ),
        ),
      ),
      
      // Card theme for consistency
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      
      // App bar theme - ensuring text is visible
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white, // Text color
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.indigo),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo, width: 2.0),
        ),
      ),
      
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 32, 
          fontWeight: FontWeight.bold, 
          color: Colors.indigo, // Explicitly set for the app title
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black, // Default text color
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black, // Default text color
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import local files
import 'firebase_options.dart';
import 'auth_service.dart';
import 'widgets/asset_flow_loader.dart';
import 'investments_list_screen.dart';
import 'add_investment_screen.dart';


// Main application entry point
void main() async {
  // Ensure Flutter binding is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging with a comprehensive and informative setup
  _configureLogging();

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
    runApp(const MyApp());
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

// Comprehensive logging configuration function
void _configureLogging() {
  // Set the root logging level to capture all log events
  Logger.root.level = Level.ALL;
  
  // Create a sophisticated log handler with rich formatting
  Logger.root.onRecord.listen((record) {
    String emoji = _getLogLevelEmoji(record.level);
    String logMessage = '$emoji ${record.time} | '
                        '${record.loggerName} | '
                        '${record.level.name}: '
                        '${record.message}';
    
    // Color-coded console output based on log severity
    switch (record.level) {
      case Level.SEVERE:
        debugPrint('\x1B[31m$logMessage\x1B[0m'); // Red for severe errors
        break;
      case Level.WARNING:
        debugPrint('\x1B[33m$logMessage\x1B[0m'); // Yellow for warnings
        break;
      case Level.INFO:
        debugPrint('\x1B[32m$logMessage\x1B[0m'); // Green for info
        break;
      default:
        debugPrint(logMessage);
    }
  });
}

// Helper function to get emojis for log levels
String _getLogLevelEmoji(Level level) {
  if (level == Level.SEVERE) return '🔴';
  if (level == Level.WARNING) return '🟡';
  if (level == Level.INFO) return '🟢';
  if (level == Level.CONFIG) return '🔵';
  return '⚪';
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
class MyApp extends StatelessWidget {
  static final Logger _logger = Logger('MyApp');

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.info('MyApp built.');
    return MaterialApp(
      title: 'AssetFlow',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
        
        // Button themes - using MaterialStateProperty for proper styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(const Size(double.infinity, 55)),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
            foregroundColor: WidgetStateProperty.all(Colors.white), // Text color
            backgroundColor: WidgetStateProperty.all(Colors.indigo), // Button background
            elevation: WidgetStateProperty.all(4.0),
            alignment: Alignment.center, // Center the button content
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(const Size(double.infinity, 55)),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
            foregroundColor: WidgetStateProperty.all(Colors.indigo), // Text color
            alignment: Alignment.center, // Center the button content
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)
            ),
            side: WidgetStateProperty.all(
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
      ),
      home: AuthWrapper(),
    );
  }
}

// Loading widget to standardize loading state across the app
class AssetFlowLoadingWidget extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingText;
  
  const AssetFlowLoadingWidget({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingText,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,
        
        // Show loader overlay when loading
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AssetFlowLoader(
                    size: 80,
                    primaryColor: Colors.blue,
                    duration: const Duration(seconds: 3),
                  ),
                  if (loadingText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        loadingText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Auth wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  static final Logger _logger = Logger('AuthWrapper');
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.info('AuthWrapper built.');
    
    // Use StreamBuilder to listen for auth state changes
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while determining auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: AssetFlowLoader(
                size: 60,
                primaryColor: Theme.of(context).primaryColor,
              ),
            ),
          );
        }
        
        // Check if the user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          _logger.info('User is logged in. Navigating to HomeScreen.');
          return HomeScreen();
        } else {
          _logger.info('User is not logged in. Navigating to AuthScreen.');
          return const AuthScreen();
        }
      },
    );
  }
}

// HomeScreen class that serves as a central dashboard
class HomeScreen extends StatelessWidget {
  static final Logger _logger = Logger('HomeScreen');
  final AuthService _authService = AuthService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    _logger.info('HomeScreen built.');
    return Scaffold(
      appBar: AppBar(
        title: const Text('AssetFlow Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _logger.info('Logout button pressed.');
              try {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                }
              } catch (e) {
                _logger.severe('Error logging out: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: ${e.toString()}')),
                  );
                }
              }
            },
          ),
        ],
      ),
      // Use SafeArea to avoid overflow issues with system UI
      body: SafeArea(
        // Use SingleChildScrollView to handle potential overflow
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Text(
                  'Welcome to AssetFlow',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Text(
                  'Manage your investments efficiently',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                // Main menu - Investments button with proper styling
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: _buildMenuButton(
                    context,
                    'Investments',
                    Icons.account_balance,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InvestmentsListScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Improved menu button widget with proper sizing and alignment
  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 60,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  static final Logger _logger = Logger('AuthScreen');
  bool _isLoading = false;

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('AuthScreen built.');
    return AssetFlowLoadingWidget(
      isLoading: _isLoading,
      loadingText: 'Authenticating...',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('AssetFlow Login'),
        ),
        // Use a ScrollView to prevent overflow when keyboard appears
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  // App Title - Explicitly setting color
                  const Text(
                    'AssetFlow',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle with explicit color
                  const Text(
                    'Manage your investments with ease',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Email Input
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                      // Explicit label styling
                      labelStyle: TextStyle(color: Colors.indigo),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  // Password Input
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      // Explicit label styling
                      labelStyle: TextStyle(color: Colors.indigo),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 32),
                  // Sign In button with explicit styling
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sign Up button with explicit styling
                  OutlinedButton(
                    onPressed: _signUp,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: const BorderSide(color: Colors.indigo, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Sign in method with proper error handling
  Future<void> _signIn() async {
    _logger.info('Sign In button pressed.');
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Validate inputs first
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw Exception('Email and password are required');
      }
      
      await _authService.signIn(_emailController.text, _passwordController.text);
      
      if (mounted) {
        // Navigate to HomeScreen on success
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } else {
        _logger.warning('AuthScreen was unmounted before navigation.');
      }
    } catch (e) {
      _logger.severe('Error signing in: $e');
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Sign up method with proper error handling
  Future<void> _signUp() async {
    _logger.info('Sign Up button pressed.');
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Validate inputs first
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw Exception('Email and password are required');
      }
      
      if (_passwordController.text.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }
      
      await _authService.signUp(_emailController.text, _passwordController.text);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully. Please sign in.')),
        );
        
        // Clear the password field after signup
        _passwordController.clear();
      } else {
        _logger.warning('AuthScreen was unmounted before showing success message.');
      }
    } catch (e) {
      _logger.severe('Error signing up: $e');
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
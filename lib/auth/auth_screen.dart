import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../widgets/asset_flow_loading_widget.dart';
import '../auth/auth_service.dart';
import '../utils/theme_colors.dart';
import '../list/assets_list_screen.dart';
import 'forgot_password_screen.dart';

/// Authentication screen for user sign in
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
  bool _obscurePassword = true;

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
          title: const Text('Sign In'),
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
                  // App Title
                  Text(
                    'AssetFlow',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Sign in to manage your investments',
                    style: TextStyle(
                      fontSize: 16,
                      color: AssetFlowColors.textSecondary,
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
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: AssetFlowColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  // Password Input with visibility toggle
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                    style: TextStyle(color: AssetFlowColors.textPrimary),
                  ),
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _logger.info('Forgot password button pressed');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AssetFlowColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sign In button
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AssetFlowColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign In'),
                  ),
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
    
    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signIn(_emailController.text, _passwordController.text);
      
      if (mounted) {
        // Navigate to AssetsListScreen on success
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AssetsListScreen()),
          (route) => false, // Remove all previous routes
        );
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
}
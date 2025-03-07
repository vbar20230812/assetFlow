import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../widgets/asset_flow_loading_widget.dart';
import '../auth/auth_service.dart';
import '../utils/theme_colors.dart';
import '../list/assets_list_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Authentication screen for user sign in with email and password
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  static final Logger _logger = Logger('AuthScreen');
  bool _isLoading = false;
  
  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Password visibility toggle
  bool _passwordVisible = false;
  
  @override
  void dispose() {
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
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
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
                    const Text(
                      'Sign in to manage your investments',
                      style: TextStyle(
                        fontSize: 16,
                        color: AssetFlowColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // Basic email validation
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _logger.info('Forgot password link pressed.');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign In button
                    ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AssetFlowColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Don't have an account section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account?',
                          style: TextStyle(color: AssetFlowColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            _logger.info('Sign Up link pressed.');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AssetFlowColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Private & Secure message
                    const Center(
                      child: Text(
                        'Your login is private and secure',
                        style: TextStyle(
                          fontSize: 14,
                          color: AssetFlowColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Email/password sign in method
  Future<void> _signIn() async {
    _logger.info('Sign In button pressed.');
    
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      _logger.warning('Form validation failed');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
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
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../widgets/asset_flow_loading_widget.dart';
import '../auth/auth_service.dart';
import '../utils/theme_colors.dart';
import 'auth_screen.dart';

/// Signup screen for user registration
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  static final Logger _logger = Logger('SignupScreen');
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('SignupScreen built.');
    return AssetFlowLoadingWidget(
      isLoading: _isLoading,
      loadingText: 'Creating account...',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Sign Up'),
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
                  const SizedBox(height: 24),
                  // App Title
                  Text(
                    'AssetFlow',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  Text(
                    'Create an account to manage your investments',
                    style: TextStyle(
                      fontSize: 16,
                      color: AssetFlowColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
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
                      helperText: 'Password must be at least 6 characters long',
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: AssetFlowColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  // Confirm Password Input with visibility toggle
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signUp(),
                    style: TextStyle(color: AssetFlowColors.textPrimary),
                  ),
                  const SizedBox(height: 32),
                  // Sign Up button
                  ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AssetFlowColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(height: 16),
                  // Already have an account link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: AssetFlowColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          _logger.info('Sign In link pressed');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AssetFlowColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Sign up method with proper error handling and validation
  Future<void> _signUp() async {
    _logger.info('Sign Up button pressed.');
    
    // Validate inputs
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }
    
    // Validate password length
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long')),
      );
      return;
    }
    
    // Validate password match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signUp(_emailController.text, _passwordController.text);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully. Please sign in.')),
        );
        
        // Navigate to sign in screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      } else {
        _logger.warning('SignupScreen was unmounted before navigation.');
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
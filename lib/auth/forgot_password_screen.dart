import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../widgets/asset_flow_loading_widget.dart';
import '../utils/theme_colors.dart';
import '../auth/auth_service.dart';

/// Screen for password reset functionality
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static final Logger _logger = Logger('ForgotPasswordScreen');
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('ForgotPasswordScreen built.');
    return AssetFlowLoadingWidget(
      isLoading: _isLoading,
      loadingText: 'Sending reset link...',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Reset Password'),
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
                    
                    // Icon
                    const Icon(
                      Icons.lock_reset,
                      size: 72,
                      color: AssetFlowColors.primary,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Reset Your Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AssetFlowColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (!_resetEmailSent)
                      Column(
                        children: [
                          // Description
                          const Text(
                            'Enter your email address below, and we\'ll send you a link to reset your password.',
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
                          
                          const SizedBox(height: 32),
                          
                          // Reset Password button
                          ElevatedButton(
                            onPressed: _sendPasswordResetEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AssetFlowColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Send Reset Link'),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          // Success message
                          const Text(
                            'Password reset email sent!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          const Text(
                            'Check your email for instructions on how to reset your password. If you don\'t see it, check your spam folder.',
                            style: TextStyle(
                              fontSize: 16,
                              color: AssetFlowColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Resend email button
                          OutlinedButton(
                            onPressed: _sendPasswordResetEmail,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AssetFlowColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Resend Email'),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Back to Sign In button
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Back to Sign In'),
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

  // Send password reset email
  Future<void> _sendPasswordResetEmail() async {
    _logger.info('Send Reset Link button pressed.');
    
    // Validate email before sending
    if (!_formKey.currentState!.validate()) {
      _logger.warning('Email validation failed');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _resetEmailSent = true;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error sending password reset email: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
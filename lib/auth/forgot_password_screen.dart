import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../widgets/asset_flow_loading_widget.dart';
import '../auth/auth_service.dart';
import '../utils/theme_colors.dart';

/// Screen for password reset functionality
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  static final Logger _logger = Logger('ForgotPasswordScreen');
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
      loadingText: 'Sending reset email...',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Reset Password'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  
                  // Icon
                  Icon(
                    _resetEmailSent ? Icons.mark_email_read : Icons.lock_reset,
                    size: 72,
                    color: AssetFlowColors.primary,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    _resetEmailSent ? 'Email Sent' : 'Forgot Your Password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AssetFlowColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    _resetEmailSent
                        ? 'Please check your email for instructions to reset your password.'
                        : 'Enter your email address and we\'ll send you instructions to reset your password.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AssetFlowColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  if (!_resetEmailSent) ...[
                    // Email Input
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _resetPassword(),
                      style: TextStyle(color: AssetFlowColors.textPrimary),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Reset Password button
                    ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AssetFlowColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reset Password'),
                    ),
                  ] else ...[
                    // Back to Sign In button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AssetFlowColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back to Sign In'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reset password method with proper error handling
  Future<void> _resetPassword() async {
    _logger.info('Reset Password button pressed.');
    
    // Validate email
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.resetPassword(_emailController.text);
      
      if (mounted) {
        setState(() {
          _resetEmailSent = true;
          _isLoading = false;
        });
      } else {
        _logger.warning('ForgotPasswordScreen was unmounted before state update.');
      }
    } catch (e) {
      _logger.severe('Error resetting password: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../auth/auth_screen.dart';
import '../auth/signup_screen.dart';
import '../utils/theme_colors.dart';
import '../widgets/asset_flow_loader.dart';

/// Splash screen with AssetFlow logo and authentication buttons
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static final Logger _logger = Logger('SplashScreen');
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _logger.info('SplashScreen initialized');
    
    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and app name with fade-in animation
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Column(
                      children: [
                        // App Logo
                        _buildLogo(),
                        
                        const SizedBox(height: 24),
                        
                        // App Name
                        Text(
                          'AssetFlow',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // App Tagline
                        const Text(
                          'Managing your investments with ease',
                          style: TextStyle(
                            fontSize: 16,
                            color: AssetFlowColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // Sign In button
                  ElevatedButton(
                    onPressed: () {
                      _logger.info('Sign In button pressed');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AssetFlowColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign In'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sign Up button
                  OutlinedButton(
                    onPressed: () {
                      _logger.info('Sign Up button pressed');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AssetFlowColors.primary,
                      side: const BorderSide(color: AssetFlowColors.primary, width: 1.5),
                    ),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build the AssetFlow logo
  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AssetFlowColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AssetFlowColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.account_balance,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }
}
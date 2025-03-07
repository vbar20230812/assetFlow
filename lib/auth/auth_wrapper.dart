import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import 'auth_screen.dart';
import '../auth/auth_service.dart';
import '../widgets/asset_flow_loader.dart';
import '../list/assets_list_screen.dart';

/// Auth wrapper to handle authentication state
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
          _logger.info('User is logged in. Navigating to AssetsListScreen.');
          return const AssetsListScreen();
        } else {
          _logger.info('User is not logged in. Navigating to AuthScreen.');
          return const AuthScreen();
        }
      },
    );
  }
}
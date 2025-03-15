import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/dashboard_screen.dart';
import '../list/empty_assets_screen.dart';
import '../services/database_service.dart';
import '../auth/auth_screen.dart';
import '../start/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has user data but is in a loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // If the snapshot has user data, the user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const UserRouter();
        }
        
        // Otherwise, the user is not logged in
        return const AuthScreen();
      },
    );
  }
}

/// Router that checks if the user has any assets and routes accordingly
class UserRouter extends StatelessWidget {
  const UserRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DatabaseService databaseService = DatabaseService();

    return StreamBuilder<List<dynamic>>(
      stream: databaseService.getUserProjects(),
      builder: (context, snapshot) {
        // Show splash screen while loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // If there's an error, show the auth screen
        if (snapshot.hasError) {
          return const AuthScreen();
        }
        
        // Check if the user has any projects
        final hasProjects = snapshot.hasData && snapshot.data!.isNotEmpty;
        
        // Route to dashboard if they have projects, otherwise to empty state
        if (hasProjects) {
          return const DashboardScreen();
        } else {
          return const EmptyAssetsScreen();
        }
      },
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('AuthService');

  // Sign up with email and password
  Future<void> signUp(String email, String password) async {
    try {
      _logger.info('Attempting to sign up user: $email');
      
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _logger.info('User signed up successfully');
    } on FirebaseAuthException catch (e) {
      _logger.severe('Firebase Auth Exception during sign up: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      _logger.severe('Unexpected error during sign up: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      _logger.info('Attempting to sign in user: $email');
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // We don't need to access the UserCredential result
      // Just check if the current user is non-null
      if (_auth.currentUser != null) {
        _logger.info('User signed in successfully: ${_auth.currentUser?.uid}');
      } else {
        throw Exception('Failed to authenticate user');
      }
    } on FirebaseAuthException catch (e) {
      _logger.severe('Firebase Auth Exception during sign in: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = 'Authentication failed: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      _logger.severe('Unexpected error during sign in: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logger.info('User signed out successfully');
    } catch (e) {
      _logger.severe('Error signing out: $e');
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
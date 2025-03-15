import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle app preferences including payment celebration controls
class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  
  // Singleton constructor
  factory PreferencesService() => _instance;
  
  PreferencesService._internal();
  
  // Keys for preferences
  static const String _keyPaymentCelebration = 'payment_celebration_shown_';
  
  /// Check if payment celebration has been shown for a specific date and project
  Future<bool> hasPaymentCelebrationBeenShown(
    String projectId, 
    DateTime date
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildPaymentCelebrationKey(projectId, date);
    return prefs.getBool(key) ?? false;
  }
  
  /// Mark payment celebration as shown for a specific date and project
  Future<void> markPaymentCelebrationAsShown(
    String projectId, 
    DateTime date
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _buildPaymentCelebrationKey(projectId, date);
    await prefs.setBool(key, true);
  }
  
  /// Reset all payment celebration markers (useful for testing)
  Future<void> resetAllPaymentCelebrations() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyPaymentCelebration)) {
        await prefs.remove(key);
      }
    }
  }
  
  /// Build a unique key for a payment celebration based on project and date
  String _buildPaymentCelebrationKey(String projectId, DateTime date) {
    // Format: payment_celebration_shown_PROJECT-ID_YYYY-MM-DD
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${_keyPaymentCelebration}${projectId}_$formattedDate';
  }
}
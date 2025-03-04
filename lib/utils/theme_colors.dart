import 'package:flutter/material.dart';

/// A utility class for consistent color theming throughout the app
class AssetFlowColors {
  // Primary colors
  static const Color primary = Color(0xFF3F51B5); // Indigo
  static const Color primaryLight = Color(0xFF7986CB);
  static const Color primaryDark = Color(0xFF303F9F);

  // Accent colors
  static const Color accent = Color(0xFF4CAF50); // Green
  static const Color accentLight = Color(0xFF81C784);
  static const Color accentDark = Color(0xFF388E3C);

  // Status colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Neutral colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnAccent = Colors.white;

  // Investment specific colors
  static const Color invested = Color(0xFF4CAF50); // Green
  static const Color returns = Color(0xFF3F51B5); // Indigo
  static const Color fees = Color(0xFFF44336); // Red
  static const Color pending = Color(0xFFFFA726); // Orange
  
  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF3F51B5), // Indigo
    Color(0xFF4CAF50), // Green
    Color(0xFFFFC107), // Amber
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF2196F3), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFF795548), // Brown
  ];

  // Plan type colors
  static const Color limitedPartner = Color(0xFF3F51B5); // Indigo
  static const Color lender = Color(0xFF4CAF50); // Green
  static const Color development = Color(0xFFF44336); // Red
  static const Color other = Color(0xFF757575); // Grey

  /// Get a color based on participation type
  static Color getParticipationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'limited partner':
        return limitedPartner;
      case 'lender':
        return lender;
      case 'development':
        return development;
      default:
        return other;
    }
  }

  /// Get a gradient based on a base color
  static LinearGradient getGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor,
      ],
    );
  }

  /// Get a color shade based on a value (for heatmaps)
  static Color getShade(Color baseColor, double value, {double min = 0, double max = 100}) {
    // Normalize the value between 0 and 1
    final normalizedValue = (value - min) / (max - min);
    
    // Clamp the value between 0 and 1
    final clampedValue = normalizedValue.clamp(0.0, 1.0);
    
    // Return a color shade based on the value
    return Color.lerp(Colors.white, baseColor, clampedValue) ?? baseColor;
  }

  /// Get a status color based on a status string
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'success':
        return success;
      case 'pending':
      case 'in progress':
      case 'waiting':
        return warning;
      case 'failed':
      case 'error':
      case 'cancelled':
        return error;
      default:
        return info;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Utility class to configure and manage application logging
class LoggerUtil {
  /// Configure logging for the entire application
  static void configureLogging() {
    // Set the root logging level to capture all log events
    Logger.root.level = Level.ALL;
    
    // Create a sophisticated log handler with rich formatting
    Logger.root.onRecord.listen((record) {
      String emoji = _getLogLevelEmoji(record.level);
      String logMessage = '$emoji ${record.time} | '
                        '${record.loggerName} | '
                        '${record.level.name}: '
                        '${record.message}';
      
      // Color-coded console output based on log severity
      switch (record.level) {
        case Level.SEVERE:
          debugPrint('\x1B[31m$logMessage\x1B[0m'); // Red for severe errors
          break;
        case Level.WARNING:
          debugPrint('\x1B[33m$logMessage\x1B[0m'); // Yellow for warnings
          break;
        case Level.INFO:
          debugPrint('\x1B[32m$logMessage\x1B[0m'); // Green for info
          break;
        default:
          debugPrint(logMessage);
      }
    });
  }

  // Helper function to get emojis for log levels
  static String _getLogLevelEmoji(Level level) {
    if (level == Level.SEVERE) return '🔴';
    if (level == Level.WARNING) return '🟡';
    if (level == Level.INFO) return '🟢';
    if (level == Level.CONFIG) return '🔵';
    return '⚪';
  }
}
import 'package:intl/intl.dart';

/// Utility class for date-related operations
class DateUtil {
  /// Format a DateTime to a string with the format "MMM d, yyyy" (e.g., "Jan 1, 2023")
  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  /// Format a DateTime to a string with the format "MMM yyyy" (e.g., "Jan 2023")
  static String formatMonthYear(DateTime date) {
    return DateFormat.yMMM().format(date);
  }

  /// Format a DateTime to a string with the format "MMMM d, yyyy" (e.g., "January 1, 2023")
  static String formatLongDate(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }

  /// Format a DateTime to a string with the format "yyyy-MM-dd" (e.g., "2023-01-01")
  static String formatIsoDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Add months to a DateTime
  static DateTime addMonths(DateTime date, int months) {
    var result = DateTime(
      date.year,
      date.month + months,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
    
    // Handle month overflow (e.g., adding 1 month to January 31 should give February 28/29)
    if (date.day != result.day) {
      result = DateTime(
        result.year,
        result.month,
        0,
        result.hour,
        result.minute,
        result.second,
        result.millisecond,
        result.microsecond,
      );
    }
    
    return result;
  }

  /// Calculate the first payment date based on the start date and payment distribution type
  static DateTime calculateFirstPaymentDate(DateTime startDate, String distributionType) {
    switch (distributionType.toLowerCase()) {
      case 'quarterly':
        return addMonths(startDate, 3);
      case 'half yearly':
        return addMonths(startDate, 6);
      case 'annual':
        return addMonths(startDate, 12);
      case 'exit':
        // For exit distribution, we don't have a specific payment date
        return startDate;
      default:
        return startDate;
    }
  }

  /// Check if a date is in the past
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }

  /// Check if a date is in the future
  static bool isFuture(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(now);
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Get the remaining months between two dates
  static int remainingMonths(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
  }
}
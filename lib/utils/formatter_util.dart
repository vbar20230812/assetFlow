import 'package:intl/intl.dart';

/// Utility class for formatting values like currency and percentages
class FormatterUtil {
  /// Format a number as currency with the given currency symbol (default: $)
  static String formatCurrency(double value, {String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(value);
  }

  /// Format a number as a percentage with the given decimal places (default: 2)
  static String formatPercentage(double value, {int decimalPlaces = 2}) {
    return NumberFormat.percentPattern().format(value / 100);
  }

  /// Format a large number with commas as thousands separators
  static String formatNumber(num value) {
    return NumberFormat.decimalPattern().format(value);
  }

  /// Format a number as a compact representation (e.g., 1.2K, 4.5M)
  static String formatCompactNumber(num value) {
    return NumberFormat.compact().format(value);
  }

  /// Convert a percentage to a decimal value (e.g., 5% to 0.05)
  static double percentageToDecimal(double percentage) {
    return percentage / 100;
  }

  /// Convert a decimal to a percentage value (e.g., 0.05 to 5%)
  static double decimalToPercentage(double decimal) {
    return decimal * 100;
  }

  /// Format a monthly payment amount
  static String formatMonthlyPayment(double amount) {
    return '${formatCurrency(amount)}/month';
  }

  /// Format an annual payment amount
  static String formatAnnualPayment(double amount) {
    return '${formatCurrency(amount)}/year';
  }

  /// Format a date range as a string (e.g., "Jan 2023 - Dec 2024")
  static String formatDateRange(DateTime start, DateTime end) {
    final startFormat = DateFormat.yMMM();
    final endFormat = DateFormat.yMMM();
    return '${startFormat.format(start)} - ${endFormat.format(end)}';
  }
}
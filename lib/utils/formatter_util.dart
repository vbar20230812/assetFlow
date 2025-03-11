import 'package:intl/intl.dart';

/// Utility class for formatting different types of data
class FormatterUtil {
  // Map of currency codes to symbols
  static final Map<String, String> _currencySymbols = {
    'GBP': '£',
    'USD': '\$',
    'EUR': '€',
    // Add more currencies as needed
  };

  // Cache for currency formatters to avoid recreating them
  static final Map<String, NumberFormat> _currencyFormatters = {};
  
  // Percentage formatter
  static final NumberFormat _percentFormatter = NumberFormat.percentPattern();
  
  // Date formatter
  static final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');
  
  // Short date formatter
  static final DateFormat _shortDateFormatter = DateFormat('MM/dd/yyyy');
  
  // Month year formatter
  static final DateFormat _monthYearFormatter = DateFormat('MMM yyyy');

  /// Get currency formatter for a specific currency
  static NumberFormat getCurrencyFormatter(String currencyCode) {
    // Return cached formatter if exists
    if (_currencyFormatters.containsKey(currencyCode)) {
      return _currencyFormatters[currencyCode]!;
    }
    
    // Create a new formatter
    final formatter = NumberFormat.currency(
      symbol: _currencySymbols[currencyCode] ?? currencyCode,
      decimalDigits: 0,  // No decimals
    );
    
    // Cache it for future use
    _currencyFormatters[currencyCode] = formatter;
    
    return formatter;
  }

  /// Format a number as currency with the specified currency code
  static String formatCurrency(double value, {String currencyCode = 'GBP'}) {
    return getCurrencyFormatter(currencyCode).format(value);
  }

  /// Get the currency symbol for a currency code
  static String getCurrencySymbol(String currencyCode) {
    return _currencySymbols[currencyCode] ?? currencyCode;
  }

  /// Format a number as percentage
  static String formatPercentage(double value) {
    // Convert decimal to percentage (0.05 -> 5%)
    return _percentFormatter.format(value);
  }

  /// Format a date
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format a date in short format
  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  /// Format a date as month and year
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  /// Format a double with specific precision
  static String formatDouble(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  /// Format a duration in months
  static String formatDuration(int months) {
    if (months < 12) {
      return '$months month${months == 1 ? '' : 's'}';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      
      if (remainingMonths == 0) {
        return '$years year${years == 1 ? '' : 's'}';
      } else {
        return '$years year${years == 1 ? '' : 's'} $remainingMonths month${remainingMonths == 1 ? '' : 's'}';
      }
    }
  }

  /// Format a large number with K, M, B suffixes
  static String formatCompactNumber(double value) {
    if (value < 1000) {
      return value.toStringAsFixed(0);
    } else if (value < 1000000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value < 1000000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
  }
}
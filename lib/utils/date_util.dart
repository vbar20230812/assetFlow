import 'package:intl/intl.dart';

/// Utility class for date operations
class DateUtil {
  // Date formatters
  static final DateFormat _shortDateFormatter = DateFormat('MM/dd/yyyy');
  static final DateFormat _longDateFormatter = DateFormat('MMMM d, yyyy');
  static final DateFormat _standardDateFormatter = DateFormat('MMM dd, yyyy'); // Added for formatDate
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthFormatter = DateFormat('d MMM');
  static final DateFormat _timeFormatter = DateFormat('h:mm a');
  static final DateFormat _dateTimeFormatter = DateFormat('MMM d, yyyy h:mm a');
  
  /// Format a date in short format (MM/DD/YYYY)
  static String formatShortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }
  
  /// Format a date in standard format (MMM DD, YYYY)
  static String formatDate(DateTime date) {
    return _standardDateFormatter.format(date);
  }
  
  /// Format a date in long format (Month Day, Year)
  static String formatLongDate(DateTime date) {
    return _longDateFormatter.format(date);
  }
  
  /// Format a date as month and year only
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }
  
  /// Format a date as day and month only
  static String formatDayMonth(DateTime date) {
    return _dayMonthFormatter.format(date);
  }
  
  /// Format a time
  static String formatTime(DateTime date) {
    return _timeFormatter.format(date);
  }
  
  /// Format a full date and time
  static String formatDateTime(DateTime date) {
    return _dateTimeFormatter.format(date);
  }
  
  /// Add specified months to a date
  static DateTime addMonths(DateTime date, int months) {
    var newYear = date.year + (date.month + months - 1) ~/ 12;
    var newMonth = (date.month + months - 1) % 12 + 1;
    
    // If the day is greater than the number of days in the new month, use the last day of the month
    var lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
    var newDay = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
    
    return DateTime(newYear, newMonth, newDay, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
  }
  
  /// Add specified years to a date
  static DateTime addYears(DateTime date, int years) {
    return DateTime(
      date.year + years,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
  
  /// Get the difference in months between two dates
  static int monthDifference(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + to.month - from.month;
  }
  
  /// Get the difference in years between two dates
  static int yearDifference(DateTime from, DateTime to) {
    var years = to.year - from.year;
    if (to.month < from.month || (to.month == from.month && to.day < from.day)) {
      years--;
    }
    return years;
  }
  
  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
  
  /// Get the first day of the month for a given date
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Get the last day of the month for a given date
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  /// Get the start of the day (midnight) for a given date
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Get the end of the day (23:59:59.999) for a given date
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// Format a relative date (today, yesterday, etc.) or fall back to a regular date format
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    
    if (isSameDay(date, now)) {
      return 'Today';
    } else if (isSameDay(date, DateTime(now.year, now.month, now.day - 1))) {
      return 'Yesterday';
    } else if (isSameDay(date, DateTime(now.year, now.month, now.day + 1))) {
      return 'Tomorrow';
    } else if (date.difference(now).inDays.abs() < 7) {
      return DateFormat('EEEE').format(date); // Day of week
    } else {
      return formatShortDate(date);
    }
  }
  
  /// Get a list of dates for a date range
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    return List.generate(days, (i) => DateTime(start.year, start.month, start.day + i));
  }
}
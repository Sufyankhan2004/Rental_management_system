// ============================================
// FILE 28: utils/date_formatter.dart
// ============================================
// Create new file: lib/utils/date_formatter.dart

import 'package:intl/intl.dart';

class DateFormatter {
  // Format: Jan 15, 2024
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format: January 15, 2024
  static String formatLongDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  // Format: 15/01/2024
  static String formatNumericDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format: 15 Jan
  static String formatDayMonth(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  // Format: 3:45 PM
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  // Format: Jan 15, 2024 at 3:45 PM
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(date);
  }

  // Format: Monday
  static String formatDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Relative Time (e.g., "2 hours ago", "Yesterday")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      }
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Calculate duration between two dates
  static String formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
    } else {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'}';
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }
}

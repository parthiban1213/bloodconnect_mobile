import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';

extension StringExtensions on String {
  String get initials {
    final parts = trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

extension DateExtensions on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(this);
  }

  String get formatted => DateFormat('d MMM yyyy').format(this);
  String get formattedWithTime => DateFormat('d MMM, h:mm a').format(this);
}

class UrgencyHelper {
  static Color bgColor(String urgency) {
    switch (urgency) {
      case 'Critical': return AppColors.urgentBg;
      case 'High': return AppColors.moderateBg;
      case 'Medium': return AppColors.plannedBg;
      default: return AppColors.closedBg;
    }
  }

  static Color textColor(String urgency) {
    switch (urgency) {
      case 'Critical': return AppColors.urgentText;
      case 'High': return AppColors.moderateText;
      case 'Medium': return AppColors.plannedText;
      default: return AppColors.closedText;
    }
  }

  static Color barColor(String urgency) {
    switch (urgency) {
      case 'Critical': return AppColors.primary;
      case 'High': return const Color(0xFFBA7517);
      case 'Medium': return const Color(0xFF185FA5);
      default: return AppColors.closedAccent;
    }
  }

  static double urgencyProgress(String urgency, DateTime? requiredBy) {
    if (requiredBy == null) {
      switch (urgency) {
        case 'Critical': return 0.85;
        case 'High': return 0.55;
        case 'Medium': return 0.25;
        default: return 0.0;
      }
    }
    final now = DateTime.now();
    final total = requiredBy.difference(now.subtract(const Duration(hours: 2)));
    final remaining = requiredBy.difference(now);
    if (total.inSeconds <= 0) return 1.0;
    return 1.0 - (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);
  }

  static String timeRemaining(DateTime? requiredBy) {
    if (requiredBy == null) return 'No deadline';
    final now = DateTime.now();
    final diff = requiredBy.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inHours < 1) return '${diff.inMinutes}m remaining';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}m remaining';
    return '${diff.inDays}d remaining';
  }

  static String urgencyLabel(String urgency) {
    switch (urgency) {
      case 'Critical': return 'Urgent';
      case 'High': return 'Moderate';
      case 'Medium': return 'Planned';
      default: return 'Closed';
    }
  }
}

class StatusHelper {
  static Color bgColor(String status) {
    switch (status) {
      case 'Open': return AppColors.urgentBg;
      case 'Fulfilled': return AppColors.secondaryLight;
      default: return AppColors.closedBg;
    }
  }

  static Color textColor(String status) {
    switch (status) {
      case 'Open': return AppColors.urgentText;
      case 'Fulfilled': return AppColors.secondary;
      default: return AppColors.closedText;
    }
  }
}

extension BuildContextExtensions on BuildContext {
  /// Dismisses the soft keyboard if it is currently open.
  /// Call this at the start of every user-initiated button action
  /// (form submit, login, OTP send, save, etc.) so the keyboard
  /// is gone before any loading state or navigation occurs.
  void dismissKeyboard() {
    final focus = FocusScope.of(this);
    if (!focus.hasPrimaryFocus) focus.unfocus();
  }
}

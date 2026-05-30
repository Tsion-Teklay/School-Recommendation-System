import 'package:flutter/material.dart';

/// Centralized message helper for showing user-friendly success and info messages
class MessageHelper {
  /// Show a success message using a SnackBar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  /// Show an error message using a SnackBar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  /// Show an info message using a SnackBar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  /// Show a warning message using a SnackBar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  /// Show a dialog with a success message
  static Future<void> showSuccessDialog(
    BuildContext context,
    String title,
    String message, {
    String buttonText = 'OK',
    VoidCallback? onButtonPressed,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onButtonPressed?.call();
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Show a dialog with an error message
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String buttonText = 'OK',
    VoidCallback? onButtonPressed,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onButtonPressed?.call();
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool?> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Pre-defined success messages for common actions
class SuccessMessages {
  static const String login = 'Welcome back! You\'re now signed in.';
  static const String logout = 'You\'ve been signed out successfully.';
  static const String register = 'Account created successfully!';
  static const String profileUpdated = 'Your profile has been updated.';
  static const String passwordChanged = 'Password changed successfully.';
  static const String passwordReset = 'Password reset link sent to your email.';
  static const String emailVerified = 'Email verified successfully!';
  static const String phoneVerified = 'Phone verified successfully!';
  static const String schoolCreated = 'School created successfully!';
  static const String schoolUpdated = 'School information updated.';
  static const String schoolDeleted = 'School deleted successfully.';
  static const String announcementCreated = 'Announcement posted successfully!';
  static const String announcementUpdated = 'Announcement updated.';
  static const String announcementDeleted = 'Announcement deleted.';
  static const String reviewPosted = 'Your review has been posted.';
  static const String reviewDeleted = 'Review deleted.';
  static const String reportSubmitted = 'Report submitted. Thank you for helping keep our community safe.';
  static const String accountReactivated = 'Your account has been reactivated successfully!';
  static const String accountDeactivated = 'Your account has been deactivated.';
  static const String commentPosted = 'Comment posted successfully!';
  static const String commentDeleted = 'Comment deleted.';
  static const String likeAdded = 'Added to your favorites!';
  static const String likeRemoved = 'Removed from favorites.';
  static const String verificationResent = 'Verification code sent again!';
}
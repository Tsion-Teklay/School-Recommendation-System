import '../../features/auth/data/auth_repository.dart' show ApiException;

/// Centralized error handler that converts technical errors into user-friendly messages
class ErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is ApiException) {
      return _getApiErrorMessage(error);
    }
    
    // Handle common error types
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Please sign in to continue.';
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'You don\'t have permission to perform this action.';
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    }
    
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Something went wrong on our end. Please try again later.';
    }
    
    // Default fallback
    return 'An unexpected error occurred. Please try again.';
  }
  
  static String _getApiErrorMessage(ApiException error) {
    // Handle specific error codes with user-friendly messages
    switch (error.code) {
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password. Please try again.';
      case 'USER_NOT_FOUND':
        return 'Account not found. Please check your credentials or sign up.';
      case 'EMAIL_ALREADY_EXISTS':
        return 'An account with this email already exists. Please sign in instead.';
      case 'PHONE_ALREADY_EXISTS':
        return 'An account with this phone number already exists. Please sign in instead.';
      case 'WEAK_PASSWORD':
        return 'Password is too weak. Please use a stronger password.';
      case 'INVALID_EMAIL':
        return 'Please enter a valid email address.';
      case 'INVALID_PHONE':
        return 'Please enter a valid phone number.';
      case 'PHONE_NOT_VERIFIED':
        return 'Please verify your phone number to continue.';
      case 'EMAIL_NOT_VERIFIED':
        return 'Please verify your email address to continue.';
      case 'ACCOUNT_SELF_DEACTIVATED':
        return 'Your account has been deactivated. You can reactivate it anytime.';
      case 'ACCOUNT_SUSPENDED':
        return 'Your account has been suspended. Please contact support for assistance.';
      case 'INVALID_TOKEN':
        return 'Your session has expired. Please sign in again.';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'SCHOOL_NOT_FOUND':
        return 'School not found. It may have been removed or is no longer available.';
      case 'ALREADY_ENROLLED':
        return 'You are already enrolled in this school.';
      case 'INVALID_CURRICULUM':
        return 'Invalid curriculum selected. Please choose a valid option.';
      case 'MISSING_REQUIRED_FIELDS':
        return 'Please fill in all required fields.';
      case 'INVALID_FILE_TYPE':
        return 'Invalid file type. Please upload a valid file.';
      case 'FILE_TOO_LARGE':
        return 'File is too large. Please upload a smaller file.';
      default:
        // If the error message from API is already user-friendly, use it
        if (error.message.isNotEmpty && 
            !error.message.contains('Exception') &&
            !error.message.contains('Error') &&
            error.message.length < 100) {
          return error.message;
        }
        // Otherwise, provide a generic message
        return 'Something went wrong. Please try again.';
    }
  }
  
  /// Get a more detailed error message with suggestions
  static String getDetailedErrorMessage(dynamic error) {
    final baseMessage = getUserFriendlyMessage(error);
    
    if (error is ApiException) {
      // Add specific suggestions based on error code
      switch (error.code) {
        case 'INVALID_CREDENTIALS':
          return '$baseMessage\n\nTip: Check for typos or reset your password if you\'ve forgotten it.';
        case 'PHONE_NOT_VERIFIED':
        case 'EMAIL_NOT_VERIFIED':
          return '$baseMessage\n\nTip: Check your inbox or SMS for the verification code.';
        case 'ACCOUNT_SELF_DEACTIVATED':
          return '$baseMessage\n\nTip: Use the reactivation option below to restore your account.';
        default:
          return baseMessage;
      }
    }
    
    return baseMessage;
  }
}
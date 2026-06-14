import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Auto-selects URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';       // Chrome / Web
    } else {
      return 'http://10.238.87.188:5000/api';   // Android phone (same WiFi)
    }
  }

  static const String login          = '/auth/login';
  static const String register       = '/auth/register';
  static const String me             = '/auth/me';
  static const String updateProfile  = '/auth/me';
  static const String changePassword = '/auth/change-password';

  static const String patients       = '/patients/';
  static const String predict        = '/predict/';

  static const String predictions    = '/history/predictions';
  static const String reminders      = '/history/reminders';

  static const String dashboard      = '/dashboard/';
  static const String trends         = '/dashboard/trends';

  static const String health         = '/health/';

  // Admin
  static const String adminStats     = '/admin/stats';
  static const String adminUsers     = '/admin/users';

  // Forgot password
  static const String requestOtp    = '/auth/request-otp';
  static const String verifyOtp     = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
}

class StorageKeys {
  static const String accessToken  = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userJson     = 'user_json';
}

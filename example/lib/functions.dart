import 'package:flutter/material.dart';

/// Custom Toast utility class for showing toast messages
class CustomToast {
  static void showToast(String message) {
    // For now, we'll use print. In a real app, you might want to use
    // a proper toast library like fluttertoast
    // ignore: avoid_print
    print('Toast: $message');

    // You can also implement a custom overlay toast here
    // or use any toast package you prefer
  }
  
  /// Show toast with context for SnackBar implementation
  static void showToastWithContext(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Utility functions for the fingerprint application
class FingerprintUtils {
  /// Convert bytes to human readable format
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Validate base64 string
  static bool isValidBase64(String str) {
    try {
      // Basic validation - check if it's a valid base64 string
      if (str.isEmpty) return false;
      
      // Remove data URL prefix if present
      String base64String = str;
      if (str.startsWith('data:')) {
        final commaIndex = str.indexOf(',');
        if (commaIndex != -1) {
          base64String = str.substring(commaIndex + 1);
        }
      }
      
      // Check if it's valid base64
      final RegExp base64RegExp = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      return base64RegExp.hasMatch(base64String) && base64String.length % 4 == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Generate a short ID from UUID
  static String generateShortId(String uuid) {
    return uuid.substring(0, 8).toUpperCase();
  }
  
  /// Format timestamp for display
  static String formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

/// Constants used throughout the application
class AppConstants {
  static const String defaultRegistrationCode = 'MAMASODIKOV';
  static const String defaultBiometricText = 'Here will display base64 finger template';
  static const String defaultVerifyText = 'Copy base64 to verify';
  static const String defaultUrl = 'https://google.com/';
  
  // Colors
  static const Color primaryColor = Colors.indigo;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  
  // Sizes
  static const double buttonPadding = 12.0;
  static const double defaultSpacing = 10.0;
  static const double fingerImageSize = 150.0;
  static const double fingerIconSize = 70.0;
  static const double fingerIconHeight = 120.0;
}

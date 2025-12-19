import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service to handle biometric authentication
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics
  static Future<bool> canAuthenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticate user with biometrics
  static Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        // In local_auth 3.0.0+, parameters are passed directly
        // persistAcrossBackgrounding replaces stickyAuth
        // biometricOnly: false allows fallback to PIN/pattern
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  /// Check if biometrics are enrolled
  static Future<bool> hasBiometricsEnrolled() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }
}

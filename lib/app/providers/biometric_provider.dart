import 'package:flutter_riverpod/legacy.dart';

/// Provider to track if biometric authentication has been completed this session.
/// This is reset to false on logout and must be true to access protected screens.
final biometricSessionProvider = StateProvider<bool>((ref) => false);

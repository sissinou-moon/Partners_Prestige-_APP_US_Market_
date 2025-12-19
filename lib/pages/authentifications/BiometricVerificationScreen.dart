import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/lib/biometric_service.dart';
import 'package:prestige_partners/app/providers/biometric_provider.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import 'package:prestige_partners/pages/tabs/MainTabLayout.dart';

class BiometricVerificationScreen extends ConsumerStatefulWidget {
  const BiometricVerificationScreen({super.key});

  @override
  ConsumerState<BiometricVerificationScreen> createState() =>
      _BiometricVerificationScreenState();
}

class _BiometricVerificationScreenState
    extends ConsumerState<BiometricVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isAuthenticating = false;
  bool _canUseBiometrics = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkBiometricCapability();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricCapability() async {
    final canAuth = await BiometricService.canAuthenticate();
    if (mounted) {
      setState(() {
        _canUseBiometrics = canAuth;
      });

      // Auto-trigger if biometrics are available
      if (canAuth) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _authenticate();
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    HapticFeedback.mediumImpact();

    final success = await BiometricService.authenticate(
      reason: 'Verify your identity to access Prestige Partners',
    );

    if (mounted) {
      if (success) {
        // Set biometric session as verified
        ref.read(biometricSessionProvider.notifier).state = true;

        HapticFeedback.heavyImpact();

        // Navigate to main app
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Maintablayout(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      } else {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Authentication failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userName = user?['full_name'] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo / Branding
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF13B386)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  LineIcons.userShield,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              const SizedBox(height: 32),

              // Welcome Text
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Biometric Icon with Animation
              ScaleTransition(
                scale: _pulseAnimation,
                child: GestureDetector(
                  onTap: _canUseBiometrics ? _authenticate : null,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: _isAuthenticating
                            ? const Color(0xFF00D4AA)
                            : Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: _isAuthenticating
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00D4AA).withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: _isAuthenticating
                        ? const Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: Color(0xFF00D4AA),
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : Icon(
                            LineIcons.fingerprint,
                            size: 60,
                            color: _canUseBiometrics
                                ? const Color(0xFF00D4AA)
                                : Colors.grey[600],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Status Text
              Text(
                _isAuthenticating
                    ? 'Verifying...'
                    : _canUseBiometrics
                    ? 'Tap to authenticate'
                    : 'Biometrics not available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Error Message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LineIcons.exclamationTriangle,
                        color: Colors.red[400],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _errorMessage,
                        style: TextStyle(fontSize: 14, color: Colors.red[400]),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(flex: 2),

              // Retry Button
              if (!_isAuthenticating && _canUseBiometrics) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Authenticate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Skip option (only if biometrics fail repeatedly)
              if (!_canUseBiometrics)
                TextButton(
                  onPressed: () {
                    // Allow access without biometrics if not available
                    ref.read(biometricSessionProvider.notifier).state = true;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const Maintablayout()),
                    );
                  },
                  child: Text(
                    'Continue without biometrics',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),

              const SizedBox(height: 32),

              // Security Note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LineIcons.lock, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Your data is protected with biometric security',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

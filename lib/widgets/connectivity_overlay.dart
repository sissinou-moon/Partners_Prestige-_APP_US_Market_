import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:line_icons/line_icons.dart';

class ConnectivityOverlay extends StatefulWidget {
  final Widget child;

  const ConnectivityOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late StreamSubscription<InternetConnectionStatus> _internetSubscription;
  bool _isOffline = false;
  final InternetConnectionChecker _internetChecker =
      InternetConnectionChecker.instance;
  final Connectivity _connectivity = Connectivity();

  // Animation controller for the pulse effect
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Listen to network interface changes (immediate response for WiFi/Mobile toggle)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      if (results.contains(ConnectivityResult.none) && results.length == 1) {
        // Immediate offline if no network interface
        if (mounted) {
          setState(() {
            _isOffline = true;
          });
        }
      } else {
        // If interface is up, we might still be offline, but let the internet checker confirm
        // However, we can do a quick check
        bool hasConnection = await _internetChecker.hasConnection;
        if (mounted) {
          setState(() {
            _isOffline = !hasConnection;
          });
        }
      }
    });

    // Listen to actual internet status changes (handles "connected to wifi but no internet")
    _internetSubscription = _internetChecker.onStatusChange.listen((status) {
      if (mounted) {
        setState(() {
          _isOffline = status == InternetConnectionStatus.disconnected;
        });
      }
    });

    // Initial Check
    _initialCheck();
  }

  Future<void> _initialCheck() async {
    // 1. Check Connectivity first (fastest)
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none) && results.length == 1) {
      if (mounted) setState(() => _isOffline = true);
      return;
    }

    // 2. Check actual internet (slightly slower but accurate)
    bool hasConnection = await _internetChecker.hasConnection;
    if (mounted) {
      setState(() => _isOffline = !hasConnection);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _internetSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // Animated Overlay
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isOffline ? _buildOfflineOverlay() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildOfflineOverlay() {
    return Material(
      color: Colors.black.withOpacity(0.9), // Dark background
      child: AbsorbPointer(
        absorbing: true,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse effect
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF00D4AA,
                          ).withOpacity(0.1 * _opacityAnimation.value),
                        ),
                      ),
                      Container(
                        width: 150 * _scaleAnimation.value,
                        height: 150 * _scaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF00D4AA,
                            ).withOpacity(0.2 * (1 - _controller.value)),
                            width: 2,
                          ),
                        ),
                      ),
                      // Main Icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LineIcons.wifi,
                          size: 64,
                          color: Color(0xFF00D4AA), // Using brand color
                        ),
                      ),
                      // Disconnected slash
                      Positioned(
                        child: Transform.rotate(
                          angle: 0.5,
                          child: Container(
                            width: 80,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // Creative Text
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Whoops! It seems you are lost in space.\nCheck your signal and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Retry Button (Visual only, as the check is auto)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

import '../../app/storage/local_storage.dart';
import '../authentifications/SignInPage.dart';

class OnboardingSlider extends StatefulWidget {
  const OnboardingSlider({super.key});

  @override
  State<OnboardingSlider> createState() => _OnboardingSliderState();
}

class _OnboardingSliderState extends State<OnboardingSlider>
    with TickerProviderStateMixin {
  final PageController controller = PageController();
  int page = 0;
  late AnimationController _orbController;
  late AnimationController _fadeController;

  final List<Map<String, String>> slides = [
    {
      "image": "assets/Helping a partner-bro.svg",
      "title": "Welcome to Prestige+",
      "desc":
          "Manage your business rewards program and customer loyalty with ease.",
    },
    {
      "image": "assets/Data analysis-bro.svg",
      "title": "Track & Analyze",
      "desc":
          "Monitor customer engagement, point redemptions, and business performance.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _fadeController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Subtle Animated Gradient Background
          //_buildAnimatedBackground(),

          // Floating Orbs
          _buildFloatingOrb(
            top: 80,
            left: 20,
            size: 100,
            color: const Color(0xFF00D4AA).withOpacity(0.12),
            duration: 3.5,
          ),
          _buildFloatingOrb(
            bottom: 120,
            right: 30,
            size: 130,
            color: const Color(0xFF13B386).withOpacity(0.1),
            duration: 4.2,
          ),
          _buildFloatingOrb(
            top: 200,
            right: 50,
            size: 70,
            color: const Color(0xFF00D4AA).withOpacity(0.08),
            duration: 3.8,
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo with fade-in
                FadeTransition(
                  opacity: _fadeController,
                  child: Image.asset(
                    'assets/prestige_logo.png',
                    width: 90,
                    height: 30,
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: controller,
                    onPageChanged: (i) => setState(() => page = i),
                    itemCount: slides.length,
                    itemBuilder: (_, i) {
                      final s = slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration with scale animation
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF00D4AA,
                                          ).withOpacity(0.1),
                                          blurRadius: 40,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: SvgPicture.asset(
                                      s["image"]!,
                                      height: 240,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 50),

                            // Title with shimmer effect
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  const Color(0xFF13B386),
                                  const Color(0xFF00D4AA),
                                  const Color(0xFF13B386),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                s["title"]!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Description
                            Text(
                              s["desc"]!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87.withOpacity(0.65),
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slides.length,
                    (i) => AnimatedContainer(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: page == i ? 24 : 8,
                      height: 8,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        gradient: page == i
                            ? const LinearGradient(
                                colors: [Color(0xFF00D4AA), Color(0xFF13B386)],
                              )
                            : null,
                        color: page == i
                            ? null
                            : const Color(0xFF13B386).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: page == i
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00D4AA,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Navigation Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip Button
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const SignInPage(),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                              transitionDuration: const Duration(
                                milliseconds: 400,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Next/Get Started Button
                      _buildCTAButton(),
                    ],
                  ),
                ),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF00D4AA).withOpacity(0.015),
                Colors.white,
                const Color(0xFF13B386).withOpacity(0.007),
              ],
              stops: [
                0.0,
                0.3 + (_orbController.value * 0.15),
                0.6 + (_orbController.value * 0.1),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double duration,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _orbController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              math.sin(_orbController.value * 2 * math.pi / duration) * 15,
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color, color.withOpacity(0.0)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCTAButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF13B386)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (page == slides.length - 1) {
              setOnBoardingDone();
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SignInPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            } else {
              controller.nextPage(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  page == slides.length - 1 ? "Get Started" : "Next",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: _orbController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_orbController.value * 2 * math.pi) * 3,
                        0,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void setOnBoardingDone() async {
    await LocalStorage.setOnboardDone();
  }
}

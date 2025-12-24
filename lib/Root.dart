import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestige_partners/app/lib/auth.dart';
import 'package:prestige_partners/app/lib/supabase.dart';
import 'package:prestige_partners/app/providers/biometric_provider.dart';
import 'package:prestige_partners/pages/authentifications/BiometricVerificationScreen.dart';
import 'package:prestige_partners/pages/authentifications/SignInPage.dart';
import 'package:prestige_partners/pages/onBoarding/LandingPage.dart';
import 'package:prestige_partners/pages/tabs/MainTabLayout.dart';
import 'app/providers/partner_provider.dart';
import 'app/providers/subscription_provider.dart';
import 'app/providers/user_provider.dart';
import 'app/storage/local_storage.dart';
import 'package:app_links/app_links.dart';
import 'package:prestige_partners/pages/authentifications/SignUpPage.dart';
import 'dart:async';

class RootLayout extends ConsumerStatefulWidget {
  const RootLayout({super.key});

  @override
  ConsumerState<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends ConsumerState<RootLayout> {
  bool _loading = true;
  bool _authenticated = false;
  bool _forceSignUp = false;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _checkAuth();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Check initial link if app was closed
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    print('DEEP LINK RECEIVED: $uri');
    if (uri.scheme == 'prestigePartners' && uri.host == 'register') {
      setState(() {
        _forceSignUp = true;
      });
    }
  }

  bool _showOnboarding = false;

  // Update the _checkAuth method in RootLayout
  Future<void> _checkAuth() async {
    _showOnboarding = !(await LocalStorage.isOnboardDone());

    String? token = await LocalStorage.getToken();
    print(token);

    if (!_showOnboarding) {
      if (token != null && token.isNotEmpty) {
        try {
          final user = await ApiService.verifyToken(token);
          ref.read(userProvider.notifier).state = user;

          if (user['role'] != "CASHIER") {
            print("HE IS REALLY AN OWNER ✅");
            final partnerOf = await PartnerService.getPartnerByOwner(
              user['id'],
            );
            ref.read(partnerProvider.notifier).state = partnerOf.toJson();

            // ✅ FIX: Use Future.microtask to ensure build is complete
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              // Check subscription after UI is built
              print("CHECK IF HE HAS PLAN 🎟️💯");
              await ref
                  .read(subscriptionProvider.notifier)
                  .checkSubscription(user['id'], token);
            });
          } else {
            print("HE IS CASHIER WORKER 🎟️💯");
            final partnerANDbranch = await PartnerService.getCashierBranch(
              user['partner_branch_id'],
            );
            ref.read(partnerProvider.notifier).state = partnerANDbranch;
            print(partnerANDbranch);
          }

          _authenticated = true;
        } catch (err) {
          await LocalStorage.removeToken();
          _authenticated = false;
        }
      } else {
        _authenticated = false;
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch biometric session state
    final biometricVerified = ref.watch(biometricSessionProvider);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showOnboarding) {
      return LandingPage();
    }

    // If authenticated but biometric not verified, show biometric screen
    if (_authenticated && !biometricVerified) {
      return const BiometricVerificationScreen();
    }

    if (_forceSignUp) {
      return Navigator(
        onPopPage: (route, result) {
          setState(() => _forceSignUp = false);
          return route.didPop(result);
        },
        pages: const [MaterialPage(child: SignUpPage())],
      );
    }

    return _authenticated ? const Maintablayout() : const SignInPage();
  }
}

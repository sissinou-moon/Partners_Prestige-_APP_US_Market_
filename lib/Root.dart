import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prestige_partners/app/lib/auth.dart';
import 'package:prestige_partners/app/lib/supabase.dart';
import 'package:prestige_partners/pages/authentifications/SignInPage.dart';
import 'package:prestige_partners/pages/tabs/MainTabLayout.dart';
import 'app/providers/partner_provider.dart';
import 'app/providers/user_provider.dart';
import 'app/storage/local_storage.dart';

class RootLayout extends ConsumerStatefulWidget {
  const RootLayout({super.key});

  @override
  ConsumerState<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends ConsumerState<RootLayout> {
  bool _loading = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }
  bool _showOnboarding = false;

  Future<void> _checkAuth() async {
    // Check if onboarding already done
    _showOnboarding = !(await LocalStorage.isOnboardDone());

    // Only check token IF onboarding is done

      String? token = await LocalStorage.getToken();
      print(token);

      if (token != null && token.isNotEmpty) {
        try {
          final user = await ApiService.verifyToken(token);
          ref.read(userProvider.notifier).state = user;

          if(user['role'] != "CASHIER") {
            print("HE IS REALLY AN OWNER ✅");
            final partnerOf = await PartnerService.getPartnerByOwner(user['id']);

            // SAVE PARTNER
            ref.read(partnerProvider.notifier).state = partnerOf.toJson();
          } else {
            print("HE IS CASHIER WORKER 🎟️💯");
            final partnerANDbranch = await PartnerService.getCashierBranch(user['partner_branch_id']);
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

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _authenticated ? const Maintablayout() : const SignInPage();
  }

}

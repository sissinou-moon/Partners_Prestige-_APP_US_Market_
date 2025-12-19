import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import 'package:prestige_partners/pages/Settings/CustomersPage.dart';
import 'package:prestige_partners/pages/Settings/LocationsPage.dart';
import 'package:prestige_partners/pages/Settings/NotificationsPage.dart';
import 'package:prestige_partners/pages/Settings/PosIntegrationPage.dart';
import 'package:prestige_partners/pages/Settings/ProPlanPage.dart';
import 'package:prestige_partners/pages/Settings/QrCodePage.dart';
import 'package:prestige_partners/pages/Settings/ScanQrCodePage.dart';
import 'package:prestige_partners/pages/Settings/SubscriptionDetailsPage.dart';
import 'package:prestige_partners/pages/Settings/HelpCenterPage.dart';
import 'package:prestige_partners/pages/Settings/TermsConditionsPage.dart';

import '../../app/lib/supabase.dart';
import '../../app/lib/biometric_service.dart';
import '../../app/providers/partner_provider.dart';
import '../../app/providers/subscription_provider.dart';
import '../Settings/ModifyBusinessProfile.dart';

import 'package:prestige_partners/pages/Settings/EditProfilePage.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Verify biometric before navigating to a protected screen
  Future<bool> _verifyBiometric() async {
    final canAuth = await BiometricService.canAuthenticate();
    if (!canAuth) {
      // If biometrics not available, allow access
      return true;
    }

    final success = await BiometricService.authenticate(
      reason: 'Verify your identity to access this section',
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required to access this section'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return success;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSection(
            children: [
              _buildSettingsTile(
                icon: LineIcons.userEdit,
                title: 'Edit Profile',
                subtitle: 'Update personal information',
                index: 0,
                onTap: () async {
                  // Require biometric verification for Edit Profile
                  final verified = await _verifyBiometric();
                  if (verified && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  }
                },
              ),
              if (user!['role'] == "OWNER")
                _buildSettingsTile(
                  icon: LineIcons.store,
                  title: 'Business Profile',
                  subtitle: 'Manage your business information',
                  index: 0,
                  onTap: () async {
                    // Require biometric verification for Business Profile
                    final verified = await _verifyBiometric();
                    if (!verified) return;

                    // Get partner data from your provider
                    final partner = ref.read(partnerProvider);

                    if (partner != null && mounted) {
                      final partnerObj = Partner.fromJson(partner);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BusinessProfilePage(partner: partnerObj),
                        ),
                      );
                    }
                  },
                ),
              if (user['role'] == "OWNER")
                _buildSettingsTile(
                  icon: LineIcons.mapMarker,
                  title: 'Locations',
                  subtitle: 'Manage business locations',
                  index: 1,
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LocationsPage()),
                    );
                  },
                ),
              if (user['tier'] != 'Starter' && user['tier'] != 'none')
                _buildSettingsTile(
                  icon: LineIcons.user,
                  title: 'Customers',
                  subtitle: 'Manage business customers',
                  index: 1,
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CustomersPage()),
                    );
                  },
                ),
              _buildSettingsTile(
                icon: LineIcons.bell,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                index: 3,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationsPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildSection(
            children: [
              _buildSettingsTile(
                icon: LineIcons.qrcode,
                title: 'Checkout',
                subtitle: 'Scan your customers qr code for redemption',
                index: 5,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QRScannerPage()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: LineIcons.plug,
                title: 'Integrations',
                subtitle: 'Connect third-party services',
                index: 5,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => IntegrationPage()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: LineIcons.creditCard,
                title: 'Billing & Subscription',
                subtitle: 'Manage your plan and payments',
                index: 8,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        if (subscription != null && subscription.plan != null) {
                          return SubscriptionDetailsPage(
                            planName: subscription.plan!,
                          );
                        } else {
                          return PricingPage();
                        }
                      },
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: LineIcons.fileContract,
                title: 'Terms & Conditions',
                subtitle: 'Read our terms of service',
                index: 6,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsConditionsPage(),
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: LineIcons.questionCircle,
                title: 'Help Center',
                subtitle: 'Get support and view FAQs',
                index: 7,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Version 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double start = (index * 0.05).clamp(0.0, 1.0);
        final double end = (start + 0.3).clamp(0.0, 1.0);

        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.vertical(
            top: index == 0 ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: !isLast
                  ? Border(
                      bottom: BorderSide(color: Colors.grey[100]!, width: 1),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _getIconColor(index), size: 17),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LineIcons.angleRight, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor(int index) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Red
    ];
    return colors[index % colors.length];
  }

  void _navigateTo(BuildContext context, String title) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PlaceholderPage(title: title),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// Placeholder page for navigation
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(LineIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}

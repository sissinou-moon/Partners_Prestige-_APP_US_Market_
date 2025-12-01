import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/Root.dart';
import 'package:prestige_partners/app/providers/partner_provider.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';
import 'package:prestige_partners/pages/Settings/QrCodePage.dart';
import 'package:prestige_partners/pages/Settings/ScanQrCodePage.dart';

import 'package:prestige_partners/pages/tabs/CompaignPage.dart';
import 'package:prestige_partners/pages/tabs/MembersPage.dart';
import 'package:prestige_partners/pages/tabs/StorePage.dart';
import '../../app/providers/user_provider.dart';
import 'HomePage.dart';
import 'SettingsPage.dart';

class Maintablayout extends ConsumerStatefulWidget {
  const Maintablayout({super.key});

  @override
  ConsumerState<Maintablayout> createState() => _MaintablayoutState();
}

class _MaintablayoutState extends ConsumerState<Maintablayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const StorePage(),
    const MembersPage(),
    const CompaignPage(),
    const SettingsPage(),
  ];

  final List<Widget> _CashierPages = [
    const QRGeneratorPage(),
    const QRScannerPage(),
  ];

  final List<String> _pageTitles = [
    'Dashboard',
    'Store',
    'Members',
    'Campaigns',
    'Settings',
  ];


  final List<String> _cashierPageTitles = [
    'Dashboard',
    'Store',
    'Members',
    'Campaigns',
    'Settings',
  ];

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 500), () {final token = ref.watch(tokenProvider).value ?? "";});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final partner = ref.watch(partnerProvider);

    final profileImage = user?['profile_image'] as String?;
    final fullName = user?['full_name'] as String? ?? 'Guest User';
    final userRole = user?['role'] as String? ?? 'USER';

    final businessName = partner?['business_name'] as String? ?? 'Business';
    final businessType = partner?['business_type'] as String? ?? '';

    final email = partner?['email'] as String?;
    final phone = partner?['phone'] as String?;
    final website = partner?['website'] as String?;
    final address = partner?['address'] as String?;
    final city = partner?['city'] as String?;
    final state = partner?['state'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: const Color(0xFF004F54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          leading: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(top: 30),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(70, 20, 20, 20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: profileImage != null && profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage == null || profileImage.isEmpty
                          ? const Icon(Icons.person, size: 30, color: Colors.white)
                          : null,
                    ),
                  ),

                  const SizedBox(width: 10,),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hi, $fullName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          businessName == 'Business' ? '${partner!['partner']['business_type']}, ${partner['partner']['email']}' : '$businessName${businessType.isNotEmpty ? ' • $businessType' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Modern Drawer Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF004F54),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: profileImage != null && profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                          child: profileImage == null || profileImage.isEmpty
                              ? const Icon(Icons.person, size: 40, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          userRole.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Business Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FluentIcons.building_20_filled,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    businessName == 'Business' ? partner!['partner']['business_name'] : '',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (businessType.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                businessType,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation Items
            user!['role'] != "CASHIER" ? Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: LineIcons.home,
                    title: 'Dashboard',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                  _buildDrawerItem(
                    icon: LineIcons.store,
                    title: 'Store',
                    index: 1,
                    isSelected: _selectedIndex == 1,
                  ),
                  if(user['role'] != "MANAGER" || user['role'] != "CASHIER") _buildDrawerItem(
                    icon: LineIcons.users,
                    title: 'Members',
                    index: 2,
                    isSelected: _selectedIndex == 2,
                  ),
                  _buildDrawerItem(
                    icon: LineIcons.bullhorn,
                    title: 'Campaigns',
                    index: 3,
                    isSelected: _selectedIndex == 3,
                  ),
                  _buildDrawerItem(
                    icon: LineIcons.cog,
                    title: 'Settings',
                    index: 4,
                    isSelected: _selectedIndex == 4,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),

                  // Business Info Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Business Information',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  if (email != null)
                    _buildInfoTile(
                      icon: FluentIcons.mail_20_regular,
                      text: email,
                    ),
                  if (phone != null)
                    _buildInfoTile(
                      icon: FluentIcons.phone_20_regular,
                      text: phone,
                    ),
                  if (website != null)
                    _buildInfoTile(
                      icon: FluentIcons.globe_20_regular,
                      text: website,
                    ),
                  if (address != null && city != null && state != null)
                    _buildInfoTile(
                      icon: FluentIcons.location_20_regular,
                      text: '$address, $city, $state',
                    ),
                ],
              ),
            ) : Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: LineIcons.home,
                    title: 'Generate QRCode',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                  _buildDrawerItem(
                    icon: LineIcons.store,
                    title: 'Scan QRCode',
                    index: 1,
                    isSelected: _selectedIndex == 1,
                  ),
                ],
              ),
            ),

            // Logout Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => const RootLayout()));
                    ref.invalidate(userProvider);
                    LocalStorage.removeToken();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.arrow_exit_20_filled,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10,),

          ],
        ),
      ),
      body: user['role'] != "CASHIER" ? _pages[_selectedIndex] : _CashierPages[_selectedIndex],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Material(
        color: isSelected ? Color(0xFF004F54).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onDrawerItemTapped(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: Colors.teal.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Color(0xFF004F54) : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 18),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Color(0xFF004F54) : Colors.grey[400],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
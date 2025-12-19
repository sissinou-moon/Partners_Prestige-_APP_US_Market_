import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/lib/supabase.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';

import '../../app/providers/user_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  // Local state to track changes
  Map<String, bool> _notificationSettings = {};
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize settings from provider when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialSettings();
    });
  }

  void _loadInitialSettings() {
    final user = ref.read(userProvider);
    if (user != null && user['notifications'] != null) {
      print("truuuueeeee==================================");
      setState(() {
        _notificationSettings = Map<String, bool>.from(
          user['notifications'] as Map,
        );
      });
    } else {
      // Default settings if none exist
      setState(() {
        _notificationSettings = {
          'email only': false,
          'Integration errors': false,
          'Settlement updates': false,
          'Promotions reminders': false,
          'Weekly performance digest': false,
        };
      });
    }
  }

  void _toggleNotification(String key, bool value) {
    setState(() {
      _notificationSettings[key] = value;
      _hasChanges = true;
    });

    // Haptic feedback for better UX
    HapticFeedback.selectionClick();
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final user = ref.read(userProvider);
      if (user == null) throw 'User not found';

      final userId = user['id'] as String;
      final token = await LocalStorage.getToken();

      // Only send the changed settings (optimize API call)
      final updates = _notificationSettings;
      print(updates);

      await PartnerService.updateNotificationSettings(
        userId: userId,
        notifications: updates,
        token: token!,
      );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update the provider
      ref.read(userProvider.notifier).update((state) {
        if (state == null) return state;
        return {...state, 'notifications': _notificationSettings};
      });

      if (mounted) {
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings updated successfully'),
            backgroundColor: Color(0xFF00D4AA),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resetChanges() {
    HapticFeedback.lightImpact();
    _loadInitialSettings();
    setState(() => _hasChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(LineIcons.arrowLeft, color: Colors.black87),
          onPressed: () {
            if (_hasChanges) {
              _showDiscardDialog();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_hasChanges && !_isSaving)
            TextButton(
              onPressed: _resetChanges,
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00D4AA),
                  ),
                ),
              ),
            )
          else if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF00D4AA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            _buildInfoCard(),

            const SizedBox(height: 24),

            // Email Preferences Section
            _buildSection(
              title: 'Email Preferences',
              icon: LineIcons.envelope,
              child: Column(
                children: [
                  _buildNotificationToggle(
                    key: 'email only',
                    title: 'Email Only',
                    description:
                        'Receive notifications via email instead of in-app alerts',
                    icon: LineIcons.at,
                    value: _notificationSettings['email only'] ?? false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // System Notifications Section
            _buildSection(
              title: 'System Notifications',
              icon: LineIcons.bell,
              child: Column(
                children: [
                  _buildNotificationToggle(
                    key: 'Integration errors',
                    title: 'Integration Errors',
                    description: 'Get notified when integration issues occur',
                    icon: LineIcons.exclamationCircle,
                    value: _notificationSettings['Integration errors'] ?? true,
                    important: true,
                  ),
                  const Divider(height: 32),
                  _buildNotificationToggle(
                    key: 'Settlement updates',
                    title: 'Settlement Updates',
                    description: 'Receive updates about payment settlements',
                    icon: LineIcons.moneyBill,
                    value: _notificationSettings['Settlement updates'] ?? true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Marketing & Reports Section
            _buildSection(
              title: 'Marketing & Reports',
              icon: LineIcons.lineChart,
              child: Column(
                children: [
                  _buildNotificationToggle(
                    key: 'Promotions reminders',
                    title: 'Promotions Reminders',
                    description:
                        'Reminders about ongoing and upcoming promotions',
                    icon: LineIcons.bullhorn,
                    value:
                        _notificationSettings['Promotions reminders'] ?? true,
                  ),
                  const Divider(height: 32),
                  _buildNotificationToggle(
                    key: 'Weekly performance digest',
                    title: 'Weekly Performance Digest',
                    description: 'Weekly summary of your business performance',
                    icon: LineIcons.fileInvoice,
                    value:
                        _notificationSettings['Weekly performance digest'] ??
                        true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Additional Info
            _buildFooterInfo(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF13B386)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LineIcons.bellSlash,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Informed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize how you receive important updates',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00D4AA), size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String key,
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    bool important = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: important
                ? Colors.orange.withOpacity(0.1)
                : const Color(0xFF00D4AA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: important ? Colors.orange : const Color(0xFF00D4AA),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (important) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Important',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: (newValue) => _toggleNotification(key, newValue),
            activeColor: const Color(0xFF00D4AA),
            activeTrackColor: const Color(0xFF00D4AA).withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(LineIcons.infoCircle, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You can change these settings at any time. Some notifications may be required for security purposes.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDiscardDialog() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Discard',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldDiscard == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}

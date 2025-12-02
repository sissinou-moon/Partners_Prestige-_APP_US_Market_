import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/storage/local_storage.dart';

import '../../app/lib/pos.dart';
import '../../app/providers/partner_provider.dart';
import '../../app/providers/pos_provider.dart';
import '../../app/providers/user_provider.dart';

class IntegrationPage extends ConsumerStatefulWidget {
  const IntegrationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<IntegrationPage> createState() => _IntegrationPageState();
}

class _IntegrationPageState extends ConsumerState<IntegrationPage> {
  bool _isLoading = false;
  bool _isConnected = false;
  Map<String, dynamic>? _connectionData;

  // Manual connection controllers
  final _applicationIdController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _applicationSecretController = TextEditingController();
  bool _showManualForm = false;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  @override
  void dispose() {
    _applicationIdController.dispose();
    _accessTokenController.dispose();
    _applicationSecretController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectionStatus() async {
    setState(() => _isLoading = true);

    try {
      final partner = ref.read(partnerProvider);
      final user = ref.read(userProvider);

      if (partner == null || user == null) {
        throw 'Partner or user data not found';
      }

      final partnerId = partner['id'] as String;
      final token = await LocalStorage.getToken();

      final connection = await POSIntegrationService.getPOSConnection(
        partnerId: partnerId,
        token: token!,
      );

      setState(() {
        _isConnected = connection != null;
        _connectionData = connection;
        _isLoading = false;
      });

      if (connection != null) {
        ref.read(posConnectionProvider.notifier).state = connection;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to check connection: $e');
    }
  }

  Future<void> _startOAuthFlow() async {
    try {
      HapticFeedback.mediumImpact();

      final partner = ref.read(partnerProvider);
      if (partner == null) throw 'Partner data not found';

      final partnerId = partner['id'];

      final success = await POSIntegrationService.startSquareOAuth(
        partnerId: partnerId,
        provider: 'SQUARE',
      );
      //
      if (success) {
        _showInfoDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start OAuth: $e');
    }
  }

  Future<void> _disconnectPOS() async {
    print("disconnect");
    final confirmed = await _showConfirmDialog(
      title: 'Disconnect Square POS?',
      message: 'Are you sure you want to disconnect your Square POS account? This will stop syncing your data.',
      confirmText: 'Disconnect',
      isDangerous: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final partner = ref.read(partnerProvider);
      final user = ref.read(userProvider);

      if (partner == null || user == null) throw 'Partner or user data not found';

      final partnerId = partner['id'] as String;
      final token = await LocalStorage.getToken();

      final success = await POSIntegrationService.disconnect(
        partnerId,
        token!,
      );

      if (success) {
        setState(() {
          _isConnected = false;
          _connectionData = null;
        });
        ref.read(posConnectionProvider.notifier).state = null;
        _showSuccessSnackBar('Square POS disconnected successfully');
      } else {
        throw 'Failed to disconnect';
      }
    } catch (e) {
      _showErrorSnackBar('Failed to disconnect: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectManually() async {
    if (_applicationIdController.text.isEmpty ||
        _accessTokenController.text.isEmpty ||
        _applicationSecretController.text.isEmpty) {
      _showErrorSnackBar('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final partner = ref.read(partnerProvider);
      final user = ref.read(userProvider);

      if (partner == null || user == null) throw 'Partner or user data not found';

      final partnerId = partner['id'] as String;
      final token = user['token'] as String;

      final result = await POSIntegrationService.connectManually(
        partnerId: partnerId,
        token: token,
        applicationId: _applicationIdController.text,
        accessToken: _accessTokenController.text,
        applicationSecret: _applicationSecretController.text,
      );

      if (result['success'] == true) {
        setState(() {
          _isConnected = true;
          _connectionData = result['data'];
          _showManualForm = false;
        });

        // Clear controllers
        _applicationIdController.clear();
        _accessTokenController.clear();
        _applicationSecretController.clear();

        ref.read(posConnectionProvider.notifier).state = result['data'];
        _showSuccessSnackBar('Connected successfully');
        await _checkConnectionStatus();
      } else {
        throw result['message'] ?? 'Connection failed';
      }
    } catch (e) {
      _showErrorSnackBar('Failed to connect: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(LineIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'POS Integration',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LineIcons.syncIcon, color: Color(0xFF00D4AA)),
            onPressed: _isLoading ? null : _checkConnectionStatus,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00D4AA),
        ),
      )
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),

            const SizedBox(height: 24),

            // Connection Details or Connect Options
            if (_isConnected)
              _buildConnectionDetails()
            else
              _buildConnectionOptions(),

            const SizedBox(height: 24),

            // Features Section
            _buildFeaturesSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [const Color(0xFF00D4AA), const Color(0xFF00B894)]
              : [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? const Color(0xFF00D4AA) : Colors.grey)
                .withOpacity(0.3),
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
            child: Icon(
              _isConnected ? LineIcons.checkCircle : LineIcons.exclamationCircle,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Connected' : 'Not Connected',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isConnected
                      ? 'Your Square POS is syncing'
                      : 'Connect to start syncing data',
                  style: const TextStyle(
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

  Widget _buildConnectionDetails() {
    return Column(
      children: [
        _buildSection(
          title: 'Connection Details',
          icon: LineIcons.plug,
          child: Column(
            children: [
              _buildDetailRow(
                'Provider',
                'Square',
                LineIcons.creditCard,
              ),
              const Divider(height: 24),
              _buildDetailRow(
                'Connected At',
                _formatDate(_connectionData?['connection']['connected_at']),
                LineIcons.calendar,
              ),
              const Divider(height: 24),
              _buildDetailRow(
                'Status',
                'Active',
                LineIcons.checkCircle,
                valueColor: Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _disconnectPOS,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(LineIcons.unlink, color: Colors.white),
            label: const Text(
              'Disconnect Square POS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionOptions() {
    return Column(
      children: [
        _buildSection(
          title: 'Connect to Square',
          icon: LineIcons.plug,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect your Square POS account to sync customers, payments, and orders automatically.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // OAuth Connect Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startOAuthFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LineIcons.squarespace, color: Colors.white, size: 24),
                  label: const Text(
                    'Connect with Square',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Manual Connection Toggle
              TextButton.icon(
                onPressed: () {
                  setState(() => _showManualForm = !_showManualForm);
                  HapticFeedback.selectionClick();
                },
                icon: Icon(
                  _showManualForm ? LineIcons.angleUp : LineIcons.angleDown,
                  size: 18,
                ),
                label: const Text(
                  'Or connect manually with credentials',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Manual Form
              if (_showManualForm) ...[
                const SizedBox(height: 16),
                _buildManualConnectionForm(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualConnectionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Connection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your Square API credentials',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          _buildManualTextField(
            controller: _applicationIdController,
            label: 'Application ID',
            icon: LineIcons.key,
          ),
          const SizedBox(height: 12),

          _buildManualTextField(
            controller: _accessTokenController,
            label: 'Access Token',
            icon: LineIcons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 12),

          _buildManualTextField(
            controller: _applicationSecretController,
            label: 'Application Secret',
            icon: LineIcons.userSecret,
            obscureText: true,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _connectManually,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Connect',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF00D4AA), size: 18),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return _buildSection(
      title: 'Integration Features',
      icon: LineIcons.star,
      child: Column(
        children: [
          _buildFeatureItem(
            'Real-time Sync',
            'Automatically sync customers and transactions',
            LineIcons.syncIcon,
          ),
          const Divider(height: 24),
          _buildFeatureItem(
            'Customer Management',
            'Access and manage your Square customers',
            LineIcons.users,
          ),
          const Divider(height: 24),
          _buildFeatureItem(
            'Payment Processing',
            'Create and track payments seamlessly',
            LineIcons.creditCard,
          ),
          const Divider(height: 24),
          _buildFeatureItem(
            'Order Tracking',
            'Monitor orders across all locations',
            LineIcons.shoppingBag,
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
              Icon(
                icon,
                color: const Color(0xFF00D4AA),
                size: 22,
              ),
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

  Widget _buildDetailRow(
      String label,
      String value,
      IconData icon, {
        Color? valueColor,
      }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4AA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00D4AA),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4AA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00D4AA),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
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
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(LineIcons.infoCircle, color: Color(0xFF00D4AA)),
            SizedBox(width: 12),
            Text(
              'Authentication Started',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          'Please complete the authentication in your browser. Once done, return to this app and refresh to see your connection status.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: Color(0xFF00D4AA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDangerous = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
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
            style: TextButton.styleFrom(
              foregroundColor: isDangerous ? Colors.red : const Color(0xFF00D4AA),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:prestige_partners/app/providers/user_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app/lib/qrCode.dart';
import '../../app/providers/partner_provider.dart';
import '../../app/storage/local_storage.dart';

class QRGeneratorPage extends ConsumerStatefulWidget {
  const QRGeneratorPage({Key? key}) : super(key: key);

  @override
  ConsumerState<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends ConsumerState<QRGeneratorPage> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isLoading = false;
  Map<String, dynamic>? _generatedQr;

  // Form controllers
  final _rewardIdController = TextEditingController();
  final _costController = TextEditingController();
  final _maxRedemptionsController = TextEditingController(text: '1');

  String? _selectedRewardId;
  String? _selectedRewardName;

  String? _selectedBranchId;

  @override
  void dispose() {
    _rewardIdController.dispose();
    _costController.dispose();
    _maxRedemptionsController.dispose();
    super.dispose();
  }

  Future<void> _generateQr() async {
    if (_selectedBranchId == null || _selectedRewardId == null || _costController.text.trim().isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    final cost = double.tryParse(_costController.text.trim());
    if (cost == null || cost <= 0) {
      _showErrorSnackBar('Please enter a valid cost');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final partner = ref.read(partnerProvider);
      final user = ref.read(userProvider);
      if (partner == null) throw 'Partner data not found';

      final token = await LocalStorage.getToken();
      if (token == null) throw 'Authentication token not found';

      final maxRedemptions = int.tryParse(_maxRedemptionsController.text.trim()) ?? 1;

      if(user!['role'] != 'CASHIER') {
        final partnerId = partner['id'];

        final result = await QRRedeemService.createRedeemQr(
          token: token,
          branchId: _selectedBranchId!, // Use selected branch ID
          rewardId: _selectedRewardId!, // Use selected reward ID
          cost: cost,
          partnerId: partnerId,
          maxRedemptions: maxRedemptions,
        );

        if (result != null && result['qr'] != null) {
          setState(() {
            _generatedQr = result['qr'];
            _isLoading = false;
          });
          _showSuccessSnackBar('QR Code generated successfully!');
          HapticFeedback.lightImpact();
        } else {
          throw 'Failed to generate QR code';
        }
      } else {
        final partnerId = partner['partner']['id'];

        final result = await QRRedeemService.createRedeemQr(
          token: token,
          branchId: _selectedBranchId!, // Use selected branch ID
          rewardId: _selectedRewardId!, // Use selected reward ID
          cost: cost,
          partnerId: partnerId,
          maxRedemptions: maxRedemptions,
        );

        if (result != null && result['qr'] != null) {
          setState(() {
            _generatedQr = result['qr'];
            _isLoading = false;
          });
          _showSuccessSnackBar('QR Code generated successfully!');
          HapticFeedback.lightImpact();
        } else {
          throw 'Failed to generate QR code';
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to generate QR: $e');
    }
  }

// Updated _resetForm():
  void _resetForm() {
    setState(() {
      _generatedQr = null;
      _selectedRewardId = null;
      _selectedBranchId = null;
      _costController.clear();
      _maxRedemptionsController.text = '1';
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _saveQrImage() async {
    try {
      HapticFeedback.mediumImpact();

      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw 'Failed to get QR code image';

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) throw 'Failed to convert image';

      // Here you would typically use a package like path_provider and image_gallery_saver
      // to save the image to the device gallery
      _showSuccessSnackBar('QR Code saved! (Implement save to gallery)');
    } catch (e) {
      _showErrorSnackBar('Failed to save QR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);

    final role = user!['role'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: role != 'CASHIER' ? AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(LineIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Generate QR Code',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_generatedQr != null)
            IconButton(
              icon: const Icon(LineIcons.redo, color: Color(0xFF00D4AA)),
              onPressed: _resetForm,
              tooltip: 'Reset',
            ),
        ],
      ) : null,
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
            if (_generatedQr == null) ...[
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildFormSection(user['role']),
            ] else ...[
              _buildQrDisplay(),
              const SizedBox(height: 24),
              _buildQrDetails(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardDropdown(String partnerId) {
    final rewardsAsync = ref.watch(partnerRewardsProvider(partnerId));

    return rewardsAsync.when(
      data: (rewards) {
        if (rewards.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(LineIcons.exclamationTriangle, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No rewards available',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedRewardId,
              hint: Row(
                children: [
                  const Icon(LineIcons.gift, color: Color(0xFF00D4AA), size: 18),
                  const SizedBox(width: 12),
                  Text(
                    'Select Reward *',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              items: rewards.map((reward) {
                final id = reward['id'].toString();
                final name = reward['name'] ?? 'Unnamed Reward';
                final points = reward['points_required'] ?? 0;

                return DropdownMenuItem<String>(
                  value: id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$points pts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRewardId = value;
                  final reward = rewards.firstWhere((r) => r['id'].toString() == value);
                  _selectedRewardName = reward['name'];
                  // Auto-fill cost
                  _costController.text = (reward['points_required'] ?? 0).toString();
                });
                HapticFeedback.selectionClick();
              },
              icon: const Icon(LineIcons.angleDown, color: Color(0xFF00D4AA)),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00D4AA),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading rewards...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(LineIcons.exclamationCircle, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading rewards: $err',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
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
          colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
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
              LineIcons.qrcode,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Redeem QR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Generate QR codes for customers to redeem rewards',
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

  Widget _buildFormSection(String userRole) {
    final partner = ref.watch(partnerProvider);
    final partnerId = userRole == 'OWNER' ? partner!['id'] as String? : partner?['partner']['id'];

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
              const Icon(LineIcons.edit, color: Color(0xFF00D4AA), size: 22),
              const SizedBox(width: 12),
              const Text(
                'QR Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Branch Dropdown
          if (partnerId != null) _buildBranchDropdown(partnerId),
          const SizedBox(height: 16),

          // Reward Dropdown
          if (partnerId != null) _buildRewardDropdown(partnerId),
          const SizedBox(height: 16),

          // Cost
          _buildFormField(
            controller: _costController,
            label: 'Points Cost *',
            icon: LineIcons.coins,
            hint: 'Enter points required',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Max Redemptions
          _buildFormField(
            controller: _maxRedemptionsController,
            label: 'Max Redemptions',
            icon: LineIcons.users,
            hint: 'How many times can this be used?',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateQr,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(LineIcons.qrcode, color: Colors.white),
              label: const Text(
                'Generate QR Code',
                style: TextStyle(
                  fontSize: 16,
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

  Widget _buildBranchDropdown(String partnerId) {
    final branchesAsync = ref.watch(branchesProvider(partnerId));

    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(LineIcons.exclamationTriangle, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No branches available',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedBranchId,
              hint: Row(
                children: [
                  const Icon(LineIcons.mapMarker, color: Color(0xFF00D4AA), size: 18),
                  const SizedBox(width: 12),
                  Text(
                    'Select Branch *',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              items: branches.map((branch) {
                final id = branch.id.toString();
                final name = branch.branchName ?? 'Unnamed Branch';
                final address = branch.address ?? '';

                return DropdownMenuItem<String>(
                  value: id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (address.isNotEmpty)
                        Text(
                          address,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBranchId = value;
                });
                HapticFeedback.selectionClick();
              },
              icon: const Icon(LineIcons.angleDown, color: Color(0xFF00D4AA)),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00D4AA),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading branches...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(LineIcons.exclamationCircle, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading branches: $err',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF00D4AA), size: 18),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildQrDisplay() {
    final qrData = _generatedQr?['qr_data'] ?? {};
    final qrString = {
      'qr_id': _generatedQr?['id'],
      'encrypted_data': qrData['encrypted_data'],
      'nonce': qrData['nonce'],
      'authTag': _generatedQr?['metadata']?['authTag'],
    }.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Your QR Code',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan this code to redeem',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // QR Code
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00D4AA),
                  width: 3,
                ),
              ),
              child: QrImageView(
                data: qrString,
                version: QrVersions.auto,
                size: 240,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1A1A1A),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveQrImage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Color(0xFF00D4AA),
                      width: 2,
                    ),
                  ),
                  icon: const Icon(
                    LineIcons.download,
                    color: Color(0xFF00D4AA),
                  ),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00D4AA),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LineIcons.plus, color: Colors.white),
                  label: const Text(
                    'New QR',
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
        ],
      ),
    );
  }

  Widget _buildQrDetails() {
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
              const Icon(
                LineIcons.infoCircle,
                color: Color(0xFF00D4AA),
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                'QR Code Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            'Status',
            _generatedQr?['status'] ?? 'Active',
            LineIcons.checkCircle,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Max Redemptions',
            '${_generatedQr?['max_redemptions'] ?? 1}',
            LineIcons.users,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Current Uses',
            '${_generatedQr?['current_redemptions'] ?? 0}',
            LineIcons.lineChart,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
}
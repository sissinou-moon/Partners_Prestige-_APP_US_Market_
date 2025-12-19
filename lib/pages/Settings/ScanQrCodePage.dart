import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/lib/qrCode.dart';
import '../../app/lib/supabase.dart';
import '../../app/providers/partner_provider.dart';
import '../../app/providers/user_provider.dart';
import '../../app/storage/local_storage.dart';

class QRScannerPage extends ConsumerStatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends ConsumerState<QRScannerPage>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _scannerActive = true;
  bool _hasScanned = false;
  String? _lastScannedCode;
  bool _isRedeemMode = true; // true = Redeem, false = Earn
  String? _scannedUserId;

  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _setupAnimations();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showEarnBottomSheet() {
    final user = ref.read(userProvider);

    if (user!['role'] != 'CASHIER') {
      final partners = ref.read(partnerProvider);
      final partnerId = partners!['id'];
      final branchesAsync = partners != null
          ? ref.watch(branchesProvider(partners['id'] as String))
          : const AsyncValue<List<Branch>>.loading();

      int pointsToAdd = 0;
      String? selectedPartnerId = partners?.isNotEmpty == true
          ? partners!['id']
          : null;
      String? selectedBranchId;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Points',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),

                // Points Input
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Points to Add',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      LineIcons.coins,
                      color: Color(0xFF00D4AA),
                    ),
                  ),
                  onChanged: (value) => pointsToAdd = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 16),

                // Partner Dropdown
                Opacity(
                  opacity: 0.6,
                  child: TextField(
                    controller: TextEditingController(text: partnerId),
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Partner ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        LineIcons.coins,
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Branch Dropdown
                _buildBranchDropdown(),
                const SizedBox(height: 24),

                // Submit Button
                Material(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print("start========================");
                        if (pointsToAdd <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields'),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        await _processEarnQr(
                          pointsToAdd,
                          partnerId,
                          _selectedBranchId!,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ).whenComplete(() => _resetScanner());
    } else {
      final partners = ref.read(partnerProvider);
      final partnerId = partners!['partner']['id'];

      int pointsToAdd = 0;
      String? selectedPartnerId = partners?.isNotEmpty == true
          ? partners!['partner']['id']
          : null;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Points',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),

                // Points Input
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Points to Add',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      LineIcons.coins,
                      color: Color(0xFF00D4AA),
                    ),
                  ),
                  onChanged: (value) => pointsToAdd = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 16),

                // Partner Dropdown
                Opacity(
                  opacity: 0.6,
                  child: TextField(
                    controller: TextEditingController(text: partnerId),
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Partner ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        LineIcons.coins,
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Branch Dropdown
                //_buildBranchDropdown(),
                const SizedBox(height: 24),

                // Submit Button
                Material(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print("start========================");
                        if (pointsToAdd <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields'),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        await _processEarnQr(pointsToAdd, partnerId, '');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4AA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ).whenComplete(() => _resetScanner());
    }
  }

  Future<void> _processEarnQr(
    int points,
    String partnerId,
    String branchId,
  ) async {
    _showProcessingDialog();

    final token = await LocalStorage.getToken();
    if (token == null) {
      Navigator.of(context).pop();
      _showResultDialog(
        success: false,
        title: 'Authentication Error',
        message: 'Session expired. Please login again.',
        icon: LineIcons.lock,
      );
      return;
    }

    final result = await QRRedeemService.scanEarnQr(
      token: token,
      userId: _scannedUserId!,
      pointsToAdd: points,
      partnerId: partnerId,
      partnerBranchId: branchId,
    );

    if (mounted) Navigator.of(context).pop();

    if (result?['message'] == 'Points earned successfully') {
      _showResultDialog(
        success: true,
        title: 'Points Added! 🎉',
        message:
            'Successfully added ${result!['points']} points.\n\nNew balance: ${result['new_balance']} points',
        icon: LineIcons.checkCircle,
      );
    } else {
      _showResultDialog(
        success: false,
        title: 'Failed',
        message: result?['message'] ?? 'Failed to add points',
        icon: LineIcons.timesCircle,
      );
    }
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    print("1");

    if (_isProcessing || !_scannerActive) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;
    print("2");

    final code = barcode.rawValue!;
    if (_lastScannedCode == code && _hasScanned) return;

    _lastScannedCode = code;
    _hasScanned = true;
    print("3");

    setState(() {
      _isProcessing = true;
      _scannerActive = false;
    });
    print("4");

    HapticFeedback.mediumImpact();
    await _scannerController?.stop();
    print("5");

    if (_isRedeemMode) {
      print("Redeem Started");
      await _processQrCode(code);
    } else {
      // Earn mode - extract user_id and show bottom sheet
      _scannedUserId = code; // Assuming QR contains just user_id
      print("Scan Started");
      print(_scannedUserId);
      _showEarnBottomSheet();
    }
  }

  Future<void> _processQrCode(String qrContent) async {
    try {
      // Add detailed logging
      print("🔵 RAW QR CONTENT: $qrContent");
      // Parse QR data
      final qrData = QRRedeemService.parseQrData(qrContent);

      print("🔵 PARSED QR DATA TYPE: ${qrData.runtimeType}");
      print("🔵 PARSED QR DATA: $qrData");

      if (qrData == null) {
        _showResultDialog(
          success: false,
          title: 'Invalid QR Code',
          message: 'The scanned QR code is not valid.',
          icon: LineIcons.timesCircle,
        );
        return;
      }

      // Log what we're about to send
      print("🔵 QR_ID: ${qrData['qr_id']}");
      print("🔵 ENCRYPTED_DATA: ${qrData['encrypted_data']}");
      print("🔵 NONCE: ${qrData['nonce']}");
      print("🔵 AUTH_TAG: ${qrData['authTag']}");

      await _executeRedeem(
        userId: qrData['user_id'] as String,
        qrId: qrData['qr_id'],
        encryptedData: qrData['encrypted_data'],
        nonce: qrData['nonce'],
        authTag: qrData['authTag'],
      );
    } catch (e) {
      print("🔴 QR PROCESS ERROR: $e");
      _showResultDialog(
        success: false,
        title: 'Error',
        message: 'An unexpected error occurred: $e',
        icon: LineIcons.exclamationTriangle,
      );
    }
  }

  Future<void> _executeRedeem({
    required String userId,
    required String qrId,
    required String encryptedData,
    required String nonce,
    required String authTag,
  }) async {
    final token = await LocalStorage.getToken();

    if (token == null) {
      _showResultDialog(
        success: false,
        title: 'Authentication Error',
        message: 'Session expired. Please login again.',
        icon: LineIcons.lock,
      );
      return;
    }

    // Show processing dialog
    _showProcessingDialog();

    // Call API to redeem
    final result = await QRRedeemService.scanRedeemQr(
      token: token,
      userId: userId,
      qrId: qrId,
      encryptedData: encryptedData,
      nonce: nonce,
      authTag: authTag,
    );

    // Close processing dialog
    if (mounted) Navigator.of(context).pop();

    if (result == null) {
      _showResultDialog(
        success: false,
        title: 'Network Error',
        message: 'Failed to connect to server. Please try again.',
        icon: LineIcons.exclamationTriangle,
      );
      return;
    }

    if (result['success'] == true) {
      final data = result['data'];
      final remainingBalance = data['remaining_balance'] ?? 0;
      final pointsSpent = data['transaction']?['amount_points']?.abs() ?? 0;

      _showResultDialog(
        success: true,
        title: 'Redemption Successful! 🎉',
        message:
            'You have successfully redeemed $pointsSpent points.\n\nRemaining balance: $remainingBalance points',
        icon: LineIcons.checkCircle,
        extraData: data,
      );
    } else {
      final error = result['error'] ?? 'Failed to redeem';
      final balance = result['balance'];
      final required = result['required'];

      String message = error;
      if (balance != null && required != null) {
        message =
            'Insufficient points!\n\nYour balance: $balance points\nRequired: $required points';
      }

      _showResultDialog(
        success: false,
        title: 'Redemption Failed',
        message: message,
        icon: LineIcons.timesCircle,
      );
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00D4AA)),
                const SizedBox(height: 20),
                const Text(
                  'Processing Redemption...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
    required IconData icon,
    Map<String, dynamic>? extraData,
  }) {
    final user = ref.read(userProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: success
                  ? [Colors.white, const Color(0xFF00D4AA).withOpacity(0.05)]
                  : [Colors.white, Colors.red.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: success
                      ? const Color(0xFF00D4AA).withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: success ? const Color(0xFF00D4AA) : Colors.red,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (user!['role'] != 'CASHIER')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(
                            context,
                          ).pop(); // Go back to previous screen
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: success
                                ? const Color(0xFF00D4AA)
                                : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: success
                                ? const Color(0xFF00D4AA)
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetScanner();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: success
                            ? const Color(0xFF00D4AA)
                            : Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Scan Again',
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
        ),
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
      _scannerActive = true;
      _hasScanned = false;
      _lastScannedCode = null;
    });
    _scannerController?.start();
    HapticFeedback.selectionClick();
  }

  void _toggleFlash() {
    _scannerController?.toggleTorch();
    HapticFeedback.selectionClick();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);

    final role = user!['role'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // Overlay
          _buildOverlay(),

          // Top Bar
          _buildTopBar(role),

          // Bottom Info Card
          _buildBottomCard(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Scanning animation line
          if (_scannerActive)
            Align(
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return Container(
                    height: 280,
                    width: 280,
                    alignment: Alignment(
                      0,
                      -1 + (_scanLineAnimation.value * 2),
                    ),
                    child: Container(
                      height: 3,
                      width: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF00D4AA),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // Corner indicators
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 280,
              width: 280,
              child: Stack(
                children: [
                  _buildCorner(Alignment.topLeft, true, true),
                  _buildCorner(Alignment.topRight, true, false),
                  _buildCorner(Alignment.bottomLeft, false, true),
                  _buildCorner(Alignment.bottomRight, false, false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment, bool isTop, bool isLeft) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Color(0xFF00D4AA), width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Color(0xFF00D4AA), width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Color(0xFF00D4AA), width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Color(0xFF00D4AA), width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            topRight: isTop && !isLeft
                ? const Radius.circular(20)
                : Radius.zero,
            bottomLeft: !isTop && isLeft
                ? const Radius.circular(20)
                : Radius.zero,
            bottomRight: !isTop && !isLeft
                ? const Radius.circular(20)
                : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String role) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (role != 'CASHIER')
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        LineIcons.arrowLeft,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _scannerController?.torchEnabled ?? false
                          ? LineIcons.lightbulb
                          : LineIcons.lightbulbAlt,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isRedeemMode = true;
                        _resetScanner();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isRedeemMode
                              ? const Color(0xFF00D4AA)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Redeem',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isRedeemMode = false;
                        _resetScanner();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isRedeemMode
                              ? const Color(0xFF00D4AA)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Earn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchDropdown() {
    final partner = ref.watch(partnerProvider);
    if (partner == null) {
      return const SizedBox();
    }

    final branchesAsync = ref.watch(branchesProvider(partner['id']));

    return branchesAsync.when(
      data: (branches) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonFormField<String>(
            value: _selectedBranchId,
            decoration: InputDecoration(
              labelText: 'Select Branch',
              labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              prefixIcon: const Icon(
                LineIcons.store,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select a branch'),
              ),
              ...branches.map((branch) {
                return DropdownMenuItem(
                  value: branch.id,
                  child: Text('${branch.branchName}'),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedBranchId = value;
              });
            },
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00D4AA),
            ),
          ),
        ),
      ),
      error: (error, stack) {
        print(partner['id']);
        print(branchesAsync);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Error loading branches: $error',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        );
      },
    );
  }

  Widget _buildBottomCard() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LineIcons.qrcode,
                    color: Color(0xFF00D4AA),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRedeemMode
                            ? 'Scan Redeem QR Code'
                            : 'Scan User QR Code',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isProcessing
                            ? 'Processing...'
                            : 'Align QR code within the frame',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    LineIcons.infoCircle,
                    size: 18,
                    color: Color(0xFF00D4AA),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure the QR code is clear and well-lit',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _showManualEntryDialog,
              child: const Text(
                "Problem scanning? Enter manually",
                style: TextStyle(
                  color: Color(0xFF00D4AA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Manual Entry - ${_isRedeemMode ? "Redeem" : "Earn"}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              if (_isRedeemMode)
                _buildManualRedeemForm()
              else
                _buildManualEarnForm(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualEarnForm() {
    String userId = "";
    return Column(
      children: [
        TextField(
          onChanged: (val) => userId = val,
          decoration: InputDecoration(
            labelText: 'User ID',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(LineIcons.user, color: Color(0xFF00D4AA)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (userId.isEmpty) return;
              Navigator.pop(context);
              setState(() {
                _scannedUserId = userId;
              });
              _showEarnBottomSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualRedeemForm() {
    final user = ref.read(userProvider);
    final partners = ref.watch(partnerProvider);
    if (partners == null) return const SizedBox();

    String partnerId;
    if (user!['role'] != 'CASHIER') {
      partnerId = partners['id'];
    } else {
      partnerId = partners['partner']['id'];
    }

    // Local state for the form
    String? selectedRewardId;
    Map<String, dynamic>? selectedReward;
    String userId = "";

    return Consumer(
      builder: (context, ref, child) {
        final rewardsAsync = ref.watch(partnerRewardsProvider(partnerId));

        return rewardsAsync.when(
          data: (rewards) {
            // Filter rewards with active QR codes
            final activeRewards = rewards.where((r) {
              final activeQr = r['active_qr_codes'];
              return activeQr != null && (activeQr as List).isNotEmpty;
            }).toList();

            if (activeRewards.isEmpty) {
              return const Text("No active rewards available for redemption.");
            }

            return StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedRewardId,
                      decoration: InputDecoration(
                        labelText: 'Select Reward',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          LineIcons.gift,
                          color: Color(0xFF00D4AA),
                        ),
                      ),
                      isExpanded: true,
                      items: activeRewards.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['id'] as String,
                          child: Text(
                            r['title'] ?? 'Unknown Reward',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedRewardId = val;
                          selectedReward = activeRewards.firstWhere(
                            (r) => r['id'] == val,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (val) => userId = val,
                      decoration: InputDecoration(
                        labelText: 'User ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          LineIcons.user,
                          color: Color(0xFF00D4AA),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedReward == null || userId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a reward and enter user ID',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);

                          final activeQr =
                              (selectedReward!['active_qr_codes'] as List)
                                  .first;
                          // Extract needed data safely
                          final qrId = activeQr['id'];
                          final encryptedData = activeQr['encrypted_data'];
                          final nonce = activeQr['nonce'];
                          final metadata =
                              activeQr['metadata'] as Map<String, dynamic>?;
                          final authTag = metadata?['authTag'];

                          if (qrId == null ||
                              encryptedData == null ||
                              nonce == null ||
                              authTag == null) {
                            _showResultDialog(
                              success: false,
                              title: 'Error',
                              message:
                                  'Reward data is incomplete. Cannot redeem.',
                              icon: LineIcons.exclamationTriangle,
                            );
                            return;
                          }

                          await _executeRedeem(
                            userId: userId,
                            qrId: qrId,
                            encryptedData: encryptedData,
                            nonce: nonce,
                            authTag: authTag,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4AA),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Redeem',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
          ),
          error: (err, stack) => Text(
            'Error loading rewards: $err',
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }
}

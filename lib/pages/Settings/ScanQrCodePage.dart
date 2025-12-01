import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/lib/qrCode.dart';
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

  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;

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

    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || !_scannerActive) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = barcode.rawValue!;

    // Prevent duplicate scans
    if (_lastScannedCode == code && _hasScanned) return;

    _lastScannedCode = code;
    _hasScanned = true;

    setState(() {
      _isProcessing = true;
      _scannerActive = false;
    });

    HapticFeedback.mediumImpact();
    await _scannerController?.stop();

    await _processQrCode(code);
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

      final userId = qrData['user_id'] as String;
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
        qrId: qrData['qr_id'],
        encryptedData: qrData['encrypted_data'],
        nonce: qrData['nonce'],
        authTag: qrData['authTag'],
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
          message: 'You have successfully redeemed $pointsSpent points.\n\nRemaining balance: $remainingBalance points',
          icon: LineIcons.checkCircle,
          extraData: data,
        );
      } else {
        final error = result['error'] ?? 'Failed to redeem';
        final balance = result['balance'];
        final required = result['required'];

        String message = error;
        if (balance != null && required != null) {
          message = 'Insufficient points!\n\nYour balance: $balance points\nRequired: $required points';
        }

        _showResultDialog(
          success: false,
          title: 'Redemption Failed',
          message: message,
          icon: LineIcons.timesCircle,
        );
      }
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
                const CircularProgressIndicator(
                  color: Color(0xFF00D4AA),
                ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Go back to previous screen
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: success ? const Color(0xFF00D4AA) : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: success ? const Color(0xFF00D4AA) : Colors.red,
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
                        backgroundColor:
                        success ? const Color(0xFF00D4AA) : Colors.red,
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
          role != 'CASHIER' ? _buildTopBar() : SizedBox(),

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
            topRight: isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
            bottomLeft:
            !isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            bottomRight:
            !isTop && !isLeft ? const Radius.circular(20) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(LineIcons.arrowLeft, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Flash Toggle
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
      ),
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
                      const Text(
                        'Scan Redeem QR Code',
                        style: TextStyle(
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
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
}
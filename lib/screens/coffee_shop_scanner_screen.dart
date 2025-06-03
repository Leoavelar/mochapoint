// lib/screens/coffee_shop_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/redemption_service.dart';
import '../services/auth_service.dart';

class CoffeeShopScannerScreen extends StatefulWidget {
  const CoffeeShopScannerScreen({Key? key}) : super(key: key);

  @override
  State<CoffeeShopScannerScreen> createState() => _CoffeeShopScannerScreenState();
}

class _CoffeeShopScannerScreenState extends State<CoffeeShopScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Customer QR Code'),
        backgroundColor: const Color(0xFFA6623A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                return const Icon(Icons.flip_camera_ios);
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner area
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onDetect,
                ),

                // Scanning overlay
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: const Color(0xFFA6623A),
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 8,
                      cutOutSize: MediaQuery.of(context).size.width * 0.7,
                    ),
                  ),
                ),

                // Processing overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Processing redemption...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Instructions and controls
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Position the customer\'s QR code within the frame',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The code will be scanned automatically',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Camera controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.pause,
                        label: 'Pause',
                        onPressed: () => cameraController.stop(),
                      ),
                      _buildControlButton(
                        icon: Icons.play_arrow,
                        label: 'Resume',
                        onPressed: () => cameraController.start(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFA6623A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            color: const Color(0xFFA6623A),
            iconSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFA6623A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && !_isProcessing && code != _lastScannedCode) {
        _lastScannedCode = code;
        _processQRCode(code);
        break;
      }
    }
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await RedemptionService.validateAndRedeem(qrCode);

      if (result['success']) {
        _showSuccessDialog(result);
      } else {
        _showErrorDialog(result['error']);
      }
    } catch (e) {
      _showErrorDialog('Failed to process QR code: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });

      // Reset scanning after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _lastScannedCode = null;
          });
        }
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    final customer = result['customer'];
    final redemption = result['redemption'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Coffee Redeemed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Customer', customer['name'] ?? 'Unknown'),
            _buildInfoRow('Type', customer['redemptionType'] == 'subscription' ? 'Subscription' : 'Joker'),
            if (customer['subscriptionInfo'] != null)
              _buildInfoRow('Bundle', customer['subscriptionInfo']['bundleName'] ?? 'N/A'),
            if (customer['redemptionType'] == 'joker')
              _buildInfoRow('Remaining Jokers', '${customer['remainingJokers']}'),
            _buildInfoRow('Time', DateTime.now().toString().substring(0, 16)),

            const SizedBox(height: 16),

            // Available coffee types based on subscription
            if (customer['subscriptionInfo']?['allowedCoffeeTypes'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Coffee Types:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (customer['subscriptionInfo']['allowedCoffeeTypes'] as List)
                          .join(', '),
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Continue Scanning'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCoffeeTypeDialog(customer, redemption);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA6623A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Coffee Type'),
          ),
        ],
      ),
    );
  }

  void _showCoffeeTypeDialog(Map<String, dynamic> customer, Map<String, dynamic> redemption) {
    final coffeeTypes = [
      'Espresso',
      'Americano',
      'Cappuccino',
      'Latte',
      'Macchiato',
      'Mocha',
      'Flat White',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What coffee was served?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: coffeeTypes.map((type) => ListTile(
            title: Text(type),
            onTap: () {
              Navigator.of(context).pop();
              _logCoffeeType(type);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _logCoffeeType(String coffeeType) {
    // Here you could send the coffee type to your analytics
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coffee type "$coffeeType" logged for analytics'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Redemption Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Custom overlay shape class
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    final double cutOutWidth = cutOutSize;
    final double cutOutHeight = cutOutSize;
    final Rect cutOutRect = Rect.fromLTWH(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    path.addRect(rect);
    path.addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)));
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final double cutOutWidth = cutOutSize;
    final double cutOutHeight = cutOutSize;
    final Rect cutOutRect = Rect.fromLTWH(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Draw corner borders
    final Path borderPath = Path();

    // Top-left corner
    borderPath.moveTo(cutOutRect.left - borderWidth / 2, cutOutRect.top + borderLength);
    borderPath.lineTo(cutOutRect.left - borderWidth / 2, cutOutRect.top + borderRadius);
    borderPath.arcToPoint(
      Offset(cutOutRect.left + borderRadius, cutOutRect.top - borderWidth / 2),
      radius: Radius.circular(borderRadius),
    );
    borderPath.lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderWidth / 2);

    // Top-right corner
    borderPath.moveTo(cutOutRect.right - borderLength, cutOutRect.top - borderWidth / 2);
    borderPath.lineTo(cutOutRect.right - borderRadius, cutOutRect.top - borderWidth / 2);
    borderPath.arcToPoint(
      Offset(cutOutRect.right + borderWidth / 2, cutOutRect.top + borderRadius),
      radius: Radius.circular(borderRadius),
    );
    borderPath.lineTo(cutOutRect.right + borderWidth / 2, cutOutRect.top + borderLength);

    // Bottom-right corner
    borderPath.moveTo(cutOutRect.right + borderWidth / 2, cutOutRect.bottom - borderLength);
    borderPath.lineTo(cutOutRect.right + borderWidth / 2, cutOutRect.bottom - borderRadius);
    borderPath.arcToPoint(
      Offset(cutOutRect.right - borderRadius, cutOutRect.bottom + borderWidth / 2),
      radius: Radius.circular(borderRadius),
    );
    borderPath.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + borderWidth / 2);

    // Bottom-left corner
    borderPath.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom + borderWidth / 2);
    borderPath.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom + borderWidth / 2);
    borderPath.arcToPoint(
      Offset(cutOutRect.left - borderWidth / 2, cutOutRect.bottom - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    borderPath.lineTo(cutOutRect.left - borderWidth / 2, cutOutRect.bottom - borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth,
    overlayColor: overlayColor,
  );
}
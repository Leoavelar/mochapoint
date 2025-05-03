// Path: lib/widgets/qr_code_widget.dart

import 'package:flutter/material.dart';

class QRCodeWidget extends StatelessWidget {
  const QRCodeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;

    // Centered container with white background
    return Center(
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        color: Colors.white,
        shadowColor: Colors.black26, // Add this line
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Today\'s Coffee',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Valid until midnight',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // QR code container
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // QR code image instead of CustomPaint
                    Image.asset(
                      'assets/images/qr_code.png', // Your QR code image
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image not found
                        return CustomPaint(
                          size: const Size(220, 220),
                          painter: QRCodePainter(),
                        );
                      },
                    ),

                    // Centered logo
                    // Container(
                    //   width: 50,
                    //   height: 50,
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     shape: BoxShape.circle,
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.white.withOpacity(0.1),
                    //         blurRadius: 4,
                    //         offset: const Offset(0, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   child: ClipOval(
                    //     child: Image.asset(
                    //       'assets/images/Icon.png',
                    //       width: 40,
                    //       height: 40,
                    //       // errorBuilder: (context, error, stackTrace) {
                    //       //   return Container(
                    //       //     color: coffeeBean,
                    //       //     child: const Icon(
                    //       //       Icons.coffee,
                    //       //       color: Colors.white,
                    //       //       size: 24,
                    //       //     ),
                    //       //   );
                    //       // },
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ready to redeem status with green background
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ready to Redeem',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for QR code display
class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 8;

    // Draw a simplified QR code pattern
    // Top-left position detection pattern
    canvas.drawRect(Rect.fromLTWH(cellSize, cellSize, cellSize * 2, cellSize * 2), paint);

    // Top-right position detection pattern
    canvas.drawRect(Rect.fromLTWH(cellSize * 5, cellSize, cellSize * 2, cellSize * 2), paint);

    // Bottom-left position detection pattern
    canvas.drawRect(Rect.fromLTWH(cellSize, cellSize * 5, cellSize * 2, cellSize * 2), paint);

    // Some random data cells to make it look like a QR code
    canvas.drawRect(Rect.fromLTWH(cellSize * 4, cellSize * 4, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize * 5, cellSize * 5, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize * 6, cellSize * 4, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize * 6, cellSize * 6, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize * 4, cellSize * 6, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize * 5, cellSize * 7, cellSize, cellSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
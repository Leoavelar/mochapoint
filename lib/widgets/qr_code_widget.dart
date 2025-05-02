// Path: lib/widgets/qr_code_widget.dart

import 'package:flutter/material.dart';

class QRCodeWidget extends StatelessWidget {
  const QRCodeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final darkGreen = Theme.of(context).primaryColor;
    final coffeeBean = Theme.of(context).colorScheme.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Today\'s Coffee',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Valid until midnight',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // QR code container with logo overlay
          Stack(
            alignment: Alignment.center,
            children: [
              // QR code background
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: darkGreen, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.qr_code,
                    size: 160,
                    color: darkGreen,
                  ),
                ),
              ),
              // Logo overlay in center
              Positioned(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: darkGreen, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.location_on,
                      color: coffeeBean,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: darkGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: darkGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: darkGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ready to Redeem',
                  style: TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
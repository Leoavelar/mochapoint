// Path: lib/widgets/logo_widget.dart

import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool darkBackground;

  const LogoWidget({
    Key? key,
    this.size = 60.0,
    this.darkBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final darkGreen = Theme.of(context).primaryColor;
    final coffeeBean = Theme.of(context).colorScheme.secondary;

    // Determine colors based on background
    final pinColor = darkBackground ? Colors.white : darkGreen;
    final backgroundColor = darkBackground ? darkGreen : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          if (!darkBackground)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Location pin outer shape
          Icon(
            Icons.location_on,
            size: size * 0.9,
            color: pinColor,
          ),

          // Coffee bean in the center
          Positioned(
            top: size * 0.25,
            child: Container(
              width: size * 0.3,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: coffeeBean,
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
              child: Center(
                child: Container(
                  width: size * 0.1,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.05),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
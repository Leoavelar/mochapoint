import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import '../services/auth_service.dart';
import 'profile_avatar.dart';
import '../screens/home_screen.dart';
import 'dart:math' as math;

class AppHeader extends StatefulWidget {
  final String backgroundImage;
  final double height;
  final double borderRadius;

  const AppHeader({
    super.key,
    required this.backgroundImage,
    this.height = 175.0,
    this.borderRadius = 100.0, // Increased from 20.0
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Wave animation controller - smooth back-and-forth motion with easing
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Apply ease-in-out curve for smooth acceleration/deceleration
    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

    // Repeat with reverse - slows down at ends, speeds up in middle
    _waveController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _navigateToProfile() {
    final homeScreen = context.findAncestorStateOfType<HomeScreenState>();
    if (homeScreen != null) {
      homeScreen.setSelectedIndex(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(widget.borderRadius),
        bottomRight: Radius.circular(widget.borderRadius),
      ),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),

            // Animated dark espresso wave layer (only one animated layer)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: HeaderCoffeeLiquidPainter(
                      wavePhase: _waveAnimation.value * 2 * math.pi,
                      height: widget.height,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),

            // Dark gradient overlay for better text/icon visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.05),
                  ],
                ),
              ),
            ),

            // Content layer
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo icon on the left
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: Image.asset(
                          'assets/icons/mocha_icon_black.png',
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                    // Profile avatar on the right
                    ProfileAvatar(
                      user: _user,
                      size: 60,
                      showBorder: true,
                      onTap: _navigateToProfile,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Header coffee liquid painter - single coffee wave over image background
class HeaderCoffeeLiquidPainter extends CustomPainter {
  final double wavePhase;
  final double height;

  // Light brown coffee color for the wave (from the original froth gradient)
  static const Color coffeeColor = Color(0xFF94511A); // Updated medium brown

  HeaderCoffeeLiquidPainter({
    required this.wavePhase,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Only paint ONE layer: Light brown coffee wave
    // The image is now the static background

    final espressoLevel = size.height * 0.6; // Starts at 75% from top (lowered, closer to bottom)
    final espressoPath = Path();
    espressoPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 3) {
      final distanceFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final amplitude = 8 * (1 - distanceFromCenter * 0.1);

      // Wave pattern
      final wave1 = math.sin((x / size.width) * 3 * math.pi + wavePhase) * amplitude;
      final wave2 = math.sin((x / size.width) * 5 * math.pi - wavePhase * 0.7) * (amplitude * 0.5);

      final y = espressoLevel + wave1 + wave2;
      espressoPath.lineTo(x, y.clamp(0, size.height));
    }

    espressoPath.lineTo(size.width, size.height);
    espressoPath.close();

    final espressoPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          coffeeColor,
          MyApp.coffeeBean,
          MyApp.coffeeBean,
          Colors.black,// Light brown at top
          Colors.black,   // Black at bottom
        ],
      ).createShader(Rect.fromLTWH(0, espressoLevel, size.width, size.height - espressoLevel))
      ..style = PaintingStyle.fill;

    canvas.drawPath(espressoPath, espressoPaint);
  }

  @override
  bool shouldRepaint(HeaderCoffeeLiquidPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase;
  }
}
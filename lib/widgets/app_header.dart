import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_avatar.dart';
import '../screens/home_screen.dart';
import 'dart:math' as math;

class AppHeader extends StatefulWidget {
  final String backgroundImage;
  final double height;
  final double borderRadius;

  const AppHeader({
    Key? key,
    required this.backgroundImage,
    this.height = 200.0,
    this.borderRadius = 20.0,
  }) : super(key: key);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> with SingleTickerProviderStateMixin {
  // Coffee-themed colors (matching splash screen)
  static const Color lightCream = Color(0xFFF9F5F1); // Light tone background
  static const Color frothColor = Color(0xFFA6623A); // Light brown froth
  static const Color darkEspresso = Color(0xFF472A19); // Dark espresso

  Map<String, dynamic>? _user;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Wave animation controller - smooth back-and-forth motion
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true); // Play forward then backward
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
      child: Container(
        height: widget.height,
        child: Stack(
          children: [
            // Base layer - Light cream background
            Container(
              decoration: const BoxDecoration(
                color: lightCream,
              ),
            ),

            // Animated coffee liquid layer (like splash screen but covering full header)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: HeaderCoffeeLiquidPainter(
                      wavePhase: _waveController.value * 2 * math.pi,
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
                          'assets/icons/mocha_icon_white.png',
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

// Header coffee liquid painter - adapted from splash screen
class HeaderCoffeeLiquidPainter extends CustomPainter {
  final double wavePhase;
  final double height;

  // Same colors as splash screen
  static const Color frothColor = Color(0xFFA6623A); // Light brown froth
  static const Color darkEspresso = Color(0xFF472A19); // Dark espresso
  static const Color creamBackground = Color(0xFFF9F5F1);

  HeaderCoffeeLiquidPainter({
    required this.wavePhase,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background - cream
    final bgPaint = Paint()..color = frothColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // LAYER 1: Light brown froth layer (bottom z-index)
    // Covers more of the header
    final frothLevel = size.height * 0.3; // Starts at 30% from top
    final frothPath = Path();
    frothPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 3) {
      final distanceFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final amplitude = 8 * (1 - distanceFromCenter * 0.3); // Slightly smaller amplitude for header

      // Same wave pattern as splash screen
      final wave1 = math.sin((x / size.width) * 3 * math.pi + wavePhase) * amplitude;
      final wave2 = math.sin((x / size.width) * 5 * math.pi - wavePhase * 0.7) * (amplitude * 0.5);

      final y = frothLevel + wave1 + wave2;
      frothPath.lineTo(x, y.clamp(0, size.height));
    }

    frothPath.lineTo(size.width, size.height);
    frothPath.close();

    final frothPaint = Paint()
      ..color = darkEspresso
      ..style = PaintingStyle.fill;

    canvas.drawPath(frothPath, frothPaint);

    // LAYER 2: Dark espresso layer (top z-index)
    final espressoLevel = size.height * 0.55; // Starts at 55% from top
    final espressoPath = Path();
    espressoPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 3) {
      final distanceFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final amplitude = 8 * (1 - distanceFromCenter * 0.3);

      // Same wave pattern as froth
      final wave1 = math.sin((x / size.width) * 3 * math.pi + wavePhase) * amplitude;
      final wave2 = math.sin((x / size.width) * 5 * math.pi - wavePhase * 0.7) * (amplitude * 0.5);

      final y = espressoLevel + wave1 + wave2;
      espressoPath.lineTo(x, y.clamp(0, size.height));
    }

    espressoPath.lineTo(size.width, size.height);
    espressoPath.close();

    final espressoPaint = Paint()
      ..color = darkEspresso
      ..style = PaintingStyle.fill;

    canvas.drawPath(espressoPath, espressoPaint);
  }

  @override
  bool shouldRepaint(HeaderCoffeeLiquidPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase;
  }
}
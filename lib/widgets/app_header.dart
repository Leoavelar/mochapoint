import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mocha_point/main.dart';
import '../services/auth_service.dart';
import 'profile_avatar.dart';
import '../screens/home_screen.dart';
import 'dart:math' as math;

class AppHeader extends StatefulWidget {
  final String backgroundImage;
  // final double height;
  final double borderRadius;

  const AppHeader({
    super.key,
    required this.backgroundImage,
    // this.height = 120.0,
    this.borderRadius = 00.0,
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

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

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
        // height: widget.height,
        child: Stack(
          children: [
            // Content layer

            SafeArea(
              child: Padding(
                // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                padding: const EdgeInsets.only(top: 32, left: 8, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting text on the left (replacing logo)
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Montserrat',
                            height: 1.25,
                            letterSpacing: -1,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Good morning\n[',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: 'Leonardo',
                              style: TextStyle(color: MyApp.coffeeAccent),
                            ),
                            const TextSpan(
                              text: ']',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

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

  static const Color coffeeColor = Color(0xFF94511A);

  HeaderCoffeeLiquidPainter({
    required this.wavePhase,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final espressoLevel = size.height * 0.6;
    final espressoPath = Path();
    espressoPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 3) {
      final distanceFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final amplitude = 8 * (1 - distanceFromCenter * 0.1);

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
          // MyApp.coffeeBean,
          Colors.black,
          Colors.black,
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
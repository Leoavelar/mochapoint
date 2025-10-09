// lib/screens/splash_screen.dart - Clean Two-Layer Coffee Liquid with Bigger Offset
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _squashAnimation;
  late Animation<double> _stretchAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Bounce animation controller
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Wave animation controller - smooth continuous motion
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Fade in animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Slide animation with bounce back
    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -50.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 8,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -15.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -15.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 32,
      ),
    ]).animate(_bounceController);

    // Squash animation
    _squashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
    ]).animate(_bounceController);

    // Stretch animation
    _stretchAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
    ]).animate(_bounceController);

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _bounceController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cream background for upper 3/4
          Container(
            color: const Color(0xFFF9F5F1),
          ),

          // Coffee liquid animation at bottom 1/4
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.25, // Only bottom 1/4
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CoffeeLiquidPainter(
                    wavePhase: _waveController.value * 2 * math.pi,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Content on top - fully transparent
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated coffee bean icon - NO background
                  AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Transform.scale(
                          scaleX: _stretchAnimation.value,
                          scaleY: _squashAnimation.value,
                          child: Image.asset(
                            'assets/icons/mocha_icon_black.png',
                            width: 120,
                            height: 120,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Text without background container - transparent
                  Column(
                    children: [
                      Text(
                        'Mocha Point',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: const Color(0xFF472A19), // Dark espresso
                          fontFamily: 'ClashDisplay',
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your daily dose of Happiness',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFA6623A), // Coffee bean color
                          fontSize: 16,
                        ),
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
}

// Clean two-layer coffee liquid painter with bigger offset and same wave pattern
class CoffeeLiquidPainter extends CustomPainter {
  final double wavePhase;

  // Your original coffee colors
  static const Color frothColor = Color(0xFFA6623A); // Light brown froth (coffee bean)
  static const Color darkEspresso = Color(0xFF472A19); // Dark espresso
  static const Color creamBackground = Color(0xFFF9F5F1);

  CoffeeLiquidPainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    // Background - cream
    final bgPaint = Paint()..color = creamBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // LAYER 1: Light brown froth layer (painted first, bottom z-index)
    // This fills more area and is visible above the espresso
    final frothLevel = size.height * 0.15; // Starts at 15% from top (higher up)
    final frothPath = Path();
    frothPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 3) {
      final distanceFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final amplitude = 12 * (1 - distanceFromCenter * 0.3);

      // Same "random" wave pattern
      final wave1 = math.sin((x / size.width) * 3 * math.pi + wavePhase) * amplitude;
      final wave2 = math.sin((x / size.width) * 5 * math.pi - wavePhase * 0.7) * (amplitude * 0.5);

      final y = frothLevel + wave1 + wave2;
      frothPath.lineTo(x, y.clamp(0, size.height));
    }

    frothPath.lineTo(size.width, size.height);
    frothPath.close();

    final frothPaint = Paint()
      ..color = frothColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(frothPath, frothPaint);

    // LAYER 2: Dark espresso layer (painted last, top z-index)
    // Bigger offset - starts much lower to show more froth
    final espressoLevel = size.height * 0.45; // Starts at 45% from top (much lower)
    final espressoPath = Path();
    espressoPath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 3) {
      final distanceFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final amplitude = 12 * (1 - distanceFromCenter * 0.3);

      // SAME "random" wave pattern as froth
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
  bool shouldRepaint(CoffeeLiquidPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase;
  }
}
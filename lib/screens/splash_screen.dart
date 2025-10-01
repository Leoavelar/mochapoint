// lib/screens/splash_screen.dart - NO LOADING INDICATOR
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

    // Wave animation controller - slower (5 seconds instead of 3)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
          // Animated espresso waves background
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: EspressoWavesPainter(
                  waveAnimation: _waveController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Content on top of waves
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated coffee bean icon
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
                  const SizedBox(height: 24),
                  Text(
                    'Mocha Point',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.black,
                      fontFamily: 'Mocha',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your daily dose of Happiness',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  // Loading indicator removed - clean splash screen!
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for animated espresso waves
class EspressoWavesPainter extends CustomPainter {
  final double waveAnimation;

  EspressoWavesPainter({required this.waveAnimation});

  @override
  void paint(Canvas canvas, Size size) {
    // Background color (cream)
    final bgPaint = Paint()..color = const Color(0xFFF9F5F1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // PAINT FROTH FIRST (bottom z-index) - Coffee bean color (#A6623A)
    final frothPath = Path();
    frothPath.moveTo(0, size.height);
    frothPath.lineTo(0, size.height * 0.70);

    // Animated wave for froth layer
    for (double i = 0; i <= size.width; i++) {
      frothPath.lineTo(
          i,
          size.height * 0.70 +
              math.sin((i / size.width * 2 * math.pi) + (waveAnimation * 2.5 * math.pi) + 1.5) * 20
      );
    }

    frothPath.lineTo(size.width, size.height);
    frothPath.close();

    final frothPaint = Paint()
      ..color = const Color(0xFFA6623A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(frothPath, frothPaint);

    // PAINT DARK ESPRESSO LAST (top z-index) - #472A19
    final darkPath = Path();
    darkPath.moveTo(0, size.height);
    darkPath.lineTo(0, size.height * 0.77);

    // Animated wave for dark layer
    for (double i = 0; i <= size.width; i++) {
      darkPath.lineTo(
          i,
          size.height * 0.77 +
              math.sin((i / size.width * 2 * math.pi) + (waveAnimation * 2 * math.pi)) * 15
      );
    }

    darkPath.lineTo(size.width, size.height);
    darkPath.close();

    final darkPaint = Paint()
      ..color = const Color(0xFF472A19)
      ..style = PaintingStyle.fill;
    canvas.drawPath(darkPath, darkPaint);
  }

  @override
  bool shouldRepaint(EspressoWavesPainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation;
  }
}
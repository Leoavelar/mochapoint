// lib/screens/splash_screen.dart - Simplified with App Header Style Wave
import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import 'dart:math' as math;

import '../config/app_typography.dart';

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
    )..repeat(reverse: true);

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
      body: Container(
        color: Colors.white, // Pure white background
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated coffee bean icon - OUTSIDE header
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
                // Title - OUTSIDE header
                Text(
                  'Mochapoint',
                  style: AppTypography.statsNumber.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle - OUTSIDE header
                Text(
                  'Your daily dose of Happiness',
                  style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MyApp.coffeeBean
                  ),
                ),
                const SizedBox(height: 32),
                // Wave header - NOW TALLER with just the wave
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                    bottomLeft: Radius.circular(100.0),
                    bottomRight: Radius.circular(100.0),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 250, // Increased from 80 to 200
                    child: Stack(
                      children: [
                        // White background
                        Positioned.fill(
                          child: Container(
                            color: Colors.white,
                          ),
                        ),
                        // Dark gradient overlay (same as app header)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  MyApp.coffeeBean.withOpacity(0.15),
                                  MyApp.coffeeBean.withOpacity(0.15),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Wave animation filling the header
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: SplashWavePainter(
                                  wavePhase: _waveController.value * 2 * math.pi,
                                ),
                                size: Size.infinite,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// Simplified wave painter - inspired by app header
class SplashWavePainter extends CustomPainter {
  final double wavePhase;

  // Coffee colors from app header
  static const Color coffeeColor = Color(0xFF94511A); // Medium brown

  SplashWavePainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final waveLevel = size.height * 0.30; // Start wave at 40% for taller container
    final wavePath = Path();
    wavePath.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 3) {
      final distanceFromCenter = (x - size.width / 2).abs() / (size.width / 2);
      final amplitude = 8 * (1 - distanceFromCenter * 0.1);

      // Wave pattern (same as app header)
      final wave1 = math.sin((x / size.width) * 3 * math.pi + wavePhase) * amplitude;
      final wave2 = math.sin((x / size.width) * 5 * math.pi - wavePhase * 0.7) * (amplitude * 0.5);

      final y = waveLevel + wave1 + wave2;
      wavePath.lineTo(x, y.clamp(0, size.height));
    }

    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          coffeeColor,
          MyApp.coffeeBean,
          MyApp.coffeeBean,
          Colors.black,
          Colors.black,
        ],
      ).createShader(Rect.fromLTWH(0, waveLevel, size.width, size.height - waveLevel))
      ..style = PaintingStyle.fill;

    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(SplashWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase;
  }
}
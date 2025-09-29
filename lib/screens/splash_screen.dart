// lib/screens/splash_screen.dart - SUBTLE SMOOTH BOUNCE
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;

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
      // Drop down from above (0% to 40%)
      TweenSequenceItem(
        tween: Tween<double>(begin: -50.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      // Stay on ground during squash (40% to 48%)
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 8,
      ),
      // Bounce back up (48% to 68%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -15.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      // Settle back down to final position (68% to 100%)
      TweenSequenceItem(
        tween: Tween<double>(begin: -15.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 32,
      ),
    ]).animate(_bounceController);

    // Squash animation (vertical compression) - REDUCED intensity
    _squashAnimation = TweenSequence<double>([
      // Normal during drop (0% to 38%)
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 38,
      ),
      // Subtle squash on impact (38% to 48%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85) // Was 0.75, now 0.85 (15% squash instead of 25%)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 10,
      ),
      // Smooth return to normal (48% to 60%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0) // Match the squash value
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      // Stay normal for rest of animation (60% to 100%)
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
    ]).animate(_bounceController);

    // Stretch animation (horizontal expansion) - REDUCED intensity
    _stretchAnimation = TweenSequence<double>([
      // Normal during drop (0% to 38%)
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 38,
      ),
      // Subtle stretch on impact (38% to 48%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15) // Was 1.25, now 1.15 (15% stretch instead of 25%)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 10,
      ),
      // Smooth return to normal (48% to 60%)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0) // Match the stretch value
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      // Stay normal for rest of animation (60% to 100%)
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
    ]).animate(_bounceController);

    // Start animations sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start fade in
    _fadeController.forward();

    // Wait a moment, then start bounce
    await Future.delayed(const Duration(milliseconds: 200));
    _bounceController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F1),
      body: Center(
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
                      scaleX: _stretchAnimation.value, // Horizontal stretch
                      scaleY: _squashAnimation.value,  // Vertical squash
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
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA6623A)),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
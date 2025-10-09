// Path: lib/widgets/daily_coffee_card.dart
// ✅ REDESIGNED to match redemption modal subscription card style
// ✅ UPDATED with coffee gradient circular progress bar

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import '../services/subscription_service.dart';
import '../widgets/nearest_shops_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:async';

class DailyCoffeeCard extends StatefulWidget {
  final VoidCallback? onRedeem;

  const DailyCoffeeCard({
    super.key,
    this.onRedeem,
  });

  @override
  State<DailyCoffeeCard> createState() => _DailyCoffeeCardState();
}

enum SubscriptionState {
  loading,
  active,
  inactive
}

class _DailyCoffeeCardState extends State<DailyCoffeeCard>
    with TickerProviderStateMixin {
  // Coffee-themed colors matching redemption modal
  static const Color coffeeBrown = Color(0xFF8B4513);
  static const Color chocolate = Color(0xFFD2691E);
  static const Color coffeeGreen = Color(0xFF4CAF50);

  // ✨ ANIMATION CONFIGURATION - Easy to adjust!
  static const int flipIntervalSeconds = 5;  // Time between flips
  static const int numberOfFlips = 1;        // Number of complete rotations (1 = 360°, 2 = 720°, etc.)
  static const int flipDurationMs = 1600;     // Duration of flip animation in milliseconds

  bool isAvailableToday = true;
  int availableCoffees = 1;
  UserSubscriptionData? _subscriptionData;
  bool _isLoadingSubscription = true;
  CoffeeShop? _selectedShop;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  Timer? _countdownTimer;
  Timer? _flipTimer;

  SubscriptionState get _subscriptionState {
    if (_isLoadingSubscription) return SubscriptionState.loading;
    if (_subscriptionData?.hasActiveSubscription == true) return SubscriptionState.active;
    return SubscriptionState.inactive;
  }

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Flip animation controller
    _flipController = AnimationController(
      duration: Duration(milliseconds: flipDurationMs),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    ));

    _progressController.forward();
    _startCountdownTimer();
    _startFlipTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startFlipTimer() {
    // Start first flip after initial delay (40% of interval)
    final initialDelay = (flipIntervalSeconds * 0.4).round();
    Future.delayed(Duration(seconds: initialDelay), () {
      if (mounted) {
        _flipController.forward(from: 0.0);
      }
    });

    _flipTimer = Timer.periodic(Duration(seconds: flipIntervalSeconds), (timer) {
      if (mounted) {
        _flipController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _flipController.dispose();
    _countdownTimer?.cancel();
    _flipTimer?.cancel();
    super.dispose();
  }

  double _getProgressToMidnight() {
    final now = DateTime.now();
    final totalSecondsInDay = 24 * 60 * 60;
    final secondsSinceMidnight = now.hour * 3600 + now.minute * 60 + now.second;
    return secondsSinceMidnight / totalSecondsInDay;
  }

  String _getTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final difference = midnight.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  bool _isCoffeeReady() {
    return isAvailableToday;
  }

  Future<void> _launchSubscriptionWebsite() async {
    const url = 'https://mochapoint.coffee/';

    try {
      final uri = Uri.parse(url);
      bool launched = false;

      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('External app launch failed: $e');
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        } catch (e) {
          print('External non-browser launch failed: $e');
        }
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri);
        } catch (e) {
          print('Platform default launch failed: $e');
        }
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open browser. Please visit mochapoint.coffee manually.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } catch (e) {
      print('URL launch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please visit mochapoint.coffee in your browser'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    }
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final subscriptionData = await SubscriptionService.getUserSubscription();

      if (mounted) {
        setState(() {
          _subscriptionData = subscriptionData;
          _isLoadingSubscription = false;
        });

        if (subscriptionData?.accessibleShops.isNotEmpty == true) {
          final firstShop = subscriptionData!.accessibleShops.first;

          try {
            final shopData = await ApiService.getCoffeeShops();
            final shops = shopData['shops'] as List<CoffeeShop>;
            final fullShopData = shops.where((shop) => shop.id == firstShop.id).firstOrNull;

            if (mounted) {
              setState(() {
                if (fullShopData != null) {
                  _selectedShop = fullShopData;
                } else {
                  _selectedShop = CoffeeShop(
                    id: firstShop.id,
                    name: firstShop.name,
                    address: firstShop.address,
                    latitude: firstShop.latitude ?? 0.0,
                    longitude: firstShop.longitude ?? 0.0,
                    subscriptionEnabled: true,
                    jokerEnabled: true,
                    userAverageRating: 0.0,
                    userRatingCount: 0,
                    googleRating: 0.0,
                    googleRatingCount: 0,
                    supportedDrinkTiers: [],
                    isActive: true,
                    logoUrl: null,
                  );
                }
              });
            }
          } catch (e) {
            print('Error fetching full shop data: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subscriptionData = null;
          _isLoadingSubscription = false;
        });
      }
      print('Error loading subscription data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_subscriptionState) {
      case SubscriptionState.loading:
        return _buildLoadingView(context);
      case SubscriptionState.active:
        return _buildAvailableView(context);
      case SubscriptionState.inactive:
        return _buildNoSubscriptionView(context);
    }
  }

  Widget _buildLoadingView(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(coffeeBrown),
          ),
          SizedBox(height: 12),
          Text('Loading your coffee...'),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header section - matches redemption modal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [coffeeBrown, chocolate],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_cafe_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Start Your Coffee Journey!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // White section - benefits and CTA
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscribe to enjoy daily free coffee',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Benefits container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: coffeeBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '☕ What you\'ll get:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: coffeeBrown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBenefitRow('🎯', 'Daily free coffee at your favorite shops'),
                      _buildBenefitRow('⚡', 'Skip the line with QR redemption'),
                      _buildBenefitRow('🌟', 'Access to premium coffee selections'),
                      _buildBenefitRow('📍', 'Multiple locations across your city'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _launchSubscriptionWebsite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: coffeeBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.coffee, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Explore Subscriptions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 14),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'Choose from our partner coffee shops in your city',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableView(BuildContext context) {
    final bool coffeeReady = _isCoffeeReady();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header section - ALWAYS coffee brown gradient (like subscription card)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [coffeeBrown, chocolate],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedShop?.name ?? 'Your Coffee Shop',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // White section - status with circular progress
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Left side - Text info
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coffeeReady) ...[
                        // Ready status - two lines with different colors
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Your Coffee is\n',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 1.2,
                                  fontFamily: "ClashDisplay",
                                ),
                              ),
                              TextSpan(
                                text: 'Ready!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: coffeeGreen,
                                  height: 1.2,
                                  fontFamily: "ClashDisplay",
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Redeem your free coffee now',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ] else ...[
                        // Countdown status
                        Text(
                          _getTimeUntilMidnight(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontFamily: "ClashDisplay",
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Until next free coffee',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // Right side - Circular progress with gradient
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      // Background circle
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                        ),
                      ),

                      // Animated progress circle with gradient
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(80, 80),
                            painter: CircularProgressPainter(
                              progress: coffeeReady ? 1.0 : _getProgressToMidnight(),
                              backgroundColor: Colors.grey.shade200,
                              progressColor: coffeeReady ? coffeeGreen : coffeeBrown,
                              strokeWidth: 6,
                            ),
                          );
                        },
                      ),

                      // Center icon/logo with flip animation
                      Center(
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            // Calculate rotation angle based on number of flips
                            // numberOfFlips = 1: 360°, numberOfFlips = 2: 720°, etc.
                            final angle = _flipAnimation.value * numberOfFlips * 2 * math.pi;

                            // Calculate scale effect (shrink during middle of flip)
                            final scale = 1.0 - (math.sin(_flipAnimation.value * math.pi) * 0.15);

                            // Apply 3D perspective transform with scale (Y-axis rotation)
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002) // stronger perspective
                                ..rotateY(angle)  // Changed from rotateX to rotateY
                                ..scale(scale),
                              child: GestureDetector(
                                onTap: () {
                                  // Debug mode: toggle between available and countdown states
                                  print('Tapped! Current state: $isAvailableToday');
                                  setState(() {
                                    isAvailableToday = !isAvailableToday;
                                  });
                                  // Also trigger flip animation on tap
                                  _flipController.forward(from: 0.0);
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: coffeeReady ? coffeeGreen : Colors.grey.shade300,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _selectedShop?.logoUrl != null
                                        ? Padding(
                                      padding: const EdgeInsets.all(0),
                                      child: Image.asset(
                                        'assets/images/shops/${_selectedShop!.logoUrl}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            coffeeReady ? Icons.local_cafe : Icons.access_time,
                                            color: Colors.white,
                                            size: 24,
                                          );
                                        },
                                      ),
                                    )
                                        : Icon(
                                      coffeeReady ? Icons.local_cafe : Icons.access_time,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

// Custom painter for the circular progress bar with coffee gradient
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc with uniform color
    final sweepAngle = 2 * math.pi * progress;

    // Use chocolate (lighter tone) for countdown, green for ready
    final Color arcColor = progressColor == const Color(0xFF4CAF50)
        ? const Color(0xFF4CAF50) // coffeeGreen when ready
        : const Color(0xFFD2691E); // chocolate (lighter) for countdown

    final progressPaint = Paint()
      ..color = arcColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
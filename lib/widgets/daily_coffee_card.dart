// lib/widgets/daily_coffee_card.dart
// ✅ SYNCED with actual redemption status from backend
// ✅ Updates automatically after redemptions
// ✅ FIXED: Consistent width with other cards

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import '../services/subscription_service.dart';
import '../services/redemption_service.dart';
import '../widgets/nearest_shops_widget.dart';
import '../config/app_config.dart';
import '../config/app_typography.dart';
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
  State<DailyCoffeeCard> createState() => DailyCoffeeCardState();
}

enum SubscriptionState {
  loading,
  active,
  inactive
}

class DailyCoffeeCardState extends State<DailyCoffeeCard>
    with TickerProviderStateMixin {
  // Coffee-themed colors matching redemption modal
  static const Color coffeeBrown = Color(0xFF000000);
  static const Color chocolate = Color(0xFFD2691E);
  static const Color coffeeGreen = Color(0xFF4CAF50);

  // ✨ ANIMATION CONFIGURATION
  static const int flipIntervalSeconds = 5;
  static const int numberOfFlips = 1;
  static const int flipDurationMs = 1600;

  // ✅ NEW: Track actual redemption status from backend
  bool isAvailableToday = true;
  bool _isLoadingRedemptionStatus = true;
  DateTime? _lastRedemptionToday;

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
    if (_isLoadingSubscription || _isLoadingRedemptionStatus) {
      return SubscriptionState.loading;
    }
    if (_subscriptionData?.hasActiveSubscription == true) {
      return SubscriptionState.active;
    }
    return SubscriptionState.inactive;
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();

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

  // ✅ NEW: Public method to refresh from parent
  void refresh() {
    if (mounted) {
      if (AppConfig.enableLogging) {
        print('🔄 DailyCoffeeCard: Refresh triggered');
      }
      _loadAllData();
    }
  }

  // ✅ NEW: Load both subscription and redemption status
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadSubscriptionData(),
      _loadRedemptionStatus(),
    ]);
  }

  Future<void> _loadRedemptionStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRedemptionStatus = true;
    });

    try {
      if (AppConfig.enableLogging) {
        print('🔍 DailyCoffeeCard: Loading redemption status');
      }

      final statusResult = await RedemptionService.getRedemptionStatus();

      if (statusResult['success'] == true) {
        // Access nested status object correctly
        final status = statusResult['status'];

        // ✅ FIXED: Access canRedeemSubscription from top level, not nested in subscriptionInfo
        final canRedeemSubscription = status['canRedeemSubscription'] ?? true;

        // Coffee is available if subscription CAN be redeemed
        final hasRedeemedToday = !canRedeemSubscription;

        if (AppConfig.enableLogging) {
          print('📊 DailyCoffeeCard: canRedeemSubscription = $canRedeemSubscription');
          print('📊 DailyCoffeeCard: Total today redemptions = ${status['todayRedemptions']}');
          print('☕ DailyCoffeeCard: Subscription coffee ${hasRedeemedToday ? "NOT" : "IS"} available');
        }

        if (mounted) {
          setState(() {
            isAvailableToday = !hasRedeemedToday;
            _lastRedemptionToday = hasRedeemedToday ? DateTime.now() : null;
            _isLoadingRedemptionStatus = false;
          });
        }
      } else {
        if (AppConfig.enableLogging) {
          print('⚠️ DailyCoffeeCard: Failed to load redemption status');
        }

        if (mounted) {
          setState(() {
            isAvailableToday = true; // Default to available on error
            _isLoadingRedemptionStatus = false;
          });
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ DailyCoffeeCard: Error loading redemption status: $e');
      }

      if (mounted) {
        setState(() {
          isAvailableToday = true; // Default to available on error
          _isLoadingRedemptionStatus = false;
        });
      }
    }
  }

  Future<void> _loadSubscriptionData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSubscription = true;
    });

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
                  );
                }
              });
            }
          } catch (e) {
            if (AppConfig.enableLogging) {
              print('Error loading full shop data: $e');
            }
          }
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Error loading subscription data: $e');
      }

      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startFlipTimer() {
    _flipTimer?.cancel();
    _flipTimer = Timer.periodic(const Duration(seconds: flipIntervalSeconds), (timer) {
      if (mounted) {
        _flipController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _flipTimer?.cancel();
    _progressController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  bool _isCoffeeReady() {
    return _subscriptionState == SubscriptionState.active && isAvailableToday;
  }

  String _getTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final duration = midnight.difference(now);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _getProgressToMidnight() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day + 1);

    final totalSeconds = endOfDay.difference(startOfDay).inSeconds;
    final elapsedSeconds = now.difference(startOfDay).inSeconds;

    return elapsedSeconds / totalSeconds;
  }

  Future<void> _launchSubscriptionWebsite() async {
    final url = Uri.parse('https://mochapoint.coffee');

    try {
      final canLaunch = await canLaunchUrl(url);

      if (canLaunch) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Error launching URL: $e');
      }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // ✅ FIXED: Ensure full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [coffeeBrown, chocolate],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
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

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: coffeeBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedShop?.name ?? 'Your Coffee Shop',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coffeeReady) ...[
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Your Coffee is\n',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  height: 1.2,
                                  fontFamily: "Poppins",
                                ),
                              ),
                              TextSpan(
                                text: 'Ready!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: MyApp.coffeeBean,
                                  height: 1.2,
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Redeem your free coffee now',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Brewing...',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: MyApp.coffeeBean
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeUntilMidnight(),
                          style: AppTypography.statsNumber.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Until next free coffee',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                        ),
                      ),

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

                      Center(
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle = _flipAnimation.value * numberOfFlips * 2 * math.pi;
                            final scale = 1.0 - (math.sin(_flipAnimation.value * math.pi) * 0.15);

                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002)
                                ..rotateY(angle)
                                ..scale(scale),
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

// Custom painter for the circular progress bar
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

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * math.pi * progress;

    final Color arcColor = progressColor == const Color(0xFF4CAF50)
        ? const Color(0xFF4CAF50)
        : MyApp.coffeeBean;

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
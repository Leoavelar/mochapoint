// lib/widgets/daily_coffee_card.dart
import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import '../services/subscription_service.dart';
import '../services/redemption_service.dart';
import '../widgets/nearest_shops_widget.dart';
import '../widgets/coffee_ready_background.dart';
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

enum SubscriptionState { loading, active, inactive }

class DailyCoffeeCardState extends State<DailyCoffeeCard>
    with TickerProviderStateMixin {
  static const Color coffeeBrown = Color(0xFF000000);
  static const Color chocolate = Color(0xFFD2691E);
  static const Color coffeeGreen = Color(0xFF4CAF50);

  static const int flipIntervalSeconds = 5;
  static const int numberOfFlips = 1;
  static const int flipDurationMs = 1600;

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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressController.forward();
    _startCountdownTimer();
    _startFlipTimer();
  }

  void refresh() {
    if (mounted) {
      if (AppConfig.enableLogging) {
        print('🔄 DailyCoffeeCard: Refresh triggered');
      }
      _loadAllData();
    }
  }

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
        final status = statusResult['status'];

        final canRedeemSubscription = status['canRedeemSubscription'] ?? true;

        final hasRedeemedToday = !canRedeemSubscription;

        if (AppConfig.enableLogging) {
          print(
              '📊 DailyCoffeeCard: canRedeemSubscription = $canRedeemSubscription');
          print(
              '📊 DailyCoffeeCard: Total today redemptions = ${status['todayRedemptions']}');
          print(
              '☕ DailyCoffeeCard: Subscription coffee ${hasRedeemedToday ? "NOT" : "IS"} available');
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
            isAvailableToday = true;
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
          isAvailableToday = true;
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
            final fullShopData =
                shops.where((shop) => shop.id == firstShop.id).firstOrNull;

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
    _flipTimer =
        Timer.periodic(const Duration(seconds: flipIntervalSeconds), (timer) {
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
    _pulseController.dispose();
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
            content:
            const Text('Please visit mochapoint.coffee in your browser'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
    return CoffeeReadyBackground(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              'Loading your coffee...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSubscriptionView(BuildContext context) {
    return CoffeeReadyBackground(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start your',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Coffee Journey!',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subscribe to enjoy daily free coffee',
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white60)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What you\'ll get:',
                          style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        _buildBenefitRow(
                            '', 'Daily free coffee at your favorite shops'),
                        const SizedBox(height: 4),
                        _buildBenefitRow('',
                            'Collect beans and get free coffees in participating shops'),
                        const SizedBox(height: 4),
                        _buildBenefitRow(
                            '', 'Fast coffee redemption with QR Code'),
                        const SizedBox(height: 4),
                        _buildBenefitRow(
                            '', 'Access to premium coffee selections'),
                        const SizedBox(height: 4),
                        _buildBenefitRow(
                            '', 'Multiple locations across your city'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                        colors: [
                          MyApp.coffeeFroth,
                          MyApp.coffeeBean,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _launchSubscriptionWebsite,
                        borderRadius: BorderRadius.circular(50),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.coffee, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Explore Subscriptions',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Choose from our partner coffee shops in your city',
                      style: AppTypography.bodyMedium
                          .copyWith(color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 16, color: Colors.white70),
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // In daily_coffee_card.dart, update the _buildAvailableView method:

  Widget _buildAvailableView(BuildContext context) {
    final bool coffeeReady = _isCoffeeReady();

    return CoffeeReadyBackground(
      // Don't specify height - let it size dynamically based on content
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Important: Use min to fit content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR CODE READY status badge
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: coffeeReady ? MyApp.coffeeGreen : Colors.orange,
                    boxShadow: coffeeReady
                        ? [
                      BoxShadow(
                        color: MyApp.coffeeGreen.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  coffeeReady ? 'QR CODE READY' : 'BREWING',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Center content
            if (coffeeReady) ...[
              // Circular progress indicator with logo (centered)
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      // Pulse animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: MyApp.coffeeAccent
                                      .withOpacity(_pulseAnimation.value),
                                  blurRadius: 60,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Background circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // Progress circle
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(120, 120),
                            painter: CircularProgressPainter(
                              progress: 1.0,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              gradientColors: [
                                MyApp.coffeeAccent,
                                MyApp.coffeeAccent
                              ],
                              strokeWidth: 8,
                            ),
                          );
                        },
                      ),
                      // Logo with flip animation
                      Center(
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle = _flipAnimation.value *
                                numberOfFlips *
                                2 *
                                math.pi;
                            final scale = 1.0 -
                                (math.sin(_flipAnimation.value * math.pi) *
                                    0.15);

                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002)
                                ..rotateY(angle)
                                ..scale(scale),
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 15,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _selectedShop?.logoUrl != null
                                      ? Image.asset(
                                    'assets/images/shops/${_selectedShop!.logoUrl}',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.local_cafe,
                                        color: Colors.white,
                                        size: 36,
                                      );
                                    },
                                  )
                                      : const Icon(
                                    Icons.local_cafe,
                                    color: Colors.white,
                                    size: 36,
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
              ),

              const SizedBox(height: 24),

              // "YOUR ORDER IS" text
              Center(
                child: Text(
                  'YOUR ORDER IS',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // "[Ready]" text
              Center(
                child: Text(
                  '[Ready]',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0,
                    height: 1.0,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Shop location info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: MyApp.coffeeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedShop?.name ?? 'Your Coffee Shop',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedShop?.distance != null)
                            Text(
                              '${(_selectedShop!.distance! * 1000).toStringAsFixed(0)}m • ${(_selectedShop!.distance! * 12).toStringAsFixed(0)} min walk',
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.4),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Not ready state - show countdown
              Column(
                mainAxisSize: MainAxisSize.min, // Important: Use min to fit content
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brewing...',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTimeUntilMidnight(),
                    style: AppTypography.statsNumber.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Until next free coffee',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Progress bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _getProgressToMidnight(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [MyApp.coffeeAccent, MyApp.coffeeFroth],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color? progressColor;
  final List<Color>? gradientColors;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    this.progressColor,
    this.gradientColors,
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

    final progressPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (gradientColors != null && gradientColors!.length >= 2) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      progressPaint.shader = SweepGradient(
        colors: gradientColors!,
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
      ).createShader(rect);
    } else if (progressColor != null) {
      progressPaint.color = progressColor!;
    }

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
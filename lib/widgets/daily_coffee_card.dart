// Path: lib/widgets/daily_coffee_card.dart

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

// Define enum outside the class to avoid scope issues
enum SubscriptionState {
  loading,
  active,
  inactive
}

class _DailyCoffeeCardState extends State<DailyCoffeeCard>
    with TickerProviderStateMixin {
  bool isAvailableToday = true;
  int availableCoffees = 1;
  UserSubscriptionData? _subscriptionData;
  bool _isLoadingSubscription = true;
  CoffeeShop? _selectedShop;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _countdownTimer;

  SubscriptionState get _subscriptionState {
    if (_isLoadingSubscription) return SubscriptionState.loading;
    if (_subscriptionData?.hasActiveSubscription == true) return SubscriptionState.active;
    return SubscriptionState.inactive;
  }

  void _toggleAvailability() {
    setState(() {
      if (availableCoffees == 0) {
        availableCoffees = 1;
      } else {
        availableCoffees = 0;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();

    // Initialize animation controller for progress bar
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

    _progressController.forward();

    // Start timer to update countdown every second
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild every second to update the countdown
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  double _getProgressToMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
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
    const url = 'https://mochapoint.coffee/'; // Replace with your actual subscription URL

    try {
      final uri = Uri.parse(url);

      // Try different launch modes in order of preference
      bool launched = false;

      // First try external application (default browser)
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('External app launch failed: $e');
      }

      // If external app fails, try external non-browser mode
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (e) {
          print('External non-browser launch failed: $e');
        }
      }

      // If both fail, try platform default
      if (!launched) {
        try {
          launched = await launchUrl(uri);
        } catch (e) {
          print('Platform default launch failed: $e');
        }
      }

      // If all methods fail, show error
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open browser. Please visit mochapoint.coffee manually.'),
            backgroundColor: Colors.orange.shade700,
            action: SnackBarAction(
              label: 'Copy URL',
              textColor: Colors.white,
              onPressed: () {
                // You can add clipboard functionality here if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visit: mochapoint.coffee/subscribe'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ),
        );
      } else if (launched) {
        // Success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Opening subscription page...'),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

    } catch (e) {
      print('URL launch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please visit mochapoint.coffee/subscribe in your browser'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
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

        // Get the first accessible shop as the selected one and fetch its full details
        if (subscriptionData?.accessibleShops.isNotEmpty == true) {
          final firstShop = subscriptionData!.accessibleShops.first;

          try {
            // Fetch full shop data to get logos
            final shopData = await ApiService.getCoffeeShops();
            final shops = shopData['shops'] as List<CoffeeShop>;

            // Find the matching shop by ID
            final fullShopData = shops.where((shop) => shop.id == firstShop.id).firstOrNull;

            if (mounted) {
              setState(() {
                if (fullShopData != null) {
                  _selectedShop = fullShopData;
                } else {
                  // Fallback to basic shop data without logo
                  _selectedShop = CoffeeShop(
                    id: firstShop.id,
                    name: firstShop.name,
                    address: firstShop.address,
                    latitude: firstShop.latitude ?? 0.0,
                    longitude: firstShop.longitude ?? 0.0,
                    subscriptionEnabled: true,
                    jokerEnabled: true,
                    userAverageRating: 0.0,
                    googleRating: 0.0,
                    supportedDrinkTiers: [],
                    isActive: true,
                    logoUrl: null,
                  );
                }
              });
            }
          } catch (e) {
            print('Error fetching full shop data: $e');
            // Fallback to basic shop data
            if (mounted) {
              setState(() {
                _selectedShop = CoffeeShop(
                  id: firstShop.id,
                  name: firstShop.name,
                  address: firstShop.address,
                  latitude: firstShop.latitude ?? 0.0,
                  longitude: firstShop.longitude ?? 0.0,
                  subscriptionEnabled: true,
                  jokerEnabled: true,
                  userAverageRating: 0.0,
                  googleRating: 0.0,
                  supportedDrinkTiers: [],
                  isActive: true,
                  logoUrl: null,
                );
              });
            }
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
    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
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
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Loading subscription status...'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoSubscriptionView(BuildContext context) {
    const coffeeGradient = LinearGradient(
      colors: [Color(0xFF8B4513), Color(0xFFD2B48C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with coffee icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align to top
          children: [
            Image.asset(
              'assets/icons/mocha_icon_active.png',
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to original icon if image fails to load
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: coffeeGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_cafe,
                    color: Colors.white,
                    size: 20,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Your Coffee Journey!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: "ClashDisplay",
                    ),
                  ),
                  Text(
                    'Subscribe to enjoy daily free coffee',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Benefits list
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MyApp.coffeeBean.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '☕ What you\'ll get:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MyApp.coffeeBean,
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
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.coffee, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Explore Coffee Subscriptions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: "ClashDisplay",
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Subtitle
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
    const coffeeGreen = Color(0xFF4CAF50);
    final bool coffeeReady = _isCoffeeReady();
    final progressValue = coffeeReady ? 1.0 : _getProgressToMidnight();

    return Row(
      children: [
        // Left side - Text and shop info
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main counter or ready text
              if (coffeeReady) ...[
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Your Coffee is ',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.1,
                            fontFamily: "ClashDisplay"
                        ),
                      ),
                      TextSpan(
                        text: 'Ready!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontFamily: "ClashDisplay",
                          color: Color(0xFF4CAF50),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Redeem your free coffee now',
                  style:Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

                // Neutral separator line
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Countdown display (same style as "ready" state)
                Text(
                  _getTimeUntilMidnight(),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.1,
                      fontFamily: "ClashDisplay"
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Until next free coffee',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

                // Neutral separator line (same as ready state)
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
              ],

              // Shop info
              if (_selectedShop != null) ...[
                Text(
                  _selectedShop!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: "ClashDisplay",
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Right side - Circular progress
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

              // Animated progress circle
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(80, 80),
                    painter: CircularProgressPainter(
                      progress: coffeeReady ? 1.0 : _getProgressToMidnight(),
                      backgroundColor: Colors.grey.shade200,
                      progressColor: coffeeReady ? coffeeGreen : MyApp.coffeeBean,
                      strokeWidth: 6,
                    ),
                  );
                },
              ),

              // Center icon/logo with tap functionality
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Debug mode: toggle between available and redeemed states
                    print('Tapped! Current state: $isAvailableToday');
                    setState(() {
                      isAvailableToday = !isAvailableToday;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: coffeeReady ? coffeeGreen : Colors.grey.shade300,
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRedeemedView(BuildContext context) {
    const coffeeBean = MyApp.coffeeBean;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: coffeeBean,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Coffee Break Enjoyed!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: coffeeBean,
                  ),
                ),
              ],
            ),
            if (availableCoffees > 0)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.coffee,
                      color: Colors.grey.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      availableCoffees.toString(),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Hope you enjoyed your coffee today! Your next free coffee will be available tomorrow. Until then, keep collecting those coffee points!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'New Coffee Tomorrow',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
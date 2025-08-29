// Path: lib/widgets/daily_coffee_card.dart

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import '../services/subscription_service.dart';

// Add this class to handle shop data
class CoffeeShop {
  final int id;
  final String name;
  final String? brand;
  final String address;
  final double latitude;
  final double longitude;
  final String? logoUrl;

  CoffeeShop({
    required this.id,
    required this.name,
    this.brand,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.logoUrl,
  });

  factory CoffeeShop.fromJson(Map<String, dynamic> json) {
    return CoffeeShop(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      logoUrl: json['logoFilename'],
    );
  }
}

class DailyCoffeeCard extends StatefulWidget {
  final VoidCallback? onRedeem;

  const DailyCoffeeCard({
    Key? key,
    this.onRedeem,
  }) : super(key: key);

  @override
  State<DailyCoffeeCard> createState() => _DailyCoffeeCardState();
}

class _DailyCoffeeCardState extends State<DailyCoffeeCard> {
  bool isAvailableToday = true;
  int availableCoffees = 1;
  UserSubscriptionData? _subscriptionData;
  bool _isLoadingSubscription = true;
  CoffeeShop? _selectedShop; // Add shop data

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
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final subscriptionData = await SubscriptionService.getUserSubscription();

      if (mounted) {
        setState(() {
          _subscriptionData = subscriptionData;
          _isLoadingSubscription = false;

          // Get the first accessible shop as the selected one
          if (subscriptionData?.accessibleShops.isNotEmpty == true) {
            final firstShop = subscriptionData!.accessibleShops.first;
            _selectedShop = CoffeeShop(
              id: firstShop.id,
              name: firstShop.name,
              address: '',
              // You might need to add this to AccessibleShop
              latitude: 0.0,
              longitude: 0.0,
              logoUrl:
                  null, // AccessibleShop doesn't have logoUrl, we'll handle this differently
            );
          }
        });
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: isAvailableToday
            ? _buildAvailableView(context)
            : _buildRedeemedView(context),
      ),
    );
  }

  Widget _buildAvailableView(BuildContext context) {
    const coffeeGreen = Color(0xFF4CAF50);
    final bool hasCoffees = availableCoffees > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keep the original top section unchanged
        Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 5, right: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Icon(
                  //   hasCoffees ? Icons.local_cafe : Icons.coffee_maker_outlined,
                  //   color: MyApp.coffeeBean,
                  //   size: 24,
                  // ),
                  const SizedBox(width: 8),
                  // Dynamic title based on coffee availability
                  hasCoffees
                      ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Your Coffee is ',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: 'Ready!',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: coffeeGreen,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Text(
                    'Coffee Coming Soon',
                    style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              // Coffee count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasCoffees ? coffeeGreen : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_cafe,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      availableCoffees.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // New container section with background image (matching the design)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            image: const DecorationImage(
              image: AssetImage('assets/images/header_2.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(1.0),
                  Colors.black.withOpacity(0.0),
                ],
              ),
            ),
            padding: const EdgeInsets.all(10),
            // Remove extra padding since parent already has it
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main message
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Head to ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            fontFamily: 'ClashDisplay'),
                      ),
                      TextSpan(
                        text:
                            _selectedShop?.name ?? 'your favorite coffee shop',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            fontFamily: 'ClashDisplay'),
                      ),
                      const TextSpan(
                        text: ' and redeem your free coffee!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            fontFamily: 'ClashDisplay'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bottom row with button and logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // View directions button
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Add functionality to open maps
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening directions - Coming soon!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Redeem Now',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),

                    // Shop logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: MyApp.coffeeBean,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _selectedShop?.logoUrl != null
                            ? Image.asset(
                                'assets/images/shops/${_selectedShop!.logoUrl}',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/shops/default_coffee_logo.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildFallbackLogo();
                                    },
                                  );
                                },
                              )
                            : _buildFallbackLogo(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: MyApp.coffeeBean,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.coffee,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildSubscriptionInfo() {
    if (_isLoadingSubscription) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MyApp.coffeeBean.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(MyApp.coffeeBean),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading subscription info...',
              style: TextStyle(
                color: MyApp.coffeeBean,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_subscriptionData?.hasActiveSubscription == true) {
      final subscription = _subscriptionData!.subscription!;
      final accessibleShops = _subscriptionData!.accessibleShops;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MyApp.coffeeBean.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MyApp.coffeeBean.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: MyApp.coffeeBean,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subscription.planName,
                    style: TextStyle(
                      color: MyApp.coffeeBean,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${subscription.usedThisWeek}/${subscription.weeklyLimit} this week',
                  style: TextStyle(
                    color: MyApp.coffeeBean,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (accessibleShops.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...accessibleShops.take(2).map((shop) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.store,
                          color: MyApp.coffeeBean,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            shop.name,
                            style: TextStyle(
                              color: MyApp.coffeeBean,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (accessibleShops.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${accessibleShops.length - 2} more shops',
                    style: TextStyle(
                      color: MyApp.coffeeBean,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    }

    // No active subscription
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No active subscription. Using jokers for redemptions.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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

// Path: lib/widgets/daily_coffee_card.dart

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import '../services/subscription_service.dart';

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
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.black, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isAvailableToday ? _buildAvailableView(context) : _buildRedeemedView(context),
      ),
    );
  }

  Widget _buildAvailableView(BuildContext context) {
    const coffeeGreen = Color(0xFF4CAF50);
    final bool hasCoffees = availableCoffees > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  hasCoffees ? Icons.local_cafe : Icons.coffee_maker_outlined,
                  color: MyApp.coffeeBean,
                  size: 24,
                ),
                const SizedBox(width: 8),
                // Dynamic title based on coffee availability
                hasCoffees
                    ? RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Your Coffee is ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: 'Ready!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: coffeeGreen,
                        ),
                      ),
                    ],
                  ),
                )
                    : Text(
                  'Coffee Coming Soon',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
        const SizedBox(height: 12),

        // Subscription Shop Information
        _buildSubscriptionInfo(),

        const SizedBox(height: 12),
        Text(
          _getAvailableMessage(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: () {
              _toggleAvailability();
              if (widget.onRedeem != null) {
                widget.onRedeem!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasCoffees ? Colors.white : Colors.grey.shade200,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                hasCoffees
                    ? Image.asset(
                  'assets/images/redeem.png',
                  width: 28,
                  height: 28,
                )
                    : Icon(
                  Icons.hourglass_empty,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  hasCoffees ? 'Redeem Now' : 'Wait for Refill',
                  style: TextStyle(
                    color: hasCoffees ? Colors.black : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  String _getAvailableMessage() {
    if (_subscriptionData?.hasActiveSubscription == true) {
      final subscription = _subscriptionData!.subscription!;
      final remaining = subscription.weeklyLimit - subscription.usedThisWeek;

      if (remaining <= 0) {
        return 'You\'ve used all your subscription coffees this week. Try again next week or use a joker!';
      } else if (remaining == 1) {
        return 'You have 1 subscription coffee remaining this week. Visit any of your subscribed coffee shops!';
      } else {
        return 'You have $remaining subscription coffees remaining this week. Visit any of your subscribed coffee shops!';
      }
    }

    // Fallback for no subscription
    if (availableCoffees <= 0) {
      return 'You\'ve redeemed all your coffees for today. Check back tomorrow for a fresh refill!';
    } else if (availableCoffees == 1) {
      return 'Time for a delicious coffee break! Head to your favorite coffee shop and redeem your free coffee today.';
    } else {
      return 'You have $availableCoffees coffees ready to redeem! Head to your favorite coffee shop and enjoy a well-deserved break today.';
    }
  }
}
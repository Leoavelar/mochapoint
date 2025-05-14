// Path: lib/widgets/daily_coffee_card.dart

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';

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
  bool isAvailableToday = true; // Default to true
  int availableCoffees = 1; // Default to 1 coffee available

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
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: isAvailableToday ? _buildAvailableView(context) : _buildRedeemedView(context),
      ),
    );
  }

  Widget _buildAvailableView(BuildContext context) {
    const coffeeGreen = Color(0xFF4CAF50);
    final bool hasCoffees = availableCoffees > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyApp.coffeeBean.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MyApp.coffeeBean.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
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
                            fontWeight: FontWeight.bold,
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
                  color: hasCoffees ? coffeeGreen : Colors.grey.shade400, // Gray if zero
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
                elevation: 0, // No shadow
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  // No border
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Larger image or hourglass icon
                  hasCoffees
                      ? Image.asset(
                    'assets/images/redeem.png',
                    width: 28, // Increased size
                    height: 28, // Increased size
                  )
                      : Icon(
                    Icons.hourglass_empty,
                    color: Colors.grey.shade600,
                    size: 24, // Increased size
                  ),
                  const SizedBox(width: 10), // Slightly increased spacing
                  Text(
                    hasCoffees ? 'Redeem Now' : 'Wait for Refill',
                    style: TextStyle(
                      color: hasCoffees ? Colors.black : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 15, // Slightly increased font size
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemedView(BuildContext context) {
    const coffeeBean = MyApp.coffeeBean;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
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
              // Only show remaining coffees if there are any
              if (availableCoffees > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get a dynamic message based on available coffees
  String _getAvailableMessage() {
    if (availableCoffees <= 0) {
      return 'You\'ve redeemed all your coffees for today. Check back tomorrow for a fresh refill!';
    } else if (availableCoffees == 1) {
      return 'Time for a delicious coffee break! Head to your favorite coffee shop and redeem your free coffee today.';
    } else {
      return 'You have $availableCoffees coffees ready to redeem! Head to your favorite coffee shop and enjoy a well-deserved break today.';
    }
  }
}
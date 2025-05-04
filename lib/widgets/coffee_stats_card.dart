// Path: lib/widgets/coffee_stats_card.dart

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';

class CoffeeStatsCard extends StatelessWidget {
  final String month;
  final String redeemedCount;
  final String availableCount;
  final String jokersCount;

  const CoffeeStatsCard({
    Key? key,
    required this.month,
    required this.redeemedCount,
    required this.availableCount,
    required this.jokersCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              month,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: MyApp.coffeeBean,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your Redemption Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            // Coffee Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItemWithIcon(
                  context,
                  availableCount,
                  'Available',
                  Icons.local_cafe,
                ),
                _buildStatItemWithIcon(
                  context,
                  redeemedCount,
                  'Redeemed',
                  Icons.check_circle_outline,
                ),
                _buildStatItemWithIcon(
                  context,
                  jokersCount,
                  'Jokers',
                  Icons.auto_awesome,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemWithIcon(BuildContext context, String value, String label, IconData icon) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: coffeeBean.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevents overflow
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: coffeeBean,
                size: 18, // Smaller icon
              ),
              const SizedBox(height: 2), // Reduced spacing
              Text(
                value,
                style: TextStyle(
                  fontSize: 20, // Smaller font
                  fontWeight: FontWeight.bold,
                  color: coffeeBean,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
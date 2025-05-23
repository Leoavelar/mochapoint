// Path: lib/widgets/nearest_shops_widget.dart

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';

class NearestShopsWidget extends StatelessWidget {
  const NearestShopsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Updated shop data with additional entries and subscription status
    final shops = [
      {
        'name': 'Tribeka Kaiserfeldgasse',
        'distance': '600m',
        'rating': 4.8,
        'walking_time': '2 min',
        'logo': 'assets/images/shops/tribeka.png',
        'subscription': true, // User has subscription here
        'joker': false, // No need for joker since user has subscription
      },
      {
        'name': 'Sorger Sporgasse',
        'distance': '1.4km',
        'rating': 4.7,
        'walking_time': '4 min',
        'logo': 'assets/images/shops/sorger.png',
        'subscription': false, // No subscription
        'joker': true, // Can use joker here
      },
      {
        'name': 'AUER Hauptplatz',
        'distance': '1.3km',
        'rating': 4.6,
        'walking_time': '2 min',
        'logo': 'assets/images/shops/auer.png',
        'subscription': false,
        'joker': true,
      },
      {
        'name': 'Home Bakery',
        'distance': '1.1km',
        'rating': 4.7,
        'walking_time': '4 min',
        'logo': 'assets/images/shops/home_bakery.png',
        'subscription': false,
        'joker': true,
      },
    ];

    return Column(
      children: shops.map((shop) => _buildShopItem(context, shop)).toList(),
    );
  }

  Widget _buildShopItem(BuildContext context, Map<String, dynamic> shop) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;
    const coffeeGreen = Color(0xFF4CAF50);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Shop logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  shop['logo'],
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to a coffee icon if image fails to load
                    return Container(
                      color: coffeeBean.withOpacity(0.1),
                      child: Icon(
                        Icons.coffee,
                        color: coffeeBean,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Shop details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        size: 14,
                        color: MyApp.coffeeBean,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop['distance'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: MyApp.coffeeBean,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop['walking_time'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${shop['rating']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Subscription or Joker indicator
                      if (shop['subscription'])
                        Icon(
                          Icons.local_cafe,
                          size: 14,
                          color: coffeeGreen,
                        )
                      else if (shop['joker'])
                        Icon(
                          Icons.card_giftcard,
                          size: 14,
                          color: coffeeBean,
                        ),

                      const SizedBox(width: 4),

                      // Subscription or Joker text
                      Text(
                        shop['subscription'] ? 'subscribed' : (shop['joker'] ? 'joker' : ''),
                        style: TextStyle(
                          fontSize: 14,
                          color: shop['subscription'] ? coffeeGreen :
                          (shop['joker'] ? coffeeBean : Colors.black54),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Directions button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: coffeeBean,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.directions,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Directions to ${shop['name']} coming soon!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
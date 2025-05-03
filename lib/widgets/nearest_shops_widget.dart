// Path: lib/widgets/nearest_shops_widget.dart

import 'package:flutter/material.dart';

class NearestShopsWidget extends StatelessWidget {
  const NearestShopsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data for nearest shops
    final shops = [
      {
        'name': 'Tribeka Kaiserfeldgasse',
        'distance': '600m',
        'rating': 4.8,
        'walking_time': '2 min',
      },
      {
        'name': 'Home Bakery',
        'distance': '1.1km',
        'rating': 4.7,
        'walking_time': '4 min',
      },
    ];

    return Column(
      children: shops.map((shop) => _buildShopItem(context, shop)).toList(),
    );
  }

  Widget _buildShopItem(BuildContext context, Map<String, dynamic> shop) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black26, // Add this line
      surfaceTintColor: Colors.transparent, // Add this line
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Shop logo/icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/Icon.png',
                  width: 30,
                  height: 30,
                  // color: Colors.white,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
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
                        color: Colors.orange,
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
                        color: Colors.orange,
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
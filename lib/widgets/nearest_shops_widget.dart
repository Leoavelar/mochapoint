// Path: lib/widgets/nearest_shops_widget.dart

import 'package:flutter/material.dart';

class NearestShopsWidget extends StatelessWidget {
  const NearestShopsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data for nearest shops
    final shops = [
      {
        'name': 'Mocha Point Downtown',
        'distance': '0.3 miles',
        'rating': 4.8,
        'walking_time': '5 min',
      },
      {
        'name': 'Mocha Point Riverside',
        'distance': '0.5 miles',
        'rating': 4.6,
        'walking_time': '8 min',
      },
      {
        'name': 'Mocha Point University',
        'distance': '0.8 miles',
        'rating': 4.9,
        'walking_time': '12 min',
      },
    ];

    return Column(
      children: shops.map((shop) => _buildShopItem(context, shop)).toList(),
    );
  }

  Widget _buildShopItem(BuildContext context, Map<String, dynamic> shop) {
    final darkGreen = Theme.of(context).primaryColor;
    final coffeeBean = Theme.of(context).colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          shop['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: coffeeBean),
                const SizedBox(width: 4),
                Text(shop['distance']),
                const SizedBox(width: 12),
                Icon(Icons.directions_walk, size: 14, color: coffeeBean),
                const SizedBox(width: 4),
                Text(shop['walking_time']),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${shop['rating']}'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.directions, color: coffeeBean),
          onPressed: () {
            // Will implement directions functionality later
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Directions to ${shop['name']} coming soon!'),
                backgroundColor: darkGreen,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        onTap: () {
          // Will implement shop details view later
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${shop['name']} details coming soon!'),
              backgroundColor: darkGreen,
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}
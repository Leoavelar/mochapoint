import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Center of Graz, Austria
  final LatLng _center = const LatLng(47.0707, 15.4395);

  // List of coffee shops with their positions
  final List<Map<String, dynamic>> _coffeeShops = [
    {
      'name': 'Tribeka Kaiserfeldgasse',
      'position': const LatLng(47.06837847307516, 15.440760976673467),
      'subscription': true,
      'rating': 4.8,
    },
    {
      'name': 'Sorger Sporgasse',
      'position': const LatLng(47.07186680617716, 15.438352049466518),
      'subscription': false,
      'joker': true,
      'rating': 4.7,
    },
    {
      'name': 'AUER Hauptplatz',
      'position': const LatLng(47.07158402395699, 15.438189099660917),
      'subscription': false,
      'joker': true,
      'rating': 4.6,
    },
    {
      'name': 'Home Bakery',
      'position': const LatLng(47.06793815882071, 15.442564496718765),
      'subscription': false,
      'joker': true,
      'rating': 4.7,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;
    const coffeeGreen = Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/Icon.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'Mocha Point Locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _center,
                    zoom: 14.5,
                    minZoom: 10,
                    maxZoom: 18,
                    // Disable rotation
                    interactiveFlags:
                        InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mocha_point',
                    ),
                    MarkerLayer(
                      markers: _coffeeShops.map((shop) {
                        return Marker(
                          point: shop['position'],
                          width: 40,
                          height: 40,
                          builder: (context) => GestureDetector(
                            onTap: () {
                              _showShopDetails(context, shop);
                            },
                            child: _buildCustomMarker(
                              context,
                              shop['subscription'] == true
                                  ? coffeeGreen
                                  : coffeeBean,
                              shop['subscription'] == true,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Attribution positioned at the bottom right
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '© CARTO © OpenStreetMap contributors',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Container(
          //   padding: const EdgeInsets.all(12.0),
          //   color: Colors.white,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       _buildLegendItem(context, 'Subscription', coffeeGreen, true),
          //       const SizedBox(width: 24),
          //       _buildLegendItem(context, 'Joker', coffeeBean, false),
          //     ],
          //   ),
          // ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: coffeeBean,
        child: const Icon(Icons.my_location),
        onPressed: () {
          // Would normally get user location and center map there
          _mapController.move(_center, 15.0);
        },
      ),
    );
  }

  Widget _buildCustomMarker(
      BuildContext context, Color color, bool isSubscription) {
    return Center(
      child: Image.asset(
        isSubscription ? 'assets/images/mochalogo.png' : 'assets/images/Icon.png',
        height: 32,
        width: 32,
      ),
    );
  }


  void _showShopDetails(BuildContext context, Map<String, dynamic> shop) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;
    final coffeeGreen = const Color(0xFF4CAF50);
    final isSubscription = shop['subscription'] == true;
    final color = isSubscription ? coffeeGreen : coffeeBean;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSubscription ? Icons.local_cafe : Icons.redeem,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop['name'],
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${shop['rating']}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              isSubscription ? 'Subscription' : 'Joker',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to the redeem screen or show redeem dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Redeem coffee at ${shop['name']}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSubscription ? Icons.local_cafe : Icons.redeem,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSubscription ? 'Redeem Coffee' : 'Use Joker',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Open directions in external map app
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Directions to ${shop['name']}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Get Directions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

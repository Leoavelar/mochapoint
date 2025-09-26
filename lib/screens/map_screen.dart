// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mocha_point/services/coffee_shop_service.dart';
import 'package:mocha_point/config/app_config.dart';
import 'package:mocha_point/utils/exceptions.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Center of Graz, Austria (fallback location)
  final LatLng _defaultCenter = const LatLng(47.0707, 15.4395);
  LatLng _currentCenter;

  // State management
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  List<CoffeeShop> _coffeeShops = [];
  LatLng? _userLocation;

  _MapScreenState() : _currentCenter = const LatLng(47.0707, 15.4395);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadCoffeeShops();
    await _getCurrentLocation();
  }

  Future<void> _loadCoffeeShops({LatLng? userLocation}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (AppConfig.enableLogging) {
        print('🗺️ MapScreen: Loading coffee shops...');
      }

      final coffeeShops = await CoffeeShopService.getCoffeeShops(
        userLatitude: userLocation?.latitude,
        userLongitude: userLocation?.longitude,
        radius: 20.0, // 20km radius for map view
      );

      if (mounted) {
        setState(() {
          _coffeeShops = coffeeShops;
          _isLoading = false;
        });

        if (AppConfig.enableLogging) {
          print('☕ MapScreen: Loaded ${coffeeShops.length} coffee shops');
        }
      }
    } on SessionExpiredException catch (e) {
      if (mounted) {
        _handleSessionExpired(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });

        if (AppConfig.enableLogging) {
          print('❌ MapScreen Error: $e');
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (AppConfig.enableLogging) {
            print('📍 MapScreen: Location permission denied');
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (AppConfig.enableLogging) {
          print('📍 MapScreen: Location permission permanently denied');
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current location
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final userLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _userLocation = userLocation;
          _currentCenter = userLocation;
          _isLoadingLocation = false;
        });

        // Move map to user location
        _mapController.move(userLocation, 15.0);

        // Reload coffee shops with user location for distance calculation
        await _loadCoffeeShops(userLocation: userLocation);

        if (AppConfig.enableLogging) {
          print('📍 MapScreen: User location: ${position.latitude}, ${position.longitude}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });

        if (AppConfig.enableLogging) {
          print('❌ MapScreen Location Error: $e');
        }

        // Still show coffee shops, just without user location
        if (_coffeeShops.isEmpty) {
          await _loadCoffeeShops();
        }
      }
    }
  }

  void _handleSessionExpired(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Session Expired',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _redirectToLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
              ),
              child: const Text('Log In Again'),
            ),
          ],
        );
      },
    );
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;
    const coffeeGreen = Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/mocha_icon_black.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'Coffee Shops Near You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading || _isLoadingLocation)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initializeMap(),
          ),
        ],
      ),
      body: _buildBody(coffeeBean, coffeeGreen),
      floatingActionButton: FloatingActionButton(
        backgroundColor: coffeeBean,
        child: _isLoadingLocation
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.my_location),
        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
      ),
    );
  }

  Widget _buildBody(Color coffeeBean, Color coffeeGreen) {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // Info banner
        if (_coffeeShops.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: coffeeBean.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: coffeeBean, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Found ${_coffeeShops.length} coffee shops nearby',
                    style: TextStyle(
                      color: coffeeBean,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_userLocation != null)
                  Text(
                    'Location: ON',
                    style: TextStyle(
                      color: coffeeGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: _userLocation != null ? 15.0 : 14.5,
                  minZoom: 10,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mochapoint.app',
                  ),
                  // User location marker
                  if (_userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation!,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Coffee shop markers
                  MarkerLayer(
                    markers: _coffeeShops.map((shop) {
                      final isSubscription = shop.supportsSubscription;
                      return Marker(
                        point: LatLng(shop.latitude, shop.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showShopDetails(context, shop),
                          child: _buildCustomMarker(
                            context,
                            isSubscription ? coffeeGreen : coffeeBean,
                            isSubscription,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              // Attribution
              Positioned(
                bottom: 5,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.white.withOpacity(0.8),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading coffee shops...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load coffee shops',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _initializeMap(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMarker(BuildContext context, Color color, bool isSubscription) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          width: 32,
          height: 32,
          color: Colors.white,
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            isSubscription
                ? 'assets/icons/mocha_icon_coffeebean.png'
                : 'assets/icons/mocha_icon_black.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _showShopDetails(BuildContext context, CoffeeShop shop) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;
    const coffeeGreen = Color(0xFF4CAF50);
    final isSubscription = shop.supportsSubscription;
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
                          shop.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (shop.brand != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            shop.brand!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (shop.bestRating > 0) ...[
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                shop.bestRating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (shop.distance != null) ...[
                              Icon(
                                Icons.directions_walk,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${shop.distance!.toStringAsFixed(1)}km',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isSubscription ? 'Subscription' : 'Joker Only',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (shop.address.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Redeem coffee at ${shop.name}'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Directions to ${shop.name}'),
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
// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocha_point/services/coffee_shop_service.dart';
import 'package:mocha_point/services/subscription_service.dart';
import 'package:mocha_point/services/monthly_stats_service.dart';
import 'package:mocha_point/services/auth_service.dart';
import 'package:mocha_point/config/app_config.dart';
import 'package:mocha_point/utils/exceptions.dart';
import 'package:mocha_point/utils/location_utils.dart';
import 'package:mocha_point/widgets/profile_avatar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Center of Graz, Austria (fallback location)
  LatLng _currentCenter = LocationUtils.defaultCenter;

  // State management
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  List<CoffeeShop> _coffeeShops = [];
  LatLng? _userLocation;

  // User subscription data
  Set<int> _accessibleShopIds = {};
  int _availableJokers = 0;
  bool _hasActiveSubscription = false;

  // User profile data for avatar
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadUserData();
    await _loadUserSubscriptionData();
    await _loadCoffeeShops();
    await _getCurrentLocation();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUser();
      if (mounted) {
        setState(() {
          _userData = userData;
        });

        if (AppConfig.enableLogging) {
          print('👤 MapScreen: User data loaded');
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ MapScreen: Error loading user data: $e');
      }
      // Continue without user data - will use default icon
    }
  }

  Future<void> _loadUserSubscriptionData() async {
    try {
      if (AppConfig.enableLogging) {
        print('🔐 MapScreen: Loading user subscription data...');
      }

      // Get user subscription details
      final subscriptionData = await SubscriptionService.getUserSubscription();

      // Get monthly stats for joker count
      final monthlyStats = await MonthlyStatsService.getMonthlyStats();

      if (mounted) {
        setState(() {
          _hasActiveSubscription = subscriptionData.hasActiveSubscription;
          // Extract shop IDs from accessible shops list
          _accessibleShopIds = subscriptionData.accessibleShops
              .map((shop) => shop.id)
              .toSet();
          _availableJokers = monthlyStats.jokersAvailable;
        });

        if (AppConfig.enableLogging) {
          print('🔐 MapScreen: Subscription status - Active: $_hasActiveSubscription');
          print('🔐 MapScreen: Accessible shops: $_accessibleShopIds');
          print('🔐 MapScreen: Available jokers: $_availableJokers');
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ MapScreen: Error loading subscription data: $e');
      }
      // Continue with default values (no subscription, no jokers)
      setState(() {
        _hasActiveSubscription = false;
        _accessibleShopIds = {};
        _availableJokers = 0;
      });
    }
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
          for (final shop in coffeeShops) {
            final category = _getShopCategory(shop);
            print('   ${shop.name}: $category (ID: ${shop.id})');
          }
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

  // NEW: Determine shop category based on user's subscription status and shop capabilities
  ShopCategory _getShopCategory(CoffeeShop shop) {
    // Priority 1: User has subscription AND shop is accessible with subscription
    if (_hasActiveSubscription && _accessibleShopIds.contains(shop.id)) {
      return ShopCategory.subscription;
    }

    // Priority 2: User has jokers AND shop accepts jokers
    if (_availableJokers > 0 && shop.supportsJoker) {
      return ShopCategory.joker;
    }

    // Priority 3: No redemption options available
    return ShopCategory.unavailable;
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      if (AppConfig.enableLogging) {
        print('📍 MapScreen: Getting current location...');
      }

      final locationResult = await LocationUtils.getCurrentLocation();

      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });

        if (locationResult.isSuccess && locationResult.location != null) {
          final userLocation = locationResult.location!;

          setState(() {
            _userLocation = userLocation;
            _currentCenter = userLocation;
          });

          // Move map to user location
          _mapController.move(userLocation, 15.0);

          // Reload coffee shops with user location for distance calculation
          await _loadCoffeeShops(userLocation: userLocation);

          if (AppConfig.enableLogging) {
            print('📍 MapScreen: User location updated successfully');
          }
        } else {
          // Handle location error
          if (AppConfig.enableLogging) {
            print('❌ MapScreen Location Error: ${locationResult.errorMessage}');
          }

          // Show error message to user
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(locationResult.errorMessage ?? 'Unable to get location'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }

          // Still show coffee shops, just without user location
          if (_coffeeShops.isEmpty) {
            await _loadCoffeeShops();
          }
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
                  // Coffee shop markers (rendered first, below user marker)
                  MarkerLayer(
                    markers: _coffeeShops.map((shop) {
                      final category = _getShopCategory(shop);
                      return Marker(
                        point: LatLng(shop.latitude, shop.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showShopDetails(context, shop, category),
                          child: _buildCustomMarker(context, category),
                        ),
                      );
                    }).toList(),
                  ),
                  // User location marker (rendered last, on top)
                  if (_userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation!,
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          child: _buildUserLocationMarker(coffeeBean),
                        ),
                      ],
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

  Widget _buildCustomMarker(BuildContext context, ShopCategory category) {
    String iconPath;
    Color backgroundColor;

    switch (category) {
      case ShopCategory.subscription:
      // User has subscription and shop accepts it - green icon
        iconPath = 'assets/icons/mocha_icon_green.png';
        backgroundColor = const Color(0xFF4CAF50);
        break;
      case ShopCategory.joker:
      // User has jokers and shop accepts them - coffee bean icon
        iconPath = 'assets/icons/mocha_icon_coffeebean.png';
        backgroundColor = Theme.of(context).colorScheme.secondary;
        break;
      case ShopCategory.unavailable:
      // No redemption options available - black/grey icon
        iconPath = 'assets/icons/mocha_icon_black.png';
        backgroundColor = Colors.grey;
        break;
    }

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
            iconPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildUserLocationMarker(Color coffeeBean) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        // Profile picture with white border
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: ClipOval(
            child: _userData != null
                ? ProfileAvatar(
              user: _userData,
              size: 38,
            )
                : Container(
              color: coffeeBean,
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showShopDetails(BuildContext context, CoffeeShop shop, ShopCategory category) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;
    const coffeeGreen = Color(0xFF4CAF50);

    Color color;
    String statusText;
    String actionText;
    IconData actionIcon;

    switch (category) {
      case ShopCategory.subscription:
        color = coffeeGreen;
        statusText = 'Subscription';
        actionText = 'Redeem Coffee';
        actionIcon = Icons.local_cafe;
        break;
      case ShopCategory.joker:
        color = coffeeBean;
        statusText = 'Joker Only';
        actionText = 'Use Joker';
        actionIcon = Icons.redeem;
        break;
      case ShopCategory.unavailable:
        color = Colors.grey;
        statusText = 'Unavailable';
        actionText = 'No Options';
        actionIcon = Icons.block;
        break;
    }

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
                      actionIcon,
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
                                statusText,
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
                onPressed: category == ShopCategory.unavailable ? null : () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$actionText at ${shop.name}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: category == ShopCategory.unavailable ? Colors.grey : color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(actionIcon, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      actionText,
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

// NEW: Enum to clearly define shop categories
enum ShopCategory {
  subscription,  // User can use subscription here
  joker,        // User can use jokers here
  unavailable   // No redemption options available
}
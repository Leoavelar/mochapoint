// lib/widgets/nearest_shops_widget.dart - With pagination and glassmorphism
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mocha_point/main.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';
import '../config/app_typography.dart';
import '../services/subscription_service.dart';

class CoffeeShop {
  final int id;
  final String name;
  final String? brand;
  final String address;
  final double latitude;
  final double longitude;
  final bool subscriptionEnabled;
  final bool jokerEnabled;
  final double userAverageRating;
  final int userRatingCount;
  final double googleRating;
  final int googleRatingCount;
  final String? description;
  final String? phone;
  final String? hours;
  final String? logoUrl;
  final List<String> supportedDrinkTiers;
  final bool isActive;
  final double? distance;
  final String? walkingTime;

  CoffeeShop({
    required this.id,
    required this.name,
    this.brand,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.subscriptionEnabled,
    required this.jokerEnabled,
    required this.userAverageRating,
    required this.userRatingCount,
    required this.googleRating,
    required this.googleRatingCount,
    this.description,
    this.phone,
    this.hours,
    this.logoUrl,
    required this.supportedDrinkTiers,
    required this.isActive,
    this.distance,
    this.walkingTime,
  });

  factory CoffeeShop.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse numbers
    double safeParseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    return CoffeeShop(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      address: json['address'],
      latitude: safeParseDouble(json['latitude']),
      longitude: safeParseDouble(json['longitude']),
      subscriptionEnabled: json['subscription_enabled'] ?? true,
      jokerEnabled: json['joker_enabled'] ?? true,
      userAverageRating: safeParseDouble(json['app_rating']),
      userRatingCount: safeParseInt(json['app_rating_count']),
      googleRating: safeParseDouble(json['google_rating']),
      googleRatingCount: safeParseInt(json['google_rating_count']),
      description: json['description'],
      phone: json['phone'],
      hours: json['hours'],
      logoUrl: json['logoFilename'],
      supportedDrinkTiers: List<String>.from(json['supportedDrinkTiers'] ?? []),
      isActive: json['is_active'] ?? true,
      distance: safeParseDouble(json['distance']),
      walkingTime: json['walkingTime'],
    );
  }
}

class UserSubscriptionStatus {
  final bool hasActiveSubscription;
  final String? bundleName;
  final int weeklyUsageCount;
  final int weeklyLimit;
  final int jokerCount;

  UserSubscriptionStatus({
    required this.hasActiveSubscription,
    this.bundleName,
    required this.weeklyUsageCount,
    required this.weeklyLimit,
    required this.jokerCount,
  });

  factory UserSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionStatus(
      hasActiveSubscription: json['hasActiveSubscription'] ?? false,
      bundleName: json['bundleName'],
      weeklyUsageCount: json['weeklyUsageCount'] ?? 0,
      weeklyLimit: json['weeklyLimit'] ?? 0,
      jokerCount: json['jokerCount'] ?? 0,
    );
  }
}

class ApiService {
  static Future<Map<String, dynamic>> getCoffeeShops() async {
    try {
      String url = '${AppConfig.apiBaseUrl}/coffee-shops';

      if (AppConfig.enableLogging) {
        print('🔍 ApiService: Getting coffee shops from $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConfig.apiTimeout);

      if (AppConfig.enableLogging) {
        print('📊 ApiService: Coffee shops response status = ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (AppConfig.enableLogging) {
          print('📊 ApiService: Response data type = ${responseData.runtimeType}');
        }

        // Handle different response formats
        List<dynamic> jsonData;

        if (responseData is List) {
          jsonData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            jsonData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('coffeeShops')) {
            jsonData = responseData['coffeeShops'] as List<dynamic>;
          } else if (responseData.containsKey('shops')) {
            jsonData = responseData['shops'] as List<dynamic>;
          } else {
            jsonData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format: ${responseData.runtimeType}');
        }

        final List<CoffeeShop> shops = jsonData.map((shop) => CoffeeShop.fromJson(shop)).toList();

        if (AppConfig.enableLogging) {
          print('✅ ApiService: Successfully loaded ${shops.length} coffee shops');
        }

        return {
          'shops': shops,
          'rawJson': response.body,
          'parsedData': responseData,
        };
      } else {
        if (AppConfig.enableLogging) {
          print('❌ ApiService: Failed to load coffee shops: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to load coffee shops: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('💥 ApiService: API Error: $e');
      }
      throw Exception('Network error: $e');
    }
  }

  static Future<UserSubscriptionStatus> getUserSubscriptionStatus(String token) async {
    try {
      if (AppConfig.enableLogging) {
        print('🔍 ApiService: Getting user subscription status');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/subscription-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.apiTimeout);

      if (AppConfig.enableLogging) {
        print('📊 ApiService: Subscription status response = ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (AppConfig.enableLogging) {
          print('✅ ApiService: Successfully loaded subscription status');
        }
        return UserSubscriptionStatus.fromJson(jsonData);
      } else {
        if (AppConfig.enableLogging) {
          print('❌ ApiService: Failed to load subscription status: ${response.statusCode}');
        }
        throw Exception('Failed to load subscription status: ${response.statusCode}');
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('💥 ApiService: Network error: $e');
      }
      throw Exception('Network error: $e');
    }
  }
}

class NearestShopsWidget extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;
  final double searchRadius;
  final String? userToken;

  const NearestShopsWidget({
    super.key,
    this.userLatitude,
    this.userLongitude,
    this.searchRadius = 10.0,
    this.userToken,
  });

  @override
  State<NearestShopsWidget> createState() => _NearestShopsWidgetState();
}

class _NearestShopsWidgetState extends State<NearestShopsWidget> {
  // All shops (sorted by distance/rating)
  List<CoffeeShop> _allShops = [];

  // Currently displayed shops (paginated subset)
  List<CoffeeShop> _displayedShops = [];

  UserSubscriptionStatus? subscriptionStatus;
  UserSubscriptionData? _subscriptionData;
  bool isLoading = true;
  String? errorMessage;
  String? debugRawJson;
  Map<String, dynamic>? debugParsedData;
  bool _isDisposed = false;

  // Pagination state
  static const int _shopsPerPage = 5;
  int _currentPage = 1;
  bool _hasMoreShops = false;
  bool _isLoadingMore = false;

  // Location-related state
  Position? _currentPosition;
  bool _locationPermissionGranted = false;
  bool _isLoadingLocation = false;
  String _orderBy = 'distance';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (!mounted || _isDisposed) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (AppConfig.enableLogging) {
          print('Location services are disabled');
        }
        await _loadData();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (AppConfig.enableLogging) {
            print('Location permissions are denied');
          }
          await _loadData();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (AppConfig.enableLogging) {
          print('Location permissions are permanently denied');
        }
        await _loadData();
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _locationPermissionGranted = true;

      if (AppConfig.enableLogging && _currentPosition != null) {
        print('📍 Got location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      }

      await _loadData();
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Error getting location: $e');
      }
      await _loadData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted || _isDisposed) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      _currentPage = 1; // Reset pagination
    });

    try {
      // Load coffee shops WITHOUT location parameters (Flutter-only solution)
      final shopData = await ApiService.getCoffeeShops();

      if (!mounted || _isDisposed) return;

      // Calculate distances on Flutter side using geolocator
      List<CoffeeShop> shopsWithDistances = [];

      for (var shop in shopData['shops'] as List<CoffeeShop>) {
        double? distance;
        String? walkingTime;

        // Calculate distance using geolocator if we have current position
        if (_currentPosition != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            shop.latitude,
            shop.longitude,
          );

          distance = distanceInMeters / 1000; // Convert to kilometers
          walkingTime = _calculateWalkingTime(distance);
        }

        // Create new CoffeeShop with calculated distance
        shopsWithDistances.add(CoffeeShop(
          id: shop.id,
          name: shop.name,
          brand: shop.brand,
          address: shop.address,
          latitude: shop.latitude,
          longitude: shop.longitude,
          subscriptionEnabled: shop.subscriptionEnabled,
          jokerEnabled: shop.jokerEnabled,
          userAverageRating: shop.userAverageRating,
          userRatingCount: shop.userRatingCount,
          googleRating: shop.googleRating,
          googleRatingCount: shop.googleRatingCount,
          description: shop.description,
          phone: shop.phone,
          hours: shop.hours,
          logoUrl: shop.logoUrl,
          supportedDrinkTiers: shop.supportedDrinkTiers,
          isActive: shop.isActive,
          distance: distance,
          walkingTime: walkingTime,
        ));
      }

      // Sort by distance or rating based on user preference
      if (_currentPosition != null && _orderBy == 'distance') {
        shopsWithDistances.sort((a, b) {
          final distanceA = a.distance ?? double.infinity;
          final distanceB = b.distance ?? double.infinity;
          return distanceA.compareTo(distanceB);
        });
      } else if (_orderBy == 'rating') {
        shopsWithDistances.sort((a, b) {
          final ratingA = (a.googleRating > 0) ? a.googleRating : a.userAverageRating;
          final ratingB = (b.googleRating > 0) ? b.googleRating : b.userAverageRating;
          return ratingB.compareTo(ratingA);
        });
      }

      // Load user subscription status if token provided
      UserSubscriptionStatus? userStatus;
      if (widget.userToken != null) {
        userStatus = await ApiService.getUserSubscriptionStatus(widget.userToken!);
      } else {
        userStatus = UserSubscriptionStatus(
          hasActiveSubscription: false,
          weeklyUsageCount: 0,
          weeklyLimit: 0,
          jokerCount: 0,
        );
      }

      if (!mounted || _isDisposed) return;

      // Load subscription data to know which shops user is subscribed to
      UserSubscriptionData? subscriptionData;
      try {
        subscriptionData = await SubscriptionService.getUserSubscription();
      } catch (e) {
        if (AppConfig.enableLogging) {
          print('Error loading subscription data: $e');
        }
        subscriptionData = null;
      }

      if (!mounted || _isDisposed) return;

      setState(() {
        _allShops = shopsWithDistances;
        _displayedShops = _allShops.take(_shopsPerPage).toList();
        _hasMoreShops = _allShops.length > _shopsPerPage;
        subscriptionStatus = userStatus;
        _subscriptionData = subscriptionData;
        debugRawJson = shopData['rawJson'] as String;
        debugParsedData = shopData['parsedData'] as Map<String, dynamic>?;
        isLoading = false;
      });

      if (AppConfig.enableLogging) {
        print('📊 Pagination: Showing ${_displayedShops.length} of ${_allShops.length} shops');
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _loadMoreShops() {
    if (_isLoadingMore || !_hasMoreShops) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate slight delay for smoother UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _isDisposed) return;

      final nextPage = _currentPage + 1;
      final startIndex = _currentPage * _shopsPerPage;
      final endIndex = startIndex + _shopsPerPage;

      final moreShops = _allShops.skip(startIndex).take(_shopsPerPage).toList();

      setState(() {
        _displayedShops.addAll(moreShops);
        _currentPage = nextPage;
        _hasMoreShops = endIndex < _allShops.length;
        _isLoadingMore = false;
      });

      if (AppConfig.enableLogging) {
        print('📊 Loaded more shops: Now showing ${_displayedShops.length} of ${_allShops.length}');
      }
    });
  }

  // Helper method to calculate walking time
  String _calculateWalkingTime(double distanceKm) {
    const walkingSpeedKmh = 5.0; // Average walking speed
    final minutes = (distanceKm / walkingSpeedKmh * 60).round();

    if (minutes < 1) return "< 1 min";
    if (minutes < 60) return "$minutes min";

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes > 0 ? "${hours}h ${remainingMinutes}m" : "${hours}h";
  }

  Future<void> _refresh() async {
    await _initializeLocation();
  }

  void _changeOrderBy(String newOrderBy) {
    if (_orderBy != newOrderBy) {
      setState(() {
        _orderBy = newOrderBy;
      });
      _loadData();
    }
  }

  bool _isUserSubscribedToShop(int shopId) {
    if (_subscriptionData?.hasActiveSubscription != true) {
      return false;
    }

    return _subscriptionData!.accessibleShops.any((shop) => shop.id == shopId);
  }

  String? _getSubscriptionType(int shopId) {
    if (_subscriptionData?.hasActiveSubscription != true) {
      return null;
    }

    final accessibleShop = _subscriptionData!.accessibleShops
        .where((shop) => shop.id == shopId)
        .firstOrNull;

    return accessibleShop?.subscriptionType;
  }

  Widget _buildRatingDisplay(CoffeeShop shop, bool isSubscribed) {
    final bool hasGoogleRating = shop.googleRating > 0 && shop.googleRatingCount > 0;
    final bool hasAppRating = shop.userAverageRating > 0 && shop.userRatingCount > 0;

    if (hasGoogleRating) {
      return Row(
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            shop.googleRating.toStringAsFixed(1),
            style: AppTypography.bodySmall.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w600
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '(${shop.googleRatingCount})',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 4),
        ],
      );
    } else if (hasAppRating) {
      return Row(
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            shop.userAverageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSubscribed ? MyApp.coffeeBean : Colors.black54,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '(${shop.userRatingCount})',
            style: TextStyle(
              fontSize: 12,
              color: isSubscribed ? MyApp.coffeeBean.withOpacity(0.7) : Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.coffee,
            size: 12,
            color: isSubscribed ? MyApp.coffeeBean.withOpacity(0.7) : Colors.grey,
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(
            Icons.star_border,
            size: 14,
            color: isSubscribed ? MyApp.coffeeBean.withOpacity(0.5) : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            'No ratings',
            style: TextStyle(
              fontSize: 12,
              color: isSubscribed ? MyApp.coffeeBean.withOpacity(0.7) : Colors.grey,
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_isLoadingLocation ? 'Getting your location...' : 'Loading coffee shops...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_allShops.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Nearest Coffee Shops',
                    style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700
                    ),
                  ),
                ),

                _buildLocationHeader(),

                // Display paginated shops
                ..._displayedShops.map((shop) => _buildShopItem(context, shop)).toList(),

                // Load More button
                if (_hasMoreShops)
                  _buildLoadMoreButton(),

                // Show "All shops loaded" message when at the end
                if (!_hasMoreShops && _displayedShops.length < _allShops.length)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'All ${_allShops.length} shops loaded',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: _isLoadingMore
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(MyApp.coffeeBean),
          ),
        )
            : SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _loadMoreShops,
            icon: const Icon(Icons.expand_more),
            label: Text(
              'Load More (${_allShops.length - _displayedShops.length} remaining)',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _currentPosition != null ? Icons.location_on : Icons.location_off,
                size: 16,
                color: _currentPosition != null ? Color(0xFF000000) : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentPosition != null
                      ? 'Showing nearest coffee shops (${_displayedShops.length} of ${_allShops.length})'
                      : 'Location unavailable - showing all shops',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          if (_currentPosition != null) ...[
            const SizedBox(height: 8),
            _buildSegmentedControl(),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(1),
                Colors.white.withOpacity(1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegmentButton('Distance', 'distance', Icons.near_me),
              _buildSegmentButton('Rating', 'rating', Icons.star),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, String value, IconData icon) {
    final isSelected = _orderBy == value;

    return GestureDetector(
      onTap: () => _changeOrderBy(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C2C2E),
              Color(0xFF2C2C2E),
              Color(0xFF000000),
            ],
          )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSummary() {
    final subscription = _subscriptionData!.subscription!;
    final accessibleShopsCount = _subscriptionData!.accessibleShops.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyApp.coffeeBean.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subscription.planName,
                  style: TextStyle(
                    color: MyApp.coffeeBean,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MyApp.coffeeBean,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${subscription.usedThisWeek}/${subscription.weeklyLimit}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.store,
                color: MyApp.coffeeBean,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '$accessibleShopsCount subscribed ${accessibleShopsCount == 1 ? 'shop' : 'shops'} nearby',
                style: TextStyle(
                  color: MyApp.coffeeBean,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load coffee shops',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(
              Icons.coffee_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No coffee shops found',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try expanding your search radius or check your location settings.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(BuildContext context, CoffeeShop shop) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;

    final bool isSubscribed = _isUserSubscribedToShop(shop.id);
    final bool shopAcceptsJokers = shop.jokerEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: shop.logoUrl != null
                  ? Image.asset(
                'assets/images/shops/${shop.logoUrl}',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/shops/default_coffee_logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackLogo(coffeeBean);
                    },
                  );
                },
              )
                  : _buildFallbackLogo(coffeeBean),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700
                  ),
                ),
                if (shop.brand != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    shop.brand!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // Rating (left) and Walking Distance (right)
                Row(
                  children: [
                    // Rating on the left
                    _buildRatingDisplay(shop, false),

                    const SizedBox(width: 16),

                    // Walking distance
                    if (shop.distance != null) ...[
                      const Icon(
                        Icons.directions_walk,
                        size: 14,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop.distance! < 1
                            ? '${(shop.distance! * 1000).round()}m'
                            : '${shop.distance!.toStringAsFixed(1)}km',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ],
                    if (shop.walkingTime != null && shop.distance == null) ...[
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop.walkingTime!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Subscription status and Joker acceptance (separate rows)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSubscribed)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: AppConfig.successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Subscribed',
                            style: AppTypography.bodySmall.copyWith(
                                color: AppConfig.successColor,
                                fontWeight: FontWeight.w700
                            ),
                          ),
                        ],
                      ),
                    if (isSubscribed && shopAcceptsJokers)
                      const SizedBox(height: 4),
                    if (shopAcceptsJokers)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 14,
                            color: MyApp.coffeeAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Accepts Joker',
                            style: AppTypography.bodySmall.copyWith(
                                color: MyApp.coffeeAccent,
                                fontWeight: FontWeight.w700
                            ),
                          ),
                        ],
                      ),
                    if (!isSubscribed && !shopAcceptsJokers)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.payments,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'No Joker',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo(Color coffeeBean) {
    return Container(
      color: coffeeBean.withOpacity(0.1),
      child: Icon(
        Icons.coffee,
        color: coffeeBean,
        size: 24,
      ),
    );
  }
}
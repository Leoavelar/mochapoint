// Path: lib/widgets/nearest_shops_widget.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mocha_point/main.dart';

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
  final double googleRating;
  final String? description;
  final String? phone;
  final String? hours;
  final String? logoUrl;
  final List<String> supportedDrinkTiers;
  final bool isActive;
  final double? distance; // Calculated distance from user location
  final String? walkingTime; // Calculated walking time

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
    required this.googleRating,
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
    return CoffeeShop(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      subscriptionEnabled: json['subscription_enabled'] ?? true,
      jokerEnabled: json['joker_enabled'] ?? true,
      userAverageRating: (json['average_rating'] ?? 0.0).toDouble(),
      googleRating: (json['google_rating'] ?? 0.0).toDouble(),
      description: json['description'],
      phone: json['phone'],
      hours: json['hours'],
      logoUrl: json['logoFilename'],  // ✅ Using logoFilename (camelCase from backend)
      supportedDrinkTiers: List<String>.from(json['supportedDrinkTiers'] ?? []),
      isActive: json['is_active'] ?? true,
      distance: json['distance']?.toDouble(),
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
  // Update this IP address to your backend server's LAN IP
  static const String baseUrl = 'http://192.168.1.109:8000/api';
  // static const String baseUrl = 'https://mochapoint.coffee/api';

  static Future<Map<String, dynamic>> getCoffeeShops({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      String url = '$baseUrl/coffee-shops';

      // Add location-based filtering if coordinates are provided
      if (latitude != null && longitude != null) {
        url += '?lat=$latitude&lng=$longitude';
        if (radius != null) {
          url += '&radius=$radius';
        }
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Handle different response formats
        List<dynamic> jsonData;

        if (responseData is List) {
          // Direct array response
          jsonData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Object response - check common patterns
          if (responseData.containsKey('data')) {
            jsonData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('coffeeShops')) {
            jsonData = responseData['coffeeShops'] as List<dynamic>;
          } else if (responseData.containsKey('shops')) {
            jsonData = responseData['shops'] as List<dynamic>;
          } else {
            // If it's a single shop object, wrap it in a list
            jsonData = [responseData];
          }
        } else {
          throw Exception('Unexpected response format: ${responseData.runtimeType}');
        }

        final List<CoffeeShop> shops = jsonData.map((shop) => CoffeeShop.fromJson(shop)).toList();

        // Return both the shops and the raw JSON for debugging
        return {
          'shops': shops,
          'rawJson': response.body,
          'parsedData': responseData,
        };
      } else {
        throw Exception('Failed to load coffee shops: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('API Error: $e'); // Debug log
      throw Exception('Network error: $e');
    }
  }

  static Future<UserSubscriptionStatus> getUserSubscriptionStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/subscription-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserSubscriptionStatus.fromJson(jsonData);
      } else {
        throw Exception('Failed to load subscription status: ${response.statusCode}');
      }
    } catch (e) {
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
    this.searchRadius = 5.0,
    this.userToken,
  });

  @override
  State<NearestShopsWidget> createState() => _NearestShopsWidgetState();
}

class _NearestShopsWidgetState extends State<NearestShopsWidget> {
  List<CoffeeShop> shops = [];
  UserSubscriptionStatus? subscriptionStatus;
  UserSubscriptionData? _subscriptionData; // NEW: Add subscription data
  bool isLoading = true;
  String? errorMessage;
  String? debugRawJson;
  Map<String, dynamic>? debugParsedData;
  bool _isDisposed = false; // Track disposal state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _isDisposed = true; // Mark as disposed
    super.dispose();
  }

  Future<void> _loadData() async {
    // Check if widget is still mounted and not disposed
    if (!mounted || _isDisposed) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load coffee shops
      final shopData = await ApiService.getCoffeeShops(
        latitude: widget.userLatitude,
        longitude: widget.userLongitude,
        radius: widget.searchRadius,
      );

      // Check again after async operation
      if (!mounted || _isDisposed) return;

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

      // Check again after async operation
      if (!mounted || _isDisposed) return;

      // NEW: Load subscription data to know which shops user is subscribed to
      UserSubscriptionData? subscriptionData;
      try {
        subscriptionData = await SubscriptionService.getUserSubscription();
      } catch (e) {
        print('Error loading subscription data: $e');
        subscriptionData = null;
      }

      // Final check before setState
      if (!mounted || _isDisposed) return;

      setState(() {
        shops = shopData['shops'] as List<CoffeeShop>;
        subscriptionStatus = userStatus;
        _subscriptionData = subscriptionData; // NEW: Store subscription data
        debugRawJson = shopData['rawJson'] as String;
        debugParsedData = shopData['parsedData'] as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      // Check if widget is still mounted before calling setState
      if (!mounted || _isDisposed) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // NEW: Helper method to check if shop is subscribed
  bool _isUserSubscribedToShop(int shopId) {
    if (_subscriptionData?.hasActiveSubscription != true) {
      return false;
    }

    return _subscriptionData!.accessibleShops.any((shop) => shop.id == shopId);
  }

  // NEW: Get subscription type for shop
  String? _getSubscriptionType(int shopId) {
    if (_subscriptionData?.hasActiveSubscription != true) {
      return null;
    }

    final accessibleShop = _subscriptionData!.accessibleShops
        .where((shop) => shop.id == shopId)
        .firstOrNull;

    return accessibleShop?.subscriptionType;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (shops.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          // NEW: Show subscription info summary if user has active subscription
          if (_subscriptionData?.hasActiveSubscription == true)
            _buildSubscriptionSummary(),

          // Coffee shops list
          ...shops.map((shop) => _buildShopItem(context, shop)).toList(),
        ],
      ),
    );
  }

  // NEW: Build subscription summary widget
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
                    fontWeight: FontWeight.bold,
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
    const coffeeGreen = Color(0xFF4CAF50);

    // Check if user is subscribed to this shop
    final bool isSubscribed = _isUserSubscribedToShop(shop.id);
    final String? subscriptionType = _getSubscriptionType(shop.id);

    // Determine if user can use subscription at this shop
    final bool canUseSubscription = subscriptionStatus?.hasActiveSubscription == true &&
        shop.subscriptionEnabled &&
        (subscriptionStatus?.weeklyUsageCount ?? 0) < (subscriptionStatus?.weeklyLimit ?? 0) &&
        isSubscribed; // NEW: Add subscription check

    // Simple check: does the shop accept jokers?
    final bool shopAcceptsJokers = shop.jokerEnabled;

    // Use the better rating for display (Google vs User Average)
    final double displayRating = shop.googleRating > 0 ? shop.googleRating : shop.userAverageRating;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        // NEW: Add colored border for subscribed shops
        side: isSubscribed
            ? BorderSide(color: MyApp.coffeeBean, width: 2.0)
            : BorderSide.none,
      ),
      child: Container(
        // NEW: Add subtle background color for subscribed shops
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSubscribed
              ? MyApp.coffeeBean.withOpacity(0.05)
              : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // NEW: Add subscription badge at the top
              if (isSubscribed)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MyApp.coffeeBean,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subscriptionType == 'brand-wide'
                            ? 'Brand Subscription'
                            : 'Your Subscribed Shop',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  // Shop logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      // NEW: Add border for subscribed shops
                      border: isSubscribed
                          ? Border.all(color: MyApp.coffeeBean, width: 2)
                          : null,
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

                  // Shop details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shop.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  // NEW: Highlight subscribed shop names
                                  color: isSubscribed ? MyApp.coffeeBean : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (shop.brand != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            shop.brand!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSubscribed ? MyApp.coffeeBean.withOpacity(0.8) : Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (shop.distance != null) ...[
                              Icon(
                                Icons.directions_walk,
                                size: 14,
                                color: isSubscribed ? MyApp.coffeeBean : MyApp.coffeeBean,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(shop.distance! * 1000).round()}m',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSubscribed ? MyApp.coffeeBean : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (shop.walkingTime != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: isSubscribed ? MyApp.coffeeBean : MyApp.coffeeBean,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                shop.walkingTime!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSubscribed ? MyApp.coffeeBean : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
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
                              displayRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                color: isSubscribed ? MyApp.coffeeBean : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Subscription or Joker indicator with enhanced styling
                            if (canUseSubscription)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: coffeeGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_cafe,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Free Coffee',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (shopAcceptsJokers)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    size: 14,
                                    color: coffeeBean,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Accepts Joker',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: coffeeBean,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.payments,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
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

                  // Directions button with enhanced styling for subscribed shops
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSubscribed ? MyApp.coffeeBean : coffeeBean,
                      borderRadius: BorderRadius.circular(8),
                      // NEW: Add glow effect for subscribed shops
                      boxShadow: isSubscribed ? [
                        BoxShadow(
                          color: MyApp.coffeeBean.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
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
                            content: Text('Directions to ${shop.name} coming soon!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
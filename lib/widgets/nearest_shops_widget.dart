// Path: lib/widgets/nearest_shops_widget.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mocha_point/main.dart';

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
  final double searchRadius; // in kilometers
  final String? userToken; // JWT token for authenticated requests

  const NearestShopsWidget({
    Key? key,
    this.userLatitude,
    this.userLongitude,
    this.searchRadius = 5.0, // Default 5km radius
    this.userToken,
  }) : super(key: key);

  @override
  State<NearestShopsWidget> createState() => _NearestShopsWidgetState();
}

class _NearestShopsWidgetState extends State<NearestShopsWidget> {
  List<CoffeeShop> shops = [];
  UserSubscriptionStatus? subscriptionStatus;
  bool isLoading = true;
  String? errorMessage;
  String? debugRawJson; // Store raw JSON for debugging
  Map<String, dynamic>? debugParsedData; // Store parsed data for debugging

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      setState(() {
        shops = shopData['shops'] as List<CoffeeShop>;
        subscriptionStatus = userStatus;
        debugRawJson = shopData['rawJson'] as String;
        debugParsedData = shopData['parsedData'] as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
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
          // Coffee shops list
          ...shops.map((shop) => _buildShopItem(context, shop)).toList(),

          // Debug section (only shown in debug mode)
          // if (kDebugMode) _buildDebugSection(),  // ✅ Temporarily disabled
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'DEBUG INFO (Development Only)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subscription Status
          Text(
            'User Subscription Status:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(
            'Has Subscription: ${subscriptionStatus?.hasActiveSubscription ?? false}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            'Jokers Available: ${subscriptionStatus?.jokerCount ?? 0}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            'Weekly Usage: ${subscriptionStatus?.weeklyUsageCount ?? 0}/${subscriptionStatus?.weeklyLimit ?? 0}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            'Bundle: ${subscriptionStatus?.bundleName ?? "None"}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),

          const SizedBox(height: 12),

          // Raw JSON Response
          Text(
            'Raw API Response:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              child: Text(
                _formatJson(debugRawJson ?? ''),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.green,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Parsed Shop Data Summary
          Text(
            'Parsed Shop Data Summary:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          ...shops.take(3).map((shop) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              '• ${shop.name}: jokerEnabled=${shop.jokerEnabled}, logo=${shop.logoUrl ?? "null"}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          )),
          if (shops.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '... and ${shops.length - 3} more shops',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  String _formatJson(String jsonString) {
    try {
      final dynamic jsonData = json.decode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(jsonData);
    } catch (e) {
      return jsonString;
    }
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

    // Determine if user can use subscription at this shop
    final bool canUseSubscription = subscriptionStatus?.hasActiveSubscription == true &&
        shop.subscriptionEnabled &&
        (subscriptionStatus?.weeklyUsageCount ?? 0) < (subscriptionStatus?.weeklyLimit ?? 0);

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
                child: shop.logoUrl != null
                    ? Image.asset(
                  'assets/images/shops/${shop.logoUrl}',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to default logo if specific logo fails
                    return Image.asset(
                      'assets/images/shops/default_coffee_logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Final fallback to icon
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
                  Text(
                    shop.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (shop.brand != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      shop.brand!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (shop.distance != null) ...[
                        const Icon(
                          Icons.directions_walk,
                          size: 14,
                          color: MyApp.coffeeBean,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(shop.distance! * 1000).round()}m',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (shop.walkingTime != null) ...[
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: MyApp.coffeeBean,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shop.walkingTime!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Subscription or Joker indicator
                      if (canUseSubscription)
                        Icon(
                          Icons.local_cafe,
                          size: 14,
                          color: coffeeGreen,
                        )
                      else if (shopAcceptsJokers)
                        Icon(
                          Icons.card_giftcard,
                          size: 14,
                          color: coffeeBean,
                        )
                      else
                        Icon(
                          Icons.payments,
                          size: 14,
                          color: Colors.grey,
                        ),

                      const SizedBox(width: 4),

                      // Simple text labels
                      Text(
                        canUseSubscription
                            ? 'subscription'
                            : shopAcceptsJokers
                            ? 'Accepts Joker'
                            : 'No Joker',
                        style: TextStyle(
                          fontSize: 14,
                          color: canUseSubscription
                              ? coffeeGreen
                              : shopAcceptsJokers
                              ? coffeeBean
                              : Colors.grey,
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
                      content: Text('Directions to ${shop.name} coming soon!'),
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
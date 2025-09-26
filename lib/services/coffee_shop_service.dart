// lib/services/coffee_shop_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mocha_point/config/app_config.dart';
import 'package:mocha_point/services/auth_service.dart';
import 'package:mocha_point/utils/exceptions.dart';

class CoffeeShop {
  final int id;
  final String name;
  final String? brand;
  final String address;
  final double latitude;
  final double longitude;
  final bool subscriptionEnabled;
  final bool jokerEnabled;
  final double? appRating;
  final double? googleRating;
  final String? description;
  final String? phone;
  final bool isActive;
  final bool? isSubscriptionAccessible;
  final double? distance;
  final String? walkingTime;
  final bool? isOpen;
  final bool? redemptionsAllowed;

  CoffeeShop({
    required this.id,
    required this.name,
    this.brand,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.subscriptionEnabled,
    required this.jokerEnabled,
    this.appRating,
    this.googleRating,
    this.description,
    this.phone,
    required this.isActive,
    this.isSubscriptionAccessible,
    this.distance,
    this.walkingTime,
    this.isOpen,
    this.redemptionsAllowed,
  });

  factory CoffeeShop.fromJson(Map<String, dynamic> json) {
    return CoffeeShop(
      id: json['id'] as int,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      subscriptionEnabled: json['subscriptionEnabled'] as bool? ?? false,
      jokerEnabled: json['jokerEnabled'] as bool? ?? false,
      appRating: json['appRating'] != null ? (json['appRating'] as num).toDouble() : null,
      googleRating: json['googleRating'] != null ? (json['googleRating'] as num).toDouble() : null,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isSubscriptionAccessible: json['isSubscriptionAccessible'] as bool?,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      walkingTime: json['walkingTime'] as String?,
      isOpen: json['isOpen'] as bool?,
      redemptionsAllowed: json['redemptionsAllowed'] as bool?,
    );
  }

  // Helper getter for the best available rating
  double get bestRating {
    if (appRating != null && googleRating != null) {
      return appRating! > googleRating! ? appRating! : googleRating!;
    }
    return appRating ?? googleRating ?? 0.0;
  }

  // Helper getter to determine if this shop supports subscriptions
  bool get supportsSubscription => subscriptionEnabled && (isSubscriptionAccessible ?? false);
}

class CoffeeShopService {
  static Future<List<CoffeeShop>> getCoffeeShops({
    double? userLatitude,
    double? userLongitude,
    double? radius = 10.0, // Default 10km radius
  }) async {
    try {
      if (AppConfig.enableLogging) {
        print('🗺️ CoffeeShopService: Fetching coffee shops...');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (userLatitude != null) queryParams['lat'] = userLatitude.toString();
      if (userLongitude != null) queryParams['lng'] = userLongitude.toString();
      if (radius != null) queryParams['radius'] = radius.toString();
      queryParams['active'] = 'true'; // Only get active shops

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/coffee-shops').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (AppConfig.enableLogging) {
        print('🌐 CoffeeShopService GET: $uri');
      }

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // Note: Coffee shops endpoint might not require auth, but we include it if available
          ...await AuthService.getAuthHeaders(),
        },
      ).timeout(AppConfig.apiTimeout);

      if (AppConfig.enableLogging) {
        print('📱 CoffeeShopService Response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] is List) {
          final coffeeShopsJson = jsonData['data'] as List;
          final coffeeShops = coffeeShopsJson
              .map((shopJson) => CoffeeShop.fromJson(shopJson))
              .toList();

          if (AppConfig.enableLogging) {
            print('☕ CoffeeShopService: Loaded ${coffeeShops.length} coffee shops');
          }

          return coffeeShops;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        final body = json.decode(response.body);
        if (body['errorCode'] == 'TOKEN_EXPIRED') {
          await AuthService.logout();
          throw SessionExpiredException('Your session has expired. Please log in again.');
        }
        throw Exception('Authentication failed');
      } else {
        throw Exception('Failed to load coffee shops: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SessionExpiredException) {
        rethrow;
      }
      if (AppConfig.enableLogging) {
        print('❌ CoffeeShopService Error: $e');
      }
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  static Future<CoffeeShop> getCoffeeShopDetails(int shopId) async {
    try {
      if (AppConfig.enableLogging) {
        print('🏪 CoffeeShopService: Fetching shop details for ID: $shopId');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/coffee-shops/$shopId'),
        headers: {
          'Content-Type': 'application/json',
          ...await AuthService.getAuthHeaders(),
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return CoffeeShop.fromJson(jsonData['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        final body = json.decode(response.body);
        if (body['errorCode'] == 'TOKEN_EXPIRED') {
          await AuthService.logout();
          throw SessionExpiredException('Your session has expired. Please log in again.');
        }
        throw Exception('Authentication failed');
      } else if (response.statusCode == 404) {
        throw Exception('Coffee shop not found');
      } else {
        throw Exception('Failed to load coffee shop details: ${response.statusCode}');
      }
    } catch (e) {
      if (e is SessionExpiredException) {
        rethrow;
      }
      if (AppConfig.enableLogging) {
        print('❌ CoffeeShopService Error: $e');
      }
      throw NetworkException('Network error: ${e.toString()}');
    }
  }
}
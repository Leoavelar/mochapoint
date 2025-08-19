// Path: lib/services/subscription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class UserSubscription {
  final int id;
  final String planName;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final int weeklyLimit;
  final int usedThisWeek;
  final bool autoRenew;

  UserSubscription({
    required this.id,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.weeklyLimit,
    required this.usedThisWeek,
    required this.autoRenew,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      planName: json['planName'],
      status: json['status'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      weeklyLimit: json['weeklyLimit'],
      usedThisWeek: json['usedThisWeek'],
      autoRenew: json['autoRenew'],
    );
  }
}

class AccessibleShop {
  final int id;
  final String name;
  final String address;
  final String subscriptionType;
  final double? latitude;
  final double? longitude;

  AccessibleShop({
    required this.id,
    required this.name,
    required this.address,
    required this.subscriptionType,
    this.latitude,
    this.longitude,
  });

  factory AccessibleShop.fromJson(Map<String, dynamic> json) {
    return AccessibleShop(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      subscriptionType: json['subscriptionType'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}

class UserSubscriptionData {
  final bool hasActiveSubscription;
  final UserSubscription? subscription;
  final List<AccessibleShop> accessibleShops;

  UserSubscriptionData({
    required this.hasActiveSubscription,
    this.subscription,
    required this.accessibleShops,
  });

  factory UserSubscriptionData.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return UserSubscriptionData(
      hasActiveSubscription: data['hasActiveSubscription'],
      subscription: data['subscription'] != null
          ? UserSubscription.fromJson(data['subscription'])
          : null,
      accessibleShops: (data['accessibleShops'] as List<dynamic>?)
          ?.map((shop) => AccessibleShop.fromJson(shop))
          .toList() ?? [],
    );
  }
}

class SubscriptionService {
  // Update this to match your backend URL
  static const String baseUrl = 'http://192.168.1.109:8000/api';

  static Future<UserSubscriptionData> getUserSubscription() async {
    try {
      final headers = await AuthService.getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/subscription'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          return UserSubscriptionData.fromJson(jsonResponse);
        } else {
          throw Exception('API returned success: false');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Failed to load subscription data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching subscription data: $e');
      throw Exception('Network error: $e');
    }
  }
}
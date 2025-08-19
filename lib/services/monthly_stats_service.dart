// Path: lib/services/monthly_stats_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class MonthlyStatsData {
  final String month;
  final int totalRedeemed;
  final int subscriptionRedeemed;
  final int jokerRedeemed;
  final int totalAvailable;
  final int subscriptionAvailable;
  final int jokersAvailable;
  final int monthlySubscriptionLimit;
  final bool hasActiveSubscription;
  final String subscriptionName;

  MonthlyStatsData({
    required this.month,
    required this.totalRedeemed,
    required this.subscriptionRedeemed,
    required this.jokerRedeemed,
    required this.totalAvailable,
    required this.subscriptionAvailable,
    required this.jokersAvailable,
    required this.monthlySubscriptionLimit,
    required this.hasActiveSubscription,
    required this.subscriptionName,
  });

  factory MonthlyStatsData.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final redeemed = data['redeemed'];
    final available = data['available'];
    final limits = data['limits'];

    return MonthlyStatsData(
      month: data['month'],
      totalRedeemed: redeemed['total'],
      subscriptionRedeemed: redeemed['subscription'],
      jokerRedeemed: redeemed['joker'],
      totalAvailable: available['total'],
      subscriptionAvailable: available['subscription'],
      jokersAvailable: available['jokers'],
      monthlySubscriptionLimit: limits['monthlySubscriptionLimit'],
      hasActiveSubscription: limits['hasActiveSubscription'],
      subscriptionName: limits['subscriptionName'],
    );
  }
}

class MonthlyStatsService {
  // Update this to match your backend URL
  static const String baseUrl = 'http://192.168.1.109:8000/api'; // Updated to match AuthService

  static Future<MonthlyStatsData> getMonthlyStats() async {
    try {
      // BETTER: Use the existing getAuthHeaders method which handles token automatically
      final headers = await AuthService.getAuthHeaders();

      // Check if Authorization header exists (means token is present)
      if (!headers.containsKey('Authorization')) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/redemptions/monthly-stats'),
        headers: headers, // Use the auth headers directly
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          return MonthlyStatsData.fromJson(jsonResponse);
        } else {
          throw Exception('API returned success: false');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception('Failed to load monthly stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching monthly stats: $e');
      throw Exception('Network error: $e');
    }
  }
}
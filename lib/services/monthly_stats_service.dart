// lib/services/monthly_stats_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MonthlyStatsData {
  final String month;
  final int totalRedeemed;
  final int subscriptionRedeemed;
  final int jokerRedeemed;
  final int jokersAvailable;

  // New subscription-related fields
  final bool hasActiveSubscription;
  final String? subscriptionPlanName;
  final int monthlyLimit;
  final int weeklyLimit;
  final int remainingMonthly;
  final bool canRedeemSubscription;

  MonthlyStatsData({
    required this.month,
    required this.totalRedeemed,
    required this.subscriptionRedeemed,
    required this.jokerRedeemed,
    required this.jokersAvailable,
    required this.hasActiveSubscription,
    this.subscriptionPlanName,
    required this.monthlyLimit,
    required this.weeklyLimit,
    required this.remainingMonthly,
    required this.canRedeemSubscription,
  });

  factory MonthlyStatsData.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final redeemed = data['redeemed'];
    final subscription = data['subscription'];
    final available = data['available'];

    return MonthlyStatsData(
      month: data['month'] ?? 'Unknown',
      totalRedeemed: redeemed['total'] ?? 0,
      subscriptionRedeemed: redeemed['subscription'] ?? 0,
      jokerRedeemed: redeemed['joker'] ?? 0,
      jokersAvailable: available['jokers'] ?? 0,
      hasActiveSubscription: subscription['hasActiveSubscription'] ?? false,
      subscriptionPlanName: subscription['planName'],
      monthlyLimit: subscription['monthlyLimit'] ?? 0,
      weeklyLimit: subscription['weeklyLimit'] ?? 0,
      remainingMonthly: subscription['remainingMonthly'] ?? 0,
      canRedeemSubscription: subscription['canRedeemSubscription'] ?? false,
    );
  }

  // Helper getters for backward compatibility
  int get totalAvailable => remainingMonthly + jokersAvailable;

  // New getter for remaining monthly redemptions
  int get monthlyRemaining => remainingMonthly;
}

class MonthlyStatsService {
  static const String baseUrl = 'http://192.168.1.109:8000/api';

  static Future<MonthlyStatsData> getMonthlyStats() async {
    final headers = await AuthService.getAuthHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/redemptions/monthly-stats'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return MonthlyStatsData.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please log in again.');
    } else {
      throw Exception('Failed to load monthly stats: ${response.statusCode}');
    }
  }
}
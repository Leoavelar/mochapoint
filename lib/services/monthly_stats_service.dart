// lib/services/monthly_stats_service.dart - Complete enhanced version
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/exceptions.dart';
import 'auth_service.dart';

class MonthlyStatsData {
  final String month;
  final int totalRedeemed;
  final int subscriptionRedeemed;
  final int jokerRedeemed;
  final int jokersAvailable;
  final bool hasActiveSubscription;
  final String? subscriptionPlanName;
  final String? coffeeShopName;
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
    this.coffeeShopName,
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
      coffeeShopName: subscription['shopName'],
      monthlyLimit: subscription['monthlyLimit'] ?? 0,
      weeklyLimit: subscription['weeklyLimit'] ?? 0,
      remainingMonthly: subscription['remainingMonthly'] ?? 0,
      canRedeemSubscription: subscription['canRedeemSubscription'] ?? false,
    );
  }

  int get totalAvailable => remainingMonthly + jokersAvailable;
  int get monthlyRemaining => remainingMonthly;
}

class MonthlyStatsService {
  // Helper method to handle API responses with session expiry detection (matching RedemptionService pattern)
  static Map<String, dynamic> _handleApiResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else if (response.statusCode == 401) {
        // Check if this is a session expiry
        final errorCode = data['code'] ?? data['errorCode'];
        if (errorCode == 'TOKEN_EXPIRED') {
          return {
            'success': false,
            'error': 'Your session has expired. Please log in again.',
            'isSessionExpired': true,
            'errorCode': 'SESSION_EXPIRED'
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? 'Authentication failed',
            'isSessionExpired': true,
            'errorCode': 'AUTH_FAILED'
          };
        }
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Request failed',
          'isSessionExpired': false
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse response: $e',
        'isSessionExpired': false
      };
    }
  }

  static Future<MonthlyStatsData> getMonthlyStats() async {
    try {
      if (AppConfig.enableLogging) {
        print('🔍 MonthlyStatsService: Getting monthly statistics');
        print('🌐 Using API base URL: ${AppConfig.apiBaseUrl}');
      }

      final headers = await AuthService.getAuthHeaders();
      if (AppConfig.enableLogging) {
        print('📋 MonthlyStatsService: Headers = $headers');
      }

      if (!headers.containsKey('Authorization')) {
        throw SessionExpiredException('No authentication token available');
      }

      final url = '${AppConfig.apiBaseUrl}/redemptions/monthly-stats';
      if (AppConfig.enableLogging) {
        print('📞 MonthlyStatsService: Calling $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(AppConfig.apiTimeout);

      if (AppConfig.enableLogging) {
        print('📊 MonthlyStatsService: Response status = ${response.statusCode}');
        print('📊 MonthlyStatsService: Response body = ${response.body}');
      }

      final result = _handleApiResponse(response);

      // Handle session expiry (same as RedemptionService)
      if (result['isSessionExpired'] == true) {
        await AuthService.logout();
        if (AppConfig.enableLogging) {
          print('🔒 Session expired, user logged out');
        }

        // Throw the specific exception that triggers session expiry dialog
        throw SessionExpiredException(result['error'] ?? 'Your session has expired. Please log in again.');
      }

      if (result['success']) {
        if (AppConfig.enableLogging) {
          print('✅ MonthlyStatsService: Stats retrieval successful');
        }
        return MonthlyStatsData.fromJson(result);
      } else {
        if (AppConfig.enableLogging) {
          print('❌ MonthlyStatsService: Stats retrieval failed - ${result['error']}');
        }
        throw Exception(result['error'] ?? 'Failed to load monthly stats');
      }
    } catch (e) {
      if (e is SessionExpiredException) {
        // Re-throw session expired exceptions to maintain proper handling
        rethrow;
      }

      if (AppConfig.enableLogging) {
        print('💥 MonthlyStatsService: Stats exception - $e');
      }
      throw NetworkException('Network error: ${e.toString()}');
    }
  }
}
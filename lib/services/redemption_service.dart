// lib/services/redemption_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RedemptionService {
  static const String baseUrl = 'https://mochapoint.coffee/api'; // Replace with your API URL

  // Generate QR token for redemption
  static Future<Map<String, dynamic>> generateQRToken(String redemptionType) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/redemptions/generate-qr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'redemptionType': redemptionType, // 'subscription' or 'joker'
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'qrToken': data['qrToken'],
          'expiresAt': data['expiresAt'],
          'userInfo': data['userInfo'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to generate QR code',
          'nextAvailableAt': data['nextAvailableAt'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Coffee shop validates and redeems QR code
  static Future<Map<String, dynamic>> validateAndRedeem(String qrToken, {String? coffeeType}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/redemptions/validate-and-redeem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qrToken': qrToken,
          'coffeeType': coffeeType,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
          'customer': data['customer'],
          'redemption': data['redemption'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to validate redemption',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user's redemption status
  static Future<Map<String, dynamic>> getRedemptionStatus() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/redemptions/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'status': data['status'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get redemption status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user's redemption history
  static Future<Map<String, dynamic>> getRedemptionHistory({int limit = 50, int offset = 0}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/redemptions/history?limit=$limit&offset=$offset'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'redemptions': data['redemptions'],
          'total': data['total'],
          'hasMore': data['hasMore'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get redemption history',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Helper method to format time until next redemption
  static String getTimeUntilNextRedemption(String? nextAvailableAt) {
    if (nextAvailableAt == null) return '';

    final nextAvailable = DateTime.parse(nextAvailableAt);
    final now = DateTime.now();
    final difference = nextAvailable.difference(now);

    if (difference.isNegative) {
      return 'Available now';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m until next redemption';
    } else {
      return '${minutes}m until next redemption';
    }
  }
}
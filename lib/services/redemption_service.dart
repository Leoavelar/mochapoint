// lib/services/redemption_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RedemptionService {
  // FIXED: Use development URL and remove extra /api
  static const String baseUrl = 'http://192.168.1.109:8000/api'; // Development URL

  // Generate QR token for redemption
  static Future<Map<String, dynamic>> generateQRToken(String redemptionType) async {
    try {
      print('🔍 RedemptionService: Generating QR token for $redemptionType');

      // FIXED: Use getAuthHeaders instead of getToken
      final headers = await AuthService.getAuthHeaders();
      print('📋 RedemptionService: Headers = $headers');

      if (!headers.containsKey('Authorization')) {
        throw Exception('No authentication token available');
      }

      // FIXED: Remove duplicate /api
      final url = '$baseUrl/redemptions/generate-qr';
      print('📞 RedemptionService: Calling $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers, // Use the headers directly
        body: jsonEncode({
          'redemptionType': redemptionType, // 'subscription' or 'joker'
        }),
      );

      print('📊 RedemptionService: Response status = ${response.statusCode}');
      print('📊 RedemptionService: Response body = ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        print('✅ RedemptionService: QR generation successful');
        return {
          'success': true,
          'qrToken': data['qrToken'],
          'expiresAt': data['expiresAt'],
          'userInfo': data['userInfo'],
        };
      } else {
        print('❌ RedemptionService: QR generation failed - ${data['error']}');
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to generate QR code',
          'nextAvailableAt': data['nextAvailableAt'],
        };
      }
    } catch (e) {
      print('💥 RedemptionService: QR generation exception - $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Coffee shop validates and redeems QR code
  static Future<Map<String, dynamic>> validateAndRedeem(String qrToken, {String? coffeeType}) async {
    try {
      print('🔍 RedemptionService: Validating QR token');

      final headers = await AuthService.getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('No authentication token available');
      }

      // FIXED: Remove duplicate /api
      final url = '$baseUrl/redemptions/validate-and-redeem';
      print('📞 RedemptionService: Calling $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'qrToken': qrToken,
          'coffeeType': coffeeType,
        }),
      );

      print('📊 RedemptionService: Validation response status = ${response.statusCode}');
      print('📊 RedemptionService: Validation response body = ${response.body}');

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
      print('💥 RedemptionService: Validation exception - $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user's redemption status
  static Future<Map<String, dynamic>> getRedemptionStatus() async {
    try {
      print('🔍 RedemptionService: Getting redemption status');

      final headers = await AuthService.getAuthHeaders();
      print('📋 RedemptionService: Status headers = $headers');

      if (!headers.containsKey('Authorization')) {
        throw Exception('No authentication token available');
      }

      // FIXED: Remove duplicate /api
      final url = '$baseUrl/redemptions/status';
      print('📞 RedemptionService: Calling $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📊 RedemptionService: Status response status = ${response.statusCode}');
      print('📊 RedemptionService: Status response body = ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        print('✅ RedemptionService: Status retrieval successful');
        return {
          'success': true,
          'status': data['status'],
        };
      } else {
        print('❌ RedemptionService: Status retrieval failed - ${data['error']}');
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get redemption status',
        };
      }
    } catch (e) {
      print('💥 RedemptionService: Status exception - $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user's redemption history
  static Future<Map<String, dynamic>> getRedemptionHistory({int limit = 50, int offset = 0}) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('No authentication token available');
      }

      // FIXED: Remove duplicate /api
      final url = '$baseUrl/redemptions/history?limit=$limit&offset=$offset';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
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
// lib/services/redemption_service.dart - Enhanced with session handling
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RedemptionService {
  static const String baseUrl = 'http://192.168.1.109:8000/api';

  // Helper method to handle API responses with session expiry detection
  static Map<String, dynamic> _handleApiResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else if (response.statusCode == 401) {
        // Check if this is a session expiry
        final errorCode = data['code'];
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

  // Generate QR token for redemption
  static Future<Map<String, dynamic>> generateQRToken(String redemptionType) async {
    try {
      print('🔍 RedemptionService: Generating QR token for $redemptionType');

      final headers = await AuthService.getAuthHeaders();
      print('📋 RedemptionService: Headers = $headers');

      if (!headers.containsKey('Authorization')) {
        return {
          'success': false,
          'error': 'No authentication token available',
          'isSessionExpired': true,
          'errorCode': 'NO_TOKEN'
        };
      }

      final url = '$baseUrl/redemptions/generate-qr';
      print('📞 RedemptionService: Calling $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'redemptionType': redemptionType,
        }),
      );

      print('📊 RedemptionService: Response status = ${response.statusCode}');
      print('📊 RedemptionService: Response body = ${response.body}');

      final result = _handleApiResponse(response);

      // Handle session expiry
      if (result['isSessionExpired'] == true) {
        await AuthService.logout();
        print('🔒 Session expired, user logged out');
      }

      if (result['success']) {
        print('✅ RedemptionService: QR generation successful');
        return {
          'success': true,
          'qrToken': result['qrToken'],
          'expiresAt': result['expiresAt'],
          'userInfo': result['userInfo'],
        };
      } else {
        print('❌ RedemptionService: QR generation failed - ${result['error']}');
        return {
          'success': false,
          'error': result['error'],
          'nextAvailableAt': result['nextAvailableAt'],
          'isSessionExpired': result['isSessionExpired'] ?? false,
          'errorCode': result['errorCode']
        };
      }
    } catch (e) {
      print('💥 RedemptionService: QR generation exception - $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'isSessionExpired': false
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
        return {
          'success': false,
          'error': 'No authentication token available',
          'isSessionExpired': true,
          'errorCode': 'NO_TOKEN'
        };
      }

      final url = '$baseUrl/redemptions/status';
      print('📞 RedemptionService: Calling $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📊 RedemptionService: Status response status = ${response.statusCode}');
      print('📊 RedemptionService: Status response body = ${response.body}');

      final result = _handleApiResponse(response);

      // Handle session expiry
      if (result['isSessionExpired'] == true) {
        await AuthService.logout();
        print('🔒 Session expired, user logged out');
      }

      if (result['success']) {
        print('✅ RedemptionService: Status retrieval successful');
        return {
          'success': true,
          'status': result['status'],
        };
      } else {
        print('❌ RedemptionService: Status retrieval failed - ${result['error']}');
        return {
          'success': false,
          'error': result['error'],
          'isSessionExpired': result['isSessionExpired'] ?? false,
          'errorCode': result['errorCode']
        };
      }
    } catch (e) {
      print('💥 RedemptionService: Status exception - $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'isSessionExpired': false
      };
    }
  }

  // Coffee shop validates and redeems QR code
  static Future<Map<String, dynamic>> validateAndRedeem(String qrToken, {String? coffeeType}) async {
    try {
      print('🔍 RedemptionService: Validating QR token');

      final headers = await AuthService.getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        return {
          'success': false,
          'error': 'No authentication token available',
          'isSessionExpired': true
        };
      }

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

      final result = _handleApiResponse(response);

      // Handle session expiry
      if (result['isSessionExpired'] == true) {
        await AuthService.logout();
        print('🔒 Session expired, user logged out');
      }

      if (result['success']) {
        return {
          'success': true,
          'message': result['message'],
          'customer': result['customer'],
          'redemption': result['redemption'],
        };
      } else {
        return {
          'success': false,
          'error': result['error'],
          'isSessionExpired': result['isSessionExpired'] ?? false,
          'errorCode': result['errorCode']
        };
      }
    } catch (e) {
      print('💥 RedemptionService: Validation exception - $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'isSessionExpired': false
      };
    }
  }

  // Get user's redemption history
  static Future<Map<String, dynamic>> getRedemptionHistory({int limit = 50, int offset = 0}) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        return {
          'success': false,
          'error': 'No authentication token available',
          'isSessionExpired': true
        };
      }

      final url = '$baseUrl/redemptions/history?limit=$limit&offset=$offset';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      final result = _handleApiResponse(response);

      // Handle session expiry
      if (result['isSessionExpired'] == true) {
        await AuthService.logout();
      }

      if (result['success']) {
        return {
          'success': true,
          'redemptions': result['redemptions'],
          'total': result['total'],
          'hasMore': result['hasMore'],
        };
      } else {
        return {
          'success': false,
          'error': result['error'],
          'isSessionExpired': result['isSessionExpired'] ?? false,
          'errorCode': result['errorCode']
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'isSessionExpired': false
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
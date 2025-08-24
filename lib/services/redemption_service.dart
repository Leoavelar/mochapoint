// lib/services/redemption_service.dart - Updated with environment config + session handling
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class RedemptionService {
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
      if (AppConfig.enableLogging) {
        print('🔍 RedemptionService: Generating QR token for $redemptionType');
        print('🌐 Using API base URL: ${AppConfig.apiBaseUrl}');
      }

      final headers = await AuthService.getAuthHeaders();
      if (AppConfig.enableLogging) {
        print('📋 RedemptionService: Headers = $headers');
      }

      if (!headers.containsKey('Authorization')) {
        return {
          'success': false,
          'error': 'No authentication token available',
          'isSessionExpired': true,
          'errorCode': 'NO_TOKEN'
        };
      }

      final url = '${AppConfig.apiBaseUrl}/redemptions/generate-qr';
      if (AppConfig.enableLogging) {
        print('📞 RedemptionService: Calling $url');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'redemptionType': redemptionType,
        }),
      ).timeout(AppConfig.apiTimeout);

      if (AppConfig.enableLogging) {
        print('📊 RedemptionService: Response status = ${response.statusCode}');
        print('📊 RedemptionService: Response body = ${response.body}');
      }

      final result = _handleApiResponse(response);

      // Handle session expiry
      if (result['isSessionExpired'] == true) {
        await AuthService.logout();
        if (AppConfig.enableLogging) {
          print('🔒 Session expired, user logged out');
        }
      }

      if (result['success']) {
        if (AppConfig.enableLogging) {
          print('✅ RedemptionService: QR generation successful');
        }
        return {
          'success': true,
          'qrToken': result['qrToken'],
          'expiresAt': result['expiresAt'],
          'userInfo': result['userInfo'],
        };
      } else {
        if (AppConfig.enableLogging) {
          print('❌ RedemptionService: QR generation failed - ${result['error']}');
        }
        return {
          'success': false,
          'error': result['error'],
          'nextAvailableAt': result['nextAvailableAt'],
          'isSessionExpired': result['isSessionExpired'] ?? false,
          'errorCode': result['errorCode']
        };
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('💥 RedemptionService: QR generation exception - $e');
      }
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
      if (AppConfig.enableLogging) {
        print('🔍 RedemptionService: Getting redemption status');
        print('🌐 Using API base URL: ${AppConfig.apiBaseUrl}');
      }

      final headers = await AuthService.getAuthHeaders();
      if (AppConfig.enableLogging) {
        print('📋 RedemptionService: Status headers = $headers');
      }

      if (!headers.containsKey('Authorization')) {
        return {
          'success': false,
          'error': 'No authentication token available',
          'isSessionExpired': true,
          'errorCode': 'NO_TOKEN'
        };
      }

      final url = '${AppConfig.apiBaseUrl}/redemptions/status';
      if (AppConfig.enableLogging) {
        print('📞 RedemptionService: Calling $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(AppConfig.apiTimeout);

      if (AppConfig.enableLogging) {
        print('📊 RedemptionService: Status response status = ${response.statusCode}');
        print('📊 RedemptionService: Status response body = ${response.body}');
      }

      final result = _handleApiResponse(response);

      // Handle session expiry
      if (result['isSessionExpired'] == true) {
        await AuthService.logout();
        if (AppConfig.enableLogging) {
          print('🔒 Session expired, user logged out');
        }
      }

      if (result['success']) {
        if (AppConfig.enableLogging) {
          print('✅ RedemptionService: Status retrieval successful');
        }
        return {
          'success': true,
          'status': result['status'],
        };
      } else {
        if (AppConfig.enableLogging) {
          print('❌ RedemptionService: Status retrieval failed - ${result['error']}');
        }
        return {
          'success': false,
          'error': result['error'],
          'isSessionExpired': result['isSessionExpired'] ?? false,
          'errorCode': result['errorCode']
        };
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('💥 RedemptionService: Status exception - $e');
      }
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
      if (AppConfig.enableLogging) {
        print('🔍 RedemptionService: Validating QR token');
        print('🌐 Using API base URL: ${AppConfig.apiBaseUrl}');
      }

      final headers = await AuthService.getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        return {
          'success': false,
          'error': 'No authentication token available',
          'isSessionExpired': true
        };
      }

      final url = '${AppConfig.apiBaseUrl}/redemptions/validate-and-redeem';
      if (AppConfig.enableLogging) {
        print('📞 RedemptionService: Calling $url');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'qrToken': qrToken,
          'coffeeType': coffeeType,
        }),
      ).timeout(AppConfig.apiTimeout);

      if (AppConfig.enableLogging) {
        print('📊 RedemptionService: Validation response status = ${response.statusCode}');
        print('📊 RedemptionService: Validation response body = ${response.body}');
      }

      final result = _handleApiResponse(response);

      // Handle session expiry
      if (result['isSessionExpired'] == true) {
        await AuthService.logout();
        if (AppConfig.enableLogging) {
          print('🔒 Session expired, user logged out');
        }
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
      if (AppConfig.enableLogging) {
        print('💥 RedemptionService: Validation exception - $e');
      }
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

      final url = '${AppConfig.apiBaseUrl}/redemptions/history?limit=$limit&offset=$offset';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(AppConfig.apiTimeout);

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
// lib/services/api_service.dart - Base API service
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Centralized HTTP client with common configuration
  static Future<http.Response> get(String endpoint, {Map<String, String>? additionalHeaders}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(additionalHeaders);

    if (AppConfig.enableLogging) {
      print('📞 GET $url');
      print('📋 Headers: $headers');
    }

    final response = await http.get(url, headers: headers)
        .timeout(AppConfig.apiTimeout);

    if (AppConfig.enableLogging) {
      print('📊 Response ${response.statusCode}: ${response.body}');
    }

    return response;
  }

  static Future<http.Response> post(String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(additionalHeaders);
    final jsonBody = body != null ? jsonEncode(body) : null;

    if (AppConfig.enableLogging) {
      print('📞 POST $url');
      print('📋 Headers: $headers');
      print('📦 Body: $jsonBody');
    }

    final response = await http.post(url, headers: headers, body: jsonBody)
        .timeout(AppConfig.apiTimeout);

    if (AppConfig.enableLogging) {
      print('📊 Response ${response.statusCode}: ${response.body}');
    }

    return response;
  }

  static Future<Map<String, String>> _getHeaders([Map<String, String>? additionalHeaders]) async {
    final headers = await AuthService.getAuthHeaders();
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  // Helper method to handle API responses consistently
  static Map<String, dynamic> handleResponse(http.Response response, {String? errorPrefix}) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        final errorMessage = data['error'] ?? 'Unknown error occurred';
        final prefix = errorPrefix != null ? '$errorPrefix: ' : '';
        return {
          'success': false,
          'error': '$prefix$errorMessage'
        };
      }
    } catch (e) {
      final prefix = errorPrefix != null ? '$errorPrefix: ' : '';
      return {
        'success': false,
        'error': '${prefix}Failed to parse response: $e'
      };
    }
  }
}
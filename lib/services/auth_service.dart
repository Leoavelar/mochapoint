import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.1.105:3000/api';
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Get stored JWT token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Store JWT token
  static Future<void> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error storing token: $e');
    }
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);
      if (userString != null) {
        return json.decode(userString);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Store user data
  static Future<void> setUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user));
    } catch (e) {
      print('Error storing user: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Email/password login
  static Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await setToken(data['token']);
        await setUser(data['user']);
        return AuthResult(success: true, user: data['user']);
      } else {
        return AuthResult(
          success: false,
          error: data['error'] ?? data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Network error: $e');
    }
  }

  // Email/password registration
  static Future<AuthResult> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        await setToken(data['token']);
        await setUser(data['user']);
        return AuthResult(success: true, user: data['user']);
      } else {
        return AuthResult(
          success: false,
          error: data['error'] ?? data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Network error: $e');
    }
  }

  // Google Sign-In using custom approach
  static Future<AuthResult> signInWithGoogle() async {
    // For now, show a message that Google Sign-In is in development
    // Later we can integrate the WebView approach
    return AuthResult(
      success: false,
      error: 'Google Sign-In is being implemented. Please use email/password for now.',
    );
  }

  // Method to handle Google token (for future use)
  static Future<AuthResult> signInWithGoogleToken(String accessToken, Map<String, dynamic> userInfo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'googleId': userInfo['id'],
          'email': userInfo['email'],
          'name': userInfo['name'],
          'photoUrl': userInfo['picture'],
          'accessToken': accessToken,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await setToken(data['token']);
        await setUser(data['user']);
        return AuthResult(success: true, user: data['user']);
      } else {
        return AuthResult(
          success: false,
          error: data['error'] ?? data['message'] ?? 'Google sign-in failed',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Network error: $e');
    }
  }

  // Get headers with auth token for API calls
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

class AuthResult {
  final bool success;
  final Map<String, dynamic>? user;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}
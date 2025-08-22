// lib/services/auth_service.dart - Compatible version with both methods
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.1.109:8000/api';
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Google Sign-In instance
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

      // Also sign out from Google
      await _googleSignIn.signOut();
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

  // Clean Google Sign-In using the official package
  static Future<AuthResult> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        return AuthResult(success: false, error: 'Sign-in cancelled');
      }

      print('Google Sign-In successful! User: ${googleUser.email}');

      // Get the authentication details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Got Google auth tokens. Access token: ${googleAuth.accessToken?.substring(0, 20)}...');

      // Send Google user data to your backend
      print('Sending data to backend...');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'googleId': googleUser.id,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
          'accessToken': googleAuth.accessToken,
        }),
      );

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await setToken(data['token']);
        await setUser(data['user']);
        print('Successfully stored user data');
        return AuthResult(success: true, user: data['user']);
      } else {
        print('Backend error: ${data}');
        return AuthResult(
          success: false,
          error: data['error'] ?? data['message'] ?? 'Google sign-in failed',
        );
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      return AuthResult(success: false, error: 'Google sign-in failed: $e');
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

  // ORIGINAL METHOD - Keep for backward compatibility (returns bool)
  static Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  // ORIGINAL METHOD - Keep for backward compatibility (returns bool)
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    return await validateToken();
  }

  // NEW ENHANCED METHOD - Detailed validation with session expiry detection
  static Future<AuthValidationResult> validateTokenDetailed() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthValidationResult(isValid: false, needsLogin: true);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return AuthValidationResult(isValid: true, needsLogin: false);
      } else if (response.statusCode == 401) {
        // Parse the error response to check if it's a session expiry
        try {
          final errorData = json.decode(response.body);
          final errorCode = errorData['code'];

          if (errorCode == 'TOKEN_EXPIRED') {
            return AuthValidationResult(
                isValid: false,
                needsLogin: true,
                isExpired: true,
                message: 'Your session has expired. Please log in again.'
            );
          } else {
            return AuthValidationResult(
                isValid: false,
                needsLogin: true,
                message: errorData['error'] ?? 'Authentication failed'
            );
          }
        } catch (e) {
          return AuthValidationResult(
              isValid: false,
              needsLogin: true,
              message: 'Authentication failed'
          );
        }
      } else {
        return AuthValidationResult(isValid: false, needsLogin: false);
      }
    } catch (e) {
      print('Token validation error: $e');
      return AuthValidationResult(
          isValid: false,
          needsLogin: false,
          message: 'Network error: $e'
      );
    }
  }

  // NEW ENHANCED METHOD - Detailed authentication check
  static Future<AuthValidationResult> isAuthenticatedDetailed() async {
    final token = await getToken();
    if (token == null) {
      return AuthValidationResult(isValid: false, needsLogin: true);
    }

    return await validateTokenDetailed();
  }

  // Helper method to handle session expiry across the app
  static Future<bool> handleApiResponse(http.Response response) async {
    if (response.statusCode == 401) {
      try {
        final errorData = json.decode(response.body);
        final errorCode = errorData['code'];

        if (errorCode == 'TOKEN_EXPIRED') {
          // Clear expired token
          await logout();
          return false; // Indicates session expired
        }
      } catch (e) {
        // If we can't parse the error, still treat 401 as expired
        await logout();
        return false;
      }
    }
    return true; // Session is still valid
  }

  // Get a fresh token if current one is invalid
  static Future<String?> getValidToken() async {
    final isValid = await validateToken();
    if (isValid) {
      return await getToken();
    }

    // Token is invalid, need to re-authenticate
    print('Token is invalid, user needs to log in again');
    await logout(); // Clear invalid token
    return null;
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

class AuthValidationResult {
  final bool isValid;
  final bool needsLogin;
  final bool isExpired;
  final String? message;

  AuthValidationResult({
    required this.isValid,
    required this.needsLogin,
    this.isExpired = false,
    this.message,
  });
}
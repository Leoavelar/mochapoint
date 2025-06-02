// lib/screens/google_auth_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class GoogleAuthScreen extends StatefulWidget {
  const GoogleAuthScreen({Key? key}) : super(key: key);

  @override
  State<GoogleAuthScreen> createState() => _GoogleAuthScreenState();
}

class _GoogleAuthScreenState extends State<GoogleAuthScreen> {
  bool _isLoading = false;
  String? _authUrl;

  // Your Google OAuth configuration
  static const String clientId = '***REMOVED***';
  static const String redirectUri = 'http://localhost:3000/auth/google/callback';
  static const String scope = 'openid email profile';

  @override
  void initState() {
    super.initState();
    _generateAuthUrl();
  }

  void _generateAuthUrl() {
    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scope,
      'response_type': 'code',
      'access_type': 'offline',
      'prompt': 'consent',
    };

    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    _authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?$query';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In'),
        backgroundColor: const Color(0xFFA6623A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA6623A)),
            ),
            SizedBox(height: 16),
            Text('Completing Google Sign-In...'),
          ],
        ),
      )
          : _buildWebView(),
    );
  }

  Widget _buildWebView() {
    return Column(
      children: [
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Google Sign-In',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button below to open Google Sign-In in your browser. After signing in, you\'ll be redirected back to the app.',
                style: TextStyle(color: Colors.blue[700]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Manual steps for now (until we implement deep linking)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Google OAuth Steps:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA6623A),
                  ),
                ),

                const SizedBox(height: 16),

                _buildStep(1, 'Tap "Open Google Sign-In" below'),
                _buildStep(2, 'Sign in with your Google account'),
                _buildStep(3, 'Copy the authorization code'),
                _buildStep(4, 'Paste it in the field below'),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _openGoogleSignIn,
                  icon: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.g_mobiledata,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  label: const Text('Open Google Sign-In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA6623A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  decoration: InputDecoration(
                    labelText: 'Authorization Code',
                    hintText: 'Paste the code from Google here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onSubmitted: _handleAuthCode,
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    // Get text from the TextField
                    _handleAuthCode('demo_code'); // This would be the actual code
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Complete Sign-In'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFA6623A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _openGoogleSignIn() {
    if (_authUrl != null) {
      // This would normally open in browser or WebView
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Google Sign-In URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copy this URL and open it in your browser:'),
              const SizedBox(height: 12),
              SelectableText(
                _authUrl!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleAuthCode(String code) async {
    if (code.isEmpty) {
      _showError('Please enter the authorization code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Exchange authorization code for access token
      final tokenResponse = await _exchangeCodeForToken(code);

      if (tokenResponse != null) {
        // Get user info from Google
        final userInfo = await _getUserInfo(tokenResponse['access_token']);

        if (userInfo != null) {
          // Send to your backend
          final result = await AuthService.signInWithGoogleToken(
            tokenResponse['access_token'],
            userInfo,
          );

          if (result.success) {
            Navigator.of(context).pop(); // Close this screen
            // The main app will automatically navigate to home
          } else {
            _showError(result.error ?? 'Google sign-in failed');
          }
        } else {
          _showError('Failed to get user information from Google');
        }
      } else {
        _showError('Failed to exchange authorization code');
      }
    } catch (e) {
      _showError('Error during Google sign-in: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<Map<String, dynamic>?> _exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': 'YOUR_GOOGLE_CLIENT_SECRET', // You'll need this
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Token exchange error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('User info error: $e');
    }
    return null;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
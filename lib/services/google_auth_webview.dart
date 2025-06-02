// lib/services/google_auth_webview.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoogleAuthWebView extends StatefulWidget {
  final Function(String token, Map<String, dynamic> userInfo) onSuccess;
  final Function(String error) onError;

  const GoogleAuthWebView({
    Key? key,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<GoogleAuthWebView> createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<GoogleAuthWebView> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;

  // For development: Manual token entry
  // In production, you'd use a proper WebView

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In'),
        backgroundColor: const Color(0xFFA6623A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Google Sign-In Setup',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFA6623A),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Development Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For now, we\'ll implement a simple Google auth flow. In production, this would be automated with proper OAuth.',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _showGoogleSignInInstructions,
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
              label: const Text('Continue with Google'),
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

            const Text(
              'Or for testing purposes:',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Google Access Token (for testing)',
                hintText: 'Paste Google access token here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _testGoogleToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('Test Token'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoogleSignInInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Sign-In'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To implement full Google Sign-In, we need:'),
            SizedBox(height: 8),
            Text('1. A WebView plugin that works with your build'),
            Text('2. Or a custom deep linking setup'),
            Text('3. Or use the existing web OAuth flow'),
            SizedBox(height: 16),
            Text('For now, you can test with email/password authentication, and we can add Google Sign-In later when we find a compatible solution.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _testGoogleToken() async {
    if (_tokenController.text.isEmpty) {
      widget.onError('Please enter a token to test');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Test token with Google API
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v1/userinfo?access_token=${_tokenController.text}'),
      );

      if (response.statusCode == 200) {
        final userInfo = json.decode(response.body);
        widget.onSuccess(_tokenController.text, userInfo);
        Navigator.of(context).pop();
      } else {
        widget.onError('Invalid token');
      }
    } catch (e) {
      widget.onError('Error testing token: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}
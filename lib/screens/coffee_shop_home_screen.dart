// lib/screens/coffee_shop_home_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../config/app_config.dart'; // ADD THIS IMPORT
import '../widgets/app_header.dart';
import '../widgets/overlapping_content_layout.dart';
import 'coffee_shop_scanner_screen.dart';

class CoffeeShopHomeScreen extends StatefulWidget {
  const CoffeeShopHomeScreen({Key? key}) : super(key: key);

  @override
  State<CoffeeShopHomeScreen> createState() => _CoffeeShopHomeScreenState();
}

class _CoffeeShopHomeScreenState extends State<CoffeeShopHomeScreen> {
  Map<String, dynamic>? _shopData;
  Map<String, dynamic>? _stats;
  List<dynamic> _recentRedemptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthService.getUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check for coffee shop ID in different possible field names
      int? shopId;
      if (user['coffeeShopId'] != null) {
        shopId = user['coffeeShopId'];
      } else if (user['coffee_shop_id'] != null) {
        shopId = user['coffee_shop_id'];
      } else if (user['coffeeShop'] != null) {
        shopId = user['coffeeShop'];
      } else if (user['role'] == 'coffee_shop') {
        // For coffee shop users, try to get the shop ID from the backend
        shopId = await _fetchCoffeeShopIdFromProfile();
        if (shopId == null) {
          print('Coffee shop user data: $user');
          throw Exception('Coffee shop user found but no coffee shop ID available. Please contact support.');
        }
      } else {
        throw Exception('User is not associated with a coffee shop');
      }

      if (shopId == null) {
        throw Exception('No coffee shop ID found');
      }

      // Load shop details, stats, and recent redemptions
      await Future.wait([
        _loadShopDetails(shopId),
        _loadShopStats(shopId),
        _loadRecentRedemptions(shopId),
      ]);

    } catch (e) {
      print('Error loading shop data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shop data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<int?> _fetchCoffeeShopIdFromProfile() async {
    try {
      // First, validate if we have a valid token
      final isAuthenticated = await AuthService.validateToken();
      if (!isAuthenticated) {
        print('Token is invalid or expired. User needs to log in again.');
        // Navigate to login screen or show re-login dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
          // Navigate to login - adjust route name as needed
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return null;
      }

      final token = await AuthService.getToken();
      print('Using valid token for API call');

      final fullUrl = '${AppConfig.apiBaseUrl}/users/profile'; // CHANGED: Use AppConfig instead of AuthService.baseUrl
      print('Fetching fresh user profile from: $fullUrl');

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Profile API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Raw API response: $data');

        final userData = data['user'] ?? data['data'] ?? data;
        print('User data: $userData');
        print('Available fields: ${userData.keys.toList()}');

        // Try different possible field names
        if (userData['coffeeShopId'] != null) {
          print('Found coffeeShopId: ${userData['coffeeShopId']}');
          return userData['coffeeShopId'];
        } else if (userData['coffee_shop_id'] != null) {
          print('Found coffee_shop_id: ${userData['coffee_shop_id']}');
          return userData['coffee_shop_id'];
        } else if (userData['coffeeShop'] != null) {
          print('Found coffeeShop: ${userData['coffeeShop']}');
          return userData['coffeeShop'];
        } else {
          print('No coffee shop ID found in user data');
          print('User role: ${userData['role']}');
          return null;
        }
      } else if (response.statusCode == 403) {
        print('Token expired during API call');
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return null;
      } else {
        print('API call failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching coffee shop ID: $e');
      return null;
    }
  }

  Future<void> _loadShopDetails(int shopId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/coffee-shops/$shopId?includeStatus=true'), // CHANGED: Use AppConfig instead of AuthService.baseUrl
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _shopData = data['data'];
        });
      }
    } catch (e) {
      print('Error loading shop details: $e');
    }
  }

  Future<void> _loadShopStats(int shopId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/coffee-shops/$shopId/stats'), // CHANGED: Use AppConfig instead of AuthService.baseUrl
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _stats = data['data'];
        });
      }
    } catch (e) {
      print('Error loading shop stats: $e');
    }
  }

  Future<void> _loadRecentRedemptions(int shopId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/coffee-shops/$shopId/redemptions?limit=5'), // CHANGED: Use AppConfig instead of AuthService.baseUrl
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recentRedemptions = data['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading recent redemptions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA6623A)),
          ),
        ),
      );
    }

    return OverlappingContentLayout(
      header: const AppHeader(
        backgroundImage: 'assets/images/header_2.png',
        height: 200.0,
      ),
      overlappingWidget: _buildShopHeaderCard(),
      contentWidgets: [
        _buildQuickStatsCard(),
        _buildTodayOverview(),
        _buildQuickActions(),
        _buildRecentRedemptions(),
      ],
      contentSpacing: 20.0,
    );
  }

  Widget _buildShopHeaderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _shopData?['name'] ?? 'Coffee Shop Dashboard',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA6623A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor()),
            ),
            child: Text(
              _getShopStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Color(0xFFA6623A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Today',
                  '${_getTodayRedemptions()}',
                  Icons.today,
                  const Color(0xFFA6623A),
                ),
                _buildStatItem(
                  'This Week',
                  '${_stats!['thisWeek'] ?? 0}',
                  Icons.calendar_view_week,
                  Colors.blue,
                ),
                _buildStatItem(
                  'This Month',
                  '${_stats!['thisMonth'] ?? 0}',
                  Icons.calendar_month,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOverview() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, color: Color(0xFFA6623A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_stats?['redemptionsByType'] != null) ...[
              ..._buildRedemptionTypeBreakdown(),
            ] else
              const Text('No redemptions today'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Color(0xFFA6623A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Scan QR',
                    Icons.qr_code_scanner,
                    const Color(0xFFA6623A),
                        () => _openScanner(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Refresh Data',
                    Icons.refresh,
                    Colors.green,
                        () => _loadShopData(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRedemptions() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Color(0xFFA6623A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Redemptions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentRedemptions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No recent redemptions'),
                ),
              )
            else
              ..._recentRedemptions.take(3).map((redemption) => _buildRedemptionItem(redemption)),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getShopStatusText() {
    if (_shopData?['status'] != null) {
      final status = _shopData!['status'];
      final isOpen = status['isOpen'] ?? false;
      final redemptionsAllowed = status['redemptionsAllowed'] ?? false;

      if (!isOpen) return 'Currently Closed';
      if (!redemptionsAllowed) return 'Open • No Redemptions';
      return 'Open • Accepting Redemptions';
    }
    return 'Coffee Shop';
  }

  Color _getStatusColor() {
    if (_shopData?['status'] != null) {
      final status = _shopData!['status'];
      final isOpen = status['isOpen'] ?? false;
      final redemptionsAllowed = status['redemptionsAllowed'] ?? false;

      if (!isOpen) return Colors.red;
      if (!redemptionsAllowed) return Colors.orange;
      return Colors.green;
    }
    return Colors.grey;
  }

  int _getTodayRedemptions() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final recentData = _stats?['recentRedemptions'] as List?;
    if (recentData != null) {
      final todayData = recentData.where((item) => item['date'] == todayStr).firstOrNull;
      return int.tryParse(todayData?['count']?.toString() ?? '0') ?? 0;
    }
    return 0;
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRedemptionTypeBreakdown() {
    final redemptionsByType = _stats!['redemptionsByType'] as List;

    return redemptionsByType.map<Widget>((item) {
      final type = item['redemption_type'];
      final count = item['count'];
      final isSubscription = type == 'subscription';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isSubscription ? Icons.card_membership : Icons.stars,
                  color: isSubscription ? Colors.blue : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isSubscription ? 'Subscription' : 'Joker',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRedemptionItem(Map<String, dynamic> redemption) {
    final user = redemption['user'] ?? {};
    final type = redemption['redemption_type'];
    final timestamp = DateTime.parse(redemption['timestamp']);
    final timeAgo = _formatTimeAgo(timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: type == 'subscription' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              type == 'subscription' ? Icons.card_membership : Icons.stars,
              color: type == 'subscription' ? Colors.blue : Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? user['email']?.split('@')[0] ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${type == 'subscription' ? 'Subscription' : 'Joker'} • $timeAgo',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CoffeeShopScannerScreen(),
      ),
    );
  }
}
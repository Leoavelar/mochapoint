// lib/screens/home_screen.dart

// Add this import at the top of your file
import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mocha_point/screens/profile_screen.dart';
import '../widgets/daily_coffee_card.dart';
import '../widgets/nearest_shops_widget.dart';
import '../utils/admin_interface_helper.dart';
import '../services/auth_service.dart';
import 'map_screen.dart';
import 'coffee_shop_home_screen.dart';
import '../widgets/redemption_stats_card.dart'; // Ensure this is the correct path
import '../widgets/coffee_bottom_nav.dart';
import '../widgets/app_header.dart';
import '../widgets/overlapping_content_layout.dart';


// ... (HomeScreen code remains the same)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _user;
  bool _showCoffeeShopInterface = false;
  bool _isLoading = true;

  final List<Widget> _tabs = [];

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndInterface();
  }

  Future<void> _loadUserAndInterface() async {
    try {
      final user = await AuthService.getUser();
      final shouldShowCoffeeShop = await AdminInterfaceHelper.shouldShowCoffeeShopInterface(user);

      setState(() {
        _user = user;
        _showCoffeeShopInterface = shouldShowCoffeeShop;
        _isLoading = false;
      });

      _initializeTabs();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (kDebugMode) {
        print('Error loading user interface: $e');
      }
    }
  }

  void _initializeTabs() {
    _tabs.clear();

    if (_showCoffeeShopInterface) {
      // Coffee shop interface
      _tabs.add(const CoffeeShopHomeScreen());
      _tabs.add(const MapScreen());
      _tabs.add(const SizedBox()); // Placeholder for scanner button
      _tabs.add(const ProfileScreen());
    } else {
      // Regular user interface
      _tabs.add(const _CustomerHomeTab());
      _tabs.add(const MapScreen());
      _tabs.add(const SizedBox()); // Placeholder for QR generator button
      _tabs.add(const ProfileScreen());
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

    // A check to prevent range errors if tabs are not yet initialized
    if (_tabs.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Initializing...'),
        ),
      );
    }

    // Handle index 2 which is a placeholder
    final int effectiveIndex = _selectedIndex >= _tabs.length || _selectedIndex == 2 ? 0 : _selectedIndex;

    return Scaffold(
      body: _tabs[effectiveIndex],
      bottomNavigationBar: CoffeeBottomNav(
        selectedIndex: _selectedIndex,
        onIndexChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// MODIFIED WIDGET
class _CustomerHomeTab extends StatelessWidget {
  const _CustomerHomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Get the current date
    final now = DateTime.now();

    // 2. Format it to "Month Year" using the intl package
    final String formattedDate = DateFormat('MMMM yyyy').format(now);

    return OverlappingContentLayout(
      header: const AppHeader(
        backgroundImage: 'assets/images/header_2.png',
        height: 200.0,
      ),
      overlappingWidget: const CoffeeStatsCard(
        // Remove the hardcoded values - the widget will fetch them from API
        // Optional: provide fallback values for when API fails
        fallbackMonth: null, // Will use current month if needed
        fallbackRedeemedCount: '0',
        fallbackAvailableCount: '0',
        fallbackJokersCount: '0',
      ),
      contentWidgets: [
        DailyCoffeeCard(
          onRedeem: () {
            if (kDebugMode) {
              print('Redeem button pressed!');
            }
          },
        ),
        Text(
          'Nearest Coffee Shops',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        const NearestShopsWidget(),
      ],
      contentSpacing: 20.0,
    );
  }
}
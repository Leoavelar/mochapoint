// lib/screens/home_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mocha_point/screens/profile_screen.dart';
import '../widgets/daily_coffee_card.dart';
import '../widgets/nearest_shops_widget.dart';
import '../utils/admin_interface_helper.dart';
import '../services/auth_service.dart';
import 'map_screen.dart';
import 'coffee_shop_home_screen.dart';
import '../widgets/redemption_stats_card.dart';
import '../widgets/coffee_bottom_nav.dart';
import '../widgets/app_header.dart';
import '../widgets/overlapping_content_layout.dart';

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
      print('Error loading user interface: $e');
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

    return Scaffold(
      body: _tabs.isNotEmpty ? _tabs[_selectedIndex == 2 ? 0 : _selectedIndex] : const SizedBox(),
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

// Keep the original customer home screen as a separate widget
class _CustomerHomeTab extends StatelessWidget {
  const _CustomerHomeTab({Key? key}) : super(key: key);

  final bool hasCoffeeAvailableToday = true;

  @override
  Widget build(BuildContext context) {
    return OverlappingContentLayout(
      header: const AppHeader(
        backgroundImage: 'assets/images/header_2.png',
        height: 200.0,
      ),
      overlappingWidget: const CoffeeStatsCard(
        month: 'May 2025',
        redeemedCount: '12',
        availableCount: '10',
        jokersCount: '2',
      ),
      contentWidgets: [
        // Daily Coffee Card - now with internal state management
        DailyCoffeeCard(
          onRedeem: () {
            if (kDebugMode) {
              print('Redeem button pressed!');
            }
            // Any additional logic you want to trigger from the parent
          },
        ),

        Text(
          'Nearest Coffee Shops',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const NearestShopsWidget(),
      ],
      contentSpacing: 20.0,
    );
  }
}
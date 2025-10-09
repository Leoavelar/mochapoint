// lib/screens/home_screen.dart

import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mocha_point/screens/profile_screen.dart';
import '../widgets/daily_coffee_card.dart';
import '../widgets/nearest_shops_widget.dart';
import '../utils/admin_interface_helper.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
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

  // Back button navigation state
  final List<int> _navigationStack = [0]; // Track navigation history
  DateTime? _lastBackPressed;

  final List<Widget> _tabs = [];

  void setSelectedIndex(int index) {
    if (AppConfig.enableLogging) {
      print('🔄 Tab changed: $index (current: $_selectedIndex)');
    }

    setState(() {
      // Add to navigation stack if different from current and not placeholder (index 2)
      if (index != _selectedIndex && index != 2) {
        _navigationStack.add(index);
        _selectedIndex = index;

        if (AppConfig.enableLogging) {
          print('📚 Navigation stack: $_navigationStack');
        }
      } else if (index == 2) {
        // Index 2 is the center button (QR/Scanner), don't add to stack
        _selectedIndex = index;
      }
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

  Future<bool> _onWillPop() async {
    if (AppConfig.enableLogging) {
      print('⬅️ Back button pressed');
      print('📚 Current stack: $_navigationStack');
      print('📍 Current index: $_selectedIndex');
    }

    // If currently showing center button action (index 2), go back to previous tab
    if (_selectedIndex == 2 && _navigationStack.isNotEmpty) {
      setState(() {
        _selectedIndex = _navigationStack.last;
      });

      if (AppConfig.enableLogging) {
        print('↩️ Closing center modal, returning to index: $_selectedIndex');
      }

      return false; // Don't exit app
    }

    // If we have navigation history, go back through tabs
    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
        _selectedIndex = _navigationStack.last;
      });

      if (AppConfig.enableLogging) {
        print('↩️ Navigating back to index: $_selectedIndex');
      }

      return false; // Don't exit app
    }

    // If on home tab (index 0), implement double-tap to exit
    if (_selectedIndex == 0) {
      final now = DateTime.now();
      if (_lastBackPressed == null ||
          now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
        _lastBackPressed = now;

        if (AppConfig.enableLogging) {
          print('🔔 Showing exit confirmation snackbar');
        }

        // Show snackbar: "Press back again to exit"
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Press back again to exit',
                style: TextStyle(color: Colors.white),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFFA6623A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        return false; // Don't exit yet
      }

      if (AppConfig.enableLogging) {
        print('👋 Exiting app');
      }

      return true; // Exit app on second press within 2 seconds
    }

    // If not on home tab but no history, go to home
    setState(() {
      _navigationStack.clear();
      _navigationStack.add(0);
      _selectedIndex = 0;
    });

    if (AppConfig.enableLogging) {
      print('🏠 Returning to home tab');
    }

    return false;
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

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: effectiveIndex,
          children: _tabs,
        ),
        bottomNavigationBar: CoffeeBottomNav(
          selectedIndex: _selectedIndex,
          onIndexChanged: (index) {
            setSelectedIndex(index);
          },
        ),
      ),
    );
  }
}

class _CustomerHomeTab extends StatelessWidget {
  const _CustomerHomeTab({super.key});

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
      overlappingWidget: CoffeeStatsCard(
        // Updated parameter names to match the new widget structure
        fallbackMonth: formattedDate, // Use the formatted current month
        fallbackRedeemedCount: '0',
        fallbackRemainingCount: '0', // Changed from fallbackAvailableCount
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
        const NearestShopsWidget(),
      ],
      contentSpacing: 20.0,
    );
  }
}
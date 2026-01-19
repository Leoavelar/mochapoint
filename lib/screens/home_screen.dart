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
import '../widgets/redemption_selection_modal.dart';
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

  final GlobalKey<_CustomerHomeTabState> _customerHomeKey = GlobalKey<_CustomerHomeTabState>();

  final List<int> _navigationStack = [0];
  DateTime? _lastBackPressed;

  final List<Widget> _tabs = [];

  void setSelectedIndex(int index) {
    if (AppConfig.enableLogging) {
      print('🔄 Tab changed: $index (current: $_selectedIndex)');
    }

    setState(() {
      if (index == 2) {
        if (AppConfig.enableLogging) {
          print('🔄 Received refresh signal, refreshing current tab');
        }

        if (_selectedIndex == 0 && !_showCoffeeShopInterface) {
          _customerHomeKey.currentState?.triggerRefresh();
        }

        return;
      }

      if (index != _selectedIndex) {
        _navigationStack.add(index);
        _selectedIndex = index;

        if (AppConfig.enableLogging) {
          print('📚 Navigation stack: $_navigationStack');
        }
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
      _tabs.add(const CoffeeShopHomeScreen());
      _tabs.add(const MapScreen());
      _tabs.add(const SizedBox());
      _tabs.add(const ProfileScreen());
    } else {
      _tabs.add(_CustomerHomeTab(key: _customerHomeKey));
      _tabs.add(const MapScreen());
      _tabs.add(const SizedBox());
      _tabs.add(const ProfileScreen());
    }
  }

  Future<bool> _onWillPop() async {
    if (AppConfig.enableLogging) {
      print('⬅️ Back button pressed');
      print('📚 Current stack: $_navigationStack');
      print('📍 Current index: $_selectedIndex');
    }

    if (_selectedIndex == 2 && _navigationStack.isNotEmpty) {
      setState(() {
        _selectedIndex = _navigationStack.last;
      });

      if (AppConfig.enableLogging) {
        print('↩️ Closing center modal, returning to index: $_selectedIndex');
      }

      return false;
    }

    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
        _selectedIndex = _navigationStack.last;
      });

      if (AppConfig.enableLogging) {
        print('↩️ Navigating back to index: $_selectedIndex');
      }

      return false;
    }

    if (_selectedIndex == 0) {
      final now = DateTime.now();
      if (_lastBackPressed == null ||
          now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
        _lastBackPressed = now;

        if (AppConfig.enableLogging) {
          print('🔔 Showing exit confirmation snackbar');
        }

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

        return false;
      }

      if (AppConfig.enableLogging) {
        print('👋 Exiting app');
      }

      return true;
    }

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
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA6623A)),
          ),
        ),
      );
    }

    if (_tabs.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('Initializing...'),
        ),
      );
    }

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
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: effectiveIndex,
          children: _tabs,
        ),
        bottomNavigationBar: CoffeeBottomNav(
          selectedIndex: _selectedIndex,
          onIndexChanged: setSelectedIndex,
        ),
      ),
    );
  }
}

class _CustomerHomeTab extends StatefulWidget {
  const _CustomerHomeTab({super.key});

  @override
  State<_CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<_CustomerHomeTab> {
  int _refreshTrigger = 0;

  void triggerRefresh() {
    if (mounted) {
      setState(() {
        _refreshTrigger++;
      });

      if (AppConfig.enableLogging) {
        print('✅ _CustomerHomeTab: Refresh triggered, counter = $_refreshTrigger');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String formattedDate = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  const AppHeader(
                    backgroundImage: 'assets/images/header_2.png',
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    child: DailyCoffeeCard(
                      onRedeem: () async {
                        final result = await showRedemptionModal(context);

                        if (result == true) {
                          triggerRefresh();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    child: CoffeeStatsCard(
                      key: ValueKey(_refreshTrigger),
                      fallbackMonth: formattedDate,
                      fallbackRedeemedCount: '0',
                      fallbackRemainingCount: '0',
                      fallbackJokersCount: '0',
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const SizedBox(
                    width: double.infinity,
                    child: NearestShopsWidget(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> showRedemptionModal(BuildContext context) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RedemptionSelectionModal(),
    );
  }
}
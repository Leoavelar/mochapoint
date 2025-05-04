// Path: lib/screens/home_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mocha_point/screens/profile_screen.dart';
import '../widgets/daily_coffee_card.dart';
import '../widgets/nearest_shops_widget.dart';
import 'map_screen.dart';
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

  final List<Widget> _tabs = [];

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize tabs here to avoid issues with context
    _tabs.add(const _HomeTab());
    _tabs.add(const MapScreen());
    _tabs.add(
        const SizedBox()); // Placeholder for the redeem button (not used as a real tab)
    _tabs.add(const ProfileScreen()); // Add profile screen as a tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex == 2 ? 0 : _selectedIndex],
      // Don't use index 2 as it's just a placeholder
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

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    Key? key,
  }) : super(key: key);

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

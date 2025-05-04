// Path: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';
import '../widgets/qr_code_widget.dart';
import '../widgets/nearest_shops_widget.dart';
import 'map_screen.dart';
import '../widgets/coffee_stats_card.dart';
import '../widgets/coffee_bottom_nav.dart';
import '../widgets/app_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [];

  @override
  void initState() {
    super.initState();
    // Initialize tabs here to avoid issues with context
    _tabs.add(const _HomeTab());
    _tabs.add(const MapScreen());
    _tabs.add(const SizedBox()); // Placeholder for the redeem button (not used as a real tab)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex == 2 ? 0 : _selectedIndex], // Don't use index 2 as it's just a placeholder
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive values
        final screenWidth = constraints.maxWidth;
        final headerHeight = 200.0;
        final qrOverlap = 60.0; // How much the QR code overlaps with the header
        final estimatedQRHeight = 220.0; // Estimated height of QR code widget

        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: headerHeight + (estimatedQRHeight - qrOverlap),
                child: Stack(
                  children: [
                    // Simplified AppHeader with only the image parameter
                    AppHeader(
                      backgroundImage: 'assets/images/header_2.png',
                      height: headerHeight,
                    ),

                    // Coffee Stats Card
                    Positioned(
                      top: headerHeight - qrOverlap,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        child: const CoffeeStatsCard(
                          month: 'May 2025',
                          redeemedCount: '12',
                          availableCount: '10',
                          jokersCount: '2',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content area (unchanged)
              Container(
                color: const Color(0xFFF9F5F1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nearest coffee shops
                      const SizedBox(height: 24),
                      Text(
                        'Nearest Coffee Shops',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const NearestShopsWidget(),
                      const SizedBox(height: 24), // Add some bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


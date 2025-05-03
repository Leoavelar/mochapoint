// Path: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../widgets/qr_code_widget.dart';
import '../widgets/nearest_shops_widget.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

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
    _tabs.add(_HomeTab(
      onProfileTap: () {
        setState(() {
          _selectedIndex = 3;
        });
      },
    ));
    _tabs.add(const MapScreen());
    _tabs.add(const HistoryScreen());
    _tabs.add(const ProfileScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.black,
        elevation: 8,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onProfileTap;

  const _HomeTab({
    Key? key,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive values
        final screenWidth = constraints.maxWidth;
        final headerHeight = 200.0;
        final qrOverlap = 60.0; // How much the QR code overlaps with the header
        final estimatedQRHeight = 400.0; // Estimated height of QR code widget

        return SingleChildScrollView(
          child: Column(
            children: [
              // Stack for header and overlapping QR code
              SizedBox(
                height: headerHeight + (estimatedQRHeight - qrOverlap),
                child: Stack(
                  children: [
                    // Header with coffee image background
                    Container(
                      color: Colors.black,
                      width: double.infinity,
                      height: headerHeight,
                      child: Image.asset(
                        'assets/images/header.png',
                        width: double.infinity,
                        height: headerHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: headerHeight,
                            color: const Color(0xFFE3D0BA),
                          );
                        },
                      ),
                    ),

                    // App bar with profile
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mocha \nPoint',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: onProfileTap,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/profile.png',
                                        width: 60,
                                        height: 60,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 20,
                                            color: Colors.black54,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // QR Code positioned to overlap header
                    Positioned(
                      top: headerHeight - qrOverlap,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.064),
                        child: const QRCodeWidget(),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content area
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

                      // Quick Actions

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

  Widget _buildActionButton(BuildContext context, IconData icon, String label, int? tabIndex) {
    final coffeeBean = Theme.of(context).colorScheme.secondary;

    return GestureDetector(
      onTap: () {
        if (tabIndex != null) {
          // Find the HomeScreen state and update its selected index
          final homeState = context.findAncestorStateOfType<_HomeScreenState>();
          if (homeState != null) {
            homeState.setState(() {
              homeState._selectedIndex = tabIndex;
            });
          }
        } else {
          // Show a coming soon message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label coming soon!'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: coffeeBean.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: coffeeBean,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
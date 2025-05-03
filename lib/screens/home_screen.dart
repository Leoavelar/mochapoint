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

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with coffee image background
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Coffee background image
              Container(
                // color: const Color(0xFFE3D0BA),
                color: Colors.black,// Light coffee/beige background color
                width: double.infinity,
                height: 200,
                child: Image.asset(
                  'assets/images/header.png',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image not found
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: const Color(0xFFE3D0BA), // Same fallback color
                    );
                  },
                ),
              ),

              // App bar with notification icon and profile
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
                          // fontFamily: Mochapoint
                        ),
                      ),
                      Row(
                        children: [
                          // IconButton(
                          //   icon: const Icon(Icons.notifications_outlined),
                          //   color: Colors.black,
                          //   onPressed: () {
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       const SnackBar(
                          //         content: Text('Notifications coming soon!'),
                          //         duration: Duration(seconds: 1),
                          //       ),
                          //     );
                          //   },
                          // ),
                          GestureDetector(
                            onTap: onProfileTap, // Use the callback
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

              // Welcome message
              const Positioned(
                top: 150, // Position to overlap with header
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: QRCodeWidget(),
                ),
              ),
            ],
          ),

          SizedBox(height: 350),

          // Main content area
          Container(
            color: const Color(0xFFF9F5F1), // Light cream background color
            // color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QR Code card
                  const SizedBox(height: 16),
                  // const QRCodeWidget(),

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
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(context, Icons.map, 'Find Shops', 1),
                      _buildActionButton(context, Icons.favorite, 'Favorites', null),
                      _buildActionButton(context, Icons.history, 'History', 2),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
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
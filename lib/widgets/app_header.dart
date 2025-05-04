// Path: lib/widgets/app_header.dart

import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

class AppHeader extends StatelessWidget {
  final String backgroundImage;
  final double height;

  const AppHeader({
    Key? key,
    required this.backgroundImage,
    this.height = 200.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the parent scaffold's context to ensure consistent navigation
    final scaffoldContext = Scaffold.of(context).context;

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: height,
      child: Stack(
        children: [
          // Background image
          Image.asset(
            backgroundImage,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: height,
                color: const Color(0xFFE3D0BA),
              );
            },
          ),

          // Profile image in top-right corner
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(), // Empty spacer on the left
                  GestureDetector(
                    onTap: () {
                      // Instead of direct navigation, use a tab switch method
                      // Find the nearest HomeScreen state and tell it to switch tabs
                      final HomeScreenState? homeState =
                      context.findAncestorStateOfType<HomeScreenState>();

                      if (homeState != null) {
                        // Switch to profile tab (index 3)
                        homeState.setSelectedIndex(3);
                      } else {
                        // Fallback navigation if not inside HomeScreen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                            // Use MaterialPageRoute settings that match tab behavior
                            maintainState: true,
                          ),
                        );
                      }
                    },
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
            ),
          ),
        ],
      ),
    );
  }
}
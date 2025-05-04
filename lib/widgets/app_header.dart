// Path: lib/widgets/app_header.dart

import 'package:flutter/material.dart';
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

          // Profile image in top-right corner with navigation built-in
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(), // Empty spacer on the left
                  GestureDetector(
                    onTap: () {
                      // Use named route instead of direct push
                      // This will ensure the ProfileScreen gets proper theme and context
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                          // Make sure we're using full-screen dialog for proper rendering
                          fullscreenDialog: false,
                        ),
                      );
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
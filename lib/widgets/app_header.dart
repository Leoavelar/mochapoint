import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_avatar.dart';
import '../screens/home_screen.dart'; // Import home screen instead

class AppHeader extends StatefulWidget {
  final String backgroundImage;
  final double height;
  final double borderRadius; // Add this parameter for customizable radius

  const AppHeader({
    Key? key,
    required this.backgroundImage,
    this.height = 200.0,
    this.borderRadius = 20.0, // Default radius value
  }) : super(key: key);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _navigateToProfile() {
    // Find the HomeScreen in the widget tree and switch to profile tab
    final homeScreen = context.findAncestorStateOfType<HomeScreenState>();
    if (homeScreen != null) {
      homeScreen.setSelectedIndex(3); // Profile tab index
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(widget.borderRadius),
        bottomRight: Radius.circular(widget.borderRadius),
      ),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(widget.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo icon on the left
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Image.asset(
                        'assets/icons/mocha_icon_white.png',
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  // Profile avatar on the right
                  ProfileAvatar(
                    user: _user,
                    size: 60,
                    showBorder: true,
                    onTap: _navigateToProfile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
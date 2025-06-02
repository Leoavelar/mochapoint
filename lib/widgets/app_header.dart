import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_avatar.dart';
import '../screens/home_screen.dart'; // Import home screen instead

class AppHeader extends StatefulWidget {
  final String backgroundImage;
  final double height;

  const AppHeader({
    Key? key,
    required this.backgroundImage,
    this.height = 200.0,
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
    return Container(
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
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topRight,
              child: ProfileAvatar(
                user: _user,
                size: 60,
                showBorder: true,
                onTap: _navigateToProfile,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
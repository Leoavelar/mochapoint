// lib/widgets/profile_avatar.dart
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final Map<String, dynamic>? user;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;

  const ProfileAvatar({
    Key? key,
    required this.user,
    this.size = 40,
    this.onTap,
    this.showBorder = false,
  }) : super(key: key);

  String _getUserInitial() {
    if (user?['name'] != null && user!['name'].isNotEmpty) {
      return user!['name'][0].toUpperCase();
    } else if (user?['email'] != null && user!['email'].isNotEmpty) {
      return user!['email'][0].toUpperCase();
    }
    return 'U'; // Default to 'U' for User
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          )
              : null,
        ),
        child: ClipOval(
          child: user?['photoUrl'] != null && user!['photoUrl'].isNotEmpty
              ? Image.network(
            user!['photoUrl'],
            fit: BoxFit.cover,
            width: size,
            height: size,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildInitialAvatar();
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialAvatar();
            },
          )
              : _buildInitialAvatar(),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFA6623A), // Coffee brown
            const Color(0xFF8B4513), // Darker brown
          ],
        ),
      ),
      child: Center(
        child: Text(
          _getUserInitial(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4, // Dynamic font size based on avatar size
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }
}
// lib/widgets/coffee_bottom_nav.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/coffee_shop_scanner_screen.dart';
import 'redemption_selection_modal.dart';

class CoffeeBottomNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const CoffeeBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  State<CoffeeBottomNav> createState() => _CoffeeBottomNavState();
}

class _CoffeeBottomNavState extends State<CoffeeBottomNav>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _user;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final bool isCoffeeShopUser = _user?['role'] == 'coffee_shop';
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 85, // Reduced height to prevent overflow
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFFA6623A).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Animated selection indicator - Properly aligned
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: widget.selectedIndex == 0
                  ? (screenWidth * 0.25) - 25  // Center of first quarter
                  : (screenWidth * 0.75) - 25, // Center of third quarter
              top: 8,
              child: Container(
                width: 50,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA6623A), Color(0xFF8B4513)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA6623A).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom navigation items - Properly spaced
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 5),
              child: Row(
                children: [
                  // Home tab - Takes 1/2 of screen
                  Expanded(
                    child: _buildNavItem(
                      index: 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                    ),
                  ),
                  // Map tab - Takes 1/2 of screen
                  Expanded(
                    child: _buildNavItem(
                      index: 1,
                      icon: Icons.map_outlined,
                      activeIcon: Icons.map_rounded,
                      label: 'Map',
                    ),
                  ),
                ],
              ),
            ),

            // Center floating action button - Properly centered
            Positioned(
              top: 5,
              left: (screenWidth / 2) - 35, // Perfect center
              child: GestureDetector(
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                onTap: _handleCenterButtonTap,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF000000),
                              Color(0xFF000000),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background glow effect
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Icon
                            Icon(
                              isCoffeeShopUser ? Icons.qr_code_scanner_rounded : Icons.qr_code_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onIndexChanged(index),
      child: Container(
        // Full width container for proper alignment
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon - no background decorations
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? const Color(0xFF000000)
                    : Colors.grey[500],
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            // Label - clean text only
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF000000)
                    : Colors.grey[500],
                fontSize: isSelected ? 13 : 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'Montserrat',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCenterButtonTap() {
    final bool isCoffeeShopUser = _user?['role'] == 'coffee_shop';

    if (isCoffeeShopUser) {
      // Navigate to scanner screen for coffee shop users
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const CoffeeShopScannerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    } else {
      // Show redemption modal for regular users
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const RedemptionSelectionModal(),
      );
    }
  }
}
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
      height: 70,
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
            color: const Color(0xFF8B4513).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Animated selection indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: widget.selectedIndex == 0
                  ? (screenWidth * 0.25) - 25
                  : (screenWidth * 0.75) - 25,
              top: 8,
              child: Container(
                width: 50,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B4513), Color(0xFF8B4513)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B4513).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom navigation items
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              // Reduced padding
              child: Row(
                children: [
                  Expanded(
                    child: _buildNavItem(
                      index: 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                    ),
                  ),
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

            // Center floating action button - SQUARE WITH ROUNDED CORNERS (SMALLER)
            Positioned(
              top: 5, // Adjusted for thinner navbar
              left: (screenWidth / 2) - 28, // Adjusted for smaller size
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
                        width: 56, // Reduced from 70
                        height: 56, // Reduced from 70
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF000000),
                              Color(0xFF000000),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          // Proportionally adjusted
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
                              width: 48, // Adjusted for smaller button
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),

                              ),
                            ),
                            // Icon - kept at 32px as requested
                            Icon(
                              isCoffeeShopUser
                                  ? Icons.qr_code_scanner_rounded
                                  : Icons.qr_code_rounded,
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
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? const Color(0xFF000000) : Colors.grey[500],
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? const Color(0xFF000000) : Colors.grey[500],
                fontSize: isSelected ? 12 : 11, // Reduced font sizes
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

  void _handleCenterButtonTap() async { // ✅ Make it async
    final bool isCoffeeShopUser = _user?['role'] == 'coffee_shop';

    if (isCoffeeShopUser) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const CoffeeShopScannerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    } else {
      // ✅ Await the modal result
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const RedemptionSelectionModal(),
      );

      // ✅ If redemption was successful, call onIndexChanged with index 2
      // This will notify HomeScreen that something happened
      if (result == true && mounted) {
        widget.onIndexChanged(2); // Signal to parent that redemption happened
      }
    }
  }
}

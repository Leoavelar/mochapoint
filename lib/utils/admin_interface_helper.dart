// lib/utils/admin_interface_helper.dart
import 'package:shared_preferences/shared_preferences.dart';

class AdminInterfaceHelper {
  static const String _adminViewModeKey = 'admin_view_mode';

  /// Get the current admin view mode ('user' or 'coffee_shop')
  static Future<String> getAdminViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_adminViewModeKey) ?? 'user';
    } catch (e) {
      print('Error getting admin view mode: $e');
      return 'user';
    }
  }

  /// Set the admin view mode
  static Future<void> setAdminViewMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adminViewModeKey, mode);
    } catch (e) {
      print('Error setting admin view mode: $e');
    }
  }

  /// Determine if the current user should see the coffee shop interface
  /// This considers both actual coffee shop users and admin preferences
  static Future<bool> shouldShowCoffeeShopInterface(Map<String, dynamic>? user) async {
    if (user == null) return false;

    // If user is actually a coffee shop, always show coffee shop interface
    if (user['role'] == 'coffee_shop') {
      return true;
    }

    // If user is admin, check their preference
    if (user['role'] == 'admin') {
      final adminViewMode = await getAdminViewMode();
      return adminViewMode == 'coffee_shop';
    }

    // Regular users always see customer interface
    return false;
  }

  /// Check if user is admin and currently in switched mode
  static Future<bool> isAdminInSwitchedMode(Map<String, dynamic>? user) async {
    if (user == null || user['role'] != 'admin') return false;

    final adminViewMode = await getAdminViewMode();
    return adminViewMode == 'coffee_shop';
  }
}
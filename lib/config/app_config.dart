// lib/config/app_config.dart - Enhanced version with typography
// ✅ FIXED: CardThemeData type error
// ✅ FIXED: ColorScheme deprecation warnings
import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppConfig {
  static const String _prodApiUrl = 'https://mochapoint.coffee/api';
  static const String _devApiUrl = 'http://192.168.1.109:8000/api';

  // Environment detection using dart-define
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  // Environment detection
  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';
  static String get currentEnvironment => _environment;

  // API Configuration
  static String get apiBaseUrl => isDevelopment ? _devApiUrl : _prodApiUrl;

  // App Configuration
  static const String appName = 'MochaPoint';
  static const String appVersion = '1.0.0';

  // Development settings
  static bool get enableLogging => isDevelopment;
  static const Duration apiTimeout = Duration(seconds: 30);

  // Features flags (can be environment-specific)
  static bool get enableDebugFeatures => isDevelopment;
  static bool get enableAnalytics => isProduction;

  // ============================================================================
  // TYPOGRAPHY CONFIGURATION
  // ============================================================================

  /// Get the app's text theme
  static TextTheme get textTheme => AppTypography.textTheme;

  /// Typography class for easy access
  static Type get typography => AppTypography;

  // ============================================================================
  // COLOR CONFIGURATION (Coffee-themed)
  // ============================================================================

  static const Color primaryColor = Color(0xFF8B4513); // Coffee brown
  static const Color secondaryColor = Color(0xFFD2691E); // Chocolate
  static const Color accentColor = Color(0xFFFFE4C4); // Bisque
  static const Color backgroundColor = Color(0xFFFFFFF0); // Ivory
  static const Color surfaceColor = Color(0xFFFFFFF0); // Ivory (for newer Flutter)
  static const Color errorColor = Color(0xFFB00020); // Red
  static const Color successColor = Color(0xFF4CAF50); // Green

  static const Color coffeeBrown = Color(0xFF000000);
  static const Color chocolate = Color(0xFFD2691E);
  static const Color coffeeGreen = Color(0xFF4CAF50);
  static const Color coffeeBean = Color(0xFF6A2801);

  // Additional color variants
  static const Color lightBrown = Color(0xFFD2691E);
  static const Color darkBrown = Color(0xFF654321);
  static const Color cream = Color(0xFFFFFDD0);
  static const Color espresso = Color(0xFF3E2723);

  // ============================================================================
  // THEME DATA GENERATION
  // ============================================================================

  /// Generate complete ThemeData for the app
  static ThemeData get theme => ThemeData(
    // Color scheme - Compatible with both old and new Flutter versions
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      // Use surface instead of background for Flutter 3.7+
      surface: surfaceColor,
    ),

    // Typography
    textTheme: textTheme,

    // Primary color
    primaryColor: primaryColor,

    // Scaffold background color
    scaffoldBackgroundColor: backgroundColor,

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: Colors.white,
      ),
    ),

    // Card theme - FIXED: Using CardThemeData instead of CardTheme
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(8),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: AppTypography.labelLarge,
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        textStyle: AppTypography.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: AppTypography.bodyMedium,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: Colors.grey.shade400,
      ),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: primaryColor,
      size: 24,
    ),

    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
      space: 1,
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titleTextStyle: AppTypography.headlineSmall.copyWith(
        color: primaryColor,
      ),
      contentTextStyle: AppTypography.bodyMedium,
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: accentColor,
      disabledColor: Colors.grey.shade300,
      selectedColor: primaryColor,
      secondarySelectedColor: secondaryColor,
      labelStyle: AppTypography.labelSmall,
      secondaryLabelStyle: AppTypography.labelSmall.copyWith(
        color: Colors.white,
      ),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Use Material 3
    useMaterial3: true,
  );

  // ============================================================================
  // DEBUGGING UTILITIES
  // ============================================================================

  /// Print current configuration
  static void printConfig() {
    print('🔧 AppConfig:');
    print('   Environment: ${isDevelopment ? 'Development' : 'Production'}');
    print('   Current Environment Value: $_environment');
    print('   API Base URL: $apiBaseUrl');
    print('   Debug Features: $enableDebugFeatures');
    print('   Logging Enabled: $enableLogging');
    print('   Analytics: $enableAnalytics');
    print('\n☕ Theme Configuration:');
    print('   Primary Color: #${primaryColor.value.toRadixString(16)}');
    print('   Secondary Color: #${secondaryColor.value.toRadixString(16)}');
    print('   Success Color: #${successColor.value.toRadixString(16)}');
    print('   Error Color: #${errorColor.value.toRadixString(16)}');

    if (enableLogging) {
      AppTypography.printStyles();
    }
  }
}
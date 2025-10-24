// lib/config/app_typography.dart
import 'package:flutter/material.dart';
import 'package:mocha_point/main.dart';

/// Centralized typography configuration for MochaPoint app
///
/// Usage:
/// ```dart
/// Text('Header', style: AppTypography.displayLarge)
/// Text('Body text', style: AppTypography.bodyMedium)
/// ```
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // ============================================================================
  // FONT FAMILIES
  // ============================================================================

  /// Primary font family (used for most text)
  static const String primaryFontFamily = 'Montserrat';

  /// Secondary font family (used for emphasis or special content)
  static const String secondaryFontFamily = 'Montserrat';

  /// Monospace font family (used for codes, numbers)
  static const String monospaceFontFamily = 'Poppins';

  // Alternative: If you want custom fonts, uncomment and add to pubspec.yaml
  // static const String primaryFontFamily = 'Montserrat';
  // static const String secondaryFontFamily = 'Roboto';

  // ============================================================================
  // FONT WEIGHTS
  // ============================================================================

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ============================================================================
  // DISPLAY STYLES (Largest text - hero sections, splash screens)
  // ============================================================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 57,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 45,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 36,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============================================================================
  // HEADLINE STYLES (Page titles, section headers)
  // ============================================================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 32,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 28,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 24,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============================================================================
  // TITLE STYLES (Card headers, dialog titles, prominent labels)
  // ============================================================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 22,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 16,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.50,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============================================================================
  // BODY STYLES (Main content, paragraphs)
  // ============================================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.0,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============================================================================
  // LABEL STYLES (Buttons, tabs, small UI elements)
  // ============================================================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============================================================================
  // CUSTOM APP-SPECIFIC STYLES (Coffee-themed styles)
  // ============================================================================

  /// Style for coffee statistics numbers (large, bold)
  static const TextStyle statsNumber = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 32,
    fontWeight: semiBold,
    letterSpacing: -0.5,
    height: 1.0,
  );

  /// Style for coffee statistics labels
  static const TextStyle statsLabel = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  /// Style for coffee shop names
  static const TextStyle shopName = TextStyle(
    fontFamily: primaryFontFamily,
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.33,
  );

  /// Style for coffee shop addresses
  static const TextStyle shopAddress = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// Style for month/period labels
  static const TextStyle periodLabel = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// Style for error messages
  static const TextStyle error = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.25,
    height: 1.43,
    color: Colors.red,
  );

  /// Style for button text
  static const TextStyle button = TextStyle(
    fontFamily: secondaryFontFamily,
    fontSize: 16,
    fontWeight: semiBold,
    letterSpacing: 0.5,
    height: 1.0,
  );

  // ============================================================================
  // THEME GENERATION
  // ============================================================================

  /// Generate TextTheme for MaterialApp
  static TextTheme get textTheme => const TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  // ============================================================================
  // COLOR VARIANTS (For quick color application)
  // ============================================================================

  /// Apply coffee brown color to any text style
  static TextStyle withCoffeeBrown(TextStyle style) {
    return style.copyWith(color: MyApp.coffeeBean);
  }

  /// Apply white color to any text style
  static TextStyle withWhite(TextStyle style) {
    return style.copyWith(color: Colors.white);
  }

  /// Apply grey color to any text style
  static TextStyle withGrey(TextStyle style) {
    return style.copyWith(color: Colors.grey);
  }

  /// Apply custom color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  // ============================================================================
  // FONT WEIGHT VARIANTS (For quick weight changes)
  // ============================================================================

  /// Make any text style bold
  static TextStyle makeBold(TextStyle style) {
    return style.copyWith(fontWeight: bold);
  }

  /// Make any text style medium weight
  static TextStyle makeMedium(TextStyle style) {
    return style.copyWith(fontWeight: medium);
  }

  /// Make any text style regular weight
  static TextStyle makeRegular(TextStyle style) {
    return style.copyWith(fontWeight: regular);
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Print all typography styles (useful for debugging)
  static void printStyles() {
    print('📝 AppTypography Configuration:');
    print('   Primary Font: $primaryFontFamily');
    print('   Secondary Font: $secondaryFontFamily');
    print('\n   Display Styles:');
    print('   - displayLarge: ${displayLarge.fontSize}px, ${displayLarge.fontWeight}');
    print('   - displayMedium: ${displayMedium.fontSize}px, ${displayMedium.fontWeight}');
    print('   - displaySmall: ${displaySmall.fontSize}px, ${displaySmall.fontWeight}');
    print('\n   Headline Styles:');
    print('   - headlineLarge: ${headlineLarge.fontSize}px, ${headlineLarge.fontWeight}');
    print('   - headlineMedium: ${headlineMedium.fontSize}px, ${headlineMedium.fontWeight}');
    print('   - headlineSmall: ${headlineSmall.fontSize}px, ${headlineSmall.fontWeight}');
    print('\n   Body Styles:');
    print('   - bodyLarge: ${bodyLarge.fontSize}px, ${bodyLarge.fontWeight}');
    print('   - bodyMedium: ${bodyMedium.fontSize}px, ${bodyMedium.fontWeight}');
    print('   - bodySmall: ${bodySmall.fontSize}px, ${bodySmall.fontWeight}');
  }
}
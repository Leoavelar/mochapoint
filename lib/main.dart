// Path: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Colors based on the Mocha Point logo
  static const Color darkGreen = Color(0xFF0A3029);
  static const Color coffeeBean = Color(0xFFA6623A);
  static const Color lightBackground = Color(0xFFF8F5F2);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'Mocha Point',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: darkGreen,
        scaffoldBackgroundColor: lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: GoogleFonts.montserratTextTheme(textTheme).copyWith(
          displayLarge: GoogleFonts.montserrat(
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: GoogleFonts.montserrat(
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.montserrat(
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: GoogleFonts.montserrat(
            color: darkGreen,
          ),
          bodyLarge: GoogleFonts.montserrat(
            color: darkGreen,
          ),
          bodyMedium: GoogleFonts.montserrat(
            color: darkGreen,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeBean,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: darkGreen,
          secondary: coffeeBean,
          surface: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
// lib/main.dart - Alternative solution with prebuilt screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.printConfig();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Colors based on the updated design
  static const Color coffeeBean = Color(0xFFA6623A); // Brown for coffee bean
  static const Color background = Color(0xFFFAF9F2); // Light cream background

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.enableDebugFeatures,
      theme: ThemeData(
        primaryColor: coffeeBean,
        scaffoldBackgroundColor: background,
        fontFamily: 'ClashDisplay',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          displayMedium: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: Colors.black,
          ),
          bodyLarge: TextStyle(
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            color: Colors.black,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeBean,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: coffeeBean,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: coffeeBean,
          secondary: coffeeBean,
          surface: Colors.white,
          background: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
      // Add routes for better navigation handling
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  Widget? _nextScreen; // Store the next screen
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Determine next screen immediately
    _loadNextScreen();

    // Fade animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Show splash for 3 seconds, then fade out
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          if (mounted) {
            setState(() {
              _showSplash = false;
            });
          }
        });
      }
    });
  }

  Future<void> _loadNextScreen() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (mounted) {
      setState(() {
        _nextScreen = isLoggedIn ? const HomeScreen() : const LoginScreen();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen with fade animation
    if (_showSplash) {
      return Stack(
        children: [
          // Background color layer (cream)
          Container(
            color: const Color(0xFFF9F5F1),
          ),
          // Splash screen with fade
          FadeTransition(
            opacity: _fadeAnimation,
            child: const SplashScreen(),
          ),
        ],
      );
    }

    // Show the preloaded next screen (no loading state)
    return _nextScreen ?? Container(color: const Color(0xFFF9F5F1));
  }
}
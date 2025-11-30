// lib/main.dart
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

  static const Color coffeeBean = Color(0xFF6A2801);
  static const Color lightCream = Color(0xFFF5E6D3);
  static const Color coffeeFroth = Color(0xFF94511A);
  static const Color coffeeAccent = Color(0xFFD85C27);
  static const Color coffeeGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.enableDebugFeatures,
      theme: ThemeData(
        primaryColor: coffeeBean,
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Poppins',
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
      home: const GradientBackground(
        child: AuthWrapper(),
      ),
      routes: {
        '/login': (context) => const GradientBackground(child: LoginScreen()),
        '/home': (context) => const GradientBackground(child: HomeScreen()),
      },
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // colors: [
          //   Color(0xFFE1CFC0),
          //   Color(0xFFF1E7DD),
          // ],
          colors: [
            Color(0xFFE4E4E4),
            Color(0xFFE4E4E4),
          ],
        ),
      ),
      child: child,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with SingleTickerProviderStateMixin {
  bool _showSplash = false;
  Widget? _nextScreen;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _loadNextScreen();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

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
    if (_showSplash) {
      return Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF7F3F0),
                  Color(0xFFF6F0EB),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: const SplashScreen(),
          ),
        ],
      );
    }

    return _nextScreen ?? Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7F3F0),
            Color(0xFFF6F0EB),
          ],
        ),
      ),
    );
  }
}
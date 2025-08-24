// lib/config/app_config.dart - Fixed version
class AppConfig {
  static const String _prodApiUrl = 'https://mochapoint.coffee/api';
  static const String _devApiUrl = 'http://192.168.1.109:8000/api';

  // FIXED: Environment detection using dart-define
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

  // Print current configuration (useful for debugging)
  static void printConfig() {
    print('🔧 AppConfig:');
    print('   Environment: ${isDevelopment ? 'Development' : 'Production'}');
    print('   Current Environment Value: $_environment');
    print('   API Base URL: $apiBaseUrl');
    print('   Debug Features: $enableDebugFeatures');
    print('   Logging Enabled: $enableLogging');
    print('   Analytics: $enableAnalytics');
  }
}
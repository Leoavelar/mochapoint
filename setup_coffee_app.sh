#!/bin/bash

# Coffee Subscription App Setup Script
# This script creates the file structure for the Flutter coffee subscription app

echo "Creating Coffee Subscription App file structure..."

# Create root directories
mkdir -p lib/config
mkdir -p lib/core/services
mkdir -p lib/core/models
mkdir -p lib/core/utils
mkdir -p lib/features/auth/screens
mkdir -p lib/features/auth/widgets
mkdir -p lib/features/auth/providers
mkdir -p lib/features/home/screens
mkdir -p lib/features/home/widgets
mkdir -p lib/features/home/providers
mkdir -p lib/features/map/screens
mkdir -p lib/features/map/widgets
mkdir -p lib/features/map/providers
mkdir -p lib/features/history/screens
mkdir -p lib/features/history/widgets
mkdir -p lib/features/history/providers
mkdir -p lib/features/profile/screens
mkdir -p lib/features/profile/widgets
mkdir -p lib/features/profile/providers
mkdir -p lib/shared/widgets
mkdir -p lib/shared/styles
mkdir -p lib/shared/animations

# Create main files
touch lib/main.dart
touch lib/app.dart

# Create config files
touch lib/config/routes.dart
touch lib/config/theme.dart
touch lib/config/constants.dart

# Create core model files
touch lib/core/models/user.dart
touch lib/core/models/coffee_shop.dart
touch lib/core/models/subscription.dart
touch lib/core/models/redemption.dart

# Create core service files
touch lib/core/services/auth_service.dart
touch lib/core/services/subscription_service.dart
touch lib/core/services/redemption_service.dart
touch lib/core/services/location_service.dart
touch lib/core/services/analytics_service.dart

# Create core utils files
touch lib/core/utils/date_utils.dart
touch lib/core/utils/qr_generator.dart
touch lib/core/utils/network_utils.dart

# Create auth feature files
touch lib/features/auth/screens/login_screen.dart
touch lib/features/auth/screens/register_screen.dart
touch lib/features/auth/screens/forgot_password_screen.dart
touch lib/features/auth/widgets/auth_header.dart
touch lib/features/auth/widgets/auth_button.dart
touch lib/features/auth/providers/auth_provider.dart

# Create home feature files
touch lib/features/home/screens/home_screen.dart
touch lib/features/home/widgets/qr_code_widget.dart
touch lib/features/home/widgets/nearby_shops_widget.dart
touch lib/features/home/widgets/daily_recommendation_widget.dart
touch lib/features/home/providers/home_provider.dart

# Create map feature files
touch lib/features/map/screens/map_screen.dart
touch lib/features/map/widgets/coffee_shop_sheet.dart
touch lib/features/map/widgets/coffee_shop_list_item.dart
touch lib/features/map/providers/map_provider.dart

# Create history feature files
touch lib/features/history/screens/history_screen.dart
touch lib/features/history/screens/stats_screen.dart
touch lib/features/history/widgets/redemption_card.dart
touch lib/features/history/widgets/calendar_widget.dart
touch lib/features/history/providers/history_provider.dart

# Create profile feature files
touch lib/features/profile/screens/profile_screen.dart
touch lib/features/profile/screens/edit_profile_screen.dart
touch lib/features/profile/screens/settings_screen.dart
touch lib/features/profile/widgets/settings_tile.dart
touch lib/features/profile/widgets/subscription_card.dart
touch lib/features/profile/providers/profile_provider.dart

# Create shared widgets
touch lib/shared/widgets/coffee_card.dart
touch lib/shared/widgets/subscription_badge.dart
touch lib/shared/widgets/loading_indicator.dart
touch lib/shared/widgets/custom_app_bar.dart
touch lib/shared/widgets/custom_button.dart

# Create shared styles
touch lib/shared/styles/text_styles.dart
touch lib/shared/styles/colors.dart

# Create shared animations
touch lib/shared/animations/page_transitions.dart
touch lib/shared/animations/loading_animations.dart

# Update pubspec.yaml to include necessary dependencies
cat > pubspec.yaml << 'EOL'
name: coffee_subscription
description: A coffee subscription app for redeeming daily coffee.

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  google_maps_flutter: ^2.5.0
  qr_flutter: ^4.1.0
  intl: ^0.18.1
  provider: ^6.0.5
  http: ^1.1.0
  shared_preferences: ^2.2.2
  url_launcher: ^6.1.14
  flutter_secure_storage: ^9.0.0
  table_calendar: ^3.0.9
  geolocator: ^10.1.0
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
EOL

# Create assets directories
mkdir -p assets/images
mkdir -p assets/icons

echo "File structure created successfully!"
echo "Don't forget to run 'flutter pub get' to install dependencies."
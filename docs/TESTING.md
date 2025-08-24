#### Test Enhanced Stats Card Widget
```dart
// test/enhanced_stats_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocha_point/widgets/coffee_stats_card.dart';

void main() {
  testWidgets('Stats card shows "Remaining" instead of "Available"', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CoffeeStatsCard(
        fallbackRemainingCount: 12, // Updated from fallbackAvailableCount
        fallbackMonth: 'January 2025',
        fallbackRedeemedCount: 8,
        fallbackJokersCount: 3,
      )
    ));

    // Should show "Remaining" not "Available"
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Available'), findsNothing);
    
    // Should show remaining count
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('Stats card shows subscription plan name when available', (WidgetTester tester) async {
    // Mock monthly stats with plan name
    await tester.pumpWidget(MaterialApp(home: CoffeeStatsCard()));
    
    // Wait for async load
    await tester.pumpAndSettle();
    
    // Should show plan name if subscription is active
    expect(find.text('Premium Monthly Plan'), findsOneWidget);
  });

  testWidgets('Stats card shows grey icon when no remaining redemptions', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CoffeeStatsCard(
        fallbackRemainingCount: 0, // No remaining redemptions
      )
    ));

    await tester.pumpAndSettle();
    
    // Icon should be grey when no redemptions remaining
    final iconFinder = find.byIcon(Icons.coffee);
    expect(iconFinder, findsOneWidget);
    
    final Icon icon = tester.widget(iconFinder);
    expect(icon.color, equals(Colors.grey));
  });
}
```

#### Test Environment Configuration ⭐ NEW
```dart
// test/environment_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocha_point/config/app_config.dart';

void main() {
  group('AppConfig Environment Tests', () {
    test('Should detect development environment correctly', () {
      // This would need to be run with --dart-define=ENVIRONMENT=development
      expect(AppConfig.isDevelopment, isTrue);
      expect(AppConfig.enableLogging, isTrue);
      expect(AppConfig.apiTimeout.inSeconds, equals(30));
    });

    test('Should use correct API URLs for each environment', () {
      // Test development URL
      if (AppConfig.isDevelopment) {
        expect(AppConfig.apiBaseUrl, contains('192.168.1.109:8000'));
      }
      
      // Test production URL
      if (AppConfig.isProduction) {
        expect(AppConfig.apiBaseUrl, equals('https://mochapoint.coffee/api'));
      }
    });

    test('Should have appropriate timeout settings', () {
      if (AppConfig.isDevelopment) {
        expect(AppConfig.apiTimeout.inSeconds, equals(30));
      } else {
        expect(AppConfig.apiTimeout.inSeconds, equals(10));
      }
    });
  });
}
```

#### Test Enhanced Session Management ⭐ NEW
```dart
// test/session_management_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocha_point/services/auth_service.dart';

void main() {
  group('Enhanced Session Management', () {
    testWidgets('Should show session expired dialog on TOKEN_EXPIRED', (WidgetTester tester) async {
      // Mock expired token response
      // Test that session expired dialog appears
      // Verify navigation to login screen
    });

    test('Should detect session expiry correctly', () async {
      // Mock TOKEN_EXPIRED response from API
      final result = await AuthService.isAuthenticatedDetailed();
      
      expect(result.isValid, isFalse);
      expect(result.isExpired, isTrue);
    });

    test('Should clear token on session expiry', () async {
      // Mock expired token
      // Call AuthService method that triggers session expiry
      // Verify token is cleared from storage
      final token = await AuthService.getToken();
      expect(token, isNull);
    });
  });
}
```

### Device Testing Matrix ⭐ UPDATED

#### Android Testing
| Device Type | Screen Size | Android Version | Environment | Status |
|-------------|-------------|-----------------|-------------|---------|
| Phone | Small (5") | Android 10+ | Development | ✅ |
| Phone | Medium (6") | Android 11+ | Development | ✅ |
| Phone | Large (6.5"+) | Android 12+ | Development | ✅ |
| Phone | Medium (6") | Android 11+ | Production | ✅ |
| Tablet | 7-10" | Android 11+ | Development | 🚧 |

#### iOS Testing
| Device Type | Screen Size | iOS Version | Environment | Status |
|-------------|-------------|-------------|-------------|---------|
| iPhone SE | Small | iOS 14+ | Development | ✅ |
| iPhone 13/14 | Standard | iOS 15+ | Development | ✅ |
| iPhone Pro Max | Large | iOS 16+ | Development | ✅ |
| iPhone 13/14 | Standard | iOS 15+ | Production | ✅ |
| iPad | Tablet | iOS 14+ | Development | 🚧 |

---

## Environment Testing

### Environment Configuration Testing ⭐ NEW

#### Development Environment Testing
```bash
# Test development configuration
flutter run --dart-define=ENVIRONMENT=development

# Verify console output
# Expected: "Environment: Development"
# Expected: "API Base URL: http://192.168.1.109:8000/api"
# Expected: "Debug Features: true"
```

**Test Checklist:**
- [ ] **Console Logging**: Debug messages appear in console
- [ ] **API URL**: Uses local development URL
- [ ] **Timeouts**: 30-second API timeouts
- [ ] **Debug Features**: Debug buttons/features visible
- [ ] **Network Calls**: Can connect to local backend

#### Production Environment Testing
```bash
# Test production configuration
flutter run --dart-define=ENVIRONMENT=production

# Verify console output  
# Expected: "Environment: Production"
# Expected: "API Base URL: https://mochapoint.coffee/api"
# Expected: "Debug Features: false"
```

**Test Checklist:**
- [ ] **Console Logging**: Minimal/no debug messages
- [ ] **API URL**: Uses production URL
- [ ] **Timeouts**: 10-second API timeouts
- [ ] **Debug Features**: Debug buttons/features hidden
- [ ] **Network Calls**: Can connect to production backend
- [ ] **Performance**: Optimized for production use

#### Environment Switching Testing ⭐ NEW
```bash
# Test switching between environments
flutter run --dart-define=ENVIRONMENT=development
# Stop app
flutter run --dart-define=ENVIRONMENT=production

# Verify environment changes without app rebuild
# Check API calls go to correct endpoints
# Verify different timeout behaviors
```

#### Build Testing by Environment
```bash
# Development build
flutter build apk --dart-define=ENVIRONMENT=development

# Production build  
flutter build apk --release --dart-define=ENVIRONMENT=production

# Verify APK uses correct configuration for each environment
```

---

## Integration Testing

### Enhanced Complete User Journey Testing ⭐ UPDATED

#### User Registration → Enhanced First Redemption
```bash
#!/bin/bash
# enhanced_integration_test.sh

echo "=== Enhanced Integration Test: User Journey ==="

# 1. Register user
echo "1. Registering user..."
USER_RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "integration@test.com",
    "password": "testpass123"
  }')

USER_TOKEN=$(echo $USER_RESPONSE | jq -r '.token')
echo "User registered, 30-day token: ${USER_TOKEN:0:20}..."

# 2. Check initial monthly stats
echo "2. Checking initial monthly stats..."
STATS_RESPONSE=$(curl -s -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN")

REMAINING_INITIAL=$(echo $STATS_RESPONSE | jq -r '.data.subscription.remainingMonthly')
echo "Initial remaining redemptions: $REMAINING_INITIAL"

# 3. Generate QR with monthly limit checking
echo "3. Generating QR token with monthly limit..."
QR_RESPONSE=$(curl -s -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}')

QR_TOKEN=$(echo $QR_RESPONSE | jq -r '.qrToken')
echo "QR generated: ${QR_TOKEN:0:20}..."

# 4. Register coffee shop
echo "4. Registering coffee shop..."
SHOP_RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/register-coffee-shop \
  -H "Content-Type: application/json" \
  -d '{
    "email": "shoptest@test.com",
    "password": "shoppass123",
    "shopName": "Integration Test Shop",
    "address": "Test Street 123"
  }')

SHOP_TOKEN=$(echo $SHOP_RESPONSE | jq -r '.token')
echo "Shop registered, 30-day token: ${SHOP_TOKEN:0:20}..."

# 5. Process redemption
echo "5. Processing redemption..."
REDEMPTION_RESPONSE=$(curl -s -X POST http://localhost:8000/api/redemptions/validate-and-redeem \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "qrToken": "'$QR_TOKEN'",
    "coffeeType": "Integration Test Coffee"
  }')

REMAINING_AFTER=$(echo $REDEMPTION_RESPONSE | jq -r '.customer.subscriptionInfo.remainingMonthly')
echo "Redemption result - Remaining after: $REMAINING_AFTER"

# 6. Check updated monthly stats
echo "6. Checking updated monthly statistics..."
FINAL_STATS_RESPONSE=$(curl -s -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN")

FINAL_REMAINING=$(echo $FINAL_STATS_RESPONSE | jq -r '.data.subscription.remainingMonthly')
FINAL_REDEEMED=$(echo $FINAL_STATS_RESPONSE | jq -r '.data.redeemed.subscription')

echo "Final stats:"
echo "  - Remaining: $FINAL_REMAINING"
echo "  - Subscription redeemed: $FINAL_REDEEMED"

# 7. Test joker redemption doesn't affect subscription count
echo "7. Testing joker redemption separation..."
JOKER_QR_RESPONSE=$(curl -s -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "joker"}')

JOKER_TOKEN=$(echo $JOKER_QR_RESPONSE | jq -r '.qrToken')

curl -s -X POST http://localhost:8000/api/redemptions/validate-and-redeem \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "qrToken": "'$JOKER_TOKEN'",
    "coffeeType": "Joker Coffee"
  }' > /dev/null

# Check stats after joker redemption
JOKER_STATS_RESPONSE=$(curl -s -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN")

JOKER_REMAINING=$(echo $JOKER_STATS_RESPONSE | jq -r '.data.subscription.remainingMonthly')
TOTAL_REDEEMED=$(echo $JOKER_STATS_RESPONSE | jq -r '.data.redeemed.total')
JOKER_REDEEMED=$(echo $JOKER_STATS_RESPONSE | jq -r '.data.redeemed.joker')

echo "After joker redemption:"
echo "  - Subscription remaining: $JOKER_REMAINING (should be same as before)"
echo "  - Total redeemed: $TOTAL_REDEEMED"
echo "  - Joker redeemed: $JOKER_REDEEMED"

# 8. Test session expiry simulation
echo "8. Testing session expiry detection..."
EXPIRED_RESPONSE=$(curl -s -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer invalid-expired-token")

ERROR_CODE=$(echo $EXPIRED_RESPONSE | jq -r '.errorCode')
echo "Session expiry test - Error code: $ERROR_CODE"

echo "=== Enhanced Integration Test Complete ==="
```

### Cross-Platform Environment Testing ⭐ NEW

#### Flutter Integration Tests with Environment
```dart
// integration_test/environment_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocha_point/main.dart' as app;
import 'package:mocha_point/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Environment Integration Tests', () {
    testWidgets('App uses correct environment configuration', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test splash screen shows environment info (in development)
      if (AppConfig.isDevelopment) {
        expect(find.text('Development'), findsOneWidget);
      }
      
      // Wait for navigation
      await tester.pumpAndSettle(Duration(seconds: 4));

      // Test login screen appears
      expect(find.text('Login'), findsOneWidget);
      
      // Test API calls use correct base URL
      // This would require mocking or actual API testing
    });

    testWidgets('Session expiry triggers correct flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate through app to trigger API call with expired token
      // Verify session expired dialog appears
      // Verify navigation to login screen
      
      // This test would require mocking expired token responses
    });

    testWidgets('Monthly stats show remaining count correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(Duration(seconds: 4));

      // Login as test user
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Navigate to home and check stats card
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Available'), findsNothing);
    });
  });
}
```

---

## End-to-End Testing

### Enhanced Complete Redemption Workflow ⭐ UPDATED

#### Test Scenario: Subscription Redemption with Monthly Limits
1. **Setup**: User with active subscription (25 monthly limit), Coffee shop with QR scanner
2. **Action**: User generates subscription QR, shop scans and validates
3. **Verification**:
    - Redemption recorded as subscription type
    - Monthly remaining count decreases by 1
    - Statistics updated correctly
    - User notified of successful redemption

#### Test Scenario: Monthly Limit Enforcement
1. **Setup**: User who has reached monthly subscription limit (25/25)
2. **Action**: Attempt to generate another subscription QR
3. **Verification**:
    - Error message: "Monthly subscription limit reached"
    - Next available date shown (next month)
    - QR generation fails
    - User can still generate joker QR

#### Test Scenario: Joker vs Subscription Separation
1. **Setup**: User with 10 subscription redemptions and 5 joker redemptions this month
2. **Action**: Check monthly stats display
3. **Verification**:
    - Total redeemed: 15
    - Subscription redeemed: 10 (counts against monthly limit)
    - Joker redeemed: 5 (doesn't count against monthly limit)
    - Remaining monthly: 15 (25 - 10 subscription redemptions)

#### Test Scenario: Enhanced Session Expiry
1. **Setup**: User with expired 30-day JWT token
2. **Action**: Attempt to access any authenticated endpoint
3. **Verification**:
    - Receives TOKEN_EXPIRED error code
    - Session expired dialog appears with orange styling
    - User redirected to login screen
    - Stored token cleared from app

#### Test Scenario: Environment Switching
1. **Setup**: App running in development environment
2. **Action**: Switch to production environment and restart
3. **Verification**:
    - API calls go to production URL
    - Debug logging disabled
    - Shorter API timeouts applied
    - UI performance optimized

### Multi-Device Environment Testing ⭐ UPDATED

#### Same User, Multiple Environments
```bash
# Test user consistency across environments
# Device 1: Development environment - generate QR
# Device 2: Production environment - check same user stats
# Device 3: Development environment - verify consistency
```

#### Concurrent Redemptions with Monthly Limits
```bash
# Test race conditions with monthly limit enforcement
# Multiple users attempting to redeem when limit is near maximum
# Should handle concurrent requests correctly
# Monthly limit enforcement should be atomic
```

---

## Performance Testing

### Enhanced API Load Testing ⭐ UPDATED

#### Using Artillery with Subscription Endpoints
```yaml
# enhanced_artillery_config.yml
config:
  target: 'http://localhost:8000'
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - name: "Enhanced API Load Test"
    requests:
      - get:
          url: "/health"
      - post:
          url: "/api/auth/login"
          json:
            email: "test@example.com"
            password: "password123"
      - get:
          url: "/api/redemptions/monthly-stats"
          headers:
            Authorization: "Bearer {{ token }}"
      - get:
          url: "/api/users/subscription"
          headers:
            Authorization: "Bearer {{ token }}"
      - post:
          url: "/api/redemptions/generate-qr"
          headers:
            Authorization: "Bearer {{ token }}"
          json:
            redemptionType: "subscription"
```

```bash
# Run enhanced load test
npm install -g artillery
artillery run enhanced_artillery_config.yml
```

#### Subscription System Load Testing
```bash
# Test monthly limit calculations under load
for i in {1..100}; do
  curl -s http://localhost:8000/api/redemptions/monthly-stats \
    -H "Authorization: Bearer $USER_TOKEN" > /dev/null &
done
wait

# Test QR generation with monthly limit checking
for i in {1..50}; do
  curl -s -X POST http://localhost:8000/api/redemptions/generate-qr \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"redemptionType": "subscription"}' > /dev/null &
done
wait

echo "Load tests completed - check server performance"
```

### Enhanced Mobile App Performance ⭐ UPDATED

#### Flutter Performance Testing with Environment
```dart
// test/performance_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocha_point/config/app_config.dart';

void main() {
  testWidgets('Enhanced stats card loads within environment-specific timeout', (WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(MaterialApp(home: CoffeeStatsCard()));
    await tester.pumpAndSettle();

    stopwatch.stop();
    
    // Different expectations based on environment
    if (AppConfig.isDevelopment) {
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // More lenient in dev
    } else {
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // Stricter in prod
    }
  });

  testWidgets('Environment configuration loads instantly', (WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();
    
    // Test AppConfig initialization
    final apiUrl = AppConfig.apiBaseUrl;
    final isLoggingEnabled = AppConfig.enableLogging;
    
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(10)); // Should be instant
    expect(apiUrl, isNotEmpty);
    expect(isLoggingEnabled, isA<bool>());
  });
}
```

#### Environment-Specific Performance Benchmarks
```bash
# Development environment - more lenient
flutter run --dart-define=ENVIRONMENT=development --profile
# Expected: Slower startup, more logging, debug features

# Production environment - optimized  
flutter run --dart-define=ENVIRONMENT=production --profile
# Expected: Faster startup, minimal logging, optimized performance
```

### Enhanced Database Performance Testing ⭐ UPDATED

#### Subscription System Query Performance
```sql
-- Test enhanced monthly stats query performance
EXPLAIN ANALYZE
SELECT 
  COUNT(*) as total_redemptions,
  COUNT(*) FILTER (WHERE redemption_type = 'subscription') as subscription_count,
  COUNT(*) FILTER (WHERE redemption_type = 'joker') as joker_count
FROM redemptions 
WHERE user_id = 1 
  AND timestamp >= date_trunc('month', CURRENT_DATE)
  AND timestamp < date_trunc('month', CURRENT_DATE) + interval '1 month';

-- Test subscription plan query performance  
EXPLAIN ANALYZE
SELECT sp.*, us.status 
FROM subscription_plans sp
JOIN user_subscriptions us ON sp.id = us.plan_id
WHERE us.user_id = 1 AND us.status = 'active';

-- Test monthly limit calculation performance
EXPLAIN ANALYZE
SELECT 
  sp.monthly_coffee_limit,
  COALESCE(COUNT(r.id) FILTER (WHERE r.redemption_type = 'subscription'), 0) as used_this_month,
  sp.monthly_coffee_limit - COALESCE(COUNT(r.id) FILTER (WHERE r.redemption_type = 'subscription'), 0) as remaining
FROM user_subscriptions us
JOIN subscription_plans sp ON us.plan_id = sp.id  
LEFT JOIN redemptions r ON r.user_id = us.user_id 
  AND r.timestamp >= date_trunc('month', CURRENT_DATE)
  AND r.timestamp < date_trunc('month', CURRENT_DATE) + interval '1 month'
WHERE us.user_id = 1 AND us.status = 'active'
GROUP BY sp.monthly_coffee_limit;
```

---

## Security Testing

### Enhanced Authentication Security ⭐ UPDATED

#### JWT Token Testing with 30-day Expiry
```bash
# Test enhanced token lifecycle
# 1. Generate 30-day token
TOKEN_RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}')

TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.token')

# 2. Decode and verify 30-day expiry
# Visit https://jwt.io and paste token
# Verify 'exp' claim shows 30 days from now (current_time + 2592000 seconds)

# 3. Test token validation over time
# Day 1: Should work
curl -X GET http://localhost:8000/api/users/profile \
  -H "Authorization: Bearer $TOKEN"

# Day 29: Should still work  
# Day 31: Should return TOKEN_EXPIRED with errorCode

# 4. Test session expiry detection
curl -X GET http://localhost:8000/api/users/profile \
  -H "Authorization: Bearer expired-token-here"

# Expected response:
# {
#   "success": false,
#   "error": "Token has expired", 
#   "errorCode": "TOKEN_EXPIRED"
# }
```

#### Enhanced OAuth Security Testing
```bash
# Test Google OAuth with enhanced session management
curl -X POST http://localhost:8000/api/auth/google \
  -H "Content-Type: application/json" \
  -d '{
    "googleId": "test-google-id",
    "email": "test@gmail.com",
    "accessToken": "valid-google-token"
  }'

# Should return 30-day JWT token
# Test Apple Sign-In with enhanced session
curl -X POST http://localhost:8000/api/auth/apple \
  -H "Content-Type: application/json" \
  -d '{
    "appleId": "test-apple-id", 
    "email": "test@privaterelay.appleid.com",
    "identityToken": "valid-apple-token"
  }'

# Should return 30-day JWT token
```

#### Enhanced QR Security Testing
```bash
# Test QR code security with monthly limits
# 1. Generate QR with monthly limit checking
QR_RESPONSE=$(curl -s -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}')

QR_TOKEN=$(echo $QR_RESPONSE | jq -r '.qrToken')

# 2. Test replay attack prevention
# Try to use same QR token twice
curl -X POST http://localhost:8000/api/redemptions/validate-and-redeem \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"qrToken": "'$QR_TOKEN'"}'

# First use: Should succeed
# Second use: Should fail with "QR code already used"

# 3. Test QR expiry (daily)
# Generate QR today, try to use tomorrow
# Should fail with "Invalid or expired QR code"

# 4. Test monthly limit security
# User with 25/25 monthly redemptions tries to generate QR
# Should fail with "Monthly subscription limit reached"
```

### Enhanced Input Validation Testing ⭐ UPDATED

#### SQL Injection Testing with Subscription System
```bash
# Test subscription plan queries for SQL injection
curl -X GET http://localhost:8000/api/users/subscription \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Malicious-Input: '; DROP TABLE subscription_plans; --"

# Should not affect database

# Test monthly stats with malicious input
curl -X GET "http://localhost:8000/api/redemptions/monthly-stats?month='; DROP TABLE redemptions; --" \
  -H "Authorization: Bearer $TOKEN"

# Should return validation error, not SQL error
```

#### Enhanced XSS Testing
```bash
# Test coffee shop creation with script injection
curl -X POST http://localhost:8000/api/coffee-shops \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<script>alert(\"xss\")</script>Coffee Shop",
    "description": "<img src=x onerror=alert(\"xss\")>",
    "address": "Test Address"
  }'

# Should sanitize input and not execute scripts
```

#### Session Management Security ⭐ NEW
```bash
# Test session fixation prevention
# 1. Get initial token
TOKEN1=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}' | jq -r '.token')

# 2. Login again  
TOKEN2=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}' | jq -r '.token')

# Tokens should be different (new session each login)
echo "Token 1: ${TOKEN1:0:20}..."
echo "Token 2: ${TOKEN2:0:20}..."

# Test concurrent session handling
# Both tokens should work simultaneously (stateless JWT)
curl -X GET http://localhost:8000/api/users/profile \
  -H "Authorization: Bearer $TOKEN1" &

curl -X GET http://localhost:8000/api/users/profile \
  -H "Authorization: Bearer $TOKEN2" &

wait
```

---

## Automated Testing

### Enhanced GitHub Actions Workflow ⭐ UPDATED
```yaml
# .github/workflows/enhanced_test.yml
name: Enhanced Test Suite

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: mocha_point_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          cd backend
          npm ci

      - name: Run enhanced tests
        run: |
          cd backend
          npm test
        env:
          DB_HOST: localhost
          DB_PORT: 5432
          DB_NAME: mocha_point_test
          DB_USER: postgres
          DB_PASSWORD: postgres
          JWT_SECRET: test-secret-256-chars-long
          JWT_EXPIRY: 30d

      - name: Test subscription system
        run: |
          cd backend
          npm run test:subscription

      - name: Test session management
        run: |
          cd backend
          npm run test:session

  frontend-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [development, production]
    
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: |
          cd frontend
          flutter pub get

      - name: Run environment-specific tests
        run: |
          cd frontend
          flutter test --dart-define=ENVIRONMENT=${{ matrix.environment }}

      - name: Test environment configuration
        run: |
          cd frontend
          flutter test test/environment_config_test.dart \
            --dart-define=ENVIRONMENT=${{ matrix.environment }}

      - name: Run enhanced widget tests
        run: |
          cd frontend
          flutter test test/enhanced_stats_card_test.dart \
            --dart-define=ENVIRONMENT=${{ matrix.environment }}

  integration-tests:
    runs-on: ubuntu-latest
    needs: [backen# Testing Guide

> Comprehensive testing procedures and validation for MochaPoint platform

## 📋 Table of Contents
- [Testing Overview](#testing-overview)
- [Backend API Testing](#backend-api-testing)
- [Frontend Testing](#frontend-testing)
- [Environment Testing](#environment-testing)
- [Integration Testing](#integration-testing)
- [End-to-End Testing](#end-to-end-testing)
- [Performance Testing](#performance-testing)
- [Security Testing](#security-testing)
- [Automated Testing](#automated-testing)

---

## Testing Overview

### Enhanced Testing Strategy ⭐ UPDATED
- **Unit Tests**: Individual component testing
- **Integration Tests**: API endpoint testing with subscription system
- **E2E Tests**: Complete user workflow testing including session management
- **Manual Tests**: User experience validation across environments
- **Performance Tests**: Load and stress testing with subscription features
- **Security Tests**: Authentication and authorization validation (30-day JWT)
- **Environment Tests**: Development/production configuration validation

### Enhanced Test Environment Setup ⭐ UPDATED
```bash
# Backend test server
cd backend
npm run dev

# Frontend test app (development environment)
cd frontend
flutter run --dart-define=ENVIRONMENT=development

# Frontend test app (production environment) 
flutter run --dart-define=ENVIRONMENT=production

# Test database (optional)
createdb mocha_point_test
```

---

## Backend API Testing

### Prerequisites
```bash
# Install testing tools
npm install -g newman  # Postman CLI
# OR use curl for manual testing
```

### Enhanced Authentication Flow Testing ⭐ UPDATED

#### 1. User Registration with Extended JWT
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "testpassword123"
  }'
```

**Expected Response (201):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // 30-day expiry
  "user": {
    "id": 1,
    "email": "testuser@example.com",
    "role": "user",
    "jokerCount": 3
  }
}
```

**Test JWT Expiry:**
```bash
# Decode token at https://jwt.io
# Verify exp claim shows 30 days from now (2592000 seconds)
```

#### 2. Enhanced User Login Testing
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "testpassword123"
  }'
```

#### 3. Session Expiry Testing ⭐ NEW
```bash
# Test with expired token
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer expired-token-here"

# Expected Response (401):
# {
#   "success": false,
#   "error": "Token has expired",
#   "errorCode": "TOKEN_EXPIRED"
# }
```

#### 4. Coffee Shop Registration
```bash
curl -X POST http://localhost:8000/api/auth/register-coffee-shop \
  -H "Content-Type: application/json" \
  -d '{
    "email": "shop@example.com",
    "password": "shoppassword123",
    "shopName": "Test Coffee Shop",
    "address": "Test Street 123, 8010 Graz"
  }'
```

#### 5. Admin Creation
```bash
curl -X POST http://localhost:8000/api/auth/create-admin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@mochapoint.com",
    "password": "adminpassword123",
    "adminSecret": "your-admin-secret"
  }'
```

### Enhanced QR Redemption System Testing ⭐ UPDATED

#### 1. Test Redemption Status ⭐ NEW
```bash
# Save user token from login
export USER_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Check redemption status before QR generation
curl -X GET http://localhost:8000/api/redemptions/status \
  -H "Authorization: Bearer $USER_TOKEN"
```

**Expected Response (200):**
```json
{
  "success": true,
  "status": {
    "jokerCount": 3,
    "subscriptionInfo": {
      "hasSubscription": true,
      "bundleName": "Premium Monthly",
      "monthlyLimit": 25,
      "remainingMonthly": 17,
      "canRedeemSubscription": true
    },
    "canRedeemJoker": true
  }
}
```

#### 2. Generate QR Token with Monthly Limit Enforcement
```bash
# Generate subscription QR
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}'
```

**Expected Response (200) - With Remaining Credits:**
```json
{
  "success": true,
  "qrToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2025-01-15T23:59:59.999Z",
  "userInfo": {
    "name": "Test User",
    "email": "testuser@example.com",
    "subscriptionInfo": {
      "remainingMonthly": 16
    }
  }
}
```

**Expected Response (400) - Monthly Limit Reached:**
```json
{
  "success": false,
  "error": "Monthly subscription limit reached",
  "errorCode": "MONTHLY_LIMIT_REACHED",
  "nextAvailableAt": "2025-02-01T00:00:00.000Z"
}
```

#### 3. Validate QR Token (Coffee Shop)
```bash
# Save coffee shop token
export SHOP_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
export QR_TOKEN="qr-token-from-previous-step"

curl -X POST http://localhost:8000/api/redemptions/validate-and-redeem \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "qrToken": "'$QR_TOKEN'",
    "coffeeType": "Cappuccino"
  }'
```

**Expected Response - Enhanced with Remaining Count:**
```json
{
  "success": true,
  "customer": {
    "subscriptionInfo": {
      "remainingMonthly": 15
    }
  },
  "redemption": {
    "coffeeType": "Cappuccino"
  }
}
```

### Enhanced Monthly Statistics Testing ⭐ UPDATED

#### 1. Get Enhanced Monthly Stats
```bash
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN"
```

**Expected Response Structure:**
```json
{
  "success": true,
  "data": {
    "month": "January 2025",
    "subscription": {
      "hasActiveSubscription": true,
      "planName": "Premium Monthly Plan",
      "monthlyLimit": 25,
      "usedThisMonth": 8,
      "remainingMonthly": 17,
      "canRedeemSubscription": true
    },
    "redeemed": {
      "total": 10,
      "subscription": 8,
      "joker": 2
    },
    "available": {
      "jokers": 3
    }
  }
}
```

**Key Testing Points:**
- ✅ `remainingMonthly` = `monthlyLimit` - `subscription redemptions only`
- ✅ Joker redemptions don't count against subscription limit
- ✅ `total` = `subscription` + `joker` redemptions

#### 2. Test Subscription vs Joker Separation
```bash
# Redeem with joker
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "joker"}'

# Check stats - remainingMonthly should stay same
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN"

# Redeem with subscription  
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}'

# Check stats - remainingMonthly should decrease by 1
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN"
```

### Enhanced Subscription System Testing ⭐ NEW

#### 1. Test User Subscription Endpoint
```bash
curl -X GET http://localhost:8000/api/users/subscription \
  -H "Authorization: Bearer $USER_TOKEN"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "hasActiveSubscription": true,
    "subscription": {
      "planName": "Premium Monthly Plan",
      "monthlyLimit": 25,
      "usedThisMonth": 8,
      "status": "active"
    },
    "accessibleShops": [
      {
        "id": 1,
        "name": "Central Coffee Graz",
        "isSubscriptionAccessible": true
      }
    ]
  }
}
```

### Error Testing ⭐ UPDATED

#### 1. Enhanced Authentication Errors
```bash
# No token
curl -X GET http://localhost:8000/api/redemptions/monthly-stats

# Expected: 401 with errorCode: "TOKEN_MISSING"

# Invalid token  
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer invalid-token"

# Expected: 403 with errorCode: "TOKEN_INVALID"

# Expired token (simulate)
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer expired-token"

# Expected: 401 with errorCode: "TOKEN_EXPIRED"
```

#### 2. Enhanced QR Generation Errors
```bash
# Invalid redemption type
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "invalid"}'

# Expected: 400 with errorCode: "VALIDATION_FAILED"

# Test monthly limit enforcement
# (After user reaches monthly limit)
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}'

# Expected: 400 with errorCode: "MONTHLY_LIMIT_REACHED"
```

#### 3. Insufficient Permissions
```bash
# User trying to create coffee shop
curl -X POST http://localhost:8000/api/coffee-shops \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Shop"}'

# Expected: 403 with errorCode: "INSUFFICIENT_PERMISSIONS"
```

---

## Frontend Testing

### Enhanced Manual Testing Checklist ⭐ UPDATED

#### Environment Configuration Testing ⭐ NEW
- [ ] **Development Environment**: App shows correct dev API URL in console
- [ ] **Production Environment**: App shows correct prod API URL in console
- [ ] **Environment Switching**: Can switch between dev/prod with dart-define
- [ ] **Debug Logging**: Only shows in development environment
- [ ] **API Timeouts**: Longer timeouts in development vs production

#### Authentication Flow
- [ ] **Splash Screen**: Shows for 3 seconds, then navigates
- [ ] **Registration**: Email validation, password requirements
- [ ] **Login**: Successful authentication, 30-day token storage
- [ ] **Google Sign-In**: OAuth flow works correctly
- [ ] **Auto-Login**: Remembers user between app restarts (30-day token)
- [ ] **Session Expiry**: Shows session expired dialog on token expiry
- [ ] **Auto-Logout**: Automatically logs out on session expiry

#### Home Screen (User) ⭐ UPDATED
- [ ] **Statistics Card**: Loads monthly stats showing "Remaining" count
- [ ] **Remaining Count**: Shows subscription redemptions left (not total available)
- [ ] **Loading State**: Shows progress indicators
- [ ] **Error Handling**: Retry button appears on network errors
- [ ] **Session Expiry**: Shows session expired dialog instead of generic error
- [ ] **QR Generation**: Modal opens when tapping center button
- [ ] **Coffee Shops List**: Shows nearby shops with subscription highlighting

#### Enhanced QR System ⭐ UPDATED
- [ ] **QR Generation**: Creates valid QR codes with monthly limit checking
- [ ] **Monthly Limit**: Prevents QR generation when monthly limit reached
- [ ] **QR Display**: Shows user info, remaining count, and expiration
- [ ] **QR Scanner**: Scans and validates codes successfully
- [ ] **Redemption Flow**: Complete user-to-shop workflow
- [ ] **Error Messages**: Clear feedback for invalid/expired codes
- [ ] **Session Handling**: Proper session expired messages in QR modal

#### Coffee Shop Dashboard ⭐ UPDATED
- [ ] **Analytics Display**: Shows real-time statistics
- [ ] **Scanner Interface**: Camera opens and scans QR codes
- [ ] **Customer Info**: Displays customer details with remaining count
- [ ] **Statistics Updates**: Live updates after redemptions
- [ ] **Session Management**: Handles session expiry gracefully

#### Navigation & UI
- [ ] **Role-based Navigation**: Different UI for users vs shop owners
- [ ] **Environment Indicators**: Can identify current environment (dev/prod)
- [ ] **Smooth Transitions**: No lag between screens
- [ ] **Responsive Design**: Works on different screen sizes
- [ ] **Session Expiry Dialog**: Orange styling, clear messaging, navigation to login

### Enhanced Flutter Widget Testing ⭐ UPDATED

#### Test Enhanced Stats Card Widget
```dart
// test/enhanced_stats_card_test
# Testing Guide

> Comprehensive testing procedures and validation for MochaPoint platform

## 📋 Table of Contents
- [Testing Overview](#testing-overview)
- [Backend API Testing](#backend-api-testing)
- [Frontend Testing](#frontend-testing)
- [Integration Testing](#integration-testing)
- [End-to-End Testing](#end-to-end-testing)
- [Performance Testing](#performance-testing)
- [Security Testing](#security-testing)
- [Automated Testing](#automated-testing)

---

## Testing Overview

### Testing Strategy
- **Unit Tests**: Individual component testing
- **Integration Tests**: API endpoint testing
- **E2E Tests**: Complete user workflow testing
- **Manual Tests**: User experience validation
- **Performance Tests**: Load and stress testing
- **Security Tests**: Authentication and authorization validation

### Test Environment Setup
```bash
# Backend test server
cd backend
npm run dev

# Frontend test app
cd frontend
flutter run

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

### Authentication Flow Testing

#### 1. User Registration
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
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "testuser@example.com",
    "role": "user",
    "jokerCount": 3
  }
}
```

#### 2. User Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "testpassword123"
  }'
```

#### 3. Coffee Shop Registration
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

#### 4. Admin Creation
```bash
curl -X POST http://localhost:8000/api/auth/create-admin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@mochapoint.com",
    "password": "adminpassword123",
    "adminSecret": "your-admin-secret"
  }'
```

### QR Redemption System Testing

#### 1. Generate QR Token (User)
```bash
# Save user token from login
export USER_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Generate subscription QR
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}'
```

**Expected Response (200):**
```json
{
  "success": true,
  "qrToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2025-01-15T23:59:59.999Z",
  "userInfo": {
    "name": "Test User",
    "email": "testuser@example.com",
    "jokerCount": 3
  }
}
```

#### 2. Validate QR Token (Coffee Shop)
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

### Monthly Statistics Testing

#### 1. Get Monthly Stats
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
    "redeemed": {
      "total": 1,
      "subscription": 1,
      "joker": 0
    },
    "available": {
      "total": 15,
      "subscription": 12,
      "jokers": 3
    }
  }
}
```

### Coffee Shop Management Testing

#### 1. Create Coffee Shop (Admin)
```bash
export ADMIN_TOKEN="admin-token-here"

curl -X POST http://localhost:8000/api/coffee-shops \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Coffee Central",
    "address": "Hauptplatz 1, 8010 Graz",
    "latitude": 47.0707,
    "longitude": 15.4395,
    "subscriptionEnabled": true,
    "jokerEnabled": true
  }'
```

#### 2. Get Coffee Shop List
```bash
curl -X GET "http://localhost:8000/api/coffee-shops?lat=47.0707&lng=15.4395"
```

#### 3. Get Shop Statistics (Shop Owner)
```bash
curl -X GET http://localhost:8000/api/coffee-shops/1/stats \
  -H "Authorization: Bearer $SHOP_TOKEN"
```

### Error Testing

#### 1. Invalid Authentication
```bash
# No token
curl -X GET http://localhost:8000/api/redemptions/monthly-stats

# Expected: 401 Unauthorized

# Invalid token
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer invalid-token"

# Expected: 403 Forbidden
```

#### 2. Invalid QR Generation
```bash
# Invalid redemption type
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "invalid"}'

# Expected: 400 Bad Request
```

#### 3. Insufficient Permissions
```bash
# User trying to create coffee shop
curl -X POST http://localhost:8000/api/coffee-shops \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Shop"}'

# Expected: 403 Forbidden
```

---

## Frontend Testing

### Manual Testing Checklist

#### Authentication Flow
- [ ] **Splash Screen**: Shows for 3 seconds, then navigates
- [ ] **Registration**: Email validation, password requirements
- [ ] **Login**: Successful authentication, token storage
- [ ] **Google Sign-In**: OAuth flow works correctly
- [ ] **Auto-Login**: Remembers user between app restarts

#### Home Screen (User)
- [ ] **Statistics Card**: Loads monthly stats automatically
- [ ] **Loading State**: Shows progress indicators
- [ ] **Error Handling**: Retry button appears on network errors
- [ ] **QR Generation**: Modal opens when tapping center button
- [ ] **Coffee Shops List**: Shows nearby shops with ratings

#### QR System
- [ ] **QR Generation**: Creates valid QR codes
- [ ] **QR Display**: Shows user info and expiration
- [ ] **QR Scanner**: Scans and validates codes successfully
- [ ] **Redemption Flow**: Complete user-to-shop workflow
- [ ] **Error Messages**: Clear feedback for invalid/expired codes

#### Coffee Shop Dashboard
- [ ] **Analytics Display**: Shows real-time statistics
- [ ] **Scanner Interface**: Camera opens and scans QR codes
- [ ] **Customer Info**: Displays customer details during redemption
- [ ] **Statistics Updates**: Live updates after redemptions

#### Navigation & UI
- [ ] **Role-based Navigation**: Different UI for users vs shop owners
- [ ] **Smooth Transitions**: No lag between screens
- [ ] **Responsive Design**: Works on different screen sizes
- [ ] **Dark/Light Mode**: Consistent theming (if implemented)

### Flutter Widget Testing

#### Test Authentication Widget
```dart
// test/auth_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocha_point/screens/login_screen.dart';

void main() {
  testWidgets('Login screen has email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
```

#### Test Stats Card Widget
```dart
// test/stats_card_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocha_point/widgets/coffee_stats_card.dart';

void main() {
  testWidgets('Stats card shows loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: CoffeeStatsCard()));

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('Stats card shows retry button on error', (WidgetTester tester) async {
    // Mock network error
    // Verify retry button appears
  });
}
```

### Device Testing Matrix

#### Android Testing
| Device Type | Screen Size | Android Version | Status |
|-------------|-------------|-----------------|---------|
| Phone | Small (5") | Android 10+ | ✅ |
| Phone | Medium (6") | Android 11+ | ✅ |
| Phone | Large (6.5"+) | Android 12+ | ✅ |
| Tablet | 7-10" | Android 11+ | 🚧 |

#### iOS Testing
| Device Type | Screen Size | iOS Version | Status |
|-------------|-------------|-------------|---------|
| iPhone SE | Small | iOS 14+ | ✅ |
| iPhone 13/14 | Standard | iOS 15+ | ✅ |
| iPhone Pro Max | Large | iOS 16+ | ✅ |
| iPad | Tablet | iOS 14+ | 🚧 |

---

## Integration Testing

### Complete User Journey Testing

#### User Registration → First Redemption
```bash
#!/bin/bash
# integration_test.sh

echo "=== Integration Test: User Journey ==="

# 1. Register user
echo "1. Registering user..."
USER_RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "integration@test.com",
    "password": "testpass123"
  }')

USER_TOKEN=$(echo $USER_RESPONSE | jq -r '.token')
echo "User registered, token: ${USER_TOKEN:0:20}..."

# 2. Generate QR
echo "2. Generating QR token..."
QR_RESPONSE=$(curl -s -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "joker"}')

QR_TOKEN=$(echo $QR_RESPONSE | jq -r '.qrToken')
echo "QR generated: ${QR_TOKEN:0:20}..."

# 3. Register coffee shop
echo "3. Registering coffee shop..."
SHOP_RESPONSE=$(curl -s -X POST http://localhost:8000/api/auth/register-coffee-shop \
  -H "Content-Type: application/json" \
  -d '{
    "email": "shoptest@test.com",
    "password": "shoppass123",
    "shopName": "Integration Test Shop",
    "address": "Test Street 123"
  }')

SHOP_TOKEN=$(echo $SHOP_RESPONSE | jq -r '.token')
echo "Shop registered, token: ${SHOP_TOKEN:0:20}..."

# 4. Validate redemption
echo "4. Processing redemption..."
REDEMPTION_RESPONSE=$(curl -s -X POST http://localhost:8000/api/redemptions/validate-and-redeem \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "qrToken": "'$QR_TOKEN'",
    "coffeeType": "Integration Test Coffee"
  }')

echo "Redemption result:"
echo $REDEMPTION_RESPONSE | jq '.'

# 5. Check monthly stats
echo "5. Checking monthly statistics..."
STATS_RESPONSE=$(curl -s -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN")

echo "Monthly stats:"
echo $STATS_RESPONSE | jq '.data.redeemed'

echo "=== Integration Test Complete ==="
```

### Cross-Platform Testing

#### Flutter Integration Tests
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocha_point/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('Complete user flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test splash screen
      expect(find.text('Mocha Point'), findsOneWidget);

      // Wait for navigation
      await tester.pumpAndSettle(Duration(seconds: 4));

      // Test login screen appears
      expect(find.text('Login'), findsOneWidget);

      // Test navigation to registration
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Register'), findsOneWidget);
    });
  });
}
```

---

## End-to-End Testing

### Complete Redemption Workflow

#### Test Scenario: Subscription Redemption
1. **Setup**: User with active subscription, Coffee shop with QR scanner
2. **Action**: User generates subscription QR, shop scans and validates
3. **Verification**: Redemption recorded, statistics updated, user notified

#### Test Scenario: Daily Limit Enforcement
1. **Setup**: User who already redeemed today
2. **Action**: Attempt to generate another subscription QR
3. **Verification**: Error message, next available time shown

#### Test Scenario: Expired QR Code
1. **Setup**: Generated QR code from previous day
2. **Action**: Coffee shop attempts to scan expired code
3. **Verification**: Rejection message, no redemption recorded

### Multi-Device Testing

#### Same User, Multiple Devices
```bash
# Test user consistency across devices
# Device 1: Generate QR
# Device 2: Check monthly stats should show same data
# Device 3: Login should sync properly
```

#### Concurrent Redemptions
```bash
# Test race conditions
# Multiple shops scanning same QR simultaneously
# Should only allow one successful redemption
```

---

## Performance Testing

### API Load Testing

#### Using Artillery
```yaml
# artillery-config.yml
config:
  target: 'http://localhost:8000'
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - name: "API Load Test"
    requests:
      - get:
          url: "/health"
      - post:
          url: "/api/auth/login"
          json:
            email: "test@example.com"
            password: "password123"
```

```bash
# Run load test
npm install -g artillery
artillery run artillery-config.yml
```

#### Using curl (Simple)
```bash
# Concurrent requests test
for i in {1..100}; do
  curl -s http://localhost:8000/api/coffee-shops > /dev/null &
done
wait

echo "100 concurrent requests completed"
```

### Mobile App Performance

#### Flutter Performance Testing
```dart
// test/performance_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stats card loads within 3 seconds', (WidgetTester tester) async {
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(MaterialApp(home: CoffeeStatsCard()));
    await tester.pumpAndSettle();

    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(3000));
  });
}
```

### Database Performance Testing

#### Query Performance
```sql
-- Test monthly stats query performance
EXPLAIN ANALYZE
SELECT 
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE redemption_type = 'subscription') as subscription_count,
  COUNT(*) FILTER (WHERE redemption_type = 'joker') as joker_count
FROM redemptions 
WHERE user_id = 1 
  AND timestamp >= date_trunc('month', CURRENT_DATE)
  AND timestamp < date_trunc('month', CURRENT_DATE) + interval '1 month';
```

---

## Security Testing

### Authentication Security

#### JWT Token Testing
```bash
# Test token expiration
# 1. Get valid token
# 2. Wait for expiration
# 3. Verify API rejects expired token

# Test token manipulation
# 1. Modify token payload
# 2. Verify API rejects modified token

# Test role elevation
# 1. User token trying admin endpoints
# 2. Verify proper 403 responses
```

#### OAuth Security Testing
```bash
# Test Google OAuth flow
# 1. Valid Google token → should succeed
# 2. Invalid Google token → should fail
# 3. Expired Google token → should fail

# Test replay attacks
# 1. Reuse QR code → should fail second time
# 2. Reuse authentication tokens → should work until expiry
```

### Input Validation Testing

#### SQL Injection Testing
```bash
# Test malicious input
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com; DROP TABLE users; --",
    "password": "password"
  }'

# Should return validation error, not SQL error
```

#### XSS Testing
```bash
# Test script injection
curl -X POST http://localhost:8000/api/coffee-shops \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<script>alert('xss')</script>",
    "address": "Test Address"
  }'

# Should sanitize input
```

---

## Automated Testing

### GitHub Actions Workflow
```yaml
# .github/workflows/test.yml
name: Test Suite

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

      - name: Run tests
        run: |
          cd backend
          npm test
        env:
          DB_HOST: localhost
          DB_PORT: 5432
          DB_NAME: mocha_point_test
          DB_USER: postgres
          DB_PASSWORD: postgres
          JWT_SECRET: test-secret

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: |
          cd frontend
          flutter pub get

      - name: Run tests
        run: |
          cd frontend
          flutter test
```

### Test Data Management

#### Test Database Setup
```sql
-- test_data.sql
INSERT INTO users (email, password, role, joker_count) VALUES
('testuser@example.com', '$2b$12$hashed_password', 'user', 5),
('testshop@example.com', '$2b$12$hashed_password', 'coffee_shop', 0);

INSERT INTO coffee_shops (name, address, latitude, longitude) VALUES
('Test Coffee Shop', 'Test Address', 47.0707, 15.4395);
```

#### Cleanup Script
```bash
#!/bin/bash
# cleanup_test_data.sh

echo "Cleaning up test data..."

# Remove test users
psql -d mocha_point_test -c "DELETE FROM users WHERE email LIKE '%test%';"

# Remove test coffee shops
psql -d mocha_point_test -c "DELETE FROM coffee_shops WHERE name LIKE 'Test%';"

# Remove test redemptions
psql -d mocha_point_test -c "DELETE FROM redemptions WHERE id > 1000;"

echo "Test data cleanup complete"
```

---

## Test Results Documentation

### Test Report Template

#### Daily Test Results
```markdown
# Test Report - January 15, 2025

## Summary
- **Total Tests**: 127
- **Passed**: 124
- **Failed**: 3
- **Success Rate**: 97.6%

## Failed Tests
1. **QR Expiration Test**: Intermittent failure on slow networks
2. **Load Test**: 5% failure rate under 100 concurrent users
3. **iOS Integration**: Camera permission issue

## Performance Metrics
- **Average API Response**: 145ms
- **App Startup Time**: 2.3s
- **QR Generation**: 180ms

## Action Items
- [ ] Fix QR expiration timing issue
- [ ] Optimize database queries for load testing
- [ ] Update iOS camera permission handling
```

### Continuous Monitoring

#### Health Check Monitoring
```bash
#!/bin/bash
# health_monitor.sh

while true; do
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
  
  if [ $RESPONSE != "200" ]; then
    echo "$(date): Health check failed - HTTP $RESPONSE"
    # Send alert notification
  else
    echo "$(date): Health check passed"
  fi
  
  sleep 60
done
```

---

This comprehensive testing guide ensures MochaPoint maintains high quality and reliability across all features and platforms. Regular execution of these tests helps catch issues early and maintains user confidence in the platform.
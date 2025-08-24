# Setup & Installation Guide

> Complete setup instructions for MochaPoint development and production environments

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Backend Setup](#backend-setup)
- [Frontend Setup](#frontend-setup)
- [Environment Configuration](#environment-configuration)
- [Database Configuration](#database-configuration)
- [Environment Variables](#environment-variables)
- [Initial Data Setup](#initial-data-setup)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- **Node.js**: 18.0.0 or higher
- **npm**: 8.0.0 or higher (comes with Node.js)
- **PostgreSQL**: 14.0 or higher (17+ recommended)
- **Flutter**: 3.0.0 or higher
- **Git**: Latest version

### Development Tools
- **Android Studio**: For Android development with Flutter support
- **Xcode**: For iOS development (macOS only)
- **VS Code**: Alternative editor with Flutter/Dart extensions
- **Postman**: For API testing (optional)

### System Requirements
- **Memory**: 8GB RAM minimum, 16GB recommended
- **Storage**: 10GB free space
- **OS**: Windows 10+, macOS 10.14+, or Ubuntu 18.04+

---

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/your-username/mocha-point.git
cd mocha-point
```

### 2. Backend Setup (5 minutes)
```bash
cd backend
npm install
cp .env.example .env
# Edit .env file with your configuration
npm run dev
```

### 3. Frontend Setup (5 minutes) ⭐ UPDATED
```bash
cd frontend
flutter pub get

# Development environment (default)
flutter run --dart-define=ENVIRONMENT=development

# Production environment
flutter run --dart-define=ENVIRONMENT=production
```

### 4. Verify Setup
```bash
# Test API
curl http://localhost:8000/health

# Should return:
# {"success": true, "message": "Mocha Point API is running"}
```

---

## Backend Setup

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Enhanced Environment Configuration ⭐ UPDATED
```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env  # or your preferred editor
```

**Required Environment Variables:**
```env
# Server Configuration
NODE_ENV=development
PORT=8000

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mocha_point
DB_USER=your_username
DB_PASSWORD=your_password

# Enhanced Authentication (30-day JWT tokens)
JWT_SECRET=your-very-secure-256-character-secret-key-here
ADMIN_CREATION_SECRET=your-admin-creation-secret

# OAuth Configuration (Optional)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
APPLE_CLIENT_ID=your-apple-bundle-id
```

### 3. Database Setup
```bash
# Create database
createdb mocha_point

# Or using PostgreSQL command line
psql -U postgres
CREATE DATABASE mocha_point;
\q
```

### 4. Start Development Server
```bash
npm run dev
```

**Expected Output:**
```
✓ Database connected successfully
✓ Database models synchronized
✓ Subscription system models loaded
🚀 Server running on port 8000
🔗 Health check: http://localhost:8000/health
🔗 API Base URL: http://localhost:8000/api
```

### 5. Verify Backend Setup
```bash
# Health check
curl http://localhost:8000/health

# API test
curl http://localhost:8000/api/coffee-shops

# Enhanced monthly stats test (after creating user)
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Frontend Setup

### 1. Install Flutter Dependencies
```bash
cd frontend
flutter pub get
```

### 2. Environment Configuration ⭐ NEW

MochaPoint now uses an automatic environment configuration system. No manual URL editing required!

**The app automatically detects environment based on the `--dart-define` parameter:**

```bash
# Development (uses local API)
flutter run --dart-define=ENVIRONMENT=development

# Production (uses production API) 
flutter run --dart-define=ENVIRONMENT=production
```

### 3. Android Studio Environment Setup ⭐ NEW

Create run configurations in Android Studio:

#### Development Configuration
- **Name**: Development
- **Dart entrypoint**: `lib/main.dart`
- **Additional run args**: `--dart-define=ENVIRONMENT=development`

#### Production Configuration
- **Name**: Production
- **Dart entrypoint**: `lib/main.dart`
- **Additional run args**: `--dart-define=ENVIRONMENT=production`

#### Production Release Configuration
- **Name**: Production Release
- **Dart entrypoint**: `lib/main.dart`
- **Additional run args**: `--dart-define=ENVIRONMENT=production`
- **Build mode**: release

### 4. Network Configuration for Development

#### For Physical Device Testing:
Find your local IP address:
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig | grep inet

# Example: 192.168.1.109
```

The app will automatically use your local network IP for development environment.

#### For Emulator Testing:
The app automatically uses appropriate localhost URLs for emulators.

### 5. Run Flutter App ⭐ UPDATED
```bash
# List available devices
flutter devices

# Run in development environment (default)
flutter run --dart-define=ENVIRONMENT=development -d <device_id>

# Run in production environment
flutter run --dart-define=ENVIRONMENT=production -d <device_id>

# Run on Chrome (for web testing)
flutter run --dart-define=ENVIRONMENT=development -d chrome
```

### 6. Verify Frontend Setup

**Console Output (Development):**
```
🔧 AppConfig:
   Environment: Development
   API Base URL: http://192.168.1.109:8000/api
   Debug Features: true
   Logging: enabled
```

**Console Output (Production):**
```
🔧 AppConfig:
   Environment: Production  
   API Base URL: https://mochapoint.coffee/api
   Debug Features: false
   Logging: disabled
```

- App should launch and show splash screen
- Navigation to login screen should work
- Test user registration/login functionality
- Enhanced monthly stats should show "Remaining" count

---

## Environment Configuration

### Automatic Environment Detection ⭐ NEW

MochaPoint features a robust environment management system that eliminates hardcoded URLs and provides seamless development/production switching.

#### Environment Matrix

| Setting | Development | Production |
|---------|-------------|------------|
| **API Base URL** | `http://YOUR_LOCAL_IP:8000/api` | `https://mochapoint.coffee/api` |
| **Debug Logging** | ✅ Enabled | ❌ Disabled |
| **Debug Features** | ✅ Enabled | ❌ Disabled |
| **API Timeout** | 30 seconds | 10 seconds |
| **Analytics** | ❌ Disabled | ✅ Enabled |
| **Crash Reporting** | ❌ Disabled | ✅ Enabled |

#### Configuration Files ⭐ NEW

The system automatically creates these configuration files:

**`lib/config/app_config.dart`** - Centralized environment settings
**`lib/services/api_service.dart`** - Environment-aware HTTP service
**Updated service files** - All services now use AppConfig

#### Development vs Production

```bash
# Development - Full debugging, local API
flutter run --dart-define=ENVIRONMENT=development

# Production - Optimized, production API  
flutter run --dart-define=ENVIRONMENT=production
```

#### Build Commands by Environment

```bash
# Development APK
flutter build apk --dart-define=ENVIRONMENT=development

# Production APK  
flutter build apk --release --dart-define=ENVIRONMENT=production

# Production App Bundle (for Play Store)
flutter build appbundle --release --dart-define=ENVIRONMENT=production

# iOS Production Build
flutter build ios --release --dart-define=ENVIRONMENT=production
```

---

## Database Configuration

### PostgreSQL Installation

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### macOS (using Homebrew):
```bash
brew install postgresql
brew services start postgresql
```

#### Windows:
Download from [PostgreSQL official site](https://www.postgresql.org/download/windows/)

### Enhanced Database Setup ⭐ UPDATED
```bash
# Switch to postgres user
sudo -u postgres psql

# Create user and database
CREATE USER mochapoint WITH PASSWORD 'your_secure_password';
CREATE DATABASE mocha_point OWNER mochapoint;
GRANT ALL PRIVILEGES ON DATABASE mocha_point TO mochapoint;

# Enable required extensions
\c mocha_point
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\q
```

### Database Schema Initialization ⭐ UPDATED

The enhanced MochaPoint system includes subscription tables and enhanced indexing:

```sql
-- Core tables (users, coffee_shops, redemptions, ratings)
-- Subscription system tables (subscription_plans, user_subscriptions)
-- Enhanced indexing for performance
-- Automatic triggers for rating calculations
```

### Database Connection Testing
```bash
# Test connection
psql -h localhost -U mochapoint -d mocha_point

# Should connect successfully
```

### Performance Configuration (Recommended)
Edit PostgreSQL configuration for better performance:

**postgresql.conf:**
```conf
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Enhanced for subscription queries
random_page_cost = 1.1
seq_page_cost = 1.0
```

---

## Environment Variables

### Complete .env Template ⭐ UPDATED
```env
# ======================
# SERVER CONFIGURATION
# ======================
NODE_ENV=development
PORT=8000

# ======================
# DATABASE CONFIGURATION  
# ======================
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mocha_point
DB_USER=mochapoint
DB_PASSWORD=your_secure_password

# ======================
# ENHANCED AUTHENTICATION
# ======================
# Generate with: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET=your-very-secure-256-character-secret-key-here-generate-this-properly
JWT_EXPIRY=30d
ADMIN_CREATION_SECRET=your-admin-creation-secret-keep-this-secure

# ======================
# OAUTH CONFIGURATION
# ======================
# Google OAuth (Optional)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Apple Sign-In (Optional)
APPLE_CLIENT_ID=your-apple-bundle-id
APPLE_TEAM_ID=your-apple-team-id
APPLE_KEY_ID=your-apple-key-id
APPLE_PRIVATE_KEY=your-apple-private-key

# ======================
# SUBSCRIPTION SYSTEM
# ======================
# Stripe configuration (future)
STRIPE_PUBLIC_KEY=pk_test_your_stripe_public_key
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# ======================
# DEVELOPMENT SETTINGS
# ======================
# CORS Origins (comma-separated)
CORS_ORIGINS=http://localhost:3001,http://localhost:3000,http://192.168.1.109:3001

# Logging Level
LOG_LEVEL=debug

# ======================
# PRODUCTION SETTINGS
# ======================
# Uncomment for production
# NODE_ENV=production
# CORS_ORIGINS=https://mochapoint.coffee
# LOG_LEVEL=error
# JWT_EXPIRY=30d
```

### Generating Secure Secrets ⭐ UPDATED
```bash
# JWT Secret (64 bytes hex) - for 30-day tokens
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Admin Secret (32 bytes hex)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Subscription webhook secret (if using Stripe)
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

---

## Initial Data Setup

### 1. Create Admin User
```bash
curl -X POST http://localhost:8000/api/auth/create-admin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@mochapoint.com",
    "password": "SecureAdminPassword123!",
    "adminSecret": "your-admin-creation-secret"
  }'
```

**Save the returned JWT token (valid for 30 days) for next steps.**

### 2. Create Test Coffee Shop ⭐ UPDATED
```bash
curl -X POST http://localhost:8000/api/coffee-shops \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -d '{
    "name": "Central Coffee Graz",
    "brand": "Central",
    "address": "Hauptplatz 1, 8010 Graz, Austria",
    "latitude": 47.0707,
    "longitude": 15.4395,
    "description": "Best coffee in the heart of Graz",
    "phone": "+43 316 123456",
    "operatingHours": {
      "monday": {"open": "07:00", "close": "19:00"},
      "tuesday": {"open": "07:00", "close": "19:00"},
      "wednesday": {"open": "07:00", "close": "19:00"},
      "thursday": {"open": "07:00", "close": "19:00"},
      "friday": {"open": "07:00", "close": "20:00"},
      "saturday": {"open": "08:00", "close": "20:00"},
      "sunday": {"open": "09:00", "close": "18:00"}
    },
    "redemptionHours": {
      "monday": {"open": "08:00", "close": "18:00"},
      "tuesday": {"open": "08:00", "close": "18:00"},
      "wednesday": {"open": "08:00", "close": "18:00"},
      "thursday": {"open": "08:00", "close": "18:00"},
      "friday": {"open": "08:00", "close": "18:00"},
      "saturday": {"open": "09:00", "close": "18:00"},
      "sunday": {"open": "10:00", "close": "17:00"}
    },
    "subscriptionEnabled": true,
    "jokerEnabled": true
  }'
```

### 3. Create Test Subscription Plan ⭐ NEW
```bash
curl -X POST http://localhost:8000/api/subscription-plans \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -d '{
    "name": "Premium Monthly Plan",
    "shopId": 1,
    "planType": "shop",
    "durationMonths": 1,
    "priceCents": 2500,
    "currency": "EUR",
    "weeklyLimit": 5,
    "monthlyLimit": 25,
    "description": "Unlimited coffee at Central Coffee Graz",
    "features": ["Daily coffee", "Skip lines", "Premium support"],
    "isActive": true
  }'
```

### 4. Create Test Users ⭐ UPDATED
```bash
# Regular user
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@test.com",
    "password": "testpassword123"
  }'

# Coffee shop owner
curl -X POST http://localhost:8000/api/auth/register-coffee-shop \
  -H "Content-Type: application/json" \
  -d '{
    "email": "shop@test.com",
    "password": "testpassword123",
    "shopName": "Test Coffee Shop",
    "address": "Test Street 123, 8010 Graz"
  }'
```

### 5. Create Test User Subscription ⭐ NEW
```bash
# First get the user ID and plan ID from previous responses
curl -X POST http://localhost:8000/api/user-subscriptions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -d '{
    "userId": 1,
    "planId": 1,
    "status": "active",
    "startDate": "2025-01-01",
    "endDate": "2025-01-31",
    "autoRenew": true
  }'
```

### 6. Verify Enhanced Setup ⭐ UPDATED
```bash
# Test coffee shop listing
curl http://localhost:8000/api/coffee-shops

# Test user login (receives 30-day token)
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@test.com",
    "password": "testpassword123"
  }'

# Test enhanced monthly stats
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer USER_JWT_TOKEN"

# Should return enhanced response with remainingMonthly

# Test user subscription details
curl -X GET http://localhost:8000/api/users/subscription \
  -H "Authorization: Bearer USER_JWT_TOKEN"

# Test QR generation with monthly limits
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer USER_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}'
```

---

## Production Deployment

### Environment Preparation ⭐ UPDATED
```env
NODE_ENV=production
PORT=8000
DB_HOST=your-production-db-host
DB_NAME=mocha_point_prod
JWT_EXPIRY=30d
LOG_LEVEL=error
# ... other production values
```

### Backend Deployment

#### Using PM2 (Recommended) ⭐ UPDATED
```bash
# Install PM2
npm install -g pm2

# Build application
npm run build

# Start with PM2 and enhanced monitoring
pm2 start dist/app.js --name mocha-point-api --env production

# Configure auto-restart
pm2 startup
pm2 save

# Monitor with real-time stats
pm2 monit
```

#### Using Docker ⭐ UPDATED
```dockerfile
# Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["node", "dist/app.js"]
```

```bash
# Build and run
docker build -t mocha-point-api .
docker run -p 8000:8000 --env-file .env.production mocha-point-api
```

### Frontend Deployment ⭐ UPDATED

#### Build for Production
```bash
# Android APK with production environment
flutter build apk --release --dart-define=ENVIRONMENT=production

# Android App Bundle for Play Store
flutter build appbundle --release --dart-define=ENVIRONMENT=production

# iOS for App Store (macOS only)
flutter build ios --release --dart-define=ENVIRONMENT=production

# Web build (if needed)
flutter build web --dart-define=ENVIRONMENT=production
```

#### Environment-Specific Builds
```bash
# Development build for testing
flutter build apk --dart-define=ENVIRONMENT=development

# Staging build (if using staging environment)
flutter build apk --release --dart-define=ENVIRONMENT=staging

# Production build for distribution
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

#### App Store Deployment
Follow platform-specific guidelines:
- **Google Play Store**: [Android Publishing Guide](https://flutter.dev/docs/deployment/android)
- **Apple App Store**: [iOS Publishing Guide](https://flutter.dev/docs/deployment/ios)

### Database Migration ⭐ UPDATED
```bash
# Production database setup with subscription system
psql -h production-host -U production-user -d mocha_point_prod

# Import enhanced schema (includes subscription tables)
psql -h production-host -U production-user -d mocha_point_prod < enhanced_schema.sql

# Verify subscription system tables
\dt *subscription*
```

### SSL/HTTPS Setup
```nginx
# Nginx configuration for production
server {
    listen 443 ssl http2;
    server_name api.mochapoint.coffee;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (future)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8000/health;
        access_log off;
    }
}
```

---

## Troubleshooting

### Common Backend Issues ⭐ UPDATED

#### Database Connection Failed
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check database exists with subscription tables
psql -U postgres -c "\l" | grep mocha_point
psql -U mochapoint -d mocha_point -c "\dt *subscription*"

# Test connection manually
psql -h localhost -U mochapoint -d mocha_point
```

#### JWT Token Issues ⭐ NEW
```bash
# Test token generation with 30-day expiry
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "password"}'

# Verify token expiry (should show 30 days from now)
# Decode JWT at https://jwt.io to check exp claim
```

**Common JWT Errors:**
```
Error: JWT_SECRET is required
Solution: Add JWT_SECRET to .env file

Error: Token has expired  
Solution: User needs to log in again (30-day expiry)

Error: Invalid token
Solution: Clear app storage and re-login
```

#### Port Already in Use
```bash
# Find process using port 8000
lsof -i :8000
netstat -tulpn | grep :8000

# Kill process if needed
kill -9 <PID>

# Or use different port
PORT=8001 npm run dev
```

### Common Frontend Issues ⭐ UPDATED

#### Environment Configuration Errors ⭐ NEW
```bash
# Problem: App always shows "Development" environment
# Solution: Ensure dart-define parameter is correct
flutter run --dart-define=ENVIRONMENT=production

# Problem: Cannot connect to API
# Check console output for correct base URL:
# Development should show: http://YOUR_IP:8000/api
# Production should show: https://mochapoint.coffee/api
```

#### Network Errors ⭐ UPDATED
```
Error: Network error: Failed to connect to localhost:8000
```

**Solutions:**
1. Verify backend is running: `curl http://localhost:8000/health`
2. Check environment configuration in app console
3. For physical devices: Ensure correct IP address in development
4. For emulators: Check if localhost/10.0.2.2 is accessible

#### Session Expiry Issues ⭐ NEW
```
Error: Token has expired
```

**Expected Behavior:**
1. App shows "Session Expired" dialog
2. User clicks "Login Again"
3. App navigates to login screen
4. User logs in and gets new 30-day token

**If not working:**
- Check error handling in RedemptionService
- Verify session expired dialog implementation
- Check navigation routes

#### Build Failed
```bash
# Clear Flutter cache
flutter pub cache clean
flutter pub get

# Clean build with environment
flutter clean
flutter pub get
flutter build apk --dart-define=ENVIRONMENT=development
```

#### Android Studio Configuration Issues ⭐ NEW

**Problem: Run configurations not working**
```
Solution: 
1. Check "Additional run args" field has: --dart-define=ENVIRONMENT=development
2. Ensure no conflicting flags (don't mix --release with debug mode)
3. Restart Android Studio if configurations don't appear
```

#### Monthly Stats Issues ⭐ NEW
```
Problem: "Remaining" shows 0 when it shouldn't
Solutions:
1. Check if monthly_coffee_limit column exists in subscription_plans table
2. Verify user has active subscription
3. Check backend logs for subscription query errors
4. Test with: curl -X GET http://localhost:8000/api/redemptions/monthly-stats -H "Authorization: Bearer TOKEN"
```

### Performance Issues ⭐ UPDATED

#### Slow Database Queries
```sql
-- Check slow queries related to subscriptions
SELECT query, mean_time, calls 
FROM pg_stat_statements 
WHERE query LIKE '%subscription%'
ORDER BY mean_time DESC;

-- Add missing indexes for subscription system
CREATE INDEX CONCURRENTLY idx_user_subscriptions_active 
ON user_subscriptions(user_id, status) WHERE status = 'active';

CREATE INDEX CONCURRENTLY idx_redemptions_monthly_stats
ON redemptions(user_id, date_trunc('month', timestamp), redemption_type);
```

#### High Memory Usage
```bash
# Monitor Node.js memory with subscription processing
node --max-old-space-size=4096 dist/app.js

# Monitor with PM2
pm2 monit

# Check subscription-related memory usage
pm2 logs mocha-point-api --lines 100 | grep -i subscription
```

#### Mobile App Performance ⭐ UPDATED
```bash
# Profile Flutter app with environment logging
flutter run --dart-define=ENVIRONMENT=development --profile

# Check for excessive API calls in development logs
# Look for repeated calls to monthly-stats or subscription endpoints

# Build optimized production release
flutter build apk --release --dart-define=ENVIRONMENT=production
```

### Environment-Specific Debugging ⭐ NEW

#### Development Environment Debug
```bash
# Enable detailed logging
flutter run --dart-define=ENVIRONMENT=development -v

# Check API calls in console
# Should see: "🌐 ApiService GET: http://YOUR_IP:8000/api/..."
```

#### Production Environment Debug
```bash
# Limited logging for production
flutter run --dart-define=ENVIRONMENT=production

# Check for production API calls
# Should see: "🔧 AppConfig: Environment: Production"
```

### Getting Help

#### Enhanced Log Files ⭐ UPDATED
```bash
# Backend logs with subscription system
npm run dev  # Console output with subscription debugging
pm2 logs mocha-point-api  # PM2 logs with subscription events

# Backend logs specific to subscription system
pm2 logs mocha-point-api | grep -i "subscription\|monthly\|remaining"

# Flutter logs with environment information
flutter logs
```

#### Debug Mode ⭐ UPDATED
```bash
# Backend debug mode with subscription debugging
DEBUG=* npm run dev

# Flutter debug mode with environment logging
flutter run --dart-define=ENVIRONMENT=development --verbose
```

#### Common Commands ⭐ UPDATED
```bash
# Reset everything (enhanced)
rm -rf node_modules
npm install
dropdb mocha_point
createdb mocha_point
npm run dev

# Flutter reset with environment
flutter clean
flutter pub get
flutter run --dart-define=ENVIRONMENT=development

# Test subscription system
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Environment-Specific Troubleshooting ⭐ NEW

#### Issue: Wrong API URL
```
Problem: App connects to wrong API URL
Check: Console should show correct environment
Development: http://YOUR_LOCAL_IP:8000/api
Production: https://mochapoint.coffee/api

Solution: Verify dart-define parameter and restart app
```

#### Issue: Session Expiry Not Working
```
Problem: App doesn't show session expired dialog
Check: 
1. Backend returns errorCode: "TOKEN_EXPIRED"
2. RedemptionService detects session expiry
3. Modal shows session expired dialog

Test: Use expired token with API call
```

#### Issue: Monthly Stats Incorrect
```
Problem: Remaining count doesn't match expected value
Debug Steps:
1. Check subscription plan monthly_coffee_limit
2. Verify redemption_type filtering (subscription vs joker)
3. Check date range for monthly calculation
4. Test with direct database query
```

---

**Need more help?**

- Check our [Enhanced Troubleshooting FAQ](https://github.com/your-repo/issues)
- Create a new issue with environment details (development/production)
- Include console output showing environment configuration
- Mention subscription system if the issue is related to monthly stats or remaining counts

**Pro tip:** Always include your environment (development/production) and console output when reporting issues!
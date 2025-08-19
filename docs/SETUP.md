# Setup & Installation Guide

> Complete setup instructions for MochaPoint development and production environments

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Backend Setup](#backend-setup)
- [Frontend Setup](#frontend-setup)
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
- **Android Studio**: For Android development
- **Xcode**: For iOS development (macOS only)
- **VS Code**: Recommended editor with Flutter/Dart extensions
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

### 3. Frontend Setup (5 minutes)
```bash
cd frontend
flutter pub get
flutter run
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

### 2. Environment Configuration
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

# Authentication
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
```

---

## Frontend Setup

### 1. Install Flutter Dependencies
```bash
cd frontend
flutter pub get
```

### 2. Update API Configuration
Edit the following files to match your backend URL:

**lib/services/auth_service.dart:**
```dart
static const String baseUrl = 'http://YOUR_IP:8000/api';
```

**lib/services/monthly_stats_service.dart:**
```dart
static const String baseUrl = 'http://YOUR_IP:8000/api';
```

**lib/services/redemption_service.dart:**
```dart
static const String baseUrl = 'http://YOUR_IP:8000/api';
```

### 3. Configure Development Environment

#### For Physical Device Testing:
Find your local IP address:
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig | grep inet

# Example: 192.168.1.109
```

Update services to use your IP:
```dart
static const String baseUrl = 'http://192.168.1.109:8000/api';
```

#### For Emulator Testing:
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';  # Android emulator
static const String baseUrl = 'http://localhost:8000/api'; # iOS simulator
```

### 4. Run Flutter App
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run on Chrome (for web testing)
flutter run -d chrome
```

### 5. Verify Frontend Setup
- App should launch and show splash screen
- Navigation to login screen should work
- Test user registration/login functionality

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

### Database Setup
```bash
# Switch to postgres user
sudo -u postgres psql

# Create user and database
CREATE USER mochapoint WITH PASSWORD 'your_secure_password';
CREATE DATABASE mocha_point OWNER mochapoint;
GRANT ALL PRIVILEGES ON DATABASE mocha_point TO mochapoint;
\q
```

### Database Connection Testing
```bash
# Test connection
psql -h localhost -U mochapoint -d mocha_point

# Should connect successfully
```

### Performance Configuration (Optional)
Edit PostgreSQL configuration for better performance:

**postgresql.conf:**
```conf
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
```

---

## Environment Variables

### Complete .env Template
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
# AUTHENTICATION SECRETS
# ======================
# Generate with: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
JWT_SECRET=your-very-secure-256-character-secret-key-here-generate-this-properly
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
# CORS_ORIGINS=https://yourdomain.com
# LOG_LEVEL=error
```

### Generating Secure Secrets
```bash
# JWT Secret (64 bytes hex)
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Admin Secret (32 bytes hex)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Or use online generator (less secure)
# https://www.allkeysgenerator.com/Random/Security-Encryption-Key-Generator.aspx
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

**Save the returned JWT token for next steps.**

### 2. Create Test Coffee Shop
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

### 3. Create Test Users
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

### 4. Verify Setup
```bash
# Test coffee shop listing
curl http://localhost:8000/api/coffee-shops

# Test user login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@test.com",
    "password": "testpassword123"
  }'
```

---

## Production Deployment

### Environment Preparation
```env
NODE_ENV=production
PORT=8000
DB_HOST=your-production-db-host
DB_NAME=mocha_point_prod
# ... other production values
```

### Backend Deployment

#### Using PM2 (Recommended)
```bash
# Install PM2
npm install -g pm2

# Build application
npm run build

# Start with PM2
pm2 start dist/app.js --name mocha-point-api

# Configure auto-restart
pm2 startup
pm2 save
```

#### Using Docker
```dockerfile
# Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
EXPOSE 8000
CMD ["node", "dist/app.js"]
```

```bash
# Build and run
docker build -t mocha-point-api .
docker run -p 8000:8000 --env-file .env mocha-point-api
```

### Frontend Deployment

#### Build for Production
```bash
# Android APK
flutter build apk --release

# iOS (macOS only)
flutter build ios --release

# Web (if needed)
flutter build web
```

#### App Store Deployment
Follow platform-specific guidelines:
- **Google Play Store**: [Android Publishing Guide](https://flutter.dev/docs/deployment/android)
- **Apple App Store**: [iOS Publishing Guide](https://flutter.dev/docs/deployment/ios)

### Database Migration
```bash
# Production database setup
psql -h production-host -U production-user -d mocha_point_prod

# Import schema (if using SQL dump)
psql -h production-host -U production-user -d mocha_point_prod < schema.sql
```

### SSL/HTTPS Setup
```nginx
# Nginx configuration
server {
    listen 443 ssl;
    server_name api.mochapoint.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Troubleshooting

### Common Backend Issues

#### Database Connection Failed
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check database exists
psql -U postgres -c "\l" | grep mocha_point

# Test connection manually
psql -h localhost -U mochapoint -d mocha_point
```

#### Port Already in Use
```bash
# Find process using port 8000
lsof -i :8000

# Kill process if needed
kill -9 <PID>

# Or use different port
PORT=8001 npm run dev
```

#### JWT Secret Missing
```
Error: JWT_SECRET is required
```

**Solution:**
```bash
# Generate new secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Add to .env file
JWT_SECRET=generated-secret-here
```

### Common Frontend Issues

#### Network Error
```
Error: Network error: Failed to connect to localhost:8000
```

**Solutions:**
1. Verify backend is running
2. Check API URL in service files
3. Use correct IP for physical device testing

#### Build Failed
```bash
# Clear pub cache
flutter pub cache clean
flutter pub get

# Clean build
flutter clean
flutter pub get
```

#### Android Emulator Issues
```bash
# Cold boot emulator
emulator -avd <device_name> -cold-boot

# Check available devices
flutter devices

# Use specific device
flutter run -d <device_id>
```

### Performance Issues

#### Slow Database Queries
```sql
-- Check slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC;

-- Add missing indexes
CREATE INDEX CONCURRENTLY idx_redemptions_user_month 
ON redemptions(user_id, date_trunc('month', timestamp));
```

#### High Memory Usage
```bash
# Monitor Node.js memory
node --max-old-space-size=4096 dist/app.js

# Monitor with PM2
pm2 monit
```

### Getting Help

#### Log Files
```bash
# Backend logs
npm run dev  # Console output
pm2 logs mocha-point-api  # PM2 logs

# Flutter logs
flutter logs
```

#### Debug Mode
```bash
# Backend debug mode
DEBUG=* npm run dev

# Flutter debug mode
flutter run --verbose
```

#### Common Commands
```bash
# Reset everything
rm -rf node_modules
npm install
dropdb mocha_point
createdb mocha_point
npm run dev

# Flutter reset
flutter clean
flutter pub get
flutter run
```

---

**Need more help?** Check our [Troubleshooting FAQ](https://github.com/your-repo/issues) or create a new issue.
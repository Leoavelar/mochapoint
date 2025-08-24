# System Architecture

> Technical overview of MochaPoint's system design, database schema, and technology stack

## 📋 Table of Contents
- [Technology Stack](#technology-stack)
- [System Overview](#system-overview)
- [Database Schema](#database-schema)
- [Backend Architecture](#backend-architecture)
- [Frontend Architecture](#frontend-architecture)
- [Environment Configuration](#environment-configuration)
- [Security Architecture](#security-architecture)
- [Performance Considerations](#performance-considerations)

---

## Technology Stack

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js + TypeScript
- **Database**: PostgreSQL 17+ with Sequelize ORM
- **Authentication**: JWT (30-day expiry) + OAuth (Google/Apple)
- **Security**: bcrypt password hashing
- **Session Management**: Enhanced token validation with expiry detection

### Frontend
- **Framework**: Flutter (Cross-platform iOS/Android)
- **UI**: Material Design with custom components
- **State Management**: StatefulWidget + Provider pattern
- **HTTP Client**: Custom ApiService with environment configuration
- **Configuration**: Environment-aware settings (dev/prod)

### Infrastructure
- **API Architecture**: RESTful with JWT authentication
- **QR System**: JWT-signed tokens with time validation
- **Database**: ACID-compliant with proper indexing
- **Security**: Role-based access control (RBAC)
- **Environment Management**: Development/production configuration system

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        SYSTEM ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  │   Flutter App   │◄──►│   Express API   │◄──►│  PostgreSQL DB  │
│  │                 │    │                 │    │                 │
│  │ • User Interface│    │ • Business Logic│    │ • Data Storage  │
│  │ • QR Generation │    │ • Authentication│    │ • Relationships │
│  │ • Camera Scanner│    │ • Authorization │    │ • Constraints   │
│  │ • Map Discovery │    │ • Validation    │    │ • Triggers      │
│  │ • Environment   │    │ • Session Mgmt  │    │ • Indexing      │
│  │   Configuration │    │ • 30-day Tokens │    │ • Subscriptions │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘
│           │                       │                       │        │
│           │                       │                       │        │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  │  Mobile Devices │    │   Middleware    │    │   Data Layer    │
│  │                 │    │                 │    │                 │
│  │ • iOS/Android   │    │ • Auth Tokens   │    │ • ACID Txns     │
│  │ • Real-time UI  │    │ • Role Checking │    │ • Foreign Keys  │
│  │ • Offline Cache │    │ • Input Valid.  │    │ • Auto Updates  │
│  │ • Error Handling│    │ • CORS Config   │    │ • Backups       │
│  │ • Config Mgmt   │    │ • Session Expiry│    │ • Performance   │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User Action** → Flutter UI captures user interaction
2. **Environment Check** → AppConfig determines API endpoint and settings
3. **Service Call** → Flutter service makes authenticated HTTP request
4. **API Gateway** → Express middleware validates JWT and permissions
5. **Session Validation** → Enhanced token validation with expiry detection
6. **Business Logic** → Controller processes request and applies rules
7. **Database Operation** → Sequelize ORM executes optimized queries
8. **Response** → Structured JSON response with proper error handling
9. **UI Update** → Flutter updates interface with new data
10. **Error Handling** → Session expiry triggers automatic logout and re-authentication

---

## Database Schema

### Core Business Tables

#### users - User accounts and authentication
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255), -- Nullable for OAuth users
    role user_role DEFAULT 'user',
    coffee_shop_id INTEGER REFERENCES coffee_shops(id),
    subscription_status BOOLEAN DEFAULT false,
    joker_count INTEGER DEFAULT 3,
    -- Social Authentication
    google_id VARCHAR(255) UNIQUE,
    apple_id VARCHAR(255) UNIQUE,
    name VARCHAR(255),
    photo_url VARCHAR(500),
    referral_code VARCHAR(20) UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TYPE user_role AS ENUM ('user', 'coffee_shop', 'admin');
```

#### coffee_shops - Coffee shop locations and business data
```sql
CREATE TABLE coffee_shops (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),
    address TEXT NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    subscription_enabled BOOLEAN DEFAULT true,
    joker_enabled BOOLEAN DEFAULT true,
    -- Dual Rating System
    app_rating NUMERIC(3,2) DEFAULT 0.00,
    app_rating_count INTEGER DEFAULT 0,
    google_rating NUMERIC(3,2),
    google_rating_count INTEGER,
    google_place_id VARCHAR(255),
    -- Business Information
    description TEXT,
    phone VARCHAR(255),
    -- Advanced Hours System
    operating_hours JSONB,
    redemption_hours JSONB,
    logo_filename VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### redemptions - Transaction records
```sql
CREATE TABLE redemptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    shop_id INTEGER REFERENCES coffee_shops(id) ON DELETE CASCADE,
    redemption_type redemption_type NOT NULL,
    timestamp TIMESTAMP DEFAULT NOW(),
    coffee_type VARCHAR(50)
);

CREATE TYPE redemption_type AS ENUM ('subscription', 'joker');
```

#### ratings - User reviews with automatic aggregation
```sql
CREATE TABLE ratings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    shop_id INTEGER REFERENCES coffee_shops(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, shop_id)
);

-- Trigger for automatic rating calculation
CREATE OR REPLACE FUNCTION update_coffee_shop_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE coffee_shops SET
        app_rating = (
            SELECT COALESCE(AVG(rating), 0)
            FROM ratings WHERE shop_id = NEW.shop_id
        ),
        app_rating_count = (
            SELECT COUNT(*)
            FROM ratings WHERE shop_id = NEW.shop_id
        )
    WHERE id = NEW.shop_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_rating
    AFTER INSERT OR UPDATE ON ratings
    FOR EACH ROW EXECUTE FUNCTION update_coffee_shop_rating();
```

### Subscription Tables (Production Ready)

#### subscription_plans - Subscription plan definitions ✅ **IMPLEMENTED**
```sql
CREATE TABLE subscription_plans (
    id SERIAL PRIMARY KEY,
    shop_id INTEGER REFERENCES coffee_shops(id),
    brand VARCHAR(100),
    plan_type plan_type_enum CHECK (plan_type IN ('shop', 'brand')),
    name VARCHAR(100) NOT NULL,
    duration_months INTEGER NOT NULL,
    price_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'EUR',
    weekly_coffee_limit INTEGER NOT NULL,
    monthly_coffee_limit INTEGER NOT NULL, -- ✅ ACTIVE: Used for remaining calculation
    description TEXT,
    features JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### user_subscriptions - User subscription records ✅ **IMPLEMENTED**
```sql
CREATE TABLE user_subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    plan_id INTEGER REFERENCES subscription_plans(id),
    status ENUM('active', 'cancelled', 'expired', 'trialing', 'past_due'),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    current_period_start DATE NOT NULL,
    current_period_end DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT true,
    stripe_subscription_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Database Optimization

#### Strategic Indexing
```sql
-- High-frequency query optimization
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_google_id ON users(google_id);
CREATE INDEX idx_users_apple_id ON users(apple_id);
CREATE INDEX idx_redemptions_user_timestamp ON redemptions(user_id, timestamp);
CREATE INDEX idx_redemptions_shop_timestamp ON redemptions(shop_id, timestamp);
CREATE INDEX idx_coffee_shops_location ON coffee_shops(latitude, longitude);
CREATE INDEX idx_ratings_shop_id ON ratings(shop_id);
-- NEW: Subscription system indexes
CREATE INDEX idx_user_subscriptions_active ON user_subscriptions(user_id, status) WHERE status = 'active';
CREATE INDEX idx_subscription_plans_active ON subscription_plans(is_active) WHERE is_active = true;
```

#### Foreign Key Constraints
```sql
-- Ensure referential integrity
ALTER TABLE users ADD CONSTRAINT fk_users_coffee_shop 
    FOREIGN KEY (coffee_shop_id) REFERENCES coffee_shops(id);
ALTER TABLE redemptions ADD CONSTRAINT fk_redemptions_user 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE redemptions ADD CONSTRAINT fk_redemptions_shop 
    FOREIGN KEY (shop_id) REFERENCES coffee_shops(id) ON DELETE CASCADE;
-- NEW: Subscription constraints
ALTER TABLE user_subscriptions ADD CONSTRAINT fk_user_subscriptions_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE user_subscriptions ADD CONSTRAINT fk_user_subscriptions_plan
    FOREIGN KEY (plan_id) REFERENCES subscription_plans(id);
```

---

## Backend Architecture

### Project Structure
```
backend/
├── src/
│   ├── config/
│   │   └── database.ts          # Database connection & config
│   ├── controllers/             # Business logic
│   │   ├── authController.ts    # Authentication endpoints
│   │   ├── userController.ts    # User management + subscription API
│   │   ├── coffeeShopController.ts # Shop operations
│   │   ├── redemptionController.ts # QR system & enhanced stats
│   │   └── ratingController.ts  # Rating system
│   ├── middleware/              # Request processing
│   │   ├── auth.ts             # Enhanced JWT authentication (30-day)
│   │   ├── roleAuth.ts         # Role-based access control
│   │   └── validation.ts       # Input validation (Joi)
│   ├── models/                 # Sequelize models
│   │   ├── User.ts
│   │   ├── CoffeeShop.ts
│   │   ├── Redemption.ts
│   │   ├── Rating.ts
│   │   ├── SubscriptionPlan.ts # ✅ ACTIVE
│   │   └── UserSubscription.ts # ✅ ACTIVE
│   ├── routes/                 # API endpoints
│   │   ├── auth.ts             # Authentication routes
│   │   ├── users.ts            # User management + subscription routes
│   │   ├── coffeeShops.ts      # Shop management routes
│   │   ├── redemptions.ts      # QR & enhanced statistics routes
│   │   └── ratings.ts          # Rating system routes
│   └── utils/
│       ├── jwt.ts              # JWT token operations (30-day expiry)
│       ├── validation.ts       # Joi validation schemas
│       └── coffeeShopHelpers.ts # Time validation helpers
├── package.json
├── tsconfig.json
└── .env
```

### Key Architectural Patterns

#### Enhanced JWT Management
```typescript
// NEW: Extended JWT expiry and enhanced validation
export const generateToken = (payload: any): string => {
    return jwt.sign(payload, process.env.JWT_SECRET!, {
        expiresIn: '30d', // UPDATED: Extended from default to 30 days
        algorithm: 'HS256'
    });
};

// Enhanced middleware with session expiry detection
export const authenticateToken = async (req: Request, res: Response, next: NextFunction) => {
    try {
        const token = authHeader && authHeader.split(' ')[1];
        if (!token) {
            return res.status(401).json({ 
                error: 'Access token required',
                errorCode: 'TOKEN_MISSING' 
            });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
        
        // Enhanced user validation
        const user = await User.findByPk(decoded.userId);
        if (!user || !user.isActive) {
            return res.status(401).json({ 
                error: 'Invalid token or user not found',
                errorCode: 'TOKEN_INVALID'
            });
        }

        req.user = { userId: user.id, email: user.email, role: user.role };
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ 
                error: 'Token has expired',
                errorCode: 'TOKEN_EXPIRED' 
            });
        }
        return res.status(403).json({ 
            error: 'Invalid or expired token',
            errorCode: 'TOKEN_INVALID' 
        });
    }
};
```

#### Enhanced Monthly Statistics Controller
```typescript
// UPDATED: Enhanced monthly stats with remaining redemptions
export const getMonthlyRedemptionStats = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        
        // Get user's active subscription with plan details
        const activeSubscription = await UserSubscription.findOne({
            where: { user_id: userId, status: 'active' },
            include: [{ 
                model: SubscriptionPlan, 
                as: 'subscriptionPlan' 
            }]
        });

        const monthlyLimit = activeSubscription?.subscriptionPlan?.monthly_coffee_limit || 0;
        
        // Count only subscription redemptions for monthly limit
        const subscriptionRedeemed = redemptions.filter(r => r.redemption_type === 'subscription').length;
        const remainingMonthly = Math.max(0, monthlyLimit - subscriptionRedeemed);

        const monthlyStats = {
            month: currentMonth,
            subscription: {
                hasActiveSubscription: !!activeSubscription,
                planName: activeSubscription?.subscriptionPlan?.name,
                monthlyLimit,
                remainingMonthly, // NEW: Key metric for UI
                canRedeemSubscription: remainingMonthly > 0
            },
            redeemed: { total: redemptions.length, subscription: subscriptionRedeemed, joker: jokerRedeemed },
            available: { jokers: user.jokerCount }
        };

        res.json({ success: true, data: monthlyStats });
    } catch (error) {
        console.error('Monthly stats error:', error);
        res.status(500).json({ error: 'Failed to get monthly statistics' });
    }
};
```

---

## Frontend Architecture

### Project Structure
```
lib/
├── main.dart                    # App entry point + environment initialization
├── config/                      # ✅ NEW: Environment configuration
│   └── app_config.dart          # Centralized environment settings
├── services/                    # API integration
│   ├── api_service.dart         # ✅ NEW: Centralized HTTP service
│   ├── auth_service.dart        # Enhanced authentication with session handling
│   ├── redemption_service.dart  # Enhanced redemption + session detection
│   ├── monthly_stats_service.dart # Environment-aware statistics
│   └── subscription_service.dart # Subscription API integration
├── screens/                     # UI screens
│   ├── home_screen.dart         # Customer dashboard
│   ├── coffee_shop_home_screen.dart # Enhanced shop dashboard
│   ├── map_screen.dart          # Shop discovery
│   ├── login_screen.dart        # Authentication
│   ├── profile_screen.dart      # User profile
│   └── coffee_shop_scanner_screen.dart # QR scanner
├── widgets/                     # Reusable components
│   ├── app_header.dart          # Common header
│   ├── coffee_bottom_nav.dart   # Role-aware navigation
│   ├── coffee_stats_card.dart   # Enhanced statistics display (remaining count)
│   ├── daily_coffee_card.dart   # Coffee availability with subscription highlighting
│   ├── redemption_selection_modal.dart # Enhanced QR generation with session handling
│   └── overlapping_content_layout.dart # Layout component
└── utils/                       # Helper functions
    └── admin_interface_helper.dart # Role detection
```

### Key Architectural Patterns

#### Environment Configuration System ✅ **NEW**
```dart
// lib/config/app_config.dart - Centralized configuration
class AppConfig {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Environment detection
  static bool get isDevelopment => _environment == 'development';
  static bool get isProduction => _environment == 'production';

  // API Configuration
  static String get apiBaseUrl {
    switch (_environment) {
      case 'production':
        return 'https://mochapoint.coffee/api';
      case 'development':
      default:
        return 'http://192.168.1.109:8000/api'; // Local development
    }
  }

  // Feature flags
  static bool get enableLogging => isDevelopment;
  static bool get enableDebugFeatures => isDevelopment;
  static Duration get apiTimeout => isDevelopment 
      ? const Duration(seconds: 30) 
      : const Duration(seconds: 10);
}
```

#### Enhanced API Service Pattern ✅ **NEW**
```dart
// lib/services/api_service.dart - Centralized HTTP handling
class ApiService {
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = '${AppConfig.apiBaseUrl}$endpoint';
    final headers = await AuthService.getAuthHeaders();

    if (AppConfig.enableLogging) {
      print('🌐 ApiService GET: $url');
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(AppConfig.apiTimeout);

      return _handleResponse(response);
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ ApiService Error: $e');
      }
      throw _handleError(e);
    }
  }

  // Enhanced error handling with session detection
  static dynamic _handleError(dynamic error) {
    if (error.toString().contains('TOKEN_EXPIRED')) {
      return SessionExpiredException('Your session has expired. Please log in again.');
    }
    return NetworkException('Network error: $error');
  }
}
```

#### Enhanced Statistics Display ✅ **UPDATED**
```dart
// lib/widgets/coffee_stats_card.dart - Shows remaining monthly redemptions
class CoffeeStatsCard extends StatefulWidget {
  final int? fallbackRemainingCount; // UPDATED: Was fallbackAvailableCount
  final String? fallbackMonth;
  final int? fallbackRedeemedCount;
  final int? fallbackJokersCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // NEW: Shows subscription plan name if available
          if (_monthlyStats?.subscriptionPlanName != null)
            Text(_monthlyStats!.subscriptionPlanName!),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Remaining', // UPDATED: Was "Available" 
                '${_monthlyStats?.remainingMonthly ?? fallbackRemainingCount ?? 0}',
                Icons.coffee, // UPDATED: More specific icon
                _monthlyStats?.remainingMonthly == 0 ? Colors.grey : null, // Visual feedback
              ),
              _buildStatItem('Redeemed', '${_monthlyStats?.totalRedeemed ?? 0}', Icons.check_circle),
              _buildStatItem('Jokers', '${_monthlyStats?.jokersAvailable ?? 0}', Icons.stars),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### Enhanced Session Management ✅ **NEW**
```dart
// lib/services/auth_service.dart - Session expiry handling
class AuthService {
  // Enhanced validation with detailed results
  static Future<AuthValidationResult> isAuthenticatedDetailed() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthValidationResult(isValid: false, isExpired: false);
      }

      // Test token with API call
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/profile'),
        headers: await getAuthHeaders(),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 401) {
        final body = json.decode(response.body);
        final isExpired = body['errorCode'] == 'TOKEN_EXPIRED';
        
        if (isExpired && AppConfig.enableLogging) {
          print('🔒 AuthService: Token expired, clearing session');
        }
        
        return AuthValidationResult(isValid: false, isExpired: isExpired);
      }

      return AuthValidationResult(isValid: response.statusCode == 200, isExpired: false);
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('❌ AuthService: Validation error: $e');
      }
      return AuthValidationResult(isValid: false, isExpired: false);
    }
  }
}

class AuthValidationResult {
  final bool isValid;
  final bool isExpired;
  
  AuthValidationResult({required this.isValid, required this.isExpired});
}
```

---

## Environment Configuration

### Development vs Production Settings

#### Environment Detection
```dart
// Automatic environment detection via dart-define
flutter run --dart-define=ENVIRONMENT=development  # Development
flutter run --dart-define=ENVIRONMENT=production   # Production
```

#### Configuration Matrix

| Setting | Development | Production |
|---------|-------------|------------|
| **API Base URL** | `http://192.168.1.109:8000/api` | `https://mochapoint.coffee/api` |
| **Debug Logging** | Enabled | Disabled |
| **API Timeout** | 30 seconds | 10 seconds |
| **Debug Features** | Enabled | Disabled |
| **Error Reporting** | Console only | Crash reporting |
| **JWT Expiry** | 30 days | 30 days |

#### Build Configurations

```bash
# Development builds
flutter run --dart-define=ENVIRONMENT=development

# Production builds
flutter build apk --release --dart-define=ENVIRONMENT=production
flutter build appbundle --release --dart-define=ENVIRONMENT=production
flutter build ios --release --dart-define=ENVIRONMENT=production
```

### Android Studio Integration

```xml
<!-- Android Studio Run Configurations -->
Configuration: Development
- Additional run args: --dart-define=ENVIRONMENT=development

Configuration: Production  
- Additional run args: --dart-define=ENVIRONMENT=production

Configuration: Production Release
- Additional run args: --dart-define=ENVIRONMENT=production
- Build mode: release
```

---

## Security Architecture

### Enhanced Authentication Flow
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Login    │───►│  JWT Generation │───►│ Enhanced Storage│
│                 │    │                 │    │                 │
│ • Email/Pass    │    │ • User Claims   │    │ • SharedPrefs   │
│ • Google OAuth  │    │ • Role Info     │    │ • 30-day Expiry │
│ • Apple Sign-In │    │ • 30-day Expiry │    │ • Auto Detection│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│Enhanced Validation│   │ API Middleware  │    │Session Management│
│                 │    │                 │    │                 │
│ • JWT Verify    │    │ • Extract Token │    │ • Expiry Detection│
│ • Expiry Check  │    │ • Enhanced User │    │ • Auto Logout   │
│ • User Active   │    │ • Error Codes   │    │ • Re-auth Flow  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### QR Code Security (Enhanced)
```typescript
// Multi-layer QR security with extended validation
const qrPayload = {
    userId: user.id,
    redemptionType: 'subscription',
    generatedAt: Date.now(),
    expiresAt: midnight.getTime(), // Daily expiry
    nonce: crypto.randomBytes(16).toString('hex'), // Prevent replay attacks
    shopId?: specificShopId, // Optional shop targeting
    sessionId: generateSessionId(), // NEW: Session validation
};

const qrToken = jwt.sign(qrPayload, process.env.JWT_SECRET!, {
    expiresIn: timeUntilMidnight,
    algorithm: 'HS256',
    issuer: 'mochapoint-api', // NEW: Issuer validation
});
```

### Security Measures (Enhanced)
- **Password Hashing**: bcrypt with 12 salt rounds
- **JWT Tokens**: HS256 algorithm with 30-day expiry and enhanced validation
- **Session Management**: Automatic expiry detection and re-authentication
- **CORS Configuration**: Restricted origins for API access
- **Input Validation**: Joi schemas for all API inputs
- **SQL Injection Prevention**: Sequelize ORM parameterized queries
- **XSS Protection**: JSON response sanitization
- **Environment Security**: Separate configurations for dev/prod
- **Rate Limiting**: API endpoint throttling (planned)

---

## Performance Considerations

### Enhanced Database Optimization
```sql
-- Strategic indexing for subscription system
CREATE INDEX CONCURRENTLY idx_redemptions_user_month 
    ON redemptions(user_id, date_trunc('month', timestamp));

CREATE INDEX CONCURRENTLY idx_coffee_shops_active_location 
    ON coffee_shops(is_active, latitude, longitude) WHERE is_active = true;

-- NEW: Subscription-specific indexes
CREATE INDEX CONCURRENTLY idx_user_subscriptions_active_user
    ON user_subscriptions(user_id, status) WHERE status = 'active';

CREATE INDEX CONCURRENTLY idx_subscription_plans_monthly_limit
    ON subscription_plans(monthly_coffee_limit) WHERE is_active = true;

-- Partial indexes for better performance
CREATE INDEX CONCURRENTLY idx_users_active_email 
    ON users(email) WHERE is_active = true;
```

### API Response Optimization (Enhanced)
```typescript
// Efficient data serialization with subscription data
const optimizedShopData = {
    id: shop.id,
    name: shop.name,
    distance: calculateDistance(userLat, userLng, shop.latitude, shop.longitude),
    rating: Math.max(shop.app_rating, shop.google_rating || 0),
    subscriptionEnabled: shop.subscription_enabled,
    // NEW: Include subscription status for highlighting
    isSubscriptionAccessible: userSubscription?.accessibleShopIds?.includes(shop.id),
};

// Enhanced monthly stats calculation
const monthlyStatsOptimized = {
    month: currentMonth,
    subscription: {
        hasActiveSubscription: !!activeSubscription,
        planName: activeSubscription?.subscriptionPlan?.name,
        monthlyLimit: activeSubscription?.subscriptionPlan?.monthly_coffee_limit || 0,
        remainingMonthly: Math.max(0, monthlyLimit - subscriptionRedeemed), // Key optimization
    }
};
```

### Frontend Performance (Enhanced)
```dart
// Efficient widget rebuilding with environment awareness
class OptimizedStatsCard extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonthlyStatsData>(
      future: _statsFuture, // Cache future to prevent rebuilds
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildStatsDisplay(snapshot.data!);
        }
        if (snapshot.hasError) {
          // Enhanced error handling
          if (snapshot.error is SessionExpiredException) {
            return _buildSessionExpiredWidget();
          }
          return _buildErrorState();
        }
        return _buildLoadingState();
      },
    );
  }
}

// Memory management with environment awareness
@override
void dispose() {
  _timer?.cancel(); // Prevent memory leaks
  _animationController.dispose();
  if (AppConfig.enableLogging) {
    print('🗑️ Disposing OptimizedStatsCard');
  }
  super.dispose();
}
```

### Caching Strategy (Enhanced)
- **Database**: Query result caching for static data with subscription awareness
- **API**: Response caching with subscription-specific TTL
- **Mobile**: SharedPreferences for user data and subscription status
- **Images**: Network image caching for shop logos
- **Environment**: Configuration caching to prevent repeated environment checks
- **Session**: Token validation caching with expiry detection

### Performance Monitoring
```dart
// Environment-aware performance monitoring
class PerformanceMonitor {
  static void logApiCall(String endpoint, Duration duration) {
    if (AppConfig.enableLogging) {
      print('⏱️ API Call: $endpoint took ${duration.inMilliseconds}ms');
      
      if (duration.inMilliseconds > 5000) {
        print('⚠️ Slow API call detected: $endpoint');
      }
    }
  }
  
  static void logScreenLoad(String screenName, Duration duration) {
    if (AppConfig.enableLogging) {
      print('📱 Screen Load: $screenName took ${duration.inMilliseconds}ms');
    }
  }
}
```

---

## Deployment Architecture

### Environment-Specific Deployments

#### Development Environment
```yaml
# Development deployment configuration
environment: development
api_url: http://localhost:8000/api
features:
  - debug_logging: true
  - debug_features: true
  - extended_timeouts: true
monitoring:
  - console_logging: enabled
  - crash_reporting: disabled
```

#### Production Environment
```yaml
# Production deployment configuration
environment: production
api_url: https://mochapoint.coffee/api
features:
  - debug_logging: false
  - debug_features: false
  - optimized_timeouts: true
monitoring:
  - console_logging: errors_only
  - crash_reporting: enabled
  - analytics: enabled
```

### CI/CD Pipeline Integration
```yaml
# GitHub Actions example
name: Build and Deploy
on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Development
        if: github.ref == 'refs/heads/develop'
        run: |
          flutter build apk --dart-define=ENVIRONMENT=development
          
      - name: Build Production
        if: github.ref == 'refs/heads/main'
        run: |
          flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

---

This enhanced architecture provides a robust foundation for MochaPoint's continued growth, with environment management, enhanced security, session handling, and subscription system integration built-in from the ground up. The system now handles both development and production deployments seamlessly while maintaining high performance and security standards.
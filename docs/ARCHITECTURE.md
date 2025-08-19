# System Architecture

> Technical overview of MochaPoint's system design, database schema, and technology stack

## 📋 Table of Contents
- [Technology Stack](#technology-stack)
- [System Overview](#system-overview)
- [Database Schema](#database-schema)
- [Backend Architecture](#backend-architecture)
- [Frontend Architecture](#frontend-architecture)
- [Security Architecture](#security-architecture)
- [Performance Considerations](#performance-considerations)

---

## Technology Stack

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js + TypeScript
- **Database**: PostgreSQL 17+ with Sequelize ORM
- **Authentication**: JWT + OAuth (Google/Apple)
- **Security**: bcrypt password hashing

### Frontend
- **Framework**: Flutter (Cross-platform iOS/Android)
- **UI**: Material Design with custom components
- **State Management**: StatefulWidget + Provider pattern
- **HTTP Client**: dart:http with custom services

### Infrastructure
- **API Architecture**: RESTful with JWT authentication
- **QR System**: JWT-signed tokens with time validation
- **Database**: ACID-compliant with proper indexing
- **Security**: Role-based access control (RBAC)

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
│  │ • State Mgmt    │    │ • Rate Limiting │    │ • Indexing      │
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
│  └─────────────────┘    └─────────────────┘    └─────────────────┘
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User Action** → Flutter UI captures user interaction
2. **Service Call** → Flutter service makes authenticated HTTP request
3. **API Gateway** → Express middleware validates JWT and permissions
4. **Business Logic** → Controller processes request and applies rules
5. **Database Operation** → Sequelize ORM executes optimized queries
6. **Response** → Structured JSON response with proper error handling
7. **UI Update** → Flutter updates interface with new data

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

### Future Tables (Database Ready)

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
│   │   ├── userController.ts    # User management
│   │   ├── coffeeShopController.ts # Shop operations
│   │   ├── redemptionController.ts # QR system & stats
│   │   └── ratingController.ts  # Rating system
│   ├── middleware/              # Request processing
│   │   ├── auth.ts             # JWT authentication
│   │   ├── roleAuth.ts         # Role-based access control
│   │   └── validation.ts       # Input validation (Joi)
│   ├── models/                 # Sequelize models
│   │   ├── User.ts
│   │   ├── CoffeeShop.ts
│   │   ├── Redemption.ts
│   │   └── Rating.ts
│   ├── routes/                 # API endpoints
│   │   ├── auth.ts             # Authentication routes
│   │   ├── users.ts            # User management routes
│   │   ├── coffeeShops.ts      # Shop management routes
│   │   ├── redemptions.ts      # QR & statistics routes
│   │   └── ratings.ts          # Rating system routes
│   └── utils/
│       ├── jwt.ts              # JWT token operations
│       ├── validation.ts       # Joi validation schemas
│       └── coffeeShopHelpers.ts # Time validation helpers
├── package.json
├── tsconfig.json
└── .env
```

### Key Architectural Patterns

#### Controller Pattern
```typescript
// Business logic separated from routing
export const getMonthlyRedemptionStats = async (req: Request, res: Response) => {
    try {
        const userId = req.user?.userId;
        
        // Validation
        if (!userId) {
            return res.status(401).json({ error: 'User not authenticated' });
        }

        // Business logic
        const monthlyStats = await calculateMonthlyStats(userId);
        
        // Response
        res.json({ success: true, data: monthlyStats });
    } catch (error) {
        console.error('Monthly stats error:', error);
        res.status(500).json({ error: 'Failed to get monthly statistics' });
    }
};
```

#### Middleware Pattern
```typescript
// Composable request processing
export const authenticateToken = async (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET!) as any;
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(403).json({ error: 'Invalid token' });
    }
};

// Role-based access control
export const requireRole = (roles: string[]) => {
    return (req: Request, res: Response, next: NextFunction) => {
        if (!roles.includes(req.user?.role)) {
            return res.status(403).json({ error: 'Insufficient permissions' });
        }
        next();
    };
};
```

#### Service Layer Pattern
```typescript
// Reusable business logic
class RedemptionService {
    static async generateQRToken(user: User, redemptionType: string): Promise<string> {
        // Validation logic
        const canRedeem = await this.checkUserCanRedeem(user, redemptionType);
        if (!canRedeem.allowed) {
            throw new Error(canRedeem.reason);
        }

        // Token generation
        const qrPayload = {
            userId: user.id,
            redemptionType,
            generatedAt: Date.now(),
            nonce: crypto.randomBytes(16).toString('hex'),
        };

        return jwt.sign(qrPayload, process.env.JWT_SECRET!);
    }
}
```

---

## Frontend Architecture

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── screens/                     # UI screens
│   ├── home_screen.dart         # Customer dashboard
│   ├── coffee_shop_home_screen.dart # Shop dashboard
│   ├── map_screen.dart          # Shop discovery
│   ├── login_screen.dart        # Authentication
│   ├── profile_screen.dart      # User profile
│   └── coffee_shop_scanner_screen.dart # QR scanner
├── services/                    # API integration
│   ├── auth_service.dart        # Authentication API
│   ├── monthly_stats_service.dart # Statistics API
│   ├── redemption_service.dart  # Redemption API
│   └── google_auth_webview.dart # OAuth integration
├── widgets/                     # Reusable components
│   ├── app_header.dart          # Common header
│   ├── coffee_bottom_nav.dart   # Role-aware navigation
│   ├── coffee_stats_card.dart   # Statistics display
│   ├── daily_coffee_card.dart   # Coffee availability
│   ├── redemption_selection_modal.dart # QR generation
│   └── overlapping_content_layout.dart # Layout component
└── utils/                       # Helper functions
    └── admin_interface_helper.dart # Role detection
```

### Key Architectural Patterns

#### Service Pattern
```dart
// API abstraction layer
class MonthlyStatsService {
  static const String baseUrl = 'http://192.168.1.109:8000/api';

  static Future<MonthlyStatsData> getMonthlyStats() async {
    final headers = await AuthService.getAuthHeaders();

    if (!headers.containsKey('Authorization')) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/redemptions/monthly-stats'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return MonthlyStatsData.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load monthly stats');
    }
  }
}
```

#### Widget State Management
```dart
// Stateful widgets with lifecycle management
class CoffeeStatsCard extends StatefulWidget {
  @override
  State<CoffeeStatsCard> createState() => _CoffeeStatsCardState();
}

class _CoffeeStatsCardState extends State<CoffeeStatsCard> {
  MonthlyStatsData? _monthlyStats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMonthlyStats();
  }

  Future<void> _loadMonthlyStats() async {
    try {
      if (!mounted) return; // Prevent memory leaks

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final stats = await MonthlyStatsService.getMonthlyStats();

      if (!mounted) return;

      setState(() {
        _monthlyStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
```

#### Role-based UI
```dart
// Dynamic interface based on user role
class CoffeeBottomNav extends StatefulWidget {
  void _handleCenterButtonTap() {
    final bool isCoffeeShopUser = _user?['role'] == 'coffee_shop';

    if (isCoffeeShopUser) {
      // Navigate to scanner screen
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => CoffeeShopScannerScreen())
      );
    } else {
      // Show QR generation modal
      showModalBottomSheet(
        context: context,
        builder: (context) => RedemptionSelectionModal(),
      );
    }
  }
}
```

---

## Security Architecture

### Authentication Flow
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Login    │───►│  JWT Generation │───►│ Token Storage   │
│                 │    │                 │    │                 │
│ • Email/Pass    │    │ • User Claims   │    │ • SharedPrefs   │
│ • Google OAuth  │    │ • Role Info     │    │ • Secure Store  │
│ • Apple Sign-In │    │ • Expiration    │    │ • Auto Refresh  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Token Validation│    │ API Middleware  │    │ Role Authorization│
│                 │    │                 │    │                 │
│ • JWT Verify    │    │ • Extract Token │    │ • Check Permissions│
│ • Expiry Check  │    │ • Attach User   │    │ • Resource Access│
│ • Signature Val │    │ • Error Handling│    │ • Admin Functions│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### QR Code Security
```typescript
// Multi-layer QR security
const qrPayload = {
    userId: user.id,
    redemptionType: 'subscription',
    generatedAt: Date.now(),
    expiresAt: midnight.getTime(),
    nonce: crypto.randomBytes(16).toString('hex'), // Prevent replay
    shopId?: specificShopId, // Optional shop targeting
};

const qrToken = jwt.sign(qrPayload, process.env.JWT_SECRET!, {
    expiresIn: timeUntilMidnight,
    algorithm: 'HS256'
});
```

### Security Measures
- **Password Hashing**: bcrypt with 12 salt rounds
- **JWT Tokens**: HS256 algorithm with role-based claims
- **CORS Configuration**: Restricted origins for API access
- **Input Validation**: Joi schemas for all API inputs
- **SQL Injection Prevention**: Sequelize ORM parameterized queries
- **XSS Protection**: JSON response sanitization
- **Rate Limiting**: API endpoint throttling (future)

---

## Performance Considerations

### Database Optimization
```sql
-- Strategic indexing for high-frequency queries
CREATE INDEX CONCURRENTLY idx_redemptions_user_month 
    ON redemptions(user_id, date_trunc('month', timestamp));

CREATE INDEX CONCURRENTLY idx_coffee_shops_active_location 
    ON coffee_shops(is_active, latitude, longitude) WHERE is_active = true;

-- Partial indexes for better performance
CREATE INDEX CONCURRENTLY idx_users_active_email 
    ON users(email) WHERE is_active = true;
```

### API Response Optimization
```typescript
// Efficient data serialization
const optimizedShopData = {
    id: shop.id,
    name: shop.name,
    distance: calculateDistance(userLat, userLng, shop.latitude, shop.longitude),
    rating: Math.max(shop.app_rating, shop.google_rating || 0),
    // Only include necessary fields
};

// Pagination for large datasets
const { limit = 20, offset = 0 } = req.query;
const shops = await CoffeeShop.findAndCountAll({
    limit: Number(limit),
    offset: Number(offset),
    order: [['created_at', 'DESC']]
});
```

### Frontend Performance
```dart
// Efficient widget rebuilding
class OptimizedStatsCard extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MonthlyStatsData>(
      future: _statsFuture, // Cache future to prevent rebuilds
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildStatsDisplay(snapshot.data!);
        }
        return _buildLoadingState();
      },
    );
  }
}

// Memory management
@override
void dispose() {
  _timer?.cancel(); // Prevent memory leaks
  _animationController.dispose();
  super.dispose();
}
```

### Caching Strategy
- **Database**: Query result caching for static data
- **API**: Response caching with appropriate TTL
- **Mobile**: SharedPreferences for user data
- **Images**: Network image caching for shop logos

---

This architecture provides a solid foundation for MochaPoint's growth, with clear separation of concerns, security best practices, and performance optimization built-in from the ground up.
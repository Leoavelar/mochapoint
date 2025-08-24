# API Reference

> Complete API documentation for MochaPoint backend services

## 📋 Table of Contents
- [Base Configuration](#base-configuration)
- [Authentication](#authentication)
- [User Management](#user-management)
- [Coffee Shop Management](#coffee-shop-management)
- [QR Redemption System](#qr-redemption-system)
- [Rating System](#rating-system)
- [Error Handling](#error-handling)
- [Testing Examples](#testing-examples)
- [Webhook Support (Future)](#webhook-support-future)
- [Environment Configuration Integration](#environment-configuration-integration)
- [SDKs and Client Libraries](#sdks-and-client-libraries)
- [API Versioning (Future)](#api-versioning-future)
- [Security Considerations](#security-considerations)
- [Migration Notes](#migration-notes)
- [Advanced Features](#advanced-features)
- [Development & Testing APIs](#development--testing-apis)
- [Error Recovery & Resilience](#error-recovery--resilience)
- [Real-time Features (Future)](#real-time-features-future)

---

## Environment Configuration Integration

### API Base URLs by Environment

| Environment | Base URL | Usage |
|-------------|----------|--------|
| Development | `http://localhost:8000/api` | Local development, debug logging |
| Production | `https://mochapoint.coffee/api` | Live production, optimized performance |

### Client Configuration
Flutter clients automatically detect environment and use appropriate base URL:

```dart
// Development
flutter run --dart-define=ENVIRONMENT=development

// Production  
flutter run --dart-define=ENVIRONMENT=production
```

### Request Headers by Environment
```http
# Development - includes debug information
X-Environment: development
X-Debug-Mode: true

# Production - optimized headers
X-Environment: production
```

---

## SDKs and Client Libraries

### Flutter Client (Included) ⭐ ENHANCED
```dart
// Example usage with environment configuration
final stats = await MonthlyStatsService.getMonthlyStats();
final remainingCoffees = stats.subscription?.remainingMonthly ?? 0;

// Enhanced QR generation with session handling
try {
  final qrToken = await RedemptionService.generateQRToken('subscription');
} on SessionExpiredException {
  // Automatically handled - shows session expired dialog
} on NetworkException {
  // Network error handling
}

// Environment-aware API calls
final coffeeShops = await ApiService.get('/coffee-shops');
```

### JavaScript/Node.js Client (Future)
```javascript
// Future SDK
const mochapoint = new MochaPointAPI(apiKey);
const stats = await mochapoint.redemptions.getMonthlyStats();
const remaining = stats.subscription.remainingMonthly;
```

---

## API Versioning (Future)

### Current Version
- **Version**: v1 (default)
- **Base URL**: `/api/` (no version prefix)

### Future Versioning Strategy
```
/api/v1/redemptions/monthly-stats  # Explicit versioning
/api/v2/redemptions/monthly-stats  # Future version with enhanced features

# Headers approach (alternative)
X-API-Version: v1
```

---

## Security Considerations

### Enhanced API Security Checklist ⭐ UPDATED
- ✅ **HTTPS Only**: All production traffic encrypted
- ✅ **JWT Authentication**: Secure 30-day token-based auth
- ✅ **Role-based Access**: Granular permission system
- ✅ **Input Validation**: Joi schema validation
- ✅ **SQL Injection Prevention**: Sequelize ORM protection
- ✅ **Session Management**: Enhanced expiry detection and automatic logout
- ✅ **Error Code System**: Specific error codes for client handling
- 🚧 **Rate Limiting**: Future implementation
- 🚧 **API Key Management**: Future enhancement for third-party access
- 🚧 **Request Logging**: Future audit trail

### Enhanced Best Practices for Clients
1. **Store JWT securely**: Use secure storage (Keychain/SharedPreferences)
2. **Handle session expiry**: Automatic logout on TOKEN_EXPIRED
3. **Environment configuration**: Use proper API endpoints per environment
4. **Validate responses**: Check response structure and error codes
5. **Implement retry logic**: Handle network failures gracefully
6. **Use HTTPS**: Always use encrypted connections
7. **Monitor performance**: Log API call durations in development

### Subscription System Security
- **Monthly Limits**: Server-side enforcement prevents over-redemption
- **QR Code Security**: Daily expiry with nonce to prevent replay attacks
- **Redemption Validation**: Separate tracking of subscription vs joker redemptions
- **Access Control**: Subscription-based shop access validation

---

## Migration Notes

### Changes from Previous Version

#### API Changes ⭐ NEW
- Extended JWT expiry from default to 30 days
- Added error codes for enhanced client-side handling
- Enhanced monthly stats endpoint with remaining redemptions
- Added redemption status endpoint
- Enhanced user subscription endpoint

#### Database Changes ⭐ NEW
- Added `monthly_coffee_limit` column to `subscription_plans`
- Enhanced subscription system with active status tracking
- Improved indexing for subscription-related queries

#### Client Changes ⭐ NEW
- Environment configuration system implemented
- Enhanced session management with automatic logout
- Updated statistics display (Available → Remaining)
- Session expiry dialog and navigation

### Breaking Changes
None - all changes are backwards compatible additions.

---

## Advanced Features

### Subscription Management ⭐ NEW

#### Create Subscription Plan (Admin Only)
```http
POST /subscription-plans
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
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
}
```

#### Create User Subscription (Admin Only)
```http
POST /user-subscriptions
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "userId": 1,
  "planId": 1,
  "status": "active",
  "startDate": "2025-01-01",
  "endDate": "2025-01-31",
  "autoRenew": true
}
```

### Analytics Endpoints ⭐ ENHANCED

#### Get User Analytics
```http
GET /analytics/user/:userId
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "userId": 1,
    "totalRedemptions": 45,
    "subscriptionRedemptions": 35,
    "jokerRedemptions": 10,
    "favoriteShops": [
      {
        "shopId": 1,
        "shopName": "Central Coffee",
        "visitCount": 15,
        "averageRating": 4.8
      }
    ],
    "monthlyTrends": [
      {
        "month": "2025-01",
        "redemptions": 12,
        "subscriptionUsage": 10,
        "jokerUsage": 2
      }
    ]
  }
}
```

#### Get Shop Analytics
```http
GET /analytics/shop/:shopId
Authorization: Bearer <SHOP_OWNER_JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "shopId": 1,
    "totalCustomers": 234,
    "subscriptionCustomers": 189,
    "avgRedemptionsPerCustomer": 3.2,
    "peakRedemptionTimes": [
      { "hour": 8, "count": 45, "percentage": 15.2 },
      { "hour": 14, "count": 38, "percentage": 12.8 }
    ],
    "monthlyGrowth": {
      "customerGrowth": 12.5,
      "redemptionGrowth": 8.3,
      "ratingImprovement": 0.2
    }
  }
}
```

### Bulk Operations ⭐ NEW

#### Bulk Add Jokers
```http
POST /users/bulk-add-jokers
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "users": [
    { "userId": 1, "count": 5 },
    { "userId": 2, "count": 3 },
    { "userId": 3, "count": 10 }
  ]
}
```

#### Bulk Update Shop Status
```http
POST /coffee-shops/bulk-update
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "shops": [
    { "shopId": 1, "isActive": true },
    { "shopId": 2, "isActive": false }
  ]
}
```

---

## Development & Testing APIs

### Test Data Endpoints (Development Only)

#### Create Test User
```http
POST /dev/create-test-user
Authorization: Bearer <ADMIN_JWT_TOKEN>
X-Environment: development
```

**Request Body:**
```json
{
  "email": "testuser@mochapoint.dev",
  "jokerCount": 10,
  "subscriptionPlan": "premium-monthly"
}
```

#### Reset User Stats
```http
POST /dev/reset-user-stats/:userId
Authorization: Bearer <ADMIN_JWT_TOKEN>
X-Environment: development
```

### Health & Status Endpoints

#### Detailed Health Check
```http
GET /health/detailed
```

**Response (200):**
```json
{
  "success": true,
  "timestamp": "2025-01-15T10:30:00.000Z",
  "services": {
    "database": {
      "status": "healthy",
      "responseTime": 12,
      "activeConnections": 5
    },
    "subscriptionSystem": {
      "status": "healthy",
      "activeSubscriptions": 234,
      "monthlyRedemptions": 1567
    },
    "qrSystem": {
      "status": "healthy",
      "activeTokens": 45,
      "dailyGenerations": 123
    }
  },
  "performance": {
    "averageResponseTime": 128,
    "requestsPerMinute": 45,
    "errorRate": 0.02
  }
}
```

#### System Status
```http
GET /status
```

**Response (200):**
```json
{
  "success": true,
  "system": {
    "version": "1.2.0",
    "environment": "production",
    "uptime": 172800,
    "lastDeployment": "2025-01-10T15:30:00.000Z"
  },
  "features": {
    "subscriptionSystem": true,
    "enhancedSessionManagement": true,
    "monthlyLimitEnforcement": true,
    "environmentConfiguration": true
  }
}
```

---

## Error Recovery & Resilience

### Circuit Breaker Pattern (Future)
```http
GET /redemptions/monthly-stats
X-Circuit-Breaker: enabled
```

**Response when circuit is open:**
```json
{
  "success": false,
  "error": "Service temporarily unavailable",
  "errorCode": "CIRCUIT_BREAKER_OPEN",
  "retryAfter": 30
}
```

### Graceful Degradation
When subscription service is unavailable, the API still provides basic functionality:

```json
{
  "success": true,
  "data": {
    "month": "January 2025",
    "subscription": {
      "hasActiveSubscription": false,
      "error": "Subscription service temporarily unavailable"
    },
    "redeemed": {
      "total": 8,
      "joker": 8
    },
    "available": {
      "jokers": 3
    }
  },
  "warnings": ["Subscription data unavailable"]
}
```

---

## Real-time Features (Future)

### WebSocket API (Planned)
```javascript
// Future WebSocket connection
const ws = new WebSocket('wss://api.mochapoint.coffee/ws');

// Real-time redemption notifications
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'REDEMPTION_COMPLETED') {
    // Update UI with new stats
    updateMonthlyStats(data.newStats);
  }
};

// Real-time shop capacity updates
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'SHOP_CAPACITY_UPDATE') {
    // Update shop availability
    updateShopCapacity(data.shopId, data.capacity);
  }
};
```

### Push Notifications (Future)
```http
POST /notifications/send
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "userId": 1,
  "type": "MONTHLY_LIMIT_RESET",
  "title": "New Month, Fresh Coffee!",
  "body": "Your monthly coffee limit has been reset. Time for your first cup!",
  "data": {
    "monthlyLimit": 25,
    "remainingMonthly": 25
  }
}
```

---

This enhanced API reference provides comprehensive documentation for all MochaPoint backend services, including the new environment configuration system, enhanced session management, subscription system integration, and future-ready features. For additional help or questions, please refer to the [GitHub repository](../../) or contact our support team. Base Configuration

### URLs
```
Development: http://localhost:8000/api (or your local IP)
Production:  https://mochapoint.coffee/api
```

### Headers
```http
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>  # For authenticated endpoints
```

### Response Format
```json
{
  "success": true,
  "data": { /* response data */ },
  "message": "Optional success message"
}
```

### Error Format
```json
{
  "success": false,
  "error": "Error message",
  "errorCode": "ERROR_CODE", // NEW: Specific error codes for client handling
  "details": { /* optional error details */ }
}
```

### Enhanced Error Codes ⭐ NEW
| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `TOKEN_MISSING` | 401 | No authorization token provided |
| `TOKEN_EXPIRED` | 401 | JWT token has expired (triggers session expiry) |
| `TOKEN_INVALID` | 403 | Invalid or malformed token |
| `INSUFFICIENT_PERMISSIONS` | 403 | User lacks required role |
| `VALIDATION_FAILED` | 400 | Input validation errors |
| `MONTHLY_LIMIT_REACHED` | 400 | Monthly subscription limit reached |
| `NO_JOKERS_AVAILABLE` | 400 | User has no jokers left |
| `QR_EXPIRED` | 400 | QR code has expired |
| `DAILY_LIMIT_REACHED` | 400 | Already redeemed today |
| `RATE_LIMITED` | 429 | Too many requests |

---

## Authentication

### Enhanced JWT Configuration ⭐ NEW
- **Token Expiry**: 30 days (extended from default)
- **Algorithm**: HS256
- **Session Detection**: Enhanced error codes for client-side session management
- **Auto-logout**: Client automatically logs out on token expiry

### Register User
```http
POST /auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (201):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // 30-day expiry
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "user",
    "subscriptionStatus": false,
    "jokerCount": 3
  }
}
```

### Register Coffee Shop
```http
POST /auth/register-coffee-shop
```

**Request Body:**
```json
{
  "email": "shop@example.com",
  "password": "securePassword123",
  "shopName": "Amazing Coffee Shop",
  "address": "Hauptplatz 1, 8010 Graz"
}
```

### Create Admin
```http
POST /auth/create-admin
```

**Request Body:**
```json
{
  "email": "admin@mochapoint.com",
  "password": "securePassword123",
  "adminSecret": "your-admin-creation-secret"
}
```

### Login
```http
POST /auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // 30-day expiry
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user",
    "subscriptionStatus": true,
    "jokerCount": 2,
    "coffeeShopId": null
  }
}
```

### Enhanced Session Expiry Handling ⭐ NEW

**Response (401) - Token Expired:**
```json
{
  "success": false,
  "error": "Token has expired",
  "errorCode": "TOKEN_EXPIRED"
}
```

This triggers automatic logout and session expired dialog in the mobile app.

### Google OAuth
```http
POST /auth/google
```

**Request Body:**
```json
{
  "googleId": "google-user-id",
  "email": "user@gmail.com",
  "name": "John Doe",
  "photoUrl": "https://...",
  "accessToken": "google-access-token"
}
```

### Apple Sign-In
```http
POST /auth/apple
```

**Request Body:**
```json
{
  "appleId": "apple-user-id",
  "email": "user@privaterelay.appleid.com",
  "name": "John Doe",
  "identityToken": "apple-identity-token"
}
```

---

## User Management

### Get User Profile
```http
GET /users/profile
Authorization: Bearer <JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user",
    "subscriptionStatus": true,
    "jokerCount": 5,
    "photoUrl": "https://...",
    "createdAt": "2025-01-01T00:00:00.000Z"
  }
}
```

### Update User Profile
```http
PUT /users/profile
Authorization: Bearer <JWT_TOKEN>
```

**Request Body:**
```json
{
  "name": "John Smith",
  "photoUrl": "https://new-photo-url.com/image.jpg"
}
```

### Add Jokers
```http
POST /users/add-jokers
Authorization: Bearer <JWT_TOKEN>
```

**Request Body:**
```json
{
  "count": 3
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "newJokerCount": 8,
    "addedCount": 3
  }
}
```

### Get User Subscription ⭐ ENHANCED
```http
GET /users/subscription
Authorization: Bearer <JWT_TOKEN>
```

**Response (200) - Active Subscription:**
```json
{
  "success": true,
  "data": {
    "hasActiveSubscription": true,
    "subscription": {
      "id": 2,
      "planName": "Premium Monthly Plan",
      "status": "active",
      "startDate": "2025-01-01",
      "endDate": "2025-12-31",
      "weeklyLimit": 5,
      "monthlyLimit": 25, // NEW: Added for remaining calculation
      "usedThisWeek": 2,
      "usedThisMonth": 7, // NEW: Added for remaining calculation
      "autoRenew": true
    },
    "accessibleShops": [
      {
        "id": 1,
        "name": "Central Coffee Graz",
        "address": "Hauptplatz 1, 8010 Graz",
        "subscriptionType": "shop-specific",
        "latitude": 47.0707,
        "longitude": 15.4395
      }
    ]
  }
}
```

**Response (200) - No Active Subscription:**
```json
{
  "success": true,
  "data": {
    "hasActiveSubscription": false,
    "subscription": null,
    "accessibleShops": []
  }
}
```

---

## Coffee Shop Management

### List Coffee Shops
```http
GET /coffee-shops
```

**Query Parameters:**
- `lat` (optional): User latitude for distance calculation
- `lng` (optional): User longitude for distance calculation
- `radius` (optional): Search radius in kilometers (default: 5)
- `active` (optional): Filter by active status (default: true)

**Example:**
```http
GET /coffee-shops?lat=47.0707&lng=15.4395&radius=10
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Central Coffee",
      "brand": "Central",
      "address": "Hauptplatz 1, 8010 Graz",
      "latitude": 47.0707,
      "longitude": 15.4395,
      "subscriptionEnabled": true,
      "jokerEnabled": true,
      "appRating": 4.5,
      "googleRating": 4.3,
      "distance": 0.5,
      "walkingTime": "6 min",
      "isOpen": true,
      "redemptionsAllowed": true,
      "isSubscriptionAccessible": true // NEW: For subscription highlighting
    }
  ]
}
```

### Get Coffee Shop Details
```http
GET /coffee-shops/:id
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Central Coffee",
    "brand": "Central",
    "address": "Hauptplatz 1, 8010 Graz",
    "latitude": 47.0707,
    "longitude": 15.4395,
    "description": "Best coffee in Graz center",
    "phone": "+43 316 123456",
    "operatingHours": {
      "monday": { "open": "07:00", "close": "19:00" },
      "tuesday": { "open": "07:00", "close": "19:00" }
    },
    "redemptionHours": {
      "monday": { "open": "08:00", "close": "18:00" }
    },
    "subscriptionEnabled": true,
    "jokerEnabled": true,
    "appRating": 4.5,
    "appRatingCount": 127,
    "googleRating": 4.3,
    "logoUrl": "central_coffee_logo.png",
    "isActive": true
  }
}
```

### Create Coffee Shop (Admin Only)
```http
POST /coffee-shops
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "name": "New Coffee Shop",
  "brand": "Brand Name",
  "address": "Street 123, 8010 Graz",
  "latitude": 47.0707,
  "longitude": 15.4395,
  "description": "Amazing coffee shop",
  "phone": "+43 316 123456",
  "operatingHours": {
    "monday": { "open": "07:00", "close": "19:00" },
    "tuesday": { "open": "07:00", "close": "19:00" }
  },
  "subscriptionEnabled": true,
  "jokerEnabled": true
}
```

### Update Coffee Shop
```http
PUT /coffee-shops/:id
Authorization: Bearer <JWT_TOKEN>  # Admin or Shop Owner
```

### Get Coffee Shop Statistics
```http
GET /coffee-shops/:shopId/stats
Authorization: Bearer <SHOP_OWNER_JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "shopId": 1,
    "totalRedemptions": 1247,
    "todayRedemptions": 23,
    "weeklyRedemptions": 156,
    "monthlyRedemptions": 634,
    "subscriptionRedemptions": 892,
    "jokerRedemptions": 355,
    "averageRating": 4.5,
    "totalRatings": 127,
    "peakHours": [
      { "hour": 8, "count": 45 },
      { "hour": 14, "count": 38 }
    ],
    "popularCoffeeTypes": [
      { "type": "Cappuccino", "count": 234 },
      { "type": "Espresso", "count": 189 }
    ]
  }
}
```

---

## QR Redemption System

### Generate QR Token
```http
POST /redemptions/generate-qr
Authorization: Bearer <USER_JWT_TOKEN>
```

**Request Body:**
```json
{
  "redemptionType": "subscription",  // or "joker"
  "shopId": 1  // Optional: specific shop validation
}
```

**Response (200):**
```json
{
  "success": true,
  "qrToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInJlZGVtcHRpb25UeXBlIjoic3Vic2NyaXB0aW9uIiwiZ2VuZXJhdGVkQXQiOjE2NzE4NzQ4MDAwMDAsImV4cGlyZXNBdCI6MTY3MTkyOTU5OTk5OSwibm9uY2UiOiJhYmMxMjMifQ.signature",
  "expiresAt": "2025-01-15T23:59:59.999Z",
  "userInfo": {
    "name": "John Doe",
    "email": "user@example.com",
    "subscriptionStatus": true,
    "jokerCount": 5
  }
}
```

**Error Response (400) - No Monthly Redemptions Left:**
```json
{
  "success": false,
  "error": "Monthly subscription limit reached",
  "errorCode": "MONTHLY_LIMIT_REACHED",
  "nextAvailableAt": "2025-02-01T00:00:00.000Z"
}
```

**Error Response (400) - No Jokers:**
```json
{
  "success": false,
  "error": "No jokers available",
  "errorCode": "NO_JOKERS_AVAILABLE"
}
```

### Validate and Redeem QR Code
```http
POST /redemptions/validate-and-redeem
Authorization: Bearer <COFFEE_SHOP_JWT_TOKEN>
```

**Request Body:**
```json
{
  "qrToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "coffeeType": "Cappuccino"  // Optional: for analytics
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Coffee redeemed successfully",
  "customer": {
    "name": "John Doe",
    "email": "user@example.com",
    "redemptionType": "subscription",
    "subscriptionInfo": {
      "hasSubscription": true,
      "bundleName": "Premium Monthly",
      "remainingMonthly": 17 // NEW: Remaining this month
    },
    "remainingJokers": 5
  },
  "redemption": {
    "coffeeShop": "Central Coffee",
    "timestamp": "2025-01-15T10:30:00.000Z",
    "coffeeType": "Cappuccino"
  }
}
```

### Get Redemption History
```http
GET /redemptions/history?limit=20&offset=0
Authorization: Bearer <USER_JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "redemptions": [
    {
      "id": 123,
      "redemptionType": "subscription",
      "timestamp": "2025-01-15T10:30:00.000Z",
      "coffeeType": "Cappuccino",
      "coffeeShop": {
        "id": 1,
        "name": "Central Coffee",
        "address": "Hauptplatz 1, 8010 Graz"
      }
    }
  ],
  "total": 45,
  "hasMore": true
}
```

### Get Redemption Status ⭐ NEW
```http
GET /redemptions/status
Authorization: Bearer <USER_JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "status": {
    "jokerCount": 5,
    "subscriptionInfo": {
      "hasSubscription": true,
      "bundleName": "Premium Monthly",
      "monthlyLimit": 25,
      "usedThisMonth": 8,
      "remainingMonthly": 17, // NEW: Key metric
      "canRedeemSubscription": true
    },
    "weeklyRedemptions": 3,
    "todayRedemptions": 1,
    "canRedeemJoker": true,
    "nextRedemptionAvailable": null
  }
}
```

### Get Monthly Statistics ⭐ ENHANCED
```http
GET /redemptions/monthly-stats
Authorization: Bearer <USER_JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "month": "January 2025",
    "period": {
      "start": "2025-01-01T00:00:00.000Z",
      "end": "2025-01-31T23:59:59.999Z"
    },
    "subscription": {
      "hasActiveSubscription": true,
      "planName": "Premium Monthly Plan",
      "monthlyLimit": 25, // NEW: Monthly limit from subscription plan
      "usedThisMonth": 8, // NEW: Subscription redemptions this month
      "remainingMonthly": 17, // NEW: Key metric - shown as "Remaining" in app
      "canRedeemSubscription": true
    },
    "redeemed": {
      "total": 10, // All redemptions (subscription + joker)
      "subscription": 8, // Only subscription redemptions (counted against monthly limit)
      "joker": 2 // Joker redemptions (don't count against subscription limit)
    },
    "available": {
      "jokers": 3 // Available jokers
    },
    "redemptionHistory": [
      {
        "id": 156,
        "type": "subscription",
        "timestamp": "2025-01-15T10:30:00.000Z",
        "coffeeType": "Cappuccino",
        "coffeeShop": {
          "id": 1,
          "name": "Central Coffee"
        }
      },
      {
        "id": 155,
        "type": "joker",
        "timestamp": "2025-01-14T14:15:00.000Z",
        "coffeeType": "Espresso",
        "coffeeShop": {
          "id": 2,
          "name": "Corner Cafe"
        }
      }
    ]
  }
}
```

**Key Changes in Monthly Stats:**
- ✅ **remainingMonthly**: Shows remaining subscription coffees for the month
- ✅ **Separation**: Joker redemptions don't count against subscription monthly limit
- ✅ **UI Integration**: "Remaining" count in app shows `remainingMonthly` value

**Error Response (401) - Session Expired:**
```json
{
  "success": false,
  "error": "Token has expired",
  "errorCode": "TOKEN_EXPIRED"
}
```

---

## Rating System

### Create/Update Rating
```http
POST /ratings
Authorization: Bearer <USER_JWT_TOKEN>
```

**Request Body:**
```json
{
  "shopId": 1,
  "rating": 5,
  "comment": "Amazing coffee and great service!"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": 45,
    "userId": 1,
    "shopId": 1,
    "rating": 5,
    "comment": "Amazing coffee and great service!",
    "createdAt": "2025-01-15T10:30:00.000Z"
  }
}
```

### Get Shop Ratings
```http
GET /ratings/shop/:shopId
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "shopId": 1,
    "averageRating": 4.5,
    "totalRatings": 127,
    "ratingDistribution": {
      "5": 65,
      "4": 35,
      "3": 15,
      "2": 8,
      "1": 4
    },
    "recentRatings": [
      {
        "id": 45,
        "rating": 5,
        "comment": "Amazing coffee and great service!",
        "userName": "John D.",
        "createdAt": "2025-01-15T10:30:00.000Z"
      }
    ]
  }
}
```

---

## Error Handling

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (no token, expired token, invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 429 | Too Many Requests (rate limited) |
| 500 | Internal Server Error |

### Enhanced Authentication Errors ⭐ NEW

#### Session Management Errors
```json
// 401 - No token provided
{
  "success": false,
  "error": "Access token required",
  "errorCode": "TOKEN_MISSING"
}

// 401 - Token expired (triggers automatic logout)
{
  "success": false,
  "error": "Token has expired",
  "errorCode": "TOKEN_EXPIRED"
}

// 403 - Invalid token
{
  "success": false,
  "error": "Invalid token",
  "errorCode": "TOKEN_INVALID"
}

// 403 - Insufficient permissions
{
  "success": false,
  "error": "Insufficient permissions",
  "errorCode": "INSUFFICIENT_PERMISSIONS"
}
```

#### Validation Errors
```json
// 400 - Input validation failed
{
  "success": false,
  "error": "Validation failed",
  "errorCode": "VALIDATION_FAILED",
  "details": {
    "email": "Email is required",
    "password": "Password must be at least 6 characters"
  }
}
```

#### Business Logic Errors
```json
// 400 - Monthly subscription limit reached
{
  "success": false,
  "error": "Monthly subscription limit reached",
  "errorCode": "MONTHLY_LIMIT_REACHED",
  "nextAvailableAt": "2025-02-01T00:00:00.000Z"
}

// 400 - No jokers available
{
  "success": false,
  "error": "No jokers available",
  "errorCode": "NO_JOKERS_AVAILABLE"
}

// 400 - QR code expired
{
  "success": false,
  "error": "Invalid or expired QR code",
  "errorCode": "QR_EXPIRED"
}

// 400 - Already redeemed today (subscription)
{
  "success": false,
  "error": "You have already redeemed your daily coffee",
  "errorCode": "DAILY_LIMIT_REACHED",
  "nextAvailableAt": "2025-01-16T00:00:00.000Z"
}
```

### Client-Side Error Handling

The Flutter app now automatically handles these error codes:

- **TOKEN_EXPIRED**: Shows session expired dialog → redirects to login
- **TOKEN_MISSING/TOKEN_INVALID**: Clears stored token → redirects to login
- **MONTHLY_LIMIT_REACHED**: Shows specific message with next available date
- **NO_JOKERS_AVAILABLE**: Prompts user to purchase more jokers
- **DAILY_LIMIT_REACHED**: Shows countdown to next redemption

---

## Testing Examples

### Complete Authentication Flow
```bash
# 1. Register user
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 2. Login and get 30-day token
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 3. Use token for authenticated requests (valid for 30 days)
export TOKEN="your-jwt-token-here"
```

### Enhanced QR Redemption Flow
```bash
# 1. Check redemption status first (NEW)
curl -X GET http://localhost:8000/api/redemptions/status \
  -H "Authorization: Bearer $USER_TOKEN"

# 2. Generate QR token (User) - now with monthly limit checking
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}'

# 3. Validate QR token (Coffee Shop)
curl -X POST http://localhost:8000/api/redemptions/validate-and-redeem \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "qrToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "coffeeType": "Cappuccino"
  }'

# 4. Check enhanced monthly statistics
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN"
```

### Enhanced Subscription System Testing
```bash
# 1. Get user subscription details
curl -X GET http://localhost:8000/api/users/subscription \
  -H "Authorization: Bearer $USER_TOKEN"

# Response shows monthly limits and accessible shops

# 2. Test monthly limit enforcement
# Try to redeem when monthly limit is reached
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}'

# Should return: "Monthly subscription limit reached"
```

### Session Expiry Testing ⭐ NEW
```bash
# 1. Test with expired token
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer expired-token"

# Expected response:
# {
#   "success": false,
#   "error": "Token has expired",
#   "errorCode": "TOKEN_EXPIRED"
# }

# 2. Test with no token
curl -X GET http://localhost:8000/api/redemptions/monthly-stats

# Expected response:
# {
#   "success": false,
#   "error": "Access token required",
#   "errorCode": "TOKEN_MISSING"
# }

# 3. Test with invalid token
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer invalid-token"

# Expected response:
# {
#   "success": false,
#   "error": "Invalid token",
#   "errorCode": "TOKEN_INVALID"
# }
```

### Coffee Shop Management
```bash
# 1. Create admin user
curl -X POST http://localhost:8000/api/auth/create-admin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@mochapoint.com",
    "password": "securePassword123",
    "adminSecret": "your-admin-secret"
  }'

# 2. Create coffee shop
curl -X POST http://localhost:8000/api/coffee-shops \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Coffee Shop",
    "address": "Hauptplatz 1, 8010 Graz",
    "latitude": 47.0707,
    "longitude": 15.4395,
    "subscriptionEnabled": true,
    "jokerEnabled": true
  }'

# 3. Get shop statistics (enhanced)
curl -X GET http://localhost:8000/api/coffee-shops/1/stats \
  -H "Authorization: Bearer $SHOP_OWNER_TOKEN"
```

### Rating System Testing
```bash
# 1. Submit rating
curl -X POST http://localhost:8000/api/ratings \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "shopId": 1,
    "rating": 5,
    "comment": "Excellent coffee!"
  }'

# 2. Get shop ratings
curl -X GET http://localhost:8000/api/ratings/shop/1
```

### Data Validation Examples
```bash
# Test enhanced monthly stats response structure
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN" | jq '.data.subscription.remainingMonthly'

# Test monthly limit enforcement
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}' | jq '.errorCode'

# Should return "MONTHLY_LIMIT_REACHED" when limit is reached

# Test session expiry detection
curl -X GET http://localhost:8000/api/redemptions/monthly-stats
# Should return 401 with errorCode: "TOKEN_MISSING"
```

---

## Rate Limiting & Performance

### Current Limits
- **General API**: No rate limiting implemented (future enhancement)
- **QR Generation**: 1 subscription token per day + monthly limit enforcement
- **Authentication**: No login attempt limiting (future enhancement)
- **Session Management**: 30-day JWT tokens with automatic expiry detection

### Performance Notes
- **Response Times**: Target < 200ms for most endpoints
- **Database Queries**: Optimized with strategic indexing for subscription system
- **Pagination**: Available on history endpoints (limit/offset)
- **Caching**: Future enhancement for static data
- **Monthly Stats**: Optimized calculation using database aggregations

---

## Webhook Support (Future)

### Planned Webhooks
```http
POST /webhooks/stripe
Content-Type: application/json
Stripe-Signature: t=1234567890,v1=signature

# For subscription payment events
```

### Webhook Events (Future)
- `subscription.created`
- `subscription.cancelled`
- `subscription.payment_succeeded`
- `subscription.payment_failed`
- `monthly_limit.reset` (first day of month)

---

## Environment Configuration Integration

### API Base URLs by Environment

| Environment | Base URL | Usage |
|-------------|----------|--------|
| Development | `http://localhost:8000/api` | Local development, debug logging |
| Production | `https://mochapoint.coffee/api` | Live production, optimized performance |

### Client Configuration
Flutter clients automatically detect environment and use appropriate base URL:

```dart
// Development
flutter run --dart-define=ENVIRONMENT=development

// Production  
flutter run --dart-define=ENVIRONMENT=production
```

### Request Headers by Environment
```http
# Development - includes debug information
X-Environment: development
X-Debug-Mode: true

# Production - optimized headers
X-Environment: production
```

---

## SDKs and Client Libraries

### Flutter Client (Included) ⭐ ENHANCED
```dart
// Example usage with environment configuration
final stats = await MonthlyStatsService.getMonthlyStats();
final remainingCoffees = stats.subscription?.remainingMonthly ?? 0;

// Enhanced QR generation with session handling
try {
  final qrToken = await RedemptionService.generateQRToken('subscription');
} on SessionExpiredException {
  // Automatically handled - shows session expired dialog
} on NetworkException {
  // Network error handling
}

// Environment-aware API calls
final coffeeShops = await ApiService.get('/coffee-shops');
```

### JavaScript/Node.js Client (Future)
```javascript
// Future SDK
const mochapoint = new MochaPointAPI(apiKey);
const stats = await mochapoint.redemptions.getMonthlyStats();
const remaining = stats.subscription.remainingMonthly;
```

---

## API Versioning (Future)

### Current Version
- **Version**: v1 (default)
- **Base URL**: `/api/` (no version prefix)

### Future Versioning Strategy
```
/api/v1/redemptions/monthly-stats  # Explicit versioning
/api/v2/redemptions/monthly-stats  # Future version with enhanced features

# Headers approach (alternative)
X-API-Version: v1
```

---

## Security Considerations

### Enhanced API Security Checklist ⭐ UPDATED
- ✅ **HTTPS Only**: All production traffic encrypted
- ✅ **JWT Authentication**: Secure 30-day token-based auth
- ✅ **Role-based Access**: Granular permission system
- ✅ **Input Validation**: Joi schema validation
- ✅ **SQL Injection Prevention**: Sequelize ORM protection
- ✅ **Session Management**: Enhanced expiry detection and automatic logout
- ✅ **Error Code System**: Specific error codes for client handling
- 🚧 **Rate Limiting**: Future implementation
- 🚧 **API Key Management**: Future enhancement for third-party access
- 🚧 **Request Logging**: Future audit trail

### Enhanced Best Practices for Clients
1. **Store JWT securely**: Use secure storage (Keychain/SharedPreferences)
2. **Handle session expiry**: Automatic logout on TOKEN_EXPIRED
3. **Environment configuration**: Use proper API endpoints per environment
4. **Validate responses**: Check response structure and error codes
5. **Implement retry logic**: Handle network failures gracefully
6. **Use HTTPS**: Always use encrypted connections
7. **Monitor performance**: Log API call durations in development

### Subscription System Security
- **Monthly Limits**: Server-side enforcement prevents over-redemption
- **QR Code Security**: Daily expiry with nonce to prevent replay attacks
- **Redemption Validation**: Separate tracking of subscription vs joker redemptions
- **Access Control**: Subscription-based shop access validation

---

## Migration Notes

### Changes from Previous Version

#### API Changes ⭐ NEW
- Extended JWT expiry from default to 30 days
- Added error codes for enhanced client-side handling
- Enhanced monthly stats endpoint with remaining redemptions
- Added redemption status endpoint
- Enhanced user subscription endpoint

#### Database Changes ⭐ NEW
- Added `monthly_coffee_limit` column to `subscription_plans`
- Enhanced subscription system with active status tracking
- Improved indexing for subscription-related queries

#### Client Changes ⭐ NEW
- Environment configuration system implemented
- Enhanced session management with automatic logout
- Updated statistics display (Available → Remaining)
- Session expiry dialog and navigation

### Breaking Changes
None - all changes are backwards compatible additions.

---

## Advanced Features

### Subscription Management ⭐ NEW

#### Create Subscription Plan (Admin Only)
```http
POST /subscription-plans
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
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
}
```

#### Create User Subscription (Admin Only)
```http
POST /user-subscriptions
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "userId": 1,
  "planId": 1,
  "status": "active",
  "startDate": "2025-01-01",
  "endDate": "2025-01-31",
  "autoRenew": true
}
```

### Analytics Endpoints ⭐ ENHANCED

#### Get User Analytics
```http
GET /analytics/user/:userId
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "userId": 1,
    "totalRedemptions": 45,
    "subscriptionRedemptions": 35,
    "jokerRedemptions": 10,
    "favoriteShops": [
      {
        "shopId": 1,
        "shopName": "Central Coffee",
        "visitCount": 15,
        "averageRating": 4.8
      }
    ],
    "monthlyTrends": [
      {
        "month": "2025-01",
        "redemptions": 12,
        "subscriptionUsage": 10,
        "jokerUsage": 2
      }
    ]
  }
}
```

#### Get Shop Analytics
```http
GET /analytics/shop/:shopId
Authorization: Bearer <SHOP_OWNER_JWT_TOKEN>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "shopId": 1,
    "totalCustomers": 234,
    "subscriptionCustomers": 189,
    "avgRedemptionsPerCustomer": 3.2,
    "peakRedemptionTimes": [
      { "hour": 8, "count": 45, "percentage": 15.2 },
      { "hour": 14, "count": 38, "percentage": 12.8 }
    ],
    "monthlyGrowth": {
      "customerGrowth": 12.5,
      "redemptionGrowth": 8.3,
      "ratingImprovement": 0.2
    }
  }
}
```

### Bulk Operations ⭐ NEW

#### Bulk Add Jokers
```http
POST /users/bulk-add-jokers
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "users": [
    { "userId": 1, "count": 5 },
    { "userId": 2, "count": 3 },
    { "userId": 3, "count": 10 }
  ]
}
```

#### Bulk Update Shop Status
```http
POST /coffee-shops/bulk-update
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "shops": [
    { "shopId": 1, "isActive": true },
    { "shopId": 2, "isActive": false }
  ]
}
```

---

## Development & Testing APIs

### Test Data Endpoints (Development Only)

#### Create Test User
```http
POST /dev/create-test-user
Authorization: Bearer <ADMIN_JWT_TOKEN>
X-Environment: development
```

**Request Body:**
```json
{
  "email": "testuser@mochapoint.dev",
  "jokerCount": 10,
  "subscriptionPlan": "premium-monthly"
}
```

#### Reset User Stats
```http
POST /dev/reset-user-stats/:userId
Authorization: Bearer <ADMIN_JWT_TOKEN>
X-Environment: development
```

### Health & Status Endpoints

#### Detailed Health Check
```http
GET /health/detailed
```

**Response (200):**
```json
{
  "success": true,
  "timestamp": "2025-01-15T10:30:00.000Z",
  "services": {
    "database": {
      "status": "healthy",
      "responseTime": 12,
      "activeConnections": 5
    },
    "subscriptionSystem": {
      "status": "healthy",
      "activeSubscriptions": 234,
      "monthlyRedemptions": 1567
    },
    "qrSystem": {
      "status": "healthy",
      "activeTokens": 45,
      "dailyGenerations": 123
    }
  },
  "performance": {
    "averageResponseTime": 128,
    "requestsPerMinute": 45,
    "errorRate": 0.02
  }
}
```

#### System Status
```http
GET /status
```

**Response (200):**
```json
{
  "success": true,
  "system": {
    "version": "1.2.0",
    "environment": "production",
    "uptime": 172800,
    "lastDeployment": "2025-01-10T15:30:00.000Z"
  },
  "features": {
    "subscriptionSystem": true,
    "enhancedSessionManagement": true,
    "monthlyLimitEnforcement": true,
    "environmentConfiguration": true
  }
}
```

---

## Error Recovery & Resilience

### Circuit Breaker Pattern (Future)
```http
GET /redemptions/monthly-stats
X-Circuit-Breaker: enabled
```

**Response when circuit is open:**
```json
{
  "success": false,
  "error": "Service temporarily unavailable",
  "errorCode": "CIRCUIT_BREAKER_OPEN",
  "retryAfter": 30
}
```

### Graceful Degradation
When subscription service is unavailable, the API still provides basic functionality:

```json
{
  "success": true,
  "data": {
    "month": "January 2025",
    "subscription": {
      "hasActiveSubscription": false,
      "error": "Subscription service temporarily unavailable"
    },
    "redeemed": {
      "total": 8,
      "joker": 8
    },
    "available": {
      "jokers": 3
    }
  },
  "warnings": ["Subscription data unavailable"]
}
```

---

## Real-time Features (Future)

### WebSocket API (Planned)
```javascript
// Future WebSocket connection
const ws = new WebSocket('wss://api.mochapoint.coffee/ws');

// Real-time redemption notifications
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'REDEMPTION_COMPLETED') {
    // Update UI with new stats
    updateMonthlyStats(data.newStats);
  }
};

// Real-time shop capacity updates
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'SHOP_CAPACITY_UPDATE') {
    // Update shop availability
    updateShopCapacity(data.shopId, data.capacity);
  }
};
```

### Push Notifications (Future)
```http
POST /notifications/send
Authorization: Bearer <ADMIN_JWT_TOKEN>
```

**Request Body:**
```json
{
  "userId": 1,
  "type": "MONTHLY_LIMIT_RESET",
  "title": "New Month, Fresh Coffee!",
  "body": "Your monthly coffee limit has been reset. Time for your first cup!",
  "data": {
    "monthlyLimit": 25,
    "remainingMonthly": 25
  }
}
```

---

This enhanced API reference provides comprehensive documentation for all MochaPoint backend services, including the new environment configuration system, enhanced session management, subscription system integration, and future-ready features. For additional help or questions, please refer to the [GitHub repository](../../) or contact our support team.
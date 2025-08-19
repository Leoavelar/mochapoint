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

---

## Base Configuration

### URLs
```
Development: http://localhost:8000/api
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
  "details": { /* optional error details */ }
}
```

---

## Authentication

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
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
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
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
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
      "redemptionsAllowed": true
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

**Error Response (400):**
```json
{
  "success": false,
  "error": "No jokers available",
  "nextAvailableAt": "2025-01-16T00:00:00.000Z"
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
      "bundleName": "Premium Monthly"
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

### Get Redemption Status
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
      "canRedeem": true
    },
    "weeklyRedemptions": 3,
    "todayRedemptions": 1,
    "canRedeemSubscription": false,  // Already redeemed today
    "canRedeemJoker": true,
    "nextRedemptionAvailable": "2025-01-16T00:00:00.000Z"
  }
}
```

### Get Monthly Statistics ⭐ NEW
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
    "redeemed": {
      "total": 8,
      "subscription": 6,
      "joker": 2
    },
    "available": {
      "total": 12,
      "subscription": 7,
      "jokers": 5
    },
    "limits": {
      "monthlySubscriptionLimit": 13,
      "hasActiveSubscription": true,
      "subscriptionName": "Premium Monthly"
    },
    "redemptionHistory": [
      {
        "id": 156,
        "type": "subscription",
        "timestamp": "2025-01-15T10:30:00.000Z",
        "coffeeType": "Cappuccino"
      },
      {
        "id": 155,
        "type": "joker",
        "timestamp": "2025-01-14T14:15:00.000Z",
        "coffeeType": "Espresso"
      }
    ]
  }
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
| 401 | Unauthorized (no token or invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 500 | Internal Server Error |

### Common Error Responses

#### Authentication Errors
```json
// 401 - No token provided
{
  "success": false,
  "error": "Access token required"
}

// 403 - Invalid token
{
  "success": false,
  "error": "Invalid token"
}

// 403 - Insufficient permissions
{
  "success": false,
  "error": "Insufficient permissions"
}
```

#### Validation Errors
```json
// 400 - Invalid input
{
  "success": false,
  "error": "Validation failed",
  "details": {
    "email": "Email is required",
    "password": "Password must be at least 6 characters"
  }
}
```

#### Business Logic Errors
```json
// 400 - Redemption not allowed
{
  "success": false,
  "error": "You have already redeemed your daily coffee",
  "nextAvailableAt": "2025-01-16T00:00:00.000Z"
}

// 400 - QR code expired
{
  "success": false,
  "error": "Invalid or expired QR code"
}
```

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

# 2. Login and get token
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# 3. Use token for authenticated requests
export TOKEN="your-jwt-token-here"
```

### QR Redemption Flow
```bash
# 1. Generate QR token (User)
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "subscription"}'

# 2. Validate QR token (Coffee Shop)
curl -X POST http://localhost:8000/api/redemptions/validate-and-redeem \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "qrToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "coffeeType": "Cappuccino"
  }'

# 3. Check monthly statistics
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN"
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

# 3. Get shop statistics
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
# Test monthly stats response structure
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer $USER_TOKEN" | jq '.data.redeemed.total'

# Test QR generation with invalid type
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"redemptionType": "invalid"}'  # Should return 400 error

# Test unauthorized access
curl -X GET http://localhost:8000/api/redemptions/monthly-stats
# Should return 401 error
```

---

## Rate Limiting & Performance

### Current Limits
- **General API**: No rate limiting implemented (future enhancement)
- **QR Generation**: 1 token per day per redemption type per user
- **Authentication**: No login attempt limiting (future enhancement)

### Performance Notes
- **Response Times**: Target < 200ms for most endpoints
- **Database Queries**: Optimized with strategic indexing
- **Pagination**: Available on history endpoints (limit/offset)
- **Caching**: Future enhancement for static data

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
- `payment.succeeded`
- `payment.failed`

---

## SDKs and Client Libraries

### Flutter Client (Included)
```dart
// Example usage
final stats = await MonthlyStatsService.getMonthlyStats();
final qrToken = await RedemptionService.generateQR('subscription');
```

### JavaScript/Node.js Client (Future)
```javascript
// Future SDK
const mochapoint = new MochaPointAPI(apiKey);
const stats = await mochapoint.redemptions.getMonthlyStats();
```

---

## API Versioning (Future)

### Current Version
- **Version**: v1 (default)
- **Base URL**: `/api/` (no version prefix)

### Future Versioning Strategy
```
/api/v1/redemptions/monthly-stats  # Explicit versioning
/api/v2/redemptions/monthly-stats  # Future version

# Headers approach (alternative)
X-API-Version: v1
```

---

## Security Considerations

### API Security Checklist
- ✅ **HTTPS Only**: All production traffic encrypted
- ✅ **JWT Authentication**: Secure token-based auth
- ✅ **Role-based Access**: Granular permission system
- ✅ **Input Validation**: Joi schema validation
- ✅ **SQL Injection Prevention**: Sequelize ORM protection
- 🚧 **Rate Limiting**: Future implementation
- 🚧 **API Key Management**: Future enhancement
- 🚧 **Request Logging**: Future audit trail

### Best Practices for Clients
1. **Store JWT securely**: Use secure storage (Keychain/SharedPreferences)
2. **Handle token expiration**: Implement automatic refresh
3. **Validate responses**: Check response structure and status
4. **Implement retry logic**: Handle network failures gracefully
5. **Use HTTPS**: Always use encrypted connections

---

This API reference provides comprehensive documentation for all MochaPoint backend services. For additional help or questions, please refer to the [GitHub repository](../../) or contact our support team.
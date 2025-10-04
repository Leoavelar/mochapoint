# MochaPoint ☕

> Your daily dose of happiness - A coffee subscription platform connecting coffee lovers with partner shops in Graz, Austria

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17+-blue.svg)](https://postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🚀 Quick Start

```bash
# Backend
cd backend && npm install && npm run dev

# Frontend  
cd frontend && flutter pub get && flutter run

# Health Check
curl http://localhost:8000/health
```

**New to MochaPoint?** → [Complete Setup Guide](docs/SETUP.md)

## 📱 What is MochaPoint?

MochaPoint is a mobile-first coffee subscription platform that connects coffee lovers with local coffee shops in Graz, Austria. Users can redeem coffee through secure QR codes, discover nearby shops, and track their monthly coffee consumption.

### Key Features
- **🔐 Multi-Authentication**: Email, Google, Apple Sign-In
- **📱 QR Redemption**: Secure coffee redemptions via QR codes
- **📍 Shop Discovery**: Map-based coffee shop finding
- **📊 Real-time Stats**: Monthly redemption tracking with remaining coffee count
- **⭐ Rating System**: Community-driven shop ratings
- **👥 Role-based Access**: Different interfaces for users and coffee shop owners
- **🎫 Subscription Integration**: Visual highlighting of subscribed coffee shops
- **📈 Subscription Dashboard**: Shows subscription plan details and accessible shops
- **🌍 Environment Management**: Development/production configuration system
- **🔄 Session Management**: Enhanced token handling with 30-day expiry

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [🏗️ Architecture](docs/ARCHITECTURE.md) | System design, database schema, tech stack |
| [🔌 API Reference](docs/API.md) | Complete API documentation with examples |
| [⚙️ Setup Guide](docs/SETUP.md) | Installation, configuration, deployment |
| [🧪 Testing Guide](docs/TESTING.md) | Testing procedures and validation |
| [🔒 Security](docs/SECURITY.md) | Authentication, QR security, best practices |
| [📱 Mobile App](docs/MOBILE.md) | Flutter app structure and features |
| [📋 Changelog](docs/CHANGELOG.md) | Version history and updates |

## 🏗️ System Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │◄──►│   Express API   │◄──►│  PostgreSQL DB  │
│                 │    │                 │    │                 │
│ • QR Generation │    │ • JWT Auth      │    │ • User Data     │
│ • Camera Scanner│    │ • Role Validation│    │ • Redemptions   │
│ • Map Discovery │    │ • Business Logic│    │ • Coffee Shops  │
│ • Environment   │    │ • Session Mgmt  │    │ • Subscriptions │
│   Config        │    │ • 30-day Tokens │    │ • Plans & Access│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Tech Stack**: Node.js + Express + TypeScript + PostgreSQL + Flutter
**Environment Management**: Development/Production configuration system

## 📊 Current Status

### ✅ Production Ready (100% Complete)
- **Authentication System**: Email/password, Google OAuth, Apple Sign-In
- **QR Redemption System**: Secure token generation and validation
- **Coffee Shop Management**: CRUD operations with real-time analytics
- **Mobile App**: Cross-platform iOS/Android with role-based UI
- **Monthly Statistics**: Real-time redemption tracking with remaining coffee count
- **Rating System**: Dual-source ratings (app + Google) with aggregation
- **🆕 Subscription Integration**: Complete subscription system with shop highlighting
- **🆕 User Subscription API**: Backend endpoint for subscription details
- **🆕 Enhanced UI**: Visual subscription indicators and accessible shop highlighting
- **🆕 Environment Configuration**: Development/production config management
- **🆕 Session Management**: Enhanced JWT tokens with 30-day expiry and session expiry handling
- **Joker System**: Subscription plans define monthly joker allocations with 30-day reset cycles

### 🚧 In Development (Database Ready)
- **Payment Processing**: Stripe integration for subscriptions
- **Advanced Analytics**: Business intelligence and user insights
- **Referral System**: User referral codes and reward management

## 🔄 How It Works

### For Coffee Lovers (Users)
1. **Sign Up** → Create account via email, Google, or Apple
2. **Discover** → Find nearby coffee shops on the map
3. **Generate QR** → Create secure QR code for redemption
4. **Redeem** → Show QR to coffee shop for free coffee
5. **Track** → View monthly statistics showing remaining monthly redemptions

### For Coffee Shop Owners
1. **Register** → Create coffee shop business account
2. **Manage** → Update shop info, hours, and redemption settings
3. **Scan** → Use built-in scanner to validate customer QR codes
4. **Analytics** → View real-time redemption stats and customer data
5. **Rate** → Receive and manage customer ratings
6. 

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- PostgreSQL 17+
- Flutter 3.0+
- Android Studio / Xcode (for mobile development)

### Quick Setup

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd mocha-point
   ```

2. **Backend Setup**
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Edit .env with your configuration
   npm run dev
   ```

3. **Frontend Setup**
   ```bash
   cd frontend
   flutter pub get
   
   # Development environment
   flutter run --dart-define=ENVIRONMENT=development
   
   # Production environment
   flutter run --dart-define=ENVIRONMENT=production
   ```

4. **Initial Data**
   ```bash
   # Create admin user and test coffee shop
   # See docs/SETUP.md for detailed instructions
   ```

**Need detailed setup instructions?** → [Complete Setup Guide](docs/SETUP.md)

## 🧪 Quick Test

```bash
# API Health Check
curl http://localhost:8000/health

# Test Authentication
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}'

# Test Monthly Stats (with remaining redemptions)
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Want comprehensive testing?** → [Testing Guide](docs/TESTING.md)

## 📊 API Examples

### Generate QR Code
```bash
curl -X POST http://localhost:8000/api/redemptions/generate-qr \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"redemptionType": "subscription"}'
```

### Get Monthly Statistics (Updated)
```bash
curl -X GET http://localhost:8000/api/redemptions/monthly-stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response includes remaining monthly redemptions:**
```json
{
  "success": true,
  "data": {
    "month": "January 2025",
    "subscription": {
      "hasActiveSubscription": true,
      "planName": "Premium Monthly Plan",
      "monthlyLimit": 25,
      "remainingMonthly": 18
    },
    "redeemed": {
      "total": 7,
      "subscription": 7,
      "joker": 0
    }
  }
}
```

### Get User Subscription Status
```bash
curl -X GET http://localhost:8000/api/users/subscription \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Need complete API docs?** → [API Reference](docs/API.md)

## 🔧 Environment Configuration

MochaPoint now features a robust environment management system:

### Development Environment
```bash
# Run in development mode
flutter run --dart-define=ENVIRONMENT=development

# Uses: http://localhost:8000/api (or your local IP)
# Features: Debug logging, shorter timeouts, development features
```

### Production Environment
```bash
# Run in production mode
flutter run --dart-define=ENVIRONMENT=production

# Uses: https://mochapoint.coffee/api
# Features: Optimized performance, error-only logging
```

### Build for Distribution
```bash
# Production APK
flutter build apk --release --dart-define=ENVIRONMENT=production

# Production App Bundle
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Update documentation if needed
5. Submit a pull request

### Development Workflow
- **Documentation**: Keep docs in sync with code changes
- **Testing**: Add tests for new features
- **Code Style**: Follow existing patterns and conventions
- **Environment**: Use development environment for testing

## 📈 Roadmap

### Q1 2025: Payment Integration
- [ ] Stripe payment processing for subscriptions
- [ ] Payment method management
- [ ] Billing history and invoices

### Q2 2025: Business Intelligence
- [ ] Advanced analytics dashboard
- [ ] User behavior insights
- [ ] Coffee shop performance metrics
- [ ] Revenue tracking and reporting

### Q3 2025: Social Features
- [ ] Referral system with rewards
- [ ] Social sharing capabilities
- [ ] Community features and reviews
- [ ] Loyalty program enhancements

## 🔗 Links

- **API Documentation**: [docs/API.md](docs/API.md)
- **Architecture Guide**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Setup Instructions**: [docs/SETUP.md](docs/SETUP.md)
- **Testing Guide**: [docs/TESTING.md](docs/TESTING.md)
- **Live Demo**: *Coming Soon*

## 📞 Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Email**: support@mochapoint.coffee
- **Documentation**: [docs/](docs/)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**MochaPoint** - Built with ❤️ for the coffee community in Graz, Austria ☕️

*Ready to get started? Check out the [Setup Guide](docs/SETUP.md)!*
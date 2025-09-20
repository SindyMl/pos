# Point of Sale (POS) System

A comprehensive Flutter-based Point of Sale application designed for retail businesses. This modern POS system provides real-time sales tracking, inventory management, and payment processing capabilities with cloud-based data synchronization.

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

## 📋 Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

### 🏪 Core POS Functionality
- **Real-time Sales Processing**: Process sales transactions with automatic inventory updates
- **Multi-payment Support**: Accept both cash and card payments (Stripe integration ready)
- **Barcode Scanning**: Built-in barcode scanner for quick product identification
- **Receipt Generation**: Digital receipt generation for completed transactions

### 📊 Dashboard & Analytics
- **Real-time Dashboard**: Live sales metrics and key performance indicators
- **Daily Sales Tracking**: Monitor today's sales, profits, and transaction volumes
- **Low Stock Alerts**: Automatic notifications when inventory runs low
- **Pending Orders Management**: Track and manage incomplete transactions

### 📦 Inventory Management
- **Product Catalog**: Comprehensive product database with SKU and barcode support
- **Stock Level Monitoring**: Real-time inventory tracking with configurable low-stock thresholds
- **Product Search**: Autocomplete search functionality for quick product lookup
- **Inventory Updates**: Automatic stock adjustments upon sale completion

### 🔧 Business Management
- **Tax Configuration**: Configurable tax rates for different regions
- **Discount Management**: Flexible discount system for promotional pricing
- **User Authentication**: Secure user access with Firebase Authentication
- **Cloud Synchronization**: Real-time data sync across multiple devices

## 🏗️ Architecture

This application follows a clean architecture pattern with clear separation of concerns:

- **Presentation Layer**: Flutter widgets and screens
- **Business Logic**: State management with Provider pattern
- **Data Layer**: Firebase Firestore for cloud storage and Hive for local caching
- **Services**: Firebase services for authentication and cloud functions

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.7.2**: Cross-platform mobile development framework
- **Dart**: Programming language for Flutter development
- **Material Design 3**: Modern UI/UX design system

### State Management
- **Provider 6.1.2**: Lightweight state management solution

### Backend & Database
- **Firebase Core 3.13.0**: Backend-as-a-Service platform
- **Cloud Firestore 5.4.3**: NoSQL cloud database
- **Firebase Auth 5.3.1**: User authentication and authorization

### Payment Processing
- **Stripe SDK 5.0.0**: Payment processing integration (ready for implementation)

### Local Storage
- **Hive 2.2.3**: Lightweight NoSQL local database
- **Hive Flutter 1.1.0**: Flutter integration for Hive

### Additional Features
- **Flutter Barcode Scanner 2.0.0**: QR/Barcode scanning capabilities
- **FL Chart 0.70.2**: Beautiful charts and analytics visualization

### Development Tools
- **Build Runner 2.4.12**: Code generation tool
- **Hive Generator 2.0.1**: Automatic type adapter generation
- **Flutter Lints 5.0.0**: Code quality and style enforcement

## 📋 Prerequisites

Before running this application, ensure you have the following installed:

- **Flutter SDK**: Version 3.7.2 or higher
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account**: For backend services
- **Android Device/Emulator** or **iOS Device/Simulator**

### System Requirements
- **Minimum SDK**: Android API 21 (Android 5.0) / iOS 11.0
- **Target SDK**: Android API 34 / iOS 17.0
- **RAM**: Minimum 4GB (8GB recommended)
- **Storage**: 2GB free space

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/SindyMl/pos.git
cd pos/pos
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Required Files
```bash
flutter packages pub run build_runner build
```

### 4. Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - **Authentication**: Email/Password provider
   - **Firestore Database**: In production mode
   - **Cloud Storage**: For file uploads (optional)

### 5. Configure Firebase
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Configure Firebase for Flutter
flutter pub global activate flutterfire_cli
flutterfire configure
```

### 6. Run the Application
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

## ⚙️ Configuration

### Firebase Collections Structure

The application uses the following Firestore collections:

#### **Sales Collection** (`sales`)
```json
{
  "total": 150.75,
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "completed",
  "items": [
    {
      "sku": "PROD001",
      "name": "Product Name",
      "price": 25.99,
      "quantity": 2
    }
  ],
  "paymentType": "cash"
}
```

#### **Inventory Collection** (`inventory`)
```json
{
  "sku": "PROD001",
  "name": "Product Name",
  "barcode": "1234567890123",
  "price": 25.99,
  "quantity": 100,
  "category": "Electronics"
}
```

#### **Settings Collection** (`settings`)
```json
// Document ID: "tax"
{
  "rate": 15.5
}

// Document ID: "lowStock"
{
  "threshold": 10
}

// Document ID: "discount"
{
  "value": 5.0
}
```

### Environment Variables

Create a `.env` file in the project root (if needed for API keys):
```env
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
STRIPE_SECRET_KEY=sk_test_your_key_here
```

## 📱 Usage

### Getting Started
1. **Launch the App**: Open the application on your device
2. **Dashboard Overview**: View real-time business metrics
3. **Process Sales**: Navigate to the sales screen to begin transactions

### Making a Sale
1. **Add Products**: 
   - Scan barcodes using the built-in scanner
   - Or manually enter product SKU/barcode
   - Use autocomplete for quick product search

2. **Review Cart**: 
   - Verify items and quantities
   - Remove items if necessary

3. **Process Payment**:
   - Select payment method (Cash/Card)
   - For cash: Enter amount tendered and view change
   - For card: Use integrated payment processing

4. **Complete Transaction**: 
   - Finalize the sale
   - Generate digital receipt
   - Automatic inventory updates

### Dashboard Features
- **Today's Sales**: View current day revenue
- **Low Stock Alerts**: Monitor inventory levels
- **Profit Tracking**: Real-time profit calculations
- **Pending Orders**: Manage incomplete transactions

## 📁 Project Structure

```
pos/
├── android/                 # Android platform configuration
├── ios/                     # iOS platform configuration
├── lib/
│   ├── dashboard.dart       # Main dashboard screen
│   ├── firebase_options.dart # Firebase configuration
│   ├── main.dart           # Application entry point
│   ├── sales.dart          # Sales transaction screen
│   └── utils/
│       └── constants.dart   # App-wide constants and colors
├── test/                   # Unit and widget tests
├── web/                    # Web platform assets
├── windows/                # Windows platform configuration
├── analysis_options.yaml  # Dart analyzer configuration
├── firebase.json          # Firebase project configuration
├── pubspec.yaml           # Dependencies and project metadata
└── README.md              # This file
```

### Key Files Description

- **`main.dart`**: Application entry point with routing and theme configuration
- **`dashboard.dart`**: Main dashboard with real-time business metrics
- **`sales.dart`**: Complete sales transaction processing interface
- **`constants.dart`**: Centralized color scheme and app constants
- **`firebase_options.dart`**: Auto-generated Firebase configuration

## 🤝 Contributing

We welcome contributions to improve this POS system! Please follow these guidelines:

### Development Workflow
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Standards
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

### Reporting Issues
Please use the [GitHub Issues](https://github.com/SindyMl/pos/issues) page to report bugs or request features.

## 📄 License

This project is proprietary and private. All rights reserved.

## 🔮 Future Enhancements

- **Multi-store Support**: Manage multiple store locations
- **Advanced Analytics**: Detailed sales reports and trends
- **Employee Management**: User roles and permissions
- **Loyalty Program**: Customer rewards and points system
- **API Integration**: Connect with accounting software
- **Offline Mode**: Enhanced offline capabilities with sync

## 📞 Support

For support and questions, please contact:
- **Email**: [Your Email]
- **GitHub**: [@SindyMl](https://github.com/SindyMl)

---

**Built with ❤️ using Flutter and Firebase**

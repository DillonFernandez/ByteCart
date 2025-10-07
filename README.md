<div align="center">
  <img src="assets/images/logo.webp" alt="ByteCart Logo" width="200" height="200">
</div>

# ByteCart 🛒

An e-commerce electronics store application built with Flutter for mobile and Laravel for web. This project was developed as a university assignment showcasing modern mobile app development practices.

## 📱 About

ByteCart is a comprehensive e-commerce solution for electronics shopping, featuring both mobile applications (iOS/Android) and a web platform. The app provides a seamless shopping experience with intelligent features like auto-location detection, adaptive theming, and offline connectivity handling.

## ✨ Features

### 🎨 Smart UI/UX

- **Adaptive Theming**: Automatic light/dark mode switching based on ambient brightness
- **Manual Theme Control**: Toggle between light and dark modes manually
- **Auto Brightness**: Intelligent screen brightness adjustment

### 📍 Location Services

- **Auto Location Detection**: Automatically fills shipping and billing address fields
- **Smart Address Completion**: Reduces manual input for faster checkout

### 🌐 Connectivity Management

- **Real-time Connectivity Status**: Shows online/offline status
- **Offline Mode Support**: Browse previously loaded content without internet
- **Smart Sync**: Automatically syncs data when connection is restored

### 🛍️ E-commerce Core

- Electronics product catalog
- Shopping cart functionality
- User authentication and profiles
- Order management
- Secure checkout process

## 🛠️ Tech Stack

### Mobile App (Flutter)

- **Framework**: Flutter
- **Language**: Dart
- **Platforms**: iOS, Android

### Web Platform

- **Backend**: Laravel (PHP)
- **Database**: MySQL (XAMPP), MongoDB
- **Frontend**: Laravel Blade Templates

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Xcode (for iOS development)
- XAMPP (for local MySQL server)
- MongoDB

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd ByteCart
   ```

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up the database**

   - Start XAMPP and ensure MySQL is running
   - Configure MongoDB connection
   - Run database migrations (Laravel)

4. **Configure environment**

   - Update API endpoints in the Flutter app
   - Set up Laravel environment variables

5. **Run the application**

   ```bash
   # For mobile app
   flutter run

   # For web platform
   # Navigate to Laravel directory and run
   php artisan serve
   ```

## 📂 Project Structure

```
ByteCart/
├── lib/                    # Flutter app source code
├── android/               # Android-specific files
├── ios/                   # iOS-specific files
├── web-platform/          # Laravel web application
├── assets/                # Images, fonts, and other assets
└── README.md
```

## 🎓 Academic Context

This project is developed as a university assignment to demonstrate:

- Cross-platform mobile development with Flutter
- Full-stack web development with Laravel
- Database integration (MySQL & MongoDB)
- Modern UI/UX design principles
- Location services and device sensors integration
- Offline-first application architecture

## 📧 Contact

For questions or support regarding this project:

- **Email**: dillonfernandez@gmail.com

## 📄 License

This project is developed for educational purposes as part of a university assignment.

---

**Note**: This is an academic project and is not intended for commercial use.

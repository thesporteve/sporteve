# SportEve Documentation Hub

## 📚 Documentation Overview

This repository contains comprehensive documentation for the SportEve sports news application ecosystem.

### 📋 Available Documentation

1. **[README.md](README.md)** - Main project documentation
   - Mobile app features and architecture
   - AI-powered content system
   - Technical specifications
   - Getting started guide

2. **[ADMIN_README.md](ADMIN_README.md)** - Admin panel documentation
   - Admin panel features and functionality
   - Analytics dashboard guide
   - Content management workflows
   - Deployment instructions

## 🏗️ Project Structure

### 📱 Mobile Application
- **Flutter-based** cross-platform mobile app
- **AI-powered content** including daily tips and facts
- **Real-time notifications** for new content
- **Offline support** with smart caching

### 🌐 Admin Panel
- **Web-based** admin interface at https://sporteve-7afbf.web.app
- **AI content generation** and management
- **Real-time analytics** dashboard
- **Content review** and approval workflow

### ☁️ Backend Infrastructure
- **Firebase ecosystem** (Firestore, Functions, Hosting, Auth)
- **OpenAI integration** for content generation
- **Real-time analytics** tracking
- **Push notification** system

## 🚀 Quick Links

- **Live Admin Panel**: https://sporteve-7afbf.web.app
- **Firebase Console**: https://console.firebase.google.com/project/sporteve-7afbf
- **Project Repository**: Current directory

## 📊 Key Features

### For Users (Mobile App)
- Latest sports news and updates
- AI-generated daily tips and facts
- Smart search across all content
- Bookmark and share functionality
- Offline reading capabilities

### For Admins (Web Panel)
- Content generation and management
- Real-time user analytics
- Content performance insights
- User engagement tracking
- Role-based access control

## 🔧 Development

### Mobile App Development
```bash
# Run mobile app
flutter run

# Build for production
flutter build apk
flutter build ios
```

### Admin Panel Development
```bash
# Run admin panel locally
flutter run -d web-server --target lib/admin_main.dart --web-port 8080

# Build and deploy admin panel
flutter build web --target lib/admin_main.dart
firebase deploy --only hosting
```

## 📞 Support

For technical support or questions about the documentation:
- Check the specific README files for detailed information
- Review Firebase console logs for backend issues
- Contact the development team for access-related questions

---

**SportEve** - Comprehensive sports content management ecosystem 🏆

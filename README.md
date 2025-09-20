# SportEve - Sports News App

A modern, feature-rich Flutter application for sports news and updates. SportEve provides users with the latest sports news, live match updates, and comprehensive coverage across multiple sports categories.

## Features

### 🏆 Core Features
- **Latest Sports News**: Get breaking news and updates from various sports categories
- **Live Match Updates**: Real-time scores and match information
- **AI-Powered Tips & Facts**: Daily parenting tips and sports facts powered by AI
- **Category Filtering**: Browse news by sport with elegant badges and proper formatting
- **Advanced Search**: Enhanced search with smart suggestions and real-time results
- **Breaking News Banner**: Prominent display of urgent sports updates
- **Featured Articles**: Curated top stories and important news
- **Push Notifications**: Smart notifications with direct content navigation
- **Content Detail Views**: Full-screen detailed views for all content types
- **Anonymous Analytics**: Track views, likes, and shares without user accounts

### 🎨 User Interface
- **Modern Material Design**: Clean, intuitive interface following Material Design 3
- **Enhanced News Cards**: Beautiful sport category badges with proper formatting
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Responsive Design**: Optimized for various screen sizes
- **Smooth Animations**: Engaging transitions and micro-interactions
- **Custom Components**: Beautiful cards, chips, and interactive elements
- **Professional Typography**: Improved text formatting and category displays

### 📱 User Experience
- **Splash Screen**: Animated app introduction
- **Pull-to-Refresh**: Easy content updates
- **Daily Tip Banner**: Dismissible daily tips with direct navigation to content
- **Tips & Facts Hub**: Dedicated tabbed section for AI-generated content
- **Content Detail Screen**: Full-screen immersive content viewing experience
- **Persistent Bookmarking**: Save articles and tips for later (accessible via Settings)
- **Anonymous Engagement**: Like and share content with persistent state tracking
- **Smart Notifications**: Direct navigation to content detail from notifications
- **Enhanced Search**: Smart suggestions, recent searches, and category filters
- **Offline Access**: Cached content for offline reading
- **Native Sharing**: System-integrated sharing with formatted content

## Screenshots

The app includes:
- Animated splash screen with app branding
- Home screen with breaking news banner and live matches
- Category-based news filtering
- Detailed article view with full content
- Modern card-based design throughout

## Technical Architecture

### 🏗️ Project Structure
```
lib/
├── main.dart                 # Mobile app entry point
├── admin_main.dart           # Admin panel entry point
├── models/                   # Data models
│   ├── news_article.dart     # News article model
│   ├── content_feed.dart     # AI content models
│   └── user.dart             # User models
├── providers/                # State management
│   ├── news_provider.dart    # News data provider
│   ├── content_provider.dart # AI content provider
│   └── settings_provider.dart # App settings
├── screens/                  # Mobile app screens
│   ├── splash_screen.dart    # Animated splash screen
│   ├── home_screen.dart      # Main news feed with daily tips
│   ├── news_detail_screen.dart # Full news article view
│   ├── content_detail_screen.dart # Full AI content detail view
│   ├── tips_facts_screen.dart # AI content hub with tabs
│   ├── search_screen.dart    # Enhanced content search
│   ├── bookmarks_screen.dart # Saved content
│   └── settings_screen.dart  # App settings with bookmarks
├── admin/                    # Admin panel (Web)
│   ├── screens/              # Admin interface screens
│   ├── services/             # Admin backend services
│   ├── providers/            # Admin state management
│   └── widgets/              # Admin UI components
├── services/                 # Backend services
│   ├── firebase_service.dart # Firebase initialization
│   ├── content_feed_service.dart # AI content service
│   ├── content_analytics_service.dart # Analytics tracking
│   ├── like_service.dart     # Anonymous like persistence
│   ├── content_like_service.dart # AI content like tracking
│   ├── notification_service.dart # Push notifications
│   └── offline_cache_service.dart # Offline functionality
├── theme/                    # App theming
│   └── app_theme.dart        # Light and dark themes
└── widgets/                  # Reusable components
    ├── news_card.dart        # Enhanced news cards with analytics
    ├── news_page_card.dart   # Full-page news display
    ├── daily_tip_banner.dart # Daily tip banner with navigation
    ├── content_card.dart     # AI content cards with engagement
    └── content_detail_dialog.dart # Content detail popup (deprecated)
```

### 🛠️ Technologies Used
- **Flutter**: Cross-platform mobile development framework
- **Firebase**: Backend-as-a-Service platform
- **Cloud Firestore**: NoSQL database for real-time data
- **Cloud Functions**: Serverless backend for AI content generation
- **Firebase Hosting**: Web hosting for admin panel
- **Provider**: State management solution
- **Go Router**: Declarative routing
- **OpenAI GPT**: AI content generation
- **Push Notifications**: Real-time user engagement
- **Google Fonts**: Typography
- **Cached Network Image**: Image loading and caching

### 📦 Dependencies
- `provider: ^6.1.1` - State management
- `go_router: ^12.1.3` - Navigation
- `google_fonts: ^6.1.0` - Typography
- `cached_network_image: ^3.3.0` - Image handling
- `http: ^1.1.0` - HTTP requests
- `font_awesome_flutter: ^10.6.0` - Icons
- `intl: ^0.18.1` - Date formatting

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd SportEve
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

1. **API Configuration**
   - Open `lib/services/news_service.dart`
   - Replace `YOUR_API_KEY_HERE` with your NewsAPI key
   - Set `_useMockData = false` to use real API data

2. **Customization**
   - Modify colors in `lib/theme/app_theme.dart`
   - Update app name in `pubspec.yaml`
   - Add your own images to `assets/images/`

## Features in Detail

### News Categories
- **Football**: NFL, College Football
- **Basketball**: NBA, College Basketball
- **Soccer**: Premier League, Champions League, MLS
- **Tennis**: Grand Slams, ATP, WTA
- **Olympics**: Summer and Winter Games
- **General**: Other sports and general news

### Live Features
- Real-time match scores
- Live match status indicators
- Breaking news notifications
- Upcoming match schedules

### User Interactions
- Tap to read full articles and tips with immersive detail views
- Swipe to refresh content across all screens
- Daily tip banner with dismiss functionality and direct content navigation
- Enhanced category filtering with beautiful badges (Football, Table Tennis, etc.)
- Advanced search with smart suggestions, recent searches, and result filters
- Persistent bookmarking system (accessible via Settings menu)
- Anonymous like and share tracking with visual feedback
- Native content sharing with formatted text and app branding
- Push notification taps navigate directly to content detail screens
- Interactive engagement tracking (views, likes, shares) without user accounts

## AI-Powered Content System

### 🤖 AI Content Features
- **Daily Tips**: Sports-related parenting advice with benefits and age group recommendations
- **Did You Know Facts**: Interesting sports facts with detailed explanations and categories
- **Content Detail Views**: Full-screen immersive experience showing all content details
- **Smart Notifications**: Push alerts with direct navigation to specific content
- **Anonymous Analytics**: Track content performance without requiring user accounts
- **Engagement Tracking**: Like, share, and view tracking with persistent state
- **Quality Control**: All AI content reviewed and editable by admins before publication

### 📱 Mobile App Navigation
- **News**: Latest sports news with enhanced category badges and engagement tracking
- **Search**: Advanced search with smart suggestions, recent searches, and category filters
- **Tips & Facts**: Tabbed hub for AI-generated content (Parenting Tips & Did You Know)
- **Settings**: App preferences with integrated bookmarks section for easy access

### 🎯 Content Types
1. **Parenting Tips**: Advice on involving children in sports
2. **Did You Know**: Fascinating sports facts and history
3. **Trivia Questions**: Interactive sports knowledge (coming soon)

## Admin Panel

### 🌐 Web-Based Administration
**Admin URL**: https://sporteve-7afbf.web.app

### 👥 Admin Features
- **Content Generation**: AI-powered content creation tools
- **Review System**: Approve/edit AI-generated content before publication
- **Analytics Dashboard**: Track user engagement and content performance
- **User Management**: Admin role and permission management
- **News Management**: Traditional news article creation and editing

### 📊 Analytics & Insights
- **Real-time Analytics**: Live user interaction tracking
- **Performance Metrics**: View counts, likes, shares, and bookmarks
- **Content Strategy**: Data-driven insights for content optimization
- **User Engagement**: Understand what content resonates with users

### 🔐 Admin Access
- **Role-based Permissions**: Different access levels for admin users
- **Secure Authentication**: Firebase-powered login system
- **Responsive Design**: Works on desktop, tablet, and mobile

## Future Enhancements

### Planned Features
- **User Accounts**: Personalized news feeds and preferences
- **Comment System**: User discussions on articles and AI content
- **Video Content**: Embedded sports highlights and tutorials
- **Team Following**: Follow favorite teams with personalized updates
- **Match Predictions**: User predictions and community polls
- **Advanced Trivia**: Interactive trivia games with leaderboards
- **Content Scheduling**: Timed publication of daily tips

### Technical Improvements
- **API Integration**: Real news API implementation
- **Enhanced Caching**: Advanced offline data management
- **Performance Optimization**: Image optimization and lazy loading
- **Accessibility**: Screen reader support and improved navigation
- **Internationalization**: Multi-language support for global audience
- **Advanced Analytics**: Enhanced user behavior insights and content optimization
- **Real-time Features**: Live chat and real-time content updates

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- NewsAPI for providing news data
- Flutter team for the amazing framework
- Material Design for design guidelines
- Unsplash for placeholder images

## Support

For support, email support@sporteve.com or create an issue in the repository.

---

**SportEve Mobile App** - Your Ultimate Sports News and Tips Hub 🏆

**Last Updated**: December 2024  
**Version**: 2.1.0 - Enhanced Content Experience  
**Features**: Content detail screens, smart notifications, anonymous analytics, enhanced search  
**Platform**: iOS & Android via Flutter

---

**SportEve** - Your Ultimate Sports News Hub 🏆

# Firebase Setup Guide for SportEve

This guide will help you set up Firebase for your SportEve app with data storage, Cloud Functions, and push notifications.

## 🚀 Quick Start

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `sporteve-app`
4. Enable Google Analytics (optional)
5. Create project

### 2. Add Android App

1. In Firebase Console, click "Add app" → Android
2. Package name: `com.example.sporteve`
3. Download `google-services.json`
4. Place it in `android/app/` directory

### 3. Add iOS App (if needed)

1. Click "Add app" → iOS
2. Bundle ID: `com.example.sporteve`
3. Download `GoogleService-Info.plist`
4. Add to iOS project in Xcode

## 🔧 Configuration

### Update Firebase Options

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase config:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-messaging-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);
```

## 📊 Firestore Database Setup

### Collections Structure

Create these collections in Firestore:

#### 1. News Collection (`news`)
```json
{
  "title": "Manchester City Dominates Derby Match",
  "summary": "City secures a convincing 3-1 victory...",
  "content": "Full article content...",
  "author": "John Smith",
  "publishedAt": "2024-01-15T10:30:00Z",
  "imageUrl": "https://example.com/image.jpg",
  "category": "football",
  "source": "ESPN",
  "tags": ["manchester", "derby", "football"],
  "readTime": 5,
  "isBreaking": false,
  "views": 1250,
  "relatedArticles": ["article1", "article2"],
  "searchKeywords": ["manchester", "city", "derby", "football"]
}
```

#### 2. Matches Collection (`matches`)
```json
{
  "homeTeam": "Manchester City",
  "awayTeam": "Manchester United",
  "homeScore": 3,
  "awayScore": 1,
  "status": "finished",
  "date": "2024-01-15T15:00:00Z",
  "league": "Premier League",
  "venue": "Etihad Stadium",
  "homeTeamLogo": "https://example.com/city-logo.png",
  "awayTeamLogo": "https://example.com/united-logo.png"
}
```

#### 3. User Preferences (`userPreferences`)
```json
{
  "favoriteSports": ["football", "basketball"],
  "favoriteTeams": ["Manchester City", "Lakers"],
  "notificationSettings": {
    "sportsNews": true,
    "breakingNews": true,
    "matchUpdates": false
  }
}
```

## ☁️ Cloud Functions Setup

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Initialize Functions
```bash
firebase init functions
```

### 3. Create Functions

Create these Cloud Functions in `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Fetch latest news from external API
exports.fetchLatestNews = functions.https.onCall(async (data, context) => {
  try {
    // Your API integration logic here
    const newsData = await fetchFromNewsAPI();
    
    // Store in Firestore
    const batch = admin.firestore().batch();
    newsData.forEach(article => {
      const docRef = admin.firestore().collection('news').doc();
      batch.set(docRef, article);
    });
    await batch.commit();
    
    return { success: true, articles: newsData };
  } catch (error) {
    console.error('Error fetching news:', error);
    throw new functions.https.HttpsError('internal', 'Failed to fetch news');
  }
});

// Fetch latest matches from external API
exports.fetchLatestMatches = functions.https.onCall(async (data, context) => {
  try {
    // Your API integration logic here
    const matchesData = await fetchFromMatchesAPI();
    
    // Store in Firestore
    const batch = admin.firestore().batch();
    matchesData.forEach(match => {
      const docRef = admin.firestore().collection('matches').doc();
      batch.set(docRef, match);
    });
    await batch.commit();
    
    return { success: true, matches: matchesData };
  } catch (error) {
    console.error('Error fetching matches:', error);
    throw new functions.https.HttpsError('internal', 'Failed to fetch matches');
  }
});

// Send push notification
exports.sendNotification = functions.https.onCall(async (data, context) => {
  try {
    const { title, body, topic, data: notificationData } = data;
    
    const message = {
      notification: {
        title: title,
        body: body,
      },
      topic: topic,
      data: notificationData,
    };
    
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});
```

### 4. Deploy Functions
```bash
firebase deploy --only functions
```

## 🔔 Push Notifications Setup

### 1. Enable Cloud Messaging
1. In Firebase Console → Project Settings → Cloud Messaging
2. Generate server key (if needed)

### 2. Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<service
    android:name=".MyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### 3. iOS Configuration (if needed)

Add to `ios/Runner/AppDelegate.swift`:
```swift
import Firebase
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 🧪 Testing

### 1. Test Firestore Connection
```bash
flutter run
# Check console for "Firebase initialized successfully"
```

### 2. Test Push Notifications
1. Get FCM token from console logs
2. Send test notification from Firebase Console
3. Verify notification appears on device

### 3. Test Cloud Functions
```bash
# Test from Firebase Console → Functions → Testing
```

## 📱 App Features

### Current Implementation
- ✅ **Mock Data Fallback**: App works without Firebase
- ✅ **Firebase Integration**: Ready for real data
- ✅ **Push Notifications**: FCM setup complete
- ✅ **User Preferences**: Firestore integration
- ✅ **Search**: Firebase search with fallback

### Ready for Production
- 🔄 **Real-time Updates**: Firestore listeners
- 🔄 **Offline Support**: Firestore offline persistence
- 🔄 **User Authentication**: Firebase Auth integration
- 🔄 **Analytics**: Firebase Analytics

## 🚨 Important Notes

1. **Mock Data**: App continues working with mock data if Firebase fails
2. **Security Rules**: Set up Firestore security rules before production
3. **API Keys**: Never commit real API keys to version control
4. **Testing**: Test thoroughly before deploying to production

## 📞 Support

If you encounter issues:
1. Check Firebase Console for errors
2. Verify configuration files are in correct locations
3. Check Flutter console for initialization messages
4. Ensure all dependencies are properly installed

---

**Your SportEve app is now ready for Firebase! 🎉**

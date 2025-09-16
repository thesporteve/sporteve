# Firestore Data Structure for SportEve

This document outlines the expected data structure for your Firestore database.

## 📚 Collections

### 1. `news_articles` Collection

Each document in this collection represents a news article.

**Document Structure:**
```json
{
  "title": "Magnus Carlsen Defends World Chess Championship",
  "summary": "The Norwegian grandmaster successfully defended his title in a thrilling 14-game match against challenger Ian Nepomniachtchi, showcasing brilliant tactical play.",
  "content": "Magnus Carlsen has successfully defended his World Chess Championship title in a dramatic 14-game match against Russian grandmaster Ian Nepomniachtchi. The Norwegian champion won the match 7.5-6.5, securing his fifth consecutive world championship victory.\n\nThe match was a masterclass in modern chess, featuring complex opening theory, deep positional understanding, and brilliant tactical combinations. Carlsen's victory came in game 12, where he executed a stunning queen sacrifice that left commentators and fans in awe.\n\n\"I'm incredibly proud to have defended this title,\" Carlsen said after the match. \"Ian is a formidable opponent, and this victory means everything to me. Chess continues to evolve, and I'm honored to be part of this incredible journey.\"\n\nThe championship match drew record viewership, with millions of fans worldwide following the games live. The event has been credited with bringing chess to a new generation of players and fans.",
  "author": "Sarah Johnson",
  "publishedAt": "2024-01-15T10:30:00Z", // ISO 8601 string or Firestore Timestamp
  "imageUrl": "https://images.unsplash.com/photo-1606092195730-5d7b9af1efc5?w=800",
  "category": "chess",
  "source": "Chess.com",
  // tags, readTime, and isBreaking fields are not needed
  "views": 15420,
  "relatedArticles": ["article_id_2", "article_id_3"] // Optional array of related article IDs
}
```

**Required Fields:**
- `title` (string): Article headline
- `summary` (string): Brief description/excerpt
- `content` (string): Full article text
- `author` (string): Author name
- `publishedAt` (timestamp/string): Publication date in ISO 8601 format
- `imageUrl` (string): Main article image URL
- `category` (string): Article category (e.g., "football", "basketball", "tennis", "cricket", "chess", "swimming")
- `source` (string): Publication source

**Optional Fields:**
- `views` (number): View count (defaults to 0)
- `relatedArticles` (array of strings): Related article document IDs

### 2. `matches` Collection

Each document represents a sports match/game.

**Document Structure:**
```json
{
  "homeTeam": "Toronto Maple Leafs",
  "awayTeam": "Boston Bruins",
  "homeScore": 6, // Optional - only for live/finished matches
  "awayScore": 2, // Optional - only for live/finished matches
  "status": "upcoming", // "upcoming", "live", "finished"
  "date": "2024-01-16T19:00:00Z", // ISO 8601 string or Firestore Timestamp
  "league": "NHL",
  "venue": "Scotiabank Arena",
  "homeTeamLogo": "https://example.com/maple-leafs-logo.png", // Optional
  "awayTeamLogo": "https://example.com/bruins-logo.png", // Optional
  "additionalData": { // Optional - for sport-specific data
    "period": "3rd",
    "timeRemaining": "5:42",
    "powerPlay": "home"
  }
}
```

**Required Fields:**
- `homeTeam` (string): Home team name
- `awayTeam` (string): Away team name
- `status` (string): Match status - "upcoming", "live", or "finished"
- `date` (timestamp/string): Match date/time in ISO 8601 format
- `league` (string): League/tournament name
- `venue` (string): Venue/stadium name

**Optional Fields:**
- `homeScore` (number): Home team score (for live/finished matches)
- `awayScore` (number): Away team score (for live/finished matches)
- `homeTeamLogo` (string): Home team logo URL
- `awayTeamLogo` (string): Away team logo URL
- `additionalData` (object): Sport-specific metadata

## 🚀 Getting Started

### Step 1: Create Firestore Database
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Firestore Database
4. Click "Create database"
5. Choose "Start in test mode" (for development)

### Step 2: Create Collections
Create these collections manually in Firestore:
- `news_articles`
- `matches`

### Step 3: Add Sample Data

#### Sample News Article:
```json
// Collection: news_articles
// Document ID: (auto-generated or custom)
{
  "title": "Lakers Win Championship",
  "summary": "LeBron leads Lakers to victory in Game 6",
  "content": "The Los Angeles Lakers defeated the Miami Heat 106-93 in Game 6 of the NBA Finals...",
  "author": "Sports Reporter",
  "publishedAt": "2024-01-20T20:00:00Z",
  "imageUrl": "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800",
  "category": "basketball",
  "source": "ESPN",
  // tags, readTime, and isBreaking fields removed per user request
  "views": 0
}
```

#### Sample Match:
```json
// Collection: matches
// Document ID: (auto-generated or custom)
{
  "homeTeam": "Los Angeles Lakers",
  "awayTeam": "Boston Celtics",
  "status": "upcoming",
  "date": "2024-01-25T20:00:00Z",
  "league": "NBA",
  "venue": "Crypto.com Arena"
}
```

## 📊 Firestore Rules

For development, you can start with these basic rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to news articles
    match /news_articles/{document} {
      allow read: if true;
      allow write: if false; // Prevent client writes for now
    }
    
    // Allow read access to matches
    match /matches/{document} {
      allow read: if true;
      allow write: if false; // Prevent client writes for now
    }
  }
}
```

## 🔍 Querying Examples

The app will automatically query Firestore using these patterns:

```dart
// Get latest news articles
firestore.collection('news_articles')
  .orderBy('publishedAt', descending: true)
  .limit(50)
  .get()

// Get upcoming matches
firestore.collection('matches')
  .orderBy('date', descending: false)
  .limit(20)
  .get()

// Get specific article
firestore.collection('news_articles')
  .doc(articleId)
  .get()
```

## ⚡ Performance Tips

1. **Indexing**: Firestore will automatically suggest indexes when needed
2. **Pagination**: Consider implementing pagination for large datasets
3. **Caching**: The app includes offline support via Firestore caching
4. **Search**: For better search functionality, consider integrating with Algolia

## 🔄 Migration from Mock Data

Your app will automatically:
1. Try to fetch from Firestore first
2. Fall back to mock data if Firestore is unavailable
3. Show loading states during data fetching
4. Handle errors gracefully

Once you add data to Firestore, the app will start using real data while maintaining the same UI and functionality.

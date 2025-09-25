import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick setup script to add sample news articles to Firebase
class NewsArticlesSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add sample news articles to Firebase
  static Future<void> createSampleNewsArticles() async {
    try {
      print('🚀 Setting up sample news articles in Firebase...');

      final articles = [
        {
          "title": "Manchester City Wins Premier League",
          "summary": "City clinches the title with a stunning 3-0 victory over Arsenal in the final match.",
          "content": "In a thrilling finale to the Premier League season, Manchester City secured their championship with a commanding performance against Arsenal. Goals from Haaland, De Bruyne, and Foden sealed the title in front of a jubilant home crowd.",
          "author": "John Smith",
          "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))),
          "category": "football",
          "source": "ESPN",
          "views": 1250,
          "likes": 45,
          "shares": 12,
          "imageUrl": null, // Will use category icon
        },
        {
          "title": "LeBron James Breaks Another Record",
          "summary": "Lakers superstar becomes oldest player to record triple-double in NBA history.",
          "content": "At 39 years old, LeBron James continues to defy Father Time. Last night's triple-double performance against the Nuggets marked yet another historic milestone in his legendary career.",
          "author": "Sarah Johnson",
          "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 5))),
          "category": "basketball",
          "source": "NBA.com",
          "views": 2100,
          "likes": 89,
          "shares": 34,
          "imageUrl": null,
        },
        {
          "title": "Novak Djokovic Advances to Wimbledon Final",
          "summary": "Serbian tennis legend defeats Alcaraz in straight sets to reach his 10th Wimbledon final.",
          "content": "In a masterclass display of tennis, Novak Djokovic showcased his grass-court prowess against the young Spaniard. The victory sets up a tantalizing final showdown.",
          "author": "Maria Rodriguez",
          "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 8))),
          "category": "tennis",
          "source": "Tennis.com",
          "views": 950,
          "likes": 67,
          "shares": 18,
          "imageUrl": null,
        },
        {
          "title": "India Crushes Australia in Cricket World Cup Semi",
          "summary": "Magnificent centuries from Kohli and Sharma propel India to World Cup final.",
          "content": "India's batting maestros Virat Kohli and Rohit Sharma produced magical centuries to demolish Australia's bowling attack. India will now face England in the World Cup final.",
          "author": "Raj Patel",
          "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 12))),
          "category": "cricket",
          "source": "Cricket Australia",
          "views": 3500,
          "likes": 156,
          "shares": 78,
          "imageUrl": null,
        },
        {
          "title": "Olympic Swimming Records Shattered in Paris",
          "summary": "Katie Ledecky sets new world record in 1500m freestyle at Paris Olympics.",
          "content": "American swimming legend Katie Ledecky delivered yet another breathtaking performance, smashing the world record in the 1500m freestyle. The Paris Olympics continues to witness historic sporting moments.",
          "author": "David Wilson",
          "publishedAt": Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 18))),
          "category": "olympics",
          "source": "Olympic Channel",
          "views": 2800,
          "likes": 134,
          "shares": 56,
          "imageUrl": null,
        },
      ];

      for (int i = 0; i < articles.length; i++) {
        await _firestore.collection('news_articles').add(articles[i]);
        print('✅ Added article: ${articles[i]["title"]}');
      }

      print('🎉 Successfully added ${articles.length} news articles to Firebase!');
      print('📱 Your app should now show real Firebase data instead of mock data.');
      
    } catch (e) {
      print('❌ Error setting up news articles: $e');
      print('Make sure you have internet connection and proper Firebase permissions.');
    }
  }
}

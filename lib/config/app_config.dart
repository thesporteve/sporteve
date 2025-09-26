/// App configuration constants
class AppConfig {
  // App Information
  static const String packageName = 'com.sporteve.app';
  static const String appName = 'SportEve';
  static const String tagline = 'Your Daily Sports Pulse';
  
  // Deep Linking Configuration
  static const String baseWebUrl = 'https://sporteve-7afbf.web.app';
  static const String deepLinkScheme = 'sporteve';
  
  // Store URLs (will be updated when app goes live)
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageName';
  static const String playStoreBaseUrl = 'market://details?id=$packageName';
  
  // App Status
  static const bool isLiveOnPlayStore = false; // TODO: Update when app is live
  
  // Smart Link Configuration
  static String getArticleWebUrl(String articleId) {
    return '$baseWebUrl/article/$articleId';
  }
  
  static String getArticleDeepLink(String articleId) {
    return '$deepLinkScheme://article/$articleId';
  }
  
  static String getSmartArticleLink(String articleId) {
    // This creates a smart link that works for both installed and non-installed users
    return getArticleWebUrl(articleId);
  }
  
  static String getAppStoreLink() {
    return isLiveOnPlayStore ? playStoreUrl : '$baseWebUrl/download';
  }
}

class AdminConfig {
  static const String adminVersion = '1.3.0';
  static const String adminName = 'SportEve Admin';
  
  // Release info - update this for each deployment
  static const String releaseNotes = 'Dynamic Sports Management';
  static const String releaseDate = '2025-09-27';
  
  // Environment info
  static const String environment = 'Production';
  
  static String get fullVersionString => '$adminName v$adminVersion';
  static String get versionWithNotes => '$adminVersion - $releaseNotes';
}

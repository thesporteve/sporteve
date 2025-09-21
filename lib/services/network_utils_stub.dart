// Stub implementation for web
class InternetAddress {
  static Future<List<dynamic>> lookup(String host) async {
    throw UnsupportedError('InternetAddress.lookup not supported on web');
  }
  
  List<int> get rawAddress => throw UnsupportedError('rawAddress not supported on web');
}

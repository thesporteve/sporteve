// IO implementation for mobile/desktop
import 'dart:io' as io;

class InternetAddress {
  static Future<List<io.InternetAddress>> lookup(String host) {
    return io.InternetAddress.lookup(host);
  }
}

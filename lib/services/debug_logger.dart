import 'package:flutter/foundation.dart';

class DebugLogger extends ChangeNotifier {
  static DebugLogger? _instance;
  static DebugLogger get instance => _instance ??= DebugLogger._();
  
  DebugLogger._();

  final List<String> _logs = [];
  static const int _maxLogs = 100;

  List<String> get logs => List.unmodifiable(_logs);

  void log(String message) {
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];
    final logEntry = '[$timestamp] $message';
    
    // Add to internal log list
    _logs.add(logEntry);
    
    // Keep only recent logs
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    
    // Also print to console for development
    print(logEntry);
    
    // Notify listeners
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void logFirebaseStatus(Map<String, dynamic> status) {
    log('📊 Firebase Status Update:');
    status.forEach((key, value) {
      log('   $key: $value');
    });
  }

  void logError(String context, dynamic error) {
    log('❌ ERROR in $context: $error');
  }

  void logSuccess(String context, [String? details]) {
    log('✅ SUCCESS in $context${details != null ? ': $details' : ''}');
  }

  void logWarning(String context, String warning) {
    log('⚠️ WARNING in $context: $warning');
  }

  void logInfo(String context, String info) {
    log('🔄 INFO in $context: $info');
  }
}

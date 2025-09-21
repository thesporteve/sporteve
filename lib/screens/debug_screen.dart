import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/firebase_service.dart';
import '../services/firebase_data_service.dart';
import '../providers/news_provider.dart';
import '../services/debug_logger.dart';
import 'package:provider/provider.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when new logs arrive
    DebugLogger.instance.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    DebugLogger.instance.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients && _scrollController.positions.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _scrollController.positions.length == 1) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can pop, otherwise navigate to settings
            if (context.canPop()) {
              context.pop();
            } else {
              // Navigate back to settings screen
              context.go('/settings');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.keyboard_arrow_down : Icons.pause),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              DebugLogger.instance.clearLogs();
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFirebaseStatus(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildSystemInfo(),
            const SizedBox(height: 16),
            _buildLogSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseStatus() {
    final firebaseStatus = FirebaseService.instance.getFirebaseStatus();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...firebaseStatus.entries.map((entry) {
              final bool isAvailable = entry.value == true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.error,
                      color: isAvailable ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value}',
                        style: TextStyle(
                          color: isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testFirebaseConnection,
                  child: const Text('Test Firebase'),
                ),
                ElevatedButton(
                  onPressed: _testNewsLoad,
                  child: const Text('Test News Load'),
                ),
                ElevatedButton(
                  onPressed: _copyLogsToClipboard,
                  child: const Text('Copy Logs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Platform: ${Theme.of(context).platform}'),
            Text('Time: ${DateTime.now().toLocal()}'),
            Text('Firebase Available: ${FirebaseService.instance.isFirebaseAvailable}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recent Logs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${DebugLogger.instance.logs.length} entries',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: DebugLogger.instance.logs.length,
                itemBuilder: (context, index) {
                  final log = DebugLogger.instance.logs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: _getLogColor(log),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('❌') || log.contains('ERROR')) return Colors.red;
    if (log.contains('⚠️') || log.contains('WARN')) return Colors.orange;
    if (log.contains('✅') || log.contains('SUCCESS')) return Colors.green;
    if (log.contains('🔄') || log.contains('INFO')) return Colors.blue;
    return Colors.white70;
  }

  Future<void> _testFirebaseConnection() async {
    DebugLogger.instance.log('🧪 Manual Firebase connection test started');
    try {
      await FirebaseService.instance.initialize();
      final status = FirebaseService.instance.getFirebaseStatus();
      DebugLogger.instance.log('📊 Firebase Status: $status');
      setState(() {});
    } catch (e) {
      DebugLogger.instance.log('❌ Manual Firebase test failed: $e');
    }
  }

  Future<void> _testNewsLoad() async {
    DebugLogger.instance.log('🧪 Manual news loading test started');
    try {
      final newsProvider = context.read<NewsProvider>();
      await newsProvider.loadNews();
      DebugLogger.instance.log('✅ News loaded: ${newsProvider.articles.length} articles');
      setState(() {});
    } catch (e) {
      DebugLogger.instance.log('❌ Manual news test failed: $e');
    }
  }

  Future<void> _copyLogsToClipboard() async {
    final logs = DebugLogger.instance.logs.join('\n');
    await Clipboard.setData(ClipboardData(text: logs));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copied to clipboard')),
      );
    }
  }
}

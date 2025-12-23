import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_kit/network_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// **MyApp** is the entry point for the Network Kit demonstration.
///
/// It showcases the "Magic Trick" of offline queuing and automatic synchronization
/// using a simple log-based UI.
class MyApp extends StatefulWidget {
  /// Creates the [MyApp] widget.
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 1. Initialize the Client
  final _client = NetworkClient(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    storage: OfflineStorage(),
  );

  // 2. The Sync Manager
  late SyncManager _syncManager;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initSync();
  }

  void _initSync() {
    // Initialize SyncManager.
    _syncManager = SyncManager(_client);
    
    // Start listening to connectivity changes to auto-replay queue
    _syncManager.startMonitoring(); 
    _addLog("✅ System Initialized. Sync Manager Active.");
  }

  Future<void> _fetchPost() async {
    _addLog("⏳ Requesting Post #1...");

    // 3. Make the Request
    final result = await _client.request<Map<dynamic, dynamic>>(
      path: '/posts/1',
      method: HttpMethod.get,
    );

    // 4. Handle the Result (Dart 3 Pattern Matching)
    switch (result) {
      case Success<Map<dynamic, dynamic>>(data: final data):
        _addLog("🟢 SUCCESS: ${data['title']}");
      case Failure<dynamic>(statusCode: 499, message: final msg):
        _addLog("🟠 OFFLINE: $msg (Saved to Queue)");
      case Failure<dynamic>(message: final msg):
        _addLog("🔴 ERROR: $msg");
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, "${DateTime.now().second}s: $message");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Network Kit Demo"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("FETCH DATA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _fetchPost,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Activity Logs", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setState(() => _logs.clear()),
                    child: const Text("Clear"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color color = Colors.black;
                  if (log.contains("SUCCESS")) color = Colors.green;
                  if (log.contains("OFFLINE")) color = Colors.orange;
                  if (log.contains("ERROR")) color = Colors.red;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(log, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

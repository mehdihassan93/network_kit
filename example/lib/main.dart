import 'package:flutter/material.dart';
import 'package:network_kit/network_kit.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// A premium demonstration app for the Network Kit.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Network Kit Premium',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFEC4899),
          surface: const Color(0xFF0F172A),
          background: const Color(0xFF020617),
        ),
      ),
      home: const NetworkKitDemo(),
    );
  }
}

class NetworkKitDemo extends StatefulWidget {
  const NetworkKitDemo({super.key});

  @override
  State<NetworkKitDemo> createState() => _NetworkKitDemoState();
}

class _NetworkKitDemoState extends State<NetworkKitDemo> {
  late final NetworkClient _client;
  late final SyncManager _syncManager;
  final List<NetworkLog> _logs = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _client = NetworkClient(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      storage: OfflineStorage(),
    );
    _syncManager = SyncManager(_client);
    _syncManager.startMonitoring();
    _addLog("System Initialized", LogType.info);
  }

  void _addLog(String message, LogType type) {
    final log = NetworkLog(
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    _logs.insert(0, log);
    _listKey.currentState?.insertItem(0);
  }

  Future<void> _triggerRequest() async {
    _addLog("Dispatching GET request to /posts/1", LogType.info);
    
    final result = await _client.request<Map<dynamic, dynamic>>(
      path: '/posts/1',
      method: HttpMethod.get,
    );

    switch (result) {
      case Success<Map<dynamic, dynamic>>(data: final data):
        _addLog("SUCCESS: ${data['title']}", LogType.success);
      case Failure<dynamic>(statusCode: 499, message: final msg):
        _addLog("OFFLINE: $msg (Captured in Vault)", LogType.warning);
      case Failure<dynamic>(message: final msg):
        _addLog("FAILURE: $msg", LogType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF020617), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
          
          // Decorative Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.15),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(child: _buildLogList()),
                _buildActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: const Icon(Icons.bolt, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 16),
              const Text(
                'Network Kit',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'High-Resiliency Networking Engine',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return AnimatedList(
      key: _listKey,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      initialItemCount: _logs.length,
      itemBuilder: (context, index, animation) {
        final log = _logs[index];
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(Tween(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            )),
            child: _buildLogCard(log),
          ),
        );
      },
    );
  }

  Widget _buildLogCard(NetworkLog log) {
    Color accentColor;
    IconData icon;

    switch (log.type) {
      case LogType.success:
        accentColor = const Color(0xFF10B981);
        icon = Icons.check_circle_outline;
      case LogType.warning:
        accentColor = const Color(0xFFF59E0B);
        icon = Icons.cloud_off;
      case LogType.error:
        accentColor = const Color(0xFFEF4444);
        icon = Icons.error_outline;
      case LogType.info:
        accentColor = const Color(0xFF6366F1);
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _triggerRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch),
              SizedBox(width: 12),
              Text(
                'Fire Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum LogType { info, success, warning, error }

class NetworkLog {
  final String message;
  final DateTime timestamp;
  final LogType type;

  NetworkLog({
    required this.message,
    required this.timestamp,
    required this.type,
  });
}
